import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/tactile/tactile.dart';
import 'package:feel_you/vibration/vibration_service.dart';

/// A mock [VibrationService] that records all method calls.
///
/// Supports both string-based call log (for simple verification) and
/// typed [VibrationCall] objects (for detailed assertions).
///
/// Playbacks are recorded in Morse terms, because the lessons are Morse and
/// the tests are written in dots and dashes: [playTokens] turns the tactile
/// tokens back into Morse and records a playback with a character gap (a
/// word) through [playMorseTokenPattern], and one without (a digit, a
/// letter, a spelled letter, `?` or a language identifier) through
/// [playMorsePattern]. Every lesson word has at least two letters, so a
/// gap reliably marks a word. Subclasses can override those two methods to
/// hold a playback open.
class MockVibrationService implements VibrationService {
  final List<VibrationCall> calls = [];

  /// Returns all recorded call types as strings in order.
  List<String> get callLog => calls.map((c) => c.toString()).toList();

  /// Returns the signals from all [playMorsePattern] calls.
  List<List<MorseSignal>> get patterns => calls
      .where((c) => c.type == VibrationCallType.playMorsePattern)
      .map((c) => c.signals!)
      .toList();

  /// Clears all recorded calls.
  void reset() => calls.clear();

  @override
  Future<void> playTokens(List<TactileToken> tokens) {
    final morse = [for (final token in tokens) _morseToken(token)];
    if (morse.contains(const CharGap())) return playMorseTokenPattern(morse);
    return playMorsePattern([for (final token in morse) _signal(token)]);
  }

  /// Records a playback without a character gap, as Morse [signals].
  Future<void> playMorsePattern(List<MorseSignal> signals) async {
    calls.add(
      VibrationCall(
        VibrationCallType.playMorsePattern,
        signals: List.of(signals),
      ),
    );
  }

  /// Records a playback with character gaps, as Morse [tokens].
  Future<void> playMorseTokenPattern(List<MorseToken> tokens) async {
    calls.add(
      VibrationCall(
        VibrationCallType.playMorseTokenPattern,
        tokens: List.of(tokens),
      ),
    );
  }

  @override
  Future<void> playSuccess() async {
    calls.add(const VibrationCall(VibrationCallType.playSuccess));
  }

  @override
  Future<void> playError() async {
    calls.add(const VibrationCall(VibrationCallType.playError));
  }

  @override
  Future<void> playCloudOff() async {
    calls.add(const VibrationCall(VibrationCallType.playCloudOff));
  }

  @override
  Future<void> playTapFeedback() async {
    calls.add(const VibrationCall(VibrationCallType.playTapFeedback));
  }

  @override
  Future<void> cancel() async {
    calls.add(const VibrationCall(VibrationCallType.cancel));
  }
}

/// The Morse token a tactile [token] stands for in a Morse playback.
MorseToken _morseToken(TactileToken token) => switch (token) {
  TactileToken.shortPulse => const Signal(MorseSignal.dot),
  TactileToken.longPulse => const Signal(MorseSignal.dash),
  TactileToken.characterGap => const CharGap(),
  TactileToken.emptySlot => throw UnsupportedError(
    'An empty slot has no Morse equivalent',
  ),
};

/// The signal of a Morse [token] from a playback without a character gap.
MorseSignal _signal(MorseToken token) => switch (token) {
  Signal(:final signal) => signal,
  CharGap() => throw StateError('A character gap is not a signal'),
};

/// The type of vibration call made to [MockVibrationService].
enum VibrationCallType {
  playMorsePattern,
  playMorseTokenPattern,
  playSuccess,
  playError,
  playCloudOff,
  playTapFeedback,
  cancel,
}

/// A single recorded call to [MockVibrationService].
class VibrationCall {
  const VibrationCall(this.type, {this.signals, this.tokens});

  final VibrationCallType type;

  /// Non-null only for [VibrationCallType.playMorsePattern].
  final List<MorseSignal>? signals;

  /// Non-null only for [VibrationCallType.playMorseTokenPattern].
  final List<MorseToken>? tokens;

  @override
  String toString() {
    switch (type) {
      case VibrationCallType.playMorsePattern:
        return 'playMorsePattern:$signals';
      case VibrationCallType.playMorseTokenPattern:
        return 'playMorseTokenPattern:$tokens';
      case VibrationCallType.playSuccess:
        return 'playSuccess';
      case VibrationCallType.playError:
        return 'playError';
      case VibrationCallType.playCloudOff:
        return 'playCloudOff';
      case VibrationCallType.playTapFeedback:
        return 'playTapFeedback';
      case VibrationCallType.cancel:
        return 'cancel';
    }
  }
}
