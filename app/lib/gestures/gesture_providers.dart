import 'package:feel_you/gestures/gesture_classifier.dart';
import 'package:feel_you/gestures/gesture_timing_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the [GestureTimingConfig] used for gesture classification.
///
/// Override this provider in tests or to tune threshold values.
final gestureTimingConfigProvider = Provider<GestureTimingConfig>(
  (ref) => const GestureTimingConfig(),
);

/// Provides the [GestureClassifier] for interpreting touch input.
///
/// The classifier is disposed automatically when the provider is disposed.
final gestureClassifierProvider = Provider<GestureClassifier>((ref) {
  final config = ref.watch(gestureTimingConfigProvider);
  final classifier = GestureClassifier(config: config);
  ref.onDispose(classifier.dispose);
  return classifier;
});
