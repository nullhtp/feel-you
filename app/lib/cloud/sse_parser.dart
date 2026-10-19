import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

/// One event of a server-sent event stream.
@immutable
final class SseEvent {
  /// Creates an event of [type] carrying [data].
  const SseEvent(this.data, {this.type = 'message', this.id});

  /// The event's data: its `data:` lines joined with line breaks.
  final String data;

  /// The event's type, from its `event:` line; `message` without one.
  final String type;

  /// The last event ID seen so far, from an `id:` line, or `null`.
  final String? id;

  @override
  bool operator ==(Object other) =>
      other is SseEvent &&
      other.data == data &&
      other.type == type &&
      other.id == id;

  @override
  int get hashCode => Object.hash(data, type, id);

  @override
  String toString() => 'SseEvent($type, ${data.length} characters)';
}

/// Parses a server-sent event stream, as the HTML standard's event stream
/// interpretation describes it, from the bytes of a response body.
///
/// The bytes are UTF-8 (a malformed sequence becomes U+FFFD, a leading
/// byte order mark is dropped) and may be cut anywhere, inside a line or a
/// character. Lines end with LF, CRLF or CR. A `data:` line adds its value
/// to the event's data, a blank line dispatches the event, a line starting
/// with `:` is a comment (OpenRouter's `: OPENROUTER PROCESSING`
/// keep-alives) and is skipped, as are `retry:` and unknown fields. An
/// event without data is not dispatched, and neither is an unfinished
/// event at the end of the stream.
///
/// Cancelling the subscription cancels the subscription to the bytes.
final class SseParser extends StreamTransformerBase<List<int>, SseEvent> {
  const SseParser();

  @override
  Stream<SseEvent> bind(Stream<List<int>> stream) => Stream.eventTransformed(
    stream
        .transform(const Utf8Decoder(allowMalformed: true))
        .transform(const LineSplitter()),
    _SseSink.new,
  );
}

/// Turns the lines of one event stream into [SseEvent]s.
class _SseSink implements EventSink<String> {
  _SseSink(this._out);

  static const _byteOrderMark = '\uFEFF';

  final EventSink<SseEvent> _out;

  /// The data lines of the event being read, `null` until its first one.
  StringBuffer? _data;
  String _type = '';
  String? _lastEventId;
  bool _firstLine = true;

  @override
  void add(String input) {
    var line = input;
    if (_firstLine) {
      _firstLine = false;
      if (line.startsWith(_byteOrderMark)) line = line.substring(1);
    }
    if (line.isEmpty) {
      _dispatch();
      return;
    }
    if (line.startsWith(':')) return;
    final colon = line.indexOf(':');
    final field = colon < 0 ? line : line.substring(0, colon);
    var value = colon < 0 ? '' : line.substring(colon + 1);
    if (value.startsWith(' ')) value = value.substring(1);
    switch (field) {
      case 'data':
        final data = _data;
        if (data == null) {
          _data = StringBuffer(value);
        } else {
          data
            ..write('\n')
            ..write(value);
        }
      case 'event':
        _type = value;
      case 'id':
        if (!value.contains('\u0000')) _lastEventId = value;
    }
  }

  void _dispatch() {
    final data = _data;
    final type = _type;
    _data = null;
    _type = '';
    if (data == null) return;
    _out.add(
      SseEvent(
        data.toString(),
        type: type.isEmpty ? 'message' : type,
        id: _lastEventId,
      ),
    );
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) =>
      _out.addError(error, stackTrace);

  /// Ends the stream; an event still being read is dropped.
  @override
  void close() => _out.close();
}
