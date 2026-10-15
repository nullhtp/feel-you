import 'dart:async';

import 'package:feel_you/gestures/gesture_event.dart';
import 'package:feel_you/gestures/gesture_timing_config.dart';
import 'package:feel_you/morse/morse.dart';
import 'package:flutter/foundation.dart';

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

/// The press in progress ended without a real release.
///
/// Sent when the OS takes over the pointer (edge back/home gesture,
/// notification shade, Control Center, incoming-call screen), or when the
/// UI abandons a press, for example because the app left the foreground.
///
/// Unlike [TouchUp], a cancelled press is never classified: it produces no
/// dot, dash, swipe or other [GestureEvent], so it carries no position or
/// timestamp.
class TouchCancel extends RawTouchEvent {
  const TouchCancel();
}

/// Classifies raw touch events into [GestureEvent]s.
///
/// Dot/dash classification is position-based: taps on the left half of the
/// screen (x < screenWidth / 2) produce dots; taps on the right half
/// (x >= screenWidth / 2) produce dashes.
///
/// The width is mutable via [screenWidth] so the UI can feed in the live
/// layout width (split-screen, foldables, rotation, display-size changes)
/// without recreating the classifier and losing its stream subscribers,
/// input buffer and timers.
///
/// Emits events via a broadcast [Stream]. Manages an internal input buffer
/// and silence timer for input completion detection.
class GestureClassifier {
  /// Creates a classifier with an initial [screenWidth] in logical pixels.
  ///
  /// An unusable initial width (zero, negative or non-finite) is logged, and
  /// dot/dash taps are then dropped until a usable width is set rather than
  /// being misclassified.
  GestureClassifier({
    required double screenWidth,
    this.config = const GestureTimingConfig(),
  }) : _screenWidth = screenWidth {
    if (!_isUsableWidth(screenWidth)) {
      debugPrint(
        'GestureClassifier: initial screen width $screenWidth is unusable; '
        'dot/dash taps are dropped until a usable width is set.',
      );
    }
  }

  double _screenWidth;

  /// Screen width in logical pixels, used to determine the dot/dash boundary.
  ///
  /// Set this whenever the touch surface width may have changed. Unusable
  /// values (zero, negative or non-finite) are rejected with a [debugPrint]
  /// and the last usable width is kept, so a transient zero-size layout can
  /// never make every tap a dash.
  double get screenWidth => _screenWidth;

  set screenWidth(double value) {
    if (!_isUsableWidth(value)) {
      debugPrint(
        'GestureClassifier: ignoring unusable screen width $value; '
        'keeping $_screenWidth.',
      );
      return;
    }
    _screenWidth = value;
  }

  static bool _isUsableWidth(double width) => width.isFinite && width > 0;

  final GestureTimingConfig config;

  final _controller = StreamController<GestureEvent>.broadcast();
  final List<MorseToken> _inputBuffer = [];
  Timer? _silenceTimer;
  Timer? _resetTimer;

  /// Notifies listeners whenever the input buffer changes.
  ///
  /// Emits an unmodifiable copy of the current buffer contents.
  /// Used by the companion overlay to display accumulated user input.
  final ValueNotifier<List<MorseToken>> inputBufferNotifier = ValueNotifier(
    const [],
  );

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
      case TouchCancel():
        _onTouchCancel();
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

    // Only reachable if no usable width was ever provided (the setter keeps
    // the last usable one). The midpoint is then unknown, and with width 0
    // every tap would silently become a dash, so drop the tap and log.
    if (!_isUsableWidth(_screenWidth)) {
      debugPrint(
        'GestureClassifier: dropping tap at x=$startX, no usable screen '
        'width (got $_screenWidth).',
      );
      return;
    }

    // Position-based dot/dash classification.
    // Left half (x < midpoint) = dot, right half (x >= midpoint) = dash.
    // Any non-swipe tap shorter than resetMinDuration is classified.
    final signal = startX < _screenWidth / 2
        ? MorseSignal.dot
        : MorseSignal.dash;
    _addSignal(signal);
  }

  /// Drops the press in progress without classifying it.
  ///
  /// Cancels the long-hold timer, so no [Reset] fires later, and clears the
  /// press state, so a stray [TouchUp] is ignored. Emits no event and leaves
  /// the input buffer as it is: signals already in it came from completed
  /// taps and still complete normally.
  ///
  /// [_onTouchDown] stopped the silence timer, so it is restarted when the
  /// buffer is not empty. Otherwise that input would never be completed.
  ///
  /// If a [Reset] was already emitted during this press, it stands (the
  /// buffer was cleared then) and the cancel only cleans up, as a release
  /// would. A cancel with no press in progress does nothing.
  void _onTouchCancel() {
    _resetTimer?.cancel();
    if (_pressStartTime == null) return;

    _pressStartTime = null;
    _pressStartX = null;
    _pressStartY = null;
    _resetEmitted = false;

    if (_inputBuffer.isNotEmpty) _startSilenceTimer();
  }

  bool _isSwipe(int durationMs, double dx) {
    final distance = dx.abs();
    if (distance < config.minSwipeDistance) return false;

    // Velocity = distance / time. Guard against zero-duration.
    if (durationMs <= 0) return distance >= config.minSwipeDistance;
    final velocity = distance / (durationMs / 1000.0);
    return velocity >= config.minSwipeVelocity;
  }

  void _notifyBufferChanged() {
    inputBufferNotifier.value = List.unmodifiable(_inputBuffer);
  }

  void _addSignal(MorseSignal signal) {
    _inputBuffer.add(Signal(signal));
    _notifyBufferChanged();
    _emit(MorseInput(signal));
    _startSilenceTimer();
  }

  void _startSilenceTimer() {
    _cancelSilenceTimer();

    // After silenceTimeout, emit InputComplete as a fallback.
    _silenceTimer = Timer(Duration(milliseconds: config.silenceTimeout), () {
      if (_inputBuffer.isNotEmpty) {
        // Remove trailing charGap if present (explicitly inserted but no
        // subsequent input arrived before timeout).
        if (_inputBuffer.last is CharGap) {
          _inputBuffer.removeLast();
        }
        if (_inputBuffer.isNotEmpty) {
          _emit(InputComplete(List.unmodifiable(_inputBuffer)));
        }
        _inputBuffer.clear();
        _notifyBufferChanged();
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
    _notifyBufferChanged();
  }

  /// Cancels the reset (long-hold) timer without emitting any events.
  ///
  /// Called by the UI layer when a bottom-zone tap consumes the pointer
  /// release, preventing the normal [TouchUp] from reaching the classifier.
  void cancelResetTimer() {
    _resetTimer?.cancel();
  }

  /// Inserts a [CharGap] token into the input buffer.
  ///
  /// Does nothing if the buffer is empty (cannot start with a charGap).
  /// Restarts the silence timer after inserting.
  void insertCharGap() {
    if (_inputBuffer.isEmpty) return;
    _inputBuffer.add(const CharGap());
    _notifyBufferChanged();
    _startSilenceTimer();
  }

  /// Immediately emits [InputComplete] with the current buffer contents
  /// and clears the buffer. Does nothing if the buffer is empty.
  void submitInput() {
    if (_inputBuffer.isEmpty) return;
    _cancelSilenceTimer();
    _emit(InputComplete(List.unmodifiable(_inputBuffer)));
    _inputBuffer.clear();
    _notifyBufferChanged();
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
    inputBufferNotifier.dispose();
  }
}
