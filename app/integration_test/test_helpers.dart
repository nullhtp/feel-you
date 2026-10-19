import 'dart:async';

import 'package:feel_you/gestures/gesture_classifier.dart';
import 'package:feel_you/gestures/gesture_event.dart';
import 'package:feel_you/gestures/gesture_providers.dart';
import 'package:feel_you/gestures/gesture_timing_config.dart';
import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/session/session_providers.dart';
import 'package:feel_you/tactile/tactile.dart';
import 'package:feel_you/teaching/teaching_orchestrator.dart';
import 'package:feel_you/teaching/teaching_providers.dart';
import 'package:feel_you/teaching/teaching_timing_config.dart';
import 'package:feel_you/vibration/vibration.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Recording VibrationService
// ---------------------------------------------------------------------------

/// The type of vibration call made to [RecordingVibrationService].
enum VibrationCallType {
  playMorsePattern,
  playMorseTokenPattern,
  playSuccess,
  playError,
  playTapFeedback,
  cancel,
}

/// A single recorded call to [RecordingVibrationService].
class VibrationCall {
  const VibrationCall(this.type, {this.signals, this.tokens, this.played});

  final VibrationCallType type;

  /// Non-null only for [VibrationCallType.playMorsePattern].
  final List<MorseSignal>? signals;

  /// Non-null only for [VibrationCallType.playMorseTokenPattern].
  final List<MorseToken>? tokens;

  /// The tactile tokens the service was asked to play, as they were passed
  /// to [RecordingVibrationService.playTokens].
  ///
  /// Non-null for both playback types.
  final List<TactileToken>? played;

  @override
  String toString() {
    if (signals != null) return 'VibrationCall($type, $signals)';
    if (tokens != null) return 'VibrationCall($type, $tokens)';
    return 'VibrationCall($type)';
  }
}

/// A [VibrationService] that records all calls for test assertions.
///
/// All methods complete immediately with no delay.
///
/// Playbacks are recorded in Morse terms, because the lessons are Morse and
/// the tests are written in dots and dashes: a playback with a character
/// gap (a word) as [VibrationCallType.playMorseTokenPattern] with its
/// [VibrationCall.tokens], one without (a digit, a letter, a spelled letter,
/// `?`) as [VibrationCallType.playMorsePattern] with its
/// [VibrationCall.signals]. Every lesson word has at least two letters, so a
/// gap reliably marks a word. [VibrationCall.played] keeps the tactile
/// tokens themselves.
class RecordingVibrationService implements VibrationService {
  final List<VibrationCall> calls = [];

  /// Returns all recorded call types in order.
  List<VibrationCallType> get callTypes => calls.map((c) => c.type).toList();

  /// Returns the signals of all [VibrationCallType.playMorsePattern]
  /// playbacks.
  List<List<MorseSignal>> get patterns => calls
      .where((c) => c.type == VibrationCallType.playMorsePattern)
      .map((c) => c.signals!)
      .toList();

  /// Whether any [VibrationCallType.playMorsePattern] playback matches
  /// [expected] (element-wise).
  bool hasPattern(List<MorseSignal> expected) =>
      patterns.any((p) => listEquals(p, expected));

  /// Clears all recorded calls.
  void reset() => calls.clear();

  @override
  Future<void> playTokens(List<TactileToken> tokens) async {
    final played = List<TactileToken>.unmodifiable(tokens);
    final morse = [for (final token in tokens) _morseToken(token)];
    if (morse.contains(const CharGap())) {
      calls.add(
        VibrationCall(
          VibrationCallType.playMorseTokenPattern,
          tokens: morse,
          played: played,
        ),
      );
    } else {
      calls.add(
        VibrationCall(
          VibrationCallType.playMorsePattern,
          signals: [for (final token in morse) (token as Signal).signal],
          played: played,
        ),
      );
    }
  }

  @override
  Future<void> playSuccess() async {
    calls.add(const VibrationCall(VibrationCallType.playSuccess));
  }

  @override
  Future<void> playError() async {
    calls.add(const VibrationCall(VibrationCallType.playError));
  }

  @override
  Future<void> playTapFeedback() async {
    calls.add(const VibrationCall(VibrationCallType.playTapFeedback));
  }

  @override
  Future<void> cancel() async {
    calls.add(const VibrationCall(VibrationCallType.cancel));
  }
}

/// The Morse token a tactile [token] stands for in a Morse playback.
MorseToken _morseToken(TactileToken token) => switch (token) {
  TactileToken.shortPulse => const Signal(MorseSignal.dot),
  TactileToken.longPulse => const Signal(MorseSignal.dash),
  TactileToken.characterGap => const CharGap(),
  TactileToken.emptySlot => throw UnsupportedError(
    'An empty slot has no Morse equivalent',
  ),
};

// ---------------------------------------------------------------------------
// Fast timing configs for tests
// ---------------------------------------------------------------------------

/// Gesture timing with very short durations for fast tests.
const fastGestureConfig = GestureTimingConfig(
  resetMinDuration: 30,
  silenceTimeout: 10,
  minSwipeDistance: 50,
  minSwipeVelocity: 200,
);

/// Vibration timing with minimal durations for fast tests.
const fastMorseTimingConfig = MorseTimingConfig(
  dotDuration: 1,
  dashDuration: 2,
  interSymbolGap: 1,
);

/// Teaching timing with minimal pauses for fast tests.
const fastTeachingConfig = TeachingTimingConfig(
  repeatPause: Duration(milliseconds: 5),
  postFeedbackPause: Duration(milliseconds: 5),
  quizMarkerGap: Duration(milliseconds: 5),
);

// ---------------------------------------------------------------------------
// Gesture simulation helpers
// ---------------------------------------------------------------------------

/// Simulates a dot tap (tap on left half) on the given [classifier].
///
/// Uses timestamps relative to [baseTime] to ensure consistent timing.
/// Position 100 is on the left half (< 400 midpoint for 800px screen).
void simulateDot(GestureClassifier classifier, {required Duration baseTime}) {
  classifier.handleTouch(TouchDown(timestamp: baseTime, position: 100));
  classifier.handleTouch(
    TouchUp(
      timestamp: baseTime + const Duration(milliseconds: 2),
      position: 100,
    ),
  );
}

/// Simulates a dash tap (tap on right half) on the given [classifier].
/// Position 600 is on the right half (>= 400 midpoint for 800px screen).
void simulateDash(GestureClassifier classifier, {required Duration baseTime}) {
  classifier.handleTouch(TouchDown(timestamp: baseTime, position: 600));
  classifier.handleTouch(
    TouchUp(
      timestamp: baseTime + const Duration(milliseconds: 2),
      position: 600,
    ),
  );
}

/// Simulates a swipe-right gesture on the given [classifier].
void simulateSwipeRight(
  GestureClassifier classifier, {
  required Duration baseTime,
}) {
  classifier.handleTouch(TouchDown(timestamp: baseTime, position: 0));
  classifier.handleTouch(
    TouchUp(
      timestamp: baseTime + const Duration(milliseconds: 2),
      position: 100, // 100px right in 2ms = high velocity
    ),
  );
}

/// Simulates a swipe-left gesture on the given [classifier].
void simulateSwipeLeft(
  GestureClassifier classifier, {
  required Duration baseTime,
}) {
  classifier.handleTouch(TouchDown(timestamp: baseTime, position: 100));
  classifier.handleTouch(
    TouchUp(
      timestamp: baseTime + const Duration(milliseconds: 2),
      position: 0, // 100px left in 2ms = high velocity
    ),
  );
}

/// Simulates a swipe-up gesture on the given [classifier].
void simulateSwipeUp(
  GestureClassifier classifier, {
  required Duration baseTime,
}) {
  classifier.handleTouch(TouchDown(timestamp: baseTime, position: 400, y: 100));
  classifier.handleTouch(
    TouchUp(
      timestamp: baseTime + const Duration(milliseconds: 2),
      position: 400,
      y: 0, // 100px up in 2ms = high velocity
    ),
  );
}

/// Simulates a swipe-down gesture on the given [classifier].
void simulateSwipeDown(
  GestureClassifier classifier, {
  required Duration baseTime,
}) {
  classifier.handleTouch(TouchDown(timestamp: baseTime, position: 400, y: 0));
  classifier.handleTouch(
    TouchUp(
      timestamp: baseTime + const Duration(milliseconds: 2),
      position: 400,
      y: 100, // 100px down in 2ms = high velocity
    ),
  );
}

/// Simulates a long hold that triggers a reset on the given [classifier].
///
/// Returns a future that completes after the reset timer fires.
Future<void> simulateLongHold(
  GestureClassifier classifier, {
  required Duration baseTime,
}) async {
  classifier.handleTouch(TouchDown(timestamp: baseTime, position: 100));
  // Wait for the reset timer to fire (resetMinDuration + buffer).
  await Future<void>.delayed(
    Duration(milliseconds: fastGestureConfig.resetMinDuration + 10),
  );
  classifier.handleTouch(
    TouchUp(
      timestamp:
          baseTime +
          Duration(milliseconds: fastGestureConfig.resetMinDuration + 10),
      position: 100,
    ),
  );
}

/// Waits for the silence timeout to elapse, triggering [InputComplete].
Future<void> waitForSilenceTimeout() async {
  await Future<void>.delayed(
    Duration(milliseconds: fastGestureConfig.silenceTimeout + 5),
  );
}

// ---------------------------------------------------------------------------
// Test harness setup
// ---------------------------------------------------------------------------

/// Everything needed for an integration test scenario.
class TestHarness {
  TestHarness({
    required this.container,
    required this.vibration,
    required this.classifier,
    required this.orchestrator,
  });

  final ProviderContainer container;
  final RecordingVibrationService vibration;
  final GestureClassifier classifier;
  final TeachingOrchestrator orchestrator;

  /// Reads the current character from session state.
  // ignore: avoid_dynamic_calls
  String get currentCharacter =>
      container.read(sessionNotifierProvider).currentCharacter;

  /// Legacy alias used by existing integration tests.
  String get currentLetter => currentCharacter;

  /// Disposes the provider container and all providers.
  Future<void> dispose() async {
    await orchestrator.stop();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    container.dispose();
  }
}

/// Creates a fully wired [TestHarness] with real providers and mocked vibration.
///
/// [overrides] are added to the defaults, e.g. a learned-items store shared
/// by two harnesses to stand for an app restart.
TestHarness createTestHarness({List<Override> overrides = const []}) {
  final vibration = RecordingVibrationService();

  final container = ProviderContainer(
    overrides: [
      vibrationServiceProvider.overrideWithValue(vibration),
      gestureTimingConfigProvider.overrideWithValue(fastGestureConfig),
      screenWidthProvider.overrideWithValue(800),
      morseTimingConfigProvider.overrideWithValue(fastMorseTimingConfig),
      teachingTimingConfigProvider.overrideWithValue(fastTeachingConfig),
      ...overrides,
    ],
  );

  final classifier = container.read(gestureClassifierProvider);
  final orchestrator = container.read(teachingOrchestratorProvider.notifier);

  return TestHarness(
    container: container,
    vibration: vibration,
    classifier: classifier,
    orchestrator: orchestrator,
  );
}
