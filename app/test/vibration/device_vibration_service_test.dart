import 'dart:async';

import 'package:feel_you/morse/morse.dart';
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
  group('DeviceVibrationService Morse patterns', () {
    /// R = dot dash dot.
    const letterR = [MorseSignal.dot, MorseSignal.dash, MorseSignal.dot];

    testWidgets('sends a letter with silent gaps between its symbols', (
      tester,
    ) async {
      final calls = _mockVibrationChannel(tester);
      final service = DeviceVibrationService();

      await _playFully(tester, () => service.playMorsePattern(letterR));

      expect(calls, hasLength(1));
      // wait(0) dot(100) gap(100) dash(300) gap(100) dot(100)
      expect(calls.single['pattern'], [0, 100, 100, 300, 100, 100]);
      expect(calls.single['intensities'], [0, 255, 0, 255, 0, 255]);
    });

    testWidgets('sends a word with silent symbol and character gaps', (
      tester,
    ) async {
      final calls = _mockVibrationChannel(tester);
      final service = DeviceVibrationService();

      // "IT" = dot dot CharGap dash
      await _playFully(
        tester,
        () => service.playMorseTokenPattern(const [
          Signal(MorseSignal.dot),
          Signal(MorseSignal.dot),
          CharGap(),
          Signal(MorseSignal.dash),
        ]),
      );

      expect(calls, hasLength(1));
      // wait(0) dot(100) gap(100) dot(100) charGap(300) dash(300)
      expect(calls.single['pattern'], [0, 100, 100, 100, 300, 300]);
      expect(calls.single['intensities'], [0, 255, 0, 255, 0, 255]);
    });

    testWidgets('sends intensities even without amplitude control', (
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

      await _playFully(tester, () => service.playMorsePattern(letterR));

      expect(calls.single['pattern'], [0, 100, 100, 300, 100, 100]);
      expect(calls.single['intensities'], [0, 255, 0, 255, 0, 255]);
    });

    testWidgets('completes only once the whole pattern has played', (
      tester,
    ) async {
      _mockVibrationChannel(tester);
      final service = DeviceVibrationService();
      var done = false;

      unawaited(service.playMorsePattern(letterR).then((_) => done = true));

      // R lasts 0 + 100 + 100 + 300 + 100 + 100 = 700ms.
      await tester.pump(const Duration(milliseconds: 699));
      expect(done, isFalse);
      await tester.pump(const Duration(milliseconds: 1));
      expect(done, isTrue);
    });

    testWidgets('does not vibrate for an empty pattern', (tester) async {
      final calls = _mockVibrationChannel(tester);
      final service = DeviceVibrationService();

      await service.playMorsePattern(const []);
      await service.playMorseTokenPattern(const []);

      expect(calls, isEmpty);
    });
  });

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
