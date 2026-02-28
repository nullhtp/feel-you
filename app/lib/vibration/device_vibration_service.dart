import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/vibration/morse_timing_config.dart';
import 'package:feel_you/vibration/morse_vibration_pattern.dart';
import 'package:feel_you/vibration/signal_pattern.dart';
import 'package:feel_you/vibration/vibration_service.dart';
import 'package:vibration/vibration.dart';

/// Concrete [VibrationService] that uses the `vibration` package.
///
/// For Morse patterns, uses the standard `pattern:` API (no intensities).
/// For success/error signals, uses a single `vibrate(pattern:, intensities:)`
/// call so the OS plays the entire ramp natively without gaps.
class DeviceVibrationService implements VibrationService {
  DeviceVibrationService({this.config = const MorseTimingConfig()});

  final MorseTimingConfig config;

  @override
  Future<void> playMorsePattern(List<MorseSymbol> symbols) async {
    final pattern = buildMorseVibrationPattern(symbols, config);
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
    await _playSignal(successSignal);
  }

  @override
  Future<void> playError() async {
    await _playSignal(errorSignal);
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
