import 'dart:async';

import 'package:feel_you/vibration/vibration.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_doubles/fake_vibration_capability_probe.dart';

/// The method channel the `vibration` plugin talks to.
const _vibrationChannel = MethodChannel('vibration');

/// Mocks the `vibration` plugin channel and returns the arguments of every
/// `vibrate` call, in order.
List<Map<Object?, Object?>> _mockVibrationChannel(WidgetTester tester) {
  final vibrateCalls = <Map<Object?, Object?>>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    _vibrationChannel,
    (call) async {
      if (call.method == 'vibrate') {
        vibrateCalls.add(call.arguments as Map<Object?, Object?>);
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      _vibrationChannel,
      null,
    ),
  );
  return vibrateCalls;
}

/// Plays [play] to completion, advancing fake time past its duration.
Future<void> _playFully(WidgetTester tester, Future<void> Function() play) {
  final done = play();
  return tester.pump(const Duration(seconds: 1)).then((_) => done);
}

void main() {
  group('DeviceVibrationService signals', () {
    testWidgets('plays the intensity signals with amplitude control', (
      tester,
    ) async {
      final calls = _mockVibrationChannel(tester);
      final service = DeviceVibrationService(
        capabilities: () => const VibrationCapabilities(
          hasVibrator: true,
          hasAmplitudeControl: true,
          hasCustomVibrationsSupport: true,
        ),
      );

      await _playFully(tester, service.playSuccess);
      await _playFully(tester, service.playError);

      expect(calls[0]['pattern'], successSignal.pattern);
      expect(calls[0]['intensities'], successSignal.intensities);
      expect(calls[1]['pattern'], errorSignal.pattern);
      expect(calls[1]['intensities'], errorSignal.intensities);
    });

    testWidgets('plays the duration-only signals without amplitude control', (
      tester,
    ) async {
      final calls = _mockVibrationChannel(tester);
      final service = DeviceVibrationService(
        capabilities: () => const VibrationCapabilities(
          hasVibrator: true,
          hasAmplitudeControl: false,
          hasCustomVibrationsSupport: true,
        ),
      );

      await _playFully(tester, service.playSuccess);
      await _playFully(tester, service.playError);

      expect(calls[0]['pattern'], durationOnlySuccessSignal.pattern);
      expect(calls[1]['pattern'], durationOnlyErrorSignal.pattern);
    });

    testWidgets('keeps the intensity signals when capabilities are unknown', (
      tester,
    ) async {
      final calls = _mockVibrationChannel(tester);
      final service = DeviceVibrationService();

      await _playFully(tester, service.playSuccess);
      await _playFully(tester, service.playError);

      expect(calls[0]['pattern'], successSignal.pattern);
      expect(calls[1]['pattern'], errorSignal.pattern);
    });

    testWidgets('provider switches to duration-only once detection reports '
        'no amplitude control', (tester) async {
      final calls = _mockVibrationChannel(tester);
      final gate = Completer<void>();
      final container = ProviderContainer(
        overrides: [
          vibrationCapabilityProbeProvider.overrideWithValue(
            FakeVibrationCapabilityProbe(amplitudeControl: false, gate: gate),
          ),
        ],
      );
      addTearDown(container.dispose);
      final service = container.read(vibrationServiceProvider);

      // Still detecting: existing behaviour.
      await _playFully(tester, service.playError);
      expect(calls.last['pattern'], errorSignal.pattern);

      gate.complete();
      await container.read(vibrationCapabilitiesProvider.future);

      // Same service instance, now adapted to the device.
      expect(container.read(vibrationServiceProvider), same(service));
      await _playFully(tester, service.playError);
      expect(calls.last['pattern'], durationOnlyErrorSignal.pattern);
    });
  });
}
