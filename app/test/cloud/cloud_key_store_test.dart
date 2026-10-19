import 'package:feel_you/cloud/cloud.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The method channel `flutter_secure_storage` talks to on iOS and Android.
const _channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

final _key = CloudKey.parse('sk-or-v1-${'0123456789abcdef' * 4}');

/// A stand-in for the platform side of `flutter_secure_storage`: keeps the
/// values in a map and records every call.
class _FakeSecureStorage {
  _FakeSecureStorage() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, _handle);
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, null),
    );
  }

  final Map<String, String> values = {};
  final List<MethodCall> calls = [];

  /// When set, every call fails with this error.
  Exception? failWith;

  Future<Object?> _handle(MethodCall call) async {
    calls.add(call);
    final failure = failWith;
    if (failure != null) throw failure;
    final arguments = call.arguments as Map<Object?, Object?>;
    final key = arguments['key'] as String?;
    switch (call.method) {
      case 'write':
        values[key!] = arguments['value']! as String;
        return null;
      case 'read':
        return values[key];
      case 'delete':
        values.remove(key);
        return null;
      case 'containsKey':
        return values.containsKey(key);
    }
    return null;
  }

  /// The options sent with the last call to [method].
  Map<Object?, Object?> optionsOf(String method) =>
      (calls.lastWhere((c) => c.method == method).arguments
              as Map<Object?, Object?>)['options']!
          as Map<Object?, Object?>;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SecureCloudKeyStore', () {
    test('nothing is saved at first', () async {
      _FakeSecureStorage();
      expect(await const SecureCloudKeyStore().read(), isNull);
    });

    test('saves, reads back and deletes the key in one entry', () async {
      final storage = _FakeSecureStorage();
      const store = SecureCloudKeyStore();

      await store.save(_key);
      expect(storage.values, {'cloud_api_key': _key.value});
      expect(await const SecureCloudKeyStore().read(), _key);

      await store.delete();
      expect(storage.values, isEmpty);
      expect(await store.read(), isNull);
    });

    test('reads a stored value that is not a key as no key', () async {
      final storage = _FakeSecureStorage();
      storage.values['cloud_api_key'] = 'not a key';

      expect(await const SecureCloudKeyStore().read(), isNull);
    });

    test('keeps the Keychain item on this device, readable only while '
        'unlocked, never synchronized', () async {
      final storage = _FakeSecureStorage();
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      await const SecureCloudKeyStore().save(_key);
      await const SecureCloudKeyStore().read();
      await const SecureCloudKeyStore().delete();

      for (final method in ['write', 'read', 'delete']) {
        final options = storage.optionsOf(method);
        expect(
          options['accessibility'],
          'unlocked_this_device',
          reason: method,
        );
        expect(options['synchronizable'], 'false', reason: method);
        expect(options['groupId'], isNull, reason: method);
      }
    });

    test('uses the default Android ciphers in the default files, and wipes '
        'a store it cannot decrypt', () async {
      final storage = _FakeSecureStorage();
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      await const SecureCloudKeyStore().save(_key);

      final options = storage.optionsOf('write');
      expect(options['resetOnError'], 'true');
      expect(
        options['keyCipherAlgorithm'],
        'RSA_ECB_OAEPwithSHA_256andMGF1Padding',
      );
      expect(options['storageCipherAlgorithm'], 'AES_GCM_NoPadding');
      expect(options['enforceBiometrics'], 'false');
      // No namespace: the backup rules list the default file names.
      expect(options['storageNamespace'], '');
    });

    group('failures', () {
      final failures = <String, Exception>{
        'PlatformException': PlatformException(
          code: 'Unexpected security result code',
          message: 'Code: -25308, value ${_key.value}',
          details: _key.value,
        ),
        'MissingPluginException': MissingPluginException(_key.value),
      };
      const expectedCodes = {
        'PlatformException': 'Unexpected security result code',
        'MissingPluginException': 'MissingPluginException',
      };

      for (final MapEntry(key: name, value: failure) in failures.entries) {
        test('a $name becomes a CloudKeyStoreException without the key', () {
          final storage = _FakeSecureStorage()..failWith = failure;
          const store = SecureCloudKeyStore();

          Matcher failed(CloudKeyStoreOperation operation) => throwsA(
            isA<CloudKeyStoreException>()
                .having((e) => e.operation, 'operation', operation)
                .having((e) => e.code, 'code', expectedCodes[name])
                .having((e) => '$e', 'text', isNot(contains(_key.value)))
                .having((e) => '$e', 'text', isNot(contains('0123456789'))),
          );

          expect(store.read, failed(CloudKeyStoreOperation.read));
          expect(() => store.save(_key), failed(CloudKeyStoreOperation.save));
          expect(store.delete, failed(CloudKeyStoreOperation.delete));
          expect(storage.values, isEmpty);
        });
      }
    });

    test("never writes the key to the app's preferences", () async {
      SharedPreferences.setMockInitialValues({'selected_language': 'english'});
      _FakeSecureStorage();

      await const SecureCloudKeyStore().save(_key);
      expect(await const SecureCloudKeyStore().read(), _key);

      SharedPreferences.resetStatic();
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getKeys(), {'selected_language'});
      for (final name in preferences.getKeys()) {
        expect('${preferences.get(name)}', isNot(contains(_key.value)));
      }
    });
  });

  group('InMemoryCloudKeyStore', () {
    test('saves, reads back and deletes the key', () async {
      final store = InMemoryCloudKeyStore();
      expect(await store.read(), isNull);

      await store.save(_key);
      expect(await store.read(), _key);

      await store.delete();
      expect(await store.read(), isNull);
    });

    test('can start with a key', () async {
      expect(await InMemoryCloudKeyStore(_key).read(), _key);
    });
  });

  group('CloudKeyStoreException', () {
    test('names the operation and the code', () {
      expect(
        '${const CloudKeyStoreException(CloudKeyStoreOperation.save, 'E1')}',
        'CloudKeyStoreException: could not save the cloud key (E1)',
      );
      expect(
        '${const CloudKeyStoreException(CloudKeyStoreOperation.read)}',
        'CloudKeyStoreException: could not read the cloud key',
      );
    });
  });
}
