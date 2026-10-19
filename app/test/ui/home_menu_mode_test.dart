import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/tactile/tactile.dart';
import 'package:feel_you/ui/home_menu_mode.dart';
import 'package:feel_you/vibration/vibration.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

// The home menu's modes and the Morse letters that announce them (#41).

const _short = TactileToken.shortPulse;
const _long = TactileToken.longPulse;

/// The codec the menu plays its letters with: International Morse.
final _codec = MorseCodec(HomeMenuMode.identifierLanguage);

/// The tokens that announce [mode].
List<TactileToken> _identifierOf(HomeMenuMode mode) =>
    _codec.encode(mode.letter);

/// Total length of [tokens] with the default timing, in ms.
int _durationOf(List<TactileToken> tokens) => buildVibrationPattern(
  tokens,
  const MorseTimingConfig(),
).fold(0, (total, ms) => total + ms);

void main() {
  test('the menu shows Learn, then Settings', () {
    expect(HomeMenuMode.values, [HomeMenuMode.learn, HomeMenuMode.settings]);
    expect(HomeMenuMode.learn.label, 'Learn');
    expect(HomeMenuMode.settings.label, 'Settings');
  });

  test('the letters are played in International Morse', () {
    expect(HomeMenuMode.identifierLanguage, MorseLanguage.english);
  });

  test('Learn is Morse L, 900 ms', () {
    expect(HomeMenuMode.learn.letter, 'L');
    expect(_identifierOf(HomeMenuMode.learn), [_short, _long, _short, _short]);
    expect(_codec.describe('L'), '· — · ·');
    expect(_durationOf(_identifierOf(HomeMenuMode.learn)), 900);
  });

  test('Settings is Morse S, 500 ms', () {
    expect(HomeMenuMode.settings.letter, 'S');
    expect(_identifierOf(HomeMenuMode.settings), [_short, _short, _short]);
    expect(_codec.describe('S'), '· · ·');
    expect(_durationOf(_identifierOf(HomeMenuMode.settings)), 500);
  });

  test('the identifiers are also letters of every lesson language', () {
    const sameAsL = {
      MorseLanguage.arabic: 'ل',
      MorseLanguage.russian: 'Л',
      MorseLanguage.spanish: 'L',
      MorseLanguage.french: 'L',
      MorseLanguage.german: 'L',
    };
    const sameAsS = {
      MorseLanguage.arabic: 'س',
      MorseLanguage.russian: 'С',
      MorseLanguage.spanish: 'S',
      MorseLanguage.french: 'S',
      MorseLanguage.german: 'S',
    };
    for (final MapEntry(key: language, value: letter) in sameAsL.entries) {
      expect(
        MorseCodec(language).encode(letter),
        _identifierOf(HomeMenuMode.learn),
        reason: '$language $letter',
      );
    }
    for (final MapEntry(key: language, value: letter) in sameAsS.entries) {
      expect(
        MorseCodec(language).encode(letter),
        _identifierOf(HomeMenuMode.settings),
        reason: '$language $letter',
      );
    }
  });

  test('every mode has its own, non-empty identifier', () {
    for (final mode in HomeMenuMode.values) {
      expect(_identifierOf(mode), isNotEmpty, reason: mode.name);
      for (final other in HomeMenuMode.values) {
        if (other == mode) continue;
        expect(
          listEquals(_identifierOf(mode), _identifierOf(other)),
          isFalse,
          reason: '${mode.name} vs ${other.name}',
        );
      }
    }
  });

  test('every mode has a screen-reader hint', () {
    expect(HomeMenuMode.learn.hint, 'Opens the Morse lessons');
    expect(HomeMenuMode.settings.hint, 'Opens the language choice');
  });
}
