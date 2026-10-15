import 'package:feel_you/gestures/gesture_providers.dart';
import 'package:feel_you/teaching/teaching_providers.dart';
import 'package:feel_you/vibration/vibration_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_doubles/fake_shake_detector.dart';
import '../test_doubles/mock_vibration_service.dart';

void main() {
  group('screenWidthProvider', () {
    test('has a default and no longer has to be overridden', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(screenWidthProvider), isA<double>());
      expect(() => container.read(gestureClassifierProvider), returnsNormally);
    });
  });

  group('gestureClassifierProvider', () {
    test('seeds the classifier with the initial screen width', () {
      final container = ProviderContainer(
        overrides: [screenWidthProvider.overrideWithValue(800)],
      );
      addTearDown(container.dispose);

      expect(container.read(gestureClassifierProvider).screenWidth, 800);
    });

    test('a screen width change never recreates the classifier or the '
        'orchestrator subscribed to it', () {
      var initialWidth = 800.0;
      final container = ProviderContainer(
        overrides: [
          screenWidthProvider.overrideWith((ref) => initialWidth),
          vibrationServiceProvider.overrideWithValue(MockVibrationService()),
          shakeDetectorProvider.overrideWithValue(FakeShakeDetector()),
        ],
      );
      addTearDown(container.dispose);

      final classifier = container.read(gestureClassifierProvider);
      final inputBuffer = container.read(inputBufferProvider);
      final orchestrator = container.read(
        teachingOrchestratorProvider.notifier,
      );

      // Live width updates go through the classifier itself.
      classifier.screenWidth = 500;

      // Even if the seed provider changes, the classifier is not rebuilt.
      initialWidth = 1200;
      container.invalidate(screenWidthProvider);
      expect(container.read(screenWidthProvider), 1200);

      expect(container.read(gestureClassifierProvider), same(classifier));
      expect(container.read(inputBufferProvider), same(inputBuffer));
      expect(
        container.read(teachingOrchestratorProvider.notifier),
        same(orchestrator),
      );
      expect(classifier.screenWidth, 500);
    });
  });
}
