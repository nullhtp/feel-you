import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/session/session_providers.dart';
import 'package:feel_you/ui/touch_surface.dart';
import 'package:feel_you/vibration/vibration.dart';
import 'package:flutter/material.dart';
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
};

/// Display labels for each language.
const Map<MorseLanguage, String> _languageLabels = {
  MorseLanguage.english: 'English',
  MorseLanguage.arabic: 'العربية',
};

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
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: MorseLanguage.values.map((language) {
              return Expanded(
                child: GestureDetector(
                  onTap: () => _selectLanguage(context, ref, language),
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox.expand(
                    child: Center(
                      child: Text(
                        _languageLabels[language] ?? language.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
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
