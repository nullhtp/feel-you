import 'dart:async';

import 'package:feel_you/morse/morse_language.dart';
import 'package:feel_you/morse/morse_providers.dart';
import 'package:feel_you/session/session_providers.dart';
import 'package:feel_you/vibration/reading_speed.dart';
import 'package:feel_you/vibration/vibration_providers.dart';
import 'package:feel_you/vibration/vibration_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Remembers the reading speed, so reading modes play at it on every
/// launch.
abstract interface class ReadingSpeedStore {
  /// The saved speed, or [ReadingSpeed.standard] when none is saved or the
  /// stored value is not one of the speeds (e.g. corrupt, or written by
  /// another version).
  ReadingSpeed read();

  /// Saves [speed] as the user's choice.
  ///
  /// Best effort: a failed write is logged, never thrown, so it can't keep
  /// the confirmation from playing.
  Future<void> write(ReadingSpeed speed);
}

/// A [ReadingSpeedStore] backed by [SharedPreferences], so the speed
/// survives app restarts. It sits next to the language, and is backed up
/// like it.
class SharedPreferencesReadingSpeedStore implements ReadingSpeedStore {
  /// Creates a store that keeps the speed in the given preferences.
  SharedPreferencesReadingSpeedStore(this._preferences);

  /// The [SharedPreferences] key holding the speed's
  /// [ReadingSpeed.wordsPerMinute], as an integer.
  ///
  /// The number rather than the enum's name, so the stored value says what
  /// it means and a renamed value still reads back.
  static const storageKey = 'reading_speed_wpm';

  final SharedPreferences _preferences;

  @override
  ReadingSpeed read() {
    // `get` rather than `getInt`: a value of another type must not throw.
    final stored = _preferences.get(storageKey);
    if (stored is! int) return ReadingSpeed.standard;
    return ReadingSpeed.fromWordsPerMinute(stored) ?? ReadingSpeed.standard;
  }

  @override
  Future<void> write(ReadingSpeed speed) async {
    try {
      final saved = await _preferences.setInt(storageKey, speed.wordsPerMinute);
      if (!saved) debugPrint('Could not save the reading speed.');
    } on Exception catch (error) {
      debugPrint('Could not save the reading speed: $error');
    }
  }
}

/// A [ReadingSpeedStore] that only lasts as long as the app runs.
///
/// Used when [SharedPreferences] can't be loaded, and by default when
/// [readingSpeedStoreProvider] is not overridden (e.g. in tests).
class InMemoryReadingSpeedStore implements ReadingSpeedStore {
  /// Creates a store that starts with the given speed saved
  /// ([ReadingSpeed.standard] by default).
  InMemoryReadingSpeedStore([this._speed = ReadingSpeed.standard]);

  ReadingSpeed _speed;

  @override
  ReadingSpeed read() => _speed;

  @override
  Future<void> write(ReadingSpeed speed) async => _speed = speed;
}

/// Loads the persistent [ReadingSpeedStore].
///
/// Call before `runApp` and override [readingSpeedStoreProvider] with the
/// result, so the saved speed is known before the first frame. Falls back to
/// an [InMemoryReadingSpeedStore] (the speed lasts for the current run only)
/// if the platform storage can't be loaded.
Future<ReadingSpeedStore> loadReadingSpeedStore() async {
  try {
    return SharedPreferencesReadingSpeedStore(
      await SharedPreferences.getInstance(),
    );
  } on Exception catch (error) {
    debugPrint(
      'Could not load preferences, reading speed will not be saved: $error',
    );
    return InMemoryReadingSpeedStore();
  }
}

/// Provides the [ReadingSpeedStore].
///
/// `main` overrides it with the store from [loadReadingSpeedStore]. The
/// default keeps the speed in memory only, at [ReadingSpeed.standard], so
/// widgets and tests work without any setup.
final readingSpeedStoreProvider = Provider<ReadingSpeedStore>(
  (ref) => InMemoryReadingSpeedStore(),
);

/// The word that confirms a new reading speed in [language]: the same word
/// at every speed, so only the gaps change from one sample to the next.
///
/// A four-letter word of the language's own words level, so the user has
/// learned it and feels three character gaps.
String readingSpeedSampleWord(MorseLanguage language) => switch (language) {
  MorseLanguage.english => 'GOOD',
  MorseLanguage.arabic => 'سعيد',
  MorseLanguage.russian => 'ВОДА',
  MorseLanguage.spanish => 'BIEN',
  MorseLanguage.french => 'BIEN',
  MorseLanguage.german => 'WARM',
};

/// Provides the [ReadingSpeedNotifier] and the speed reading modes play at.
///
/// Read from [readingSpeedStoreProvider] once, when first needed. Reading
/// modes play text through
/// `readingVibrationServiceProvider(ref.watch(readingSpeedProvider))`; the
/// lessons never read it.
final readingSpeedProvider =
    NotifierProvider<ReadingSpeedNotifier, ReadingSpeed>(
      ReadingSpeedNotifier.new,
    );

/// Holds the reading speed, saves each change and confirms it with a sample
/// word; see [readingSpeedProvider].
class ReadingSpeedNotifier extends Notifier<ReadingSpeed> {
  /// The sample playing right now, if any: the service it plays on and the
  /// number of the change that started it.
  ({VibrationService service, int change})? _sample;

  /// How many changes have started a sample.
  int _changes = 0;

  @override
  ReadingSpeed build() => ref.watch(readingSpeedStoreProvider).read();

  /// Sets the reading speed to [speed], saves it and plays the sample word
  /// at it as confirmation.
  ///
  /// The sample is [readingSpeedSampleWord] of the session's language,
  /// encoded with that language's codec and played through
  /// [readingVibrationServiceProvider] at [speed]. It plays even when
  /// [speed] is already set: the call confirms where the user is. A sample
  /// still playing from an earlier change is cancelled first, so two never
  /// overlap.
  ///
  /// Completes once the sample has played and the speed is saved.
  Future<void> change(ReadingSpeed speed) async {
    state = speed;
    final saved = ref.read(readingSpeedStoreProvider).write(speed);
    await _playSample(speed);
    await saved;
  }

  Future<void> _playSample(ReadingSpeed speed) async {
    final language = ref.read(sessionNotifierProvider).language;
    final tokens = ref
        .read(tactileCodecProvider(language))
        .encode(readingSpeedSampleWord(language));
    final service = ref.read(readingVibrationServiceProvider(speed));

    final change = ++_changes;
    final previous = _sample;
    _sample = (service: service, change: change);
    if (previous != null) {
      await previous.service.cancel();
      // A later change started while the motor stopped: it plays instead.
      if (_sample?.change != change) return;
    }
    try {
      await service.playTokens(tokens);
    } finally {
      if (_sample?.change == change) _sample = null;
    }
  }
}
