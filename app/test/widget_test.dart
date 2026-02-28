import 'package:feel_you/app.dart';
import 'package:feel_you/gestures/gesture_providers.dart';
import 'package:feel_you/teaching/teaching_providers.dart';
import 'package:feel_you/teaching/teaching_timing_config.dart';
import 'package:feel_you/ui/touch_surface.dart';
import 'package:feel_you/vibration/vibration_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_doubles/fake_gesture_classifier.dart';
import 'test_doubles/mock_vibration_service.dart';

const _testRepeatPause = Duration(seconds: 5);

void main() {
  testWidgets('App renders TouchSurface as home', (tester) async {
    final classifier = FakeGestureClassifier();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gestureClassifierProvider.overrideWithValue(classifier),
          vibrationServiceProvider.overrideWithValue(MockVibrationService()),
          teachingTimingConfigProvider.overrideWithValue(
            const TeachingTimingConfig(repeatPause: _testRepeatPause),
          ),
        ],
        child: const FeelYouApp(),
      ),
    );

    expect(find.byType(TouchSurface), findsOneWidget);

    // Clean up: stop orchestrator, remove widget tree, flush timers.
    final element = tester.element(find.byType(TouchSurface));
    final container = ProviderScope.containerOf(element);
    await container.read(teachingOrchestratorProvider.notifier).stop();
    await tester.pumpWidget(const SizedBox());
    await tester.pump(_testRepeatPause);

    classifier.dispose();
  });
}
