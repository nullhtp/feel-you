import 'package:feel_you/session/session_notifier.dart';
import 'package:feel_you/session/session_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the [SessionNotifier] and its current [SessionState].
///
/// Watch this provider to react to letter or phase changes.
/// Use `ref.read(sessionNotifierProvider.notifier)` to call
/// mutation methods.
///
/// Override in tests to inject a custom notifier or initial state.
final sessionNotifierProvider =
    StateNotifierProvider<SessionNotifier, SessionState>(
      (ref) => SessionNotifier(),
    );
