import 'package:feel_you/cloud/cloud.dart';
import 'package:flutter_test/flutter_test.dart';

/// A key shaped like a real OpenRouter key: `sk-or-v1-` and 64 hex digits,
/// ending in `a1b2`.
final _openRouterKey = 'sk-or-v1-${'0123456789abcdef' * 3}0123456789aba1b2';

void main() {
  group('CloudKey.tryParse', () {
    test('accepts an OpenRouter key as it is', () {
      expect(_openRouterKey, hasLength(73));
      expect(CloudKey.tryParse(_openRouterKey)?.value, _openRouterKey);
    });

    test('trims a pasted key with a line break', () {
      expect(CloudKey.tryParse('  sk-or-v1-abc\n')?.value, 'sk-or-v1-abc');
      expect(CloudKey.tryParse('\tsk-or-v1-abc\r\n')?.value, 'sk-or-v1-abc');
    });

    test('rejects empty or whitespace-only input', () {
      for (final input in ['', ' ', '\n', ' \t \r\n ']) {
        expect(CloudKey.tryParse(input), isNull, reason: '"$input"');
      }
    });

    test('rejects a space, a tab or a non-ASCII character inside', () {
      for (final input in [
        'sk-or-v1 abc',
        'sk-or-v1\tabc',
        'sk-or-v1\nabc',
        'sk-or-v1-ключ',
        'sk-or-v1-abc def',
        'sk-or-v1-abc\u0000def',
        'sk-or-v1-abc\u007Fdef',
      ]) {
        expect(CloudKey.tryParse(input), isNull, reason: input);
      }
    });

    test('accepts every printable ASCII character but the space', () {
      final all = String.fromCharCodes([for (var c = 0x21; c <= 0x7E; c++) c]);
      expect(CloudKey.tryParse(all)?.value, all);
    });

    test('accepts 512 characters and rejects 513', () {
      expect(CloudKey.maxLength, 512);
      expect(CloudKey.tryParse('k' * 512)?.value, 'k' * 512);
      expect(CloudKey.tryParse('k' * 513), isNull);
      // Trimmed first: surrounding whitespace doesn't count.
      expect(CloudKey.tryParse(' ${'k' * 512} '), isNotNull);
    });
  });

  group('CloudKey.parse', () {
    test('returns the key for valid input', () {
      expect(CloudKey.parse(' $_openRouterKey ').value, _openRouterKey);
    });

    test('throws a FormatException that does not contain the input', () {
      const input = 'sk-or-v1-almost a key';
      expect(
        () => CloudKey.parse(input),
        throwsA(
          isA<FormatException>()
              .having((e) => e.source, 'source', isNull)
              .having((e) => '$e', 'text', isNot(contains('almost')))
              .having((e) => '$e', 'text', isNot(contains('sk-or'))),
        ),
      );
    });
  });

  group('maskCloudKey', () {
    test('keeps the OpenRouter prefix and the last 4 characters', () {
      expect(maskCloudKey(_openRouterKey), 'sk-or-...a1b2');
    });

    test('shows the last 4 only when 12 characters after sk-or- stay '
        'hidden', () {
      // 16 characters after the prefix: 12 hidden, 4 shown.
      expect(maskCloudKey('sk-or-${'x' * 12}a1b2'), 'sk-or-...a1b2');
      // 15 characters after the prefix: only 11 would stay hidden.
      expect(maskCloudKey('sk-or-${'x' * 11}a1b2'), 'sk-or-...');
    });

    test('a short OpenRouter key shows only its prefix', () {
      expect(maskCloudKey('sk-or-v1-a1b2'), 'sk-or-...');
      expect(maskCloudKey('sk-or-'), 'sk-or-...');
    });

    test('a key without the OpenRouter prefix shows no prefix', () {
      expect(maskCloudKey('custom-key-0123456a1b2'), '...a1b2');
      expect(maskCloudKey('sk-proj-${'x' * 20}a1b2'), '...a1b2');
      // The prefix is matched exactly, case included.
      expect(maskCloudKey('SK-OR-${'x' * 20}a1b2'), '...a1b2');
    });

    test('a short key without the prefix shows nothing but ...', () {
      expect(maskCloudKey('x' * 15), '...');
      expect(maskCloudKey('${'x' * 12}a1b2'), '...a1b2');
      expect(maskCloudKey('k'), '...');
    });

    test('never contains more than 4 characters of the key after sk-or-', () {
      for (var length = 1; length <= 80; length++) {
        final key = 'sk-or-${'abcdefghij' * 8}'.substring(0, 6 + length);
        final masked = maskCloudKey(key);
        expect(masked, startsWith('sk-or-...'));
        expect(masked.length - 'sk-or-...'.length, lessThanOrEqualTo(4));
      }
    });
  });

  group('CloudKey', () {
    final key = CloudKey.parse(_openRouterKey);

    test('masked is the masked form', () {
      expect(key.masked, 'sk-or-...a1b2');
    });

    test('toString and string interpolation never contain the key', () {
      expect(key.toString(), 'CloudKey(sk-or-...a1b2)');
      expect('key: $key', isNot(contains(_openRouterKey)));
      expect('${[key]}', isNot(contains(_openRouterKey)));
      expect('${{'key': key}}', isNot(contains('0123456789abcdef')));
    });

    test('compares by value', () {
      expect(CloudKey.parse(_openRouterKey), key);
      expect(CloudKey.parse(_openRouterKey).hashCode, key.hashCode);
      expect(CloudKey.parse('sk-or-other'), isNot(key));
    });
  });
}
