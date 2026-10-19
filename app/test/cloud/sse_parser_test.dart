import 'dart:async';
import 'dart:convert';

import 'package:feel_you/cloud/sse_parser.dart';
import 'package:flutter_test/flutter_test.dart';

import 'cloud_test_helpers.dart';

/// Parses [chunks] of bytes as one event stream.
Future<List<SseEvent>> _parse(List<List<int>> chunks) =>
    Stream.fromIterable(chunks).transform(const SseParser()).toList();

/// Parses [text], sent in one piece.
Future<List<SseEvent>> _parseText(String text) => _parse([utf8.encode(text)]);

/// [bytes] cut into pieces of [size] bytes.
List<List<int>> _cut(List<int> bytes, int size) => [
  for (var i = 0; i < bytes.length; i += size)
    bytes.sublist(i, i + size > bytes.length ? bytes.length : i + size),
];

/// The `choices[0].delta.content` of each event that has one.
List<String> _contents(List<SseEvent> events) => [
  for (final event in events)
    if (event.data != '[DONE]')
      if (((jsonDecode(event.data) as Map)['choices'] as List?)?.firstOrNull
          case {'delta': {'content': final String content}}
          when content.isNotEmpty)
        content,
];

void main() {
  group('OpenRouter streams', () {
    test('a recorded stream gives its chunks, without the comments, and '
        'ends with [DONE]', () async {
      final events = await _parseText(fixture('openrouter_stream.sse'));

      expect(events, hasLength(9));
      expect(events.every((e) => e.type == 'message'), isTrue);
      expect(events.any((e) => e.data.contains('OPENROUTER')), isFalse);
      expect(events.last.data, '[DONE]');
      expect(_contents(events), [
        'Hel',
        'lo wor',
        'ld, how',
        ' are you?',
        ' Ça va.',
      ]);
    });

    test('the same events whatever the chunk size, even inside a line or a '
        'multi-byte character', () async {
      final bytes = utf8.encode(fixture('openrouter_stream.sse'));
      final whole = await _parse([bytes]);
      for (final size in [1, 2, 3, 7, 64, 333]) {
        expect(await _parse(_cut(bytes, size)), whole, reason: 'size $size');
      }
    });

    test('CRLF and CR line ends give the same events as LF', () async {
      final text = fixture('openrouter_stream.sse');
      final lf = await _parseText(text);
      final crlf = text.replaceAll('\n', '\r\n');
      final cr = text.replaceAll('\n', '\r');

      expect(await _parseText(crlf), lf);
      expect(await _parseText(cr), lf);
      // A CRLF cut between its CR and LF is still one line end.
      expect(await _parse(_cut(utf8.encode(crlf), 1)), lf);
    });
  });

  group('event stream format', () {
    test('two data lines are joined with a line break', () async {
      expect(await _parseText('data: first\ndata: second\n\n'), [
        const SseEvent('first\nsecond'),
      ]);
    });

    test('one space after the colon is dropped, other spaces are kept, and '
        'a colon is optional', () async {
      expect(await _parseText('data:a\n\ndata:  b\n\ndata\n\n'), [
        const SseEvent('a'),
        const SseEvent(' b'),
        const SseEvent(''),
      ]);
    });

    test('comments, retry and unknown fields are skipped; event and id are '
        'kept', () async {
      final events = await _parseText(
        ': keep-alive\nretry: 1000\nfoo: bar\nevent: delta\nid: 7\n'
        'data: x\n\n: OPENROUTER PROCESSING\n\ndata: y\n\n',
      );

      expect(events, [
        const SseEvent('x', type: 'delta', id: '7'),
        const SseEvent('y', id: '7'),
      ]);
    });

    test('blank lines without data dispatch nothing', () async {
      expect(await _parseText('\n\n\nevent: ping\n\n'), isEmpty);
    });

    test('an unfinished last event is dropped', () async {
      expect(await _parseText('data: whole\n\ndata: cut off'), [
        const SseEvent('whole'),
      ]);
      expect(await _parseText('data: whole\n\ndata: no blank line\n'), [
        const SseEvent('whole'),
      ]);
    });

    test('a leading byte order mark is dropped', () async {
      expect(
        await _parse([
          [0xEF, 0xBB, 0xBF, ...utf8.encode('data: x\n\n')],
        ]),
        [const SseEvent('x')],
      );
    });

    test('malformed UTF-8 does not stop the stream', () async {
      expect(
        await _parse([
          [...utf8.encode('data: a'), 0xFF, ...utf8.encode('b\n\ndata: c\n\n')],
        ]),
        [const SseEvent('a\uFFFDb'), const SseEvent('c')],
      );
    });

    test('an error of the byte stream is passed on', () async {
      final controller = StreamController<List<int>>();
      final events = <SseEvent>[];
      Object? error;
      final done = Completer<void>();
      controller.stream
          .transform(const SseParser())
          .listen(
            events.add,
            onError: (Object e) => error = e,
            onDone: done.complete,
          );

      controller
        ..add(utf8.encode('data: before\n\n'))
        ..addError(const FormatException('cut'));
      await controller.close();
      await done.future;

      expect(events, [const SseEvent('before')]);
      expect(error, isA<FormatException>());
    });

    test('cancelling stops reading the bytes', () async {
      var cancelled = false;
      final controller = StreamController<List<int>>(
        onCancel: () => cancelled = true,
      );
      final first = Completer<SseEvent>();
      final subscription = controller.stream
          .transform(const SseParser())
          .listen(first.complete);
      controller.add(utf8.encode('data: one\n\n'));
      expect(await first.future, const SseEvent('one'));

      await subscription.cancel();

      expect(cancelled, isTrue);
    });
  });
}
