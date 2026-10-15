import 'package:feel_you/gestures/gesture_classifier.dart';
import 'package:feel_you/gestures/gesture_timing_config.dart';
import 'package:feel_you/gestures/shake_config.dart';
import 'package:feel_you/gestures/shake_detector.dart';
import 'package:feel_you/morse/morse.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the [GestureTimingConfig] used for gesture classification.
///
/// Override this provider in tests or to tune threshold values.
final gestureTimingConfigProvider = Provider<GestureTimingConfig>(
  (ref) => const GestureTimingConfig(),
);

/// Provides the initial screen width in logical pixels for position-based
/// dot/dash classification.
///
/// This only seeds [GestureClassifier.screenWidth] when the classifier is
/// created. The live width comes from the layout: `TouchSurface` sets
/// [GestureClassifier.screenWidth] from `MediaQuery.sizeOf` on every touch,
/// so split-screen, foldables, rotation and display-size changes move the
/// midpoint without recreating the classifier.
///
/// Defaults to the logical width of the implicit view at the time the
/// classifier is first created (after `runApp`). If that width is not usable
/// yet (e.g. zero before the first layout), the classifier logs it and waits
/// for a usable width instead of classifying every tap as a dash. Override in
/// tests to pin a known width.
final screenWidthProvider = Provider<double>((ref) {
  final view = PlatformDispatcher.instance.implicitView;
  if (view == null) return 0;
  return view.physicalSize.width / view.devicePixelRatio;
});

/// Provides the [GestureClassifier] for interpreting touch input.
///
/// The classifier is disposed automatically when the provider is disposed.
///
/// [screenWidthProvider] is deliberately read, not watched: the classifier
/// must never be recreated because of a width change. The teaching
/// orchestrator subscribes to its event stream and [inputBufferProvider]
/// exposes its buffer, so a rebuild would drop both mid-session. Width
/// updates go through [GestureClassifier.screenWidth] instead.
final gestureClassifierProvider = Provider<GestureClassifier>((ref) {
  final config = ref.watch(gestureTimingConfigProvider);
  final screenWidth = ref.read(screenWidthProvider);
  final classifier = GestureClassifier(
    screenWidth: screenWidth,
    config: config,
  );
  ref.onDispose(classifier.dispose);
  return classifier;
});

/// Provides the [GestureClassifier]'s input buffer as a [ValueNotifier].
///
/// Watch this provider to reactively display the accumulated Morse tokens
/// the user has tapped so far. The value is an unmodifiable list that
/// updates on every buffer change (signal added, charGap inserted, cleared).
final inputBufferProvider = Provider<ValueNotifier<List<MorseToken>>>((ref) {
  return ref.watch(gestureClassifierProvider).inputBufferNotifier;
});

/// Provides the [ShakeConfig] used for shake detection.
///
/// Override this provider in tests or to tune threshold values.
final shakeConfigProvider = Provider<ShakeConfig>((ref) => const ShakeConfig());

/// Provides the [ShakeDetector] for detecting device shakes.
///
/// The detector is disposed automatically when the provider is disposed.
final shakeDetectorProvider = Provider<ShakeDetector>((ref) {
  final config = ref.watch(shakeConfigProvider);
  final detector = ShakeDetector(config: config);
  ref.onDispose(detector.dispose);
  return detector;
});
