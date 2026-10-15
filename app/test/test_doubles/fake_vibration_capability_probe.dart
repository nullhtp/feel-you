import 'dart:async';

import 'package:feel_you/vibration/vibration_capability_probe.dart';

/// A [VibrationCapabilityProbe] with scripted answers.
///
/// Each query returns its configured value (which may be `null`), or throws
/// [error] when set. When [gate] is given, every query waits for it to
/// complete first, which keeps detection "loading" for as long as needed.
class FakeVibrationCapabilityProbe implements VibrationCapabilityProbe {
  FakeVibrationCapabilityProbe({
    this.vibrator = true,
    this.amplitudeControl = true,
    this.customVibrations = true,
    this.error,
    this.gate,
  });

  /// Answer for [hasVibrator].
  final bool? vibrator;

  /// Answer for [hasAmplitudeControl].
  final bool? amplitudeControl;

  /// Answer for [hasCustomVibrationsSupport].
  final bool? customVibrations;

  /// When non-null, thrown by every query instead of answering.
  final Object? error;

  /// When non-null, every query waits for this to complete.
  final Completer<void>? gate;

  /// Number of queries made so far, across all three capabilities.
  int queryCount = 0;

  Future<bool?> _answer(bool? value) async {
    queryCount++;
    if (gate != null) await gate!.future;
    if (error != null) Error.throwWithStackTrace(error!, StackTrace.current);
    return value;
  }

  @override
  Future<bool?> hasVibrator() => _answer(vibrator);

  @override
  Future<bool?> hasAmplitudeControl() => _answer(amplitudeControl);

  @override
  Future<bool?> hasCustomVibrationsSupport() => _answer(customVibrations);
}
