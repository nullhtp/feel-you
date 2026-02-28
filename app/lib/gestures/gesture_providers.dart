import 'package:feel_you/gestures/gesture_classifier.dart';
import 'package:feel_you/gestures/gesture_timing_config.dart';
import 'package:feel_you/gestures/shake_config.dart';
import 'package:feel_you/gestures/shake_detector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the [GestureTimingConfig] used for gesture classification.
///
/// Override this provider in tests or to tune threshold values.
final gestureTimingConfigProvider = Provider<GestureTimingConfig>(
  (ref) => const GestureTimingConfig(),
);

/// Provides the screen width in logical pixels for position-based
/// dot/dash classification.
///
/// Must be overridden with the actual screen width before the
/// [gestureClassifierProvider] is read. In the app, [TouchSurface]
/// sets this via a provider override. In tests, override directly.
final screenWidthProvider = Provider<double>(
  (ref) => throw UnimplementedError(
    'screenWidthProvider must be overridden with the actual screen width.',
  ),
);

/// Provides the [GestureClassifier] for interpreting touch input.
///
/// The classifier is disposed automatically when the provider is disposed.
final gestureClassifierProvider = Provider<GestureClassifier>((ref) {
  final config = ref.watch(gestureTimingConfigProvider);
  final screenWidth = ref.watch(screenWidthProvider);
  final classifier = GestureClassifier(
    screenWidth: screenWidth,
    config: config,
  );
  ref.onDispose(classifier.dispose);
  return classifier;
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
