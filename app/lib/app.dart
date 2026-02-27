import 'package:feel_you/ui/touch_surface.dart';
import 'package:flutter/material.dart';

class FeelYouApp extends StatelessWidget {
  const FeelYouApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(title: 'Feel You', home: TouchSurface());
  }
}
