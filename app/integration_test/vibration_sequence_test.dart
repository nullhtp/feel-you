import 'dart:math';

import 'package:feel_you/gestures/gesture_classifier.dart';
import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/session/session_providers.dart';
import 'package:feel_you/vibration/vibration.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

// The lessons must feel exactly as they did before the tactile codec was
// introduced (issue #40). Each step below drives a real lesson flow and
// compares what the vibration service is asked to play, in milliseconds
// with the default Morse timing, with the sequence recorded on master at
// 94cc0b3, before the refactor.

/// The app's real timing, used to turn the recorded tokens into the
/// milliseconds the device is sent. The harness's fast timing only shortens
/// the pauses of the loop, which are not part of a pattern.
const _deviceTiming = MorseTimingConfig();

/// A recorded call: `play [ms...]`, `cancel`, `success`, `error`, `tap` or
/// `cloud off`.
String _event(VibrationCall call) => switch (call.type) {
  VibrationCallType.playMorsePattern ||
  VibrationCallType.playMorseTokenPattern => _play(
    buildVibrationPattern(call.played!, _deviceTiming),
  ),
  VibrationCallType.playSuccess => _success,
  VibrationCallType.playError => _error,
  VibrationCallType.playTapFeedback => _tap,
  VibrationCallType.playCloudOff => _cloudOff,
  VibrationCallType.cancel => _cancel,
};

String _play(List<int> milliseconds) => 'play $milliseconds';
const _cancel = 'cancel';
const _success = 'success';
const _error = 'error';
const _tap = 'tap';
const _cloudOff = 'cloud off';

// Patterns recorded before the refactor, `[wait, vibrate, wait, ...]` ms.
final _digit0 = _play([0, 300, 100, 300, 100, 300, 100, 300, 100, 300]);
final _digit1 = _play([0, 100, 100, 300, 100, 300, 100, 300, 100, 300]);
final _dotDash = _play([0, 100, 100, 300]); // A, ا, А, أ
final _letterH = _play([0, 100, 100, 100, 100, 100, 100, 100]);
final _letterI = _play([0, 100, 100, 100]);
final _wordHI = _play([
  0, 100, 100, 100, 100, 100, 100, 100, 300, 100, 100, 100, //
]);
final _questionMark = _play([
  0, 100, 100, 100, 100, 300, 100, 300, 100, 100, 100, 100, //
]);
final _arabicBa = _play([0, 300, 100, 100, 100, 100, 100, 100]); // ب
final _arabicKaf = _play([0, 300, 100, 100, 100, 300]); // ك
final _arabicLam = _play([0, 100, 100, 300, 100, 100, 100, 100]); // ل
final _arabicMim = _play([0, 300, 100, 300]); // م
final _arabicKul = _play([
  0, 300, 100, 100, 100, 300, 300, 100, 100, 300, 100, 100, 100, 100, //
]); // كل
final _arabicAlam = _play([
  0, 100, 100, 300, 300, 100, 100, 300, 100, 100, 100, 100, 300, 300, //
  100, 300,
]); // ألم
final _russianDe = _play([0, 300, 100, 100, 100, 100]); // Д
final _russianEn = _play([0, 300, 100, 100]); // Н
final _russianYe = _play([0, 100]); // Е
final _russianDa = _play([0, 300, 100, 100, 100, 100, 300, 100, 100, 300]);
final _russianNe = _play([0, 300, 100, 100, 300, 100]); // НЕ

/// A [Random] that always draws the first candidate, so the quiz item is
/// known: with nothing (or one item) learned, the first item of the level.
class _FirstCandidate implements Random {
  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;

  @override
  int nextInt(int max) => 0;
}

/// Drives a lesson flow step by step and checks each step's vibrations.
class _Flow {
  _Flow(MorseLanguage language)
    : h = createTestHarness(
        overrides: [quizRandomProvider.overrideWithValue(_FirstCandidate())],
      ) {
    // A screen tall enough for the bottom strip (its lower 15 %).
    h.classifier.screenHeight = 400;
    h.container.read(sessionNotifierProvider.notifier).selectLanguage(language);
  }

  final TestHarness h;

  var _time = const Duration(milliseconds: 100);
  Duration _next() => _time += const Duration(milliseconds: 100);

  /// Silence long enough for the loop to settle after a step.
  static const _settle = Duration(milliseconds: 40);

  /// Silence long enough for a word with [letterGaps] gaps between its
  /// letters to be spelled, and drilled at least once.
  static Duration spelled(int letterGaps) =>
      fastTeachingConfig.spellingLetterGap * letterGaps +
      const Duration(milliseconds: 300);

  /// Runs [action], waits [wait] and expects the step's vibrations to be
  /// [prefix] followed only by repeats of [repeating].
  ///
  /// How often the loop repeats depends on timing, so the pattern the loop
  /// was repeating before the step (the last call recorded so far) may also
  /// repeat a few more times before the step's first vibration: while a
  /// hold is being held, or when a pause of the loop ends just before a
  /// swipe is handled.
  Future<void> step(
    String name,
    Future<void> Function() action, {
    required List<String> prefix,
    required String repeating,
    Duration wait = _settle,
  }) async {
    final calls = h.vibration.calls;
    final before = calls.isEmpty ? null : _event(calls.last);
    h.vibration.reset();
    await action();
    await Future<void>.delayed(wait);
    final events = h.vibration.calls.map(_event).toList();
    _expectStep(name, events, before: before, prefix, repeating);
  }

  /// Runs [action] without checking it, e.g. to move along a level.
  Future<void> move(Future<void> Function() action) async {
    await action();
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }

  Future<void> start() async => h.orchestrator.start();
  Future<void> swipeRight() async =>
      simulateSwipeRight(h.classifier, baseTime: _next());
  Future<void> swipeLeft() async =>
      simulateSwipeLeft(h.classifier, baseTime: _next());
  Future<void> swipeUp() async =>
      simulateSwipeUp(h.classifier, baseTime: _next());
  Future<void> swipeDown() async =>
      simulateSwipeDown(h.classifier, baseTime: _next());
  Future<void> hold() => simulateLongHold(h.classifier, baseTime: _next());

  /// Taps [morse] (`.` dot, `-` dash, `/` the bottom strip) and waits for
  /// the silence timeout to complete the answer.
  Future<void> answer(String morse) async {
    for (final symbol in morse.split('')) {
      switch (symbol) {
        case '.':
          simulateDot(h.classifier, baseTime: _next());
        case '-':
          simulateDash(h.classifier, baseTime: _next());
        case '/':
          final at = _next();
          h.classifier
            ..handleTouch(TouchDown(timestamp: at, position: 100, y: 390))
            ..handleTouch(
              TouchUp(
                timestamp: at + const Duration(milliseconds: 2),
                position: 100,
                y: 390,
              ),
            );
          // The letter gap is inserted after the tap feedback has played.
          await Future<void>.delayed(const Duration(milliseconds: 2));
      }
    }
    await waitForSilenceTimeout();
  }

  Future<void> dispose() => h.dispose();
}

/// Expects [events] to be: some repeats of [before] (possibly none), then
/// exactly [prefix], then only repeats of [repeating].
void _expectStep(
  String name,
  List<String> events,
  List<String> prefix,
  String repeating, {
  String? before,
}) {
  for (var skip = 0; skip + prefix.length <= events.length; skip++) {
    if (skip > 0 && events[skip - 1] != before) break;
    final head = events.sublist(skip, skip + prefix.length);
    final rest = events.sublist(skip + prefix.length);
    if (listEquals(head, prefix) &&
        rest.every((e) => e == repeating) &&
        (prefix.isNotEmpty || rest.isNotEmpty)) {
      return;
    }
  }
  fail(
    '$name: expected ${before == null ? '' : '[$before]*, '}'
    '$prefix, [$repeating]*\n  got $events',
  );
}

void main() {
  late _Flow flow;

  tearDown(() => flow.dispose());

  test('English: digits, letters, words and the quiz feel as before', () async {
    flow = _Flow(MorseLanguage.english);

    await flow.step(
      'start on 0',
      flow.start,
      prefix: [_digit0],
      repeating: _digit0,
    );
    await flow.step(
      'answer 0',
      () => flow.answer('-----'),
      prefix: [_cancel, _success, _digit0],
      repeating: _digit0,
    );
    await flow.step(
      'swipe right to 1',
      flow.swipeRight,
      prefix: [_cancel, _digit1],
      repeating: _digit1,
    );
    await flow.step(
      'swipe up to A',
      flow.swipeUp,
      prefix: [_cancel, _dotDash],
      repeating: _dotDash,
    );
    await flow.step(
      'answer A wrong',
      () => flow.answer('.'),
      prefix: [_cancel, _error, _dotDash],
      repeating: _dotDash,
    );
    await flow.step(
      'swipe up to HI, spelled',
      flow.swipeUp,
      wait: _Flow.spelled(1),
      prefix: [_cancel, _letterH, _letterI, _wordHI],
      repeating: _wordHI,
    );
    await flow.step(
      'answer HI with a bottom-strip letter gap',
      () => flow.answer('..../..'),
      prefix: [_cancel, _tap, _success, _wordHI],
      repeating: _wordHI,
    );
    await flow.step(
      'hold: HI again, spelled',
      flow.hold,
      wait: _Flow.spelled(1),
      prefix: [_cancel, _letterH, _letterI, _wordHI],
      repeating: _wordHI,
    );
    await flow.step(
      'swipe down to A',
      flow.swipeDown,
      prefix: [_cancel, _dotDash],
      repeating: _dotDash,
    );
    await flow.step(
      'swipe down to 0',
      flow.swipeDown,
      prefix: [_cancel, _digit0],
      repeating: _digit0,
    );
    for (var i = 0; i < 9; i++) {
      await flow.move(flow.swipeRight);
    }
    expect(flow.h.currentCharacter, '9');
    await flow.step(
      'swipe right into the quiz',
      flow.swipeRight,
      prefix: [_cancel, _questionMark, _digit0],
      repeating: _digit0,
    );
    expect(flow.h.container.read(sessionNotifierProvider).isInQuiz, isTrue);
  });

  test('Arabic: letters and a word with an alias feel as before', () async {
    flow = _Flow(MorseLanguage.arabic);

    await flow.step(
      'start on 0',
      flow.start,
      prefix: [_digit0],
      repeating: _digit0,
    );
    await flow.step(
      'swipe up to ا',
      flow.swipeUp,
      prefix: [_cancel, _dotDash],
      repeating: _dotDash,
    );
    await flow.step(
      'swipe right to ب',
      flow.swipeRight,
      prefix: [_cancel, _arabicBa],
      repeating: _arabicBa,
    );
    await flow.step(
      'swipe up to كل, spelled',
      flow.swipeUp,
      wait: _Flow.spelled(1),
      prefix: [_cancel, _arabicKaf, _arabicLam, _arabicKul],
      repeating: _arabicKul,
    );
    for (var i = 0; i < 5; i++) {
      await flow.move(flow.swipeRight);
    }
    await flow.step(
      'swipe right to ألم, spelled with Alif for أ',
      flow.swipeRight,
      wait: _Flow.spelled(2),
      prefix: [_cancel, _dotDash, _arabicLam, _arabicMim, _arabicAlam],
      repeating: _arabicAlam,
    );
    expect(flow.h.currentCharacter, 'ألم');
  });

  test('Russian: words and a boundary swipe feel as before', () async {
    flow = _Flow(MorseLanguage.russian);

    await flow.step(
      'start on 0',
      flow.start,
      prefix: [_digit0],
      repeating: _digit0,
    );
    await flow.step(
      'swipe up to А',
      flow.swipeUp,
      prefix: [_cancel, _dotDash],
      repeating: _dotDash,
    );
    await flow.step(
      'swipe up to ДА, spelled',
      flow.swipeUp,
      wait: _Flow.spelled(1),
      prefix: [_cancel, _russianDe, _dotDash, _russianDa],
      repeating: _russianDa,
    );
    await flow.step(
      'swipe left on the first word: ДА keeps repeating',
      flow.swipeLeft,
      prefix: [],
      repeating: _russianDa,
    );
    await flow.step(
      'swipe right to НЕ, spelled',
      flow.swipeRight,
      wait: _Flow.spelled(1),
      prefix: [_cancel, _russianEn, _russianYe, _russianNe],
      repeating: _russianNe,
    );
    expect(flow.h.currentCharacter, 'НЕ');
  });
}
