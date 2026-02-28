import 'dart:async';

import 'package:feel_you/gestures/gesture_classifier.dart';
import 'package:feel_you/gestures/gesture_event.dart';
import 'package:feel_you/gestures/gesture_providers.dart';
import 'package:feel_you/gestures/gesture_timing_config.dart';
import 'package:feel_you/morse/morse_symbol.dart';
import 'package:feel_you/session/session_providers.dart';
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
enum VibrationCallType { playMorsePattern, playSuccess, playError, cancel }

/// A single recorded call to [RecordingVibrationService].
class VibrationCall {
  const VibrationCall(this.type, [this.symbols]);

  final VibrationCallType type;

  /// Non-null only for [VibrationCallType.playMorsePattern].
  final List<MorseSymbol>? symbols;

  @override
  String toString() {
    if (symbols != null) return 'VibrationCall($type, $symbols)';
    return 'VibrationCall($type)';
  }
}

/// A [VibrationService] that records all calls for test assertions.
///
/// All methods complete immediately with no delay.
class RecordingVibrationService implements VibrationService {
  final List<VibrationCall> calls = [];

  /// Returns all recorded call types in order.
  List<VibrationCallType> get callTypes => calls.map((c) => c.type).toList();

  /// Returns the symbols from all [playMorsePattern] calls.
  List<List<MorseSymbol>> get patterns => calls
      .where((c) => c.type == VibrationCallType.playMorsePattern)
      .map((c) => c.symbols!)
      .toList();

  /// Whether any [playMorsePattern] call matches [expected] (element-wise).
  bool hasPattern(List<MorseSymbol> expected) =>
      patterns.any((p) => listEquals(p, expected));

  /// Clears all recorded calls.
  void reset() => calls.clear();

  @override
  Future<void> playMorsePattern(List<MorseSymbol> symbols) async {
    calls.add(
      VibrationCall(VibrationCallType.playMorsePattern, List.of(symbols)),
    );
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
  Future<void> cancel() async {
    calls.add(const VibrationCall(VibrationCallType.cancel));
  }
}

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

/// Teaching timing with minimal pause for fast tests.
const fastTeachingConfig = TeachingTimingConfig(
  repeatPause: Duration(milliseconds: 5),
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

  /// Reads the current session state.
  // ignore: avoid_dynamic_calls
  String get currentLetter =>
      container.read(sessionNotifierProvider).currentLetter;

  /// Disposes the provider container and all providers.
  Future<void> dispose() async {
    await orchestrator.stop();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    container.dispose();
  }
}

/// Creates a fully wired [TestHarness] with real providers and mocked vibration.
TestHarness createTestHarness() {
  final vibration = RecordingVibrationService();

  final container = ProviderContainer(
    overrides: [
      vibrationServiceProvider.overrideWithValue(vibration),
      gestureTimingConfigProvider.overrideWithValue(fastGestureConfig),
      screenWidthProvider.overrideWithValue(800),
      morseTimingConfigProvider.overrideWithValue(fastMorseTimingConfig),
      teachingTimingConfigProvider.overrideWithValue(fastTeachingConfig),
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
