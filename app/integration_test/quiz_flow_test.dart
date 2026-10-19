import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/session/session_providers.dart';
import 'package:feel_you/settings/learned_items.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

/// Longer than the post-feedback pause of [fastTeachingConfig], so the loop
/// has resumed after a correct or wrong signal.
const _afterFeedback = Duration(milliseconds: 50);

/// Taps [signals] in one go, starting at [time], waits for the silence
/// timeout to complete the input, and returns the next free timestamp.
Future<Duration> _answer(
  TestHarness h,
  List<MorseSignal> signals,
  Duration time,
) async {
  var t = time;
  for (final signal in signals) {
    if (signal == MorseSignal.dot) {
      simulateDot(h.classifier, baseTime: t);
    } else {
      simulateDash(h.classifier, baseTime: t);
    }
    t += const Duration(milliseconds: 5);
  }
  await waitForSilenceTimeout();
  await Future<void>.delayed(const Duration(milliseconds: 20));
  return t + const Duration(milliseconds: 100);
}

/// Swipes right once at [time], lets the loop restart, and returns the next
/// free timestamp.
Future<Duration> _swipeRight(TestHarness h, Duration time) async {
  simulateSwipeRight(h.classifier, baseTime: time);
  await Future<void>.delayed(const Duration(milliseconds: 10));
  return time + const Duration(milliseconds: 50);
}

void main() {
  final letters = morseRegistry.levelsForLanguage(MorseLanguage.english)[1];
  List<MorseSignal> pattern(String letter) => letters.patterns[letter]!;

  late TestHarness h;
  late LearnedItemsStore store;

  setUp(() {
    store = InMemoryLearnedItemsStore();
    h = createTestHarness(
      overrides: [learnedItemsStoreProvider.overrideWithValue(store)],
    );
  });

  tearDown(() async {
    await h.dispose();
  });

  Set<String> learnedLetters(TestHarness h) =>
      h.container.read(learnedItemsProvider).of(MorseLanguage.english, letters);

  test('learn two letters, then the quiz plays only them', () async {
    h.container.read(sessionNotifierProvider.notifier).nextLevel();
    h.orchestrator.start();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    var time = const Duration(milliseconds: 100);

    // Learn A, then B.
    time = await _answer(h, pattern('A'), time);
    expect(learnedLetters(h), {'A'});
    await Future<void>.delayed(_afterFeedback);
    time = await _swipeRight(h, time);
    expect(h.currentCharacter, 'B');
    time = await _answer(h, pattern('B'), time);
    expect(learnedLetters(h), {'A', 'B'});
    await Future<void>.delayed(_afterFeedback);

    // Swipe right to Z and one more, into the quiz.
    for (var i = 0; i < 25; i++) {
      time = await _swipeRight(h, time);
    }
    final session = h.container.read(sessionNotifierProvider);
    expect(session.isInQuiz, isTrue);
    expect(h.vibration.hasPattern(questionMarkPattern), isTrue);
    final first = h.currentCharacter;
    expect(first, isIn(['A', 'B']));

    // Echo the quiz item: correct, then the other learned letter.
    h.vibration.reset();
    time = await _answer(h, pattern(first), time);
    expect(h.vibration.callTypes, contains(VibrationCallType.playSuccess));
    await Future<void>.delayed(_afterFeedback);

    final second = h.currentCharacter;
    expect(h.container.read(sessionNotifierProvider).isInQuiz, isTrue);
    expect(second, first == 'A' ? 'B' : 'A');
    expect(h.vibration.hasPattern(pattern(second)), isTrue);

    // Quiz answers do not change what is learned.
    expect(learnedLetters(h), {'A', 'B'});
  });

  test('learned items survive a restart, which still starts at 0', () async {
    h.container.read(sessionNotifierProvider.notifier).nextLevel();
    h.orchestrator.start();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await _answer(h, pattern('A'), const Duration(milliseconds: 100));
    expect(learnedLetters(h), {'A'});

    // A new container on the same store stands for the next launch.
    final relaunched = createTestHarness(
      overrides: [learnedItemsStoreProvider.overrideWithValue(store)],
    );
    addTearDown(relaunched.dispose);

    final session = relaunched.container.read(sessionNotifierProvider);
    expect(session.levelIndex, 0);
    expect(session.currentCharacter, '0');
    expect(session.isInQuiz, isFalse);
    expect(learnedLetters(relaunched), {'A'});
  });
}
