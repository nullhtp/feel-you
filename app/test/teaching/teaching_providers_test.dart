import 'package:feel_you/gestures/gesture_providers.dart';
import 'package:feel_you/morse/morse_symbol.dart';
import 'package:feel_you/teaching/teaching_orchestrator.dart';
import 'package:feel_you/teaching/teaching_providers.dart';
import 'package:feel_you/teaching/teaching_timing_config.dart';
import 'package:feel_you/vibration/vibration_providers.dart';
import 'package:feel_you/vibration/vibration_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mock vibration service for provider tests.
class _MockVibrationService implements VibrationService {
  @override
  Future<void> playMorsePattern(List<MorseSymbol> symbols) async {}
  @override
  Future<void> playSuccess() async {}
  @override
  Future<void> playError() async {}
  @override
  Future<void> cancel() async {}
}

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
          vibrationServiceProvider.overrideWithValue(_MockVibrationService()),
          screenWidthProvider.overrideWithValue(800),
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
            vibrationServiceProvider.overrideWithValue(_MockVibrationService()),
            screenWidthProvider.overrideWithValue(800),
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
