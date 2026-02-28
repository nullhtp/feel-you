/// Centralized tuning reference for all timing constants.
///
/// This file documents every adjustable timing parameter in the app,
/// grouped by subsystem. It references the existing config classes
/// without replacing them — use this as the single entry point when
/// calibrating values on real devices.
///
/// ## How to tune
///
/// 1. Run the app on a real device (iOS or Android).
/// 2. Adjust values in this file.
/// 3. Override the corresponding providers in `main.dart` or via
///    provider overrides, passing these config instances.
/// 4. Repeat until the feel is right.
///
/// Values marked with `// TODO(tuning):` need real-device validation.
library;

import 'package:feel_you/gestures/gesture_timing_config.dart';
import 'package:feel_you/teaching/teaching_timing_config.dart';
import 'package:feel_you/vibration/morse_timing_config.dart';

// ---------------------------------------------------------------------------
// Gesture recognition timing
// ---------------------------------------------------------------------------

/// All gesture timing thresholds in one place.
///
/// These control how raw touch events are classified into swipes and resets.
/// Dot/dash classification is position-based (left half = dot, right half =
/// dash), so no duration thresholds for dot/dash are needed.
const gestureDefaults = GestureTimingConfig(
  /// Minimum press duration to trigger a reset (long hold), in ms.
  // TODO(tuning): 2000ms — ensure this is long enough to feel intentional
  // but short enough to not frustrate.
  resetMinDuration: 2000,

  /// Silence after the last Morse input before auto-submitting, in ms.
  /// Shorter = faster pace; longer = more forgiving.
  // TODO(tuning): 1000ms silence timeout — critical for learning pace.
  // Too short and users can't think; too long and it feels sluggish.
  silenceTimeout: 1000,

  /// Minimum horizontal distance for a swipe, in logical pixels.
  minSwipeDistance: 50,

  /// Minimum horizontal velocity for a swipe, in logical pixels per second.
  minSwipeVelocity: 200,
);

// ---------------------------------------------------------------------------
// Vibration output timing
// ---------------------------------------------------------------------------

/// Morse code vibration timing parameters.
///
/// These control how long each vibration pulse lasts and the gaps between
/// them. The "feel" of Morse code depends heavily on these ratios.
///
/// Note: success/error signal patterns are hardcoded as [successSignal]
/// and [errorSignal] constants in `vibration_service.dart` — their
/// rhythmic structure doesn't reduce to simple config parameters.
const vibrationDefaults = MorseTimingConfig(
  /// Duration of a dot vibration, in ms.
  // TODO(tuning): 100ms — may need to increase for perceptibility on
  // devices with weaker haptic motors.
  dotDuration: 100,

  /// Duration of a dash vibration, in ms.
  /// Standard Morse ratio is dash = 3x dot.
  // TODO(tuning): 300ms (3x dot) — validate the 3:1 ratio feels
  // distinguishable through touch.
  dashDuration: 300,

  /// Silence between consecutive symbols within a letter, in ms.
  // TODO(tuning): 100ms gap — must be long enough to feel like a pause
  // but short enough to keep the letter cohesive.
  interSymbolGap: 100,
);

// ---------------------------------------------------------------------------
// Teaching loop timing
// ---------------------------------------------------------------------------

/// Teaching loop timing parameters.
///
/// Controls the pace of the play-wait-repeat loop that teaches each letter.
const teachingDefaults = TeachingTimingConfig(
  /// Pause between pattern repetitions, in ms.
  /// After playing a letter's Morse pattern, the app waits this long
  /// before replaying it.
  // TODO(tuning): 3000ms pause — critical for learning pace. Too short
  // and the user can't process; too long and they lose context.
  repeatPause: Duration(milliseconds: 3000),
);
