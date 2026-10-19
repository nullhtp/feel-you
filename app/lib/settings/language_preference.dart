import 'package:feel_you/morse/morse_language.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Remembers the language the user last chose in the language picker, so
/// later launches can skip the picker and open the home menu.
abstract interface class LanguagePreferenceStore {
  /// The saved language, or `null` when none is saved or the stored value
  /// is not a known language (e.g. corrupt, or written by another version).
  MorseLanguage? read();

  /// Saves [language] as the user's choice.
  ///
  /// Best effort: a failed write is logged, never thrown, so it can't keep
  /// a session from starting.
  Future<void> write(MorseLanguage language);
}

/// A [LanguagePreferenceStore] backed by [SharedPreferences], so the choice
/// survives app restarts.
class SharedPreferencesLanguagePreferenceStore
    implements LanguagePreferenceStore {
  /// Creates a store that keeps the language in the given preferences.
  SharedPreferencesLanguagePreferenceStore(this._preferences);

  /// The [SharedPreferences] key holding the name of the [MorseLanguage].
  static const storageKey = 'selected_language';

  final SharedPreferences _preferences;

  @override
  MorseLanguage? read() {
    // `get` rather than `getString`: a value of another type must not throw.
    final stored = _preferences.get(storageKey);
    if (stored is! String) return null;
    return MorseLanguage.values.asNameMap()[stored];
  }

  @override
  Future<void> write(MorseLanguage language) async {
    try {
      final saved = await _preferences.setString(storageKey, language.name);
      if (!saved) debugPrint('Could not save the selected language.');
    } on Exception catch (error) {
      debugPrint('Could not save the selected language: $error');
    }
  }
}

/// A [LanguagePreferenceStore] that only lasts as long as the app runs.
///
/// Used when [SharedPreferences] can't be loaded, and by default when
/// [languagePreferenceStoreProvider] is not overridden (e.g. in tests).
class InMemoryLanguagePreferenceStore implements LanguagePreferenceStore {
  /// Creates a store that starts with the given language saved (none by
  /// default).
  InMemoryLanguagePreferenceStore([this._language]);

  MorseLanguage? _language;

  @override
  MorseLanguage? read() => _language;

  @override
  Future<void> write(MorseLanguage language) async => _language = language;
}

/// Loads the persistent [LanguagePreferenceStore].
///
/// Call before `runApp` and override [languagePreferenceStoreProvider] with
/// the result, so the saved language is known before the first frame. Falls
/// back to an [InMemoryLanguagePreferenceStore] (the picker is shown on
/// every launch) if the platform storage can't be loaded.
Future<LanguagePreferenceStore> loadLanguagePreferenceStore() async {
  try {
    return SharedPreferencesLanguagePreferenceStore(
      await SharedPreferences.getInstance(),
    );
  } on Exception catch (error) {
    debugPrint(
      'Could not load preferences, language will not be saved: $error',
    );
    return InMemoryLanguagePreferenceStore();
  }
}

/// Provides the [LanguagePreferenceStore].
///
/// `main` overrides it with the store from [loadLanguagePreferenceStore].
/// The default keeps the choice in memory only, so widgets and tests work
/// without any setup.
final languagePreferenceStoreProvider = Provider<LanguagePreferenceStore>(
  (ref) => InMemoryLanguagePreferenceStore(),
);

/// The language saved on an earlier run, or `null` if there is none.
///
/// Read from the store once, when first needed (at launch), and kept for the
/// rest of the run: choosing a language later saves it for the next launch
/// but does not change this value. Decides whether the app opens on the
/// language picker or on the home menu, and is the language the session
/// starts in.
final launchLanguageProvider = Provider<MorseLanguage?>(
  (ref) => ref.watch(languagePreferenceStoreProvider).read(),
);
