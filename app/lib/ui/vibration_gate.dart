import 'dart:async';

import 'package:feel_you/teaching/teaching_providers.dart';
import 'package:feel_you/ui/no_vibration_screen.dart';
import 'package:feel_you/vibration/vibration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shows the [NoVibrationScreen] instead of [child] on a device that
/// definitely has no vibration motor.
///
/// Vibration is the only output channel: no screen of the app may run on
/// such a device. The app installs this gate with [MaterialApp.builder], so
/// [child] is the navigator and the gate covers every route, including the
/// ones pushed after launch (the home menu after a language is picked, the
/// lessons and the picker opened from the menu, the menu after a double
/// shake).
///
/// Capability detection may finish after the first frame. If it then
/// reports no motor, the running session is stopped and the whole route
/// stack is replaced. When a debug build bypasses the gate afterwards, the
/// navigator starts over from its first route.
class VibrationGate extends ConsumerWidget {
  const VibrationGate({required this.child, super.key});

  /// What the app shows while the device can vibrate.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<VibrationCapabilities>(effectiveVibrationCapabilitiesProvider, (
      _,
      capabilities,
    ) {
      // Stop the loop now, before the rebuild below removes the
      // TouchSurface. Its dispose would stop it too, but providers can't
      // change while the tree is building, so it could only publish the
      // stopped state after the frame.
      if (!capabilities.canVibrate &&
          ref.exists(teachingOrchestratorProvider)) {
        unawaited(ref.read(teachingOrchestratorProvider.notifier).stop());
      }
    });

    if (!ref.watch(effectiveVibrationCapabilitiesProvider).canVibrate) {
      // Outside the navigator, so mark the screen as a route for screen
      // readers, as MaterialPageRoute does.
      return Semantics(
        scopesRoute: true,
        explicitChildNodes: true,
        child: const NoVibrationScreen(),
      );
    }
    return child;
  }
}
