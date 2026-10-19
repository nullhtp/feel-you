import 'package:feel_you/gestures/gesture_event.dart';
import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/session/session_notifier.dart';
import 'package:feel_you/teaching/teaching_orchestrator.dart';
import 'package:feel_you/teaching/teaching_timing_config.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_doubles/fake_gesture_classifier.dart';
import '../test_doubles/fake_shake_detector.dart';
import '../test_doubles/mock_vibration_service.dart';

// A double shake (ChangeLanguage) is acted on by TouchSurface, which stops
// the loop and opens the home menu. The orchestrator itself must not treat
// it as navigation.

/// Long enough that the loop never repeats during a test.
const _repeatPause = Duration(seconds: 5);

/// Lets stream events run.
Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late FakeGestureClassifier classifier;
  late FakeShakeDetector shake;
  late MockVibrationService vibration;
  late SessionNotifier session;
  late TeachingOrchestrator orchestrator;

  setUp(() {
    classifier = FakeGestureClassifier();
    shake = FakeShakeDetector();
    vibration = MockVibrationService();
    session = SessionNotifier(MorseLanguage.russian)
      ..nextLevel()
      ..nextPosition();
    orchestrator = TeachingOrchestrator(
      gestureClassifier: classifier,
      vibrationService: vibration,
      sessionNotifier: session,
      shakeDetector: shake,
      config: const TeachingTimingConfig(repeatPause: _repeatPause),
    );
  });

  tearDown(() async {
    await orchestrator.stop();
    orchestrator.dispose();
    classifier.dispose();
    shake.dispose();
  });

  test('ChangeLanguage neither navigates nor restarts the loop', () async {
    orchestrator.start();
    await _settle();
    final before = session.state;
    vibration.reset();

    shake.addEvent(const ChangeLanguage());
    await _settle();

    expect(session.state, before);
    expect(session.state.language, MorseLanguage.russian);
    expect(orchestrator.state.isRunning, isTrue);
    expect(vibration.calls, isEmpty);
  });

  test('ChangeLanguage is ignored while the loop is stopped', () async {
    final before = session.state;

    shake.addEvent(const ChangeLanguage());
    await _settle();

    expect(session.state, before);
    expect(orchestrator.state.isRunning, isFalse);
    expect(vibration.calls, isEmpty);
  });
}
