import 'package:feel_you/gestures/gestures.dart';
import 'package:feel_you/ui/foreground_shake_listener.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_doubles/fake_shake_detector.dart';

// Shake detection on the screens without a teaching loop (the home menu and
// the picker opened from it) runs only in the foreground, and is handed
// over to the next screen when they navigate away (#41).

/// Simulates the app leaving the foreground, through every state the
/// engine reports on the way.
Future<void> _sendToBackground(WidgetTester tester) async {
  for (final state in const [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
  await tester.pump();
}

/// Simulates the app returning to the foreground.
Future<void> _bringToForeground(WidgetTester tester) async {
  for (final state in const [
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
  await tester.pump();
}

/// A listener on a fresh [FakeShakeDetector], recording what it reports.
class _Harness {
  _Harness({bool startPaused = true}) {
    if (startPaused) detector.pause();
    listener = ForegroundShakeListener(detector, onEvent: events.add);
  }

  final detector = FakeShakeDetector();
  final events = <GestureEvent>[];
  late final ForegroundShakeListener listener;

  void close() {
    listener.dispose();
    detector.dispose();
  }
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized()
        .handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });

  testWidgets('resumes detection the lessons paused', (tester) async {
    final h = _Harness();
    expect(h.detector.isPaused, isFalse);
    h.close();
  });

  testWidgets('forwards shakes in the foreground', (tester) async {
    final h = _Harness();

    h.detector
      ..addEvent(const Home())
      ..addEvent(const ChangeLanguage());
    await tester.pump();

    expect(h.events, [const Home(), const ChangeLanguage()]);
    h.close();
  });

  testWidgets('pauses in the background and drops shakes there', (
    tester,
  ) async {
    final h = _Harness();

    await _sendToBackground(tester);
    expect(h.detector.isPaused, isTrue);

    // A shake still on its way is not forwarded.
    h.detector.addEvent(const ChangeLanguage());
    await tester.pump();
    expect(h.events, isEmpty);

    await _bringToForeground(tester);
    h.close();
  });

  testWidgets('resumes when the app comes back', (tester) async {
    final h = _Harness();
    await _sendToBackground(tester);

    await _bringToForeground(tester);
    expect(h.detector.isPaused, isFalse);

    h.detector.addEvent(const ChangeLanguage());
    await tester.pump();
    expect(h.events, [const ChangeLanguage()]);

    h.close();
  });

  testWidgets('a resume without a trip to the background changes nothing', (
    tester,
  ) async {
    // The app is already inactive when the screen appears, so the listener
    // sees a resume without the trip before it.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    final h = _Harness();
    // Detection paused by someone else meanwhile (the lessons, say): that
    // resume must not resume it.
    h.detector.pause();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(h.detector.isPaused, isTrue);
    h.close();
  });

  testWidgets('after a hand-over nothing is forwarded or resumed', (
    tester,
  ) async {
    final h = _Harness()..listener.handOver();

    h.detector.addEvent(const ChangeLanguage());
    await tester.pump();
    expect(h.events, isEmpty);

    await _sendToBackground(tester);
    expect(h.detector.isPaused, isTrue);
    await _bringToForeground(tester);
    // The next screen resumes detection, not this one.
    expect(h.detector.isPaused, isTrue);

    h.close();
  });

  testWidgets('dispose after a hand-over leaves detection to the next screen', (
    tester,
  ) async {
    final h = _Harness()..listener.handOver();

    h.listener.dispose();

    expect(h.detector.isPaused, isFalse);
    h.detector.dispose();
  });

  testWidgets('dispose without a hand-over pauses detection', (tester) async {
    final h = _Harness();

    h.listener.dispose();

    expect(h.detector.isPaused, isTrue);
    h.detector.dispose();
  });

  testWidgets('nothing is reported after dispose', (tester) async {
    final h = _Harness();
    h.listener.dispose();

    h.detector.addEvent(const ChangeLanguage());
    await _sendToBackground(tester);
    await _bringToForeground(tester);

    expect(h.events, isEmpty);
    // Disposed without a hand-over, it paused detection and never resumes
    // it again.
    expect(h.detector.isPaused, isTrue);
    h.detector.dispose();
  });
}
