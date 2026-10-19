import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:feel_you/cloud/cloud.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// A key shaped like a real OpenRouter key, unique to these tests.
final testKey = CloudKey.parse('sk-or-v1-${'c0ffee42' * 7}0123456789abd00d');

/// A recorded OpenRouter stream from `test/cloud/fixtures/`.
String fixture(String name) =>
    File('test/cloud/fixtures/$name').readAsStringSync();

/// A request as the fake endpoint received it.
class ReceivedRequest {
  ReceivedRequest(this.request, this.body);

  final http.BaseRequest request;
  final Uint8List body;

  String get method => request.method;
  Uri get url => request.url;
  Map<String, String> get headers => request.headers;

  /// The body as JSON.
  Map<String, Object?> get json =>
      jsonDecode(utf8.decode(body)) as Map<String, Object?>;

  /// Completes when the client aborts the request (its `abortTrigger`).
  Future<void>? get abortTrigger => switch (request) {
    http.Abortable(:final abortTrigger) => abortTrigger,
    _ => null,
  };
}

/// Answers one request of the fake endpoint.
typedef FakeHandler =
    Future<http.StreamedResponse> Function(ReceivedRequest request);

/// An HTTP client that records every request and answers it with
/// [handler], without any network.
class FakeCloudHttpClient extends http.BaseClient {
  FakeCloudHttpClient(this.handler);

  FakeHandler handler;
  final List<ReceivedRequest> requests = [];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final received = ReceivedRequest(
      request,
      await request.finalize().toBytes(),
    );
    requests.add(received);
    return handler(received);
  }
}

/// A response body the test feeds piece by piece, recording whether the
/// client stopped reading it (closed the connection).
class BodyController {
  BodyController() {
    _controller = StreamController<List<int>>(onCancel: _cancelled.complete);
  }

  late final StreamController<List<int>> _controller;
  final _cancelled = Completer<void>();

  Stream<List<int>> get stream => _controller.stream;

  /// Completes when the client cancels its subscription to the body.
  Future<void> get cancelled => _cancelled.future;
  bool get isCancelled => _cancelled.isCompleted;

  void add(String text) => _controller.add(utf8.encode(text));

  /// Fails the body, as a dropped connection does.
  void addError(Object error) => _controller.addError(error);

  /// Sends one `data:` event.
  void event(String data) => add('data: $data\n\n');

  /// Sends a chunk whose `choices[0].delta.content` is [content].
  void content(String content) => event(contentChunk(content));

  Future<void> close() => _controller.close();
}

/// A chat-completion chunk carrying [content].
String contentChunk(String content, {String? finishReason}) => jsonEncode({
  'id': 'gen-test',
  'object': 'chat.completion.chunk',
  'model': 'openai/gpt-4o-mini',
  'choices': [
    {
      'index': 0,
      'delta': {'role': 'assistant', 'content': content},
      'finish_reason': finishReason,
    },
  ],
});

/// An event stream response with [body].
http.StreamedResponse sseResponse(Stream<List<int>> body, {int status = 200}) =>
    http.StreamedResponse(
      body,
      status,
      headers: {'content-type': 'text/event-stream; charset=utf-8'},
    );

/// An event stream response with the whole of [text].
http.StreamedResponse sseText(String text) =>
    sseResponse(Stream.value(utf8.encode(text)));

/// A response with [status] and a JSON [body].
http.StreamedResponse jsonResponse(int status, Object body) =>
    http.StreamedResponse(
      Stream.value(utf8.encode(jsonEncode(body))),
      status,
      headers: {'content-type': 'application/json'},
    );

/// A client with [http] as its connection, [key] saved (by default
/// [testKey]) and [settings] (by default OpenRouter, data collection
/// denied); the usage it reports is added to [usage].
OpenRouterClient testClient(
  http.Client http, {
  CloudKey? key,
  bool noKey = false,
  CloudSettings? settings,
  CloudPreferencesStore? store,
  List<CloudUsage>? usage,
  DateTime Function()? now,
  CloudTimingConfig timing = const CloudTimingConfig(),
}) => OpenRouterClient(
  httpClient: http,
  readKey: () async => noKey ? null : key ?? testKey,
  readSettings: () => settings ?? CloudSettings(),
  store: store ?? InMemoryCloudPreferencesStore(),
  recordUsage: (u) => usage?.add(u),
  now: now ?? DateTime.now,
  timing: timing,
);

/// A request for one user message, answered by two models in turn.
final testRequest = CloudRequest(
  messages: const [
    CloudMessage.system('Answer in one short sentence.'),
    CloudMessage.user('How are you?'),
  ],
  models: const ['openai/gpt-4o-mini', 'google/gemini-2.5-flash'],
);

/// Collects everything a stream emits: its items, then its error or its
/// end.
class Collected<T> {
  final items = <T>[];
  Object? error;
  bool done = false;

  /// Completes when the stream has ended, with or without an error.
  final ended = Completer<void>();

  static Collected<T> of<T>(Stream<T> stream) {
    final collected = Collected<T>();
    stream.listen(
      collected.items.add,
      onError: (Object error) => collected.error = error,
      onDone: () {
        collected.done = true;
        collected.ended.complete();
      },
    );
    return collected;
  }
}

/// Runs [body] with `debugPrint` recorded into the returned lines.
Future<List<String>> recordingLogs(Future<void> Function() body) async {
  final lines = <String>[];
  final original = debugPrint;
  debugPrint = (message, {wrapWidth}) => lines.add(message ?? '');
  try {
    await body();
  } finally {
    debugPrint = original;
  }
  return lines;
}
