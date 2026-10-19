import 'dart:math';

import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/session/quiz_item_picker.dart';
import 'package:feel_you/session/session_providers.dart';
import 'package:feel_you/settings/learned_items.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _draws = 500;

void main() {
  final letters = morseRegistry.levelsForLanguage(MorseLanguage.english)[1];

  QuizItemPicker picker(Set<String> learned) => QuizItemPicker(
    learnedItemsOf: (language, level) =>
        language == MorseLanguage.english && level == letters
        ? learned
        : const {},
    random: Random(7),
  );

  Set<String> drawMany(QuizItemPicker picker) => {
    for (var i = 0; i < _draws; i++)
      picker.pick(MorseLanguage.english, letters),
  };

  group('QuizItemPicker', () {
    test('draws only learned items', () {
      expect(drawMany(picker({'A', 'B', 'C'})), {'A', 'B', 'C'});
    });

    test('draws from the whole level while fewer than two are learned', () {
      expect(drawMany(picker({'A'})), letters.characters.toSet());
      expect(drawMany(picker({})), letters.characters.toSet());
    });

    test('learned items of another language do not count', () {
      final russianPicker = QuizItemPicker(
        learnedItemsOf: (language, level) =>
            language == MorseLanguage.english ? {'A', 'B'} : const {},
        random: Random(7),
      );
      expect({
        for (var i = 0; i < _draws; i++)
          russianPicker.pick(MorseLanguage.russian, letters),
      }, letters.characters.toSet());
    });

    test('never draws the previous item', () {
      final quiz = picker({'A', 'B'});
      var item = quiz.pick(MorseLanguage.english, letters);
      for (var i = 0; i < _draws; i++) {
        final next = quiz.pick(MorseLanguage.english, letters, previous: item);
        expect(next, isNot(item));
        item = next;
      }
    });

    test('counts an item learned after earlier draws', () {
      final learned = {'A', 'B'};
      final quiz = picker(learned);
      expect(drawMany(quiz), {'A', 'B'});

      learned.add('C');

      expect(drawMany(quiz), {'A', 'B', 'C'});
    });

    test('ignores learned items that are not in the level', () {
      expect(drawMany(picker({'A', 'B', 'HELLO'})), {'A', 'B'});
    });
  });

  group('quizItemPickerProvider', () {
    test('draws from the learned items in learnedItemsProvider', () {
      final container = ProviderContainer(
        overrides: [quizRandomProvider.overrideWithValue(Random(7))],
      );
      addTearDown(container.dispose);
      container.read(learnedItemsProvider.notifier)
        ..add(MorseLanguage.english, letters, 'K')
        ..add(MorseLanguage.english, letters, 'M');
      final quiz = container.read(quizItemPickerProvider);

      expect(
        {
          for (var i = 0; i < _draws; i++)
            quiz.pick(MorseLanguage.english, letters),
        },
        {'K', 'M'},
      );
    });
  });
}
