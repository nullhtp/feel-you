import 'package:feel_you/cloud/cloud.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _usage = CloudUsage(
  promptTokens: 10,
  completionTokens: 5,
  totalTokens: 15,
  cost: 0.0002,
);

/// A container with the store loaded afresh from the (mock) platform
/// storage, as a new launch would, and the clock reading [clock].
Future<ProviderContainer> _launch(DateTime Function() clock) async {
  SharedPreferences.resetStatic();
  final store = await loadCloudPreferencesStore();
  final container = ProviderContainer(
    overrides: [
      cloudPreferencesStoreProvider.overrideWithValue(store),
      cloudClockProvider.overrideWithValue(clock),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CloudUsage.fromJson', () {
    test('reads an OpenRouter usage object', () {
      expect(
        CloudUsage.fromJson({
          'prompt_tokens': 24,
          'completion_tokens': 9,
          'total_tokens': 33,
          'cost': 0.0000054,
          'is_byok': false,
          'prompt_tokens_details': {'cached_tokens': 0},
        }),
        const CloudUsage(
          promptTokens: 24,
          completionTokens: 9,
          totalTokens: 33,
          cost: 0.0000054,
        ),
      );
    });

    test('without cost or total, as other endpoints report it', () {
      expect(
        CloudUsage.fromJson({'prompt_tokens': 3, 'completion_tokens': 4}),
        const CloudUsage(promptTokens: 3, completionTokens: 4, totalTokens: 7),
      );
    });

    test('not an object is no usage', () {
      expect(CloudUsage.fromJson(null), isNull);
      expect(CloudUsage.fromJson(12), isNull);
    });
  });

  group('CloudUsageTotals', () {
    final morning = DateTime(2026, 10, 19, 9);

    test('adds each answer to today and this month', () {
      final totals = CloudUsageTotals.empty(
        morning,
      ).adding(_usage, morning).adding(_usage, morning);

      const expected = CloudUsageAmount(
        answers: 2,
        promptTokens: 20,
        completionTokens: 10,
        totalTokens: 30,
        cost: 0.0004,
      );
      expect(totals.today, expected);
      expect(totals.thisMonth, expected);
    });

    test('an answer without cost adds its tokens only', () {
      final totals = CloudUsageTotals.empty(morning)
          .adding(_usage, morning)
          .adding(
            const CloudUsage(
              promptTokens: 1,
              completionTokens: 1,
              totalTokens: 2,
            ),
            morning,
          );

      expect(totals.today.cost, 0.0002);
      expect(totals.today.totalTokens, 17);
    });

    test('today rolls over at local midnight, the month on the 1st', () {
      final totals = CloudUsageTotals.empty(
        morning,
      ).adding(_usage, DateTime(2026, 10, 19, 23, 59, 59));

      expect(totals.at(DateTime(2026, 10, 19, 23, 59, 59, 999)), totals);

      final nextDay = totals.at(DateTime(2026, 10, 20));
      expect(nextDay.today, const CloudUsageAmount());
      expect(nextDay.thisMonth, totals.thisMonth);

      final nextMonth = totals.at(DateTime(2026, 11));
      expect(nextMonth.today, const CloudUsageAmount());
      expect(nextMonth.thisMonth, const CloudUsageAmount());

      // The same month of another year is another month.
      final nextYear = totals.at(DateTime(2027, 10, 19));
      expect(nextYear.thisMonth, const CloudUsageAmount());
    });

    test('adding on a new day starts today afresh', () {
      final totals = CloudUsageTotals.empty(
        morning,
      ).adding(_usage, morning).adding(_usage, DateTime(2026, 10, 20, 8));

      expect(totals.today.answers, 1);
      expect(totals.thisMonth.answers, 2);
    });

    test('a clock moved back counts the earlier day as a new day', () {
      final totals = CloudUsageTotals.empty(
        morning,
      ).adding(_usage, morning).at(DateTime(2026, 10, 18, 9));

      expect(totals.today, const CloudUsageAmount());
      expect(totals.thisMonth.answers, 1);
    });

    test('JSON round trip', () {
      final totals = CloudUsageTotals.empty(morning).adding(_usage, morning);

      expect(CloudUsageTotals.fromJson(totals.toJson()), totals);
      expect(totals.toJson()['day'], '2026-10-19');
      expect(CloudUsageTotals.fromJson('nonsense'), isNull);
      expect(CloudUsageTotals.fromJson({'day': 'yesterday'}), isNull);
    });
  });

  group('cloudUsageProvider', () {
    test('totals are saved and survive a restart', () async {
      SharedPreferences.setMockInitialValues({});
      var now = DateTime(2026, 10, 19, 9);
      var container = await _launch(() => now);

      final notifier = container.read(cloudUsageProvider.notifier);
      await notifier.add(_usage);
      await notifier.add(_usage);

      container = await _launch(() => now);
      final totals = container.read(cloudUsageProvider);
      expect(totals.today.answers, 2);
      expect(totals.today.totalTokens, 30);
      expect(totals.thisMonth.cost, closeTo(0.0004, 1e-12));

      // The next day, today reads as zero without a new answer.
      now = DateTime(2026, 10, 20, 0, 0, 1);
      final nextDay = container.read(cloudUsageProvider.notifier).current();
      expect(nextDay.today, const CloudUsageAmount());
      expect(nextDay.thisMonth.answers, 2);
      expect(container.read(cloudUsageProvider), nextDay);

      // And so on a later launch.
      container = await _launch(() => now);
      expect(container.read(cloudUsageProvider).today.answers, 0);
      expect(container.read(cloudUsageProvider).thisMonth.answers, 2);
    });

    test('corrupt saved totals read as nothing used', () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesCloudPreferencesStore.usageKey: '{not json',
      });
      final now = DateTime(2026, 10, 19);

      final totals = (await _launch(() => now)).read(cloudUsageProvider);

      expect(totals, CloudUsageTotals.empty(now));
    });
  });

  group('CloudKeyInfo', () {
    final fetchedAt = DateTime(2026, 10, 19, 9);
    final baseUrl = CloudSettings.defaultBaseUrl;

    CloudKeyInfo? read(Object? json) => CloudKeyInfo.fromResponse(
      json,
      key: testMasked,
      baseUrl: baseUrl,
      fetchedAt: fetchedAt,
    );

    test("reads OpenRouter's GET /key response", () {
      final info = read({
        'data': {
          'label': 'Feel You',
          'limit': 10,
          'limit_remaining': 7.5,
          'limit_reset': 'monthly',
          'usage': 2.5,
          'usage_daily': 0.25,
          'usage_weekly': 1,
          'usage_monthly': 2.5,
          'is_free_tier': false,
        },
      })!;

      expect(info.limit, 10);
      expect(info.limitRemaining, 7.5);
      expect(info.usage, 2.5);
      expect(info.usageDaily, 0.25);
      expect(info.usageMonthly, 2.5);
      expect(info.fetchedAt, fetchedAt.toUtc());
      expect(info.key, testMasked);
    });

    test('a key without a limit', () {
      final info = read({
        'data': {'limit': null, 'limit_remaining': null, 'usage': 0},
      })!;

      expect(info.limit, isNull);
      expect(info.limitRemaining, isNull);
    });

    test('not a key response is null', () {
      expect(read(null), isNull);
      expect(read({'data': 'x'}), isNull);
      expect(read({'data': <String, Object>{}}), isNull);
    });

    test('JSON round trip, without the key itself', () {
      final info = read({
        'data': {'limit': 10, 'limit_remaining': 7.5, 'usage': 2.5},
      })!;

      expect(CloudKeyInfo.fromJson(info.toJson()), info);
      expect('${info.toJson()}', isNot(contains('c0ffee42')));
    });

    test('current on the same local day, key and base URL only', () {
      final info = read({
        'data': {'usage': 1},
      })!;
      bool current(DateTime now, {String? key, Uri? url}) => info.isCurrent(
        key: key ?? testMasked,
        baseUrl: url ?? baseUrl,
        now: now,
      );

      expect(current(DateTime(2026, 10, 19, 23, 59)), isTrue);
      expect(current(DateTime(2026, 10, 20)), isFalse);
      expect(current(DateTime(2026, 10, 18, 23)), isFalse);
      expect(current(fetchedAt, key: 'sk-or-...beef'), isFalse);
      expect(
        current(fetchedAt, url: Uri.parse('https://example.com/v1')),
        isFalse,
      );
    });
  });
}

/// The masked form of a test key.
const testMasked = 'sk-or-...d00d';
