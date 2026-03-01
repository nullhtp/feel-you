import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/vibration/vibration_service.dart';

/// A mock [VibrationService] that records all method calls.
///
/// Supports both string-based call log (for simple verification) and
/// typed [VibrationCall] objects (for detailed assertions).
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
  Future<void> playMorsePattern(List<MorseSignal> signals) async {
    calls.add(
      VibrationCall(
        VibrationCallType.playMorsePattern,
        signals: List.of(signals),
      ),
    );
  }

  @override
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
  Future<void> playTapFeedback() async {
    calls.add(const VibrationCall(VibrationCallType.playTapFeedback));
  }

  @override
  Future<void> cancel() async {
    calls.add(const VibrationCall(VibrationCallType.cancel));
  }
}

/// The type of vibration call made to [MockVibrationService].
enum VibrationCallType {
  playMorsePattern,
  playMorseTokenPattern,
  playSuccess,
  playError,
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
      case VibrationCallType.playTapFeedback:
        return 'playTapFeedback';
      case VibrationCallType.cancel:
        return 'cancel';
    }
  }
}
