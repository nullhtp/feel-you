import 'package:equatable/equatable.dart';

/// What the device's vibration hardware can do, as reported at startup.
///
/// Vibration is Feel You's only output channel, so these capabilities decide
/// whether a session can start at all and which feedback signals are played.
///
/// Each field is `null` when the capability could not be determined (the
/// query threw, the plugin is missing, or the platform is not supported).
/// Unknown capabilities are treated as present, so the app behaves exactly
/// as it did before capabilities were checked: only a definite `false`
/// changes behaviour.
class VibrationCapabilities extends Equatable {
  const VibrationCapabilities({
    this.hasVibrator,
    this.hasAmplitudeControl,
    this.hasCustomVibrationsSupport,
  });

  /// Nothing could be determined; everything is assumed to work.
  static const unknown = VibrationCapabilities();

  /// Whether the device has a vibration motor.
  ///
  /// `false` means nothing the app plays can be felt, so the session must
  /// not start.
  final bool? hasVibrator;

  /// Whether the motor can vibrate at different strengths.
  ///
  /// Without it the plugin ignores `intensities:`, so the success/error
  /// signals fall back to duration-only patterns (see `signal_pattern.dart`).
  final bool? hasAmplitudeControl;

  /// Whether the device can play custom durations and patterns.
  ///
  /// Without it (on iOS: no Core Haptics, i.e. iPhone 7 and older) every
  /// vibration request plays the same fixed system buzz, so Morse timing is
  /// lost. There is no meaningful fallback, as a fixed buzz can't encode
  /// dots and dashes, so the session is still allowed and the problem is
  /// only surfaced in the companion overlay's diagnostics. The Android
  /// plugin always reports `true`.
  final bool? hasCustomVibrationsSupport;

  /// Whether vibration may work: `false` only when the device definitely
  /// has no vibration motor.
  bool get canVibrate => hasVibrator ?? true;

  /// Whether signals may rely on amplitude: `false` only when the device
  /// definitely lacks amplitude control.
  bool get canControlAmplitude => hasAmplitudeControl ?? true;

  /// Whether Morse timing can be reproduced: `false` only when the device
  /// definitely lacks custom vibration support.
  bool get canPlayCustomPatterns => hasCustomVibrationsSupport ?? true;

  @override
  List<Object?> get props => [
    hasVibrator,
    hasAmplitudeControl,
    hasCustomVibrationsSupport,
  ];

  @override
  String toString() =>
      'VibrationCapabilities(hasVibrator: $hasVibrator, '
      'hasAmplitudeControl: $hasAmplitudeControl, '
      'hasCustomVibrationsSupport: $hasCustomVibrationsSupport)';
}
