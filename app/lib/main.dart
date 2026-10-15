import 'package:feel_you/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // The dot/dash midpoint is not read here: before the first frame the view
  // can still report a zero size, and the width changes with split-screen,
  // foldables and rotation. TouchSurface feeds the live layout width into
  // the GestureClassifier on every touch instead.
  runApp(const ProviderScope(child: FeelYouApp()));
}
