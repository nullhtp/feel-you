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

/// Vertical swipe up — move to next level.
@immutable
class NavigateUp extends GestureEvent {
  const NavigateUp();

  @override
  List<Object?> get props => [];

  @override
  String toString() => 'NavigateUp';
}

/// Vertical swipe down — move to previous level.
@immutable
class NavigateDown extends GestureEvent {
  const NavigateDown();

  @override
  List<Object?> get props => [];

  @override
  String toString() => 'NavigateDown';
}

/// Shake detected — reset to level 0 position 0.
@immutable
class Home extends GestureEvent {
  const Home();

  @override
  List<Object?> get props => [];

  @override
  String toString() => 'Home';
}

/// Tap in the bottom input zone.
///
/// Level-agnostic marker event — the [TeachingOrchestrator] decides
/// whether to insert a charGap (words level) or submit input (other levels).
@immutable
class BottomZoneAction extends GestureEvent {
  const BottomZoneAction();

  @override
  List<Object?> get props => [];

  @override
  String toString() => 'BottomZoneAction';
}
