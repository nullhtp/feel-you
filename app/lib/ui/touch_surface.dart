import 'package:feel_you/gestures/gesture_classifier.dart';
import 'package:feel_you/gestures/gesture_providers.dart';
import 'package:feel_you/teaching/teaching_orchestrator.dart';
import 'package:feel_you/teaching/teaching_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Full-screen touch surface that captures all pointer events and feeds
/// them to the [GestureClassifier].
///
/// Renders a solid black screen with no visual elements. Automatically
/// starts the teaching orchestrator on mount and stops it on dispose.
/// Keeps the screen awake and prevents back-navigation exits.
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

    final classifier = ref.read(gestureClassifierProvider);
    classifier.handleTouch(
      TouchDown(timestamp: event.timeStamp, position: event.position.dx),
    );
  }

  void _onPointerUp(PointerUpEvent event) {
    if (event.pointer != _primaryPointer) return;
    _primaryPointer = null;

    final classifier = ref.read(gestureClassifierProvider);
    classifier.handleTouch(
      TouchUp(timestamp: event.timeStamp, position: event.position.dx),
    );
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (event.pointer != _primaryPointer) return;
    _primaryPointer = null;

    // Treat cancel as a release so the classifier can clean up.
    final classifier = ref.read(gestureClassifierProvider);
    classifier.handleTouch(
      TouchUp(timestamp: event.timeStamp, position: event.position.dx),
    );
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
