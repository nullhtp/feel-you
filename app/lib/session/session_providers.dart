import 'package:feel_you/morse/morse_language.dart';
import 'package:feel_you/morse/morse_providers.dart';
import 'package:feel_you/session/session_notifier.dart';
import 'package:feel_you/session/session_state.dart';
import 'package:feel_you/settings/language_preference.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the [SessionNotifier] and its current [SessionState].
///
/// Watch this provider to react to letter, level, language, or phase changes.
/// Use `ref.read(sessionNotifierProvider.notifier)` to call
/// mutation methods.
///
/// The initial language is the one saved on an earlier run
/// ([launchLanguageProvider]), so a launch that skips the picker starts in
/// it; [MorseLanguage.english] when none is saved. The language picker
/// calls [SessionNotifier.selectLanguage] to set the user's choice.
/// Levels are resolved from [morseRegistryProvider].
///
/// Override in tests to inject a custom notifier or initial state, or
/// override [morseRegistryProvider] to substitute the registry.
final sessionNotifierProvider =
    StateNotifierProvider<SessionNotifier, SessionState>(
      (ref) => SessionNotifier(
        ref.watch(launchLanguageProvider) ?? MorseLanguage.english,
        registry: ref.watch(morseRegistryProvider),
      ),
    );
