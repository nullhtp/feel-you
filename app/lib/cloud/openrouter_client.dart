import 'dart:async';
import 'dart:convert';
import 'dart:io' show HttpException, SocketException, TlsException;
import 'dart:typed_data' show BytesBuilder;

import 'package:feel_you/cloud/cloud_error.dart';
import 'package:feel_you/cloud/cloud_key.dart';
import 'package:feel_you/cloud/cloud_key_store.dart';
import 'package:feel_you/cloud/cloud_preferences.dart';
import 'package:feel_you/cloud/cloud_settings.dart';
import 'package:feel_you/cloud/cloud_usage.dart';
import 'package:feel_you/cloud/sse_parser.dart';
import 'package:feel_you/cloud/word_buffer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// Who wrote a [CloudMessage].
enum CloudRole {
  /// Instructions for the model.
  system,

  /// The user's side of the conversation.
  user,

  /// An earlier answer of the model.
  assistant,
}

/// One message of a [CloudRequest].
@immutable
final class CloudMessage {
  const CloudMessage(this.role, this.content);

  /// Instructions for the model.
  const CloudMessage.system(String content) : this(CloudRole.system, content);

  /// What the user said or asked.
  const CloudMessage.user(String content) : this(CloudRole.user, content);

  /// An earlier answer, for a follow-up in the same context.
  const CloudMessage.assistant(String content)
    : this(CloudRole.assistant, content);

  final CloudRole role;
  final String content;

  Map<String, Object> toJson() => {'role': role.name, 'content': content};

  /// The role and the length only: the content is the user's own.
  @override
  String toString() => 'CloudMessage(${role.name}, ${content.length} chars)';
}

/// What to ask the cloud.
@immutable
final class CloudRequest {
  /// Creates a request for [messages], answered by the first of [models]
  /// that can (OpenRouter's fallback list, in order of preference).
  ///
  /// With [jsonAnswer] the model is asked for a JSON object; read it from
  /// [CloudCompletion.fragments], not as words.
  CloudRequest({
    required List<CloudMessage> messages,
    required List<String> models,
    this.jsonAnswer = false,
  }) : messages = List.unmodifiable(messages),
       models = List.unmodifiable(models) {
    if (models.isEmpty) {
      throw ArgumentError.value(models, 'models', 'must not be empty');
    }
  }

  final List<CloudMessage> messages;

  /// Model IDs such as `openai/gpt-4o-mini`, most preferred first.
  final List<String> models;

  /// Whether the answer must be a JSON object.
  final bool jsonAnswer;

  /// The request body, with the data policy of [settings].
  Map<String, Object> toJson(CloudSettings settings) => {
    // `model` for endpoints that only know the OpenAI API; OpenRouter
    // routes by `models` and falls back along it.
    'model': models.first,
    'models': models,
    'messages': [for (final message in messages) message.toJson()],
    'stream': true,
    'temperature': 0,
    if (settings.denyDataCollection) 'provider': {'data_collection': 'deny'},
    if (jsonAnswer) 'response_format': {'type': 'json_object'},
  };

  @override
  String toString() =>
      'CloudRequest(${messages.length} messages, models: $models, '
      'json: $jsonAnswer)';
}

/// How long the client waits.
@immutable
final class CloudTimingConfig {
  const CloudTimingConfig({
    this.firstTokenTimeout = const Duration(seconds: 5),
    this.keyInfoTimeout = const Duration(seconds: 5),
  });

  /// From sending a request to the first piece of its answer.
  final Duration firstTokenTimeout;

  /// From sending a key-information request to the end of its response.
  final Duration keyInfoTimeout;
}

/// Provides the [CloudTimingConfig]. Tests override it with shorter times.
final cloudTimingConfigProvider = Provider<CloudTimingConfig>(
  (ref) => const CloudTimingConfig(),
);

/// Provides the HTTP client of the cloud requests, created when the first
/// request needs it and closed with the provider container.
final cloudHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

/// Provides the [OpenRouterClient], with the saved key, the cloud settings
/// and the usage totals of the app.
final openRouterClientProvider = Provider<OpenRouterClient>(
  (ref) => OpenRouterClient(
    httpClient: ref.watch(cloudHttpClientProvider),
    readKey: () => ref.read(cloudKeyProvider.future),
    readSettings: () => ref.read(cloudSettingsProvider),
    store: ref.watch(cloudPreferencesStoreProvider),
    recordUsage: (usage) =>
        unawaited(ref.read(cloudUsageProvider.notifier).add(usage)),
    now: ref.watch(cloudClockProvider),
    timing: ref.watch(cloudTimingConfigProvider),
  ),
);

/// Talks to OpenRouter's OpenAI-compatible API, or any endpoint that
/// speaks it, with the assistant's key.
///
/// Sends nothing on its own: only [stream] and [keyInfo] make requests.
/// Every failure is a [CloudError]; nothing it throws, emits or logs
/// contains the key or a response body.
class OpenRouterClient {
  OpenRouterClient({
    required http.Client httpClient,
    required Future<CloudKey?> Function() readKey,
    required CloudSettings Function() readSettings,
    required CloudPreferencesStore store,
    required void Function(CloudUsage usage) recordUsage,
    DateTime Function() now = DateTime.now,
    CloudTimingConfig timing = const CloudTimingConfig(),
  }) : _http = httpClient,
       _readKey = readKey,
       _readSettings = readSettings,
       _store = store,
       _recordUsage = recordUsage,
       _now = now,
       _timing = timing;

  /// The `HTTP-Referer` header: the app's page, for OpenRouter's app
  /// attribution.
  static const referer = 'https://github.com/nullhtp/feel-you';

  /// The `X-Title` header: the app's name in OpenRouter's rankings.
  static const title = 'Feel You';

  /// The largest response body read in full (an error object or the key
  /// information), in bytes.
  static const maxBodyBytes = 64 * 1024;

  final http.Client _http;
  final Future<CloudKey?> Function() _readKey;
  final CloudSettings Function() _readSettings;
  final CloudPreferencesStore _store;
  final void Function(CloudUsage usage) _recordUsage;
  final DateTime Function() _now;
  final CloudTimingConfig _timing;

  Future<CloudKeyInfo>? _pendingKeyInfo;

  /// Asks the cloud for [request] and streams the answer.
  ///
  /// The request is sent when the completion's [CloudCompletion.words] or
  /// [CloudCompletion.fragments] are first listened to.
  CloudCompletion stream(CloudRequest request) =>
      CloudCompletion._(this, request);

  /// The key's limit and spend.
  ///
  /// Fetched with `GET {base URL}/key` at most once per local day for the
  /// same key and base URL: on the same day the saved value is returned
  /// without a request. A failure throws a [CloudError] and saves nothing.
  Future<CloudKeyInfo> keyInfo() {
    final pending = _pendingKeyInfo;
    if (pending != null) return pending;
    final fetch = _keyInfo();
    _pendingKeyInfo = fetch;
    return fetch.whenComplete(() => _pendingKeyInfo = null);
  }

  Future<CloudKeyInfo> _keyInfo() async {
    final key = await _readKeyOrNull();
    if (key == null) throw const CloudNoKey();
    final settings = _readSettings();
    final cached = _store.readKeyInfo();
    if (cached != null &&
        cached.isCurrent(
          key: key.masked,
          baseUrl: settings.baseUrl,
          now: _now(),
        )) {
      return cached;
    }
    final abort = Completer<void>();
    final timer = Timer(_timing.keyInfoTimeout, abort.complete);
    try {
      final request =
          http.AbortableRequest(
              'GET',
              settings.endpoint('key'),
              abortTrigger: abort.future,
            )
            ..followRedirects = false
            ..headers.addAll({..._headers(key), 'Accept': 'application/json'});
      final response = await _http.send(request);
      if (response.statusCode != 200) {
        _discard(response);
        throw switch (response.statusCode) {
          401 => const CloudKeyRejected(),
          402 => const CloudLimitExhausted(),
          408 || 504 => const CloudTimeout(),
          final status => CloudOtherError(status),
        };
      }
      final body = await _readBody(response);
      final info = CloudKeyInfo.fromResponse(
        jsonDecode(body),
        key: key.masked,
        baseUrl: settings.baseUrl,
        fetchedAt: _now(),
      );
      if (info == null) throw const CloudOtherError(200);
      await _store.writeKeyInfo(info);
      return info;
    } on CloudError catch (error) {
      debugPrint('Cloud key information failed: $error');
      rethrow;
    } on http.RequestAbortedException {
      // Only the timer aborts this request.
      const error = CloudTimeout();
      debugPrint('Cloud key information failed: $error');
      throw error;
    } on FormatException {
      const error = CloudOtherError(200);
      debugPrint('Cloud key information failed: $error');
      throw error;
    } on Object catch (exception) {
      final error = _networkError(exception);
      debugPrint('Cloud key information failed: $error');
      throw error;
    } finally {
      timer.cancel();
    }
  }

  Future<CloudKey?> _readKeyOrNull() async {
    try {
      return await _readKey();
    } on Object {
      // The key provider never fails; a store that does means no key.
      return null;
    }
  }

  /// The headers of every request: the key and OpenRouter's attribution.
  static Map<String, String> _headers(CloudKey key) => {
    'Authorization': 'Bearer ${key.value}',
    'HTTP-Referer': referer,
    'X-Title': title,
  };

  /// Reads [response]'s body as text, up to [maxBodyBytes].
  static Future<String> _readBody(http.StreamedResponse response) async {
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in response.stream) {
      bytes.add(chunk);
      if (bytes.length > maxBodyBytes) throw const CloudOtherError(200);
    }
    return utf8.decode(bytes.takeBytes(), allowMalformed: true);
  }

  /// Closes [response] without reading its body, which may echo the
  /// request.
  static void _discard(http.StreamedResponse response) =>
      unawaited(response.stream.listen(null, onError: (Object _) {}).cancel());

  /// The error for an exception thrown by the connection.
  static CloudError _networkError(Object error) => switch (error) {
    http.ClientException() ||
    SocketException() ||
    HttpException() ||
    TlsException() => const CloudOffline(),
    _ => const CloudOtherError(null),
  };
}

/// One answer being streamed from the cloud.
///
/// Listen to [words] for text to read, or to [fragments] for the raw
/// pieces (a JSON answer); only one of them, once. Listening sends the
/// request. The stream ends normally after the last word, with a
/// [CloudError] when the request fails, and without an error when it is
/// [cancel]led.
final class CloudCompletion {
  CloudCompletion._(this._client, this._request);

  final OpenRouterClient _client;
  final CloudRequest _request;

  late final _out = StreamController<String>(
    onListen: () => unawaited(_run()),
    onCancel: _stop,
  );

  /// Set when [words] is chosen: splits the pieces into words.
  WordBuffer? _words;
  Stream<String>? _stream;

  final _abort = Completer<void>();
  Timer? _firstTokenTimer;
  StreamSubscription<SseEvent>? _events;

  /// Whether the answer has ended, failed or been cancelled: nothing more
  /// is emitted.
  bool _finished = false;
  bool _cancelled = false;

  /// Whether a chunk with a finish reason has arrived, so the answer is
  /// whole even if the connection ends before `[DONE]`.
  bool _sawFinish = false;

  /// The answer as words, each released as soon as whitespace ends it, and
  /// the last one when the answer ends.
  Stream<String> get words => _choose(words: true);

  /// The answer as the pieces the endpoint sent, unchanged.
  Stream<String> get fragments => _choose(words: false);

  /// Whether [cancel] was called, or the listener stopped listening, before
  /// the answer ended.
  bool get isCancelled => _cancelled;

  Stream<String> _choose({required bool words}) {
    final chosen = _stream;
    if (chosen != null) {
      if (words != (_words != null)) {
        throw StateError('Listen to either words or fragments, not both.');
      }
      return chosen;
    }
    if (words) _words = WordBuffer();
    // Words already queued for a paused listener are dropped on cancel.
    return _stream = _out.stream.where((_) => !_cancelled);
  }

  /// Stops the answer: closes the connection and ends the stream, without
  /// releasing anything more. Does nothing once the answer has ended.
  Future<void> cancel() async => _stop();

  Future<void> _stop() async {
    if (_finished) return;
    _finished = true;
    _cancelled = true;
    _firstTokenTimer?.cancel();
    if (!_abort.isCompleted) _abort.complete();
    unawaited(_out.close());
    await _events?.cancel();
  }

  Future<void> _run() async {
    final key = await _client._readKeyOrNull();
    if (_finished) return;
    if (key == null) {
      _fail(const CloudNoKey());
      return;
    }
    final settings = _client._readSettings();
    final request =
        http.AbortableRequest(
            'POST',
            settings.endpoint('chat/completions'),
            abortTrigger: _abort.future,
          )
          ..followRedirects = false
          ..headers.addAll({
            ...OpenRouterClient._headers(key),
            'Content-Type': 'application/json',
            'Accept': 'text/event-stream',
          })
          ..bodyBytes = utf8.encode(jsonEncode(_request.toJson(settings)));

    _firstTokenTimer = Timer(
      _client._timing.firstTokenTimeout,
      () => _fail(const CloudTimeout()),
    );
    final http.StreamedResponse response;
    try {
      response = await _client._http.send(request);
    } on Object catch (error) {
      _fail(OpenRouterClient._networkError(error));
      return;
    }
    if (_finished) {
      OpenRouterClient._discard(response);
      return;
    }
    if (response.statusCode != 200) {
      OpenRouterClient._discard(response);
      _fail(CloudError.fromStatus(response.statusCode));
      return;
    }
    if (response.headers['content-type']?.contains('json') ?? false) {
      await _readErrorBody(response);
      return;
    }
    _events = response.stream
        .transform(const SseParser())
        .listen(
          _onEvent,
          onError: (Object error) =>
              _fail(OpenRouterClient._networkError(error)),
          onDone: _onDone,
        );
  }

  /// A `200` that is JSON rather than an event stream: OpenRouter's error
  /// when every provider failed before the first token.
  Future<void> _readErrorBody(http.StreamedResponse response) async {
    try {
      final body = jsonDecode(await OpenRouterClient._readBody(response));
      final error = body is Map ? body['error'] : null;
      _fail(
        error == null
            ? const CloudOtherError(200)
            : CloudError.fromErrorObject(error),
      );
    } on CloudError catch (error) {
      _fail(error);
    } on FormatException {
      _fail(const CloudOtherError(200));
    } on Object catch (error) {
      _fail(OpenRouterClient._networkError(error));
    }
  }

  void _onEvent(SseEvent event) {
    if (_finished) return;
    final data = event.data.trim();
    if (data == '[DONE]') {
      _complete();
      return;
    }
    final Object? chunk;
    try {
      chunk = jsonDecode(data);
    } on FormatException {
      return;
    }
    if (chunk is! Map) return;
    if (chunk['error'] != null) {
      _fail(CloudError.fromErrorObject(chunk['error']));
      return;
    }
    final usage = CloudUsage.fromJson(chunk['usage']);
    if (usage != null) _client._recordUsage(usage);
    final choices = chunk['choices'];
    if (choices is! List || choices.isEmpty) return;
    final choice = choices.first;
    if (choice is! Map) return;
    final delta = choice['delta'];
    final content = delta is Map ? delta['content'] : null;
    if (content is String && content.isNotEmpty) _emit(content);
    final finishReason = choice['finish_reason'];
    if (finishReason == 'error') {
      _fail(CloudError.fromErrorObject(choice['error']));
    } else if (finishReason is String) {
      _sawFinish = true;
    }
  }

  void _emit(String content) {
    _firstTokenTimer?.cancel();
    final buffer = _words;
    if (buffer == null) {
      _out.add(content);
    } else {
      buffer.add(content).forEach(_out.add);
    }
  }

  void _onDone() {
    if (_finished) return;
    if (_sawFinish) {
      _complete();
    } else {
      // Cut off before the end: the connection was lost.
      _fail(const CloudOffline());
    }
  }

  /// Ends the answer normally, releasing the last word.
  ///
  /// The connection is left to finish on its own, so it can be reused.
  void _complete() {
    if (_finished) return;
    _finished = true;
    _firstTokenTimer?.cancel();
    final last = _words?.flush();
    if (last != null) _out.add(last);
    unawaited(_out.close());
  }

  void _fail(CloudError error) {
    if (_finished) return;
    _finished = true;
    _firstTokenTimer?.cancel();
    if (!_abort.isCompleted) _abort.complete();
    unawaited(_events?.cancel());
    _words?.clear();
    debugPrint('Cloud request failed: $error');
    _out
      ..addError(error)
      ..close();
  }
}
