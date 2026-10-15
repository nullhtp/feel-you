import 'dart:async';

import 'package:feel_you/vibration/vibration.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_doubles/fake_vibration_capability_probe.dart';

/// A probe whose queries throw synchronously instead of returning a failed
/// future.
class _SyncThrowingProbe implements VibrationCapabilityProbe {
  @override
  Future<bool?> hasVibrator() => throw MissingPluginException();

  @override
  Future<bool?> hasAmplitudeControl() => throw MissingPluginException();

  @override
  Future<bool?> hasCustomVibrationsSupport() => throw MissingPluginException();
}

/// Creates a container whose capability probe is [probe].
ProviderContainer _containerWith(VibrationCapabilityProbe probe) {
  final container = ProviderContainer(
    overrides: [vibrationCapabilityProbeProvider.overrideWithValue(probe)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('VibrationCapabilities', () {
    test('unknown capabilities are all null and assumed present', () {
      const caps = VibrationCapabilities.unknown;
      expect(caps.hasVibrator, isNull);
      expect(caps.hasAmplitudeControl, isNull);
      expect(caps.hasCustomVibrationsSupport, isNull);
      expect(caps.canVibrate, isTrue);
      expect(caps.canControlAmplitude, isTrue);
      expect(caps.canPlayCustomPatterns, isTrue);
    });

    test('only a definite false disables a capability', () {
      const none = VibrationCapabilities(
        hasVibrator: false,
        hasAmplitudeControl: false,
        hasCustomVibrationsSupport: false,
      );
      expect(none.canVibrate, isFalse);
      expect(none.canControlAmplitude, isFalse);
      expect(none.canPlayCustomPatterns, isFalse);

      const all = VibrationCapabilities(
        hasVibrator: true,
        hasAmplitudeControl: true,
        hasCustomVibrationsSupport: true,
      );
      expect(all.canVibrate, isTrue);
      expect(all.canControlAmplitude, isTrue);
      expect(all.canPlayCustomPatterns, isTrue);
    });

    test('has value equality', () {
      expect(
        const VibrationCapabilities(hasVibrator: true),
        const VibrationCapabilities(hasVibrator: true),
      );
      expect(
        const VibrationCapabilities(hasVibrator: true),
        isNot(const VibrationCapabilities(hasVibrator: false)),
      );
      expect(
        VibrationCapabilities.unknown,
        isNot(const VibrationCapabilities(hasVibrator: true)),
      );
    });
  });

  group('detectVibrationCapabilities', () {
    test('reports what the probe answers', () async {
      final caps = await detectVibrationCapabilities(
        FakeVibrationCapabilityProbe(amplitudeControl: false),
      );
      expect(
        caps,
        const VibrationCapabilities(
          hasVibrator: true,
          hasAmplitudeControl: false,
          hasCustomVibrationsSupport: true,
        ),
      );
    });

    test('null answers become unknown', () async {
      final caps = await detectVibrationCapabilities(
        FakeVibrationCapabilityProbe(
          vibrator: null,
          amplitudeControl: null,
          customVibrations: null,
        ),
      );
      expect(caps, VibrationCapabilities.unknown);
    });

    for (final error in <Object>[
      MissingPluginException('No implementation found'),
      PlatformException(code: 'error'),
      UnimplementedError(),
      StateError('boom'),
    ]) {
      test('${error.runtimeType} degrades to unknown', () async {
        final caps = await detectVibrationCapabilities(
          FakeVibrationCapabilityProbe(error: error),
        );
        expect(caps, VibrationCapabilities.unknown);
        expect(caps.canVibrate, isTrue);
        expect(caps.canControlAmplitude, isTrue);
        expect(caps.canPlayCustomPatterns, isTrue);
      });
    }

    test('a synchronous throw degrades to unknown', () async {
      final caps = await detectVibrationCapabilities(_SyncThrowingProbe());
      expect(caps, VibrationCapabilities.unknown);
    });
  });

  group('vibrationCapabilitiesProvider', () {
    test('resolves to unknown instead of failing when queries throw', () async {
      final container = _containerWith(
        FakeVibrationCapabilityProbe(error: MissingPluginException()),
      );

      final caps = await container.read(vibrationCapabilitiesProvider.future);

      expect(caps, VibrationCapabilities.unknown);
      expect(
        container.read(vibrationCapabilitiesProvider),
        isA<AsyncData<VibrationCapabilities>>(),
      );
    });

    test('queries the device only once', () async {
      final probe = FakeVibrationCapabilityProbe(vibrator: false);
      final container = _containerWith(probe);

      await container.read(vibrationCapabilitiesProvider.future);
      await container.read(vibrationCapabilitiesProvider.future);
      container.read(effectiveVibrationCapabilitiesProvider);

      expect(probe.queryCount, 3);
    });

    test('is unknown on the test host without any override', () async {
      // Widget tests that don't override the probe must keep working: the
      // device probe only asks the plugin on Android and iOS.
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final caps = await container.read(vibrationCapabilitiesProvider.future);

      expect(caps, VibrationCapabilities.unknown);
    });
  });

  group('effectiveVibrationCapabilitiesProvider', () {
    test('is unknown while detection runs, then the result', () async {
      final gate = Completer<void>();
      final container = _containerWith(
        FakeVibrationCapabilityProbe(vibrator: false, gate: gate),
      );
      final sub = container.listen(
        effectiveVibrationCapabilitiesProvider,
        (_, _) {},
      );
      addTearDown(sub.close);

      expect(sub.read(), VibrationCapabilities.unknown);

      gate.complete();
      await container.read(vibrationCapabilitiesProvider.future);

      expect(sub.read().hasVibrator, isFalse);
      expect(sub.read().canVibrate, isFalse);
    });
  });

  group('vibrationServiceProvider', () {
    test('is not rebuilt when detection completes', () async {
      final gate = Completer<void>();
      final container = _containerWith(
        FakeVibrationCapabilityProbe(amplitudeControl: false, gate: gate),
      );
      final sub = container.listen(vibrationServiceProvider, (_, _) {});
      addTearDown(sub.close);
      final before = sub.read();

      gate.complete();
      await container.read(vibrationCapabilitiesProvider.future);

      expect(sub.read(), same(before));
      expect(before, isA<DeviceVibrationService>());
    });
  });
}
