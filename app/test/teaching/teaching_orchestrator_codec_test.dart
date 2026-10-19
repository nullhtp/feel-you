import 'package:feel_you/gestures/gesture_event.dart';
import 'package:feel_you/gestures/gesture_providers.dart';
import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/session/session_notifier.dart';
import 'package:feel_you/tactile/tactile.dart';
import 'package:feel_you/teaching/teaching_orchestrator.dart';
import 'package:feel_you/teaching/teaching_providers.dart';
import 'package:feel_you/teaching/teaching_timing_config.dart';
import 'package:feel_you/vibration/vibration_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart' hide test;

import '../test_doubles/fake_gesture_classifier.dart';
import '../test_doubles/fake_shake_detector.dart';
import '../test_doubles/fake_time.dart';
import '../test_doubles/mock_vibration_service.dart';

// The tests run in fake time: `test` is the one from fake_time.dart. The
// loop's pauses and a test's waits then always end in the same order.

const _config = TeachingTimingConfig(
  repeatPause: Duration(milliseconds: 10),
  postFeedbackPause: Duration(milliseconds: 5),
  spellingLetterGap: Duration(milliseconds: 5),
  quizMarkerGap: Duration(milliseconds: 5),
);

/// A codec unlike Morse: every character is two short pulses, and `?` is
/// one long pulse. Records the texts it is asked to encode.
class _TwoDotsCodec implements TactileCodec {
  final List<String> encoded = [];

  @override
  List<TactileToken> encode(String text) {
    encoded.add(text);
    return [
      for (var i = 0; i < text.length; i++) ...[
        if (i > 0) TactileToken.characterGap,
        if (text[i] == '?')
          TactileToken.longPulse
        else ...[
          TactileToken.shortPulse,
          TactileToken.shortPulse,
        ],
      ],
    ];
  }

  @override
  String describe(String text) => 'two dots';
}

/// The fake codec's tokens for one character, as the mock records them.
const _twoDots = [MorseSignal.dot, MorseSignal.dot];

/// An orchestrator on [session] that encodes with [codec] and records the
/// languages it asks a codec for.
class _Harness {
  _Harness(this.session) {
    orchestrator = TeachingOrchestrator(
      gestureClassifier: gestures,
      vibrationService: vibration,
      sessionNotifier: session,
      config: _config,
      codecFor: (language) {
        languages.add(language);
        return codec;
      },
    );
  }

  final SessionNotifier session;
  final gestures = FakeGestureClassifier();
  final vibration = MockVibrationService();
  final codec = _TwoDotsCodec();
  final languages = <MorseLanguage>[];
  late final TeachingOrchestrator orchestrator;

  Future<void> tearDown() async {
    await orchestrator.stop();
    await _settle();
    orchestrator.dispose();
    gestures.dispose();
  }
}

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 30));

SessionNotifier _wordsLevel() => SessionNotifier(MorseLanguage.english)
  ..nextLevel()
  ..nextLevel();

void main() {
  group('the teaching loop plays what the codec encodes', () {
    test("on a characters level, the codec's tokens for the item", () async {
      final t = _Harness(SessionNotifier(MorseLanguage.english));
      addTearDown(t.tearDown);

      t.orchestrator.start();
      await _settle();

      expect(t.codec.encoded, everyElement('0'));
      // Two dots, not Morse 0 (five dashes), on every repetition.
      expect(t.vibration.patterns, hasLength(greaterThan(1)));
      expect(t.vibration.patterns, everyElement(_twoDots));
    });

    test("on a words level, the spelling splits the codec's tokens at its "
        'character gaps', () async {
      final t = _Harness(_wordsLevel());
      addTearDown(t.tearDown);
      expect(t.session.state.currentCharacter, 'HI');

      t.orchestrator.start();
      await _settle();

      final calls = t.vibration.calls;
      expect(calls[0].signals, _twoDots); // H
      expect(calls[1].signals, _twoDots); // I
      expect(calls[2].type, VibrationCallType.playMorseTokenPattern);
      expect(calls[2].tokens, const [
        Signal(MorseSignal.dot),
        Signal(MorseSignal.dot),
        CharGap(),
        Signal(MorseSignal.dot),
        Signal(MorseSignal.dot),
      ]);
      expect(t.codec.encoded, everyElement('HI'));
    });

    test("the quiz is announced with the codec's question mark", () async {
      final session = SessionNotifier(MorseLanguage.english);
      for (var i = 0; i < 10; i++) {
        session.nextPosition();
      }
      expect(session.state.isInQuiz, isTrue);
      final t = _Harness(session);
      addTearDown(t.tearDown);

      t.orchestrator.start();
      await _settle();

      expect(t.codec.encoded.first, TeachingOrchestrator.quizMarker);
      expect(t.vibration.patterns.first, [MorseSignal.dash]);
      expect(t.vibration.patterns[1], _twoDots); // the quiz item
    });

    /// Answers [input] on digit 0 while the codec plays two dots, and
    /// returns the vibration calls.
    Future<List<String>> answer(List<MorseToken> input) async {
      final t = _Harness(SessionNotifier(MorseLanguage.english));
      addTearDown(t.tearDown);
      t.orchestrator.start();
      await _settle();

      t.gestures
        ..addEvent(const MorseInput(MorseSignal.dash))
        ..addEvent(InputComplete(input));
      await _settle();
      return t.vibration.callLog;
    }

    test("an answer is right when it matches the level's Morse pattern, "
        "not the codec's tokens", () async {
      // Morse 0: five dashes.
      final calls = await answer(
        List.filled(5, const Signal(MorseSignal.dash)),
      );
      expect(calls, contains('playSuccess'));
      expect(calls, isNot(contains('playError')));
    });

    test("echoing the codec's tokens is wrong when they are not the level's "
        'Morse pattern', () async {
      final calls = await answer([for (final s in _twoDots) Signal(s)]);
      expect(calls, contains('playError'));
      expect(calls, isNot(contains('playSuccess')));
    });

    test("asks for the codec of the session's current language", () async {
      final t = _Harness(SessionNotifier(MorseLanguage.english));
      addTearDown(t.tearDown);

      t.orchestrator.start();
      await _settle();
      await t.orchestrator.stop();
      t.session.selectLanguage(MorseLanguage.russian);
      t.orchestrator.start();
      await _settle();

      expect(t.languages.first, MorseLanguage.english);
      expect(t.languages.last, MorseLanguage.russian);
    });

    test('defaults to the Morse codec', () async {
      final gestures = FakeGestureClassifier();
      final vibration = MockVibrationService();
      final orchestrator = TeachingOrchestrator(
        gestureClassifier: gestures,
        vibrationService: vibration,
        sessionNotifier: SessionNotifier(MorseLanguage.english),
        config: _config,
      );
      addTearDown(() async {
        await orchestrator.stop();
        await _settle();
        orchestrator.dispose();
        gestures.dispose();
      });

      orchestrator.start();
      await _settle();

      expect(
        vibration.patterns.first,
        encodeLetter('0', MorseLanguage.english),
      );
    });
  });

  group('teachingOrchestratorProvider', () {
    test('plays with the codec from tactileCodecProvider', () async {
      final vibration = MockVibrationService();
      final codec = _TwoDotsCodec();
      final container = ProviderContainer(
        overrides: [
          vibrationServiceProvider.overrideWithValue(vibration),
          screenWidthProvider.overrideWithValue(800),
          shakeDetectorProvider.overrideWithValue(FakeShakeDetector()),
          teachingTimingConfigProvider.overrideWithValue(_config),
          tactileCodecProvider(MorseLanguage.english).overrideWithValue(codec),
        ],
      );
      final orchestrator = container.read(
        teachingOrchestratorProvider.notifier,
      );
      addTearDown(() async {
        await orchestrator.stop();
        await _settle();
        container.dispose();
      });

      orchestrator.start();
      await _settle();

      expect(codec.encoded, contains('0'));
      expect(vibration.patterns.first, _twoDots);
    });
  });
}
