import 'package:flutter/foundation.dart';

/// Why a cloud request failed.
///
/// One case per failure the user must be able to tell apart (the status
/// signals of #64 map each case to its own vibration). The cases carry no
/// key, no message from the server and no response body, so an error and
/// its [toString] are always safe to log and to show.
@immutable
sealed class CloudError implements Exception {
  const CloudError();

  /// The error for an HTTP [statusCode] of a failed chat request.
  ///
  /// 401 rejects the key, 402 means the credit or the key's limit is used
  /// up, 404 (no such model, or none that meets the data policy), 502 (the
  /// model is down) and 503 (no provider available) mean the model is
  /// unavailable, 408 and 504 are timeouts; anything else is
  /// [CloudOtherError].
  factory CloudError.fromStatus(int statusCode) => switch (statusCode) {
    401 => const CloudKeyRejected(),
    402 => const CloudLimitExhausted(),
    404 || 502 || 503 => const CloudModelUnavailable(),
    408 || 504 => const CloudTimeout(),
    _ => CloudOtherError(statusCode),
  };

  /// The error for an `error` object in the body or the event stream of a
  /// chat request.
  ///
  /// OpenRouter's typed `metadata.error_type` decides first, then a
  /// numeric `code` as for [CloudError.fromStatus]; `server_error` (a
  /// provider that dropped out mid-answer) means the model is unavailable.
  /// Only the type and the code are read: the message may echo the input.
  factory CloudError.fromErrorObject(Object? error) {
    if (error is! Map) return const CloudOtherError(null);
    final metadata = error['metadata'];
    final type = metadata is Map ? metadata['error_type'] : null;
    switch (type) {
      case 'authentication':
        return const CloudKeyRejected();
      case 'payment_required':
        return const CloudLimitExhausted();
      case 'not_found' || 'provider_unavailable' || 'provider_overloaded':
        return const CloudModelUnavailable();
      case 'timeout':
        return const CloudTimeout();
    }
    final code = error['code'];
    final status = code is int ? code : int.tryParse('$code');
    if (status != null) return CloudError.fromStatus(status);
    if (code == 'server_error') return const CloudModelUnavailable();
    return const CloudOtherError(null);
  }
}

/// There is no usable connection: no network, the endpoint's name could
/// not be resolved, the connection was refused, dropped mid-answer or its
/// TLS handshake failed.
final class CloudOffline extends CloudError {
  const CloudOffline();

  @override
  String toString() => 'CloudOffline: no connection to the cloud';
}

/// The endpoint rejected the key (HTTP 401).
final class CloudKeyRejected extends CloudError {
  const CloudKeyRejected();

  @override
  String toString() => 'CloudKeyRejected: the cloud key was rejected';
}

/// The account's credit or the key's spending limit is used up (HTTP 402).
final class CloudLimitExhausted extends CloudError {
  const CloudLimitExhausted();

  @override
  String toString() => 'CloudLimitExhausted: the credit or limit is used up';
}

/// No model of the fallback list could answer: none exists, none meets the
/// data policy, or their providers are down (HTTP 404, 502, 503, or an
/// error in a `200` stream).
final class CloudModelUnavailable extends CloudError {
  const CloudModelUnavailable();

  @override
  String toString() => 'CloudModelUnavailable: no model could answer';
}

/// The answer's first token did not arrive in time, or the endpoint timed
/// out (HTTP 408, 504).
final class CloudTimeout extends CloudError {
  const CloudTimeout();

  @override
  String toString() => 'CloudTimeout: the cloud did not answer in time';
}

/// No cloud key is saved, so nothing was sent.
final class CloudNoKey extends CloudError {
  const CloudNoKey();

  @override
  String toString() => 'CloudNoKey: no cloud key is saved';
}

/// Any other failure: another HTTP status, a redirect, a response that is
/// not an event stream, or an error without a known code.
final class CloudOtherError extends CloudError {
  /// Creates the error with the response's [statusCode], if there was one.
  const CloudOtherError(this.statusCode);

  /// The HTTP status code, or `null` when there was none to report.
  final int? statusCode;

  @override
  bool operator ==(Object other) =>
      other is CloudOtherError && other.statusCode == statusCode;

  @override
  int get hashCode => Object.hash(CloudOtherError, statusCode);

  @override
  String toString() => statusCode == null
      ? 'CloudOtherError: the cloud request failed'
      : 'CloudOtherError: the cloud request failed (HTTP $statusCode)';
}
