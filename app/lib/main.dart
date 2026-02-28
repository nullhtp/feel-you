import 'dart:ui';

import 'package:feel_you/app.dart';
import 'package:feel_you/gestures/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Read screen width from the primary view before runApp.
  // The app is locked to landscape, so this value is stable.
  final view = PlatformDispatcher.instance.views.first;
  final screenWidth = view.physicalSize.width / view.devicePixelRatio;

  runApp(
    ProviderScope(
      overrides: [screenWidthProvider.overrideWithValue(screenWidth)],
      child: const FeelYouApp(),
    ),
  );
}
