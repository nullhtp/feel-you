import 'dart:async';

import 'package:feel_you/gestures/gestures.dart';
import 'package:flutter/widgets.dart';

/// Shake detection for a screen that has no teaching loop: the home menu,
/// and the language picker opened from it.
///
/// In the lessons the `TeachingOrchestrator` resumes shake detection when
/// its loop starts and pauses it when the loop stops, which also happens
/// when the user double-shakes out of the lessons. A screen without a loop
/// uses this listener instead:
///
/// - On creation it resumes detection and subscribes to [ShakeDetector.events].
/// - When the app leaves the foreground (inactive, hidden, paused or
///   detached, as for the lessons) it pauses detection, so the accelerometer
///   is off and no shake acts in the background. When the app is resumed it
///   resumes detection. What the screen itself does in the background (the
///   home menu and the picker cancel their identifier) is up to the screen.
/// - It forwards events to [onEvent] only while the app is in the
///   foreground.
/// - [handOver] is called right before the screen navigates to the next
///   one. From then on nothing is forwarded and detection is never resumed
///   again: the next screen owns it.
/// - [dispose] pauses detection only if the screen never handed over (it
///   was removed by the `VibrationGate`, say). After a hand-over the next
///   screen has already mounted and may have resumed detection, since the
///   outgoing route is disposed only when its transition ends.
class ForegroundShakeListener {
  /// Starts listening to the given detector for the screen that creates it.
  ForegroundShakeListener(this._detector, {required this.onEvent}) {
    _detector.resume();
    _subscription = _detector.events.listen(_onDetectorEvent);
    _lifecycleListener = AppLifecycleListener(
      onStateChange: _onAppLifecycleStateChanged,
    );
  }

  final ShakeDetector _detector;

  /// Called with every shake event ([Home], [ChangeLanguage]) detected
  /// while the app is in the foreground, until [handOver].
  final void Function(GestureEvent event) onEvent;

  late final StreamSubscription<GestureEvent> _subscription;
  late final AppLifecycleListener _lifecycleListener;

  /// Whether the app is out of the foreground, so detection is paused.
  ///
  /// The app passes through several non-foreground states on its way to
  /// the background; this makes sure it is handled once per trip.
  bool _inBackground = false;

  /// Whether the screen has navigated away (see [handOver]).
  bool _handedOver = false;

  /// Stops forwarding events and resuming detection, because the screen is
  /// navigating to another one that owns shake detection from now on.
  void handOver() => _handedOver = true;

  void _onDetectorEvent(GestureEvent event) {
    if (_inBackground || _handedOver) return;
    onEvent(event);
  }

  void _onAppLifecycleStateChanged(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (!_inBackground) return;
        _inBackground = false;
        if (_handedOver) return;
        _detector.resume();
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        if (_inBackground) return;
        _inBackground = true;
        _detector.pause();
    }
  }

  /// Stops listening. Pauses detection unless the screen handed over.
  void dispose() {
    _lifecycleListener.dispose();
    unawaited(_subscription.cancel());
    if (!_handedOver) _detector.pause();
  }
}
