package com.feelyou.app

import android.content.Context
import android.os.Build
import android.os.Vibrator
import android.os.VibratorManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        VibratorChannel(applicationContext).register(flutterEngine)
    }
}

/**
 * Answers vibration hardware queries from Dart on the `feel_you/vibrator`
 * channel (see `DeviceVibrationCapabilityProbe` in
 * `lib/vibration/vibration_capability_probe.dart`).
 *
 * The `vibration` plugin's Android capability checks only ask whether the
 * device is physical, so they report a motor on a motorless tablet and none
 * on every emulator. This asks the system [Vibrator] itself.
 *
 * Methods, each answering a `Boolean`:
 * - `hasVibrator`: whether the default vibrator has a motor.
 * - `hasAmplitudeControl`: whether it can vibrate at different strengths.
 *
 * Any other method is not implemented, and an unexpected failure is
 * reported as an error. The Dart side treats both as "unknown".
 */
private class VibratorChannel(private val context: Context) {
    fun register(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "hasVibrator" -> result.success(hasVibrator())
                        "hasAmplitudeControl" -> result.success(hasAmplitudeControl())
                        else -> result.notImplemented()
                    }
                } catch (e: RuntimeException) {
                    result.error("unavailable", e.message, null)
                }
            }
    }

    /**
     * The device's default vibrator, or `null` when the system offers no
     * vibrator service at all.
     *
     * API 31 (S) replaced the single vibrator service with [VibratorManager].
     * Older levels, down to minSdk 24, look the [Vibrator] service up by
     * class, which is available since API 23.
     */
    private fun defaultVibrator(): Vibrator? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            context.getSystemService(VibratorManager::class.java)?.defaultVibrator
        } else {
            context.getSystemService(Vibrator::class.java)
        }

    /**
     * Whether the device has a vibration motor. Without a vibrator service
     * nothing the app plays can be felt, so that also answers `false`.
     */
    private fun hasVibrator(): Boolean = defaultVibrator()?.hasVibrator() == true

    /**
     * Whether the motor supports amplitude control. The API arrived in
     * API 26 (O); below that the plugin always vibrates at the default
     * strength, so the answer is `false`.
     */
    private fun hasAmplitudeControl(): Boolean =
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            defaultVibrator()?.hasAmplitudeControl() == true

    private companion object {
        const val CHANNEL = "feel_you/vibrator"
    }
}
