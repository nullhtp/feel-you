import 'package:feel_you/tactile/tactile.dart';
import 'package:feel_you/vibration/vibration.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The gaps of each speed at the default timing, written out from the ARRL
/// Farnsworth formula (character speed 12 wpm) rather than taken from the
/// app, so the test pins the spec's table.
const _table = {
  ReadingSpeed.wpm12: (characterGap: 300, wordGap: 700),
  ReadingSpeed.wpm10: (characterGap: 458, wordGap: 1068),
  ReadingSpeed.wpm8: (characterGap: 695, wordGap: 1621),
  ReadingSpeed.wpm6: (characterGap: 1089, wordGap: 2542),
  ReadingSpeed.wpm5: (characterGap: 1405, wordGap: 3279),
};

void main() {
  group('ReadingSpeed', () {
    test('has five speeds, fastest first', () {
      expect(ReadingSpeed.values, [
        ReadingSpeed.wpm12,
        ReadingSpeed.wpm10,
        ReadingSpeed.wpm8,
        ReadingSpeed.wpm6,
        ReadingSpeed.wpm5,
      ]);
      expect(
        [for (final speed in ReadingSpeed.values) speed.wordsPerMinute],
        [12, 10, 8, 6, 5],
      );
    });

    test('the default is 12 wpm, the character speed', () {
      expect(ReadingSpeed.standard, ReadingSpeed.wpm12);
      expect(ReadingSpeed.characterSpeed, 12);
      expect(ReadingSpeed.standard.wordsPerMinute, ReadingSpeed.characterSpeed);
    });

    test('finds a speed by its words per minute', () {
      for (final speed in ReadingSpeed.values) {
        expect(ReadingSpeed.fromWordsPerMinute(speed.wordsPerMinute), speed);
      }
      for (final unknown in [0, 7, 11, 13, 20, -5]) {
        expect(ReadingSpeed.fromWordsPerMinute(unknown), isNull);
      }
    });

    test('stretches the gaps by the ARRL Farnsworth ratio', () {
      // ta(s) / ta(12), with ta(s) = (60c - 37.2s) / (cs).
      double ta(int s) => (60 * 12 - 37.2 * s) / (12 * s);
      for (final speed in ReadingSpeed.values) {
        expect(
          speed.gapStretch,
          closeTo(ta(speed.wordsPerMinute) / ta(12), 1e-9),
          reason: '${speed.wordsPerMinute} wpm',
        );
      }
    });

    test('the stretch is exactly 1 at the default speed', () {
      expect(ReadingSpeed.standard.gapStretch, 1);
    });

    test('slower speeds stretch more', () {
      final stretches = [
        for (final speed in ReadingSpeed.values) speed.gapStretch,
      ];
      for (var i = 1; i < stretches.length; i++) {
        expect(stretches[i], greaterThan(stretches[i - 1]));
      }
    });
  });

  group('ReadingSpeed.timing', () {
    const lesson = MorseTimingConfig();

    test('gives the pinned gaps of every speed', () {
      for (final MapEntry(key: speed, value: gaps) in _table.entries) {
        final timing = speed.timing(lesson);
        expect(
          timing.interCharGap,
          gaps.characterGap,
          reason: '${speed.wordsPerMinute} wpm character gap',
        );
        expect(
          timing.interWordGap,
          gaps.wordGap,
          reason: '${speed.wordsPerMinute} wpm word gap',
        );
      }
      expect(_table.keys, ReadingSpeed.values);
    });

    test('never changes the pulses or the gap inside a character', () {
      for (final speed in ReadingSpeed.values) {
        final timing = speed.timing(lesson);
        expect(timing.dotDuration, 100);
        expect(timing.dashDuration, 300);
        expect(timing.interSymbolGap, 100);
      }
    });

    test('at 12 wpm is exactly the lesson timing', () {
      expect(ReadingSpeed.wpm12.timing(lesson), lesson);
    });

    test('follows a tuned lesson timing', () {
      const tuned = MorseTimingConfig(
        dotDuration: 120,
        dashDuration: 360,
        interSymbolGap: 110,
        interCharGap: 400,
        interWordGap: 900,
      );
      expect(ReadingSpeed.wpm12.timing(tuned), tuned);
      // 400 × 1.5263 = 610.5, 900 × 1.5263 = 1373.7.
      expect(
        ReadingSpeed.wpm10.timing(tuned),
        tuned.copyWith(interCharGap: 611, interWordGap: 1374),
      );
    });

    test('plays a word at 5 wpm with the stretched gaps only', () {
      // "TEN TEN" as tokens: T E N, a word gap, T E N.
      const word = [
        TactileToken.longPulse,
        TactileToken.characterGap,
        TactileToken.shortPulse,
        TactileToken.characterGap,
        TactileToken.longPulse,
        TactileToken.shortPulse,
      ];
      final pattern = buildVibrationPattern([
        ...word,
        TactileToken.wordGap,
        ...word,
      ], ReadingSpeed.wpm5.timing(lesson));
      expect(pattern, [
        0, 300, 1405, 100, 1405, 300, 100, 100, // TEN
        3279, // word gap
        300, 1405, 100, 1405, 300, 100, 100, // TEN
      ]);
    });
  });

  group('reading providers', () {
    test('the reading timing is the lesson timing stretched to the speed', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      for (final speed in ReadingSpeed.values) {
        expect(
          container.read(readingTimingConfigProvider(speed)),
          speed.timing(container.read(morseTimingConfigProvider)),
        );
      }
      expect(
        container.read(readingTimingConfigProvider(ReadingSpeed.wpm6)),
        const MorseTimingConfig(interCharGap: 1089, interWordGap: 2542),
      );
    });

    test('the reading timing follows an overridden lesson timing', () {
      const tuned = MorseTimingConfig(dotDuration: 1, dashDuration: 2);
      final container = ProviderContainer(
        overrides: [morseTimingConfigProvider.overrideWithValue(tuned)],
      );
      addTearDown(container.dispose);

      expect(
        container.read(readingTimingConfigProvider(ReadingSpeed.wpm5)),
        tuned.copyWith(interCharGap: 1405, interWordGap: 3279),
      );
    });

    test('the reading service plays with the reading timing', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      for (final speed in ReadingSpeed.values) {
        final service = container.read(readingVibrationServiceProvider(speed));
        expect(service, isA<DeviceVibrationService>());
        expect(
          (service as DeviceVibrationService).config,
          container.read(readingTimingConfigProvider(speed)),
        );
      }
    });

    test('the lesson service keeps the lesson timing', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Reading at the slowest speed does not touch the lesson service.
      container.read(readingVibrationServiceProvider(ReadingSpeed.wpm5));
      final lesson = container.read(vibrationServiceProvider);
      expect(
        (lesson as DeviceVibrationService).config,
        const MorseTimingConfig(),
      );
      expect(lesson.config.interCharGap, 300);
      expect(
        lesson,
        isNot(
          same(
            container.read(readingVibrationServiceProvider(ReadingSpeed.wpm12)),
          ),
        ),
      );
    });
  });
}
