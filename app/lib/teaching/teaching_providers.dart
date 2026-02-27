import 'package:feel_you/gestures/gesture_providers.dart';
import 'package:feel_you/session/session_providers.dart';
import 'package:feel_you/teaching/teaching_orchestrator.dart';
import 'package:feel_you/teaching/teaching_timing_config.dart';
import 'package:feel_you/vibration/vibration_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the [TeachingTimingConfig] used by the teaching loop.
///
/// Override this provider in tests or to tune timing values.
final teachingTimingConfigProvider = Provider<TeachingTimingConfig>(
  (ref) => const TeachingTimingConfig(),
);

/// Provides the [TeachingOrchestrator] that drives the learning loop.
///
/// Depends on the gesture classifier, vibration service, session notifier,
/// and timing config. Disposes the orchestrator when the provider is disposed.
final teachingOrchestratorProvider =
    StateNotifierProvider<TeachingOrchestrator, TeachingOrchestratorState>((
      ref,
    ) {
      final gestureClassifier = ref.watch(gestureClassifierProvider);
      final vibrationService = ref.watch(vibrationServiceProvider);
      final sessionNotifier = ref.watch(sessionNotifierProvider.notifier);
      final config = ref.watch(teachingTimingConfigProvider);

      final orchestrator = TeachingOrchestrator(
        gestureClassifier: gestureClassifier,
        vibrationService: vibrationService,
        sessionNotifier: sessionNotifier,
        config: config,
      );

      // Note: StateNotifierProvider automatically calls dispose() on the
      // notifier when the provider is disposed. No need for ref.onDispose.

      return orchestrator;
    });
