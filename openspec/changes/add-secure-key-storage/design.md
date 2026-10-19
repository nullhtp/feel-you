## Context

See proposal.md for why. The relevant current state:

- Settings live in `app/lib/settings/`. Each has an interface, a `SharedPreferences` implementation, an in-memory fallback that is also the provider's default, and a `load…()` function that `main.dart` awaits before `runApp` to override the provider. The language store and the learned-items store follow this shape.
- Signals are `SignalPattern` constants in `vibration/signal_pattern.dart`, played by `DeviceVibrationService` in one `Vibration.vibrate(pattern:, intensities:)` call and then awaited for their total duration. Success and error have duration-only variants for motors without amplitude control, because Android reads `pattern:` as `[wait, vibrate, …]` when it drops the intensities.
- The companion overlay is one `Stack` with a single live-region `Semantics` node whose label is `companionOverlaySummary(...)`. The vibration readout (`VibrationDiagnostics`) sits in the bottom-left corner; the bottom-right corner is empty.
- The app has no network code, and nothing in the app will save a key until #63 adds the assistant screen.
- `flutter_secure_storage` 11.2.0 is the current release. On iOS it stores a generic-password Keychain item per entry and builds with Swift Package Manager. On Android, with the default options, it stores values AES-GCM encrypted in a private `SharedPreferences` file, wraps the AES key with an RSA-OAEP key held in the Android Keystore, and writes three files under `shared_prefs/`: `FlutterSecureStorage.xml` (the encrypted values), `FlutterSecureKeyStorage.xml` (the wrapped AES key) and `FlutterSecureStorageConfiguration:FlutterSecureStorage.xml` (cipher and migration markers). It also reads, but never writes, a legacy `FlutterSecureStorageConfiguration.xml`. The Keystore key itself is not a file and is never backed up.

## Goals / Non-Goals

**Goals:**
- One small API that #62 (read the key for each request) and #63 (save, delete, show it masked) can use as it is.
- Make it hard to leak the key by accident: a value type whose `toString` is masked, no logging of the key, errors without it.
- Keep the offline core unaffected: a broken secure storage never stops a lesson.

**Non-Goals:**
- A general secrets layer. One entry, one store.
- Moving the language or learned items into secure storage.

## Decisions

### 1. A new `lib/cloud/` area

`cloud_key.dart` (the value type and masking) and `cloud_key_store.dart` (store interface, implementations, providers and the notifier), exported from `cloud.dart`. The OpenRouter client (#62) and the cloud status signals (#64) belong next to them.

Alternative: *`lib/settings/cloud_key.dart`.* Rejected: the key is the first piece of the cloud features, not a lesson setting, and the settings area stays about what the user learns.

### 2. `CloudKey`: a validated value with a masked `toString`

- `CloudKey.tryParse(String input)` trims surrounding whitespace and returns `null` unless the rest is 1 to 512 characters, all in `!`…`~`. This is what an HTTP `Authorization: Bearer` header can carry without escaping, so a pasted key with a line break or a stray word is caught before it is saved. 512 is far above OpenRouter's ~73 characters and other OpenAI-compatible keys, and stops a whole paragraph from being saved by mistake. `CloudKey.parse` throws a `FormatException` whose message never contains the input.
- `value` is the raw key, for the client's header. `masked` is the masked form (spec: *Masked form of the key*). `toString()` returns `CloudKey(<masked>)`. Equality compares `value`. It does not use `Equatable`, whose `toString` would print its fields.
- `maskCloudKey(String)` is a pure top-level function, so the masking rules are tested without building keys.

Masking rule: keep `sk-or-` when present, then `...`, then the last 4 characters only when at least 12 characters (not counting `sk-or-`) stay hidden. A real OpenRouter key (`sk-or-v1-` and 64 hex digits) hides 63 characters. A short or unknown key shows nothing but `...` rather than a large part of itself. A non-OpenRouter key shows no prefix, since for an unknown format the start may be secret too.

Alternative: *pass the key around as a `String`.* Rejected: any `'$state'`, `print(list)` or error message would print it in full.

### 3. `CloudKeyStore` with a secure and an in-memory implementation

```dart
abstract interface class CloudKeyStore {
  Future<CloudKey?> read();
  Future<void> save(CloudKey key);
  Future<void> delete();
}
```

- `SecureCloudKeyStore` wraps `FlutterSecureStorage` with one entry, `cloud_api_key`. A stored value that is not a valid key (e.g. written by hand) reads as no key. Every platform failure is caught and rethrown as `CloudKeyStoreException(operation, code)`: a fixed message plus the `PlatformException.code`, never the plugin's message or details. The plugin's own native logs name the entry (`cloud_api_key`), never its value.
- `InMemoryCloudKeyStore` keeps the key for the run. It is the provider's default, as for the other settings, so widget tests and the overlay work without any platform channel. `main.dart` overrides `cloudKeyStoreProvider` with a `SecureCloudKeyStore`. Unlike the other stores there is nothing to load before `runApp`: the plugin needs no setup and the key is read lazily (decision 6).

Alternative: *the secure store as the provider default.* Rejected: every widget test that shows the overlay would hit a missing platform channel and log a failure.

### 4. Platform options

| Platform | Option | Value | Why |
|---|---|---|---|
| iOS | `accessibility` | `KeychainAccessibility.unlocked_this_device` (`kSecAttrAccessibleWhenUnlockedThisDeviceOnly`) | Never migrates to another device through a backup or iCloud Keychain; readable only while unlocked, which is the only time the app makes cloud requests (it stops in the background) |
| iOS | `synchronizable` | `false` | Not in iCloud Keychain |
| iOS | `accountName` (service) | plugin default | One entry; nothing to share with other apps |
| Android | constructor | `AndroidOptions()` defaults | AES-GCM values, RSA-OAEP key wrap in the Keystore, `resetOnError: true` (an undecryptable store is wiped instead of failing for ever), no biometrics |
| Android | `storageNamespace` | not set | Keeps the three default file names that the backup rules list |

`unlocked_this_device` is the strictest level that needs no passcode. The plugin finds an item whatever its accessibility, so a later change (for example to `first_unlock_this_device`, if a Phase 4 background feature needs the key while the phone is locked) only needs a rewrite of the item.

Alternative: *`first_unlock_this_device`.* Rejected for now: nothing reads the key while the phone is locked.

### 5. Android backup rules

Two resource files, referenced from `<application>`:

- `res/xml/backup_rules.xml` (`android:fullBackupContent`, Android 11 and lower): `<full-backup-content>` with three `<exclude domain="sharedpref" path="…"/>`.
- `res/xml/data_extraction_rules.xml` (`android:dataExtractionRules`, Android 12 and higher): the same three excludes under both `<cloud-backup>` and `<device-transfer>`.

Only exclude rules, so everything else is still backed up by default, including `FlutterSharedPreferences.xml` (language and learned items). `android:allowBackup` stays unset (`true`). Excluding all three files keeps the plugin's state consistent: a restore can't bring back encrypted values or markers without the Keystore key that matches them, which is the `Failed to unwrap key` error the plugin's README warns about.

Alternative: *`android:allowBackup="false"`.* Rejected: the user's language and learned items would no longer move to a new phone.

### 6. The current key: an `AsyncNotifier`

`cloudKeyProvider` is an `AsyncNotifierProvider<CloudKeyNotifier, CloudKey?>`:

- `build()` reads the store once. A failure is logged (`Could not read the cloud key (<code>)`) and gives `null`, so the provider never ends in an error and the offline core is unaffected.
- `save(key)` and `delete()` first await the initial read, so a late read can't overwrite them. They then write to the store and only on success set the state. A `CloudKeyStoreException` reaches the caller (#63 can tell the assistant) with the state unchanged.
- `delete()` then plays `playCloudOff()` and completes once the signal has played. A vibration failure after a successful deletion is logged, not thrown, because the key is gone either way.
- Deleting when there is no key still plays the signal: the user is told the state they end up in, not whether it changed.

The overlay watches the provider: `AsyncLoading` shows `checking…`, data shows the masked key or `none`. Riverpod rebuilds it after `save` and `delete`.

Alternative: *load the key in `main` before `runApp`, like the other settings.* Rejected: Android's first secure-storage access generates a Keystore key and can take a noticeable time on slow phones, and the first frame (the picker the user feels) must not wait for a feature it doesn't use yet.

### 7. The cloud-off signal

```text
  0ms  700ms                       300ms        700ms
       ███████████████████████     ·········    ███████████████████████
```

`cloudOffSignal = SignalPattern([0, 700, 300, 700], [0, 255, 0, 255])`, 1700 ms. It starts with a 0 ms off segment and alternates off/on at intensities 0 and 255, the shape of the duration-only signals, so it feels the same whether or not the platform honours `intensities:` and needs no variant: `playCloudOff()` always sends it. It is a plain timing pattern like the other signals, so the engine stays free of Morse (`vibration-engine`: *The vibration engine has no Morse dependency*). `VibrationService.playCloudOff()` sits next to `playTokens` and the other signals, is implemented by `DeviceVibrationService` through the existing `_playSignal`, and recorded by `MockVibrationService` and the integration tests' `RecordingVibrationService`.

| Signal | With amplitude control | Without |
|---|---|---|
| Correct | five 50 ms taps, 40 ms gaps (410 ms) | five 50 ms taps, 60 ms gaps (490 ms) |
| Wrong | one 500 ms buzz | one 700 ms buzz |
| Cloud off | two 700 ms buzzes, 300 ms gap (1700 ms) | same |

Each buzz is more than twice a Morse dash (300 ms), so it can't be read as Morse. The 300 ms gap equals the Morse letter gap, but the buzzes around it are not Morse elements. Cloud off differs from wrong by having two buzzes, which still holds on a motor without amplitude control, where wrong is also 700 ms.

### 8. Overlay line and summary

A new `CloudKeyStatus` widget (`ui/cloud_key_status.dart`) in the overlay's `Stack`, bottom-right, mirroring `VibrationDiagnostics`: 12 px white at 50 % opacity, inside a `SafeArea`. `describeCloudKey(AsyncValue<CloudKey?>)` gives the value (`sk-or-...a1b2`, `none`, `checking…`) for both the line (`Cloud key: <value>`) and the summary. `companionOverlaySummary` gains an optional `cloudKey` value; the overlay always passes it, and the summary appends `cloud key <value>` as its last part, after the input. This extends the reading order of *Screen-reader summary of the lesson*, which the delta modifies rather than contradicts. The summary changes only when the value does, so the live region re-announces after a save or a deletion.

## Risks / Trade-offs

- [iOS keeps Keychain items after the app is deleted, so reinstalling on the same iPhone finds the key again] → Documented in the privacy policy and README. The key can be deleted in the app (once #63 adds the screen) or by erasing the phone. Wiping it on the first launch after an install would need a marker in `UserDefaults`, and is left as an open question.
- [`resetOnError: true` erases the key when the Android store can't be decrypted] → The key is useless in that state anyway; the overlay shows `none` and the assistant enters it again.
- [Nothing in the app can save a key yet, so the overlay always says `none` in this release] → Intended: #63 adds the screen. The line also tells a helper that the cloud is off.
- [The plugin brings `path_provider` and its native-asset packages (`jni`, `objective_c`) through its Windows implementation] → They are compiled into both apps but unused. Accepted, rather than a `dependency_overrides` hack.
- [The live-region summary gets longer] → Only by a few words, at the end, after everything a lesson needs.
- [The real Keychain and Keystore are only exercised on a device] → The end-to-end test runs the real plugin on the iOS simulator through the `E2EApp` harness; the unit tests check the options sent over the method channel.
- [On the lesson surface the teaching loop keeps playing, so its next pattern can cut the cloud-off signal short] → Nothing deletes the key from the lesson surface. The assistant screen (#63) will cover it, which stops the loop, before it calls `delete()`.

## Migration Plan

No migration: no key has ever been stored. Rollback is a revert; an older build ignores the Keychain item and the encrypted file.

## Open Questions

- Should the first launch after an install remove a Keychain item left by an earlier install on the same iPhone?
- Should a later phase switch the Keychain accessibility to `first_unlock_this_device`, if a background feature needs the key while the phone is locked?
- Is 512 characters the right upper limit for keys from custom OpenAI-compatible endpoints (#62)?
