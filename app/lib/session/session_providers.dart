import 'package:feel_you/morse/morse_language.dart';
import 'package:feel_you/session/session_notifier.dart';
import 'package:feel_you/session/session_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the [SessionNotifier] and its current [SessionState].
///
/// Watch this provider to react to letter, level, language, or phase changes.
/// Use `ref.read(sessionNotifierProvider.notifier)` to call
/// mutation methods.
///
/// The initial language defaults to [MorseLanguage.english]. The language
/// picker calls [SessionNotifier.selectLanguage] to set the user's choice.
///
/// Override in tests to inject a custom notifier or initial state.
final sessionNotifierProvider =
    StateNotifierProvider<SessionNotifier, SessionState>(
      (ref) => SessionNotifier(MorseLanguage.english),
    );
