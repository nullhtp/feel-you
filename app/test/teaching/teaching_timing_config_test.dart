import 'package:feel_you/teaching/teaching_timing_config.dart';
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
  });
}
