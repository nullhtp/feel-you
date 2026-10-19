import 'dart:async';

import 'package:feel_you/teaching/teaching.dart';
import 'package:feel_you/vibration/vibration.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How long a press must last to choose the highlighted option.
const chooserHoldDuration = Duration(seconds: 1);

/// Shortest horizontal drag that moves the highlight, in logical pixels.
///
/// The same as the lessons' default swipe distance
/// (`GestureTimingConfig.minSwipeDistance`). A shorter drag replays the
/// highlighted identifier instead, so no gesture goes unanswered.
const double chooserMinSwipeDistance = 50;

/// The touch chooser shared by the screens that offer a row of options to a
/// user who cannot see them: the home menu (modes), the language picker
/// (languages) and, later, the settings list (#45).
///
/// One option is highlighted at a time, starting with [initialOption], and
/// every touch gesture is answered with the identifier vibration
/// ([playIdentifier]) of the option it leaves highlighted:
///
/// - When the screen appears, once vibration detection has finished on a
///   device that can vibrate, the highlighted identifier plays once.
/// - Tap ([highlight], wired to each [ChooserColumn]): highlights the
///   option under the finger.
/// - Swipe right / left of at least [chooserMinSwipeDistance], anywhere:
///   highlights the next / previous option, wrapping around. A shorter
///   drag replays the highlighted identifier.
/// - Hold for [chooserHoldDuration], anywhere: chooses the highlighted
///   option, i.e. the last identifier felt ([choose]).
///
/// Choosing plays the option's identifier. The screen's [onChosen] runs only
/// once it has finished and `TeachingTimingConfig.postFeedbackPause` has
/// passed, so the next screen's first vibration never cuts the identifier
/// short (on Android a new vibration replaces the one in progress) or runs
/// straight into it. From the moment an option is chosen, or the screen
/// starts leaving another way ([tryLeave]), every gesture is ignored.
///
/// While the app is not in the foreground nothing vibrates: leaving it
/// (inactive, hidden, paused or detached, once per trip) cancels an
/// identifier in progress, and coming back replays the highlighted
/// identifier, unless the screen is choosing or leaving. A chooser does not
/// keep the screen on.
///
/// What stays with each screen: its options and how they are identified
/// (the codec), the column contents, the helper's hint line, the
/// screen-reader semantics (whose activation calls [choose] directly), and
/// shakes.
mixin Chooser<W extends ConsumerStatefulWidget, T> on ConsumerState<W> {
  /// The options, in the order the screen shows them, left to right.
  @protected
  List<T> get options;

  /// The option highlighted when the screen appears. Read once, in
  /// [initState].
  @protected
  T get initialOption;

  /// Vibrates [option]'s identifier and completes when it has finished.
  @protected
  Future<void> playIdentifier(T option);

  /// Called when [option] has been chosen, its identifier has finished and
  /// the silence after it has passed, while the screen is still shown on a
  /// device that can vibrate. The screen usually replaces itself here.
  @protected
  void onChosen(T option);

  /// The option a hold chooses.
  late T _highlighted;

  /// Horizontal distance covered by the current swipe.
  double _swipeDistance = 0;

  /// Whether an option has been chosen or the screen is leaving. A second
  /// confirmation during the wait or the route transition (another hold, a
  /// screen-reader tap, a shake) must neither vibrate nor choose again.
  bool _busy = false;

  /// Whether the app is out of the foreground. The app passes through
  /// several non-foreground states on its way to the background; this makes
  /// sure each trip is handled once.
  bool _inBackground = false;

  late final AppLifecycleListener _lifecycleListener;

  /// The option highlighted now: the one a hold chooses.
  @protected
  T get highlighted => _highlighted;

  /// Whether the device may vibrate. False once detection has found no
  /// motor, just before the `VibrationGate` replaces the screen.
  @protected
  bool get canVibrate =>
      ref.read(effectiveVibrationCapabilitiesProvider).canVibrate;

  @override
  void initState() {
    super.initState();
    _highlighted = initialOption;
    _lifecycleListener = AppLifecycleListener(
      onStateChange: _onAppLifecycleStateChanged,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_announceHighlighted());
    });
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  /// Plays the highlighted identifier once when the screen appears.
  ///
  /// Waits for capability detection first, so a device without a vibration
  /// motor (which gets the `NoVibrationScreen`) is never asked to vibrate.
  Future<void> _announceHighlighted() async {
    if (!mounted) return;
    await ref.read(vibrationCapabilitiesProvider.future);
    if (!mounted || _busy || !canVibrate) return;
    unawaited(playIdentifier(_highlighted));
  }

  /// Highlights [option] and vibrates its identifier.
  @protected
  void highlight(T option) {
    if (_busy || !canVibrate) return;
    setState(() => _highlighted = option);
    unawaited(playIdentifier(option));
  }

  /// Vibrates the highlighted identifier again, so the user feels where
  /// they are.
  @protected
  void replayHighlighted() => highlight(_highlighted);

  /// Highlights the option [step] places away, wrapping around.
  void _moveHighlight(int step) {
    final options = this.options;
    final index = (options.indexOf(_highlighted) + step) % options.length;
    highlight(options[index]);
  }

  void _onSwipeStart(DragStartDetails details) => _swipeDistance = 0;

  void _onSwipeUpdate(DragUpdateDetails details) =>
      _swipeDistance += details.primaryDelta ?? 0;

  void _onSwipeEnd(DragEndDetails details) {
    if (_swipeDistance.abs() < chooserMinSwipeDistance) {
      // Too short to move the highlight: replay where the user still is.
      replayHighlighted();
      return;
    }
    // Swipe right moves to the next option, as it moves to the next item in
    // the lessons.
    _moveHighlight(_swipeDistance > 0 ? 1 : -1);
  }

  /// Chooses [option]: vibrates its identifier, then, after the silence
  /// that follows feedback in the lessons, calls [onChosen].
  ///
  /// Ignored while the screen is already choosing or leaving, and on a
  /// device that cannot vibrate (a tap that lands just before the switch to
  /// the `NoVibrationScreen`).
  @protected
  Future<void> choose(T option) async {
    if (!canVibrate || _busy) return;
    _busy = true;
    setState(() => _highlighted = option);

    final pause = ref.read(teachingTimingConfigProvider).postFeedbackPause;
    await playIdentifier(option);
    await Future<void>.delayed(pause);
    // Detection may have found no motor meanwhile: the VibrationGate then
    // replaces the screen, and nothing is chosen.
    if (!mounted || !canVibrate) return;
    onChosen(option);
  }

  /// Claims the screen for leaving without a choice (the picker's double
  /// shake back to the menu): from now on every gesture is ignored, as
  /// after a choice.
  ///
  /// Returns false, and claims nothing, while an option is being chosen or
  /// the screen is already leaving, and on a device that cannot vibrate.
  @protected
  bool tryLeave() {
    if (_busy || !canVibrate) return false;
    _busy = true;
    return true;
  }

  void _onAppLifecycleStateChanged(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (!_inBackground) return;
        _inBackground = false;
        // Tells a user who comes back (after a call, or with the screen
        // locked) where they are. Ignored while choosing or leaving.
        if (mounted) replayHighlighted();
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        if (_inBackground) return;
        _inBackground = true;
        // Nothing vibrates in the background.
        unawaited(ref.read(vibrationServiceProvider).cancel());
    }
  }

  /// The chooser's screen around [child]: black, closed by no back gesture
  /// (the Android back button, the iOS edge swipe), and with the swipes and
  /// the hold working anywhere on it.
  ///
  /// Swipes and the hold are touch gestures only: screen readers use the
  /// per-option buttons the screen builds.
  @protected
  Widget buildChooser({required Widget child}) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: RawGestureDetector(
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          gestures: {
            HorizontalDragGestureRecognizer:
                GestureRecognizerFactoryWithHandlers<
                  HorizontalDragGestureRecognizer
                >(() => HorizontalDragGestureRecognizer(debugOwner: this), (
                  recognizer,
                ) {
                  recognizer
                    // Measure the swipe from the touch-down point.
                    ..dragStartBehavior = DragStartBehavior.down
                    ..onStart = _onSwipeStart
                    ..onUpdate = _onSwipeUpdate
                    ..onEnd = _onSwipeEnd;
                }),
            LongPressGestureRecognizer:
                GestureRecognizerFactoryWithHandlers<
                  LongPressGestureRecognizer
                >(
                  () => LongPressGestureRecognizer(
                    duration: chooserHoldDuration,
                    debugOwner: this,
                  ),
                  (recognizer) {
                    recognizer.onLongPress = () =>
                        unawaited(choose(_highlighted));
                  },
                ),
          },
          child: child,
        ),
      ),
    );
  }
}

/// One column of a [Chooser]: [child] centred in a rounded frame, drawn
/// inverted (white) while [highlighted], scaled down to fit.
///
/// A tap anywhere in the column, including under the hint line, calls
/// [onTap], which highlights the column's option. The frame leaves room at
/// the bottom for the hint line. The column adds no semantics of its own:
/// the screen wraps it in its button node.
class ChooserColumn extends StatelessWidget {
  const ChooserColumn({
    required this.highlighted,
    required this.onTap,
    required this.child,
    super.key,
  });

  /// Whether the column's option is highlighted.
  final bool highlighted;

  /// Called on a tap anywhere in the column.
  final VoidCallback onTap;

  /// The option's contents. The screen draws them black while
  /// [highlighted] and white otherwise, to match the frame.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        // The bottom padding keeps the hint line clear.
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 64),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: highlighted ? Colors.white : Colors.black,
            border: Border.all(
              color: highlighted ? Colors.white : Colors.white24,
              width: 3,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: FittedBox(fit: BoxFit.scaleDown, child: child),
            ),
          ),
        ),
      ),
    );
  }
}
