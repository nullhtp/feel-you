import 'dart:async';

import 'package:feel_you/gestures/gestures.dart';
import 'package:feel_you/teaching/teaching.dart';
import 'package:feel_you/ui/companion_overlay.dart';
import 'package:feel_you/ui/language_picker_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Full-screen touch surface that captures all pointer events and feeds
/// them to the [GestureClassifier].
///
/// Renders a solid black screen with a [CompanionOverlay] on top for
/// sighted observers. The overlay is wrapped in [IgnorePointer] so all
/// touches pass through to the underlying [Listener].
///
/// Automatically starts the teaching orchestrator on mount and stops it
/// on dispose. Keeps the screen awake and prevents back-navigation exits.
///
/// While the app is not in the foreground (inactive, hidden, paused or
/// detached) the teaching loop is stopped and the wakelock released, so the
/// phone never vibrates in the background. When the app is resumed, the
/// current character is replayed from the beginning.
///
/// The [GestureClassifier] decides what every press means (dot, dash,
/// swipe, [Reset], or a [BottomZoneAction] for a tap in the bottom input
/// zone). This widget only tracks the primary pointer, feeds in the live
/// surface size and forwards the raw pointer events.
class TouchSurface extends ConsumerStatefulWidget {
  const TouchSurface({super.key});

  @override
  ConsumerState<TouchSurface> createState() => _TouchSurfaceState();
}

class _TouchSurfaceState extends ConsumerState<TouchSurface> {
  /// Cached reference to the orchestrator for use in [dispose],
  /// where [ref] is no longer accessible.
  late final TeachingOrchestrator _orchestrator;

  /// The pointer ID of the primary (first) finger currently touching.
  /// Only this pointer's events are forwarded to the classifier.
  /// Additional fingers are ignored to prevent multi-touch interference
  /// with gesture recognition (e.g. reset timer restarts).
  int? _primaryPointer;

  /// Listens for the app moving between foreground and background.
  late final AppLifecycleListener _lifecycleListener;

  /// Whether teaching was suspended because the app left the foreground.
  ///
  /// Ensures teaching is suspended only once per trip to the background
  /// (the app passes through several non-foreground states on the way), and
  /// that a `resumed` notification restarts the loop only if it was
  /// actually suspended.
  bool _suspendedInBackground = false;

  /// Listens to the shake detector for a double shake ([ChangeLanguage]).
  late final StreamSubscription<GestureEvent> _shakeSubscription;

  @override
  void initState() {
    super.initState();
    _orchestrator = ref.read(teachingOrchestratorProvider.notifier);
    _lifecycleListener = AppLifecycleListener(
      onStateChange: _onAppLifecycleStateChanged,
    );
    _shakeSubscription = ref
        .read(shakeDetectorProvider)
        .events
        .listen(_onShakeEvent);
    WakelockPlus.enable();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _orchestrator.start();
    });
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    unawaited(_shakeSubscription.cancel());
    WakelockPlus.disable();
    _orchestrator.stop();
    super.dispose();
  }

  /// Leaves the session for the [LanguagePickerSurface] on a double shake
  /// ([ChangeLanguage]).
  ///
  /// Like every gesture, it is ignored while the teaching loop is stopped
  /// (in the background, or before the loop first starts). The loop is
  /// stopped right away, so nothing vibrates during the route transition;
  /// [dispose] stops it again (a no-op) when this route is removed.
  void _onShakeEvent(GestureEvent event) {
    if (event is! ChangeLanguage || !mounted) return;
    if (!ref.read(teachingOrchestratorProvider).isRunning) return;
    unawaited(_orchestrator.stop());
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const LanguagePickerSurface()),
    );
  }

  void _onAppLifecycleStateChanged(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _resumeTeaching();
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _suspendTeaching();
    }
  }

  /// Stops the teaching loop and releases the wakelock when the app leaves
  /// the foreground (incoming call, home button, screen lock, ...).
  ///
  /// [TeachingOrchestrator.stop] cancels any ongoing vibration and the
  /// pause between repetitions, so nothing vibrates in the background.
  void _suspendTeaching() {
    if (_suspendedInBackground) return;
    _suspendedInBackground = true;
    _abandonActivePress();
    WakelockPlus.disable();
    _orchestrator.stop();
  }

  /// Re-acquires the wakelock and restarts the teaching loop when the app
  /// returns to the foreground. The current character is replayed from the
  /// beginning.
  void _resumeTeaching() {
    if (!_suspendedInBackground) return;
    _suspendedInBackground = false;
    WakelockPlus.enable();
    _orchestrator.start();
  }

  /// Drops a press that is still in progress when the app leaves the
  /// foreground.
  ///
  /// The release for that pointer may never arrive, or may arrive long after
  /// the app returns. The press is therefore abandoned rather than
  /// classified: tracking is cleared so a late up/cancel for the old pointer
  /// is ignored, and a [TouchCancel] is sent instead of a [TouchUp], so it
  /// does not count as a dot, dash or swipe. The cancel also stops the
  /// classifier's long-hold timer so it cannot emit a [Reset] in the
  /// background, which would restart the teaching loop.
  void _abandonActivePress() {
    if (_primaryPointer == null) return;
    _primaryPointer = null;
    ref.read(gestureClassifierProvider).handleTouch(const TouchCancel());
  }

  void _onPointerDown(PointerDownEvent event) {
    // Only track the first finger; ignore additional touches.
    if (_primaryPointer != null) return;
    _primaryPointer = event.pointer;

    // Feed the live view size first (event.position is in view coordinates)
    // so the dot/dash midpoint and the bottom input zone follow
    // split-screen, foldables, rotation and display-size changes. This
    // updates the existing classifier in place; it is never recreated.
    final size = MediaQuery.sizeOf(context);
    ref.read(gestureClassifierProvider)
      ..screenWidth = size.width
      ..screenHeight = size.height
      ..handleTouch(
        TouchDown(
          timestamp: event.timeStamp,
          position: event.position.dx,
          y: event.position.dy,
        ),
      );
  }

  void _onPointerUp(PointerUpEvent event) {
    if (event.pointer != _primaryPointer) return;
    _primaryPointer = null;

    ref
        .read(gestureClassifierProvider)
        .handleTouch(
          TouchUp(
            timestamp: event.timeStamp,
            position: event.position.dx,
            y: event.position.dy,
          ),
        );
  }

  /// Drops the primary press when the OS takes over the pointer (edge
  /// back/home gesture, notification shade, Control Center, incoming-call
  /// screen).
  ///
  /// The touch was not meant for the app, so the classifier gets a
  /// [TouchCancel] rather than a [TouchUp]: it cleans up without producing a
  /// dot, dash or swipe, and its pending [Reset] never fires. A cancel in
  /// the bottom zone likewise emits no [BottomZoneAction].
  void _onPointerCancel(PointerCancelEvent event) {
    if (event.pointer != _primaryPointer) return;
    _primaryPointer = null;

    ref.read(gestureClassifierProvider).handleTouch(const TouchCancel());
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Listener(
              onPointerDown: _onPointerDown,
              onPointerUp: _onPointerUp,
              onPointerCancel: _onPointerCancel,
              behavior: HitTestBehavior.opaque,
              // Describes the input area to screen readers. It also names the
              // route, so the surface is announced when the screen opens.
              //
              // Limitation: while TalkBack or VoiceOver is on, the screen
              // reader consumes single taps and swipes for exploration, so
              // they never reach this Listener. Flutter does not expose iOS's
              // "allows direct interaction" trait (VoiceOver Direct Touch) and
              // Android has no app-settable equivalent, so there is no way to
              // opt this area out. Users can use the screen reader's
              // pass-through gesture (double tap and hold, then gesture) or
              // turn the screen reader off. With no semantic tap action, a
              // screen-reader double tap is expected to fall back to a
              // synthesised tap at the centre of the focused node (screen
              // centre here), which the classifier reads as a dash.
              child: Semantics(
                container: true,
                namesRoute: true,
                label: 'Morse input surface',
                hint:
                    'Tap the left half for a dot and the right half for a '
                    'dash. Tap the bottom strip to submit, or to add a letter '
                    'gap on word levels. Swipe left or right to change '
                    'character, up or down to change level.',
                child: const SizedBox.expand(),
              ),
            ),
            const CompanionOverlay(),
          ],
        ),
      ),
    );
  }
}
