import 'package:feel_you/morse/morse_symbol.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_doubles/mock_vibration_service.dart';

void main() {
  group('VibrationService cancel()', () {
    test('cancel is callable on mock implementation', () async {
      final service = MockVibrationService();
      await service.cancel();
      expect(service.callLog, ['cancel']);
    });

    test('cancel is a no-op when nothing is playing', () async {
      final service = MockVibrationService();
      // No prior play call — cancel should still complete without error.
      await service.cancel();
      expect(service.callLog, ['cancel']);
    });

    test('cancel can be called after playMorsePattern', () async {
      final service = MockVibrationService();
      await service.playMorsePattern([MorseSymbol.dot, MorseSymbol.dash]);
      await service.cancel();
      expect(service.callLog, [
        'playMorsePattern:[MorseSymbol.dot, MorseSymbol.dash]',
        'cancel',
      ]);
    });
  });
}
