import 'package:feel_you/vibration/device_vibration_service.dart';
import 'package:feel_you/vibration/morse_timing_config.dart';
import 'package:feel_you/vibration/reading_speed.dart';
import 'package:feel_you/vibration/vibration_capabilities.dart';
import 'package:feel_you/vibration/vibration_capability_probe.dart';
import 'package:feel_you/vibration/vibration_service.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the lesson timing: the [MorseTimingConfig] that
/// [vibrationServiceProvider] plays with.
///
/// The lessons, the spelling, the quiz marker, the home menu and the
/// language picker play with it, whatever reading speed is saved. It is also
/// the base of every reading timing (see [readingTimingConfigProvider]).
///
/// Override this provider in tests or to tune timing values.
final morseTimingConfigProvider = Provider<MorseTimingConfig>(
  (ref) => const MorseTimingConfig(),
);

/// Provides the timing reading modes play with at a [ReadingSpeed]: the
/// lesson timing ([morseTimingConfigProvider]) with its character and word
/// gaps stretched to that speed (see [ReadingSpeed.timing]).
///
/// Keyed by the speed rather than watching the saved one, so the vibration
/// engine stays unaware of the settings; read it with the saved speed,
/// e.g. `readingTimingConfigProvider(ref.watch(readingSpeedProvider))`.
final readingTimingConfigProvider =
    Provider.family<MorseTimingConfig, ReadingSpeed>(
      (ref, speed) => speed.timing(ref.watch(morseTimingConfigProvider)),
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

/// Provides the [VibrationService] for triggering haptic feedback, with the
/// lesson timing ([morseTimingConfigProvider]).
///
/// Everything but reading modes plays through it: the lessons, the home
/// menu, the language picker and the signals. The saved reading speed never
/// reaches it; reading modes use [readingVibrationServiceProvider].
///
/// Override this provider in tests to inject a mock service.
final vibrationServiceProvider = Provider<VibrationService>(
  (ref) => _deviceVibrationService(ref, ref.watch(morseTimingConfigProvider)),
);

/// Provides the [VibrationService] reading modes play text with at a
/// [ReadingSpeed]: tokens are timed with that speed's
/// [readingTimingConfigProvider]; the signals are the same as
/// [vibrationServiceProvider]'s.
///
/// Read it with the saved speed, e.g.
/// `readingVibrationServiceProvider(ref.watch(readingSpeedProvider))`.
/// Its [VibrationService.cancel] stops the motor like any other's.
///
/// Override this provider in tests to inject a mock service.
final readingVibrationServiceProvider =
    Provider.family<VibrationService, ReadingSpeed>(
      (ref, speed) => _deviceVibrationService(
        ref,
        ref.watch(readingTimingConfigProvider(speed)),
      ),
    );

/// A [DeviceVibrationService] that times tactile tokens with [config] and
/// reads the effective capabilities whenever it plays a signal.
DeviceVibrationService _deviceVibrationService(
  Ref ref,
  MorseTimingConfig config,
) {
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
    config: config,
    capabilities: () => capabilities,
  );
}
