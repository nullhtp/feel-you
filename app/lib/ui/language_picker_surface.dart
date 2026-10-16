import 'dart:async';

import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/session/session_providers.dart';
import 'package:feel_you/settings/language_preference.dart';
import 'package:feel_you/teaching/teaching.dart';
import 'package:feel_you/ui/no_vibration_screen.dart';
import 'package:feel_you/ui/touch_surface.dart';
import 'package:feel_you/vibration/vibration.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Vibration identifier patterns for each language, looked up from the
/// registry instead of being hardcoded.
///
/// English: Morse "E" = [dot]
/// Arabic: Morse "ع" (Ain) = [dot, dash, dot, dash]
/// Russian: Morse "Р" (Er) = [dot, dash, dot]
final Map<MorseLanguage, List<MorseSignal>> _languageIdentifiers = {
  MorseLanguage.english:
      encodeLetter('E', MorseLanguage.english) ?? [MorseSignal.dot],
  MorseLanguage.arabic:
      encodeLetter('ع', MorseLanguage.arabic) ??
      [MorseSignal.dot, MorseSignal.dash, MorseSignal.dot, MorseSignal.dash],
  MorseLanguage.russian:
      encodeLetter('Р', MorseLanguage.russian) ??
      [MorseSignal.dot, MorseSignal.dash, MorseSignal.dot],
};

/// Display labels for each language.
const Map<MorseLanguage, String> _languageLabels = {
  MorseLanguage.english: 'English',
  MorseLanguage.arabic: 'العربية',
  MorseLanguage.russian: 'Русский',
};

/// Locale of each display label, so screen readers speak it in that
/// language.
const Map<MorseLanguage, Locale> _languageLocales = {
  MorseLanguage.english: Locale('en'),
  MorseLanguage.arabic: Locale('ar'),
  MorseLanguage.russian: Locale('ru'),
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
const _helperHint = 'Tap a language, then hold anywhere for 1 second to start';

/// Full-screen language picker.
///
/// Shown on launch when no language is saved yet, and after a double shake
/// in a session. One language is highlighted at a time, starting with the
/// saved one (English when none is saved). Every touch gesture works
/// without sight and is answered with the identifier vibration (Morse E, ع
/// or Р) of the language it leaves highlighted:
///
/// - When the picker appears, the highlighted identifier plays once, so a
///   user who lands here knows where they are.
/// - Tap: highlights the language under the finger (the screen is split
///   into one column per language) and vibrates its identifier.
/// - Swipe right / left: highlights the next / previous language, wrapping
///   around, and vibrates its identifier.
/// - Hold for [confirmHoldDuration], anywhere: starts the highlighted
///   language, i.e. the last identifier felt.
///
/// For a sighted helper the highlighted column is drawn inverted and a hint
/// line explains the tap-then-hold flow. Screen readers see one button per
/// language; activating it starts that language directly.
///
/// Starting a language vibrates its identifier. Once it has finished, plus
/// a short silence, the language is saved for the next launch, selected on
/// the session and the picker is replaced with the [TouchSurface].
class LanguagePickerSurface extends ConsumerStatefulWidget {
  const LanguagePickerSurface({super.key});

  /// How long a press must last to start the highlighted language.
  static const confirmHoldDuration = Duration(seconds: 1);

  @override
  ConsumerState<LanguagePickerSurface> createState() =>
      _LanguagePickerSurfaceState();
}

class _LanguagePickerSurfaceState extends ConsumerState<LanguagePickerSurface> {
  /// The language a hold starts.
  late MorseLanguage _highlighted;

  /// Horizontal distance covered by the current swipe.
  double _swipeDistance = 0;

  /// Whether a language has been started. A second confirmation during the
  /// route transition (e.g. another hold or a screen-reader tap) must not
  /// start another session.
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _highlighted =
        ref.read(languagePreferenceStoreProvider).read() ??
        MorseLanguage.english;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_announceHighlighted());
    });
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
    final pattern = _languageIdentifiers[language];
    if (pattern == null) return;
    await ref.read(vibrationServiceProvider).playMorsePattern(pattern);
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

  /// Starts [language]: vibrates its identifier, then opens the session.
  ///
  /// The session's first pattern must not cut the identifier short (on
  /// Android a new vibration replaces the one in progress) or run straight
  /// into it. So the route changes only once the identifier has finished
  /// and [TeachingTimingConfig.postFeedbackPause] has passed, the same
  /// silence that follows feedback in a session. Until then [_started]
  /// keeps every other gesture from vibrating.
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

    // Set the selected language on the session notifier.
    ref.read(sessionNotifierProvider.notifier).selectLanguage(language);

    // Navigate to the main learning surface.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const TouchSurface()),
    );
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
              const Positioned(
                left: 16,
                right: 16,
                bottom: 20,
                // Drawn for the sighted helper only: with a screen reader
                // the buttons start a language directly.
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
      hint: 'Starts Morse lessons in ${_englishName(language)}',
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
