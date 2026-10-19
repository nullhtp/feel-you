import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/settings/learned_items.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Loads a fresh store, as a new app launch would.
///
/// Drops the cached [SharedPreferences] instance first, so values are read
/// back from the (mock) platform storage rather than from memory.
Future<LearnedItemsStore> _launch() async {
  SharedPreferences.resetStatic();
  final store = await loadLearnedItemsStore();
  expect(store, isA<SharedPreferencesLearnedItemsStore>());
  return store;
}

Level _level(MorseLanguage language, int index) =>
    morseRegistry.levelsForLanguage(language)[index];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final englishDigits = _level(MorseLanguage.english, 0);
  final englishLetters = _level(MorseLanguage.english, 1);
  final russianDigits = _level(MorseLanguage.russian, 0);
  final russianLetters = _level(MorseLanguage.russian, 1);

  group('SharedPreferencesLearnedItemsStore', () {
    test('nothing is saved on the first launch', () async {
      SharedPreferences.setMockInitialValues({});

      final store = await _launch();

      for (final language in MorseLanguage.values) {
        for (final level in morseRegistry.levelsForLanguage(language)) {
          expect(store.read(language, level), isEmpty);
        }
      }
    });

    test('learned items survive a restart', () async {
      SharedPreferences.setMockInitialValues({});

      await (await _launch()).write(MorseLanguage.russian, russianLetters, [
        'А',
        'Б',
      ]);

      expect((await _launch()).read(MorseLanguage.russian, russianLetters), [
        'А',
        'Б',
      ]);
    });

    test('stores a string list per language and level', () async {
      SharedPreferences.setMockInitialValues({});

      await (await _launch()).write(MorseLanguage.russian, russianLetters, [
        'К',
      ]);

      final preferences = await SharedPreferences.getInstance();
      expect(
        SharedPreferencesLearnedItemsStore.storageKey(
          MorseLanguage.russian,
          russianLetters,
        ),
        'learned_items.russian.russian-letters',
      );
      expect(
        preferences.getStringList('learned_items.russian.russian-letters'),
        ['К'],
      );
    });

    test('saves Spanish letters under their own key', () async {
      SharedPreferences.setMockInitialValues({});
      final spanishLetters = _level(MorseLanguage.spanish, 1);

      await (await _launch()).write(MorseLanguage.spanish, spanishLetters, [
        'Ñ',
        'A',
      ]);

      final preferences = await SharedPreferences.getInstance();
      expect(
        preferences.getStringList('learned_items.spanish.spanish-letters'),
        ['Ñ', 'A'],
      );
      expect((await _launch()).read(MorseLanguage.spanish, spanishLetters), [
        'Ñ',
        'A',
      ]);
      // English letters A-Z share the patterns, not the learned items.
      expect(
        (await _launch()).read(MorseLanguage.english, englishLetters),
        isEmpty,
      );
    });

    test('keeps each language and level apart', () async {
      SharedPreferences.setMockInitialValues({});

      final store = await _launch();
      await store.write(MorseLanguage.english, englishDigits, ['5']);
      await store.write(MorseLanguage.english, englishLetters, ['A']);

      final relaunched = await _launch();
      expect(relaunched.read(MorseLanguage.english, englishDigits), ['5']);
      expect(relaunched.read(MorseLanguage.english, englishLetters), ['A']);
      // The digits level is shared by every language, but its learned items
      // are not.
      expect(relaunched.read(MorseLanguage.russian, russianDigits), isEmpty);
    });

    test('a write replaces the saved items', () async {
      SharedPreferences.setMockInitialValues({});

      final store = await _launch();
      await store.write(MorseLanguage.english, englishLetters, ['A']);
      await store.write(MorseLanguage.english, englishLetters, ['A', 'B']);

      expect((await _launch()).read(MorseLanguage.english, englishLetters), [
        'A',
        'B',
      ]);
    });

    test('a value of another type reads as nothing saved', () async {
      SharedPreferences.setMockInitialValues({
        'learned_items.english.letters': 'A',
      });

      expect(
        (await _launch()).read(MorseLanguage.english, englishLetters),
        isEmpty,
      );
    });

    test('a write replaces a corrupt value', () async {
      SharedPreferences.setMockInitialValues({
        'learned_items.english.letters': 2,
      });

      await (await _launch()).write(MorseLanguage.english, englishLetters, [
        'Z',
      ]);

      expect((await _launch()).read(MorseLanguage.english, englishLetters), [
        'Z',
      ]);
    });
  });

  group('InMemoryLearnedItemsStore', () {
    test('starts empty and keeps what is written', () async {
      final store = InMemoryLearnedItemsStore();
      expect(store.read(MorseLanguage.english, englishLetters), isEmpty);

      await store.write(MorseLanguage.english, englishLetters, ['A']);

      expect(store.read(MorseLanguage.english, englishLetters), ['A']);
      expect(store.read(MorseLanguage.russian, russianLetters), isEmpty);
    });
  });
}
