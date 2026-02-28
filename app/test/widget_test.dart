import 'dart:async';

import 'package:feel_you/app.dart';
import 'package:feel_you/gestures/gesture_classifier.dart';
import 'package:feel_you/gestures/gesture_event.dart';
import 'package:feel_you/gestures/gesture_providers.dart';
import 'package:feel_you/morse/morse_symbol.dart';
import 'package:feel_you/teaching/teaching_providers.dart';
import 'package:feel_you/teaching/teaching_timing_config.dart';
import 'package:feel_you/ui/touch_surface.dart';
import 'package:feel_you/vibration/vibration_providers.dart';
import 'package:feel_you/vibration/vibration_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _testRepeatPause = Duration(seconds: 5);

// Minimal test doubles to satisfy provider dependencies.
class _MockVibrationService implements VibrationService {
  @override
  Future<void> playMorsePattern(List<MorseSymbol> symbols) async {}
  @override
  Future<void> playSuccess() async {}
  @override
  Future<void> playError() async {}
  @override
  Future<void> cancel() async {}
}

class _StubGestureClassifier extends GestureClassifier {
  _StubGestureClassifier() : super(screenWidth: 800);
  final _controller = StreamController<GestureEvent>.broadcast();
  @override
  Stream<GestureEvent> get events => _controller.stream;
  @override
  void handleTouch(RawTouchEvent event) {}
  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }
}

void main() {
  testWidgets('App renders TouchSurface as home', (tester) async {
    final classifier = _StubGestureClassifier();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gestureClassifierProvider.overrideWithValue(classifier),
          vibrationServiceProvider.overrideWithValue(_MockVibrationService()),
          teachingTimingConfigProvider.overrideWithValue(
            const TeachingTimingConfig(repeatPause: _testRepeatPause),
          ),
        ],
        child: const FeelYouApp(),
      ),
    );

    expect(find.byType(TouchSurface), findsOneWidget);

    // Clean up: stop orchestrator, remove widget tree, flush timers.
    final element = tester.element(find.byType(TouchSurface));
    final container = ProviderScope.containerOf(element);
    await container.read(teachingOrchestratorProvider.notifier).stop();
    await tester.pumpWidget(const SizedBox());
    await tester.pump(_testRepeatPause);

    classifier.dispose();
  });
}
