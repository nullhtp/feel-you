import 'package:flutter/foundation.dart';

/// The `usage` an answer reports: what it cost in tokens and, when the
/// endpoint says so, in credits.
@immutable
final class CloudUsage {
  const CloudUsage({
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
    this.cost,
  });

  /// Reads a `usage` object, or returns `null` when [json] is not one.
  ///
  /// Missing token counts are 0; `total_tokens` defaults to the sum of the
  /// other two. `cost` (OpenRouter credits, about one US dollar each) is
  /// `null` when the endpoint does not report it.
  static CloudUsage? fromJson(Object? json) {
    if (json is! Map) return null;
    final prompt = _int(json['prompt_tokens']);
    final completion = _int(json['completion_tokens']);
    final cost = json['cost'];
    return CloudUsage(
      promptTokens: prompt,
      completionTokens: completion,
      totalTokens: json['total_tokens'] is num
          ? _int(json['total_tokens'])
          : prompt + completion,
      cost: cost is num ? cost.toDouble() : null,
    );
  }

  final int promptTokens;
  final int completionTokens;
  final int totalTokens;

  /// The cost in credits, or `null` when it was not reported.
  final double? cost;

  @override
  bool operator ==(Object other) =>
      other is CloudUsage &&
      other.promptTokens == promptTokens &&
      other.completionTokens == completionTokens &&
      other.totalTokens == totalTokens &&
      other.cost == cost;

  @override
  int get hashCode =>
      Object.hash(promptTokens, completionTokens, totalTokens, cost);

  @override
  String toString() =>
      'CloudUsage($promptTokens + $completionTokens = $totalTokens tokens, '
      'cost $cost)';
}

/// What the answers of one period (a day or a month) added up to.
@immutable
final class CloudUsageAmount {
  const CloudUsageAmount({
    this.answers = 0,
    this.promptTokens = 0,
    this.completionTokens = 0,
    this.totalTokens = 0,
    this.cost = 0,
  });

  /// Reads an amount written by [toJson]; anything else is zero.
  factory CloudUsageAmount.fromJson(Object? json) {
    if (json is! Map) return const CloudUsageAmount();
    final cost = json['cost'];
    return CloudUsageAmount(
      answers: _int(json['answers']),
      promptTokens: _int(json['prompt_tokens']),
      completionTokens: _int(json['completion_tokens']),
      totalTokens: _int(json['total_tokens']),
      cost: cost is num ? cost.toDouble() : 0,
    );
  }

  /// How many answers reported their usage.
  final int answers;
  final int promptTokens;
  final int completionTokens;
  final int totalTokens;

  /// The sum of the costs that were reported, in credits.
  final double cost;

  /// This amount with one more answer's [usage] added.
  CloudUsageAmount adding(CloudUsage usage) => CloudUsageAmount(
    answers: answers + 1,
    promptTokens: promptTokens + usage.promptTokens,
    completionTokens: completionTokens + usage.completionTokens,
    totalTokens: totalTokens + usage.totalTokens,
    cost: cost + (usage.cost ?? 0),
  );

  Map<String, Object> toJson() => {
    'answers': answers,
    'prompt_tokens': promptTokens,
    'completion_tokens': completionTokens,
    'total_tokens': totalTokens,
    'cost': cost,
  };

  @override
  bool operator ==(Object other) =>
      other is CloudUsageAmount &&
      other.answers == answers &&
      other.promptTokens == promptTokens &&
      other.completionTokens == completionTokens &&
      other.totalTokens == totalTokens &&
      other.cost == cost;

  @override
  int get hashCode =>
      Object.hash(answers, promptTokens, completionTokens, totalTokens, cost);

  @override
  String toString() =>
      'CloudUsageAmount($answers answers, $promptTokens + $completionTokens = '
      '$totalTokens tokens, cost $cost)';
}

/// Today's and this month's usage, by the local calendar.
@immutable
final class CloudUsageTotals {
  /// Creates totals for [day], the local date they were last added to.
  CloudUsageTotals({
    required DateTime day,
    this.today = const CloudUsageAmount(),
    this.thisMonth = const CloudUsageAmount(),
  }) : day = _date(day);

  /// Nothing used, as of [now].
  factory CloudUsageTotals.empty(DateTime now) => CloudUsageTotals(day: now);

  /// Reads totals written by [toJson], or returns `null` when [json] is not
  /// such a value.
  static CloudUsageTotals? fromJson(Object? json) {
    if (json is! Map) return null;
    final day = DateTime.tryParse('${json['day']}');
    if (day == null) return null;
    return CloudUsageTotals(
      day: day,
      today: CloudUsageAmount.fromJson(json['today']),
      thisMonth: CloudUsageAmount.fromJson(json['month']),
    );
  }

  /// The local date (midnight) these totals were last added to.
  final DateTime day;

  /// The usage of [day].
  final CloudUsageAmount today;

  /// The usage of [day]'s month.
  final CloudUsageAmount thisMonth;

  /// These totals as they stand at [now]: today is zero from the next
  /// local day on, and this month from the next local month on.
  CloudUsageTotals at(DateTime now) {
    final date = _date(now);
    if (date == day) return this;
    final sameMonth = date.year == day.year && date.month == day.month;
    return CloudUsageTotals(
      day: date,
      thisMonth: sameMonth ? thisMonth : const CloudUsageAmount(),
    );
  }

  /// These totals at [now], with [usage] added to today and this month.
  CloudUsageTotals adding(CloudUsage usage, DateTime now) {
    final current = at(now);
    return CloudUsageTotals(
      day: current.day,
      today: current.today.adding(usage),
      thisMonth: current.thisMonth.adding(usage),
    );
  }

  Map<String, Object> toJson() => {
    'day': _formatDate(day),
    'today': today.toJson(),
    'month': thisMonth.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      other is CloudUsageTotals &&
      other.day == day &&
      other.today == today &&
      other.thisMonth == thisMonth;

  @override
  int get hashCode => Object.hash(day, today, thisMonth);

  @override
  String toString() =>
      'CloudUsageTotals(${_formatDate(day)}, today: $today, '
      'month: $thisMonth)';
}

/// The key's limit and spend, as `GET {base URL}/key` reported them.
///
/// Amounts are in credits. OpenRouter counts the daily and monthly spend by
/// UTC day and month, unlike [CloudUsageTotals].
@immutable
final class CloudKeyInfo {
  const CloudKeyInfo({
    required this.key,
    required this.baseUrl,
    required this.fetchedAt,
    required this.usage,
    this.limit,
    this.limitRemaining,
    this.usageDaily,
    this.usageMonthly,
  });

  /// Reads the `data` object of a `GET /key` response, fetched at
  /// [fetchedAt] for the key masked as [key] from [baseUrl]. Returns `null`
  /// when [json] has no `data` object with a numeric `usage`.
  static CloudKeyInfo? fromResponse(
    Object? json, {
    required String key,
    required Uri baseUrl,
    required DateTime fetchedAt,
  }) {
    final data = json is Map ? json['data'] : null;
    if (data is! Map) return null;
    final usage = _double(data['usage']);
    if (usage == null) return null;
    return CloudKeyInfo(
      key: key,
      baseUrl: baseUrl.toString(),
      fetchedAt: fetchedAt.toUtc(),
      usage: usage,
      limit: _double(data['limit']),
      limitRemaining: _double(data['limit_remaining']),
      usageDaily: _double(data['usage_daily']),
      usageMonthly: _double(data['usage_monthly']),
    );
  }

  /// Reads a value written by [toJson], or returns `null` when [json] is not
  /// one.
  static CloudKeyInfo? fromJson(Object? json) {
    if (json is! Map) return null;
    final key = json['key'];
    final baseUrl = json['base_url'];
    final fetchedAt = DateTime.tryParse('${json['fetched_at']}');
    final usage = _double(json['usage']);
    if (key is! String || baseUrl is! String) return null;
    if (fetchedAt == null || usage == null) return null;
    return CloudKeyInfo(
      key: key,
      baseUrl: baseUrl,
      fetchedAt: fetchedAt,
      usage: usage,
      limit: _double(json['limit']),
      limitRemaining: _double(json['limit_remaining']),
      usageDaily: _double(json['usage_daily']),
      usageMonthly: _double(json['usage_monthly']),
    );
  }

  /// The masked form of the key this describes (never the key itself).
  final String key;

  /// The base URL it was fetched from.
  final String baseUrl;

  /// When it was fetched, in UTC.
  final DateTime fetchedAt;

  /// The key's spending limit, or `null` when it has none.
  final double? limit;

  /// What is left of [limit], or `null` when the key has no limit.
  final double? limitRemaining;

  /// What the key has spent, all time.
  final double usage;

  /// What it has spent today and this month (UTC), when reported.
  final double? usageDaily;
  final double? usageMonthly;

  /// Whether this was fetched on the local day of [now], for the key masked
  /// as [key] from [baseUrl].
  bool isCurrent({
    required String key,
    required Uri baseUrl,
    required DateTime now,
  }) =>
      this.key == key &&
      this.baseUrl == baseUrl.toString() &&
      _date(fetchedAt.toLocal()) == _date(now);

  Map<String, Object?> toJson() => {
    'key': key,
    'base_url': baseUrl,
    'fetched_at': fetchedAt.toUtc().toIso8601String(),
    'limit': limit,
    'limit_remaining': limitRemaining,
    'usage': usage,
    'usage_daily': usageDaily,
    'usage_monthly': usageMonthly,
  };

  @override
  bool operator ==(Object other) =>
      other is CloudKeyInfo &&
      other.key == key &&
      other.baseUrl == baseUrl &&
      other.fetchedAt == fetchedAt &&
      other.limit == limit &&
      other.limitRemaining == limitRemaining &&
      other.usage == usage &&
      other.usageDaily == usageDaily &&
      other.usageMonthly == usageMonthly;

  @override
  int get hashCode => Object.hash(
    key,
    baseUrl,
    fetchedAt,
    limit,
    limitRemaining,
    usage,
    usageDaily,
    usageMonthly,
  );

  @override
  String toString() =>
      'CloudKeyInfo($key, limit $limit, remaining $limitRemaining, '
      'usage $usage, fetched ${fetchedAt.toIso8601String()})';
}

/// The local date of [time], at midnight.
DateTime _date(DateTime time) {
  final local = time.isUtc ? time.toLocal() : time;
  return DateTime(local.year, local.month, local.day);
}

String _formatDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

int _int(Object? value) => value is num ? value.toInt() : 0;

double? _double(Object? value) => value is num ? value.toDouble() : null;
