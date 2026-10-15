import 'package:feel_you/app.dart';
import 'package:feel_you/settings/language_preference.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Load the saved language before the first frame, so a returning user
  // goes straight to the lessons without the picker flashing up first.
  final languagePreference = await loadLanguagePreferenceStore();

  // The dot/dash midpoint is not read here: before the first frame the view
  // can still report a zero size, and the width changes with split-screen,
  // foldables and rotation. TouchSurface feeds the live layout width into
  // the GestureClassifier on every touch instead.
  runApp(
    ProviderScope(
      overrides: [
        languagePreferenceStoreProvider.overrideWithValue(languagePreference),
      ],
      child: const FeelYouApp(),
    ),
  );
}
