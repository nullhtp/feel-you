import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/session/session.dart';
import 'package:feel_you/vibration/vibration.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'e2e_helpers.dart';
import 'test_helpers.dart';

// Tap feedback and the success and error signals end to end
// (`bottom-input-zone`, `vibration-engine`). The app runs with its own
// DeviceVibrationService and capability probe; the test answers the motor
// questions and records what reaches the `vibration` plugin's channel.

/// A motor, and the signals the app must send to it.
class _Motor {
  const _Motor({
    required this.name,
    required this.hasAmplitudeControl,
    required this.success,
    required this.successIntensities,
    required this.error,
    required this.errorIntensities,
  });

  final String name;
  final bool hasAmplitudeControl;
  final List<int> success;
  final List<int> successIntensities;
  final List<int> error;
  final List<int> errorIntensities;
}

/// The timings of `vibration-engine`, written out rather than taken from
/// the app's constants, so the test pins the spec.
const _motors = [
  _Motor(
    name: 'with amplitude control',
    hasAmplitudeControl: true,
    success: [50, 40, 50, 40, 50, 40, 50, 40, 50],
    successIntensities: [255, 0, 255, 0, 255, 0, 255, 0, 255],
    error: [500],
    errorIntensities: [255],
  ),
  _Motor(
    name: 'without amplitude control',
    hasAmplitudeControl: false,
    success: [0, 50, 60, 50, 60, 50, 60, 50, 60, 50],
    successIntensities: [0, 255, 0, 255, 0, 255, 0, 255, 0, 255],
    error: [0, 700],
    errorIntensities: [0, 255],
  ),
];

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// What digit "0" is sent as with the test's Morse timing.
  final zeroSegments = buildMorseVibrationPatternFromSignals(
    digitZero,
    fastMorseTimingConfig,
  );

  late FakeVibrationPlatform platform;
  late E2EApp app;

  /// Launches an English lesson on a motor with or without amplitude
  /// control, and waits until digit "0" has reached the plugin.
  Future<void> launchLesson(
    WidgetTester tester, {
    bool hasAmplitudeControl = true,
  }) async {
    platform = FakeVibrationPlatform(hasAmplitudeControl: hasAmplitudeControl)
      ..install(tester);
    app = E2EApp(savedLanguage: MorseLanguage.english);
    await app.launch(tester);
    await waitUntil(
      tester,
      () => app.container(tester).read(vibrationCapabilitiesProvider).hasValue,
      reason: 'detection ends',
    );
    await waitUntil(
      tester,
      () => platform.indexOfPattern(zeroSegments) >= 0,
      reason: 'the loop plays digit 0',
    );
  }

  /// Taps [signals] on the lesson surface, then the bottom strip.
  Future<void> answer(WidgetTester tester, List<MorseSignal> signals) async {
    for (final signal in signals) {
      await tapAt(
        tester,
        signal == MorseSignal.dot ? dotPoint(tester) : dashPoint(tester),
      );
    }
    await tapAt(tester, bottomStripPoint(tester));
  }

  for (final motor in _motors) {
    testWidgets('on a motor ${motor.name}, the tap feedback comes before the '
        'success and error signals of the right shape', (tester) async {
      await launchLesson(
        tester,
        hasAmplitudeControl: motor.hasAmplitudeControl,
      );

      // Correct: five dashes for "0", then the bottom strip.
      await answer(tester, digitZero);
      await waitUntil(
        tester,
        () => platform.indexOfPattern(motor.success) >= 0,
        reason: 'the success signal is sent',
      );
      final success = platform.indexOfPattern(motor.success);
      expect(platform.intensities[success], motor.successIntensities);
      // The 50 ms tap feedback, and nothing else, right before it.
      expect(platform.tapFeedbackIndexes, [success - 1]);

      // Wrong: a dot, then the bottom strip, once the loop is back.
      await waitUntil(
        tester,
        () => app.session(tester).phase == SessionPhase.playing,
        reason: 'the loop resumes after the success signal',
      );
      await answer(tester, const [MorseSignal.dot]);
      await waitUntil(
        tester,
        () => platform.indexOfPattern(motor.error) >= 0,
        reason: 'the error signal is sent',
      );
      final error = platform.indexOfPattern(motor.error);
      expect(platform.intensities[error], motor.errorIntensities);
      expect(platform.tapFeedbackIndexes, [success - 1, error - 1]);

      await app.close(tester);
    });
  }

  testWidgets('a bottom-strip tap while the item plays sends no tap feedback '
      'and the item keeps repeating', (tester) async {
    await launchLesson(tester);

    await tapAt(tester, bottomStripPoint(tester));
    final afterTap = platform.vibrateCalls.length;
    await waitFor(tester, e2eTeachingConfig.repeatPause * 3);

    expect(platform.tapFeedbackIndexes, isEmpty);
    expect(app.session(tester).phase, SessionPhase.playing);
    expect(app.inputBuffer(tester), isEmpty);
    // "0" was sent again after the tap.
    expect(platform.indexOfPattern(zeroSegments, start: afterTap), isNot(-1));

    await app.close(tester);
  });
}
