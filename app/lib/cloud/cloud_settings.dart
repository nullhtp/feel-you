import 'package:flutter/foundation.dart';

/// The settings every cloud request follows.
///
/// Kept on the device by the cloud preferences store; the assistant screen
/// (#63) changes them.
@immutable
final class CloudSettings {
  /// Creates settings with the given values, by default OpenRouter's base
  /// URL with data collection denied.
  CloudSettings({Uri? baseUrl, this.denyDataCollection = true})
    : baseUrl = baseUrl ?? defaultBaseUrl;

  /// OpenRouter's OpenAI-compatible API.
  static final defaultBaseUrl = Uri.parse('https://openrouter.ai/api/v1');

  /// The endpoint's base URL, without a trailing `/`. Requests go to paths
  /// under it, such as `chat/completions`. Always a valid base URL (see
  /// [parseCloudBaseUrl]).
  final Uri baseUrl;

  /// Whether requests ask OpenRouter for providers that neither store nor
  /// train on the data (`provider.data_collection: "deny"`). On by default.
  final bool denyDataCollection;

  /// The URL of [path] under [baseUrl], e.g. `chat/completions`.
  Uri endpoint(String path) => baseUrl.replace(path: '${baseUrl.path}/$path');

  /// A copy with the given values replaced.
  CloudSettings copyWith({Uri? baseUrl, bool? denyDataCollection}) =>
      CloudSettings(
        baseUrl: baseUrl ?? this.baseUrl,
        denyDataCollection: denyDataCollection ?? this.denyDataCollection,
      );

  @override
  bool operator ==(Object other) =>
      other is CloudSettings &&
      other.baseUrl == baseUrl &&
      other.denyDataCollection == denyDataCollection;

  @override
  int get hashCode => Object.hash(baseUrl, denyDataCollection);

  @override
  String toString() =>
      'CloudSettings($baseUrl, denyDataCollection: $denyDataCollection)';
}

/// The hosts that may be reached over plain `http`: the phone itself.
const loopbackHosts = {'localhost', '127.0.0.1', '::1'};

/// Parses [input] as a cloud base URL, or returns `null` if it is not one.
///
/// Surrounding whitespace and a trailing `/` are dropped. The scheme must
/// be `https`, or `http` when the host is one of [loopbackHosts] (a server
/// on the phone itself, which never leaves it); the URL must have a host
/// and no user name, password, query or fragment, so it can't carry a
/// secret and is safe to show and to log.
Uri? parseCloudBaseUrl(String input) {
  final url = Uri.tryParse(input.trim());
  if (url == null || !url.hasAuthority || url.host.isEmpty) return null;
  final scheme = url.scheme.toLowerCase();
  final host = url.host.toLowerCase();
  final secure =
      scheme == 'https' || (scheme == 'http' && loopbackHosts.contains(host));
  if (!secure) return null;
  if (url.userInfo.isNotEmpty || url.hasQuery || url.hasFragment) return null;
  var path = url.path;
  while (path.endsWith('/')) {
    path = path.substring(0, path.length - 1);
  }
  return url.replace(scheme: scheme, host: host, path: path);
}
