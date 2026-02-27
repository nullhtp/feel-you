import 'package:feel_you/morse/morse_symbol.dart';
import 'package:feel_you/vibration/vibration_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// A mock [VibrationService] for testing.
///
/// Records all method calls so tests can verify interactions.
class MockVibrationService implements VibrationService {
  final List<String> calls = [];

  @override
  Future<void> playMorsePattern(List<MorseSymbol> symbols) async {
    calls.add('playMorsePattern:$symbols');
  }

  @override
  Future<void> playSuccess() async {
    calls.add('playSuccess');
  }

  @override
  Future<void> playError() async {
    calls.add('playError');
  }

  @override
  Future<void> cancel() async {
    calls.add('cancel');
  }
}

void main() {
  group('VibrationService cancel()', () {
    test('cancel is callable on mock implementation', () async {
      final service = MockVibrationService();
      await service.cancel();
      expect(service.calls, ['cancel']);
    });

    test('cancel is a no-op when nothing is playing', () async {
      final service = MockVibrationService();
      // No prior play call — cancel should still complete without error.
      await service.cancel();
      expect(service.calls, ['cancel']);
    });

    test('cancel can be called after playMorsePattern', () async {
      final service = MockVibrationService();
      await service.playMorsePattern([MorseSymbol.dot, MorseSymbol.dash]);
      await service.cancel();
      expect(service.calls, [
        'playMorsePattern:[MorseSymbol.dot, MorseSymbol.dash]',
        'cancel',
      ]);
    });
  });
}
