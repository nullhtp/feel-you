import 'package:feel_you/gestures/gesture_event.dart';
import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/session/session.dart';
import 'package:feel_you/teaching/teaching_orchestrator.dart';
import 'package:feel_you/teaching/teaching_timing_config.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_doubles/fake_gesture_classifier.dart';
import '../test_doubles/mock_vibration_service.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Pause between pattern repetitions. Short to keep the tests fast.
const _repeatPause = Duration(milliseconds: 10);

/// Pause between feedback and the loop resuming.
const _postFeedbackPause = Duration(milliseconds: 20);

/// Silence between spelled letters, for tests that only need the order.
const _shortLetterGap = Duration(milliseconds: 10);

/// Silence between spelled letters, for tests that act inside a gap. Much
/// longer than the steps of a test.
const _longLetterGap = Duration(milliseconds: 300);

/// Long enough for the loop to have started and played once.
const _loopStarted = Duration(milliseconds: 20);

/// Long enough for a word spelled with [_shortLetterGap] to have been
/// spelled and drilled several times.
const _severalRepeatCycles = Duration(milliseconds: 150);

/// Well past a [_longLetterGap].
const _afterLongGap = Duration(milliseconds: 400);

/// Lets stream events and short loop iterations run.
Future<void> settle([Duration duration = Duration.zero]) =>
    Future<void>.delayed(duration);

/// The signals of an English letter.
List<MorseSignal> _letter(String letter) => englishAlphabet.characters[letter]!;

/// The token pattern of an English word, as the drill loop plays it.
List<MorseToken> _word(String word) => englishAlphabet.wordPatterns![word]!;

/// An orchestrator on the English levels, wired to test doubles.
class _Harness {
  _Harness(
    this.session, {
    Duration spellingLetterGap = _shortLetterGap,
    Duration repeatPause = _repeatPause,
  }) {
    orchestrator = TeachingOrchestrator(
      gestureClassifier: gestures,
      vibrationService: vibration,
      sessionNotifier: session,
      config: TeachingTimingConfig(
        repeatPause: repeatPause,
        postFeedbackPause: _postFeedbackPause,
        spellingLetterGap: spellingLetterGap,
      ),
    );
  }

  /// A harness on the words level, at the word at [position].
  factory _Harness.word({
    int position = 0,
    Duration spellingLetterGap = _shortLetterGap,
    Duration repeatPause = _repeatPause,
  }) {
    final session = SessionNotifier(MorseLanguage.english)
      ..nextLevel()
      ..nextLevel();
    for (var i = 0; i < position; i++) {
      session.nextPosition();
    }
    expect(session.state.currentLevel.kind, LevelKind.words);
    return _Harness(
      session,
      spellingLetterGap: spellingLetterGap,
      repeatPause: repeatPause,
    );
  }

  final SessionNotifier session;
  final gestures = FakeGestureClassifier();
  final vibration = MockVibrationService();
  late final TeachingOrchestrator orchestrator;

  SessionPhase get phase => session.state.phase;

  /// The patterns played since the vibration calls were last reset, in
  /// order: a spelled letter (or a character) as its signals, a drilled word
  /// as its tokens.
  List<Object> get played => _patterns(vibration.calls);

  /// The patterns played since the last `cancel`, as in [played].
  ///
  /// Navigation cancels the vibration and starts the new loop at once, so
  /// these are the new loop's. Resetting the calls before the navigation
  /// is not enough: the stream may deliver the navigation event only after
  /// a pause of the old loop has ended, which then plays once more.
  List<Object> get playedSinceCancel {
    final calls = vibration.calls;
    final lastCancel = calls.lastIndexWhere(
      (c) => c.type == VibrationCallType.cancel,
    );
    expect(lastCancel, isNot(-1), reason: 'no cancel');
    return _patterns(calls.skip(lastCancel + 1));
  }

  static List<Object> _patterns(Iterable<VibrationCall> calls) => [
    for (final call in calls)
      if (call.type == VibrationCallType.playMorsePattern)
        call.signals!
      else if (call.type == VibrationCallType.playMorseTokenPattern)
        call.tokens!,
  ];

  /// Expects [patterns] (by default [played]) to spell [word] letter by
  /// letter and then drill it, at least once.
  void expectSpelledThenDrilled(String word, [List<Object>? patterns]) {
    final played = patterns ?? this.played;
    final letters = [for (final letter in word.split('')) _letter(letter)];
    expect(played, hasLength(greaterThan(letters.length)));
    expect(played.take(letters.length), letters);
    expect(played.skip(letters.length), everyElement(_word(word)));
  }

  Future<void> tearDown() async {
    await orchestrator.stop();
    await settle(_loopStarted);
    orchestrator.dispose();
    gestures.dispose();
  }
}

void main() {
  // -------------------------------------------------------------------------
  // When a word is spelled
  // -------------------------------------------------------------------------
  group('word spelling', () {
    test('starting on a word spells it letter by letter, then drills '
        'it', () async {
      final t = _Harness.word();
      expect(t.session.state.currentCharacter, 'HI');

      t.orchestrator.start();
      await settle(_severalRepeatCycles);

      t.expectSpelledThenDrilled('HI');
      expect(t.phase, SessionPhase.playing);

      await t.tearDown();
    });

    test('the spelled letters are spellingLetterGap apart', () async {
      final t = _Harness.word(spellingLetterGap: _longLetterGap);

      t.orchestrator.start();
      await settle(_loopStarted);
      expect(t.played, [_letter('H')]);

      await settle(_longLetterGap);
      expect(t.played.take(2), [_letter('H'), _letter('I')]);

      await t.tearDown();
    });

    test('the spelling is followed by the repeat pause before the word is '
        'drilled', () async {
      final t = _Harness.word(repeatPause: const Duration(milliseconds: 300));

      t.orchestrator.start();
      await settle(const Duration(milliseconds: 100));
      expect(t.played, [_letter('H'), _letter('I')]);

      await settle(const Duration(milliseconds: 300));
      expect(t.played, [_letter('H'), _letter('I'), _word('HI')]);

      await t.tearDown();
    });

    test('start() after stop() spells the word again', () async {
      final t = _Harness.word();
      t.orchestrator.start();
      await settle(_loopStarted);
      await t.orchestrator.stop();
      t.vibration.reset();

      t.orchestrator.start();
      await settle(_severalRepeatCycles);

      t.expectSpelledThenDrilled('HI');

      await t.tearDown();
    });

    final navigations =
        <
          String,
          ({_Harness Function() harness, GestureEvent event, String word})
        >{
          'NavigateNext': (
            harness: _Harness.word,
            event: const NavigateNext(),
            word: 'OK',
          ),
          'NavigatePrevious': (
            harness: () => _Harness.word(position: 2),
            event: const NavigatePrevious(),
            word: 'OK',
          ),
          'Reset': (
            harness: () => _Harness.word(position: 2),
            event: const Reset(),
            word: 'HI',
          ),
          'NavigateUp from the letters level': (
            harness: () =>
                _Harness(SessionNotifier(MorseLanguage.english)..nextLevel()),
            event: const NavigateUp(),
            word: 'HI',
          ),
        };

    for (final MapEntry(key: name, value: n) in navigations.entries) {
      test('$name spells the word it lands on, then drills it', () async {
        final t = n.harness();
        t.orchestrator.start();
        await settle(_loopStarted);

        t.gestures.addEvent(n.event);
        await settle(_severalRepeatCycles);

        expect(t.session.state.currentCharacter, n.word);
        t.expectSpelledThenDrilled(n.word, t.playedSinceCancel);

        await t.tearDown();
      });
    }

    test('a swipe up on the last level while listening spells the word '
        'again', () async {
      // Swiping right on the last word enters the quiz, so the restart in
      // place is a swipe up: the words level is the last level.
      final t = _Harness.word(position: 19);
      expect(t.session.state.currentCharacter, 'THANK');
      t.orchestrator.start();
      await settle(_loopStarted);
      t.gestures.addEvent(const MorseInput(MorseSignal.dash));
      await settle();
      expect(t.phase, SessionPhase.listening);
      t.vibration.reset();

      t.gestures.addEvent(const NavigateUp());
      await settle(_severalRepeatCycles);

      expect(t.session.state.currentCharacter, 'THANK');
      t.expectSpelledThenDrilled('THANK');

      await t.tearDown();
    });

    final answers = <String, List<MorseToken> Function()>{
      'a correct answer': () => _word('HI'),
      'a wrong answer': () => const [Signal(MorseSignal.dash)],
    };

    for (final MapEntry(key: name, value: answer) in answers.entries) {
      test('after the feedback for $name, the word is drilled without being '
          'spelled again', () async {
        final t = _Harness.word();
        t.orchestrator.start();
        await settle(_severalRepeatCycles);
        t.gestures.addEvent(const MorseInput(MorseSignal.dot));
        await settle();
        expect(t.phase, SessionPhase.listening);
        t.vibration.reset();

        t.gestures.addEvent(InputComplete(answer()));
        await settle(_severalRepeatCycles);

        expect(t.phase, SessionPhase.playing);
        expect(t.played, isNotEmpty);
        expect(t.played, everyElement(_word('HI')));

        await t.tearDown();
      });
    }
  });

  // -------------------------------------------------------------------------
  // Interrupting the spelling
  // -------------------------------------------------------------------------
  group('interrupting the spelling', () {
    test('a tap during a letter gap stops the spelling and listens', () async {
      final t = _Harness.word(spellingLetterGap: _longLetterGap);
      t.orchestrator.start();
      await settle(_loopStarted);
      expect(t.played, [_letter('H')]);

      t.gestures.addEvent(const MorseInput(MorseSignal.dot));
      await settle();

      expect(t.phase, SessionPhase.listening);
      expect(t.vibration.callLog, contains('cancel'));
      await settle(_afterLongGap);
      // The rest of the word never plays.
      expect(t.played, [_letter('H')]);
      expect(t.phase, SessionPhase.listening);

      await t.tearDown();
    });

    test('a bottom-strip tap during a letter gap is ignored and the spelling '
        'goes on', () async {
      final t = _Harness.word(spellingLetterGap: _longLetterGap);
      t.orchestrator.start();
      await settle(_loopStarted);

      t.gestures.addEvent(const BottomZoneAction());
      await settle(_afterLongGap);

      expect(t.gestures.insertCharGapCallCount, 0);
      expect(t.vibration.callLog, isNot(contains('cancel')));
      expect(t.played.take(2), [_letter('H'), _letter('I')]);

      await t.tearDown();
    });

    test('navigating during a letter gap abandons the old word and spells '
        'the new one', () async {
      final t = _Harness.word(spellingLetterGap: _longLetterGap);
      t.orchestrator.start();
      await settle(_loopStarted);
      expect(t.played, [_letter('H')]);

      t.gestures.addEvent(const NavigateNext());
      await settle(_afterLongGap);

      expect(t.session.state.currentCharacter, 'OK');
      expect(t.playedSinceCancel.take(2), [_letter('O'), _letter('K')]);
      // The I of HI never plays: the abandoned spelling ends with its gap.
      expect(t.played, isNot(contains(_letter('I'))));
      expect(t.played, isNot(contains(_word('HI'))));

      await t.tearDown();
    });

    test('stopping during a letter gap stops the spelling', () async {
      final t = _Harness.word(spellingLetterGap: _longLetterGap);
      t.orchestrator.start();
      await settle(_loopStarted);

      await t.orchestrator.stop();
      t.vibration.reset();
      await settle(_afterLongGap);

      expect(t.played, isEmpty);

      await t.tearDown();
    });
  });

  // -------------------------------------------------------------------------
  // Characters levels
  // -------------------------------------------------------------------------
  test('a character is played as it is, without a spelling', () async {
    final t = _Harness(SessionNotifier(MorseLanguage.english)..nextLevel());
    expect(t.session.state.currentCharacter, 'A');

    t.orchestrator.start();
    await settle(_severalRepeatCycles);

    expect(t.played, hasLength(greaterThan(1)));
    expect(t.played, everyElement(_letter('A')));

    await t.tearDown();
  });
}
