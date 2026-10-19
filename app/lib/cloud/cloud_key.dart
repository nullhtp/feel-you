import 'package:flutter/foundation.dart';

/// The assistant's key for the cloud (OpenRouter, or another
/// OpenAI-compatible endpoint), validated and safe to print.
///
/// The key is a credential that spends the assistant's money. Pass it
/// around as a [CloudKey], never as a plain `String`: [toString] gives only
/// the [masked] form, so string interpolation, `print` and error messages
/// can't leak it by accident. Only [value] holds the key itself; read it
/// where the key is actually needed (the request header), and never log it.
///
/// Not an `Equatable`: its `toString` would print the key.
@immutable
final class CloudKey {
  const CloudKey._(this.value);

  /// Parses [input] as a key, as [tryParse] does.
  ///
  /// Throws a [FormatException] if [input] is not a key. The exception
  /// never contains the input, which may be a key with a typo in it.
  factory CloudKey.parse(String input) =>
      tryParse(input) ?? (throw const FormatException('Not a cloud key.'));

  /// Parses [input] as a key, or returns `null` if it is not one.
  ///
  /// Surrounding whitespace (a pasted line break, say) is trimmed. The rest
  /// must be 1 to [maxLength] characters long, each printable ASCII other
  /// than a space (`!` to `~`), which is what an `Authorization: Bearer`
  /// header carries as is.
  static CloudKey? tryParse(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty || trimmed.length > maxLength) return null;
    for (final unit in trimmed.codeUnits) {
      if (unit < _firstAllowed || unit > _lastAllowed) return null;
    }
    return CloudKey._(trimmed);
  }

  /// The longest key accepted, in characters.
  ///
  /// Far above OpenRouter's keys (about 73 characters) and those of other
  /// OpenAI-compatible endpoints, and short enough to reject a whole
  /// paragraph pasted by mistake.
  static const maxLength = 512;

  /// The prefix of OpenRouter keys, kept in the [masked] form.
  static const openRouterPrefix = 'sk-or-';

  /// `!`, the first printable ASCII character after the space.
  static const _firstAllowed = 0x21;

  /// `~`, the last printable ASCII character.
  static const _lastAllowed = 0x7E;

  /// The key itself.
  ///
  /// Only for where the key is used, such as a request header. Never log
  /// it, show it or put it in an error message; use [masked] instead.
  final String value;

  /// The form of the key that may be shown or logged, e.g. `sk-or-...a1b2`.
  ///
  /// See [maskCloudKey].
  String get masked => maskCloudKey(value);

  @override
  bool operator ==(Object other) => other is CloudKey && other.value == value;

  @override
  int get hashCode => value.hashCode;

  /// The [masked] form, never the key.
  @override
  String toString() => 'CloudKey($masked)';
}

/// How many of the key's last characters the masked form shows.
const maskedTailLength = 4;

/// How many characters, not counting [CloudKey.openRouterPrefix], must stay
/// hidden for the masked form to show the last [maskedTailLength].
const minHiddenCharacters = 12;

/// Masks [key] for display, e.g. `sk-or-v1-…a1b2` becomes `sk-or-...a1b2`.
///
/// The masked form is [CloudKey.openRouterPrefix] when the key starts with
/// it, then `...`, then the last [maskedTailLength] characters. Those are
/// shown only when at least [minHiddenCharacters] characters, not counting
/// the prefix, stay hidden: a short key ends at `...` (`sk-or-...`, or
/// `...` for a key without the prefix) rather than give away a large part
/// of itself. A key without the OpenRouter prefix shows no prefix, since
/// for an unknown format the start may be secret too.
String maskCloudKey(String key) {
  const ellipsis = '...';
  final hasPrefix = key.startsWith(CloudKey.openRouterPrefix);
  final prefix = hasPrefix ? CloudKey.openRouterPrefix : '';
  final rest = key.substring(prefix.length);
  final showTail = rest.length - maskedTailLength >= minHiddenCharacters;
  final tail = showTail ? rest.substring(rest.length - maskedTailLength) : '';
  return '$prefix$ellipsis$tail';
}
