import CoreHaptics
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    VibratorChannel.register(with: engineBridge.applicationRegistrar.messenger())
  }
}

/// Answers vibration hardware queries from Dart on the `feel_you/vibrator`
/// channel (see `DeviceVibrationCapabilityProbe` in
/// `lib/vibration/vibration_capability_probe.dart`), like `MainActivity.kt`
/// on Android.
///
/// The `vibration` plugin's iOS capability checks only ask whether the
/// device is physical, so they report a motor on an iPad, which can't
/// vibrate. This asks the hardware itself.
///
/// Methods, each answering a `Bool`:
/// - `hasVibrator`: whether the device has a vibration motor.
/// - `hasAmplitudeControl`: whether it can vibrate at different strengths.
///
/// Any other method is not implemented. The Dart side treats that as
/// "unknown".
private enum VibratorChannel {
  static func register(with messenger: FlutterBinaryMessenger) {
    FlutterMethodChannel(name: "feel_you/vibrator", binaryMessenger: messenger)
      .setMethodCallHandler { call, result in
        switch call.method {
        case "hasVibrator": result(hasVibrator())
        case "hasAmplitudeControl": result(supportsHaptics())
        default: result(FlutterMethodNotImplemented)
        }
      }
  }

  /// Whether the device has a vibration motor.
  ///
  /// Every iPhone has one; no iPad, iPod touch, Mac or Apple Vision Pro
  /// does. Core Haptics alone would miss the iPhone 6s and 7: they run
  /// iOS 15 and vibrate, but only with the fixed system buzz. The device
  /// model is asked rather than the interface idiom, which is `.phone` for
  /// an iPhone app running on an iPad. The simulator reports an iPhone
  /// model but has no motor.
  private static func hasVibrator() -> Bool {
    #if targetEnvironment(simulator)
      return false
    #else
      return supportsHaptics() || UIDevice.current.model == "iPhone"
    #endif
  }

  /// Whether Core Haptics can play on this device (iPhone 8 and later). The
  /// plugin then plays patterns at the requested intensity; without it every
  /// vibration is the same fixed system buzz, at one strength.
  private static func supportsHaptics() -> Bool {
    CHHapticEngine.capabilitiesForHardware().supportsHaptics
  }
}
