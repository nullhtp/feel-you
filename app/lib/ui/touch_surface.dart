import 'package:feel_you/gestures/gestures.dart';
import 'package:feel_you/teaching/teaching.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Fraction of the screen height reserved for the bottom input zone.
/// Taps in the lower [_bottomZoneFraction] of the screen are treated as
/// bottom-zone actions instead of dot/dash input.
const _bottomZoneFraction = 0.15;

/// Full-screen touch surface that captures all pointer events and feeds
/// them to the [GestureClassifier].
///
/// Renders a solid black screen with no visual elements. Automatically
/// starts the teaching orchestrator on mount and stops it on dispose.
/// Keeps the screen awake and prevents back-navigation exits.
///
/// The lower 15% of the screen is a bottom input zone. Short taps there
/// emit [BottomZoneAction] with haptic feedback; swipes and long holds
/// are forwarded to the classifier normally.
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

  // Track press start state for bottom-zone swipe detection.
  double? _pressStartX;
  double? _pressStartY;
  Duration? _pressStartTime;
  bool _resetEmittedDuringPress = false;

  @override
  void initState() {
    super.initState();
    _orchestrator = ref.read(teachingOrchestratorProvider.notifier);
    WakelockPlus.enable();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _orchestrator.start();
    });
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _orchestrator.stop();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    // Only track the first finger; ignore additional touches.
    if (_primaryPointer != null) return;
    _primaryPointer = event.pointer;

    // Track start state for bottom-zone detection.
    _pressStartX = event.position.dx;
    _pressStartY = event.position.dy;
    _pressStartTime = event.timeStamp;
    _resetEmittedDuringPress = false;

    // Always forward TouchDown to the classifier (for reset timer, etc.).
    final classifier = ref.read(gestureClassifierProvider);
    classifier.handleTouch(
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

    final startX = _pressStartX;
    final startY = _pressStartY;
    final startTime = _pressStartTime;
    _pressStartX = null;
    _pressStartY = null;
    _pressStartTime = null;

    if (startX == null || startY == null || startTime == null) {
      // Shouldn't happen, but forward to classifier as fallback.
      _forwardTouchUp(event);
      return;
    }

    final screenHeight = MediaQuery.of(context).size.height;
    final bottomZoneBoundary = screenHeight * (1 - _bottomZoneFraction);

    // Check if the release is in the bottom zone.
    if (startY >= bottomZoneBoundary) {
      // Started in bottom zone — check if it's a swipe or a tap.
      final durationMs = (event.timeStamp - startTime).inMilliseconds;
      final dx = event.position.dx - startX;
      final dy = event.position.dy - startY;
      final config = ref.read(gestureClassifierProvider).config;

      if (_isSwipe(durationMs, dx, dy, config) || _resetEmittedDuringPress) {
        // Swipe or reset: forward to classifier for normal handling.
        _forwardTouchUp(event);
      } else {
        // Short tap in bottom zone: emit BottomZoneAction.
        // We skip sending TouchUp to avoid dot/dash classification, but
        // must cancel the reset timer that started on TouchDown — otherwise
        // it fires 2s later and interrupts playback with a spurious Reset.
        final classifier = ref.read(gestureClassifierProvider);
        classifier.cancelResetTimer();
        classifier.emitEvent(const BottomZoneAction());
      }
    } else {
      // Upper zone: forward to classifier as before.
      _forwardTouchUp(event);
    }

    _resetEmittedDuringPress = false;
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (event.pointer != _primaryPointer) return;
    _primaryPointer = null;
    _pressStartX = null;
    _pressStartY = null;
    _pressStartTime = null;
    _resetEmittedDuringPress = false;

    // Treat cancel as a release so the classifier can clean up.
    final classifier = ref.read(gestureClassifierProvider);
    classifier.handleTouch(
      TouchUp(
        timestamp: event.timeStamp,
        position: event.position.dx,
        y: event.position.dy,
      ),
    );
  }

  void _forwardTouchUp(PointerUpEvent event) {
    final classifier = ref.read(gestureClassifierProvider);
    classifier.handleTouch(
      TouchUp(
        timestamp: event.timeStamp,
        position: event.position.dx,
        y: event.position.dy,
      ),
    );
  }

  /// Replicates the swipe detection logic from [GestureClassifier]._isSwipe
  /// to determine if a bottom-zone touch was a swipe.
  bool _isSwipe(
    int durationMs,
    double dx,
    double dy,
    GestureTimingConfig config,
  ) {
    // Use dominant axis, same as classifier.
    final isHorizontalDominant = dx.abs() >= dy.abs();
    final displacement = isHorizontalDominant ? dx : dy;
    final distance = displacement.abs();
    if (distance < config.minSwipeDistance) return false;
    if (durationMs <= 0) return distance >= config.minSwipeDistance;
    final velocity = distance / (durationMs / 1000.0);
    return velocity >= config.minSwipeVelocity;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Listener(
          onPointerDown: _onPointerDown,
          onPointerUp: _onPointerUp,
          onPointerCancel: _onPointerCancel,
          behavior: HitTestBehavior.opaque,
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}
