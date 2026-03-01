import 'package:feel_you/morse/morse_signal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MorseSignal', () {
    test('has exactly two values', () {
      expect(MorseSignal.values, hasLength(2));
    });

    test('contains dot and dash', () {
      expect(MorseSignal.values, contains(MorseSignal.dot));
      expect(MorseSignal.values, contains(MorseSignal.dash));
    });

    test('does not contain charGap', () {
      for (final value in MorseSignal.values) {
        expect(value.name, isNot('charGap'));
      }
    });

    test('dot and dash are distinct', () {
      expect(MorseSignal.dot, isNot(MorseSignal.dash));
    });
  });
}
