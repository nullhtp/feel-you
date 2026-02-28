import 'package:feel_you/gestures/gesture_providers.dart';
import 'package:feel_you/teaching/teaching_orchestrator.dart';
import 'package:feel_you/teaching/teaching_providers.dart';
import 'package:feel_you/teaching/teaching_timing_config.dart';
import 'package:feel_you/vibration/vibration_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_doubles/fake_shake_detector.dart';
import '../test_doubles/mock_vibration_service.dart';

void main() {
  group('teachingTimingConfigProvider', () {
    test('provides default config', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final config = container.read(teachingTimingConfigProvider);
      expect(config.repeatPause, const Duration(milliseconds: 3000));
    });

    test('can be overridden', () {
      const custom = TeachingTimingConfig(
        repeatPause: Duration(milliseconds: 5000),
      );
      final container = ProviderContainer(
        overrides: [teachingTimingConfigProvider.overrideWithValue(custom)],
      );
      addTearDown(container.dispose);

      final config = container.read(teachingTimingConfigProvider);
      expect(config.repeatPause, const Duration(milliseconds: 5000));
    });
  });

  group('teachingOrchestratorProvider', () {
    test('creates orchestrator with correct dependencies', () {
      final container = ProviderContainer(
        overrides: [
          vibrationServiceProvider.overrideWithValue(MockVibrationService()),
          screenWidthProvider.overrideWithValue(800),
          shakeDetectorProvider.overrideWithValue(FakeShakeDetector()),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(teachingOrchestratorProvider);
      expect(state, isA<TeachingOrchestratorState>());
      expect(state.isRunning, false);
      expect(state.isInterrupted, false);
    });

    test('disposes orchestrator on container disposal', () async {
      // Create, read (to instantiate the provider), then dispose.
      ProviderContainer(
          overrides: [
            vibrationServiceProvider.overrideWithValue(MockVibrationService()),
            screenWidthProvider.overrideWithValue(800),
            shakeDetectorProvider.overrideWithValue(FakeShakeDetector()),
          ],
        )
        ..read(teachingOrchestratorProvider)
        ..dispose();

      // Let any pending microtasks drain.
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // If we get here without throwing, dispose succeeded.
    });
  });
}
