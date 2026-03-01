import 'package:feel_you/morse/morse_signal.dart';

/// A token in a Morse word pattern.
///
/// Word-level patterns need both signals (dot/dash) and structural
/// separators (character gaps). This sealed class cleanly separates
/// the two concepts while allowing exhaustive pattern matching.
sealed class MorseToken {
  const MorseToken();
}

/// A signal token wrapping a [MorseSignal] value.
class Signal extends MorseToken {
  const Signal(this.signal);

  /// The underlying Morse signal (dot or dash).
  final MorseSignal signal;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Signal && signal == other.signal;

  @override
  int get hashCode => signal.hashCode;

  @override
  String toString() => 'Signal($signal)';
}

/// An inter-character gap within a multi-character word pattern.
class CharGap extends MorseToken {
  const CharGap();

  @override
  bool operator ==(Object other) => identical(this, other) || other is CharGap;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'CharGap';
}
