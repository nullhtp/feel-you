import 'dart:async';

import 'package:feel_you/cloud/cloud_key.dart';
import 'package:feel_you/vibration/vibration_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keeps the assistant's [CloudKey] on the device.
///
/// Every failure is a [CloudKeyStoreException], which never contains the
/// key or the stored value.
abstract interface class CloudKeyStore {
  /// The saved key, or `null` when none is saved.
  Future<CloudKey?> read();

  /// Saves [key], replacing the saved key if there is one.
  Future<void> save(CloudKey key);

  /// Deletes the saved key. Does nothing when none is saved.
  Future<void> delete();
}

/// What a [CloudKeyStore] was doing when it failed.
enum CloudKeyStoreOperation {
  /// Reading the saved key.
  read,

  /// Saving a key.
  save,

  /// Deleting the saved key.
  delete,
}

/// A [CloudKeyStore] operation failed.
///
/// Carries only the [operation] and the platform's error [code], never the
/// platform's message or details, so it is safe to log and to show.
class CloudKeyStoreException implements Exception {
  /// Creates an exception for a failed [operation], with the platform's
  /// error [code] if there is one.
  const CloudKeyStoreException(this.operation, [this.code]);

  /// What the store was doing.
  final CloudKeyStoreOperation operation;

  /// The platform's error code (a `PlatformException.code`, a fixed string
  /// set by the plugin) or the type of the error, or `null`.
  final String? code;

  @override
  String toString() {
    final detail = code == null ? '' : ' ($code)';
    return 'CloudKeyStoreException: could not ${operation.name} the cloud '
        'key$detail';
  }
}

/// A [CloudKeyStore] in the platform's secure storage, through
/// `flutter_secure_storage`.
///
/// - **iOS:** one Keychain item, readable only while the phone is unlocked,
///   tied to this device and not synchronizable: it is neither synced
///   through iCloud Keychain nor restored to another iPhone.
/// - **Android:** the key is AES-GCM encrypted with an AES key that is
///   wrapped by an RSA key held in the Android Keystore. The plugin keeps
///   the encrypted value and the wrapped AES key in its own
///   `SharedPreferences` files (`FlutterSecureStorage.xml`,
///   `FlutterSecureKeyStorage.xml` and
///   `FlutterSecureStorageConfiguration:FlutterSecureStorage.xml`), which
///   the app's backup rules (`android/app/src/main/res/xml/`) leave out of
///   cloud backup and device transfer. Setting a `storageNamespace` would
///   rename these files, so the rules would have to change with it.
///
/// Never the app's own preferences: the key is not in `SharedPreferences`
/// (`UserDefaults` on iOS).
class SecureCloudKeyStore implements CloudKeyStore {
  /// Creates a store in the given secure storage, by default the
  /// platform's, with [iosOptions] on iOS and the plugin's default
  /// `AndroidOptions` on Android: AES-GCM values, an RSA-OAEP key wrap in
  /// the Keystore, no biometrics, and `resetOnError`, which wipes a store
  /// that can no longer be decrypted so that a new key can be saved.
  const SecureCloudKeyStore([
    this._storage = const FlutterSecureStorage(iOptions: iosOptions),
  ]);

  /// The name of the secure storage entry holding the key.
  ///
  /// The plugin's native logs may name the entry, never its value.
  static const storageKey = 'cloud_api_key';

  /// The Keychain options: this device only, readable only while unlocked,
  /// never synchronized.
  static const iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.unlocked_this_device,
    // Stated, although it is the default: the key must never reach iCloud.
    // ignore: avoid_redundant_argument_values
    synchronizable: false,
  );

  final FlutterSecureStorage _storage;

  @override
  Future<CloudKey?> read() async {
    final String? stored;
    try {
      stored = await _storage.read(key: storageKey);
    } on Exception catch (error) {
      throw CloudKeyStoreException(
        CloudKeyStoreOperation.read,
        _errorCode(error),
      );
    }
    // A stored value that is not a key (e.g. written by hand) is no key.
    return stored == null ? null : CloudKey.tryParse(stored);
  }

  @override
  Future<void> save(CloudKey key) async {
    try {
      await _storage.write(key: storageKey, value: key.value);
    } on Exception catch (error) {
      throw CloudKeyStoreException(
        CloudKeyStoreOperation.save,
        _errorCode(error),
      );
    }
  }

  @override
  Future<void> delete() async {
    try {
      await _storage.delete(key: storageKey);
    } on Exception catch (error) {
      throw CloudKeyStoreException(
        CloudKeyStoreOperation.delete,
        _errorCode(error),
      );
    }
  }

  /// The platform's error code, or the error's type: never its message,
  /// which is not under the app's control.
  static String _errorCode(Exception error) => switch (error) {
    PlatformException(:final code) => code,
    _ => error.runtimeType.toString(),
  };
}

/// A [CloudKeyStore] that only lasts as long as the app runs.
///
/// The default of [cloudKeyStoreProvider], so widgets and tests work
/// without the platform's secure storage.
class InMemoryCloudKeyStore implements CloudKeyStore {
  /// Creates a store that starts with the given key saved (none by
  /// default).
  InMemoryCloudKeyStore([this._key]);

  CloudKey? _key;

  @override
  Future<CloudKey?> read() async => _key;

  @override
  Future<void> save(CloudKey key) async => _key = key;

  @override
  Future<void> delete() async => _key = null;
}

/// Provides the [CloudKeyStore].
///
/// `main` overrides it with a [SecureCloudKeyStore]. The default keeps the
/// key in memory only, so widgets and tests work without any setup.
final cloudKeyStoreProvider = Provider<CloudKeyStore>(
  (ref) => InMemoryCloudKeyStore(),
);

/// Provides the [CloudKeyNotifier] and the current [CloudKey], or `null`
/// when none is saved.
///
/// Loading while the key is first read from [cloudKeyStoreProvider]; never
/// an error (see [CloudKeyNotifier.build]).
final cloudKeyProvider = AsyncNotifierProvider<CloudKeyNotifier, CloudKey?>(
  CloudKeyNotifier.new,
);

/// Holds the current [CloudKey] and saves and deletes it.
///
/// The key is read from the store once, when first watched, and kept for
/// the rest of the run; [save] and [delete] update it at once.
class CloudKeyNotifier extends AsyncNotifier<CloudKey?> {
  /// Reads the saved key.
  ///
  /// A store that can't be read gives `null` for this run, logged without
  /// the key: the cloud is off, and the offline core works as usual.
  @override
  Future<CloudKey?> build() async {
    try {
      return await ref.watch(cloudKeyStoreProvider).read();
    } on Exception catch (error) {
      debugPrint(_describe(error));
      return null;
    }
  }

  /// Saves [key] and makes it the current key.
  ///
  /// Waits for the first read, so it can't overwrite this save. Throws the
  /// store's [CloudKeyStoreException] when the key can't be saved, and the
  /// current key then stays as it was.
  Future<void> save(CloudKey key) async {
    await future;
    try {
      await ref.read(cloudKeyStoreProvider).save(key);
    } on Exception catch (error) {
      debugPrint(_describe(error));
      rethrow;
    }
    state = AsyncData(key);
  }

  /// Deletes the saved key, makes the current key `null` and plays the
  /// cloud-off signal, so the user feels that the cloud is off.
  ///
  /// The signal plays even when no key was saved: it tells the user where
  /// they are, not what changed. Completes once it has played. Throws the
  /// store's [CloudKeyStoreException] when the key can't be deleted; the
  /// current key then stays as it was and no signal plays.
  Future<void> delete() async {
    await future;
    try {
      await ref.read(cloudKeyStoreProvider).delete();
    } on Exception catch (error) {
      debugPrint(_describe(error));
      rethrow;
    }
    state = const AsyncData(null);
    try {
      await ref.read(vibrationServiceProvider).playCloudOff();
    } on Exception catch (error) {
      // The key is gone either way, so this is not the caller's failure.
      debugPrint('Could not play the cloud-off signal: $error');
    }
  }

  /// A log line for a store failure, without the key.
  ///
  /// A [CloudKeyStoreException] holds no key; for anything else only the
  /// type is logged.
  static String _describe(Exception error) => switch (error) {
    CloudKeyStoreException() => '$error',
    _ => 'Cloud key store failed (${error.runtimeType})',
  };
}
