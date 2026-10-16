import 'package:feel_you/vibration/vibration_providers.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Label of the debug-only button that bypasses the vibration gate.
const noVibrationBypassLabel = 'Continue anyway (debug build)';

/// Shown instead of every other screen on a device without a vibration
/// motor (see `VibrationGate`).
///
/// Feel You speaks only through vibration, so on such a device a session
/// would run while the user feels nothing. This screen tells the sighted
/// helper why the app can't be used and, in release builds, offers no way
/// to start a session.
///
/// Debug builds add a [noVibrationBypassLabel] button so developers can
/// reach the session UI on emulators and simulators, which report no motor.
/// It sets [vibrationGateBypassProvider], which opens the gate for the rest
/// of the run.
class NoVibrationScreen extends ConsumerWidget {
  const NoVibrationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'No vibration motor',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'This device cannot vibrate, so Feel You cannot work on '
                  'it.\nFeel You communicates only through vibration. '
                  'Please use a phone with a vibration motor.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 22),
                ),
                // kDebugMode is a compile-time constant, so release and
                // profile builds don't contain this button at all.
                if (kDebugMode) ...[
                  const SizedBox(height: 32),
                  OutlinedButton(
                    onPressed: ref
                        .read(vibrationGateBypassProvider.notifier)
                        .bypass,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.amber,
                      side: const BorderSide(color: Colors.amber),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                    // The button node takes this label and hint.
                    child: Semantics(
                      hint:
                          'Opens the language picker although nothing '
                          'will vibrate',
                      child: const Text(
                        noVibrationBypassLabel,
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
