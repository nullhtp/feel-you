import 'dart:convert';

import 'package:feel_you/cloud/cloud_settings.dart';
import 'package:feel_you/cloud/cloud_usage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keeps what the cloud features remember that is not secret: the
/// [CloudSettings], the [CloudUsageTotals] and the last [CloudKeyInfo].
///
/// The key itself is never here: it lives in the secure storage (see
/// `CloudKeyStore`). Reads never throw: a missing or unreadable value
/// reads as `null`. Writes are best effort: a failure is logged, never
/// thrown, so it can't break a request.
abstract interface class CloudPreferencesStore {
  /// The base URL that was set, or `null` for the default.
  Uri? readBaseUrl();

  /// Saves [url] as the base URL, or forgets it when `null`.
  Future<void> writeBaseUrl(Uri? url);

  /// The saved "deny data collection" setting, or `null` when it was never
  /// changed.
  bool? readDenyDataCollection();

  /// Saves the "deny data collection" setting.
  Future<void> writeDenyDataCollection({required bool deny});

  /// The saved usage totals, or `null` when none are saved.
  CloudUsageTotals? readUsage();

  /// Saves [totals] as the usage totals.
  Future<void> writeUsage(CloudUsageTotals totals);

  /// The last key information fetched, or `null`.
  CloudKeyInfo? readKeyInfo();

  /// Saves [info] as the last key information fetched.
  Future<void> writeKeyInfo(CloudKeyInfo info);
}

/// A [CloudPreferencesStore] in the app's [SharedPreferences]
/// (`UserDefaults` on iOS), which survive restarts and are backed up with
/// the language and learned items.
class SharedPreferencesCloudPreferencesStore implements CloudPreferencesStore {
  SharedPreferencesCloudPreferencesStore(this._preferences);

  /// The key holding the base URL, as a string.
  static const baseUrlKey = 'cloud_base_url';

  /// The key holding the "deny data collection" setting, as a bool.
  static const denyDataCollectionKey = 'cloud_deny_data_collection';

  /// The key holding the usage totals, as JSON.
  static const usageKey = 'cloud_usage';

  /// The key holding the last key information, as JSON.
  static const keyInfoKey = 'cloud_key_info';

  /// Every key this store writes.
  static const keys = [baseUrlKey, denyDataCollectionKey, usageKey, keyInfoKey];

  final SharedPreferences _preferences;

  @override
  Uri? readBaseUrl() {
    final stored = _preferences.get(baseUrlKey);
    return stored is String ? parseCloudBaseUrl(stored) : null;
  }

  @override
  Future<void> writeBaseUrl(Uri? url) => _write(
    'base URL',
    () => url == null
        ? _preferences.remove(baseUrlKey)
        : _preferences.setString(baseUrlKey, url.toString()),
  );

  @override
  bool? readDenyDataCollection() {
    final stored = _preferences.get(denyDataCollectionKey);
    return stored is bool ? stored : null;
  }

  @override
  Future<void> writeDenyDataCollection({required bool deny}) => _write(
    'data collection setting',
    () => _preferences.setBool(denyDataCollectionKey, deny),
  );

  @override
  CloudUsageTotals? readUsage() =>
      CloudUsageTotals.fromJson(_readJson(usageKey));

  @override
  Future<void> writeUsage(CloudUsageTotals totals) => _write(
    'cloud usage',
    () => _preferences.setString(usageKey, jsonEncode(totals.toJson())),
  );

  @override
  CloudKeyInfo? readKeyInfo() => CloudKeyInfo.fromJson(_readJson(keyInfoKey));

  @override
  Future<void> writeKeyInfo(CloudKeyInfo info) => _write(
    'key information',
    () => _preferences.setString(keyInfoKey, jsonEncode(info.toJson())),
  );

  Object? _readJson(String key) {
    final stored = _preferences.get(key);
    if (stored is! String) return null;
    try {
      return jsonDecode(stored);
    } on FormatException {
      return null;
    }
  }

  static Future<void> _write(String what, Future<bool> Function() write) async {
    try {
      if (!await write()) debugPrint('Could not save the $what.');
    } on Exception catch (error) {
      debugPrint('Could not save the $what (${error.runtimeType}).');
    }
  }
}

/// A [CloudPreferencesStore] that only lasts as long as the app runs.
///
/// The default of [cloudPreferencesStoreProvider], so widgets and tests
/// work without any setup, and the fallback when [SharedPreferences] can't
/// be loaded.
class InMemoryCloudPreferencesStore implements CloudPreferencesStore {
  InMemoryCloudPreferencesStore();

  Uri? _baseUrl;
  bool? _denyDataCollection;
  CloudUsageTotals? _usage;
  CloudKeyInfo? _keyInfo;

  @override
  Uri? readBaseUrl() => _baseUrl;

  @override
  Future<void> writeBaseUrl(Uri? url) async => _baseUrl = url;

  @override
  bool? readDenyDataCollection() => _denyDataCollection;

  @override
  Future<void> writeDenyDataCollection({required bool deny}) async =>
      _denyDataCollection = deny;

  @override
  CloudUsageTotals? readUsage() => _usage;

  @override
  Future<void> writeUsage(CloudUsageTotals totals) async => _usage = totals;

  @override
  CloudKeyInfo? readKeyInfo() => _keyInfo;

  @override
  Future<void> writeKeyInfo(CloudKeyInfo info) async => _keyInfo = info;
}

/// Loads the persistent [CloudPreferencesStore].
///
/// `main` calls it before `runApp`, as for the other settings, and
/// overrides [cloudPreferencesStoreProvider] with the result. Falls back to
/// an [InMemoryCloudPreferencesStore] if the platform storage can't be
/// loaded.
Future<CloudPreferencesStore> loadCloudPreferencesStore() async {
  try {
    return SharedPreferencesCloudPreferencesStore(
      await SharedPreferences.getInstance(),
    );
  } on Exception catch (error) {
    debugPrint(
      'Could not load preferences, cloud settings and usage will not be '
      'saved: $error',
    );
    return InMemoryCloudPreferencesStore();
  }
}

/// Provides the [CloudPreferencesStore].
///
/// `main` overrides it with the store from [loadCloudPreferencesStore].
final cloudPreferencesStoreProvider = Provider<CloudPreferencesStore>(
  (ref) => InMemoryCloudPreferencesStore(),
);

/// Provides the current local time, for the usage totals and the daily key
/// information. Tests override it to move the clock.
final cloudClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Provides the [CloudSettingsNotifier] and the current [CloudSettings].
final cloudSettingsProvider =
    NotifierProvider<CloudSettingsNotifier, CloudSettings>(
      CloudSettingsNotifier.new,
    );

/// Holds the [CloudSettings] and saves each change.
class CloudSettingsNotifier extends Notifier<CloudSettings> {
  /// Reads the saved settings: the default base URL when none (or an
  /// invalid one) is saved, and data collection denied unless it was
  /// turned off.
  @override
  CloudSettings build() {
    final store = ref.watch(cloudPreferencesStoreProvider);
    return CloudSettings(
      baseUrl: store.readBaseUrl(),
      denyDataCollection: store.readDenyDataCollection() ?? true,
    );
  }

  /// Sets and saves the base URL parsed from [input] with
  /// [parseCloudBaseUrl].
  ///
  /// Returns `false`, changing nothing, when [input] is not a valid base
  /// URL.
  Future<bool> setBaseUrl(String input) async {
    final url = parseCloudBaseUrl(input);
    if (url == null) return false;
    state = state.copyWith(baseUrl: url);
    await ref.read(cloudPreferencesStoreProvider).writeBaseUrl(url);
    return true;
  }

  /// Goes back to OpenRouter's base URL.
  Future<void> resetBaseUrl() async {
    state = state.copyWith(baseUrl: CloudSettings.defaultBaseUrl);
    await ref.read(cloudPreferencesStoreProvider).writeBaseUrl(null);
  }

  /// Turns "deny data collection" on or off and saves it.
  Future<void> setDenyDataCollection({required bool deny}) async {
    state = state.copyWith(denyDataCollection: deny);
    await ref
        .read(cloudPreferencesStoreProvider)
        .writeDenyDataCollection(deny: deny);
  }
}

/// Provides the [CloudUsageNotifier] and the [CloudUsageTotals] as they
/// were last read or added to.
///
/// The state does not roll over at midnight on its own: read
/// [CloudUsageNotifier.current] for the totals as they stand now.
final cloudUsageProvider =
    NotifierProvider<CloudUsageNotifier, CloudUsageTotals>(
      CloudUsageNotifier.new,
    );

/// Adds up the usage of the answers and saves the totals.
class CloudUsageNotifier extends Notifier<CloudUsageTotals> {
  /// Reads the saved totals, as they stand now.
  @override
  CloudUsageTotals build() {
    final now = ref.watch(cloudClockProvider)();
    final saved = ref.watch(cloudPreferencesStoreProvider).readUsage();
    return (saved ?? CloudUsageTotals.empty(now)).at(now);
  }

  /// The totals as they stand now: today is zero after local midnight, and
  /// this month after the month has changed.
  CloudUsageTotals current() {
    final totals = state.at(ref.read(cloudClockProvider)());
    if (totals != state) state = totals;
    return totals;
  }

  /// Adds one answer's [usage] to today and this month, and saves the
  /// totals.
  Future<void> add(CloudUsage usage) async {
    state = state.adding(usage, ref.read(cloudClockProvider)());
    await ref.read(cloudPreferencesStoreProvider).writeUsage(state);
  }
}
