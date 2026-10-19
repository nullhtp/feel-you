import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The pigeon channel `WakelockPlus.toggle` sends its requests on.
const _wakelockToggleChannel =
    'dev.flutter.pigeon.wakelock_plus_platform_interface.'
    'WakelockPlusApi.toggle';

/// Decodes wakelock_plus pigeon messages, where a `ToggleMessage` is a
/// custom type wrapping the list `[enable]`.
class _WakelockMessageCodec extends StandardMessageCodec {
  const _WakelockMessageCodec();

  @override
  Object? readValueOfType(int type, ReadBuffer buffer) {
    if (type >= 128) return readValue(buffer);
    return super.readValueOfType(type, buffer);
  }
}

/// Mocks the wakelock platform channel and returns the list of requested
/// wakelock states (`true` = enable, `false` = disable) in call order.
List<bool> mockWakelock(WidgetTester tester) {
  const codec = _WakelockMessageCodec();
  final toggles = <bool>[];
  tester.binding.defaultBinaryMessenger.setMockMessageHandler(
    _wakelockToggleChannel,
    (message) async {
      final args = codec.decodeMessage(message)! as List<Object?>;
      final toggleMessage = args.first! as List<Object?>;
      toggles.add(toggleMessage.first! as bool);
      return codec.encodeMessage(<Object?>[]);
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMessageHandler(
      _wakelockToggleChannel,
      null,
    ),
  );
  return toggles;
}
