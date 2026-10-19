import 'dart:async';

import 'package:feel_you/cloud/cloud.dart';
import 'package:feel_you/vibration/vibration_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_doubles/mock_vibration_service.dart';

final _key = CloudKey.parse('sk-or-v1-${'0123456789abcdef' * 4}');
final _otherKey = CloudKey.parse('sk-or-v1-${'fedcba9876543210' * 4}');

/// A [CloudKeyStore] whose reads can be held back and whose operations can
/// be made to fail.
class _FakeStore implements CloudKeyStore {
  _FakeStore([this.key]);

  CloudKey? key;
  int reads = 0;

  /// While set and not completed, [read] waits for it.
  Completer<void>? readGate;

  bool failRead = false;
  bool failSave = false;
  bool failDelete = false;

  @override
  Future<CloudKey?> read() async {
    reads++;
    await readGate?.future;
    if (failRead) {
      throw const CloudKeyStoreException(CloudKeyStoreOperation.read, 'E');
    }
    return key;
  }

  @override
  Future<void> save(CloudKey key) async {
    if (failSave) {
      throw const CloudKeyStoreException(CloudKeyStoreOperation.save, 'E');
    }
    this.key = key;
  }

  @override
  Future<void> delete() async {
    if (failDelete) {
      throw const CloudKeyStoreException(CloudKeyStoreOperation.delete, 'E');
    }
    key = null;
  }
}

/// Records, at each cloud-off signal, the current key at that moment.
class _KeyAtSignal extends MockVibrationService {
  _KeyAtSignal(this.readKey);

  final AsyncValue<CloudKey?> Function() readKey;
  final List<AsyncValue<CloudKey?>> keysAtSignal = [];

  @override
  Future<void> playCloudOff() async {
    keysAtSignal.add(readKey());
    await super.playCloudOff();
  }
}

/// Fails to play the cloud-off signal.
class _BrokenCloudOff extends MockVibrationService {
  @override
  Future<void> playCloudOff() async => throw Exception('no motor');
}

ProviderContainer _container(
  CloudKeyStore store, [
  MockVibrationService? vibration,
]) {
  final container = ProviderContainer(
    overrides: [
      cloudKeyStoreProvider.overrideWithValue(store),
      vibrationServiceProvider.overrideWithValue(
        vibration ?? MockVibrationService(),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('CloudKeyNotifier', () {
    test('loads the saved key, reading the store once', () async {
      final store = _FakeStore(_key);
      final container = _container(store);

      expect(container.read(cloudKeyProvider), isA<AsyncLoading<CloudKey?>>());
      expect(await container.read(cloudKeyProvider.future), _key);
      expect(await container.read(cloudKeyProvider.future), _key);
      expect(store.reads, 1);
    });

    test('is none when nothing is saved', () async {
      final container = _container(_FakeStore());
      expect(await container.read(cloudKeyProvider.future), isNull);
    });

    test('a store that cannot be read gives none, not an error', () async {
      final container = _container(_FakeStore(_key)..failRead = true);

      expect(await container.read(cloudKeyProvider.future), isNull);
      final state = container.read(cloudKeyProvider);
      expect(state.hasError, isFalse);
      expect(state.value, isNull);
    });

    test('save stores the key and makes it current', () async {
      final store = _FakeStore();
      final vibration = MockVibrationService();
      final container = _container(store, vibration);

      await container.read(cloudKeyProvider.notifier).save(_key);

      expect(store.key, _key);
      expect(container.read(cloudKeyProvider).value, _key);
      expect(vibration.calls, isEmpty);
    });

    test('a failed save reaches the caller and changes nothing', () async {
      final store = _FakeStore(_key)..failSave = true;
      final vibration = MockVibrationService();
      final container = _container(store, vibration);
      await container.read(cloudKeyProvider.future);

      await expectLater(
        container.read(cloudKeyProvider.notifier).save(_otherKey),
        throwsA(isA<CloudKeyStoreException>()),
      );

      expect(store.key, _key);
      expect(container.read(cloudKeyProvider).value, _key);
      expect(vibration.calls, isEmpty);
    });

    test('a save during the first read is not overwritten by it', () async {
      final store = _FakeStore(_key)..readGate = Completer<void>();
      final container = _container(store);

      // Creating the notifier starts the first read, held by the gate.
      final saving = container.read(cloudKeyProvider.notifier).save(_otherKey);
      await Future<void>.delayed(Duration.zero);
      expect(store.reads, 1);
      expect(container.read(cloudKeyProvider).isLoading, isTrue);
      store.readGate!.complete();
      await saving;

      expect(store.key, _otherKey);
      expect(container.read(cloudKeyProvider).value, _otherKey);
    });

    test(
      'delete removes the key, then plays the cloud-off signal once',
      () async {
        final store = _FakeStore(_key);
        late final ProviderContainer container;
        final vibration = _KeyAtSignal(() => container.read(cloudKeyProvider));
        container = _container(store, vibration);
        await container.read(cloudKeyProvider.future);

        await container.read(cloudKeyProvider.notifier).delete();

        expect(store.key, isNull);
        expect(container.read(cloudKeyProvider).value, isNull);
        expect(vibration.callLog, ['playCloudOff']);
        // The current key was already none when the signal started.
        expect(vibration.keysAtSignal.single.value, isNull);
        expect(vibration.keysAtSignal.single.isLoading, isFalse);
      },
    );

    test('delete with no key saved still plays the cloud-off signal', () async {
      final vibration = MockVibrationService();
      final container = _container(_FakeStore(), vibration);

      await container.read(cloudKeyProvider.notifier).delete();

      expect(container.read(cloudKeyProvider).value, isNull);
      expect(vibration.callLog, ['playCloudOff']);
    });

    test('a failed delete reaches the caller, keeps the key and plays '
        'nothing', () async {
      final store = _FakeStore(_key)..failDelete = true;
      final vibration = MockVibrationService();
      final container = _container(store, vibration);
      await container.read(cloudKeyProvider.future);

      await expectLater(
        container.read(cloudKeyProvider.notifier).delete(),
        throwsA(isA<CloudKeyStoreException>()),
      );

      expect(store.key, _key);
      expect(container.read(cloudKeyProvider).value, _key);
      expect(vibration.calls, isEmpty);
    });

    test('a failed cloud-off signal does not fail the deletion', () async {
      final store = _FakeStore(_key);
      final container = _container(store, _BrokenCloudOff());

      await container.read(cloudKeyProvider.notifier).delete();

      expect(store.key, isNull);
      expect(container.read(cloudKeyProvider).value, isNull);
    });

    test('the default store keeps the key in memory', () async {
      final container = ProviderContainer(
        overrides: [
          vibrationServiceProvider.overrideWithValue(MockVibrationService()),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(cloudKeyStoreProvider),
        isA<InMemoryCloudKeyStore>(),
      );
      await container.read(cloudKeyProvider.notifier).save(_key);
      expect(await container.read(cloudKeyStoreProvider).read(), _key);
    });
  });
}
