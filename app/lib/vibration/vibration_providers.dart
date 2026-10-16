import 'package:feel_you/vibration/device_vibration_service.dart';
import 'package:feel_you/vibration/morse_timing_config.dart';
import 'package:feel_you/vibration/vibration_capabilities.dart';
import 'package:feel_you/vibration/vibration_capability_probe.dart';
import 'package:feel_you/vibration/vibration_service.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
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

/// Whether a developer chose to continue past the "no vibration motor"
/// screen in a debug build.
///
/// The iOS simulator and motorless test devices would otherwise never
/// reach a session (Android emulators report a motor, so they pass the
/// gate). Only `NoVibrationScreen` sets it, and only in debug builds. It
/// lives in memory, so it never outlasts the app run.
final vibrationGateBypassProvider = NotifierProvider<VibrationGateBypass, bool>(
  VibrationGateBypass.new,
);

/// Holds whether the vibration gate is bypassed; see
/// [vibrationGateBypassProvider].
class VibrationGateBypass extends Notifier<bool> {
  @override
  bool build() => false;

  /// Lets sessions start despite a missing motor, for the rest of this run.
  ///
  /// Does nothing outside debug builds.
  void bypass() {
    if (kDebugMode) state = true;
  }
}

/// The capabilities to act on right now.
///
/// [VibrationCapabilities.unknown] (everything assumed to work) while the
/// detection is still running, so nothing is blocked or delayed at startup.
///
/// When a debug build bypasses the gate (see [vibrationGateBypassProvider]),
/// the motor is reported as unknown, so [VibrationCapabilities.canVibrate]
/// is `true`. The other capabilities keep their detected values. Read
/// [vibrationCapabilitiesProvider] for what the device really reported.
final effectiveVibrationCapabilitiesProvider = Provider<VibrationCapabilities>((
  ref,
) {
  final detected =
      ref.watch(vibrationCapabilitiesProvider).valueOrNull ??
      VibrationCapabilities.unknown;
  // kDebugMode is a compile-time constant, so release and profile builds
  // drop this branch entirely: there the gate can't be bypassed.
  if (kDebugMode && ref.watch(vibrationGateBypassProvider)) {
    return VibrationCapabilities(
      hasAmplitudeControl: detected.hasAmplitudeControl,
      hasCustomVibrationsSupport: detected.hasCustomVibrationsSupport,
    );
  }
  return detected;
});

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
