import 'dart:async';

import 'package:feel_you/gestures/gesture_event.dart';
import 'package:feel_you/gestures/gesture_timing_config.dart';
import 'package:feel_you/morse/morse.dart';

/// Raw pointer data fed into the classifier.
///
/// Abstracts away Flutter's pointer events so the classifier can be
/// tested without a widget tree.
sealed class RawTouchEvent {
  const RawTouchEvent();
}

/// Finger touched the screen.
class TouchDown extends RawTouchEvent {
  const TouchDown({
    required this.timestamp,
    required this.position,
    this.y = 0,
  });

  final Duration timestamp;
  final double position; // x-coordinate in logical pixels
  final double y; // y-coordinate in logical pixels
}

/// Finger lifted from the screen.
class TouchUp extends RawTouchEvent {
  const TouchUp({required this.timestamp, required this.position, this.y = 0});

  final Duration timestamp;
  final double position; // x-coordinate in logical pixels
  final double y; // y-coordinate in logical pixels
}

/// Classifies raw touch events into [GestureEvent]s.
///
/// Dot/dash classification is position-based: taps on the left half of the
/// screen (x < screenWidth / 2) produce dots; taps on the right half
/// (x >= screenWidth / 2) produce dashes.
///
/// Emits events via a broadcast [Stream]. Manages an internal input buffer
/// and silence timer for input completion detection.
class GestureClassifier {
  GestureClassifier({
    required this.screenWidth,
    this.config = const GestureTimingConfig(),
  });

  /// Screen width in logical pixels, used to determine the dot/dash boundary.
  final double screenWidth;

  final GestureTimingConfig config;

  final _controller = StreamController<GestureEvent>.broadcast();
  final List<MorseSymbol> _inputBuffer = [];
  Timer? _silenceTimer;
  Timer? _resetTimer;

  // Track the current press for tap/hold classification.
  Duration? _pressStartTime;
  double? _pressStartX;
  double? _pressStartY;
  bool _resetEmitted = false;

  /// Stream of classified gesture events.
  Stream<GestureEvent> get events => _controller.stream;

  /// Feed a raw touch event into the classifier.
  void handleTouch(RawTouchEvent event) {
    switch (event) {
      case TouchDown():
        _onTouchDown(event);
      case TouchUp():
        _onTouchUp(event);
    }
  }

  void _onTouchDown(TouchDown event) {
    _pressStartTime = event.timestamp;
    _pressStartX = event.position;
    _pressStartY = event.y;
    _resetEmitted = false;
    _cancelSilenceTimer();

    // Start a timer to detect reset (long hold).
    _resetTimer?.cancel();
    _resetTimer = Timer(Duration(milliseconds: config.resetMinDuration), () {
      _resetEmitted = true;
      _clearBuffer();
      _emit(const Reset());
    });
  }

  void _onTouchUp(TouchUp event) {
    _resetTimer?.cancel();

    final startTime = _pressStartTime;
    final startX = _pressStartX;
    final startY = _pressStartY;
    if (startTime == null || startX == null || startY == null) return;

    _pressStartTime = null;
    _pressStartX = null;
    _pressStartY = null;

    // If reset was already emitted during this press, ignore the release.
    if (_resetEmitted) return;

    final durationMs = (event.timestamp - startTime).inMilliseconds;
    final dx = event.position - startX;
    final dy = event.y - startY;

    // Dominant-axis swipe discrimination: the axis with the larger absolute
    // displacement determines the swipe direction. Equal displacement favors
    // horizontal.
    final isHorizontalDominant = dx.abs() >= dy.abs();

    if (isHorizontalDominant) {
      // Check for horizontal swipe.
      if (_isSwipe(durationMs, dx)) {
        _cancelSilenceTimer();
        _clearBuffer();
        if (dx > 0) {
          _emit(const NavigateNext());
        } else {
          _emit(const NavigatePrevious());
        }
        return;
      }
    } else {
      // Check for vertical swipe.
      if (_isSwipe(durationMs, dy)) {
        _cancelSilenceTimer();
        _clearBuffer();
        if (dy < 0) {
          _emit(const NavigateUp());
        } else {
          _emit(const NavigateDown());
        }
        return;
      }
    }

    // Position-based dot/dash classification.
    // Left half (x < midpoint) = dot, right half (x >= midpoint) = dash.
    // Any non-swipe tap shorter than resetMinDuration is classified.
    final symbol = startX < screenWidth / 2
        ? MorseSymbol.dot
        : MorseSymbol.dash;
    _addSymbol(symbol);
  }

  bool _isSwipe(int durationMs, double dx) {
    final distance = dx.abs();
    if (distance < config.minSwipeDistance) return false;

    // Velocity = distance / time. Guard against zero-duration.
    if (durationMs <= 0) return distance >= config.minSwipeDistance;
    final velocity = distance / (durationMs / 1000.0);
    return velocity >= config.minSwipeVelocity;
  }

  void _addSymbol(MorseSymbol symbol) {
    _inputBuffer.add(symbol);
    _emit(MorseInput(symbol));
    _startSilenceTimer();
  }

  void _startSilenceTimer() {
    _cancelSilenceTimer();

    // After silenceTimeout, emit InputComplete as a fallback.
    _silenceTimer = Timer(Duration(milliseconds: config.silenceTimeout), () {
      if (_inputBuffer.isNotEmpty) {
        // Remove trailing charGap if present (explicitly inserted but no
        // subsequent input arrived before timeout).
        if (_inputBuffer.last == MorseSymbol.charGap) {
          _inputBuffer.removeLast();
        }
        if (_inputBuffer.isNotEmpty) {
          _emit(InputComplete(List.unmodifiable(_inputBuffer)));
        }
        _inputBuffer.clear();
      }
    });
  }

  void _cancelSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceTimer = null;
  }

  void _clearBuffer() {
    _cancelSilenceTimer();
    _inputBuffer.clear();
  }

  /// Cancels the reset (long-hold) timer without emitting any events.
  ///
  /// Called by the UI layer when a bottom-zone tap consumes the pointer
  /// release, preventing the normal [TouchUp] from reaching the classifier.
  void cancelResetTimer() {
    _resetTimer?.cancel();
  }

  /// Inserts a [MorseSymbol.charGap] into the input buffer.
  ///
  /// Does nothing if the buffer is empty (cannot start with a charGap).
  /// Restarts the silence timer after inserting.
  void insertCharGap() {
    if (_inputBuffer.isEmpty) return;
    _inputBuffer.add(MorseSymbol.charGap);
    _startSilenceTimer();
  }

  /// Immediately emits [InputComplete] with the current buffer contents
  /// and clears the buffer. Does nothing if the buffer is empty.
  void submitInput() {
    if (_inputBuffer.isEmpty) return;
    _cancelSilenceTimer();
    _emit(InputComplete(List.unmodifiable(_inputBuffer)));
    _inputBuffer.clear();
  }

  /// Emits an externally-created [GestureEvent] onto the event stream.
  ///
  /// Used by [TouchSurface] to inject [BottomZoneAction] events without
  /// going through the normal touch-classification pipeline.
  void emitEvent(GestureEvent event) => _emit(event);

  void _emit(GestureEvent event) {
    if (!_controller.isClosed) {
      _controller.add(event);
    }
  }

  /// Release resources. After calling this, the classifier should not be used.
  void dispose() {
    _silenceTimer?.cancel();
    _resetTimer?.cancel();
    _controller.close();
  }
}
