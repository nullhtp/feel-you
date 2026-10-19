import 'package:feel_you/tactile/tactile.dart';

/// Abstract interface for triggering vibrations.
///
/// Implementations can use real device haptics or be mocked for testing.
abstract class VibrationService {
  /// Plays [tokens] as one vibration pattern and completes once it has
  /// played.
  ///
  /// The tokens come from a [TactileCodec] (the Morse codec today). The
  /// service knows only how long each token lasts, never which code
  /// produced it.
  Future<void> playTokens(List<TactileToken> tokens);

  /// Plays the success signal (five rapid taps).
  Future<void> playSuccess();

  /// Plays the error signal (single long buzz).
  Future<void> playError();

  /// Plays the cloud-off signal (two 700 ms buzzes, 300 ms apart).
  ///
  /// Played when the cloud key is deleted. The same pattern on every motor,
  /// with or without amplitude control. Completes once it has played.
  Future<void> playCloudOff();

  /// Plays a short tap-confirmation vibration (~50 ms).
  ///
  /// Used for bottom-zone haptic feedback. Routed through this service
  /// so it doesn't race with [cancel] or pattern playback.
  Future<void> playTapFeedback();

  /// Cancels any ongoing vibration.
  Future<void> cancel();
}
