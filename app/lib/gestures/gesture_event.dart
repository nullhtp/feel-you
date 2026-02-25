import 'package:feel_you/morse/morse_symbol.dart';
import 'package:flutter/foundation.dart' show immutable;

/// All possible classified gesture events.
///
/// Sealed so that switch/match expressions are exhaustive.
@immutable
sealed class GestureEvent {
  const GestureEvent();
}

/// A single Morse symbol input (dot or dash).
@immutable
class MorseInput extends GestureEvent {
  const MorseInput(this.symbol);

  final MorseSymbol symbol;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is MorseInput && symbol == other.symbol;

  @override
  int get hashCode => symbol.hashCode;

  @override
  String toString() => 'MorseInput($symbol)';
}

/// The user finished entering a Morse character (silence timeout elapsed).
@immutable
class InputComplete extends GestureEvent {
  const InputComplete(this.symbols);

  final List<MorseSymbol> symbols;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InputComplete && _listEquals(symbols, other.symbols);

  @override
  int get hashCode => Object.hashAll(symbols);

  @override
  String toString() => 'InputComplete($symbols)';
}

/// Swipe right — navigate to the next letter.
@immutable
class NavigateNext extends GestureEvent {
  const NavigateNext();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is NavigateNext;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'NavigateNext';
}

/// Swipe left — navigate to the previous letter.
@immutable
class NavigatePrevious extends GestureEvent {
  const NavigatePrevious();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is NavigatePrevious;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'NavigatePrevious';
}

/// Long hold — reset to letter A.
@immutable
class Reset extends GestureEvent {
  const Reset();

  @override
  bool operator ==(Object other) => identical(this, other) || other is Reset;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'Reset';
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
