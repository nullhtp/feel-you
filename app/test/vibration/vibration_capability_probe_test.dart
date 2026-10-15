import 'package:feel_you/vibration/vibration.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The method channel the `vibration` plugin talks to.
const _pluginChannel = MethodChannel('vibration');

/// Mocks [channel] with [handler] for the current test and returns the
/// methods called on it, in order.
List<String> _mockChannel(
  MethodChannel channel,
  Future<Object?> Function(MethodCall call) handler,
) {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final methods = <String>[];
  messenger.setMockMethodCallHandler(channel, (call) {
    methods.add(call.method);
    return handler(call);
  });
  addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
  return methods;
}

/// Mocks [vibratorChannel] to answer each method from [answers], and returns
/// the methods called on it.
List<String> _mockVibratorChannel(Map<String, bool> answers) =>
    _mockChannel(vibratorChannel, (call) async => answers[call.method]);

/// Mocks the plugin's channel to report custom vibration support, and
/// returns the methods called on it.
List<String> _mockPluginChannel() =>
    _mockChannel(_pluginChannel, (call) async => true);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DeviceVibrationCapabilityProbe on Android', () {
    const probe = DeviceVibrationCapabilityProbe(
      platform: TargetPlatform.android,
    );

    test('asks the native channel whether there is a motor', () async {
      final methods = _mockVibratorChannel({'hasVibrator': false});

      expect(await probe.hasVibrator(), isFalse);
      expect(methods, ['hasVibrator']);
    });

    test('reports a motor when the native channel finds one', () async {
      _mockVibratorChannel({'hasVibrator': true});

      expect(await probe.hasVibrator(), isTrue);
    });

    test('asks the native channel about amplitude control', () async {
      final methods = _mockVibratorChannel({'hasAmplitudeControl': true});

      expect(await probe.hasAmplitudeControl(), isTrue);
      expect(methods, ['hasAmplitudeControl']);
    });

    test('asks the plugin about custom vibrations', () async {
      final native = _mockVibratorChannel({});
      final plugin = _mockPluginChannel();

      expect(await probe.hasCustomVibrationsSupport(), isTrue);
      expect(plugin, ['hasCustomVibrationsSupport']);
      expect(native, isEmpty);
    });

    test('detects a motorless device', () async {
      _mockVibratorChannel({
        'hasVibrator': false,
        'hasAmplitudeControl': false,
      });
      _mockPluginChannel();

      final caps = await detectVibrationCapabilities(probe);

      expect(
        caps,
        const VibrationCapabilities(
          hasVibrator: false,
          hasAmplitudeControl: false,
          hasCustomVibrationsSupport: true,
        ),
      );
      expect(caps.canVibrate, isFalse);
    });

    test('channel errors degrade to unknown', () async {
      _mockChannel(
        vibratorChannel,
        (call) async => throw PlatformException(code: 'unavailable'),
      );
      _mockPluginChannel();

      final caps = await detectVibrationCapabilities(probe);

      expect(caps.hasVibrator, isNull);
      expect(caps.hasAmplitudeControl, isNull);
      expect(caps.canVibrate, isTrue);
      expect(caps.hasCustomVibrationsSupport, isTrue);
    });

    test('a missing native channel degrades to unknown', () async {
      // No handler: invokeMethod throws MissingPluginException, as it does
      // when the engine was not created by MainActivity.
      _mockPluginChannel();

      final caps = await detectVibrationCapabilities(probe);

      expect(caps.hasVibrator, isNull);
      expect(caps.hasAmplitudeControl, isNull);
      expect(caps.canVibrate, isTrue);
    });

    test('a null answer is unknown', () async {
      _mockVibratorChannel({});

      expect(await probe.hasVibrator(), isNull);
      expect(await probe.hasAmplitudeControl(), isNull);
    });
  });

  group('DeviceVibrationCapabilityProbe on iOS', () {
    test('never asks the Android channel', () async {
      const probe = DeviceVibrationCapabilityProbe(
        platform: TargetPlatform.iOS,
      );
      final native = _mockVibratorChannel({
        'hasVibrator': true,
        'hasAmplitudeControl': true,
      });
      final plugin = _mockPluginChannel();

      await detectVibrationCapabilities(probe);

      expect(native, isEmpty);
      expect(plugin, ['hasCustomVibrationsSupport']);
    });
  });

  group('DeviceVibrationCapabilityProbe elsewhere', () {
    for (final (where, probe) in [
      // The host running the tests is neither Android nor iOS.
      ('on the test host', const DeviceVibrationCapabilityProbe()),
      (
        'on macOS',
        const DeviceVibrationCapabilityProbe(platform: TargetPlatform.macOS),
      ),
    ]) {
      test('reports unknown $where without asking anyone', () async {
        final native = _mockVibratorChannel({'hasVibrator': false});
        final plugin = _mockPluginChannel();

        final caps = await detectVibrationCapabilities(probe);

        expect(caps, VibrationCapabilities.unknown);
        expect(native, isEmpty);
        expect(plugin, isEmpty);
      });
    }
  });
}
