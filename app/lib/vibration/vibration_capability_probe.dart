import 'dart:io' show Platform;

import 'package:feel_you/vibration/vibration_capabilities.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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

/// [VibrationCapabilityProbe] backed by the `vibration` plugin.
///
/// Only asks the plugin on Android and iOS. Everywhere else (unit and widget
/// tests on a desktop host, web) every capability is reported as unknown,
/// because the plugin would answer `false` there, which would wrongly lock
/// the app.
///
/// Note that the plugin reports no vibrator on emulators and simulators.
class DeviceVibrationCapabilityProbe implements VibrationCapabilityProbe {
  const DeviceVibrationCapabilityProbe();

  static bool get _isSupportedPlatform =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  @override
  Future<bool?> hasVibrator() async =>
      _isSupportedPlatform ? Vibration.hasVibrator() : null;

  @override
  Future<bool?> hasAmplitudeControl() async =>
      _isSupportedPlatform ? Vibration.hasAmplitudeControl() : null;

  @override
  Future<bool?> hasCustomVibrationsSupport() async =>
      _isSupportedPlatform ? Vibration.hasCustomVibrationsSupport() : null;
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
