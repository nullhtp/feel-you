import 'package:feel_you/vibration/vibration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shown while capability detection is still running.
const vibrationDiagnosticsCheckingLabel = 'Vibration: checking…';

/// Small vibration capability readout for the companion overlay.
///
/// Lets a sighted helper diagnose a "nothing happens" report at a glance,
/// e.g. `Vibration: OK · amplitude: no · custom: yes`. Sits dimmed in the
/// bottom-left corner of the screen and turns amber when a capability is
/// definitely missing. Meant as a child of the overlay's [Stack].
class VibrationDiagnostics extends ConsumerWidget {
  const VibrationDiagnostics({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capabilities = switch (ref.watch(vibrationCapabilitiesProvider)) {
      AsyncData(:final value) => value,
      // The provider never fails, but if it did nothing would be known.
      AsyncError() => VibrationCapabilities.unknown,
      _ => null,
    };
    final hasProblem =
        capabilities != null && hasMissingVibrationCapability(capabilities);

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            capabilities == null
                ? vibrationDiagnosticsCheckingLabel
                : describeVibrationCapabilities(capabilities),
            style: TextStyle(
              color: hasProblem
                  ? Colors.amber
                  : Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
              fontWeight: hasProblem ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

/// Formats [capabilities] as a one-line readout, for example
/// `Vibration: OK · amplitude: no · custom: yes`.
///
/// Capabilities that could not be determined read `unknown`.
String describeVibrationCapabilities(VibrationCapabilities capabilities) {
  final motor = switch (capabilities.hasVibrator) {
    true => 'OK',
    false => 'NONE',
    null => 'unknown',
  };
  return 'Vibration: $motor'
      ' · amplitude: ${_yesNo(capabilities.hasAmplitudeControl)}'
      ' · custom: ${_yesNo(capabilities.hasCustomVibrationsSupport)}';
}

/// Whether any capability is definitely missing (reported as `false`).
bool hasMissingVibrationCapability(VibrationCapabilities capabilities) =>
    !capabilities.canVibrate ||
    !capabilities.canControlAmplitude ||
    !capabilities.canPlayCustomPatterns;

String _yesNo(bool? value) => switch (value) {
  true => 'yes',
  false => 'no',
  null => 'unknown',
};
