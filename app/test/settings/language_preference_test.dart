import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/session/session_providers.dart';
import 'package:feel_you/settings/language_preference.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _key = SharedPreferencesLanguagePreferenceStore.storageKey;

/// Loads a fresh store, as a new app launch would.
///
/// Drops the cached [SharedPreferences] instance first, so values are read
/// back from the (mock) platform storage rather than from memory.
Future<LanguagePreferenceStore> _launch() async {
  SharedPreferences.resetStatic();
  final store = await loadLanguagePreferenceStore();
  expect(store, isA<SharedPreferencesLanguagePreferenceStore>());
  return store;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SharedPreferencesLanguagePreferenceStore', () {
    test('nothing is saved on the first launch', () async {
      SharedPreferences.setMockInitialValues({});

      expect((await _launch()).read(), isNull);
    });

    test('a saved language survives a restart', () async {
      SharedPreferences.setMockInitialValues({});

      for (final language in MorseLanguage.values) {
        await (await _launch()).write(language);
        expect((await _launch()).read(), language, reason: language.name);
      }
    });

    test('stores the language name', () async {
      SharedPreferences.setMockInitialValues({});

      await (await _launch()).write(MorseLanguage.arabic);

      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getString(_key), 'arabic');
    });

    test('reads a language saved by an earlier run', () async {
      SharedPreferences.setMockInitialValues({_key: 'russian'});

      expect((await _launch()).read(), MorseLanguage.russian);
    });

    test('stores and reads Spanish under its name', () async {
      SharedPreferences.setMockInitialValues({});

      await (await _launch()).write(MorseLanguage.spanish);

      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getString(_key), 'spanish');
      expect((await _launch()).read(), MorseLanguage.spanish);
    });

    test('stores and reads French under its name', () async {
      SharedPreferences.setMockInitialValues({});

      await (await _launch()).write(MorseLanguage.french);

      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getString(_key), 'french');
      expect((await _launch()).read(), MorseLanguage.french);
    });

    test('stores and reads German under its name', () async {
      SharedPreferences.setMockInitialValues({});

      await (await _launch()).write(MorseLanguage.german);

      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getString(_key), 'german');
      expect((await _launch()).read(), MorseLanguage.german);
    });

    test('every saved language keeps reading back as itself', () async {
      // Values are only ever appended to MorseLanguage, so a name saved by
      // an older version still means the same language.
      for (final language in MorseLanguage.values) {
        SharedPreferences.setMockInitialValues({_key: language.name});
        expect((await _launch()).read(), language, reason: language.name);
      }
    });

    test('an unknown language name reads as nothing saved', () async {
      SharedPreferences.setMockInitialValues({_key: 'klingon'});

      expect((await _launch()).read(), isNull);
    });

    test('an empty value reads as nothing saved', () async {
      SharedPreferences.setMockInitialValues({_key: ''});

      expect((await _launch()).read(), isNull);
    });

    test('a value of another type reads as nothing saved', () async {
      SharedPreferences.setMockInitialValues({_key: 2});

      expect((await _launch()).read(), isNull);
    });

    test('a write replaces a corrupt value', () async {
      SharedPreferences.setMockInitialValues({_key: 2});

      await (await _launch()).write(MorseLanguage.english);

      expect((await _launch()).read(), MorseLanguage.english);
    });
  });

  group('InMemoryLanguagePreferenceStore', () {
    test('starts empty and keeps what is written', () async {
      final store = InMemoryLanguagePreferenceStore();
      expect(store.read(), isNull);

      await store.write(MorseLanguage.russian);
      expect(store.read(), MorseLanguage.russian);
    });

    test('can start with a saved language', () {
      expect(
        InMemoryLanguagePreferenceStore(MorseLanguage.arabic).read(),
        MorseLanguage.arabic,
      );
    });
  });

  group('providers', () {
    test('the default store keeps nothing from an earlier run', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(languagePreferenceStoreProvider),
        isA<InMemoryLanguagePreferenceStore>(),
      );
      expect(container.read(launchLanguageProvider), isNull);
    });

    test('the launch language is read once and kept for the run', () async {
      final store = InMemoryLanguagePreferenceStore(MorseLanguage.arabic);
      final container = ProviderContainer(
        overrides: [languagePreferenceStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);

      expect(container.read(launchLanguageProvider), MorseLanguage.arabic);

      // A new choice is saved for the next launch only.
      await store.write(MorseLanguage.russian);
      expect(container.read(launchLanguageProvider), MorseLanguage.arabic);
      expect(store.read(), MorseLanguage.russian);
    });

    test('the session starts in the saved language', () {
      final container = ProviderContainer(
        overrides: [
          languagePreferenceStoreProvider.overrideWithValue(
            InMemoryLanguagePreferenceStore(MorseLanguage.russian),
          ),
        ],
      );
      addTearDown(container.dispose);

      final session = container.read(sessionNotifierProvider);
      expect(session.language, MorseLanguage.russian);
      expect(session.levelIndex, 0);
      expect(session.positionIndex, 0);
    });

    test('the session starts in English when nothing is saved', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(sessionNotifierProvider).language,
        MorseLanguage.english,
      );
    });
  });
}
