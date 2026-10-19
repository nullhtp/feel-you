import 'package:feel_you/cloud/cloud_error.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CloudError.fromStatus', () {
    test('maps each documented status to its case', () {
      expect(CloudError.fromStatus(401), isA<CloudKeyRejected>());
      expect(CloudError.fromStatus(402), isA<CloudLimitExhausted>());
      expect(CloudError.fromStatus(404), isA<CloudModelUnavailable>());
      expect(CloudError.fromStatus(502), isA<CloudModelUnavailable>());
      expect(CloudError.fromStatus(503), isA<CloudModelUnavailable>());
      expect(CloudError.fromStatus(408), isA<CloudTimeout>());
      expect(CloudError.fromStatus(504), isA<CloudTimeout>());
    });

    test('anything else is the other error with its status', () {
      for (final status in [301, 400, 403, 413, 429, 500]) {
        expect(CloudError.fromStatus(status), CloudOtherError(status));
      }
    });
  });

  group('CloudError.fromErrorObject', () {
    test("OpenRouter's error type decides first", () {
      Map<String, Object> typed(String type) => {
        'code': 400,
        'message': 'x',
        'metadata': {'error_type': type},
      };

      expect(
        CloudError.fromErrorObject(typed('authentication')),
        isA<CloudKeyRejected>(),
      );
      expect(
        CloudError.fromErrorObject(typed('payment_required')),
        isA<CloudLimitExhausted>(),
      );
      for (final type in [
        'not_found',
        'provider_unavailable',
        'provider_overloaded',
      ]) {
        expect(
          CloudError.fromErrorObject(typed(type)),
          isA<CloudModelUnavailable>(),
          reason: type,
        );
      }
      expect(CloudError.fromErrorObject(typed('timeout')), isA<CloudTimeout>());
      expect(
        CloudError.fromErrorObject(typed('rate_limit_exceeded')),
        const CloudOtherError(400),
      );
    });

    test('then a numeric code, as a number or a string', () {
      expect(
        CloudError.fromErrorObject(const {'code': 502, 'message': 'down'}),
        isA<CloudModelUnavailable>(),
      );
      expect(
        CloudError.fromErrorObject(const {'code': '401'}),
        isA<CloudKeyRejected>(),
      );
      expect(
        CloudError.fromErrorObject(const {'code': 429}),
        const CloudOtherError(429),
      );
    });

    test('server_error, a provider that dropped out, is model unavailable', () {
      expect(
        CloudError.fromErrorObject(const {
          'code': 'server_error',
          'message': 'Provider disconnected unexpectedly',
        }),
        isA<CloudModelUnavailable>(),
      );
    });

    test('anything else is the other error without a status', () {
      expect(CloudError.fromErrorObject(null), const CloudOtherError(null));
      expect(CloudError.fromErrorObject('boom'), const CloudOtherError(null));
      expect(
        CloudError.fromErrorObject(const {'code': 'weird'}),
        const CloudOtherError(null),
      );
    });

    test('the message is never kept', () {
      const secret = 'sk-or-v1-secretsecretsecret';
      final error = CloudError.fromErrorObject(const {
        'code': 401,
        'message': 'Bad key $secret',
      });

      expect('$error', isNot(contains(secret)));
      expect('$error', isNot(contains('Bad key')));
    });
  });

  test('every case has a fixed text naming it', () {
    expect('${const CloudOffline()}', startsWith('CloudOffline:'));
    expect('${const CloudKeyRejected()}', startsWith('CloudKeyRejected:'));
    expect(
      '${const CloudLimitExhausted()}',
      startsWith('CloudLimitExhausted:'),
    );
    expect(
      '${const CloudModelUnavailable()}',
      startsWith('CloudModelUnavailable:'),
    );
    expect('${const CloudTimeout()}', startsWith('CloudTimeout:'));
    expect('${const CloudNoKey()}', startsWith('CloudNoKey:'));
    expect('${const CloudOtherError(418)}', endsWith('(HTTP 418)'));
    expect('${const CloudOtherError(null)}', isNot(contains('HTTP')));
  });
}
