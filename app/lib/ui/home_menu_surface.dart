import 'dart:async';

import 'package:feel_you/gestures/gestures.dart';
import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/tactile/tactile.dart';
import 'package:feel_you/ui/chooser.dart';
import 'package:feel_you/ui/foreground_shake_listener.dart';
import 'package:feel_you/ui/home_menu_mode.dart';
import 'package:feel_you/ui/language_picker_surface.dart';
import 'package:feel_you/ui/touch_surface.dart';
import 'package:feel_you/vibration/vibration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Visible instructions for a sighted helper.
const _helperHint =
    'Tap or swipe to a mode, then hold anywhere for 1 second to open it';

/// Name of the menu's route for screen readers.
const _routeName = 'Home menu';

/// The home menu: one column per [HomeMenuMode], left to right.
///
/// Shown on launch when a language is saved, after a language is chosen in
/// the picker, and after a double shake in a mode. It is a [Chooser], like
/// the language picker: one mode is highlighted at a time ([highlighted]
/// when the menu appears), and every touch gesture is answered with the
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
  static const confirmHoldDuration = chooserHoldDuration;

  /// The mode highlighted when the menu appears: Learn on launch and after
  /// the first-launch picker, otherwise the mode the user came back from.
  final HomeMenuMode highlighted;

  @override
  ConsumerState<HomeMenuSurface> createState() => _HomeMenuSurfaceState();
}

class _HomeMenuSurfaceState extends ConsumerState<HomeMenuSurface>
    with Chooser<HomeMenuSurface, HomeMenuMode> {
  late final ForegroundShakeListener _shakes;

  @override
  List<HomeMenuMode> get options => HomeMenuMode.values;

  @override
  HomeMenuMode get initialOption => widget.highlighted;

  @override
  void initState() {
    super.initState();
    _shakes = ForegroundShakeListener(
      ref.read(shakeDetectorProvider),
      onEvent: _onShakeEvent,
    );
  }

  @override
  void dispose() {
    _shakes.dispose();
    super.dispose();
  }

  /// The codec that plays and writes the modes' letters: International
  /// Morse, whatever the lesson language.
  TactileCodec get _codec =>
      ref.read(tactileCodecProvider(HomeMenuMode.identifierLanguage));

  /// Vibrates [mode]'s identifier and completes when it has finished.
  @override
  Future<void> playIdentifier(HomeMenuMode mode) =>
      ref.read(vibrationServiceProvider).playTokens(_codec.encode(mode.letter));

  /// A double shake replays where the user is; a single shake is ignored.
  void _onShakeEvent(GestureEvent event) {
    if (event is! ChangeLanguage || !mounted) return;
    replayHighlighted();
  }

  /// Opens [mode]'s screen, once its identifier and the silence after it
  /// have passed (see [Chooser.choose]).
  @override
  void onChosen(HomeMenuMode mode) {
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
    return buildChooser(
      child: Stack(
        children: [
          // Names the route, so a screen reader announces the menu when it
          // opens; the mode buttons stay separate nodes.
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
            // Drawn for the sighted helper only: with a screen reader the
            // buttons open a mode directly.
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
    );
  }

  /// One column of the menu: [mode]'s letter, name and Morse pattern,
  /// drawn inverted while it is highlighted.
  Widget _buildMode(HomeMenuMode mode) {
    final isHighlighted = mode == highlighted;
    final color = isHighlighted ? Colors.black : Colors.white;

    // One button node per mode for screen readers. The inner texts and the
    // column's GestureDetector semantics are excluded, so the tap action is
    // provided here instead. It enters the mode directly: the screen reader
    // already speaks each label, so the touch flow's highlight-then-hold
    // step is not needed.
    return Semantics(
      container: true,
      button: true,
      selected: isHighlighted,
      label: mode.label,
      hint: mode.hint,
      onTap: () => unawaited(choose(mode)),
      excludeSemantics: true,
      child: ChooserColumn(
        highlighted: isHighlighted,
        onTap: () => highlight(mode),
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
    );
  }
}
