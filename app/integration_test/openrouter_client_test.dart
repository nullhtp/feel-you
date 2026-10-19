import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:feel_you/cloud/cloud.dart';
import 'package:feel_you/morse/morse.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'e2e_helpers.dart';
import 'test_helpers.dart';

// The cloud client end to end (`openrouter-client`): the app's own
// providers, the key in the real secure storage, the base URL and the
// usage in the real preferences, and real HTTP connections to a server
// this test starts on the device's loopback address.

/// Shaped like a real OpenRouter key, and unique to this test.
final _key = CloudKey.parse('sk-or-v1-${'5eedbeef' * 7}0123456789ab0e2e');

final _request = CloudRequest(
  messages: const [
    CloudMessage.system('Answer in one short sentence.'),
    CloudMessage.user('How are you?'),
  ],
  models: const ['openai/gpt-4o-mini', 'google/gemini-2.5-flash'],
);

/// A request as the local server received it.
class _Received {
  _Received(this.method, this.path, this.headers, this.body);

  final String method;
  final String path;

  /// Header names in lower case.
  final Map<String, String> headers;
  final String body;

  Map<String, Object?> get json => jsonDecode(body) as Map<String, Object?>;
}

/// An event stream sent by the local server, in HTTP chunks written by
/// hand on the raw socket, so the test sees when the app closes it.
class _EventStream {
  _EventStream._(this._socket) {
    _socket.listen(
      (_) {},
      onDone: _markClosed,
      onError: (Object _) => _markClosed(),
    );
  }

  /// Answers [request] with `200` and an event stream.
  static Future<_EventStream> open(HttpRequest request) async {
    final response = request.response
      ..statusCode = 200
      ..headers.contentType = ContentType('text', 'event-stream')
      ..headers.chunkedTransferEncoding = true
      // Not reused: after `detachSocket` the server no longer reads it.
      ..persistentConnection = false;
    return _EventStream._(await response.detachSocket());
  }

  final Socket _socket;
  final _closed = Completer<void>();
  bool _ended = false;

  /// Completes when the connection is closed (by the app, unless [end] was
  /// called first).
  Future<void> get closed => _closed.future;
  bool get isClosed => _closed.isCompleted;

  void _markClosed() {
    if (!_closed.isCompleted) _closed.complete();
  }

  /// Sends [text] as one HTTP chunk.
  Future<void> send(String text) async {
    if (isClosed) return;
    final bytes = utf8.encode(text);
    try {
      _socket
        ..add(utf8.encode('${bytes.length.toRadixString(16)}\r\n'))
        ..add(bytes)
        ..add(utf8.encode('\r\n'));
      await _socket.flush();
    } on Object {
      // The app has closed the connection.
      _markClosed();
    }
  }

  Future<void> comment() => send(': OPENROUTER PROCESSING\n\n');

  Future<void> content(String text, {String? finishReason}) => send(
    'data: ${jsonEncode({
      'id': 'gen-e2e',
      'object': 'chat.completion.chunk',
      'model': 'openai/gpt-4o-mini',
      'choices': [
        {
          'index': 0,
          'delta': {'role': 'assistant', 'content': text},
          'finish_reason': finishReason,
        },
      ],
    })}\n\n',
  );

  /// The finish chunk, the usage chunk and `[DONE]`, then the last chunk.
  Future<void> finish({Map<String, Object>? usage}) async {
    await content('', finishReason: 'stop');
    if (usage != null) {
      await send(
        'data: ${jsonEncode({
          'id': 'gen-e2e',
          'object': 'chat.completion.chunk',
          'choices': [
            {
              'index': 0,
              'delta': {'role': 'assistant', 'content': ''},
              'finish_reason': 'stop',
            },
          ],
          'usage': usage,
        })}\n\n',
      );
    }
    await send('data: [DONE]\n\n');
    await end();
  }

  /// Ends the body properly, then the connection.
  Future<void> end() async {
    if (_ended || isClosed) return;
    _ended = true;
    _socket.add(utf8.encode('0\r\n\r\n'));
    await _socket.flush();
    await _socket.close();
  }

  /// Drops the connection mid-answer, as a lost network does.
  void drop() => _socket.destroy();
}

/// An OpenAI-compatible endpoint on the device's loopback address.
class _LocalEndpoint {
  _LocalEndpoint._(this._server) {
    _server.listen(_handle);
  }

  static Future<_LocalEndpoint> start() async =>
      _LocalEndpoint._(await HttpServer.bind(InternetAddress.loopbackIPv4, 0));

  final HttpServer _server;
  final requests = <_Received>[];
  final _streams = <_EventStream>[];

  /// Answers `POST /api/v1/chat/completions`.
  Future<void> Function(HttpRequest request) onChat = _notFound;

  /// Answers `GET /api/v1/key`.
  Future<void> Function(HttpRequest request) onKey = _notFound;

  /// The base URL to set in the app.
  String get baseUrl => 'http://127.0.0.1:${_server.port}/api/v1';

  List<_Received> get chatRequests =>
      requests.where((r) => r.path.endsWith('/chat/completions')).toList();
  List<_Received> get keyRequests =>
      requests.where((r) => r.path.endsWith('/key')).toList();

  /// Opens an event stream for [request], closed at [close].
  Future<_EventStream> stream(HttpRequest request) async {
    final stream = await _EventStream.open(request);
    _streams.add(stream);
    return stream;
  }

  Future<void> _handle(HttpRequest request) async {
    final headers = <String, String>{};
    request.headers.forEach((name, values) => headers[name] = values.join(','));
    requests.add(
      _Received(
        request.method,
        request.uri.path,
        headers,
        await utf8.decoder.bind(request).join(),
      ),
    );
    if (request.uri.path == '/api/v1/chat/completions') {
      await onChat(request);
    } else if (request.uri.path == '/api/v1/key') {
      await onKey(request);
    } else {
      await _notFound(request);
    }
  }

  static Future<void> _notFound(HttpRequest request) async {
    request.response.statusCode = 404;
    await request.response.close();
  }

  Future<void> close() async {
    for (final stream in _streams) {
      stream.drop();
    }
    await _server.close(force: true);
  }
}

/// Answers with [status] and a JSON error that repeats the key, as a
/// careless server might.
Future<void> Function(HttpRequest) _errorStatus(int status) => (request) async {
  request.response
    ..statusCode = status
    ..headers.contentType = ContentType.json
    ..write(
      jsonEncode({
        'error': {
          'code': status,
          'message': 'Key ${_key.value} cannot do this',
        },
      }),
    );
  await request.response.close();
};

/// What a request ended with.
class _Outcome {
  final words = <String>[];
  Object? error;
  bool done = false;
}

/// Listens to [completion]'s words; [onWord] is called with each.
_Outcome _listen(
  CloudCompletion completion, {
  void Function(String word)? onWord,
}) {
  final outcome = _Outcome();
  completion.words.listen(
    (word) {
      outcome.words.add(word);
      onWord?.call(word);
    },
    onError: (Object error) => outcome.error = error,
    onDone: () => outcome.done = true,
  );
  return outcome;
}

Future<_Outcome> _run(
  WidgetTester tester,
  E2EApp app,
  CloudRequest request,
) async {
  final outcome = _listen(_client(app, tester).stream(request));
  await waitUntil(tester, () => outcome.done, reason: 'the answer ends');
  return outcome;
}

OpenRouterClient _client(E2EApp app, WidgetTester tester) =>
    app.container(tester).read(openRouterClientProvider);

/// Removes this test's values from the real preferences.
Future<void> _clearCloudPreferences() async {
  final preferences = await SharedPreferences.getInstance();
  for (final key in SharedPreferencesCloudPreferencesStore.keys) {
    await preferences.remove(key);
  }
}

/// Launches the app as `main` does for the cloud: the real secure store and
/// the cloud preferences read back from the platform.
Future<E2EApp> _launch(
  WidgetTester tester, {
  DateTime Function()? clock,
  CloudTimingConfig? timing,
}) async {
  final preferences = await SharedPreferences.getInstance();
  await preferences.reload();
  final app = E2EApp(
    savedLanguage: MorseLanguage.english,
    vibration: RecordingVibrationService(),
    overrides: [
      cloudKeyStoreProvider.overrideWithValue(const SecureCloudKeyStore()),
      cloudPreferencesStoreProvider.overrideWithValue(
        await loadCloudPreferencesStore(),
      ),
      if (clock != null) cloudClockProvider.overrideWithValue(clock),
      if (timing != null) cloudTimingConfigProvider.overrideWithValue(timing),
    ],
  );
  await app.launch(tester);
  return app;
}

/// Saves the key and points the app at [endpoint], as the assistant
/// screen (#63) will.
Future<void> _connect(
  WidgetTester tester,
  E2EApp app,
  _LocalEndpoint endpoint,
) async {
  final container = app.container(tester);
  await container.read(cloudKeyProvider.notifier).save(_key);
  final accepted = await container
      .read(cloudSettingsProvider.notifier)
      .setBaseUrl(endpoint.baseUrl);
  expect(accepted, isTrue, reason: 'a loopback base URL may use http');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late _LocalEndpoint endpoint;

  // Start and end without the key and the cloud preferences, whatever an
  // earlier, interrupted run left behind.
  setUp(() async {
    await const SecureCloudKeyStore().delete();
    await _clearCloudPreferences();
    endpoint = await _LocalEndpoint.start();
  });
  tearDown(() async {
    await endpoint.close();
    await const SecureCloudKeyStore().delete();
    await _clearCloudPreferences();
  });

  testWidgets('sends the documented request and streams the words as they '
      'arrive', (tester) async {
    FakeVibrationPlatform().install(tester);
    final app = await _launch(tester);
    await _connect(tester, app, endpoint);
    await waitFor(tester, const Duration(milliseconds: 300));
    expect(endpoint.requests, isEmpty, reason: 'nothing is sent by itself');

    final firstWord = Completer<void>();
    var restSent = false;
    bool? helloBeforeRest;
    endpoint.onChat = (request) async {
      final stream = await endpoint.stream(request);
      await stream.comment();
      await stream.content('');
      await stream.content('Hello wor');
      // Hold the rest back until the app has released the first word.
      await firstWord.future.timeout(const Duration(seconds: 4));
      restSent = true;
      await stream.content('ld, how are');
      await stream.comment();
      await stream.content(' you?');
      await stream.finish();
    };
    final outcome = _listen(
      _client(app, tester).stream(_request),
      onWord: (word) {
        if (word == 'Hello') {
          helloBeforeRest = !restSent;
          firstWord.complete();
        }
      },
    );
    await waitUntil(tester, () => outcome.done, reason: 'the answer ends');

    expect(outcome.words, ['Hello', 'world,', 'how', 'are', 'you?']);
    expect(helloBeforeRest, isTrue, reason: 'Hello came before the rest');
    expect(outcome.error, isNull);

    final received = endpoint.chatRequests.single;
    expect(received.method, 'POST');
    expect(received.path, '/api/v1/chat/completions');
    expect(received.headers['authorization'], 'Bearer ${_key.value}');
    expect(
      received.headers['http-referer'],
      'https://github.com/nullhtp/feel-you',
    );
    expect(received.headers['x-title'], 'Feel You');
    expect(received.headers['content-type'], startsWith('application/json'));
    expect(received.headers['accept'], 'text/event-stream');
    expect(received.json, {
      'model': 'openai/gpt-4o-mini',
      'models': ['openai/gpt-4o-mini', 'google/gemini-2.5-flash'],
      'messages': [
        {'role': 'system', 'content': 'Answer in one short sentence.'},
        {'role': 'user', 'content': 'How are you?'},
      ],
      'stream': true,
      'temperature': 0,
      'provider': {'data_collection': 'deny'},
    });

    // Data collection allowed and a JSON answer: no provider field, a
    // response format.
    await app
        .container(tester)
        .read(cloudSettingsProvider.notifier)
        .setDenyDataCollection(deny: false);
    endpoint.onChat = (request) async {
      final stream = await endpoint.stream(request);
      await stream.content('{"text":"ok"}');
      await stream.finish();
    };
    await _run(
      tester,
      app,
      CloudRequest(
        messages: const [CloudMessage.user('Read the sign.')],
        models: const ['openai/gpt-4o-mini'],
        jsonAnswer: true,
      ),
    );
    final second = endpoint.chatRequests.last.json;
    expect(second.containsKey('provider'), isFalse);
    expect(second['response_format'], {'type': 'json_object'});

    await app.close(tester);
  });

  testWidgets('the first-token timeout and cancellation close the '
      'connection', (tester) async {
    FakeVibrationPlatform().install(tester);
    const timeout = Duration(seconds: 1);
    final app = await _launch(
      tester,
      timing: const CloudTimingConfig(firstTokenTimeout: timeout),
    );
    await _connect(tester, app, endpoint);

    // Only keep-alive comments: the timeout error, and the app closes the
    // connection.
    late _EventStream silent;
    endpoint.onChat = (request) async {
      silent = await endpoint.stream(request);
      while (!silent.isClosed) {
        await silent.comment();
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
    };
    final watch = Stopwatch()..start();
    final timedOut = await _run(tester, app, _request);
    watch.stop();

    expect(timedOut.error, isA<CloudTimeout>());
    expect(timedOut.words, isEmpty);
    expect(watch.elapsed, greaterThanOrEqualTo(timeout));
    expect(watch.elapsed, lessThan(timeout * 3));
    await silent.closed.timeout(const Duration(seconds: 2));

    // One word, then nothing: cancelling closes the connection and
    // releases nothing more.
    late _EventStream open;
    endpoint.onChat = (request) async {
      open = await endpoint.stream(request);
      await open.content('Only ');
      while (!open.isClosed) {
        await open.comment();
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    };
    final completion = _client(app, tester).stream(_request);
    final cancelled = _listen(completion);
    await waitUntil(
      tester,
      () => cancelled.words.isNotEmpty,
      reason: 'the first word arrives',
    );
    await completion.cancel();
    await open.closed.timeout(const Duration(seconds: 2));
    await waitUntil(tester, () => cancelled.done, reason: 'the answer ends');
    await waitFor(tester, const Duration(milliseconds: 300));

    expect(cancelled.words, ['Only']);
    expect(cancelled.error, isNull);

    await app.close(tester);
  });

  testWidgets('each failure gives its error, without the key', (tester) async {
    FakeVibrationPlatform().install(tester);
    final app = await _launch(tester);
    await _connect(tester, app, endpoint);

    Future<Object?> failure() async {
      final outcome = await _run(tester, app, _request);
      expect('${outcome.error}', isNot(contains(_key.value)));
      expect('${outcome.error}', isNot(contains('cannot do this')));
      return outcome.error;
    }

    endpoint.onChat = _errorStatus(401);
    expect(await failure(), isA<CloudKeyRejected>());

    endpoint.onChat = _errorStatus(402);
    expect(await failure(), isA<CloudLimitExhausted>());

    endpoint.onChat = _errorStatus(404);
    expect(await failure(), isA<CloudModelUnavailable>());

    // Every fallback model failed before the first token.
    endpoint.onChat = (request) async {
      final stream = await endpoint.stream(request);
      await stream.comment();
      await stream.send(
        'data: ${jsonEncode({
          'id': 'gen-e2e',
          'object': 'chat.completion.chunk',
          'error': {
            'code': 502,
            'message': 'Provider returned error',
            'metadata': {'error_type': 'provider_unavailable'},
          },
          'choices': [
            {
              'index': 0,
              'delta': {'content': ''},
              'finish_reason': 'error',
            },
          ],
        })}\n\n',
      );
      await stream.end();
    };
    expect(await failure(), isA<CloudModelUnavailable>());

    // The connection drops mid-answer.
    endpoint.onChat = (request) async {
      final stream = await endpoint.stream(request);
      await stream.content('Half an ans');
      await Future<void>.delayed(const Duration(milliseconds: 200));
      stream.drop();
    };
    final dropped = await _run(tester, app, _request);
    expect(dropped.words, ['Half', 'an']);
    expect(dropped.error, isA<CloudOffline>());

    // Nothing listens on the port.
    final closedPort = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = closedPort.port;
    await closedPort.close();
    await app
        .container(tester)
        .read(cloudSettingsProvider.notifier)
        .setBaseUrl('http://127.0.0.1:$port/api/v1');
    expect(await failure(), isA<CloudOffline>());

    // No key: nothing is sent.
    await app
        .container(tester)
        .read(cloudSettingsProvider.notifier)
        .setBaseUrl(endpoint.baseUrl);
    await app.container(tester).read(cloudKeyProvider.notifier).delete();
    final sent = endpoint.requests.length;
    expect(await failure(), isA<CloudNoKey>());
    expect(endpoint.requests, hasLength(sent));

    await app.close(tester);
  });

  testWidgets('usage and the key information survive a restart; the key '
      'information is fetched once a day', (tester) async {
    FakeVibrationPlatform().install(tester);
    var now = DateTime(2026, 10, 19, 12);
    DateTime clock() => now;
    var app = await _launch(tester, clock: clock);
    await _connect(tester, app, endpoint);

    endpoint
      ..onChat = (request) async {
        final stream = await endpoint.stream(request);
        await stream.content('Fine.');
        await stream.finish(
          usage: {
            'prompt_tokens': 10,
            'completion_tokens': 5,
            'total_tokens': 15,
            'cost': 0.0002,
          },
        );
      }
      ..onKey = (request) async {
        request.response
          ..statusCode = 200
          ..headers.contentType = ContentType.json
          ..write(
            jsonEncode({
              'data': {
                'label': 'Feel You',
                'limit': 10,
                'limit_remaining': 7.5,
                'usage': 2.5,
                'usage_daily': 0.25,
                'usage_monthly': 2.5,
              },
            }),
          );
        await request.response.close();
      };

    for (var i = 0; i < 2; i++) {
      final outcome = await _run(tester, app, _request);
      expect(outcome.words, ['Fine.']);
    }
    await waitFor(tester, const Duration(milliseconds: 100));
    const twoAnswers = CloudUsageAmount(
      answers: 2,
      promptTokens: 20,
      completionTokens: 10,
      totalTokens: 30,
      cost: 0.0004,
    );
    var totals = app.container(tester).read(cloudUsageProvider);
    expect(totals.today, twoAnswers);
    expect(totals.thisMonth, twoAnswers);

    final info = await _client(app, tester).keyInfo();
    expect(info.limit, 10);
    expect(info.limitRemaining, 7.5);
    expect(info.key, _key.masked);
    expect(await _client(app, tester).keyInfo(), info);
    expect(endpoint.keyRequests, hasLength(1));
    final keyRequest = endpoint.keyRequests.single;
    expect(keyRequest.method, 'GET');
    expect(keyRequest.headers['authorization'], 'Bearer ${_key.value}');

    // A restart, later the same day: everything is read back from the
    // device, and the key information is not fetched again.
    await app.close(tester);
    now = DateTime(2026, 10, 19, 23, 30);
    app = await _launch(tester, clock: clock);
    totals = app.container(tester).read(cloudUsageProvider);
    expect(totals.today, twoAnswers);
    expect(totals.thisMonth, twoAnswers);
    expect(await _client(app, tester).keyInfo(), info);
    expect(endpoint.keyRequests, hasLength(1));

    // The next day: today starts at zero, the month keeps its totals, and
    // the key information is fetched again.
    now = DateTime(2026, 10, 20, 0, 5);
    totals = app.container(tester).read(cloudUsageProvider.notifier).current();
    expect(totals.today, const CloudUsageAmount());
    expect(totals.thisMonth, twoAnswers);
    await _client(app, tester).keyInfo();
    expect(endpoint.keyRequests, hasLength(2));

    await app.close(tester);
  });
}
