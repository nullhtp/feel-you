import 'dart:math';

import 'package:feel_you/gestures/gesture_event.dart';
import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/session/session.dart';
import 'package:feel_you/settings/learned_items.dart';
import 'package:feel_you/teaching/teaching_orchestrator.dart';
import 'package:feel_you/teaching/teaching_timing_config.dart';
import 'package:flutter_test/flutter_test.dart' hide test;

import '../test_doubles/fake_gesture_classifier.dart';
import '../test_doubles/fake_time.dart';
import '../test_doubles/mock_vibration_service.dart';

// The tests run in fake time: `test` is the one from fake_time.dart. The
// loop's pauses and a test's waits then always end in the same order.

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Pause between pattern repetitions, short next to a test's waits.
const _repeatPause = Duration(milliseconds: 10);

/// Pause between feedback and the loop resuming.
const _postFeedbackPause = Duration(milliseconds: 20);

/// Silence after the `?` marker, for tests that only need the order.
const _shortMarkerGap = Duration(milliseconds: 10);

/// Silence after the `?` marker, for tests that act inside it. Much longer
/// than the steps of a test.
const _longMarkerGap = Duration(milliseconds: 300);

/// Long enough for the loop to have started and played once.
const _loopStarted = Duration(milliseconds: 20);

/// Long enough for feedback to end and the loop to play several times.
const _severalRepeatCycles = Duration(milliseconds: 150);

/// Waits [duration] of fake time: the stream events and loop iterations due
/// by then have run, and none due later.
Future<void> settle([Duration duration = Duration.zero]) =>
    Future<void>.delayed(duration);

/// An orchestrator on the English levels, wired to test doubles, with a
/// quiz that draws with a seeded [Random].
class _Harness {
  _Harness({
    int levelIndex = 0,
    int position = 0,
    Duration quizMarkerGap = _shortMarkerGap,
    Duration postFeedbackPause = _postFeedbackPause,
  }) {
    session = SessionNotifier(
      MorseLanguage.english,
      quizItemPicker: QuizItemPicker(
        learnedItemsOf: (language, level) =>
            learnedItems.state.of(language, level),
        random: Random(5),
      ),
    );
    for (var i = 0; i < levelIndex; i++) {
      session.nextLevel();
    }
    for (var i = 0; i < position; i++) {
      session.nextPosition();
    }
    orchestrator = TeachingOrchestrator(
      gestureClassifier: gestures,
      vibrationService: vibration,
      sessionNotifier: session,
      learnedItems: learnedItems,
      config: TeachingTimingConfig(
        repeatPause: _repeatPause,
        postFeedbackPause: postFeedbackPause,
        spellingLetterGap: const Duration(milliseconds: 10),
        quizMarkerGap: quizMarkerGap,
      ),
    );
  }

  /// A harness in the quiz of the level at [levelIndex], before `start()`.
  factory _Harness.inQuiz({
    int levelIndex = 0,
    Duration quizMarkerGap = _shortMarkerGap,
    Duration postFeedbackPause = _postFeedbackPause,
  }) {
    final t =
        _Harness(
            levelIndex: levelIndex,
            quizMarkerGap: quizMarkerGap,
            postFeedbackPause: postFeedbackPause,
          )
          ..moveToLastItem()
          ..session.nextPosition();
    expect(t.session.state.isInQuiz, isTrue);
    return t;
  }

  final learnedItems = LearnedItemsNotifier(InMemoryLearnedItemsStore());
  late final SessionNotifier session;
  final gestures = FakeGestureClassifier();
  final vibration = MockVibrationService();
  late final TeachingOrchestrator orchestrator;

  SessionState get state => session.state;

  /// The learned items of the current level.
  Set<String> get learned =>
      learnedItems.state.of(state.language, state.currentLevel);

  void moveToLastItem() {
    final last = state.currentLevel.characters.length - 1;
    while (state.positionIndex < last) {
      session.nextPosition();
    }
  }

  /// The pattern of [item] on the current level, as the loop plays it.
  Object patternOf(String item) {
    final level = state.currentLevel;
    return level.kind == LevelKind.words
        ? level.wordPatterns![item]!
        : level.patterns[item]!;
  }

  /// The answer that matches [item] on the current level.
  List<MorseToken> answerFor(String item) {
    final level = state.currentLevel;
    return level.kind == LevelKind.words
        ? level.wordPatterns![item]!
        : [for (final signal in level.patterns[item]!) Signal(signal)];
  }

  /// Taps [tokens] and completes the input.
  Future<void> answer(List<MorseToken> tokens) async {
    final first = tokens.whereType<Signal>().first.signal;
    gestures.addEvent(MorseInput(first));
    await settle();
    gestures.addEvent(InputComplete(tokens));
    await settle();
  }

  /// The patterns played since the vibration calls were last reset, in
  /// order: a character as its signals, a word as its tokens, and the
  /// success and error signals as their call types.
  List<Object> get played => _patterns(vibration.calls);

  /// The patterns played since the last `cancel`, as in [played].
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
      switch (call.type) {
        VibrationCallType.playMorsePattern => call.signals!,
        VibrationCallType.playMorseTokenPattern => call.tokens!,
        VibrationCallType.playSuccess ||
        VibrationCallType.playError => call.type,
        _ => null,
      },
  ].nonNulls.toList();

  Future<void> tearDown() async {
    await orchestrator.stop();
    await settle(_loopStarted);
    orchestrator.dispose();
    gestures.dispose();
    session.dispose();
    learnedItems.dispose();
  }
}

void main() {
  // -------------------------------------------------------------------------
  // Learned items
  // -------------------------------------------------------------------------
  group('learned items', () {
    test('a correct answer in the lessons makes the item learned', () async {
      final t = _Harness(position: 3);
      t.orchestrator.start();
      await settle(_loopStarted);

      await t.answer(t.answerFor('3'));

      expect(t.learned, {'3'});
      await t.tearDown();
    });

    test('a correct answer on a word makes the word learned', () async {
      final t = _Harness(levelIndex: 2);
      t.orchestrator.start();
      await settle(_loopStarted);

      await t.answer(t.answerFor('HI'));

      expect(t.learned, {'HI'});
      await t.tearDown();
    });

    test('a wrong answer does not', () async {
      final t = _Harness(position: 3);
      t.orchestrator.start();
      await settle(_loopStarted);

      await t.answer(const [Signal(MorseSignal.dot)]);

      expect(t.learned, isEmpty);
      await t.tearDown();
    });

    test('a correct answer in the quiz does not', () async {
      final t = _Harness.inQuiz();
      t.orchestrator.start();
      await settle(_loopStarted);

      await t.answer(t.answerFor(t.state.currentCharacter));

      expect(t.learned, isEmpty);
      await t.tearDown();
    });

    test(
      'a swipe during the success feedback keeps the item learned',
      () async {
        final t = _Harness(
          position: 3,
          postFeedbackPause: const Duration(milliseconds: 300),
        );
        t.orchestrator.start();
        await settle(_loopStarted);

        await t.answer(t.answerFor('3'));
        expect(t.state.phase, SessionPhase.feedback);
        t.gestures.addEvent(const NavigateNext());
        await settle(_loopStarted);

        expect(t.state.currentCharacter, '4');
        expect(
          t.learnedItems.state.of(MorseLanguage.english, t.state.currentLevel),
          {'3'},
        );
        await t.tearDown();
      },
    );
  });

  // -------------------------------------------------------------------------
  // The ? marker and the quiz loop
  // -------------------------------------------------------------------------
  group('quiz loop', () {
    test(
      'entering the quiz plays ?, then the quiz item after the gap',
      () async {
        final t = _Harness(position: 9, quizMarkerGap: _longMarkerGap);
        t.orchestrator.start();
        await settle(_loopStarted);

        t.gestures.addEvent(const NavigateNext());
        await settle(_loopStarted);
        expect(t.state.isInQuiz, isTrue);
        expect(t.playedSinceCancel, [questionMarkPattern]);

        await settle(_longMarkerGap);
        final item = t.state.currentCharacter;
        expect(t.playedSinceCancel.take(2), [
          questionMarkPattern,
          t.patternOf(item),
        ]);

        await t.tearDown();
      },
    );

    test('the quiz item then repeats', () async {
      final t = _Harness.inQuiz();
      t.orchestrator.start();
      await settle(_severalRepeatCycles);

      final item = t.patternOf(t.state.currentCharacter);
      expect(t.played.first, questionMarkPattern);
      expect(t.played.skip(1), hasLength(greaterThan(2)));
      expect(t.played.skip(1), everyElement(item));

      await t.tearDown();
    });

    test('start() in the quiz plays ?, and again after stop()', () async {
      final t = _Harness.inQuiz();
      t.orchestrator.start();
      await settle(_loopStarted);
      final item = t.state.currentCharacter;
      expect(t.played.take(2), [questionMarkPattern, t.patternOf(item)]);

      // The app goes to the background and comes back.
      await t.orchestrator.stop();
      t.vibration.reset();
      t.orchestrator.start();
      await settle(_loopStarted);

      expect(t.state.currentCharacter, item);
      expect(t.played.take(2), [questionMarkPattern, t.patternOf(item)]);

      await t.tearDown();
    });

    test('a skip plays a new item without ?', () async {
      final t = _Harness.inQuiz();
      t.orchestrator.start();
      await settle(_loopStarted);
      final before = t.state.currentCharacter;

      t.gestures.addEvent(const NavigateNext());
      await settle(_loopStarted);

      final item = t.state.currentCharacter;
      expect(item, isNot(before));
      expect(t.playedSinceCancel, isNotEmpty);
      expect(t.playedSinceCancel, everyElement(t.patternOf(item)));

      await t.tearDown();
    });

    test('a restart in place plays the same item without ?', () async {
      // The quiz of the words level: swipe up there is a no-op.
      final t = _Harness.inQuiz(levelIndex: 2);
      t.orchestrator.start();
      await settle(_loopStarted);
      final item = t.state.currentCharacter;

      t.gestures.addEvent(const MorseInput(MorseSignal.dot));
      await settle();
      expect(t.state.phase, SessionPhase.listening);
      t.gestures.addEvent(const NavigateUp());
      await settle(_loopStarted);

      expect(t.state.currentCharacter, item);
      expect(t.playedSinceCancel, isNotEmpty);
      expect(t.playedSinceCancel, everyElement(t.patternOf(item)));

      await t.tearDown();
    });

    test('lessons outside the quiz play no ?', () async {
      final t = _Harness(position: 8);
      t.orchestrator.start();
      await settle(_loopStarted);
      t.gestures.addEvent(const NavigateNext());
      await settle(_loopStarted);

      expect(t.state.currentCharacter, '9');
      expect(t.played, isNot(contains(questionMarkPattern)));

      await t.tearDown();
    });

    test('a quiz word is played without spelling it first', () async {
      final t = _Harness.inQuiz(levelIndex: 2);
      t.orchestrator.start();
      await settle(_severalRepeatCycles);

      final word = t.patternOf(t.state.currentCharacter);
      expect(t.played.first, questionMarkPattern);
      expect(t.played.skip(1), hasLength(greaterThan(1)));
      expect(t.played.skip(1), everyElement(word));

      await t.tearDown();
    });

    test('a tap during the gap after ? listens, and the answer is checked '
        'against the quiz item', () async {
      final t = _Harness.inQuiz(quizMarkerGap: _longMarkerGap);
      t.orchestrator.start();
      await settle(_loopStarted);
      expect(t.played, [questionMarkPattern]);
      final item = t.state.currentCharacter;

      await t.answer(t.answerFor(item));

      expect(
        t.vibration.calls.map((c) => c.type),
        contains(VibrationCallType.playSuccess),
      );
      // The quiz item itself was never played: the tap came first.
      expect(t.played, isNot(contains(t.patternOf(item))));

      await t.tearDown();
    });
  });

  // -------------------------------------------------------------------------
  // Feedback in the quiz
  // -------------------------------------------------------------------------
  group('quiz feedback', () {
    test('a correct answer plays success, then a new item without ?', () async {
      final t = _Harness.inQuiz();
      t.orchestrator.start();
      await settle(_loopStarted);
      final item = t.state.currentCharacter;
      t.vibration.reset();

      await t.answer(t.answerFor(item));
      await settle(_postFeedbackPause + _loopStarted);

      final next = t.state.currentCharacter;
      expect(t.state.isInQuiz, isTrue);
      expect(next, isNot(item));
      expect(t.played.first, VibrationCallType.playSuccess);
      expect(t.played.skip(1), isNotEmpty);
      expect(t.played.skip(1), everyElement(t.patternOf(next)));

      await t.tearDown();
    });

    test('the new item comes after the post-feedback pause', () async {
      final t = _Harness.inQuiz(
        postFeedbackPause: const Duration(milliseconds: 300),
      );
      t.orchestrator.start();
      await settle(_loopStarted);
      final item = t.state.currentCharacter;
      t.vibration.reset();

      await t.answer(t.answerFor(item));
      await settle(_loopStarted);
      expect(t.played, [VibrationCallType.playSuccess]);
      expect(t.state.currentCharacter, item);

      await settle(const Duration(milliseconds: 300));
      expect(t.state.currentCharacter, isNot(item));

      await t.tearDown();
    });

    test('a wrong answer plays error, then the same item again', () async {
      final t = _Harness.inQuiz();
      t.orchestrator.start();
      await settle(_loopStarted);
      final item = t.state.currentCharacter;
      t.vibration.reset();

      // Five dots is digit 5; answer with a pattern no digit has.
      await t.answer(const [Signal(MorseSignal.dash)]);
      await settle(_postFeedbackPause + _loopStarted);

      expect(t.state.currentCharacter, item);
      expect(t.played.first, VibrationCallType.playError);
      expect(t.played.skip(1), isNotEmpty);
      expect(t.played.skip(1), everyElement(t.patternOf(item)));

      await t.tearDown();
    });

    test('a correct answer in the lessons stays on the same item', () async {
      final t = _Harness(position: 9);
      t.orchestrator.start();
      await settle(_loopStarted);

      await t.answer(t.answerFor('9'));
      await settle(_postFeedbackPause + _loopStarted);

      expect(t.state.isInQuiz, isFalse);
      expect(t.state.currentCharacter, '9');

      await t.tearDown();
    });

    test(
      'a skip during the success feedback cancels it and plays a new item',
      () async {
        final t = _Harness.inQuiz(
          postFeedbackPause: const Duration(milliseconds: 300),
        );
        t.orchestrator.start();
        await settle(_loopStarted);
        final item = t.state.currentCharacter;

        await t.answer(t.answerFor(item));
        expect(t.state.phase, SessionPhase.feedback);
        t.gestures.addEvent(const NavigateNext());
        await settle(_loopStarted);

        final skipped = t.state.currentCharacter;
        expect(skipped, isNot(item));
        expect(t.state.phase, SessionPhase.playing);
        expect(t.playedSinceCancel, everyElement(t.patternOf(skipped)));

        // The abandoned feedback does not draw yet another item later.
        await settle(const Duration(milliseconds: 350));
        expect(t.state.currentCharacter, skipped);

        await t.tearDown();
      },
    );
  });
}
