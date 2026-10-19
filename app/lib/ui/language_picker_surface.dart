import 'dart:async';

import 'package:feel_you/gestures/gestures.dart';
import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/session/session_providers.dart';
import 'package:feel_you/settings/language_preference.dart';
import 'package:feel_you/teaching/teaching.dart';
import 'package:feel_you/ui/foreground_shake_listener.dart';
import 'package:feel_you/ui/home_menu_mode.dart';
import 'package:feel_you/ui/home_menu_surface.dart';
import 'package:feel_you/ui/no_vibration_screen.dart';
import 'package:feel_you/vibration/vibration.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The letter that identifies each language, vibrated with the language's
/// codec ([tactileCodecProvider]) instead of a hardcoded pattern.
///
/// English: Morse "E" = `·`
/// Arabic: Morse "ع" (Ain) = `·−·−`
/// Russian: Morse "Р" (Er) = `·−·`
/// Spanish: Morse "Ñ" (Eñe) = `−−·−−`
/// French: Morse "É" (E acute) = `··−··`
/// German: Morse "Ü" (U umlaut) = `··−−`
const Map<MorseLanguage, String> _languageIdentifiers = {
  MorseLanguage.english: 'E',
  MorseLanguage.arabic: 'ع',
  MorseLanguage.russian: 'Р',
  MorseLanguage.spanish: 'Ñ',
  MorseLanguage.french: 'É',
  MorseLanguage.german: 'Ü',
};

/// Display labels for each language.
const Map<MorseLanguage, String> _languageLabels = {
  MorseLanguage.english: 'English',
  MorseLanguage.arabic: 'العربية',
  MorseLanguage.russian: 'Русский',
  MorseLanguage.spanish: 'Español',
  MorseLanguage.french: 'Français',
  MorseLanguage.german: 'Deutsch',
};

/// Locale of each display label, so screen readers speak it in that
/// language.
const Map<MorseLanguage, Locale> _languageLocales = {
  MorseLanguage.english: Locale('en'),
  MorseLanguage.arabic: Locale('ar'),
  MorseLanguage.russian: Locale('ru'),
  MorseLanguage.spanish: Locale('es'),
  MorseLanguage.french: Locale('fr'),
  MorseLanguage.german: Locale('de'),
};

/// English name of [language] for the screen-reader hint, e.g. "Arabic".
String _englishName(MorseLanguage language) =>
    '${language.name[0].toUpperCase()}${language.name.substring(1)}';

/// Shortest horizontal drag that moves the highlight, in logical pixels.
///
/// Matches the session's default swipe distance. A shorter drag replays
/// the highlighted identifier instead, so no gesture goes unanswered.
const double _minSwipeDistance = 50;

/// Visible instructions for a sighted helper.
const _helperHint =
    'Tap a language, then hold anywhere for 1 second to choose it';

/// Added to [_helperHint] when the picker was opened from the home menu.
const _backHint = 'Double shake: back to the menu';

/// Full-screen language picker.
///
/// Shown on launch when no language is saved yet, and from the home menu's
/// Settings ([LanguagePickerSurface.fromMenu]). One language is highlighted
/// at a time, starting with the saved one (English when none is saved).
/// Every touch gesture works without sight and is answered with the
/// identifier vibration (Morse E, ع, Р, Ñ, É or Ü) of the language it
/// leaves highlighted:
///
/// - When the picker appears, the highlighted identifier plays once, so a
///   user who lands here knows where they are.
/// - Tap: highlights the language under the finger (the screen is split
///   into one column per language) and vibrates its identifier.
/// - Swipe right / left: highlights the next / previous language, wrapping
///   around, and vibrates its identifier.
/// - Hold for [confirmHoldDuration], anywhere: starts the highlighted
///   language, i.e. the last identifier felt.
/// - Double shake ([ChangeLanguage]), only when [fromMenu]: back to the
///   home menu, keeping the language as it was. On the first launch there
///   is no menu to return to yet, so the picker does not listen for shakes
///   at all. A single shake never does anything here.
///
/// For a sighted helper the highlighted column is drawn inverted and a hint
/// line explains the tap-then-hold flow (and the double shake back, when
/// [fromMenu]). Screen readers see one button per language; activating it
/// starts that language directly.
///
/// Starting a language vibrates its identifier. Once it has finished, plus
/// a short silence, the language is saved for the next launch, selected on
/// the session, and the picker is replaced with the [HomeMenuSurface]:
/// with Learn highlighted on the first launch, Settings when [fromMenu].
class LanguagePickerSurface extends ConsumerStatefulWidget {
  const LanguagePickerSurface({super.key, this.fromMenu = false});

  /// How long a press must last to start the highlighted language.
  static const confirmHoldDuration = Duration(seconds: 1);

  /// Whether the picker was opened from the home menu's Settings, rather
  /// than shown on the first launch.
  final bool fromMenu;

  @override
  ConsumerState<LanguagePickerSurface> createState() =>
      _LanguagePickerSurfaceState();
}

class _LanguagePickerSurfaceState extends ConsumerState<LanguagePickerSurface> {
  /// The language a hold starts.
  late MorseLanguage _highlighted;

  /// Horizontal distance covered by the current swipe.
  double _swipeDistance = 0;

  /// Whether a language has been started, or the picker is going back to
  /// the menu. A second confirmation during the route transition (e.g.
  /// another hold, a screen-reader tap or a double shake) must not start
  /// another session.
  bool _started = false;

  /// Shake detection for the double shake back to the menu. Only when
  /// [LanguagePickerSurface.fromMenu].
  ForegroundShakeListener? _shakes;

  /// The mode the menu highlights when the picker hands over to it.
  HomeMenuMode get _menuMode =>
      widget.fromMenu ? HomeMenuMode.settings : HomeMenuMode.learn;

  @override
  void initState() {
    super.initState();
    _highlighted =
        ref.read(languagePreferenceStoreProvider).read() ??
        MorseLanguage.english;
    if (widget.fromMenu) {
      _shakes = ForegroundShakeListener(
        ref.read(shakeDetectorProvider),
        onEvent: _onShakeEvent,
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_announceHighlighted());
    });
  }

  @override
  void dispose() {
    _shakes?.dispose();
    super.dispose();
  }

  bool get _canVibrate =>
      ref.read(effectiveVibrationCapabilitiesProvider).canVibrate;

  /// Plays the highlighted identifier once when the picker appears.
  ///
  /// Waits for capability detection first, so a device without a vibration
  /// motor (which gets the [NoVibrationScreen]) is never asked to vibrate.
  Future<void> _announceHighlighted() async {
    if (!mounted) return;
    await ref.read(vibrationCapabilitiesProvider.future);
    if (!mounted || _started || !_canVibrate) return;
    _playIdentifier(_highlighted);
  }

  void _playIdentifier(MorseLanguage language) =>
      unawaited(_vibrateIdentifier(language));

  /// Vibrates [language]'s identifier and completes when it has finished.
  Future<void> _vibrateIdentifier(MorseLanguage language) async {
    final letter = _languageIdentifiers[language];
    if (letter == null) return;
    final tokens = ref.read(tactileCodecProvider(language)).encode(letter);
    await ref.read(vibrationServiceProvider).playTokens(tokens);
  }

  /// Highlights [language] and vibrates its identifier.
  void _highlight(MorseLanguage language) {
    if (_started || !_canVibrate) return;
    setState(() => _highlighted = language);
    _playIdentifier(language);
  }

  /// Highlights the language [step] places away, wrapping around.
  void _moveHighlight(int step) {
    const languages = MorseLanguage.values;
    final index = (languages.indexOf(_highlighted) + step) % languages.length;
    _highlight(languages[index]);
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
    // Swipe right moves to the next language, as it moves to the next
    // letter in a session.
    _moveHighlight(_swipeDistance > 0 ? 1 : -1);
  }

  /// Goes back to the home menu on a double shake ([ChangeLanguage]),
  /// without saving or selecting anything. A single shake ([Home]) is
  /// ignored. The menu announces itself with Settings' identifier.
  void _onShakeEvent(GestureEvent event) {
    if (event is! ChangeLanguage || !mounted) return;
    if (_started || !_canVibrate) return;
    _started = true;
    _openMenu();
  }

  /// Replaces the picker with the home menu, which owns shake detection
  /// from now on.
  void _openMenu() {
    _shakes?.handOver();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => HomeMenuSurface(highlighted: _menuMode),
      ),
    );
  }

  /// Starts [language]: vibrates its identifier, then opens the menu.
  ///
  /// The menu's identifier must not cut the language's short (on Android a
  /// new vibration replaces the one in progress) or run straight into it.
  /// So the route changes only once the identifier has finished and
  /// [TeachingTimingConfig.postFeedbackPause] has passed, the same silence
  /// that follows feedback in a session. Until then [_started] keeps every
  /// other gesture from vibrating.
  Future<void> _selectLanguage(MorseLanguage language) async {
    // Ignore a tap that lands just before the switch to NoVibrationScreen.
    if (!_canVibrate) return;
    if (_started) return;
    _started = true;
    setState(() => _highlighted = language);

    final pause = ref.read(teachingTimingConfigProvider).postFeedbackPause;
    await _vibrateIdentifier(language);
    await Future<void>.delayed(pause);
    // Detection may have found no motor meanwhile: the VibrationGate then
    // replaces the picker, and nothing is saved or started.
    if (!mounted || !_canVibrate) return;

    // Remember the choice, so the next launch skips the picker.
    unawaited(ref.read(languagePreferenceStoreProvider).write(language));

    // Set the selected language on the session notifier: the lessons start
    // in it, at digit 0.
    ref.read(sessionNotifierProvider.notifier).selectLanguage(language);

    _openMenu();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        // Swipes and the hold work anywhere on the screen. They are touch
        // gestures only: screen readers use the per-language buttons.
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
                    duration: LanguagePickerSurface.confirmHoldDuration,
                    debugOwner: this,
                  ),
                  (recognizer) {
                    recognizer.onLongPress = () =>
                        unawaited(_selectLanguage(_highlighted));
                  },
                ),
          },
          child: Stack(
            children: [
              Row(
                children: [
                  for (final language in MorseLanguage.values)
                    Expanded(child: _buildOption(language)),
                ],
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 20,
                // Drawn for the sighted helper only: with a screen reader
                // the buttons start a language directly.
                child: IgnorePointer(
                  child: ExcludeSemantics(
                    child: Text(
                      widget.fromMenu
                          ? '$_helperHint. $_backHint'
                          : _helperHint,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 20,
                      ),
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

  /// One column of the picker: [language]'s name, drawn inverted while it
  /// is highlighted.
  Widget _buildOption(MorseLanguage language) {
    final label = _languageLabels[language] ?? language.name;
    final locale = _languageLocales[language];
    final isHighlighted = language == _highlighted;

    // One button node per language for screen readers. The label carries
    // the language's locale so it is spoken with the right voice; the hint
    // stays English (and the ambient text direction LTR) as the app has no
    // localisation. The inner Text and the GestureDetector's own semantics
    // are excluded, so the tap action is provided here instead. It starts
    // the language directly: the screen reader already speaks each label,
    // so the touch flow's highlight-then-hold step is not needed.
    return Semantics(
      container: true,
      button: true,
      selected: isHighlighted,
      attributedLabel: AttributedString(
        label,
        attributes: [
          if (locale != null)
            LocaleStringAttribute(
              range: TextRange(start: 0, end: label.length),
              locale: locale,
            ),
        ],
      ),
      hint: 'Chooses ${_englishName(language)} for the lessons',
      onTap: () => unawaited(_selectLanguage(language)),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => _highlight(language),
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
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isHighlighted ? Colors.black : Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
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
