import 'dart:async';

import 'package:feel_you/settings/language_preference.dart';
import 'package:feel_you/teaching/teaching_providers.dart';
import 'package:feel_you/ui/language_picker_surface.dart';
import 'package:feel_you/ui/no_vibration_screen.dart';
import 'package:feel_you/ui/touch_surface.dart';
import 'package:feel_you/vibration/vibration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FeelYouApp extends StatelessWidget {
  const FeelYouApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Feel You',
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.black),
      home: const LaunchScreen(),
    );
  }
}

/// The first screen of the app.
///
/// When a language was saved on an earlier run ([launchLanguageProvider]),
/// goes straight to the [TouchSurface]; the session already starts in that
/// language. Otherwise shows the [LanguagePickerSurface].
///
/// Either way, a device that definitely has no vibration motor gets the
/// [NoVibrationScreen] instead. Capability detection may finish after the
/// first frame: if it then reports no motor, the running session is
/// stopped and replaced.
class LaunchScreen extends ConsumerWidget {
  const LaunchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<VibrationCapabilities>(effectiveVibrationCapabilitiesProvider, (
      _,
      capabilities,
    ) {
      // Stop the loop now, before the rebuild below removes the
      // TouchSurface: providers can't change while the tree is building,
      // so the loop must already be stopped when TouchSurface.dispose
      // stops it again.
      if (!capabilities.canVibrate &&
          ref.exists(teachingOrchestratorProvider)) {
        unawaited(ref.read(teachingOrchestratorProvider.notifier).stop());
      }
    });

    // Vibration is the only output channel: never run a session on a
    // device that definitely has no vibration motor.
    if (!ref.watch(effectiveVibrationCapabilitiesProvider).canVibrate) {
      return const NoVibrationScreen();
    }
    if (ref.watch(launchLanguageProvider) == null) {
      return const LanguagePickerSurface();
    }
    return const TouchSurface();
  }
}
