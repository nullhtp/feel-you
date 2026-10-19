import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The vibration engine plays tactile tokens and knows nothing about the
/// code that produced them, so a braille codec or prosigns need no engine
/// change (issue #40).
void main() {
  test('nothing in lib/vibration imports the Morse code', () {
    final sources = Directory('lib/vibration')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .toList();
    expect(sources, isNotEmpty);

    final morseImport = RegExp(
      r'''^\s*(import|export)\s+['"]package:feel_you/morse/''',
      multiLine: true,
    );
    for (final file in sources) {
      expect(
        morseImport.hasMatch(file.readAsStringSync()),
        isFalse,
        reason: '${file.path} imports lib/morse/',
      );
    }
  });
}
