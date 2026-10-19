import 'package:feel_you/cloud/cloud.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A container with the preferences store loaded afresh from the (mock)
/// platform storage, as a new launch would.
Future<ProviderContainer> _launch() async {
  SharedPreferences.resetStatic();
  final store = await loadCloudPreferencesStore();
  expect(store, isA<SharedPreferencesCloudPreferencesStore>());
  final container = ProviderContainer(
    overrides: [cloudPreferencesStoreProvider.overrideWithValue(store)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('parseCloudBaseUrl', () {
    test('accepts https and drops surrounding whitespace and trailing /', () {
      expect(
        parseCloudBaseUrl(' https://example.com/v1/ \n'),
        Uri.parse('https://example.com/v1'),
      );
      expect(
        parseCloudBaseUrl('HTTPS://Example.COM:8443/api//'),
        Uri.parse('https://example.com:8443/api'),
      );
      expect(
        parseCloudBaseUrl('https://example.com'),
        Uri.parse('https://example.com'),
      );
    });

    test('accepts plain http only on the loopback hosts', () {
      expect(
        parseCloudBaseUrl('http://127.0.0.1:8080/v1'),
        Uri.parse('http://127.0.0.1:8080/v1'),
      );
      expect(
        parseCloudBaseUrl('http://localhost/v1'),
        Uri.parse('http://localhost/v1'),
      );
      expect(
        parseCloudBaseUrl('http://[::1]:8080/v1'),
        Uri.parse('http://[::1]:8080/v1'),
      );
      expect(parseCloudBaseUrl('http://example.com/v1'), isNull);
      expect(parseCloudBaseUrl('http://192.168.1.10/v1'), isNull);
      expect(parseCloudBaseUrl('http://127.0.0.2/v1'), isNull);
    });

    test('rejects credentials, queries and fragments', () {
      expect(parseCloudBaseUrl('https://user:pass@example.com/v1'), isNull);
      expect(parseCloudBaseUrl('https://user@example.com/v1'), isNull);
      expect(parseCloudBaseUrl('https://example.com/v1?key=abc'), isNull);
      expect(parseCloudBaseUrl('https://example.com/v1?'), isNull);
      expect(parseCloudBaseUrl('https://example.com/v1#top'), isNull);
    });

    test('rejects what is not a URL with a host', () {
      for (final input in [
        '',
        '   ',
        'openrouter.ai/api/v1',
        'ftp://example.com',
        'https://',
        'https:///v1',
        'file:///etc',
        'not a url',
      ]) {
        expect(parseCloudBaseUrl(input), isNull, reason: input);
      }
    });
  });

  group('CloudSettings', () {
    test('defaults to OpenRouter with data collection denied', () {
      final settings = CloudSettings();

      expect(settings.baseUrl, Uri.parse('https://openrouter.ai/api/v1'));
      expect(settings.denyDataCollection, isTrue);
      expect(
        settings.endpoint('chat/completions'),
        Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
      );
      expect(
        settings.endpoint('key'),
        Uri.parse('https://openrouter.ai/api/v1/key'),
      );
    });

    test('endpoints of a base URL without a path', () {
      final settings = CloudSettings(baseUrl: Uri.parse('https://example.com'));

      expect(
        settings.endpoint('chat/completions'),
        Uri.parse('https://example.com/chat/completions'),
      );
    });
  });

  group('cloudSettingsProvider', () {
    test('first launch: OpenRouter and data collection denied', () async {
      SharedPreferences.setMockInitialValues({});

      final settings = (await _launch()).read(cloudSettingsProvider);

      expect(settings, CloudSettings());
    });

    test('a base URL survives a restart, and reset forgets it', () async {
      SharedPreferences.setMockInitialValues({});
      var container = await _launch();

      final accepted = await container
          .read(cloudSettingsProvider.notifier)
          .setBaseUrl('https://example.com/v1/');

      expect(accepted, isTrue);
      expect(
        container.read(cloudSettingsProvider).baseUrl,
        Uri.parse('https://example.com/v1'),
      );

      container = await _launch();
      expect(
        container
            .read(cloudSettingsProvider)
            .endpoint('chat/completions')
            .toString(),
        'https://example.com/v1/chat/completions',
      );

      await container.read(cloudSettingsProvider.notifier).resetBaseUrl();
      expect(
        container.read(cloudSettingsProvider).baseUrl,
        CloudSettings.defaultBaseUrl,
      );
      container = await _launch();
      expect(
        container.read(cloudSettingsProvider).baseUrl,
        CloudSettings.defaultBaseUrl,
      );
    });

    test('an invalid base URL is rejected and changes nothing', () async {
      SharedPreferences.setMockInitialValues({});
      final container = await _launch();
      final notifier = container.read(cloudSettingsProvider.notifier);
      await notifier.setBaseUrl('https://example.com/v1');

      expect(await notifier.setBaseUrl('http://example.com/v1'), isFalse);

      expect(
        container.read(cloudSettingsProvider).baseUrl,
        Uri.parse('https://example.com/v1'),
      );
      final preferences = await SharedPreferences.getInstance();
      expect(
        preferences.getString(
          SharedPreferencesCloudPreferencesStore.baseUrlKey,
        ),
        'https://example.com/v1',
      );
    });

    test('an invalid stored base URL reads as the default', () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesCloudPreferencesStore.baseUrlKey: 'http://example.com',
      });

      expect(
        (await _launch()).read(cloudSettingsProvider).baseUrl,
        CloudSettings.defaultBaseUrl,
      );
    });

    test('turning data collection on and off survives a restart', () async {
      SharedPreferences.setMockInitialValues({});
      var container = await _launch();

      await container
          .read(cloudSettingsProvider.notifier)
          .setDenyDataCollection(deny: false);
      expect(container.read(cloudSettingsProvider).denyDataCollection, isFalse);

      container = await _launch();
      expect(container.read(cloudSettingsProvider).denyDataCollection, isFalse);

      await container
          .read(cloudSettingsProvider.notifier)
          .setDenyDataCollection(deny: true);
      container = await _launch();
      expect(container.read(cloudSettingsProvider).denyDataCollection, isTrue);
    });

    test('a stored value of another type reads as the default', () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesCloudPreferencesStore.baseUrlKey: 42,
        SharedPreferencesCloudPreferencesStore.denyDataCollectionKey: 'no',
      });

      expect((await _launch()).read(cloudSettingsProvider), CloudSettings());
    });
  });
}
