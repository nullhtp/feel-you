import 'dart:async';

import 'package:feel_you/gestures/gesture_providers.dart';
import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/session/session_providers.dart';
import 'package:feel_you/settings/language_preference.dart';
import 'package:feel_you/settings/reading_speed_preference.dart';
import 'package:feel_you/tactile/tactile.dart';
import 'package:feel_you/teaching/teaching_providers.dart';
import 'package:feel_you/teaching/teaching_timing_config.dart';
import 'package:feel_you/vibration/vibration.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_doubles/fake_shake_detector.dart';
import '../test_doubles/mock_vibration_service.dart';

const _key = SharedPreferencesReadingSpeedStore.storageKey;

/// Loads a fresh store, as a new app launch would.
///
/// Drops the cached [SharedPreferences] instance first, so values are read
/// back from the (mock) platform storage rather than from memory.
Future<ReadingSpeedStore> _launch() async {
  SharedPreferences.resetStatic();
  final store = await loadReadingSpeedStore();
  expect(store, isA<SharedPreferencesReadingSpeedStore>());
  return store;
}

/// The sample word of each language, written out from the spec.
const _sampleWords = {
  MorseLanguage.english: 'GOOD',
  MorseLanguage.arabic: 'سعيد',
  MorseLanguage.russian: 'ВОДА',
  MorseLanguage.spanish: 'BIEN',
  MorseLanguage.french: 'BIEN',
  MorseLanguage.german: 'WARM',
};

/// A [MockVibrationService] that holds every playback with a character gap
/// (a word) open until [release], as a long sample plays on a device.
class _HeldWordService extends MockVibrationService {
  final _held = <Completer<void>>[];

  /// Lets every held playback complete.
  void release() {
    for (final held in _held) {
      if (!held.isCompleted) held.complete();
    }
  }

  @override
  Future<void> playMorseTokenPattern(List<MorseToken> tokens) async {
    await super.playMorseTokenPattern(tokens);
    final held = Completer<void>();
    _held.add(held);
    await held.future;
  }
}

/// A container whose reading services are [services], one per speed, with
/// [store] as the saved speed and [language] as the launch language.
ProviderContainer _container({
  required Map<ReadingSpeed, VibrationService> services,
  ReadingSpeedStore? store,
  MorseLanguage language = MorseLanguage.english,
}) {
  final container = ProviderContainer(
    overrides: [
      readingSpeedStoreProvider.overrideWithValue(
        store ?? InMemoryReadingSpeedStore(),
      ),
      languagePreferenceStoreProvider.overrideWithValue(
        InMemoryLanguagePreferenceStore(language),
      ),
      readingVibrationServiceProvider.overrideWith(
        (ref, speed) => services[speed]!,
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

/// One recording service per speed.
Map<ReadingSpeed, MockVibrationService> _recorders() => {
  for (final speed in ReadingSpeed.values) speed: MockVibrationService(),
};

/// The Morse tokens of [word] in [language], as the recording service
/// records a word.
List<MorseToken> _morseOf(String word, MorseLanguage language) {
  final level = morseRegistry
      .levelsForLanguage(language)
      .firstWhere((level) => level.kind == LevelKind.words);
  return level.wordPatterns![word]!;
}

/// The types of the calls [service] recorded, in order.
List<VibrationCallType> _types(VibrationService service) => [
  for (final call in (service as MockVibrationService).calls) call.type,
];

/// Mocks the `vibration` plugin channel and returns the arguments of every
/// `vibrate` call, in order.
List<Map<Object?, Object?>> _mockVibrationChannel(WidgetTester tester) {
  const channel = MethodChannel('vibration');
  final calls = <Map<Object?, Object?>>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
    call,
  ) async {
    if (call.method == 'vibrate') {
      calls.add(call.arguments as Map<Object?, Object?>);
    }
    return null;
  });
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      null,
    ),
  );
  return calls;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SharedPreferencesReadingSpeedStore', () {
    test('reads 12 wpm when nothing is saved', () async {
      SharedPreferences.setMockInitialValues({});

      expect((await _launch()).read(), ReadingSpeed.wpm12);
    });

    test('a saved speed survives a restart', () async {
      SharedPreferences.setMockInitialValues({});

      for (final speed in ReadingSpeed.values) {
        await (await _launch()).write(speed);
        expect((await _launch()).read(), speed, reason: '$speed');
      }
    });

    test('stores the words per minute as an integer', () async {
      SharedPreferences.setMockInitialValues({});

      await (await _launch()).write(ReadingSpeed.wpm8);

      final preferences = await SharedPreferences.getInstance();
      expect(preferences.get(_key), 8);
      expect(_key, 'reading_speed_wpm');
    });

    test('reads a speed saved by an earlier run', () async {
      SharedPreferences.setMockInitialValues({_key: 5});

      expect((await _launch()).read(), ReadingSpeed.wpm5);
    });

    test('an unknown or corrupt value reads as 12 wpm', () async {
      for (final stored in <Object>[7, 0, -1, 13, 120, '12', 12.5, true]) {
        SharedPreferences.setMockInitialValues({_key: stored});
        expect(
          (await _launch()).read(),
          ReadingSpeed.wpm12,
          reason: '$stored (${stored.runtimeType})',
        );
      }
    });

    test('a list value reads as 12 wpm', () async {
      SharedPreferences.setMockInitialValues({
        _key: <String>['6'],
      });

      expect((await _launch()).read(), ReadingSpeed.wpm12);
    });

    test('a write replaces a corrupt value', () async {
      SharedPreferences.setMockInitialValues({_key: 'fast'});

      await (await _launch()).write(ReadingSpeed.wpm6);

      expect((await _launch()).read(), ReadingSpeed.wpm6);
    });

    test('sits next to the language without touching it', () async {
      SharedPreferences.setMockInitialValues({'selected_language': 'arabic'});

      await (await _launch()).write(ReadingSpeed.wpm10);

      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getString('selected_language'), 'arabic');
      expect(preferences.getKeys(), {'selected_language', _key});
    });
  });

  group('InMemoryReadingSpeedStore', () {
    test('starts at 12 wpm, or at the given speed', () {
      expect(InMemoryReadingSpeedStore().read(), ReadingSpeed.wpm12);
      expect(
        InMemoryReadingSpeedStore(ReadingSpeed.wpm6).read(),
        ReadingSpeed.wpm6,
      );
    });

    test('keeps what is written', () async {
      final store = InMemoryReadingSpeedStore();
      await store.write(ReadingSpeed.wpm5);
      expect(store.read(), ReadingSpeed.wpm5);
    });

    test('is the default store', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(readingSpeedStoreProvider),
        isA<InMemoryReadingSpeedStore>(),
      );
      expect(container.read(readingSpeedProvider), ReadingSpeed.wpm12);
    });
  });

  group('readingSpeedSampleWord', () {
    test('is the spec word of every language', () {
      for (final language in MorseLanguage.values) {
        expect(
          readingSpeedSampleWord(language),
          _sampleWords[language],
          reason: language.name,
        );
      }
    });

    test('is a four-letter item of the language words level', () {
      for (final language in MorseLanguage.values) {
        final word = readingSpeedSampleWord(language);
        final words = morseRegistry
            .levelsForLanguage(language)
            .firstWhere((level) => level.kind == LevelKind.words);
        expect(words.characters, contains(word), reason: language.name);
        expect(word.runes, hasLength(4), reason: language.name);
        // Three character gaps to feel the speed by.
        final codec = MorseCodec(language);
        expect(
          codec.encode(word).where((t) => t == TactileToken.characterGap),
          hasLength(3),
          reason: language.name,
        );
      }
    });
  });

  group('readingSpeedProvider', () {
    test('starts at the saved speed', () {
      final container = _container(
        services: _recorders(),
        store: InMemoryReadingSpeedStore(ReadingSpeed.wpm8),
      );

      expect(container.read(readingSpeedProvider), ReadingSpeed.wpm8);
    });

    test('change publishes and saves the speed', () async {
      final store = InMemoryReadingSpeedStore();
      final container = _container(services: _recorders(), store: store);

      await container
          .read(readingSpeedProvider.notifier)
          .change(ReadingSpeed.wpm6);

      expect(container.read(readingSpeedProvider), ReadingSpeed.wpm6);
      expect(store.read(), ReadingSpeed.wpm6);
    });

    test('change plays the sample word on the new speed service', () async {
      final services = _recorders();
      final container = _container(services: services);

      await container
          .read(readingSpeedProvider.notifier)
          .change(ReadingSpeed.wpm10);

      expect(services[ReadingSpeed.wpm10]!.calls, hasLength(1));
      final call = services[ReadingSpeed.wpm10]!.calls.single;
      expect(call.type, VibrationCallType.playMorseTokenPattern);
      expect(call.tokens, _morseOf('GOOD', MorseLanguage.english));
      for (final MapEntry(key: speed, value: service) in services.entries) {
        if (speed != ReadingSpeed.wpm10) {
          expect(service.calls, isEmpty, reason: '$speed');
        }
      }
    });

    test('the sample is the session language word, at every speed', () async {
      for (final language in MorseLanguage.values) {
        final services = _recorders();
        final container = _container(services: services, language: language);
        final notifier = container.read(readingSpeedProvider.notifier);

        for (final speed in ReadingSpeed.values) {
          await notifier.change(speed);
          expect(
            services[speed]!.calls.single.tokens,
            _morseOf(_sampleWords[language]!, language),
            reason: '${language.name} at $speed',
          );
        }
      }
    });

    test('follows a language chosen during the run', () async {
      final services = _recorders();
      final container = _container(services: services);
      container
          .read(sessionNotifierProvider.notifier)
          .selectLanguage(MorseLanguage.german);

      await container
          .read(readingSpeedProvider.notifier)
          .change(ReadingSpeed.wpm5);

      expect(
        services[ReadingSpeed.wpm5]!.calls.single.tokens,
        _morseOf('WARM', MorseLanguage.german),
      );
    });

    test('setting the current speed again replays the sample', () async {
      final store = InMemoryReadingSpeedStore();
      final services = _recorders();
      final container = _container(services: services, store: store);
      final notifier = container.read(readingSpeedProvider.notifier);

      await notifier.change(ReadingSpeed.wpm12);
      await notifier.change(ReadingSpeed.wpm12);

      expect(services[ReadingSpeed.wpm12]!.calls, hasLength(2));
      expect(store.read(), ReadingSpeed.wpm12);
    });

    test('a change during a sample cancels it before the next one', () async {
      final slow = _HeldWordService();
      final services = <ReadingSpeed, VibrationService>{
        ..._recorders(),
        ReadingSpeed.wpm5: slow,
      };
      final container = _container(services: services);
      final notifier = container.read(readingSpeedProvider.notifier);

      final first = notifier.change(ReadingSpeed.wpm5);
      await pumpEventQueue();
      expect(_types(slow), [VibrationCallType.playMorseTokenPattern]);

      await notifier.change(ReadingSpeed.wpm8);

      // The slow sample was cancelled before the new one was played.
      expect(_types(slow), [
        VibrationCallType.playMorseTokenPattern,
        VibrationCallType.cancel,
      ]);
      expect(_types(services[ReadingSpeed.wpm8]!), [
        VibrationCallType.playMorseTokenPattern,
      ]);
      expect(container.read(readingSpeedProvider), ReadingSpeed.wpm8);

      slow.release();
      await first;
    });

    test(
      'a sample that finished is not cancelled by the next change',
      () async {
        final services = _recorders();
        final container = _container(services: services);
        final notifier = container.read(readingSpeedProvider.notifier);

        await notifier.change(ReadingSpeed.wpm5);
        await notifier.change(ReadingSpeed.wpm6);

        expect(_types(services[ReadingSpeed.wpm5]!), [
          VibrationCallType.playMorseTokenPattern,
        ]);
      },
    );

    testWidgets('sends the sample at 5 wpm with its exact milliseconds', (
      tester,
    ) async {
      final calls = _mockVibrationChannel(tester);
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final done = container
          .read(readingSpeedProvider.notifier)
          .change(ReadingSpeed.wpm5);
      await tester.pump(const Duration(milliseconds: 8015));
      await done;

      // GOOD: −−·, −−−, −−−, −·· with 1405 ms between the letters.
      expect(calls, hasLength(1));
      expect(calls.single['pattern'], [
        0, 300, 100, 300, 100, 100, //
        1405, 300, 100, 300, 100, 300, //
        1405, 300, 100, 300, 100, 300, //
        1405, 300, 100, 100, 100, 100,
      ]);
      expect(calls.single['intensities'], [
        for (var i = 0; i < 24; i++)
          if (i.isOdd) 255 else 0,
      ]);
    });
  });

  group('prosigns at a reading speed', () {
    test('last the same at every speed: they have no gap to stretch', () {
      const lesson = MorseTimingConfig();
      for (final language in MorseLanguage.values) {
        final codec = MorseCodec(language);
        for (final prosign in Prosign.values) {
          final tokens = codec.encodeProsign(prosign);
          expect(tokens, isNot(contains(TactileToken.characterGap)));
          expect(tokens, isNot(contains(TactileToken.wordGap)));
          for (final speed in ReadingSpeed.values) {
            expect(
              buildVibrationPattern(tokens, speed.timing(lesson)),
              buildVibrationPattern(tokens, lesson),
              reason: '$prosign in ${language.name} at $speed',
            );
          }
        }
      }
      // SOS: nine pulses 100 ms apart, 2300 ms at 5 wpm too.
      final sos = buildVibrationPattern(
        MorseCodec(MorseLanguage.english).encodeProsign(Prosign.sos),
        ReadingSpeed.wpm5.timing(lesson),
      );
      expect(sos.fold<int>(0, (sum, ms) => sum + ms), 2300);
    });
  });

  group('the lessons keep their own timing', () {
    /// A container with [speed] saved, as a launch would find it.
    ProviderContainer lessons(ReadingSpeed speed) {
      final container = ProviderContainer(
        overrides: [
          readingSpeedStoreProvider.overrideWithValue(
            InMemoryReadingSpeedStore(speed),
          ),
          screenWidthProvider.overrideWithValue(800),
          shakeDetectorProvider.overrideWithValue(FakeShakeDetector()),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    MorseTimingConfig lessonTiming(ProviderContainer container) =>
        (container.read(vibrationServiceProvider) as DeviceVibrationService)
            .config;

    test('the lesson service ignores a saved slow speed', () {
      final container = lessons(ReadingSpeed.wpm5);

      expect(container.read(readingSpeedProvider), ReadingSpeed.wpm5);
      expect(lessonTiming(container), const MorseTimingConfig());
      expect(lessonTiming(container).interCharGap, 300);
    });

    testWidgets('the teaching loop plays through the lesson service', (
      tester,
    ) async {
      // The orchestrator cancels the vibration when it is disposed.
      _mockVibrationChannel(tester);
      final container = lessons(ReadingSpeed.wpm5);

      expect(
        container.read(teachingOrchestratorProvider.notifier).vibrationService,
        same(container.read(vibrationServiceProvider)),
      );
      // Let the capability detection the service started settle.
      await tester.pump(const Duration(milliseconds: 100));
    });

    test('the lesson pauses stay at 3 s and 1 s', () {
      final container = lessons(ReadingSpeed.wpm5);

      final config = container.read(teachingTimingConfigProvider);
      expect(config.repeatPause, const Duration(seconds: 3));
      expect(config.spellingLetterGap, const Duration(seconds: 1));
      expect(config, isA<TeachingTimingConfig>());
    });

    testWidgets('a change during the run leaves the lesson service alone', (
      tester,
    ) async {
      _mockVibrationChannel(tester);
      final container = ProviderContainer(
        overrides: [
          readingVibrationServiceProvider.overrideWith(
            (ref, speed) => MockVibrationService(),
          ),
          screenWidthProvider.overrideWithValue(800),
          shakeDetectorProvider.overrideWithValue(FakeShakeDetector()),
        ],
      );
      addTearDown(container.dispose);
      final service = container.read(vibrationServiceProvider);
      final orchestrator = container.read(
        teachingOrchestratorProvider.notifier,
      );

      await container
          .read(readingSpeedProvider.notifier)
          .change(ReadingSpeed.wpm6);

      expect(container.read(vibrationServiceProvider), same(service));
      expect(
        container.read(teachingOrchestratorProvider.notifier),
        same(orchestrator),
      );
      expect(lessonTiming(container), const MorseTimingConfig());
      // Let the capability detection the service started settle.
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('a lesson word at 5 wpm keeps 300 ms between its letters', (
      tester,
    ) async {
      final calls = _mockVibrationChannel(tester);
      final container = lessons(ReadingSpeed.wpm5);
      final session = container.read(sessionNotifierProvider.notifier)
        ..nextLevel()
        ..nextLevel();
      expect(container.read(sessionNotifierProvider).currentCharacter, 'HI');
      final orchestrator = container.read(teachingOrchestratorProvider.notifier)
        ..start();

      // H (700 ms), 1 s, I (300 ms), 3 s, then the word (1300 ms).
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 1300));

      final patterns = [for (final call in calls) call['pattern']];
      expect(patterns, [
        [0, 100, 100, 100, 100, 100, 100, 100], // H, spelled
        [0, 100, 100, 100], // I, spelled
        [0, 100, 100, 100, 100, 100, 100, 100, 300, 100, 100, 100], // HI
      ]);
      expect(session.state.currentCharacter, 'HI');

      await orchestrator.stop();
      // Let the cancelled repeat pause's timer run out.
      await tester.pump(const Duration(seconds: 3));
    });
  });
}
