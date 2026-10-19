import 'dart:io';

import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/tactile/tactile.dart';
import 'package:feel_you/vibration/vibration.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter_test/flutter_test.dart';

const _d = MorseSignal.dot;
const _s = MorseSignal.dash;

/// The prosigns of `morse-prosigns`, written out rather than taken from the
/// code, so the tests pin the spec.
const _patterns = {
  Prosign.endOfMessage: [_d, _s, _d, _s, _d], // AR
  Prosign.wait: [_d, _s, _d, _d, _d], // AS
  Prosign.sos: [_d, _d, _d, _s, _s, _s, _d, _d, _d],
  Prosign.error: [_d, _d, _d, _d, _d, _d, _d, _d], // HH
};

/// What each prosign sends to the device with the default timing, and how
/// long it lasts.
const _defaultTiming = {
  Prosign.endOfMessage: (
    [0, 100, 100, 300, 100, 100, 100, 300, 100, 100],
    1300,
  ),
  Prosign.wait: ([0, 100, 100, 300, 100, 100, 100, 100, 100, 100], 1100),
  Prosign.sos: (
    [
      0, 100, 100, 100, 100, 100, 100, 300, 100, 300, 100, 300, //
      100, 100, 100, 100, 100, 100,
    ],
    2300,
  ),
  Prosign.error: (
    [
      0, 100, 100, 100, 100, 100, 100, 100, 100, //
      100, 100, 100, 100, 100, 100, 100,
    ],
    1500,
  ),
};

/// The Morse codec of every language.
final _codecs = [
  for (final language in MorseLanguage.values) MorseCodec(language),
];

/// The vibrate segments of a `[wait, vibrate, ...]` pattern.
List<int> _vibrations(List<int> pattern) => [
  for (var i = 1; i < pattern.length; i += 2) pattern[i],
];

/// The waits between the vibrations of a `[wait, vibrate, ...]` pattern:
/// every wait but the leading one.
List<int> _pauses(List<int> pattern) => [
  for (var i = 2; i < pattern.length; i += 2) pattern[i],
];

void main() {
  group('morseProsignPattern', () {
    test('is the International Morse prosign', () {
      for (final prosign in Prosign.values) {
        expect(morseProsignPattern(prosign), _patterns[prosign]);
      }
    });
  });

  group('timing', () {
    const defaults = MorseTimingConfig();

    test('with the default timing, AR lasts 1300 ms, AS 1100 ms, SOS '
        '2300 ms and error 1500 ms', () {
      for (final codec in _codecs) {
        for (final prosign in Prosign.values) {
          final (segments, total) = _defaultTiming[prosign]!;
          final pattern = buildVibrationPattern(
            codec.encodeProsign(prosign),
            defaults,
          );
          final reason = '${codec.language.name} $prosign';
          expect(pattern, segments, reason: reason);
          expect(pattern.fold<int>(0, (sum, ms) => sum + ms), total);
        }
      }
    });

    test('follows another timing, and never uses the letter gap', () {
      // Distinct durations, so a duration in the wrong place is caught.
      const timing = MorseTimingConfig(
        dotDuration: 101,
        dashDuration: 303,
        interSymbolGap: 107,
        interCharGap: 311,
      );
      for (final prosign in Prosign.values) {
        final pattern = buildVibrationPattern(
          MorseCodec(MorseLanguage.english).encodeProsign(prosign),
          timing,
        );
        expect(pattern.first, 0);
        expect(_vibrations(pattern), [
          for (final signal in _patterns[prosign]!)
            if (signal == _d) 101 else 303,
        ]);
        expect(
          _pauses(pattern),
          List.filled(_patterns[prosign]!.length - 1, 107),
          reason: '$prosign',
        );
        expect(pattern, isNot(contains(311)), reason: '$prosign');
      }
    });
  });

  group('no prosign is a taught character', () {
    test('in any language, no digit, letter or ? has the pattern of a '
        'prosign', () {
      final checked = <MorseLanguage, int>{};
      for (final language in MorseLanguage.values) {
        final alphabet = morseRegistry.forLanguage(language)!;
        final taught = <String, List<MorseSignal>>{
          for (final level in morseRegistry.levelsForLanguage(language))
            if (level.kind == LevelKind.characters) ...level.patterns,
          ...alphabet.aliases,
          '?': questionMarkPattern,
        };
        for (final MapEntry(key: character, value: pattern) in taught.entries) {
          for (final prosign in Prosign.values) {
            expect(
              listEquals(pattern, morseProsignPattern(prosign)),
              isFalse,
              reason: '${language.name} "$character" is $prosign',
            );
          }
        }
        for (final prosign in Prosign.values) {
          expect(
            morseRegistry.decodePattern(morseProsignPattern(prosign), language),
            isNull,
            reason: '${language.name} decodes $prosign',
          );
        }
        checked[language] = taught.length;
      }
      // 10 digits, the letters, the aliases and ?.
      expect(checked, {
        MorseLanguage.english: 10 + 26 + 1,
        MorseLanguage.arabic: 10 + 28 + 2 + 1,
        MorseLanguage.russian: 10 + 32 + 1 + 1,
        MorseLanguage.spanish: 10 + 27 + 1,
        MorseLanguage.french: 10 + 30 + 1,
        MorseLanguage.german: 10 + 29 + 1,
      });
    });

    test('the prosigns differ from each other', () {
      for (final a in Prosign.values) {
        for (final b in Prosign.values) {
          if (a == b) continue;
          expect(
            listEquals(morseProsignPattern(a), morseProsignPattern(b)),
            isFalse,
            reason: '$a and $b',
          );
        }
      }
    });
  });

  group("no prosign is one of the app's signals", () {
    // The signals' vibrate segments are where their intensity is non-zero.
    List<int> signalVibrations(SignalPattern signal) => [
      for (var i = 0; i < signal.pattern.length; i++)
        if (signal.intensities[i] > 0) signal.pattern[i],
    ];

    final signals = {
      'success': signalVibrations(successSignal),
      'success, duration only': signalVibrations(durationOnlySuccessSignal),
      'error': signalVibrations(errorSignal),
      'error, duration only': signalVibrations(durationOnlyErrorSignal),
      'cloud off': signalVibrations(cloudOffSignal),
      // `playTapFeedback`: one 50 ms vibration (`vibration-engine`).
      'tap feedback': const [50],
    };

    test('every vibration of a prosign is a dot or a dash, every pause the '
        'inter-symbol gap', () {
      for (final prosign in Prosign.values) {
        final pattern = buildVibrationPattern(
          MorseCodec(MorseLanguage.english).encodeProsign(prosign),
          const MorseTimingConfig(),
        );
        expect(_vibrations(pattern), everyElement(isIn(const [100, 300])));
        expect(_pauses(pattern), everyElement(100));
      }
    });

    test('every signal has a vibration shorter than a dot or longer than '
        'a dash', () {
      for (final MapEntry(key: name, value: vibrations) in signals.entries) {
        expect(
          vibrations.any((ms) => ms == 50 || ms >= 500),
          isTrue,
          reason: name,
        );
        expect(
          vibrations.any((ms) => ms == 100 || ms == 300),
          isFalse,
          reason: name,
        );
      }
    });
  });

  test('nothing in lib/ plays or shows a prosign yet', () {
    // #44, #53, #64 and #80 wire them in; each updates this test.
    const allowed = {
      'lib/tactile/tactile_codec.dart',
      'lib/morse/morse_codec.dart',
    };
    final call = RegExp(r'(encode|describe)Prosign\(');
    final callers = [
      for (final file in Directory('lib').listSync(recursive: true))
        if (file is File &&
            file.path.endsWith('.dart') &&
            call.hasMatch(file.readAsStringSync()))
          file.path,
    ];
    expect(callers.toSet(), allowed);
  });
}
