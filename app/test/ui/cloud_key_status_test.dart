import 'dart:async';

import 'package:feel_you/cloud/cloud.dart';
import 'package:feel_you/gestures/gesture_providers.dart';
import 'package:feel_you/ui/cloud_key_status.dart';
import 'package:feel_you/ui/companion_overlay.dart';
import 'package:feel_you/vibration/vibration_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_doubles/fake_gesture_classifier.dart';
import '../test_doubles/mock_vibration_service.dart';

/// Shaped like a real OpenRouter key: `sk-or-v1-` and 64 hex digits, ending
/// in `a1b2`.
final _key = CloudKey.parse(
  'sk-or-v1-${'0123456789abcdef' * 3}0123456789aba1b2',
);

/// A [CloudKeyStore] whose first read waits for [gate].
class _GatedStore extends InMemoryCloudKeyStore {
  _GatedStore(this.gate, [super.key]);

  final Completer<void> gate;

  @override
  Future<CloudKey?> read() async {
    await gate.future;
    return super.read();
  }
}

/// Pumps a bare [CloudKeyStatus] backed by [store].
Future<void> _pumpStatus(
  WidgetTester tester,
  CloudKeyStore store, {
  MockVibrationService? vibration,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        cloudKeyStoreProvider.overrideWithValue(store),
        vibrationServiceProvider.overrideWithValue(
          vibration ?? MockVibrationService(),
        ),
      ],
      child: const MaterialApp(home: Stack(children: [CloudKeyStatus()])),
    ),
  );
  await tester.pump();
}

ProviderContainer _containerOf(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(CloudKeyStatus)));

/// Expects that no text on screen contains any long piece of the key.
void _expectKeyNotShown() {
  expect(find.textContaining(_key.value), findsNothing);
  expect(find.textContaining('0123456789'), findsNothing);
  expect(find.textContaining('sk-or-v1'), findsNothing);
}

void main() {
  group('describeCloudKey', () {
    test('is the masked key when one is saved', () {
      expect(describeCloudKey(AsyncData(_key)), 'sk-or-...a1b2');
    });

    test('is none when no key is saved', () {
      expect(describeCloudKey(const AsyncData(null)), 'none');
    });

    test('is checking… while the key is being read', () {
      expect(describeCloudKey(const AsyncLoading()), 'checking…');
    });

    test('is none if reading failed', () {
      expect(
        describeCloudKey(AsyncError(Exception('x'), StackTrace.empty)),
        'none',
      );
    });
  });

  group('CloudKeyStatus', () {
    testWidgets('shows none when no key is saved', (tester) async {
      await _pumpStatus(tester, InMemoryCloudKeyStore());

      expect(find.text('Cloud key: none'), findsOneWidget);
    });

    testWidgets('shows only the masked key', (tester) async {
      await _pumpStatus(tester, InMemoryCloudKeyStore(_key));

      expect(find.text('Cloud key: sk-or-...a1b2'), findsOneWidget);
      _expectKeyNotShown();
    });

    testWidgets('shows checking… until the key has been read', (tester) async {
      final gate = Completer<void>();
      await _pumpStatus(tester, _GatedStore(gate, _key));

      expect(find.text('Cloud key: checking…'), findsOneWidget);

      gate.complete();
      await tester.pumpAndSettle();
      expect(find.text('Cloud key: sk-or-...a1b2'), findsOneWidget);
    });

    testWidgets('follows a save and a deletion', (tester) async {
      final vibration = MockVibrationService();
      await _pumpStatus(tester, InMemoryCloudKeyStore(), vibration: vibration);
      final notifier = _containerOf(tester).read(cloudKeyProvider.notifier);

      await tester.runAsync(() => notifier.save(_key));
      await tester.pump();
      expect(find.text('Cloud key: sk-or-...a1b2'), findsOneWidget);
      _expectKeyNotShown();

      await tester.runAsync(notifier.delete);
      await tester.pump();
      expect(find.text('Cloud key: none'), findsOneWidget);
      expect(vibration.callLog, ['playCloudOff']);
    });
  });

  group('CompanionOverlay', () {
    testWidgets('shows the cloud key line in the bottom-right corner', (
      tester,
    ) async {
      final classifier = FakeGestureClassifier();
      addTearDown(classifier.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gestureClassifierProvider.overrideWithValue(classifier),
            cloudKeyStoreProvider.overrideWithValue(
              InMemoryCloudKeyStore(_key),
            ),
          ],
          child: const MaterialApp(home: CompanionOverlay()),
        ),
      );
      await tester.pump();

      final line = find.text('Cloud key: sk-or-...a1b2');
      expect(line, findsOneWidget);
      _expectKeyNotShown();
      final size = tester.getSize(find.byType(CompanionOverlay));
      final rect = tester.getRect(line);
      expect(rect.right, size.width - 16);
      expect(rect.bottom, size.height - 8);
      // Across from the vibration readout.
      final readout = tester.getRect(find.textContaining('Vibration:'));
      expect(readout.left, 16);
      expect(rect.bottom, readout.bottom);

      await tester.pumpWidget(const SizedBox());
    });
  });
}
