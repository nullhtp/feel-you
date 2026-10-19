import 'dart:async';

import 'package:feel_you/morse/morse.dart';

import 'mock_vibration_service.dart';

/// A [MockVibrationService] that can hold the next [playMorsePattern] call
/// open until [release] is called, as a long identifier plays on a device.
class HeldVibrationService extends MockVibrationService {
  Completer<void>? _held;

  /// Whether the next [playMorsePattern] call is held open.
  bool holdNextPattern = false;

  /// Lets the held call complete.
  void release() => _held?.complete();

  @override
  Future<void> playMorsePattern(List<MorseSignal> signals) async {
    await super.playMorsePattern(signals);
    if (!holdNextPattern) return;
    holdNextPattern = false;
    _held = Completer<void>();
    await _held!.future;
  }
}
