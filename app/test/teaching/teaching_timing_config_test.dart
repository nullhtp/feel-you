import 'package:feel_you/teaching/teaching_timing_config.dart';
import 'package:feel_you/vibration/morse_timing_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TeachingTimingConfig', () {
    test('default repeatPause is 3000ms', () {
      const config = TeachingTimingConfig();
      expect(config.repeatPause, const Duration(milliseconds: 3000));
    });

    test('custom repeatPause is accepted', () {
      const config = TeachingTimingConfig(
        repeatPause: Duration(milliseconds: 5000),
      );
      expect(config.repeatPause, const Duration(milliseconds: 5000));
    });

    test('default spellingLetterGap is 1000ms', () {
      const config = TeachingTimingConfig();
      expect(config.spellingLetterGap, const Duration(milliseconds: 1000));
    });

    test('spellingLetterGap is between the drilled letter gap and the '
        'repeat pause', () {
      const config = TeachingTimingConfig();
      final drilledLetterGap = Duration(
        milliseconds: const MorseTimingConfig().interCharGap,
      );
      expect(config.spellingLetterGap, greaterThan(drilledLetterGap * 2));
      expect(config.spellingLetterGap * 2, lessThan(config.repeatPause));
    });

    test('default quizMarkerGap is 1000ms', () {
      const config = TeachingTimingConfig();
      expect(config.quizMarkerGap, const Duration(milliseconds: 1000));
    });

    test('custom quizMarkerGap is accepted', () {
      const config = TeachingTimingConfig(
        quizMarkerGap: Duration(milliseconds: 1500),
      );
      expect(config.quizMarkerGap, const Duration(milliseconds: 1500));
    });
  });
}
