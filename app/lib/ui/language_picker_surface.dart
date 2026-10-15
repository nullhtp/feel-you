import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/session/session_providers.dart';
import 'package:feel_you/ui/no_vibration_screen.dart';
import 'package:feel_you/ui/touch_surface.dart';
import 'package:feel_you/vibration/vibration.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Vibration identifier patterns for each language, looked up from the
/// registry instead of being hardcoded.
///
/// English: Morse "E" = [dot]
/// Arabic: Morse "ع" (Ain) = [dot, dash, dot, dash]
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

/// Full-screen language picker shown on app start.
///
/// Displays one button per language. Tapping a button vibrates its
/// identifier pattern and navigates to the main [TouchSurface].
class LanguagePickerSurface extends ConsumerWidget {
  const LanguagePickerSurface({super.key});

  void _selectLanguage(
    BuildContext context,
    WidgetRef ref,
    MorseLanguage language,
  ) {
    // Ignore a tap that lands just before the switch to NoVibrationScreen.
    if (!ref.read(effectiveVibrationCapabilitiesProvider).canVibrate) return;

    // Vibrate the language identifier.
    final vibration = ref.read(vibrationServiceProvider);
    final pattern = _languageIdentifiers[language];
    if (pattern != null) {
      vibration.playMorsePattern(pattern);
    }

    // Set the selected language on the session notifier.
    ref.read(sessionNotifierProvider.notifier).selectLanguage(language);

    // Navigate to the main learning surface.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const TouchSurface()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Vibration is the only output channel: never start a session on a
    // device that definitely has no vibration motor.
    if (!ref.watch(effectiveVibrationCapabilitiesProvider).canVibrate) {
      return const NoVibrationScreen();
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: MorseLanguage.values.map((language) {
              final label = _languageLabels[language] ?? language.name;
              final locale = _languageLocales[language];
              return Expanded(
                // One button node per language for screen readers. The label
                // carries the language's locale so it is spoken with the
                // right voice; the hint stays English (and the ambient text
                // direction LTR) as the app has no localisation. The inner
                // Text and the GestureDetector's own semantics are excluded,
                // so the tap action is provided here instead.
                child: Semantics(
                  container: true,
                  button: true,
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
                  onTap: () => _selectLanguage(context, ref, language),
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: () => _selectLanguage(context, ref, language),
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox.expand(
                      child: Center(
                        child: Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
