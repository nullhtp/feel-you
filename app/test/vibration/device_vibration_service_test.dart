import 'dart:async';

import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/tactile/tactile.dart';
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

/// Plays [play] to completion, advancing fake time past its duration
/// ([duration], 1 s by default).
Future<void> _playFully(
  WidgetTester tester,
  Future<void> Function() play, {
  Duration duration = const Duration(seconds: 1),
}) {
  final done = play();
  return tester.pump(duration).then((_) => done);
}

void main() {
  group('DeviceVibrationService Morse patterns', () {
    /// R = dot dash dot.
    const letterR = [
      TactileToken.shortPulse,
      TactileToken.longPulse,
      TactileToken.shortPulse,
    ];

    testWidgets('sends a letter with silent gaps between its symbols', (
      tester,
    ) async {
      final calls = _mockVibrationChannel(tester);
      final service = DeviceVibrationService();

      await _playFully(tester, () => service.playTokens(letterR));

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

      // "IT" = dot dot character gap dash
      await _playFully(
        tester,
        () => service.playTokens(const [
          TactileToken.shortPulse,
          TactileToken.shortPulse,
          TactileToken.characterGap,
          TactileToken.longPulse,
        ]),
      );

      expect(calls, hasLength(1));
      // wait(0) dot(100) gap(100) dot(100) charGap(300) dash(300)
      expect(calls.single['pattern'], [0, 100, 100, 100, 300, 300]);
      expect(calls.single['intensities'], [0, 255, 0, 255, 0, 255]);
    });

    testWidgets('sends two words with a silent word gap', (tester) async {
      final calls = _mockVibrationChannel(tester);
      final service = DeviceVibrationService();

      // "E T" = dot, word gap, dash.
      await _playFully(
        tester,
        () => service.playTokens(const [
          TactileToken.shortPulse,
          TactileToken.wordGap,
          TactileToken.longPulse,
        ]),
        duration: const Duration(milliseconds: 1100),
      );

      expect(calls, hasLength(1));
      // wait(0) dot(100) wordGap(700) dash(300)
      expect(calls.single['pattern'], [0, 100, 700, 300]);
      expect(calls.single['intensities'], [0, 255, 0, 255]);
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

      await _playFully(tester, () => service.playTokens(letterR));

      expect(calls.single['pattern'], [0, 100, 100, 300, 100, 100]);
      expect(calls.single['intensities'], [0, 255, 0, 255, 0, 255]);
    });

    testWidgets('completes only once the whole pattern has played', (
      tester,
    ) async {
      _mockVibrationChannel(tester);
      final service = DeviceVibrationService();
      var done = false;

      unawaited(service.playTokens(letterR).then((_) => done = true));

      // R lasts 0 + 100 + 100 + 300 + 100 + 100 = 700ms.
      await tester.pump(const Duration(milliseconds: 699));
      expect(done, isFalse);
      await tester.pump(const Duration(milliseconds: 1));
      expect(done, isTrue);
    });

    testWidgets('does not vibrate for an empty pattern', (tester) async {
      final calls = _mockVibrationChannel(tester);
      final service = DeviceVibrationService();

      await service.playTokens(const []);

      expect(calls, isEmpty);
    });

    testWidgets('does not vibrate for tokens without a pulse', (tester) async {
      final calls = _mockVibrationChannel(tester);
      final service = DeviceVibrationService();

      // A lone wait would be a one-segment pattern, which the iOS plugin
      // vibrates through.
      await service.playTokens(const [
        TactileToken.characterGap,
        TactileToken.emptySlot,
      ]);

      expect(calls, isEmpty);
    });

    testWidgets('sends what the Morse codec encodes, unchanged', (
      tester,
    ) async {
      final calls = _mockVibrationChannel(tester);
      final service = DeviceVibrationService();
      final codec = MorseCodec(MorseLanguage.english);

      await _playFully(tester, () => service.playTokens(codec.encode('R')));
      await _playFully(tester, () => service.playTokens(codec.encode('IT')));

      expect(calls[0]['pattern'], [0, 100, 100, 300, 100, 100]);
      expect(calls[0]['intensities'], [0, 255, 0, 255, 0, 255]);
      expect(calls[1]['pattern'], [0, 100, 100, 100, 300, 300]);
      expect(calls[1]['intensities'], [0, 255, 0, 255, 0, 255]);
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

    testWidgets('plays the same cloud-off signal on every motor', (
      tester,
    ) async {
      final calls = _mockVibrationChannel(tester);
      for (final amplitude in [true, false, null]) {
        final service = DeviceVibrationService(
          capabilities: () => VibrationCapabilities(
            hasVibrator: true,
            hasAmplitudeControl: amplitude,
            hasCustomVibrationsSupport: true,
          ),
        );
        await _playFully(
          tester,
          service.playCloudOff,
          duration: const Duration(seconds: 2),
        );
      }

      expect(calls, hasLength(3));
      for (final call in calls) {
        expect(call['pattern'], [0, 700, 300, 700]);
        expect(call['intensities'], [0, 255, 0, 255]);
      }
    });

    testWidgets('cloud-off completes only once the signal has played', (
      tester,
    ) async {
      _mockVibrationChannel(tester);
      final service = DeviceVibrationService();
      var done = false;

      unawaited(service.playCloudOff().then((_) => done = true));

      await tester.pump(const Duration(milliseconds: 1699));
      expect(done, isFalse);
      await tester.pump(const Duration(milliseconds: 1));
      expect(done, isTrue);
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
