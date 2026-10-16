import 'package:feel_you/settings/language_preference.dart';
import 'package:feel_you/ui/language_picker_surface.dart';
import 'package:feel_you/ui/touch_surface.dart';
import 'package:feel_you/ui/vibration_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FeelYouApp extends StatelessWidget {
  const FeelYouApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Feel You',
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.black),
      // Above the navigator, so a device without a vibration motor gets the
      // NoVibrationScreen whichever route is showing.
      builder: (_, navigator) => VibrationGate(child: navigator!),
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
/// On a device without a vibration motor, the app's [VibrationGate] shows
/// the NoVibrationScreen instead of this screen and of every route pushed
/// after it.
class LaunchScreen extends ConsumerWidget {
  const LaunchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(launchLanguageProvider) == null) {
      return const LanguagePickerSurface();
    }
    return const TouchSurface();
  }
}
