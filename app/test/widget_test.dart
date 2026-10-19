import 'package:feel_you/app.dart';
import 'package:feel_you/gestures/gesture_providers.dart';
import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/settings/language_preference.dart';
import 'package:feel_you/teaching/teaching_providers.dart';
import 'package:feel_you/teaching/teaching_timing_config.dart';
import 'package:feel_you/ui/home_menu_surface.dart';
import 'package:feel_you/ui/language_picker_surface.dart';
import 'package:feel_you/vibration/vibration_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_doubles/fake_gesture_classifier.dart';
import 'test_doubles/fake_shake_detector.dart';
import 'test_doubles/mock_vibration_service.dart';

const _testRepeatPause = Duration(seconds: 5);

/// The app with test doubles, with [saved] as the saved language.
Widget _app(FakeGestureClassifier classifier, {MorseLanguage? saved}) =>
    ProviderScope(
      overrides: [
        languagePreferenceStoreProvider.overrideWithValue(
          InMemoryLanguagePreferenceStore(saved),
        ),
        gestureClassifierProvider.overrideWithValue(classifier),
        vibrationServiceProvider.overrideWithValue(MockVibrationService()),
        shakeDetectorProvider.overrideWithValue(FakeShakeDetector()),
        teachingTimingConfigProvider.overrideWithValue(
          const TeachingTimingConfig(repeatPause: _testRepeatPause),
        ),
      ],
      child: const FeelYouApp(),
    );

void main() {
  testWidgets('App renders LanguagePickerSurface as home', (tester) async {
    final classifier = FakeGestureClassifier();
    await tester.pumpWidget(_app(classifier));

    expect(find.byType(LanguagePickerSurface), findsOneWidget);

    // Clean up: remove widget tree, flush timers.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(_testRepeatPause);

    classifier.dispose();
  });

  testWidgets('App renders HomeMenuSurface once a language is saved', (
    tester,
  ) async {
    final classifier = FakeGestureClassifier();
    await tester.pumpWidget(_app(classifier, saved: MorseLanguage.english));

    expect(find.byType(HomeMenuSurface), findsOneWidget);
    expect(find.byType(LanguagePickerSurface), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(_testRepeatPause);

    classifier.dispose();
  });
}
