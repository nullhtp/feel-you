import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:feel_you/cloud/cloud.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'cloud_test_helpers.dart';

/// Short enough for a test to outlast, long enough not to fire by accident.
const _fastTiming = CloudTimingConfig(
  firstTokenTimeout: Duration(milliseconds: 300),
  keyInfoTimeout: Duration(milliseconds: 300),
);

/// The words of `openrouter_stream.sse`.
const _fixtureWords = ['Hello', 'world,', 'how', 'are', 'you?', 'Ça', 'va.'];

/// Listens to [stream] and waits until it has ended.
Future<Collected<String>> _collect(Stream<String> stream) async {
  final collected = Collected.of(stream);
  await collected.ended.future.timeout(const Duration(seconds: 5));
  return collected;
}

/// A handler answering every request with [response].
FakeHandler _always(http.StreamedResponse Function() response) =>
    (_) async => response();

/// A handler that never answers until the request is aborted, then fails
/// as `IOClient` does.
Future<http.StreamedResponse> _neverAnswers(ReceivedRequest request) async {
  await request.abortTrigger;
  throw http.RequestAbortedException(request.url);
}

/// An OpenRouter `GET /key` response.
Map<String, Object?> _keyResponse({double usage = 2.5}) => {
  'data': {
    'label': 'Feel You',
    'limit': 10,
    'limit_remaining': 10 - usage,
    'limit_reset': null,
    'usage': usage,
    'usage_daily': 0.25,
    'usage_weekly': 1,
    'usage_monthly': usage,
    'is_free_tier': false,
  },
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('request', () {
    test('POSTs the messages, the fallback models, temperature 0 and the '
        'data policy, with the key and the attribution headers', () async {
      final server = FakeCloudHttpClient(
        _always(() => sseText(fixture('openrouter_stream.sse'))),
      );

      await _collect(testClient(server).stream(testRequest).words);

      final request = server.requests.single;
      expect(request.method, 'POST');
      expect(
        request.url,
        Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
      );
      expect(request.headers['Authorization'], 'Bearer ${testKey.value}');
      expect(
        request.headers['HTTP-Referer'],
        'https://github.com/nullhtp/feel-you',
      );
      expect(request.headers['X-Title'], 'Feel You');
      expect(request.headers['Content-Type'], 'application/json');
      expect(request.headers['Accept'], 'text/event-stream');
      expect(request.request.followRedirects, isFalse);
      expect(request.json, {
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
    });

    test('a JSON answer asks for a JSON object; with data collection '
        'allowed there is no provider field', () async {
      final server = FakeCloudHttpClient(
        _always(() => sseText(fixture('openrouter_json_answer.sse'))),
      );
      final client = testClient(
        server,
        settings: CloudSettings(denyDataCollection: false),
      );

      await _collect(
        client
            .stream(
              CloudRequest(
                messages: const [CloudMessage.user('Read the sign.')],
                models: const ['openai/gpt-4o-mini'],
                jsonAnswer: true,
              ),
            )
            .fragments,
      );

      final body = server.requests.single.json;
      expect(body['response_format'], {'type': 'json_object'});
      expect(body.containsKey('provider'), isFalse);
      expect(body['model'], 'openai/gpt-4o-mini');
      expect(body['models'], ['openai/gpt-4o-mini']);
    });

    test('goes to the base URL of the settings', () async {
      final server = FakeCloudHttpClient(
        _always(() => sseText(fixture('openrouter_stream.sse'))),
      );
      final client = testClient(
        server,
        settings: CloudSettings(
          baseUrl: parseCloudBaseUrl('https://x.test/v1'),
        ),
      );

      await _collect(client.stream(testRequest).words);

      expect(
        server.requests.single.url,
        Uri.parse('https://x.test/v1/chat/completions'),
      );
    });

    test('no key: the no-key error and nothing sent', () async {
      final server = FakeCloudHttpClient(
        _always(() => sseText(fixture('openrouter_stream.sse'))),
      );

      final result = await _collect(
        testClient(server, noKey: true).stream(testRequest).words,
      );

      expect(result.error, isA<CloudNoKey>());
      expect(result.items, isEmpty);
      expect(server.requests, isEmpty);
    });

    test('nothing is sent until the answer is listened to', () async {
      final server = FakeCloudHttpClient(
        _always(() => sseText(fixture('openrouter_stream.sse'))),
      );
      final completion = testClient(server).stream(testRequest);
      await pumpEventQueue();
      expect(server.requests, isEmpty);

      await _collect(completion.words);

      expect(server.requests, hasLength(1));
    });

    test(
      'a redirect is not followed: the other error with its status',
      () async {
        final server = FakeCloudHttpClient(
          _always(
            () => http.StreamedResponse(
              const Stream.empty(),
              302,
              headers: {'location': 'https://elsewhere.test/'},
            ),
          ),
        );

        final result = await _collect(
          testClient(server).stream(testRequest).words,
        );

        expect(result.error, const CloudOtherError(302));
        expect(server.requests, hasLength(1));
      },
    );

    test('a request needs at least one model', () {
      expect(
        () => CloudRequest(messages: const [], models: const []),
        throwsArgumentError,
      );
    });
  });

  group('streamed answer', () {
    test('a recorded OpenRouter stream gives its words in order and its '
        'usage once', () async {
      final usage = <CloudUsage>[];
      final server = FakeCloudHttpClient(
        _always(() => sseText(fixture('openrouter_stream.sse'))),
      );

      final result = await _collect(
        testClient(server, usage: usage).stream(testRequest).words,
      );

      expect(result.items, _fixtureWords);
      expect(result.error, isNull);
      expect(usage, [
        const CloudUsage(
          promptTokens: 24,
          completionTokens: 9,
          totalTokens: 33,
          cost: 0.0000054,
        ),
      ]);
    });

    test('the same words however the bytes are cut', () async {
      final bytes = utf8.encode(fixture('openrouter_stream.sse'));
      for (final size in [1, 5, 17, 100]) {
        final server = FakeCloudHttpClient(
          _always(
            () => sseResponse(
              Stream.fromIterable([
                for (var i = 0; i < bytes.length; i += size)
                  bytes.sublist(
                    i,
                    i + size > bytes.length ? bytes.length : i + size,
                  ),
              ]),
            ),
          ),
        );

        final result = await _collect(
          testClient(server).stream(testRequest).words,
        );

        expect(result.items, _fixtureWords, reason: 'size $size');
      }
    });

    test('fragments are the pieces as sent, for a JSON answer', () async {
      final server = FakeCloudHttpClient(
        _always(() => sseText(fixture('openrouter_json_answer.sse'))),
      );

      final result = await _collect(
        testClient(server).stream(testRequest).fragments,
      );

      expect(result.items, [
        '{"text":"Door',
        ' on the left","urgent":',
        'true}',
      ]);
      expect(jsonDecode(result.items.join()), {
        'text': 'Door on the left',
        'urgent': true,
      });
    });

    test('each word is released as soon as whitespace ends it', () async {
      final body = BodyController();
      final server = FakeCloudHttpClient(
        _always(() => sseResponse(body.stream)),
      );
      final result = Collected.of(testClient(server).stream(testRequest).words);

      body.content('Hel');
      await pumpEventQueue();
      expect(result.items, isEmpty);

      body.content('lo wor');
      await pumpEventQueue();
      expect(result.items, ['Hello']);

      body
        ..content('ld, how')
        ..content(' are you?');
      await pumpEventQueue();
      expect(result.items, ['Hello', 'world,', 'how', 'are']);

      body
        ..event(contentChunk('', finishReason: 'stop'))
        ..event('[DONE]');
      await result.ended.future;
      expect(result.items, ['Hello', 'world,', 'how', 'are', 'you?']);
      expect(result.error, isNull);
      await body.close();
    });

    test('a stream that ends after its finish chunk but without [DONE] is '
        'whole', () async {
      final server = FakeCloudHttpClient(
        _always(
          () => sseText(
            'data: ${contentChunk('All good')}\n\n'
            'data: ${contentChunk('', finishReason: 'stop')}\n\n',
          ),
        ),
      );

      final result = await _collect(
        testClient(server).stream(testRequest).words,
      );

      expect(result.items, ['All', 'good']);
      expect(result.error, isNull);
    });

    test('a stream cut off before its end is offline, without the '
        'unfinished word', () async {
      final server = FakeCloudHttpClient(
        _always(() => sseText('data: ${contentChunk('Hello wor')}\n\n')),
      );

      final result = await _collect(
        testClient(server).stream(testRequest).words,
      );

      expect(result.items, ['Hello']);
      expect(result.error, isA<CloudOffline>());
    });

    test('events that are not JSON chunks are skipped', () async {
      final server = FakeCloudHttpClient(
        _always(
          () => sseText(
            'data: not json\n\ndata: [1, 2]\n\ndata: {"choices": "x"}\n\n'
            'event: other\ndata: ${contentChunk('fine ')}\n\n'
            'data: [DONE]\n\n',
          ),
        ),
      );

      final result = await _collect(
        testClient(server).stream(testRequest).words,
      );

      expect(result.items, ['fine']);
      expect(result.error, isNull);
    });

    test('words or fragments, not both', () {
      final completion = testClient(
        FakeCloudHttpClient(_neverAnswers),
      ).stream(testRequest);

      expect(completion.words, same(completion.words));
      expect(() => completion.fragments, throwsStateError);
    });
  });

  group('first-token timeout', () {
    test('is 5 seconds by default', () {
      expect(
        const CloudTimingConfig().firstTokenTimeout,
        const Duration(seconds: 5),
      );
      expect(
        ProviderContainer().read(cloudTimingConfigProvider).firstTokenTimeout,
        const Duration(seconds: 5),
      );
    });

    test('keep-alive comments and empty chunks do not count: the timeout '
        'error, and the connection closed', () async {
      final body = BodyController();
      late ReceivedRequest received;
      final server = FakeCloudHttpClient((request) async {
        received = request;
        return sseResponse(body.stream);
      });
      final keepAlive = Timer.periodic(
        const Duration(milliseconds: 50),
        (_) => body.add(': OPENROUTER PROCESSING\n\n'),
      );
      body.event(contentChunk(''));
      final watch = Stopwatch()..start();

      final result = await _collect(
        testClient(server, timing: _fastTiming).stream(testRequest).words,
      );
      keepAlive.cancel();

      expect(result.error, isA<CloudTimeout>());
      expect(result.items, isEmpty);
      expect(
        watch.elapsed,
        greaterThanOrEqualTo(_fastTiming.firstTokenTimeout),
      );
      expect(body.isCancelled, isTrue, reason: 'the connection is closed');
      await received.abortTrigger!.timeout(const Duration(seconds: 1));
    });

    test(
      'no response at all: the timeout error, and the request aborted',
      () async {
        final server = FakeCloudHttpClient(_neverAnswers);

        final result = await _collect(
          testClient(server, timing: _fastTiming).stream(testRequest).words,
        );

        expect(result.error, isA<CloudTimeout>());
      },
    );

    test('a first token in time: no timeout, however slow the rest', () async {
      final body = BodyController();
      final server = FakeCloudHttpClient(
        _always(() => sseResponse(body.stream)),
      );
      final result = Collected.of(
        testClient(server, timing: _fastTiming).stream(testRequest).words,
      );

      body.content('Slow ');
      await Future<void>.delayed(_fastTiming.firstTokenTimeout * 2);
      body
        ..content('answer')
        ..event('[DONE]');
      await result.ended.future;

      expect(result.items, ['Slow', 'answer']);
      expect(result.error, isNull);
      await body.close();
    });
  });

  group('cancellation', () {
    test(
      'mid-answer: the connection is closed, nothing more is released',
      () async {
        final body = BodyController();
        final server = FakeCloudHttpClient(
          _always(() => sseResponse(body.stream)),
        );
        final completion = testClient(server).stream(testRequest);
        final result = Collected.of(completion.words);
        body.content('First wor');
        await pumpEventQueue();
        expect(result.items, ['First']);

        await completion.cancel();
        body
          ..content('d more ')
          ..event('[DONE]');
        await result.ended.future;

        expect(body.isCancelled, isTrue);
        expect(result.items, ['First']);
        expect(result.error, isNull);
        expect(completion.isCancelled, isTrue);
      },
    );

    test(
      'before the response: the request is aborted, nothing released',
      () async {
        late ReceivedRequest received;
        final server = FakeCloudHttpClient((request) {
          received = request;
          return _neverAnswers(request);
        });
        final completion = testClient(server).stream(testRequest);
        final result = Collected.of(completion.words);
        await pumpEventQueue();
        expect(server.requests, hasLength(1));

        await completion.cancel();
        await result.ended.future;

        await received.abortTrigger!.timeout(const Duration(seconds: 1));
        expect(result.items, isEmpty);
        expect(result.error, isNull);
      },
    );

    test('after the answer has ended: nothing happens', () async {
      final server = FakeCloudHttpClient(
        _always(() => sseText(fixture('openrouter_stream.sse'))),
      );
      final completion = testClient(server).stream(testRequest);
      final result = await _collect(completion.words);

      await completion.cancel();

      expect(result.items, _fixtureWords);
      expect(completion.isCancelled, isFalse);
    });

    test('a listener that stops listening cancels the request', () async {
      final body = BodyController();
      final server = FakeCloudHttpClient(
        _always(() => sseResponse(body.stream)),
      );
      final completion = testClient(server).stream(testRequest);
      final first = Completer<String>();
      final subscription = completion.words.listen(first.complete);
      body.content('One ');

      expect(await first.future, 'One');
      await subscription.cancel();

      expect(body.isCancelled, isTrue);
      expect(completion.isCancelled, isTrue);
    });

    test('words queued for a paused listener are dropped', () async {
      final body = BodyController();
      final server = FakeCloudHttpClient(
        _always(() => sseResponse(body.stream)),
      );
      final completion = testClient(server).stream(testRequest);
      final words = <String>[];
      final done = Completer<void>();
      final subscription = completion.words.listen(
        words.add,
        onDone: done.complete,
      );
      body.content('One ');
      await pumpEventQueue();
      expect(words, ['One']);

      subscription.pause();
      body.content('two three ');
      await pumpEventQueue();
      await completion.cancel();
      subscription.resume();
      await done.future;

      expect(words, ['One']);
      await subscription.cancel();
    });
  });

  group('errors', () {
    test('each status code maps to its case', () async {
      final expected = <int, Matcher>{
        401: isA<CloudKeyRejected>(),
        402: isA<CloudLimitExhausted>(),
        404: isA<CloudModelUnavailable>(),
        502: isA<CloudModelUnavailable>(),
        503: isA<CloudModelUnavailable>(),
        408: isA<CloudTimeout>(),
        504: isA<CloudTimeout>(),
        400: equals(const CloudOtherError(400)),
        429: equals(const CloudOtherError(429)),
        500: equals(const CloudOtherError(500)),
      };
      for (final MapEntry(key: status, value: matcher) in expected.entries) {
        final server = FakeCloudHttpClient(
          _always(
            () => jsonResponse(status, {
              'error': {'code': status, 'message': 'Nope'},
            }),
          ),
        );

        final result = await _collect(
          testClient(server).stream(testRequest).words,
        );

        expect(result.error, matcher, reason: 'HTTP $status');
        expect(result.items, isEmpty);
      }
    });

    test(
      'every fallback model failed: a 200 with only an error event',
      () async {
        final server = FakeCloudHttpClient(
          _always(() => sseText(fixture('openrouter_all_models_failed.sse'))),
        );

        final result = await _collect(
          testClient(server).stream(testRequest).words,
        );

        expect(result.error, isA<CloudModelUnavailable>());
        expect(result.items, isEmpty);
      },
    );

    test('every fallback model failed: a 200 with a JSON error body', () async {
      final server = FakeCloudHttpClient(
        _always(
          () => jsonResponse(200, {
            'error': {'code': 503, 'message': 'No endpoints found'},
          }),
        ),
      );

      final result = await _collect(
        testClient(server).stream(testRequest).words,
      );

      expect(result.error, isA<CloudModelUnavailable>());
    });

    test('a 200 JSON body without an error is the other error', () async {
      final server = FakeCloudHttpClient(
        _always(() => jsonResponse(200, {'choices': <Object>[]})),
      );

      final result = await _collect(
        testClient(server).stream(testRequest).words,
      );

      expect(result.error, const CloudOtherError(200));
    });

    test('an error mid-answer comes after the words already released, '
        'without the unfinished one', () async {
      final server = FakeCloudHttpClient(
        _always(() => sseText(fixture('openrouter_mid_stream_error.sse'))),
      );

      final result = await _collect(
        testClient(server).stream(testRequest).words,
      );

      expect(result.items, ['The', 'answer', 'is']);
      expect(result.error, isA<CloudModelUnavailable>());
    });

    test('an error on the choice, without one at the top level', () async {
      final server = FakeCloudHttpClient(
        _always(
          () => sseText(
            'data: ${jsonEncode({
              'choices': [
                {
                  'delta': {'content': ''},
                  'finish_reason': 'error',
                  'error': {'code': 402, 'message': 'x'},
                },
              ],
            })}\n\n',
          ),
        ),
      );

      final result = await _collect(
        testClient(server).stream(testRequest).words,
      );

      expect(result.error, isA<CloudLimitExhausted>());
    });

    test('no connection is offline', () async {
      final failures = <Exception>[
        const SocketException('Connection refused'),
        http.ClientException('Failed host lookup: openrouter.ai'),
        const HandshakeException('CERTIFICATE_VERIFY_FAILED'),
        const HttpException('Connection closed before full header'),
      ];
      for (final failure in failures) {
        final server = FakeCloudHttpClient((_) async => throw failure);

        final result = await _collect(
          testClient(server).stream(testRequest).words,
        );

        expect(result.error, isA<CloudOffline>(), reason: '$failure');
      }
    });

    test('a connection lost mid-answer is offline', () async {
      final body = BodyController();
      final server = FakeCloudHttpClient(
        _always(() => sseResponse(body.stream)),
      );
      final result = Collected.of(testClient(server).stream(testRequest).words);

      body.content('Half an ans');
      await pumpEventQueue();
      body.addError(
        http.ClientException('Connection closed while receiving data'),
      );
      await result.ended.future;

      expect(result.items, ['Half', 'an']);
      expect(result.error, isA<CloudOffline>());
    });

    test('anything else is the other error', () async {
      final server = FakeCloudHttpClient((_) async => throw StateError('bug'));

      final result = await _collect(
        testClient(server).stream(testRequest).words,
      );

      expect(result.error, const CloudOtherError(null));
    });
  });

  group('no key or response body in errors and logs', () {
    test('a rejected key whose body repeats it', () async {
      final echo = 'Invalid key ${testKey.value} for user secret-user-id';
      late Collected<String> result;
      final logs = await recordingLogs(() async {
        final server = FakeCloudHttpClient(
          _always(
            () => jsonResponse(401, {
              'error': {'code': 401, 'message': echo},
            }),
          ),
        );
        result = await _collect(testClient(server).stream(testRequest).words);
      });

      expect(result.error, isA<CloudKeyRejected>());
      for (final text in ['${result.error}', ...logs]) {
        expect(text, isNot(contains(testKey.value)));
        expect(text, isNot(contains('c0ffee42')));
        expect(text, isNot(contains('secret-user-id')));
      }
      expect(logs, isNotEmpty, reason: 'the failure is logged');
    });

    test('an error event whose message repeats the key', () async {
      late Collected<String> result;
      final chunk = jsonEncode({
        'error': {'code': 'server_error', 'message': 'Echo ${testKey.value}'},
        'choices': [
          {
            'delta': {'content': ''},
            'finish_reason': 'error',
          },
        ],
      });
      final logs = await recordingLogs(() async {
        final server = FakeCloudHttpClient(
          _always(() => sseText('data: $chunk\n\n')),
        );
        result = await _collect(testClient(server).stream(testRequest).words);
      });

      for (final text in ['${result.error}', ...logs]) {
        expect(text, isNot(contains(testKey.value)));
        expect(text, isNot(contains('Echo')));
      }
    });

    test('a request and a message print no content', () {
      expect('$testRequest', isNot(contains('How are you?')));
      expect(
        '${const CloudMessage.user('my secret')}',
        isNot(contains('secret')),
      );
    });
  });

  group('key information', () {
    late FakeCloudHttpClient server;
    late InMemoryCloudPreferencesStore store;
    late DateTime now;

    setUp(() {
      server = FakeCloudHttpClient(
        _always(() => jsonResponse(200, _keyResponse())),
      );
      store = InMemoryCloudPreferencesStore();
      now = DateTime(2026, 10, 19, 9);
    });

    OpenRouterClient client({CloudKey? key, CloudSettings? settings}) =>
        testClient(
          server,
          key: key,
          settings: settings,
          store: store,
          now: () => now,
          timing: _fastTiming,
        );

    test('GET {base URL}/key with the key, read and saved', () async {
      final info = await client().keyInfo();

      final request = server.requests.single;
      expect(request.method, 'GET');
      expect(request.url, Uri.parse('https://openrouter.ai/api/v1/key'));
      expect(request.headers['Authorization'], 'Bearer ${testKey.value}');
      expect(
        request.headers['HTTP-Referer'],
        'https://github.com/nullhtp/feel-you',
      );
      expect(request.headers['X-Title'], 'Feel You');
      expect(request.request.followRedirects, isFalse);
      expect(info.limit, 10);
      expect(info.limitRemaining, 7.5);
      expect(info.usage, 2.5);
      expect(info.key, testKey.masked);
      expect(info.fetchedAt, now.toUtc());
      expect(store.readKeyInfo(), info);
    });

    test('at most once a day for the same key and base URL', () async {
      final first = await client().keyInfo();
      now = DateTime(2026, 10, 19, 23, 59);
      expect(await client().keyInfo(), first);
      expect(server.requests, hasLength(1));

      now = DateTime(2026, 10, 20, 0, 1);
      server.handler = _always(() => jsonResponse(200, _keyResponse(usage: 3)));
      final nextDay = await client().keyInfo();

      expect(server.requests, hasLength(2));
      expect(nextDay.usage, 3);
    });

    test('another key or base URL is fetched again the same day', () async {
      await client().keyInfo();

      final other = CloudKey.parse('sk-or-v1-${'0badf00d' * 8}');
      await client(key: other).keyInfo();
      expect(server.requests, hasLength(2));

      await client(
        key: other,
        settings: CloudSettings(
          baseUrl: parseCloudBaseUrl('https://x.test/v1'),
        ),
      ).keyInfo();
      expect(server.requests, hasLength(3));
      expect(server.requests.last.url, Uri.parse('https://x.test/v1/key'));
    });

    test('two calls at once share one request', () async {
      final c = client();

      final both = await Future.wait([c.keyInfo(), c.keyInfo()]);

      expect(both[0], both[1]);
      expect(server.requests, hasLength(1));
    });

    test('failures save nothing', () async {
      final cases = <FakeHandler, Matcher>{
        _always(() => jsonResponse(401, {'error': 'x'})):
            isA<CloudKeyRejected>(),
        _always(() => jsonResponse(402, {'error': 'x'})):
            isA<CloudLimitExhausted>(),
        _always(() => jsonResponse(404, {'error': 'x'})): equals(
          const CloudOtherError(404),
        ),
        _always(() => jsonResponse(200, {'nope': true})): equals(
          const CloudOtherError(200),
        ),
        _always(
          () => http.StreamedResponse(Stream.value(utf8.encode('{bad')), 200),
        ): equals(
          const CloudOtherError(200),
        ),
        (_) async => throw const SocketException('refused'):
            isA<CloudOffline>(),
        _neverAnswers: isA<CloudTimeout>(),
      };
      for (final MapEntry(key: handler, value: matcher) in cases.entries) {
        server.handler = handler;

        await expectLater(client().keyInfo(), throwsA(matcher));
      }
      expect(store.readKeyInfo(), isNull);
    });

    test('no key: the no-key error and nothing sent', () async {
      final c = testClient(server, noKey: true, store: store);

      await expectLater(c.keyInfo(), throwsA(isA<CloudNoKey>()));
      expect(server.requests, isEmpty);
    });
  });

  group('openRouterClientProvider', () {
    test('uses the saved key, the settings and the usage totals of the app, '
        'and sends nothing by itself', () async {
      final server = FakeCloudHttpClient(
        _always(() => sseText(fixture('openrouter_stream.sse'))),
      );
      final container = ProviderContainer(
        overrides: [
          cloudHttpClientProvider.overrideWithValue(server),
          cloudKeyStoreProvider.overrideWithValue(
            InMemoryCloudKeyStore(testKey),
          ),
          cloudClockProvider.overrideWithValue(() => DateTime(2026, 10, 19)),
        ],
      );
      addTearDown(container.dispose);
      await container
          .read(cloudSettingsProvider.notifier)
          .setBaseUrl('https://x.test/api');
      final client = container.read(openRouterClientProvider);
      await pumpEventQueue();
      expect(server.requests, isEmpty);

      final result = await _collect(client.stream(testRequest).words);
      await pumpEventQueue();

      expect(result.items, _fixtureWords);
      final request = server.requests.single;
      expect(request.url, Uri.parse('https://x.test/api/chat/completions'));
      expect(request.headers['Authorization'], 'Bearer ${testKey.value}');
      final totals = container.read(cloudUsageProvider);
      expect(totals.today.answers, 1);
      expect(totals.today.totalTokens, 33);
      expect(totals.thisMonth.cost, 0.0000054);
    });

    test('without a saved key: the no-key error', () async {
      final server = FakeCloudHttpClient(_neverAnswers);
      final container = ProviderContainer(
        overrides: [cloudHttpClientProvider.overrideWithValue(server)],
      );
      addTearDown(container.dispose);

      final result = await _collect(
        container.read(openRouterClientProvider).stream(testRequest).words,
      );

      expect(result.error, isA<CloudNoKey>());
      expect(server.requests, isEmpty);
    });
  });
}
