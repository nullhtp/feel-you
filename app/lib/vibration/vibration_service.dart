import 'package:feel_you/morse/morse.dart';

/// Abstract interface for triggering vibrations.
///
/// Implementations can use real device haptics or be mocked for testing.
abstract class VibrationService {
  /// Plays a Morse code pattern as a vibration sequence.
  ///
  /// Accepts [MorseSignal] list (single-character patterns) or
  /// [MorseToken] list (word patterns with CharGap separators).
  Future<void> playMorsePattern(List<MorseSignal> signals);

  /// Plays a Morse token pattern (word-level, with CharGap) as a vibration.
  Future<void> playMorseTokenPattern(List<MorseToken> tokens);

  /// Plays the success signal (triple rapid tap).
  Future<void> playSuccess();

  /// Plays the error signal (single long buzz).
  Future<void> playError();

  /// Plays a short tap-confirmation vibration (~50 ms).
  ///
  /// Used for bottom-zone haptic feedback. Routed through this service
  /// so it doesn't race with [cancel] or pattern playback.
  Future<void> playTapFeedback();

  /// Cancels any ongoing vibration.
  Future<void> cancel();
}
