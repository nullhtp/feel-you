import 'package:feel_you/ui/touch_surface.dart';
import 'package:flutter/material.dart';

class FeelYouApp extends StatelessWidget {
  const FeelYouApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Feel You',
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.black),
      home: const TouchSurface(),
    );
  }
}
