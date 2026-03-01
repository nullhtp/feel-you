import 'package:feel_you/morse/morse_signal.dart';
import 'package:feel_you/morse/morse_token.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Signal', () {
    test('wraps a MorseSignal value', () {
      const signal = Signal(MorseSignal.dot);
      expect(signal.signal, MorseSignal.dot);
    });

    test('equal Signal instances with same signal are equal', () {
      expect(
        const Signal(MorseSignal.dot),
        equals(const Signal(MorseSignal.dot)),
      );
    });

    test('Signal instances with different signals are not equal', () {
      expect(
        const Signal(MorseSignal.dot),
        isNot(equals(const Signal(MorseSignal.dash))),
      );
    });

    test('hashCode is consistent with equality', () {
      expect(
        const Signal(MorseSignal.dot).hashCode,
        equals(const Signal(MorseSignal.dot).hashCode),
      );
    });

    test('toString', () {
      expect(
        const Signal(MorseSignal.dot).toString(),
        'Signal(MorseSignal.dot)',
      );
    });
  });

  group('CharGap', () {
    test('two CharGap instances are equal', () {
      expect(const CharGap(), equals(const CharGap()));
    });

    test('CharGap is not equal to Signal', () {
      expect(const CharGap(), isNot(equals(const Signal(MorseSignal.dot))));
    });

    test('hashCode is consistent between instances', () {
      expect(const CharGap().hashCode, equals(const CharGap().hashCode));
    });

    test('toString', () {
      expect(const CharGap().toString(), 'CharGap');
    });
  });

  group('MorseToken exhaustive switch', () {
    test('switch covers all subtypes', () {
      const List<MorseToken> tokens = [
        Signal(MorseSignal.dot),
        Signal(MorseSignal.dash),
        CharGap(),
      ];

      final descriptions = tokens.map((token) {
        return switch (token) {
          Signal(signal: final s) => 'signal:$s',
          CharGap() => 'gap',
        };
      }).toList();

      expect(descriptions, [
        'signal:MorseSignal.dot',
        'signal:MorseSignal.dash',
        'gap',
      ]);
    });
  });
}
