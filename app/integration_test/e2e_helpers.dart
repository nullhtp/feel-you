import 'dart:async';

import 'package:feel_you/app.dart';
import 'package:feel_you/gestures/gestures.dart';
import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/session/session.dart';
import 'package:feel_you/settings/language_preference.dart';
import 'package:feel_you/settings/learned_items.dart';
import 'package:feel_you/teaching/teaching.dart';
import 'package:feel_you/ui/touch_surface.dart';
import 'package:feel_you/vibration/vibration.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'test_helpers.dart';

// End-to-end tests: the whole app on a device or simulator, driven with
// pointer events. Only what a simulator cannot do, or a test must fix, is
// replaced (see the `integration-testing` spec).

// ---------------------------------------------------------------------------
// Timings
// ---------------------------------------------------------------------------

/// Gesture timing for end-to-end tests.
///
/// The default silence timeout (1 s) leaves room for the frames between
/// two test taps. The long hold is shortened, so a test can outlast it
/// quickly.
const e2eGestureConfig = GestureTimingConfig(resetMinDuration: 400);

/// Teaching timing for end-to-end tests: a repeat pause long enough to tell
/// one repetition from the next, short silences elsewhere.
const e2eTeachingConfig = TeachingTimingConfig(
  repeatPause: Duration(milliseconds: 300),
  postFeedbackPause: Duration(milliseconds: 100),
  spellingLetterGap: Duration(milliseconds: 50),
  quizMarkerGap: Duration(milliseconds: 50),
);

/// Digit "0", the first item of every language: five dashes.
const digitZero = [
  MorseSignal.dash,
  MorseSignal.dash,
  MorseSignal.dash,
  MorseSignal.dash,
  MorseSignal.dash,
];

// ---------------------------------------------------------------------------
// The vibration platform
// ---------------------------------------------------------------------------

/// The `vibration` plugin's channel.
const vibrationPluginChannel = MethodChannel('vibration');

/// Answers the questions the app asks about the motor, and records what the
/// app sends to the `vibration` plugin, at the platform channels.
///
/// Everything above the channels is the app's own: the capability probe,
/// the `DeviceVibrationService` and the signal choice. Without [install],
/// the device answers for itself.
class FakeVibrationPlatform {
  FakeVibrationPlatform({
    this.hasVibrator = true,
    this.hasAmplitudeControl = true,
    this.answersAfter,
  });

  /// The answer to `hasVibrator` on `feel_you/vibrator`.
  final bool hasVibrator;

  /// The answer to `hasAmplitudeControl` on `feel_you/vibrator`.
  final bool hasAmplitudeControl;

  /// When given, no capability is answered before it completes, so the
  /// detection ends late.
  final Future<void>? answersAfter;

  /// The arguments of every `vibrate` call, in order.
  final List<Map<Object?, Object?>> vibrateCalls = [];

  /// Intercepts both channels until the end of the test.
  void install(WidgetTester tester) {
    final messenger = tester.binding.defaultBinaryMessenger
      ..setMockMethodCallHandler(vibratorChannel, (call) async {
        await answersAfter;
        return switch (call.method) {
          'hasVibrator' => hasVibrator,
          'hasAmplitudeControl' => hasAmplitudeControl,
          _ => null,
        };
      })
      ..setMockMethodCallHandler(vibrationPluginChannel, (call) async {
        switch (call.method) {
          case 'hasCustomVibrationsSupport':
            await answersAfter;
            return true;
          case 'vibrate':
            vibrateCalls.add(
              Map<Object?, Object?>.of(call.arguments as Map<Object?, Object?>),
            );
        }
        return null;
      });
    addTearDown(() {
      messenger
        ..setMockMethodCallHandler(vibratorChannel, null)
        ..setMockMethodCallHandler(vibrationPluginChannel, null);
    });
  }

  /// The segment durations of every `vibrate` call, in order.
  List<List<int>> get patterns => [
    for (final call in vibrateCalls) (call['pattern']! as List).cast<int>(),
  ];

  /// The segment intensities of every `vibrate` call, in order.
  List<List<int>> get intensities => [
    for (final call in vibrateCalls) (call['intensities']! as List).cast<int>(),
  ];

  /// Indexes of the `vibrate` calls that are the 50 ms tap feedback: a
  /// plain duration, with no pattern.
  List<int> get tapFeedbackIndexes => [
    for (var i = 0; i < vibrateCalls.length; i++)
      if (vibrateCalls[i]['duration'] == 50 &&
          (vibrateCalls[i]['pattern']! as List).isEmpty)
        i,
  ];

  /// Index of the first `vibrate` call with the segments [pattern] from
  /// [start] on, or -1.
  int indexOfPattern(List<int> pattern, {int start = 0}) =>
      patterns.indexWhere((p) => _listEquals(p, pattern), start);

  static bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

// ---------------------------------------------------------------------------
// The app
// ---------------------------------------------------------------------------

/// `FeelYouApp` as `main` runs it, with the overrides an end-to-end test
/// needs.
class E2EApp {
  /// Creates the app with [savedLanguage] as the language saved on an
  /// earlier run (none: the picker opens first).
  ///
  /// With a [vibration] service the vibrations are recorded there; without
  /// one the app's own `DeviceVibrationService` plays them through the
  /// `vibration` plugin. [overrides] come last and win.
  E2EApp({this.savedLanguage, this.vibration, this.overrides = const []});

  final MorseLanguage? savedLanguage;
  final VibrationService? vibration;
  final List<Override> overrides;

  /// The accelerometer readings the app's shake detector gets. Quiet unless
  /// a test calls [shake].
  final accelerometer = StreamController<AccelerometerEvent>.broadcast();

  /// Launches the app in the foreground and draws its first frames.
  Future<void> launch(WidgetTester tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final service = vibration;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          languagePreferenceStoreProvider.overrideWithValue(
            InMemoryLanguagePreferenceStore(savedLanguage),
          ),
          learnedItemsStoreProvider.overrideWithValue(
            InMemoryLearnedItemsStore(),
          ),
          gestureTimingConfigProvider.overrideWithValue(e2eGestureConfig),
          morseTimingConfigProvider.overrideWithValue(fastMorseTimingConfig),
          teachingTimingConfigProvider.overrideWithValue(e2eTeachingConfig),
          shakeDetectorProvider.overrideWith((ref) {
            final detector = ShakeDetector(
              config: ref.watch(shakeConfigProvider),
              accelerometerStream: accelerometer.stream,
            );
            ref.onDispose(detector.dispose);
            return detector;
          }),
          if (service != null)
            vibrationServiceProvider.overrideWithValue(service),
          ...overrides,
        ],
        child: const FeelYouApp(),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  /// The app's provider container.
  ProviderContainer container(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(FeelYouApp)));

  /// The session state right now.
  SessionState session(WidgetTester tester) =>
      container(tester).read(sessionNotifierProvider);

  /// Whether the teaching loop is running.
  bool isTeachingRunning(WidgetTester tester) =>
      container(tester).read(teachingOrchestratorProvider).isRunning;

  /// What the classifier has buffered of the current answer.
  List<MorseToken> inputBuffer(WidgetTester tester) =>
      container(tester).read(inputBufferProvider).value;

  /// One shake as the default sensor stream reports it: three readings
  /// well above the threshold, 200 ms apart, in real time.
  Future<void> shake() async {
    for (var i = 0; i < 3; i++) {
      if (i > 0) await Future<void>.delayed(const Duration(milliseconds: 200));
      accelerometer.add(AccelerometerEvent(30, 0, 0, DateTime.now()));
    }
  }

  /// Stops the loop and removes the app, so the next test starts afresh.
  Future<void> close(WidgetTester tester) async {
    if (!tester.binding.framesEnabled) await bringToForeground(tester);
    if (find.byType(FeelYouApp).evaluate().isNotEmpty) {
      await container(
        tester,
      ).read(teachingOrchestratorProvider.notifier).stop();
    }
    await tester.pumpWidget(const SizedBox());
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await accelerometer.close();
  }
}

// ---------------------------------------------------------------------------
// Touches on the lesson surface
// ---------------------------------------------------------------------------

/// The point at the fractions [fx] and [fy] of the lesson surface.
Offset surfacePoint(WidgetTester tester, double fx, double fy) {
  final rect = tester.getRect(find.byType(TouchSurface));
  return Offset(rect.left + rect.width * fx, rect.top + rect.height * fy);
}

/// A point on the left (dot) half, above the bottom strip.
Offset dotPoint(WidgetTester tester) => surfacePoint(tester, 0.25, 0.4);

/// A point on the right (dash) half, above the bottom strip.
Offset dashPoint(WidgetTester tester) => surfacePoint(tester, 0.75, 0.4);

/// A point in the bottom strip, the lower 15% of the surface.
Offset bottomStripPoint(WidgetTester tester) => surfacePoint(tester, 0.5, 0.95);

/// Taps once at [point] and draws a frame.
Future<void> tapAt(WidgetTester tester, Offset point) async {
  final gesture = await tester.startGesture(point);
  await gesture.up();
  await tester.pump();
}

// ---------------------------------------------------------------------------
// Time and the app lifecycle
// ---------------------------------------------------------------------------

/// Waits in real time until [condition] holds, failing after [timeout].
///
/// Draws a frame each round while frames are enabled. While the app is
/// hidden or paused the engine draws none, so it only waits.
Future<void> waitUntil(
  WidgetTester tester,
  bool Function() condition, {
  required String reason,
  Duration timeout = const Duration(seconds: 5),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) fail('Timed out waiting: $reason');
    await Future<void>.delayed(const Duration(milliseconds: 20));
    if (tester.binding.framesEnabled) await tester.pump();
  }
}

/// Waits [duration] in real time, drawing frames while they are enabled.
Future<void> waitFor(WidgetTester tester, Duration duration) async {
  await Future<void>.delayed(duration);
  if (tester.binding.framesEnabled) await tester.pump();
}

/// Waits until the wakelock plugin reports [enabled], failing after 2 s.
///
/// The app toggles the wakelock without waiting for the platform, so the
/// state may lag a frame behind.
Future<void> expectWakelock({required bool enabled}) async {
  final deadline = DateTime.now().add(const Duration(seconds: 2));
  while (await WakelockPlus.enabled != enabled) {
    if (DateTime.now().isAfter(deadline)) {
      fail('The wakelock should be ${enabled ? 'enabled' : 'disabled'}');
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

/// Sends the app to the background through every intermediate state, as
/// the engine does. Draws no frame: there are none while hidden.
void sendToBackground(WidgetTester tester) {
  for (final state in const [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
}

/// Brings the app back to the foreground through every intermediate state,
/// then draws a frame.
Future<void> bringToForeground(WidgetTester tester) async {
  for (final state in const [
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
  await tester.pump();
}
