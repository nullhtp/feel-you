import 'package:feel_you/vibration/morse_timing_config.dart';
import 'package:feel_you/vibration/vibration_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the [MorseTimingConfig] used throughout the app.
///
/// Override this provider in tests or to tune timing values.
final morseTimingConfigProvider = Provider<MorseTimingConfig>(
  (ref) => const MorseTimingConfig(),
);

/// Provides the [VibrationService] for triggering haptic feedback.
///
/// Override this provider in tests to inject a mock service.
final vibrationServiceProvider = Provider<VibrationService>(
  (ref) => DeviceVibrationService(config: ref.watch(morseTimingConfigProvider)),
);
