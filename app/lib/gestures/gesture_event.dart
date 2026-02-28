import 'package:equatable/equatable.dart';
import 'package:feel_you/morse/morse.dart';
import 'package:flutter/foundation.dart' show immutable;

/// All possible classified gesture events.
///
/// Sealed so that switch/match expressions are exhaustive.
@immutable
sealed class GestureEvent extends Equatable {
  const GestureEvent();
}

/// A single Morse symbol input (dot or dash).
@immutable
class MorseInput extends GestureEvent {
  const MorseInput(this.symbol);

  final MorseSymbol symbol;

  @override
  List<Object?> get props => [symbol];

  @override
  String toString() => 'MorseInput($symbol)';
}

/// The user finished entering a Morse character (silence timeout elapsed).
@immutable
class InputComplete extends GestureEvent {
  const InputComplete(this.symbols);

  final List<MorseSymbol> symbols;

  @override
  List<Object?> get props => [symbols];

  @override
  String toString() => 'InputComplete($symbols)';
}

/// Swipe right — navigate to the next letter.
@immutable
class NavigateNext extends GestureEvent {
  const NavigateNext();

  @override
  List<Object?> get props => [];

  @override
  String toString() => 'NavigateNext';
}

/// Swipe left — navigate to the previous letter.
@immutable
class NavigatePrevious extends GestureEvent {
  const NavigatePrevious();

  @override
  List<Object?> get props => [];

  @override
  String toString() => 'NavigatePrevious';
}

/// Long hold — reset to letter A.
@immutable
class Reset extends GestureEvent {
  const Reset();

  @override
  List<Object?> get props => [];

  @override
  String toString() => 'Reset';
}
