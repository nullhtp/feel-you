import 'package:feel_you/morse/morse.dart';

/// Abstract interface for triggering vibrations.
///
/// Implementations can use real device haptics or be mocked for testing.
abstract class VibrationService {
  /// Plays a Morse code pattern as a vibration sequence.
  Future<void> playMorsePattern(List<MorseSymbol> symbols);

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
