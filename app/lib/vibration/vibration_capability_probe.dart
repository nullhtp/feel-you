import 'dart:io' show Platform;

import 'package:feel_you/vibration/vibration_capabilities.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, kIsWeb, visibleForTesting;
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

/// Queries the device for its vibration capabilities.
///
/// A seam between the app and the `vibration` plugin: inject a fake through
/// `vibrationCapabilityProbeProvider` so tests never hit the platform
/// channel. Each query may return `null` (unknown) or throw; callers go
/// through [detectVibrationCapabilities], which turns both into "unknown".
abstract interface class VibrationCapabilityProbe {
  /// Whether the device has a vibration motor.
  Future<bool?> hasVibrator();

  /// Whether the motor supports amplitude (intensity) control.
  Future<bool?> hasAmplitudeControl();

  /// Whether the device can play custom durations and patterns.
  Future<bool?> hasCustomVibrationsSupport();
}

/// The app's own channel to the vibration hardware, implemented in
/// `MainActivity.kt` on Android and `AppDelegate.swift` on iOS.
///
/// Answers `hasVibrator` and `hasAmplitudeControl` with a `bool`.
const vibratorChannel = MethodChannel('feel_you/vibrator');

/// [VibrationCapabilityProbe] backed by the platform.
///
/// - **Android and iOS**: the motor and amplitude control are asked of the
///   hardware through [vibratorChannel], because the plugin only checks
///   whether the device is physical: it reports a motor on a motorless
///   Android tablet and on every iPad, and none on any emulator or
///   simulator. Custom patterns come from the plugin, which answers `true`
///   on Android, where every API level can time patterns, and asks Core
///   Haptics on iOS. Through the channel, Android emulators report their
///   virtual motor; the iOS simulator reports none, and debug builds can
///   bypass the gate there (see `vibrationGateBypassProvider`).
/// - **Anywhere else** (unit and widget tests on a desktop host, web): every
///   capability is unknown, because the plugin would answer `false` there,
///   which would wrongly lock the app.
class DeviceVibrationCapabilityProbe implements VibrationCapabilityProbe {
  /// Creates a probe for the platform the app runs on.
  ///
  /// Tests may pass [platform] to act as if running there.
  const DeviceVibrationCapabilityProbe({
    @visibleForTesting TargetPlatform? platform,
  }) : _platformOverride = platform;

  final TargetPlatform? _platformOverride;

  /// The platform to query, or `null` when the device can't be asked.
  TargetPlatform? get _platform => _platformOverride ?? _hostPlatform;

  static TargetPlatform? get _hostPlatform {
    if (kIsWeb) return null;
    if (Platform.isAndroid) return TargetPlatform.android;
    if (Platform.isIOS) return TargetPlatform.iOS;
    return null;
  }

  @override
  Future<bool?> hasVibrator() async => switch (_platform) {
    TargetPlatform.android || TargetPlatform.iOS =>
      await vibratorChannel.invokeMethod<bool>('hasVibrator'),
    _ => null,
  };

  @override
  Future<bool?> hasAmplitudeControl() async => switch (_platform) {
    TargetPlatform.android || TargetPlatform.iOS =>
      await vibratorChannel.invokeMethod<bool>('hasAmplitudeControl'),
    _ => null,
  };

  @override
  Future<bool?> hasCustomVibrationsSupport() async => switch (_platform) {
    TargetPlatform.android ||
    TargetPlatform.iOS => await Vibration.hasCustomVibrationsSupport(),
    _ => null,
  };
}

/// Queries all capabilities from [probe] concurrently.
///
/// Never throws: a query that fails (platform error, missing plugin, ...)
/// or returns `null` leaves that capability unknown, which the app treats
/// as present. The other capabilities are still reported.
Future<VibrationCapabilities> detectVibrationCapabilities(
  VibrationCapabilityProbe probe,
) async {
  final (vibrator, amplitude, custom) = await (
    _unknownOnError(probe.hasVibrator),
    _unknownOnError(probe.hasAmplitudeControl),
    _unknownOnError(probe.hasCustomVibrationsSupport),
  ).wait;
  return VibrationCapabilities(
    hasVibrator: vibrator,
    hasAmplitudeControl: amplitude,
    hasCustomVibrationsSupport: custom,
  );
}

/// Runs [query], mapping any thrown error to `null` (unknown).
Future<bool?> _unknownOnError(Future<bool?> Function() query) async {
  try {
    return await query();
  } on Object {
    // Any failure, including MissingPluginException, PlatformException and
    // UnimplementedError, means we can't tell. Assume the capability exists
    // rather than locking out a device that might work.
    return null;
  }
}
