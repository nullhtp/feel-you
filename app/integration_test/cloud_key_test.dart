import 'package:feel_you/cloud/cloud.dart';
import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/ui/companion_overlay.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'e2e_helpers.dart';
import 'test_helpers.dart';

// The cloud key end to end (`cloud-key-storage`, `companion-overlay`,
// `vibration-engine`): the whole app with the real secure storage plugin,
// the Keychain on iOS and the Keystore-backed storage on Android, as `main`
// injects it.

/// Shaped like a real OpenRouter key (`sk-or-v1-` and 64 hex digits), and
/// unique to this test so it can't be confused with anything else stored.
final _key = CloudKey.parse('sk-or-v1-${'f00dcafe' * 7}0123456789ab7e57');

const _maskedLine = 'Cloud key: sk-or-...7e57';
const _noneLine = 'Cloud key: none';

/// The cloud-off signal of `vibration-engine`, written out rather than
/// taken from the app's constants, so the test pins the spec.
const _cloudOff = [0, 700, 300, 700];
const _cloudOffIntensities = [0, 255, 0, 255];

/// The app's real secure store, which `main` injects.
final _secureStore = cloudKeyStoreProvider.overrideWithValue(
  const SecureCloudKeyStore(),
);

/// The overlay's screen-reader summary.
String _summary(WidgetTester tester) =>
    tester.getSemantics(find.byType(CompanionOverlay)).label;

/// The notifier that saves and deletes the key, as the assistant screen
/// (#63) will use it.
CloudKeyNotifier _cloudKey(E2EApp app, WidgetTester tester) =>
    app.container(tester).read(cloudKeyProvider.notifier);

/// Waits until [text] is on screen.
Future<void> _waitForText(WidgetTester tester, String text) => waitUntil(
  tester,
  () => find.text(text).evaluate().isNotEmpty,
  reason: '"$text" on the overlay',
);

/// Expects that nothing on screen or in the summary shows the key.
void _expectKeyNotShown(WidgetTester tester) {
  expect(find.textContaining(_key.value), findsNothing);
  expect(find.textContaining('f00dcafe'), findsNothing);
  expect(_summary(tester), isNot(contains(_key.value)));
  expect(_summary(tester), isNot(contains('f00dcafe')));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Start and end without the key in the secure storage, whatever an
  // earlier, interrupted run left behind.
  setUp(() => const SecureCloudKeyStore().delete());
  tearDown(() => const SecureCloudKeyStore().delete());

  testWidgets('the key is kept in the secure storage, shown masked, never '
      'in the preferences, and deleting it plays cloud off', (tester) async {
    final semantics = tester.ensureSemantics();
    FakeVibrationPlatform().install(tester);

    // A first launch: no key.
    final vibration = RecordingVibrationService();
    var app = E2EApp(
      savedLanguage: MorseLanguage.english,
      vibration: vibration,
      overrides: [_secureStore],
    );
    await app.launch(tester);
    await app.openLessons(tester);
    await _waitForText(tester, _noneLine);
    expect(_summary(tester), endsWith(', cloud key none'));

    // Save it, as the assistant screen (#63) will.
    await _cloudKey(app, tester).save(_key);

    // Read back from the platform by a store of its own.
    expect(await const SecureCloudKeyStore().read(), _key);

    // The overlay shows it at once, masked, and so does the summary.
    await _waitForText(tester, _maskedLine);
    expect(_summary(tester), endsWith(', cloud key sk-or-...7e57'));
    _expectKeyNotShown(tester);

    // The app's preferences hold no trace of it.
    final preferences = await SharedPreferences.getInstance();
    await preferences.reload();
    for (final name in preferences.getKeys()) {
      expect('${preferences.get(name)}', isNot(contains(_key.value)));
      expect('${preferences.get(name)}', isNot(contains('f00dcafe')));
    }

    // A restart: a new app reads the key from the secure storage.
    await app.close(tester);
    final relaunched = RecordingVibrationService();
    app = E2EApp(
      savedLanguage: MorseLanguage.english,
      vibration: relaunched,
      overrides: [_secureStore],
    );
    await app.launch(tester);
    await app.openLessons(tester);
    await _waitForText(tester, _maskedLine);
    _expectKeyNotShown(tester);

    // Delete it: cloud off is played once, the overlay says none, and the
    // platform has no key.
    relaunched.reset();
    await _cloudKey(app, tester).delete();
    expect(
      relaunched.callTypes.where((c) => c == VibrationCallType.playCloudOff),
      hasLength(1),
    );
    await _waitForText(tester, _noneLine);
    expect(_summary(tester), endsWith(', cloud key none'));
    expect(await const SecureCloudKeyStore().read(), isNull);

    await app.close(tester);
    semantics.dispose();
  });

  for (final hasAmplitudeControl in [true, false]) {
    testWidgets('deleting the key sends the same cloud-off signal to a motor '
        '${hasAmplitudeControl ? 'with' : 'without'} amplitude control', (
      tester,
    ) async {
      final platform = FakeVibrationPlatform(
        hasAmplitudeControl: hasAmplitudeControl,
      )..install(tester);
      final app = E2EApp(
        savedLanguage: MorseLanguage.english,
        overrides: [_secureStore],
      );
      await app.launch(tester);
      await app.openLessons(tester);
      await _cloudKey(app, tester).save(_key);
      await _waitForText(tester, _maskedLine);
      expect(platform.indexOfPattern(_cloudOff), -1);

      await _cloudKey(app, tester).delete();

      final index = platform.indexOfPattern(_cloudOff);
      expect(index, isNot(-1), reason: 'cloud off reached the plugin');
      expect(platform.intensities[index], _cloudOffIntensities);
      expect(platform.indexOfPattern(_cloudOff, start: index + 1), -1);
      await _waitForText(tester, _noneLine);

      await app.close(tester);
    });
  }
}
