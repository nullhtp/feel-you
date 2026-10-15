import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/vibration/morse_timing_config.dart';
import 'package:feel_you/vibration/morse_vibration_pattern.dart';
import 'package:feel_you/vibration/signal_pattern.dart';
import 'package:feel_you/vibration/vibration_capabilities.dart';
import 'package:feel_you/vibration/vibration_service.dart';
import 'package:vibration/vibration.dart';

/// Concrete [VibrationService] that uses the `vibration` package.
///
/// For Morse patterns, uses the standard `pattern:` API (no intensities).
/// For success/error signals, uses a single `vibrate(pattern:, intensities:)`
/// call so the OS plays the entire ramp natively without gaps. On a device
/// that definitely lacks amplitude control, the duration-only variants are
/// played instead (see [successSignalFor] and [errorSignalFor]).
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
  Future<void> playMorsePattern(List<MorseSignal> signals) async {
    final pattern = buildMorseVibrationPatternFromSignals(signals, config);
    if (pattern.isEmpty) return;
    await Vibration.vibrate(pattern: pattern);
    var total = 0;
    for (final ms in pattern) {
      total += ms;
    }
    await Future<void>.delayed(Duration(milliseconds: total));
  }

  @override
  Future<void> playMorseTokenPattern(List<MorseToken> tokens) async {
    final pattern = buildMorseVibrationPattern(tokens, config);
    if (pattern.isEmpty) return;
    await Vibration.vibrate(pattern: pattern);
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
