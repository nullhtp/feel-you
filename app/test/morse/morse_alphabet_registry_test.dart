import 'package:feel_you/morse/morse.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// A registry with a two-character universal level and an English level only.
MorseAlphabetRegistry _smallRegistry() => MorseAlphabetRegistry([
  MorseAlphabet(
    language: null,
    characters: digitAlphabet.characters,
    characterOrder: const ['0', '1'],
    levels: [
      Level(
        name: 'small-digits',
        characters: const ['0', '1'],
        patterns: digitAlphabet.characters,
      ),
    ],
  ),
  MorseAlphabet(
    language: MorseLanguage.english,
    characters: englishAlphabet.characters,
    characterOrder: const ['E', 'T'],
    levels: [
      Level(
        name: 'small-letters',
        characters: const ['E', 'T'],
        patterns: englishAlphabet.characters,
        language: MorseLanguage.english,
      ),
    ],
  ),
]);

void main() {
  group('MorseAlphabetRegistry.levelsForLanguage caching', () {
    for (final language in MorseLanguage.values) {
      test('returns the identical list on repeated calls for $language', () {
        final first = morseRegistry.levelsForLanguage(language);
        final second = morseRegistry.levelsForLanguage(language);
        expect(second, same(first));
      });

      test('returns an unmodifiable list for $language', () {
        final levels = morseRegistry.levelsForLanguage(language);
        final level = levels.first;
        expect(() => levels.add(level), throwsUnsupportedError);
        expect(() => levels[0] = level, throwsUnsupportedError);
        expect(levels.removeLast, throwsUnsupportedError);
        expect(levels.clear, throwsUnsupportedError);
      });
    }

    test('caches each language separately', () {
      final english = morseRegistry.levelsForLanguage(MorseLanguage.english);
      final arabic = morseRegistry.levelsForLanguage(MorseLanguage.arabic);
      expect(arabic, isNot(same(english)));
      expect(
        morseRegistry.levelsForLanguage(MorseLanguage.english),
        same(english),
      );
    });

    test('a custom registry caches its own lists', () {
      final registry = _smallRegistry();
      final levels = registry.levelsForLanguage(MorseLanguage.english);
      expect(levels.map((l) => l.name), ['small-digits', 'small-letters']);
      expect(registry.levelsForLanguage(MorseLanguage.english), same(levels));
      expect(
        levels,
        isNot(same(morseRegistry.levelsForLanguage(MorseLanguage.english))),
      );
    });

    test('an unregistered language resolves to the universal levels only', () {
      final registry = _smallRegistry();
      final arabic = registry.levelsForLanguage(MorseLanguage.arabic);
      expect(arabic.map((l) => l.name), ['small-digits']);
      expect(registry.levelsForLanguage(MorseLanguage.arabic), same(arabic));
    });

    test('keeps registration order', () {
      final registry = MorseAlphabetRegistry([englishAlphabet, digitAlphabet]);
      expect(
        registry.levelsForLanguage(MorseLanguage.english).map((l) => l.name),
        ['letters', 'words', 'digits'],
      );
    });
  });

  group('MorseAlphabetRegistry.forLanguage', () {
    test('returns the registered alphabet for each language', () {
      expect(
        morseRegistry.forLanguage(MorseLanguage.english),
        same(englishAlphabet),
      );
      expect(
        morseRegistry.forLanguage(MorseLanguage.arabic),
        same(arabicAlphabet),
      );
      expect(
        morseRegistry.forLanguage(MorseLanguage.russian),
        same(russianAlphabet),
      );
    });

    test('returns null for an unregistered language', () {
      expect(_smallRegistry().forLanguage(MorseLanguage.arabic), isNull);
    });

    test('returns the first alphabet registered for a language', () {
      final duplicate = MorseAlphabet(
        language: MorseLanguage.english,
        characters: const {},
        characterOrder: const [],
        levels: const [],
      );
      final registry = MorseAlphabetRegistry([englishAlphabet, duplicate]);
      expect(
        registry.forLanguage(MorseLanguage.english),
        same(englishAlphabet),
      );
    });
  });

  group('morseRegistryProvider', () {
    test('defaults to the global morseRegistry', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(morseRegistryProvider), same(morseRegistry));
    });

    test('can be overridden', () {
      final registry = _smallRegistry();
      final container = ProviderContainer(
        overrides: [morseRegistryProvider.overrideWithValue(registry)],
      );
      addTearDown(container.dispose);

      expect(container.read(morseRegistryProvider), same(registry));
    });
  });
}
