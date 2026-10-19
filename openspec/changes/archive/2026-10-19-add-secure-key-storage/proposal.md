## Why

Phase 2 (#35) brings the cloud: the assistant enters their own OpenRouter key once, and the app uses it for every cloud request. There is no server, so the key lives on the phone. It is a credential that spends the assistant's money, so it must be kept in the platform's secure storage, stay on that phone, and never show up in full on screen or in a log. The OpenRouter client (#62) and the assistant screen (#63) both need a place to read and write it first (#61).

## What Changes

- **A cloud key store.** The key is saved, read back and deleted through an injectable store backed by `flutter_secure_storage`: the iOS Keychain, and on Android values encrypted with a key held in the Android Keystore. It is never written to `SharedPreferences`. The current key is exposed through Riverpod like the other settings, so the overlay and, later, the OpenRouter client (#62) and the assistant screen (#63) see changes at once.
- **The key stays on this phone.** On iOS the Keychain item is "this device only" and not synchronizable: it is neither synced through iCloud Keychain nor restored to another iPhone. On Android the plugin's storage files are excluded from cloud backup and device-to-device transfer (backup rules for Android 11 and lower, data extraction rules for 12 and higher). The app's other preferences (language, learned items) keep backing up as today.
- **A key value with a masked form.** Keys are trimmed and checked (printable ASCII, no spaces, at most 512 characters). The masked form keeps the `sk-or-` prefix and the last 4 characters (`sk-or-...a1b2`), and shows fewer characters for short or non-OpenRouter keys. The key's `toString` is the masked form, and the app never logs the key.
- **Deleting the key plays a new *cloud off* signal:** two 700 ms buzzes, 300 ms apart (1.7 s). It is timing only, so it is the same on motors with and without amplitude control.
- **The companion overlay shows the key**, masked: `Cloud key: sk-or-...a1b2`, or `Cloud key: none`. The screen-reader summary says the same, masked. Both update when the key is saved or deleted.

## Accessibility

- The user never sees the key or the overlay. Deleting the key changes what the phone can do for them (the cloud stops working), so it is confirmed by the cloud-off signal, in line with "every action is confirmed by vibration".
- The cloud-off signal is two buzzes longer than twice a Morse dash, so it can't be read as Morse. It differs from the wrong-answer buzz by the number of buzzes, which holds even on a motor without amplitude control, where the wrong buzz also lasts 700 ms.
- The overlay line is for a sighted helper checking which key is set. It never shows enough of the key to use it.

## Non-goals

- No screen or gesture to enter, paste, scan or delete the key. The assistant screen (#63) adds them and calls this store; until then nothing in the app saves a key.
- No network use, key validation against OpenRouter (`GET /auth/key`) or *cloud available* signal (#62, #63).
- No other network or cloud status signals (#64), which may later fold *cloud off* into its set.
- No removal of a key left in the iOS Keychain by an earlier install (see design.md).
- No biometric or passcode prompt to read the key.
- No change to how the language and learned items are stored or backed up.

## Capabilities

### New Capabilities

- `cloud-key-storage`: where and how the cloud (OpenRouter) key is kept, what makes a valid key, its masked form, the rule that it is never logged, and deleting it with the cloud-off signal.

### Modified Capabilities

- `vibration-engine`: a new cloud-off signal, played the same way on every motor, and `playCloudOff` in the service's list of methods.
- `companion-overlay`: the masked cloud key line, and the screen-reader summary of the lesson ending with the cloud key.
- `release-build-config`: Android backup and device-transfer rules that leave out the secure storage files.
- `integration-testing`: an end-to-end test of the key with the real secure storage plugin.

## Impact

- **Dependency:** `flutter_secure_storage` ^11.2.0 (iOS through Swift Package Manager, no CocoaPods; Android minSdk 24, as the app). It pulls in the federated platform packages, including `path_provider` for Windows.
- **New code:** `app/lib/cloud/` with the key value, masking, the store interface, its secure and in-memory implementations, and the Riverpod providers. `main.dart` injects the secure store.
- **Vibration** (`signal_pattern.dart`, `vibration_service.dart`, `device_vibration_service.dart`): the cloud-off pattern and `playCloudOff()`, next to `playTokens` and the other signals; nothing in it depends on Morse. Test doubles (`MockVibrationService`, `RecordingVibrationService`, and the recorded-sequence switch of `vibration_sequence_test.dart`) gain the call.
- **UI:** a cloud key line in the overlay (`companion_overlay.dart`, new `cloud_key_status.dart`) and in `companionOverlaySummary`.
- **Android:** `res/xml/backup_rules.xml`, `res/xml/data_extraction_rules.xml` and two attributes in `AndroidManifest.xml`. **iOS:** no project change; the Keychain options are set in Dart.
- **Docs:** README (signals table, helper overlay, what the app saves), `store/privacy-policy.md`, `store/store-info.md`, `app/README.md` layout, CHANGELOG.
- **Tests:** unit tests for validation and masking, the stores and the notifier, the backup rules, the cloud-off pattern on both motor kinds, the overlay line and summary; an end-to-end test on the `E2EApp` harness with the real secure storage plugin on a device.
