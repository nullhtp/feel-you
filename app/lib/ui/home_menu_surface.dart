import 'dart:async';

import 'package:feel_you/gestures/gestures.dart';
import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/tactile/tactile.dart';
import 'package:feel_you/teaching/teaching.dart';
import 'package:feel_you/ui/foreground_shake_listener.dart';
import 'package:feel_you/ui/home_menu_mode.dart';
import 'package:feel_you/ui/language_picker_surface.dart';
import 'package:feel_you/ui/no_vibration_screen.dart';
import 'package:feel_you/ui/touch_surface.dart';
import 'package:feel_you/vibration/vibration.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shortest horizontal drag that moves the highlight, in logical pixels.
///
/// The same as the language picker's and the lessons' default swipe
/// distance. A shorter drag replays the highlighted identifier instead, so
/// no gesture goes unanswered.
const double _minSwipeDistance = 50;

/// Visible instructions for a sighted helper.
const _helperHint =
    'Tap or swipe to a mode, then hold anywhere for 1 second to open it';

/// Name of the menu's route for screen readers.
const _routeName = 'Home menu';

/// The home menu: one column per [HomeMenuMode], left to right.
///
/// Shown on launch when a language is saved, after a language is chosen in
/// the picker, and after a double shake in a mode. It works like the
/// language picker: one mode is highlighted at a time ([highlighted] when
/// the menu appears), and every touch gesture is answered with the
/// identifier vibration (the mode's Morse letter) of the mode it leaves
/// highlighted:
///
/// - When the menu appears, and when the app comes back to the foreground,
///   the highlighted identifier plays once.
/// - Tap: highlights the mode under the finger and vibrates its identifier.
/// - Swipe right / left: highlights the next / previous mode, wrapping
///   around. A shorter drag replays the highlighted identifier.
/// - Hold for [confirmHoldDuration], anywhere: enters the highlighted mode,
///   i.e. the last identifier felt.
/// - Double shake ([ChangeLanguage]): replays the highlighted identifier, so
///   a user who double-shakes to get here feels where they are. A single
///   shake ([Home]) does nothing: it is the lessons' way home, and ignoring
///   it means a double shake is answered once, not twice.
///
/// Entering a mode vibrates its identifier. Once it has finished, plus the
/// same short silence the language picker waits for, the menu is replaced
/// with the mode's screen. Until then every gesture is ignored.
///
/// Shakes are detected only while the app is in the foreground (see
/// [ForegroundShakeListener]); leaving the foreground also cancels an
/// identifier in progress. Like the picker, the menu does not keep the
/// screen on.
///
/// For a sighted helper each column shows the mode's letter, name and Morse
/// pattern, the highlighted one inverted, and a hint line explains the
/// gestures. Screen readers see one button per mode; activating it enters
/// that mode directly.
class HomeMenuSurface extends ConsumerStatefulWidget {
  const HomeMenuSurface({super.key, this.highlighted = HomeMenuMode.learn});

  /// How long a press must last to enter the highlighted mode.
  static const confirmHoldDuration = Duration(seconds: 1);

  /// The mode highlighted when the menu appears: Learn on launch and after
  /// the first-launch picker, otherwise the mode the user came back from.
  final HomeMenuMode highlighted;

  @override
  ConsumerState<HomeMenuSurface> createState() => _HomeMenuSurfaceState();
}

class _HomeMenuSurfaceState extends ConsumerState<HomeMenuSurface> {
  /// The mode a hold enters.
  late HomeMenuMode _highlighted = widget.highlighted;

  /// Horizontal distance covered by the current swipe.
  double _swipeDistance = 0;

  /// Whether a mode has been entered. A second confirmation during the wait
  /// or the route transition (another hold, a screen-reader tap, a shake)
  /// must not vibrate or enter another mode.
  bool _entering = false;

  late final ForegroundShakeListener _shakes;

  @override
  void initState() {
    super.initState();
    _shakes = ForegroundShakeListener(
      ref.read(shakeDetectorProvider),
      onEvent: _onShakeEvent,
      onBackground: _onBackground,
      onForeground: _onForeground,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_announceHighlighted());
    });
  }

  @override
  void dispose() {
    _shakes.dispose();
    super.dispose();
  }

  bool get _canVibrate =>
      ref.read(effectiveVibrationCapabilitiesProvider).canVibrate;

  /// Plays the highlighted identifier once when the menu appears.
  ///
  /// Waits for capability detection first, so a device without a vibration
  /// motor (which gets the [NoVibrationScreen]) is never asked to vibrate.
  Future<void> _announceHighlighted() async {
    if (!mounted) return;
    await ref.read(vibrationCapabilitiesProvider.future);
    if (!mounted || _entering || !_canVibrate) return;
    _playIdentifier(_highlighted);
  }

  void _playIdentifier(HomeMenuMode mode) =>
      unawaited(_vibrateIdentifier(mode));

  /// The codec that plays and writes the modes' letters: International
  /// Morse, whatever the lesson language.
  TactileCodec get _codec =>
      ref.read(tactileCodecProvider(HomeMenuMode.identifierLanguage));

  /// Vibrates [mode]'s identifier and completes when it has finished.
  Future<void> _vibrateIdentifier(HomeMenuMode mode) =>
      ref.read(vibrationServiceProvider).playTokens(_codec.encode(mode.letter));

  /// Highlights [mode] and vibrates its identifier.
  void _highlight(HomeMenuMode mode) {
    if (_entering || !_canVibrate) return;
    setState(() => _highlighted = mode);
    _playIdentifier(mode);
  }

  /// Highlights the mode [step] places away, wrapping around.
  void _moveHighlight(int step) {
    const modes = HomeMenuMode.values;
    final index = (modes.indexOf(_highlighted) + step) % modes.length;
    _highlight(modes[index]);
  }

  void _onSwipeStart(DragStartDetails details) => _swipeDistance = 0;

  void _onSwipeUpdate(DragUpdateDetails details) =>
      _swipeDistance += details.primaryDelta ?? 0;

  void _onSwipeEnd(DragEndDetails details) {
    if (_swipeDistance.abs() < _minSwipeDistance) {
      // Too short to move the highlight: replay where the user still is.
      _highlight(_highlighted);
      return;
    }
    // Swipe right moves to the next mode, as it moves to the next item in
    // the lessons and to the next language in the picker.
    _moveHighlight(_swipeDistance > 0 ? 1 : -1);
  }

  /// A double shake replays where the user is; a single shake is ignored.
  void _onShakeEvent(GestureEvent event) {
    if (event is! ChangeLanguage || !mounted) return;
    _highlight(_highlighted);
  }

  /// Nothing vibrates in the background.
  void _onBackground() =>
      unawaited(ref.read(vibrationServiceProvider).cancel());

  /// Tells a user who comes back (after a call, or with the screen locked)
  /// where they are.
  void _onForeground() {
    if (!mounted) return;
    _highlight(_highlighted);
  }

  /// Enters [mode]: vibrates its identifier, then opens its screen.
  ///
  /// The mode's first vibration must not cut the identifier short (on
  /// Android a new vibration replaces the one in progress) or run straight
  /// into it. So the route changes only once the identifier has finished
  /// and [TeachingTimingConfig.postFeedbackPause] has passed, as in the
  /// language picker. Until then [_entering] keeps every other gesture from
  /// vibrating.
  Future<void> _enter(HomeMenuMode mode) async {
    // Ignore a tap that lands just before the switch to NoVibrationScreen.
    if (!_canVibrate || _entering) return;
    _entering = true;
    setState(() => _highlighted = mode);

    final pause = ref.read(teachingTimingConfigProvider).postFeedbackPause;
    await _vibrateIdentifier(mode);
    await Future<void>.delayed(pause);
    // Detection may have found no motor meanwhile: the VibrationGate then
    // replaces the menu, and nothing is opened.
    if (!mounted || !_canVibrate) return;

    // The mode's screen owns shake detection from here on.
    _shakes.handOver();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => _screenFor(mode)),
    );
  }

  /// The screen [mode] opens. Add a case here when adding a mode.
  Widget _screenFor(HomeMenuMode mode) => switch (mode) {
    HomeMenuMode.learn => const TouchSurface(),
    // Until the settings list exists (#45), Settings is the picker.
    HomeMenuMode.settings => const LanguagePickerSurface(fromMenu: true),
  };

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        // Swipes and the hold work anywhere on the screen. They are touch
        // gestures only: screen readers use the per-mode buttons.
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
                    duration: HomeMenuSurface.confirmHoldDuration,
                    debugOwner: this,
                  ),
                  (recognizer) {
                    recognizer.onLongPress = () =>
                        unawaited(_enter(_highlighted));
                  },
                ),
          },
          child: Stack(
            children: [
              // Names the route, so a screen reader announces the menu when
              // it opens; the mode buttons stay separate nodes.
              Semantics(
                container: true,
                explicitChildNodes: true,
                namesRoute: true,
                label: _routeName,
                child: Row(
                  children: [
                    for (final mode in HomeMenuMode.values)
                      Expanded(child: _buildMode(mode)),
                  ],
                ),
              ),
              const Positioned(
                left: 16,
                right: 16,
                bottom: 20,
                // Drawn for the sighted helper only: with a screen reader
                // the buttons open a mode directly.
                child: IgnorePointer(
                  child: ExcludeSemantics(
                    child: Text(
                      _helperHint,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// One column of the menu: [mode]'s letter, name and Morse pattern,
  /// drawn inverted while it is highlighted.
  Widget _buildMode(HomeMenuMode mode) {
    final isHighlighted = mode == _highlighted;
    final color = isHighlighted ? Colors.black : Colors.white;

    // One button node per mode for screen readers. The inner texts and the
    // GestureDetector's own semantics are excluded, so the tap action is
    // provided here instead. It enters the mode directly: the screen reader
    // already speaks each label, so the touch flow's highlight-then-hold
    // step is not needed.
    return Semantics(
      container: true,
      button: true,
      selected: isHighlighted,
      label: mode.label,
      hint: mode.hint,
      onTap: () => unawaited(_enter(mode)),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => _highlight(mode),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          // The bottom padding keeps the hint line clear.
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 64),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isHighlighted ? Colors.white : Colors.black,
              border: Border.all(
                color: isHighlighted ? Colors.white : Colors.white24,
                width: 3,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        mode.letter,
                        style: TextStyle(
                          color: color,
                          fontSize: 96,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        mode.label,
                        style: TextStyle(
                          color: color,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _codec.describe(mode.letter),
                        style: TextStyle(color: color, fontSize: 32),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
