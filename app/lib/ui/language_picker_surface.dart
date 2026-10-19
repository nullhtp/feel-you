import 'dart:async';

import 'package:feel_you/gestures/gestures.dart';
import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/session/session_providers.dart';
import 'package:feel_you/settings/language_preference.dart';
import 'package:feel_you/ui/chooser.dart';
import 'package:feel_you/ui/foreground_shake_listener.dart';
import 'package:feel_you/ui/home_menu_mode.dart';
import 'package:feel_you/ui/home_menu_surface.dart';
import 'package:feel_you/vibration/vibration.dart';
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

/// Visible instructions for a sighted helper.
const _helperHint =
    'Tap a language, then hold anywhere for 1 second to choose it';

/// Added to [_helperHint] when the picker was opened from the home menu.
const _backHint = 'Double shake: back to the menu';

/// Full-screen language picker.
///
/// Shown on launch when no language is saved yet, and from the home menu's
/// Settings ([LanguagePickerSurface.fromMenu]). It is a [Chooser], like the
/// home menu: one language is highlighted at a time, starting with the
/// saved one (English when none is saved). Every touch gesture works
/// without sight and is answered with the identifier vibration (Morse E,
/// ع, Р, Ñ, É or Ü) of the language it leaves highlighted:
///
/// - When the picker appears, and when the app comes back to the
///   foreground, the highlighted identifier plays once, so a user who lands
///   here knows where they are.
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
/// Leaving the foreground cancels an identifier in progress, so nothing
/// vibrates in the background. Like the menu, the picker does not keep the
/// screen on.
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
  static const confirmHoldDuration = chooserHoldDuration;

  /// Whether the picker was opened from the home menu's Settings, rather
  /// than shown on the first launch.
  final bool fromMenu;

  @override
  ConsumerState<LanguagePickerSurface> createState() =>
      _LanguagePickerSurfaceState();
}

class _LanguagePickerSurfaceState extends ConsumerState<LanguagePickerSurface>
    with Chooser<LanguagePickerSurface, MorseLanguage> {
  /// Shake detection for the double shake back to the menu. Only when
  /// [LanguagePickerSurface.fromMenu].
  ForegroundShakeListener? _shakes;

  /// The mode the menu highlights when the picker hands over to it.
  HomeMenuMode get _menuMode =>
      widget.fromMenu ? HomeMenuMode.settings : HomeMenuMode.learn;

  @override
  List<MorseLanguage> get options => MorseLanguage.values;

  @override
  MorseLanguage get initialOption =>
      ref.read(languagePreferenceStoreProvider).read() ?? MorseLanguage.english;

  @override
  void initState() {
    super.initState();
    if (widget.fromMenu) {
      _shakes = ForegroundShakeListener(
        ref.read(shakeDetectorProvider),
        onEvent: _onShakeEvent,
      );
    }
  }

  @override
  void dispose() {
    _shakes?.dispose();
    super.dispose();
  }

  /// Vibrates [language]'s identifier and completes when it has finished.
  @override
  Future<void> playIdentifier(MorseLanguage language) async {
    final letter = _languageIdentifiers[language];
    if (letter == null) return;
    final tokens = ref.read(tactileCodecProvider(language)).encode(letter);
    await ref.read(vibrationServiceProvider).playTokens(tokens);
  }

  /// Goes back to the home menu on a double shake ([ChangeLanguage]),
  /// without saving or selecting anything. A single shake ([Home]) is
  /// ignored, and so is a double shake while a language starts. The menu
  /// announces itself with Settings' identifier.
  void _onShakeEvent(GestureEvent event) {
    if (event is! ChangeLanguage || !mounted) return;
    if (!tryLeave()) return;
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

  /// Starts [language], once its identifier and the silence after it have
  /// passed (see [Chooser.choose]): the menu's identifier must not cut the
  /// language's short or run straight into it.
  @override
  void onChosen(MorseLanguage language) {
    // Remember the choice, so the next launch skips the picker.
    unawaited(ref.read(languagePreferenceStoreProvider).write(language));

    // Set the selected language on the session notifier: the lessons start
    // in it, at digit 0.
    ref.read(sessionNotifierProvider.notifier).selectLanguage(language);

    _openMenu();
  }

  @override
  Widget build(BuildContext context) {
    return buildChooser(
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
            // Drawn for the sighted helper only: with a screen reader the
            // buttons start a language directly.
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: Text(
                  widget.fromMenu ? '$_helperHint. $_backHint' : _helperHint,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// One column of the picker: [language]'s name, drawn inverted while it
  /// is highlighted.
  Widget _buildOption(MorseLanguage language) {
    final label = _languageLabels[language] ?? language.name;
    final locale = _languageLocales[language];
    final isHighlighted = language == highlighted;

    // One button node per language for screen readers. The label carries
    // the language's locale so it is spoken with the right voice; the hint
    // stays English (and the ambient text direction LTR) as the app has no
    // localisation. The inner Text and the column's GestureDetector
    // semantics are excluded, so the tap action is provided here instead.
    // It starts the language directly: the screen reader already speaks
    // each label, so the touch flow's highlight-then-hold step is not
    // needed.
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
      onTap: () => unawaited(choose(language)),
      excludeSemantics: true,
      child: ChooserColumn(
        highlighted: isHighlighted,
        onTap: () => highlight(language),
        child: Text(
          label,
          style: TextStyle(
            color: isHighlighted ? Colors.black : Colors.white,
            fontSize: 48,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
