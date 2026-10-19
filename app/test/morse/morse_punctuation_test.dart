import 'package:feel_you/morse/morse.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('questionMarkPattern', () {
    test('is Morse ? (dot dot dash dash dot dot)', () {
      expect(questionMarkPattern, const [
        MorseSignal.dot,
        MorseSignal.dot,
        MorseSignal.dash,
        MorseSignal.dash,
        MorseSignal.dot,
        MorseSignal.dot,
      ]);
    });

    test('is longer than every digit and letter of every language', () {
      expect(questionMarkPattern, hasLength(6));
      for (final language in MorseLanguage.values) {
        final characterLevels = morseRegistry
            .levelsForLanguage(language)
            .where((level) => level.kind == LevelKind.characters);
        expect(characterLevels, hasLength(2), reason: '$language');
        for (final level in characterLevels) {
          for (final MapEntry(key: item, value: pattern)
              in level.patterns.entries) {
            expect(
              pattern.length,
              lessThanOrEqualTo(5),
              reason: '$item in ${level.name}',
            );
          }
        }
      }
    });
  });
}
