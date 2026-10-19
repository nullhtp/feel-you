import 'package:feel_you/app.dart';
import 'package:feel_you/cloud/cloud_key_store.dart';
import 'package:feel_you/settings/language_preference.dart';
import 'package:feel_you/settings/learned_items.dart';
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
  // Learned items are loaded with it, so the quiz and the overlay's count
  // never start empty.
  final languagePreference = await loadLanguagePreferenceStore();
  final learnedItems = await loadLearnedItemsStore();

  // The dot/dash midpoint is not read here: before the first frame the view
  // can still report a zero size, and the width changes with split-screen,
  // foldables and rotation. TouchSurface feeds the live layout width into
  // the GestureClassifier on every touch instead.
  runApp(
    ProviderScope(
      overrides: [
        languagePreferenceStoreProvider.overrideWithValue(languagePreference),
        learnedItemsStoreProvider.overrideWithValue(learnedItems),
        // The cloud key lives in the Keychain / Keystore, never in the
        // preferences above. Nothing is loaded here: the key is read when
        // first needed (the helper overlay), so the first frame never waits
        // for the secure storage.
        cloudKeyStoreProvider.overrideWithValue(const SecureCloudKeyStore()),
      ],
      child: const FeelYouApp(),
    ),
  );
}
