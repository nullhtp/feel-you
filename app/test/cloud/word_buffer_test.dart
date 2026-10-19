import 'dart:async';

import 'package:feel_you/cloud/word_buffer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WordBuffer', () {
    test('releases a word as soon as whitespace ends it', () {
      final buffer = WordBuffer();

      expect(buffer.add('Hel'), isEmpty);
      expect(buffer.add('lo wor'), ['Hello']);
      expect(buffer.add('ld, how'), ['world,']);
      expect(buffer.add(' are you?'), ['how', 'are']);
      expect(buffer.flush(), 'you?');
      expect(buffer.flush(), isNull);
    });

    test('a piece ending in whitespace completes its last word', () {
      final buffer = WordBuffer();

      expect(buffer.add('one two '), ['one', 'two']);
      expect(buffer.flush(), isNull);
    });

    test('any whitespace separates words and none is part of one', () {
      final buffer = WordBuffer();

      expect(buffer.add('  a\tb\nc\r\nd\u00A0e\u3000f  '), [
        'a',
        'b',
        'c',
        'd',
        'e',
        'f',
      ]);
    });

    test('empty pieces and whitespace alone release nothing', () {
      final buffer = WordBuffer();

      expect(buffer.add(''), isEmpty);
      expect(buffer.add('   '), isEmpty);
      expect(buffer.add('\n'), isEmpty);
      expect(buffer.flush(), isNull);
    });

    test('a word split over many pieces stays whole', () {
      final buffer = WordBuffer();

      for (final piece in ['Ç', 'a', ' ', 'v', 'a', '.']) {
        buffer.add(piece);
      }
      expect(buffer.flush(), 'va.');
    });

    test('clear drops the unfinished word', () {
      final buffer = WordBuffer()
        ..add('Hello wor')
        ..clear();

      expect(buffer.flush(), isNull);
    });
  });

  group('WordSplitter', () {
    test('turns pieces into words, the last one at the end', () async {
      final words = await Stream.fromIterable([
        'Hel',
        'lo wor',
        'ld, how',
        ' are you?',
      ]).transform(const WordSplitter()).toList();

      expect(words, ['Hello', 'world,', 'how', 'are', 'you?']);
    });

    test('releases each word before the next piece arrives', () async {
      final pieces = StreamController<String>();
      final words = <String>[];
      pieces.stream.transform(const WordSplitter()).listen(words.add);

      pieces.add('Hello wor');
      await pumpEventQueue();
      expect(words, ['Hello']);

      pieces.add('ld ');
      await pumpEventQueue();
      expect(words, ['Hello', 'world']);
      await pieces.close();
    });

    test('an error drops the unfinished word', () async {
      final pieces = StreamController<String>();
      final words = <String>[];
      Object? error;
      final done = Completer<void>();
      pieces.stream
          .transform(const WordSplitter())
          .listen(
            words.add,
            onError: (Object e) => error = e,
            onDone: done.complete,
          );

      pieces
        ..add('Hello wor')
        ..addError(StateError('cut'));
      await pieces.close();
      await done.future;

      expect(words, ['Hello']);
      expect(error, isA<StateError>());
    });
  });
}
