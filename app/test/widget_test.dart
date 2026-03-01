import 'package:feel_you/app.dart';
import 'package:feel_you/gestures/gesture_providers.dart';
import 'package:feel_you/teaching/teaching_providers.dart';
import 'package:feel_you/teaching/teaching_timing_config.dart';
import 'package:feel_you/ui/language_picker_surface.dart';
import 'package:feel_you/vibration/vibration_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_doubles/fake_gesture_classifier.dart';
import 'test_doubles/mock_vibration_service.dart';

const _testRepeatPause = Duration(seconds: 5);

void main() {
  testWidgets('App renders LanguagePickerSurface as home', (tester) async {
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

    expect(find.byType(LanguagePickerSurface), findsOneWidget);

    // Clean up: remove widget tree, flush timers.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(_testRepeatPause);

    classifier.dispose();
  });
}
