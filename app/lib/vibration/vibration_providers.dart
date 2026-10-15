import 'package:feel_you/vibration/device_vibration_service.dart';
import 'package:feel_you/vibration/morse_timing_config.dart';
import 'package:feel_you/vibration/vibration_capabilities.dart';
import 'package:feel_you/vibration/vibration_capability_probe.dart';
import 'package:feel_you/vibration/vibration_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the [MorseTimingConfig] used throughout the app.
///
/// Override this provider in tests or to tune timing values.
final morseTimingConfigProvider = Provider<MorseTimingConfig>(
  (ref) => const MorseTimingConfig(),
);

/// Provides the [VibrationCapabilityProbe] used to query the device.
///
/// Override this provider in tests to fake the device's capabilities
/// without touching the platform channel.
final vibrationCapabilityProbeProvider = Provider<VibrationCapabilityProbe>(
  (ref) => const DeviceVibrationCapabilityProbe(),
);

/// The device's vibration capabilities, queried once per app run.
///
/// Never completes with an error: failed or `null` queries resolve to
/// unknown capabilities, which the app treats as present (see
/// [VibrationCapabilities]). Watch this provider directly to tell
/// "still checking" apart from the result, or use
/// [effectiveVibrationCapabilitiesProvider] to simply act on it.
final vibrationCapabilitiesProvider = FutureProvider<VibrationCapabilities>(
  (ref) =>
      detectVibrationCapabilities(ref.watch(vibrationCapabilityProbeProvider)),
);

/// The capabilities to act on right now.
///
/// [VibrationCapabilities.unknown] (everything assumed to work) while the
/// detection is still running, so nothing is blocked or delayed at startup.
final effectiveVibrationCapabilitiesProvider = Provider<VibrationCapabilities>(
  (ref) =>
      ref.watch(vibrationCapabilitiesProvider).valueOrNull ??
      VibrationCapabilities.unknown,
);

/// Provides the [VibrationService] for triggering haptic feedback.
///
/// Override this provider in tests to inject a mock service.
final vibrationServiceProvider = Provider<VibrationService>((ref) {
  // Listen rather than watch: the service, and the teaching orchestrator
  // that watches it, must not be rebuilt when detection completes. The
  // service reads the latest value whenever it plays a signal.
  var capabilities = VibrationCapabilities.unknown;
  ref.listen<VibrationCapabilities>(
    effectiveVibrationCapabilitiesProvider,
    (_, next) => capabilities = next,
    fireImmediately: true,
  );
  return DeviceVibrationService(
    config: ref.watch(morseTimingConfigProvider),
    capabilities: () => capabilities,
  );
});
