import 'package:feel_you/tactile/tactile.dart';
import 'package:feel_you/vibration/morse_timing_config.dart';
import 'package:feel_you/vibration/signal_pattern.dart';
import 'package:feel_you/vibration/vibration_capabilities.dart';
import 'package:feel_you/vibration/vibration_pattern.dart';
import 'package:feel_you/vibration/vibration_service.dart';
import 'package:vibration/vibration.dart';

/// Concrete [VibrationService] that uses the `vibration` package.
///
/// For tactile tokens, sends the `[wait, vibrate, ...]` pattern built by
/// [buildVibrationPattern] with matching intensities (0 for waits, 255 for
/// vibrates; see [buildVibrationIntensities]) so iOS keeps the gaps between
/// pulses. For success/error signals, uses a single
/// `vibrate(pattern:, intensities:)` call so the OS plays the entire ramp
/// natively without gaps. On a device that definitely lacks amplitude
/// control, the duration-only variants are played instead (see
/// [successSignalFor] and [errorSignalFor]). The cloud-off signal is the
/// same on every motor.
///
/// Missing custom vibration support is not compensated for here: without
/// it the platform plays a fixed system buzz for every request, which can't
/// encode Morse timing. It is surfaced in the companion overlay instead.
class DeviceVibrationService implements VibrationService {
  DeviceVibrationService({
    this.config = const MorseTimingConfig(),
    VibrationCapabilities Function()? capabilities,
  }) : _capabilities = capabilities ?? _unknownCapabilities;

  final MorseTimingConfig config;

  /// Returns the device's current vibration capabilities.
  ///
  /// A getter rather than a value: capabilities are detected asynchronously
  /// at startup, and this service must not be rebuilt when they arrive.
  /// Read on every success/error signal.
  final VibrationCapabilities Function() _capabilities;

  static VibrationCapabilities _unknownCapabilities() =>
      VibrationCapabilities.unknown;

  @override
  Future<void> playTokens(List<TactileToken> tokens) async {
    await _playPattern(buildVibrationPattern(tokens, config));
  }

  /// Plays a tactile [pattern] in a single native call, then waits until it
  /// has finished.
  ///
  /// Always sends explicit intensities (see [buildVibrationIntensities]):
  /// without them the iOS plugin vibrates through the gaps as well.
  Future<void> _playPattern(List<int> pattern) async {
    if (pattern.isEmpty) return;
    await Vibration.vibrate(
      pattern: pattern,
      intensities: buildVibrationIntensities(pattern),
    );
    var total = 0;
    for (final ms in pattern) {
      total += ms;
    }
    await Future<void>.delayed(Duration(milliseconds: total));
  }

  @override
  Future<void> playSuccess() async {
    await _playSignal(successSignalFor(_capabilities()));
  }

  @override
  Future<void> playError() async {
    await _playSignal(errorSignalFor(_capabilities()));
  }

  @override
  Future<void> playCloudOff() async {
    // The same pattern on every motor: see [cloudOffSignal].
    await _playSignal(cloudOffSignal);
  }

  /// Plays a signal pattern in a single native call.
  Future<void> _playSignal(SignalPattern signal) async {
    await Vibration.vibrate(
      pattern: signal.pattern,
      intensities: signal.intensities,
    );
    await Future<void>.delayed(Duration(milliseconds: signal.totalDuration));
  }

  @override
  Future<void> playTapFeedback() async {
    await Vibration.vibrate(duration: 50);
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }

  @override
  Future<void> cancel() async {
    await Vibration.cancel();
  }
}
