import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/settings/reading_speed_preference.dart';
import 'package:feel_you/ui/home_menu_surface.dart';
import 'package:feel_you/vibration/vibration.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'e2e_helpers.dart';

// The reading speed end to end (`reading-speed`): the whole app with its own
// DeviceVibrationService and the default Morse timing, so what reaches the
// `vibration` plugin's channel is what a phone would feel. The speed is
// changed through the API the settings list (#45) will call; no screen
// changes it yet.

/// The preference key, written out to pin the spec.
const _key = 'reading_speed_wpm';

/// Each speed with the character gap of the spec's table, in the order the
/// test sets them: every slower speed, then back to the default.
const _speeds = [
  (speed: ReadingSpeed.wpm10, characterGap: 458),
  (speed: ReadingSpeed.wpm8, characterGap: 695),
  (speed: ReadingSpeed.wpm6, characterGap: 1089),
  (speed: ReadingSpeed.wpm5, characterGap: 1405),
  (speed: ReadingSpeed.wpm12, characterGap: 300),
];

/// One language's flow.
typedef _Flow = ({
  MorseLanguage language,

  /// The sample word's letters in Morse, `.` a dot and `-` a dash.
  List<String> sample,

  /// The first word of the words level, in Morse.
  List<String> firstWord,
});

const _flows = <_Flow>[
  (
    language: MorseLanguage.english,
    sample: ['--.', '---', '---', '-..'], // GOOD
    firstWord: ['....', '..'], // HI
  ),
  (
    language: MorseLanguage.russian,
    sample: ['.--', '---', '-..', '.-'], // ВОДА
    firstWord: ['-..', '.-'], // ДА
  ),
];

/// The milliseconds the plugin is sent for [letters] with the default
/// pulses (a 100 ms dot, a 300 ms dash, 100 ms between them) and
/// [characterGap] between the letters, written out rather than taken from
/// the app so the test pins the spec.
List<int> _pattern(List<String> letters, int characterGap) {
  final pattern = <int>[0];
  for (final (i, letter) in letters.indexed) {
    if (i > 0) pattern.add(characterGap);
    for (final (j, symbol) in letter.split('').indexed) {
      if (j > 0) pattern.add(100);
      pattern.add(symbol == '.' ? 100 : 300);
    }
  }
  return pattern;
}

/// 0 for every silence and 255 for every vibration of a [pattern].
List<int> _intensities(List<int> pattern) => [
  for (var i = 0; i < pattern.length; i++)
    if (i.isOdd) 255 else 0,
];

/// The app with the default Morse timing (the harness's is shortened) and
/// [store] holding the reading speed.
E2EApp _app(MorseLanguage language, ReadingSpeedStore store) => E2EApp(
  savedLanguage: language,
  overrides: [
    morseTimingConfigProvider.overrideWithValue(const MorseTimingConfig()),
    readingSpeedStoreProvider.overrideWithValue(store),
  ],
);

/// Launches [app] and waits until the home menu has played its letter, so
/// what follows is recorded on its own.
Future<void> _launchToMenu(
  WidgetTester tester,
  E2EApp app,
  FakeVibrationPlatform platform,
) async {
  await app.launch(tester);
  await waitUntil(
    tester,
    () =>
        find.byType(HomeMenuSurface).evaluate().isNotEmpty &&
        platform.vibrateCalls.isNotEmpty,
    reason: 'the home menu announces Learn',
  );
  // Morse L lasts 900 ms: let it end before the sample.
  await waitFor(tester, const Duration(seconds: 1));
}

/// A swipe up across the middle of the lesson surface.
Future<void> _swipeUp(WidgetTester tester) async {
  await tester.dragFrom(surfacePoint(tester, 0.5, 0.7), const Offset(0, -150));
  await tester.pump();
}

/// The speed reading modes play at in [app].
ReadingSpeed _speed(WidgetTester tester, E2EApp app) =>
    app.container(tester).read(readingSpeedProvider);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Start and end without a saved speed, whatever an earlier, interrupted
  // run left behind.
  Future<void> removeSavedSpeed() async =>
      (await SharedPreferences.getInstance()).remove(_key);
  setUp(removeSavedSpeed);
  tearDown(removeSavedSpeed);

  for (final flow in _flows) {
    final name = flow.language.name;

    testWidgets(
      '$name: every speed plays the sample word with its gaps',
      timeout: const Timeout(Duration(minutes: 3)),
      (tester) async {
        final platform = FakeVibrationPlatform()..install(tester);
        final store = InMemoryReadingSpeedStore();
        final app = _app(flow.language, store);
        await _launchToMenu(tester, app, platform);
        expect(_speed(tester, app), ReadingSpeed.wpm12);

        final notifier = app
            .container(tester)
            .read(readingSpeedProvider.notifier);
        for (final (:speed, :characterGap) in _speeds) {
          final before = platform.vibrateCalls.length;

          await notifier.change(speed);

          final wpm = speed.wordsPerMinute;
          expect(
            platform.vibrateCalls,
            hasLength(before + 1),
            reason: 'one sample at $wpm wpm',
          );
          final expected = _pattern(flow.sample, characterGap);
          expect(
            platform.patterns.last,
            expected,
            reason:
                'the sample at $wpm wpm: the same pulses, '
                '$characterGap ms between the letters',
          );
          expect(platform.intensities.last, _intensities(expected));
          expect(_speed(tester, app), speed);
          expect(store.read(), speed, reason: 'saved at $wpm wpm');
        }

        await app.close(tester);
      },
    );

    testWidgets(
      '$name: a lesson word at 5 wpm keeps 300 ms between its letters',
      timeout: const Timeout(Duration(minutes: 2)),
      (tester) async {
        final platform = FakeVibrationPlatform()..install(tester);
        final app = _app(
          flow.language,
          InMemoryReadingSpeedStore(ReadingSpeed.wpm5),
        );
        await _launchToMenu(tester, app, platform);
        expect(_speed(tester, app), ReadingSpeed.wpm5);

        await app.openLessons(tester);
        await _swipeUp(tester);
        await waitUntil(
          tester,
          () => app.session(tester).levelIndex == 1,
          reason: 'a swipe up opens the letters',
        );
        await _swipeUp(tester);
        await waitUntil(
          tester,
          () => app.session(tester).levelIndex == 2,
          reason: 'a swipe up opens the words',
        );

        // Spelled first, then the word itself, with the lesson's letter gap.
        final word = _pattern(flow.firstWord, 300);
        await waitUntil(
          tester,
          () => platform.indexOfPattern(word) != -1,
          reason: 'the first word is played with 300 ms letter gaps',
          timeout: const Duration(seconds: 15),
        );
        for (final pattern in platform.patterns) {
          expect(pattern, isNot(contains(1405)));
          expect(pattern, isNot(contains(3279)));
        }
        expect(platform.indexOfPattern(_pattern(flow.firstWord, 1405)), -1);

        await app.close(tester);
      },
    );
  }

  testWidgets(
    'the speed survives a restart',
    timeout: const Timeout(Duration(minutes: 2)),
    (tester) async {
      final platform = FakeVibrationPlatform()..install(tester);
      final preferences = await SharedPreferences.getInstance();

      // A launch with nothing saved: 12 wpm.
      var app = _app(
        MorseLanguage.english,
        SharedPreferencesReadingSpeedStore(preferences),
      );
      await _launchToMenu(tester, app, platform);
      expect(_speed(tester, app), ReadingSpeed.wpm12);

      await app
          .container(tester)
          .read(readingSpeedProvider.notifier)
          .change(ReadingSpeed.wpm6);
      await app.close(tester);

      // The platform holds the speed in words per minute.
      await preferences.reload();
      expect(preferences.get(_key), 6);

      // A restart: the store is loaded as `main` loads it.
      app = _app(MorseLanguage.english, await loadReadingSpeedStore());
      await _launchToMenu(tester, app, platform);
      expect(_speed(tester, app), ReadingSpeed.wpm6);
      final timing = app
          .container(tester)
          .read(readingTimingConfigProvider(_speed(tester, app)));
      expect(timing.interCharGap, 1089);
      expect(timing.interWordGap, 2542);
      expect(timing.dotDuration, 100);
      expect(timing.dashDuration, 300);

      await app.close(tester);
    },
  );
}
