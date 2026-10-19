import 'package:feel_you/gestures/gesture_providers.dart';
import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/session/session.dart';
import 'package:feel_you/settings/language_preference.dart';
import 'package:feel_you/tactile/tactile.dart';
import 'package:feel_you/teaching/teaching_providers.dart';
import 'package:feel_you/teaching/teaching_timing_config.dart';
import 'package:feel_you/ui/companion_overlay.dart';
import 'package:feel_you/ui/language_picker_surface.dart';
import 'package:feel_you/ui/vibration_gate.dart';
import 'package:feel_you/vibration/vibration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_doubles/fake_gesture_classifier.dart';
import '../test_doubles/fake_shake_detector.dart';
import '../test_doubles/fake_vibration_capability_probe.dart';
import '../test_doubles/mock_vibration_service.dart';

/// A codec unlike Morse: every text is three long pulses, described as
/// `codec:<text>`. Records the texts it is asked to encode.
class _ThreeDashesCodec implements TactileCodec {
  final List<String> encoded = [];

  @override
  List<TactileToken> encode(String text) {
    encoded.add(text);
    return const [
      TactileToken.longPulse,
      TactileToken.longPulse,
      TactileToken.longPulse,
    ];
  }

  @override
  String describe(String text) => 'codec:$text';

  // No screen plays or shows a prosign yet (`morse-prosigns`): asking for
  // one fails the test.
  @override
  List<TactileToken> encodeProsign(Prosign prosign) =>
      throw UnimplementedError('$prosign');

  @override
  String describeProsign(Prosign prosign) =>
      throw UnimplementedError('$prosign');
}

/// The fake codec's tokens, as the mock records them.
const _threeDashes = [MorseSignal.dash, MorseSignal.dash, MorseSignal.dash];

/// A [SessionNotifier] that starts with a custom initial state.
class _PresetSessionNotifier extends SessionNotifier {
  _PresetSessionNotifier(SessionState initial) : super(initial.language) {
    state = initial;
  }
}

void main() {
  group('CompanionOverlay pattern line', () {
    Widget overlay(
      FakeGestureClassifier classifier, {
      required SessionState state,
      TactileCodec? codec,
    }) => ProviderScope(
      overrides: [
        gestureClassifierProvider.overrideWithValue(classifier),
        sessionNotifierProvider.overrideWith(
          (ref) => _PresetSessionNotifier(state),
        ),
        if (codec != null)
          tactileCodecProvider(state.language).overrideWithValue(codec),
      ],
      child: const MaterialApp(home: CompanionOverlay()),
    );

    testWidgets("shows the session language codec's description", (
      tester,
    ) async {
      final classifier = FakeGestureClassifier();
      addTearDown(classifier.dispose);

      await tester.pumpWidget(
        overlay(
          classifier,
          state: const SessionState(
            language: MorseLanguage.arabic,
            levelIndex: 1,
          ),
          codec: _ThreeDashesCodec(),
        ),
      );

      expect(find.text('ا'), findsOneWidget);
      expect(find.text('codec:ا'), findsOneWidget);
      // Not the level's Morse pattern.
      expect(find.text('· —'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets("shows the Morse codec's notation by default, with letter "
        'gaps on words', (tester) async {
      final classifier = FakeGestureClassifier();
      addTearDown(classifier.dispose);

      await tester.pumpWidget(
        overlay(
          classifier,
          state: const SessionState(
            language: MorseLanguage.russian,
            levelIndex: 2,
          ),
        ),
      );

      // ДА: Д (−··) / А (·−).
      expect(find.text('ДА'), findsOneWidget);
      expect(find.text('— · · / · —'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('hides the description in the quiz until the feedback', (
      tester,
    ) async {
      final classifier = FakeGestureClassifier();
      addTearDown(classifier.dispose);
      const quiz = SessionState(
        language: MorseLanguage.english,
        positionIndex: 9,
        quizItem: '4',
      );

      await tester.pumpWidget(
        overlay(classifier, state: quiz, codec: _ThreeDashesCodec()),
      );
      expect(find.text('codec:4'), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        overlay(
          classifier,
          state: quiz.copyWith(phase: SessionPhase.feedback),
          codec: _ThreeDashesCodec(),
        ),
      );
      expect(find.text('codec:4'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('LanguagePickerSurface identifiers', () {
    testWidgets("are encoded with each language's codec", (tester) async {
      final classifier = FakeGestureClassifier();
      final shake = FakeShakeDetector();
      final vibration = MockVibrationService();
      final arabic = _ThreeDashesCodec();
      addTearDown(() {
        classifier.dispose();
        shake.dispose();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            languagePreferenceStoreProvider.overrideWithValue(
              InMemoryLanguagePreferenceStore(),
            ),
            gestureClassifierProvider.overrideWithValue(classifier),
            vibrationServiceProvider.overrideWithValue(vibration),
            shakeDetectorProvider.overrideWithValue(shake),
            teachingTimingConfigProvider.overrideWithValue(
              const TeachingTimingConfig(repeatPause: Duration(seconds: 5)),
            ),
            vibrationCapabilityProbeProvider.overrideWithValue(
              FakeVibrationCapabilityProbe(),
            ),
            tactileCodecProvider(
              MorseLanguage.arabic,
            ).overrideWithValue(arabic),
          ],
          child: MaterialApp(
            builder: (_, navigator) => VibrationGate(child: navigator!),
            home: const LanguagePickerSurface(),
          ),
        ),
      );
      await tester.pump();

      // English is highlighted first: Morse E from the Morse codec.
      expect(vibration.patterns.single, [MorseSignal.dot]);

      await tester.tap(find.text('العربية'));
      await tester.pump();
      expect(arabic.encoded, ['ع']);
      expect(vibration.patterns.last, _threeDashes);

      await tester.tap(find.text('Русский'));
      await tester.pump();
      // Р from the Morse codec.
      expect(vibration.patterns.last, [
        MorseSignal.dot,
        MorseSignal.dash,
        MorseSignal.dot,
      ]);

      await tester.pumpWidget(const SizedBox());
    });
  });
}
