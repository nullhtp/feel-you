import 'dart:async';

/// Collects pieces of text as they stream in and hands out each word as
/// soon as it is complete.
///
/// A word is a run of characters other than whitespace (any Unicode
/// whitespace, including line breaks and no-break spaces). It is complete
/// once whitespace follows it, so the reader can start on it before the
/// rest of the answer has arrived. Punctuation stays with its word
/// (`world,`).
class WordBuffer {
  static final _word = RegExp(r'\S+');
  static final _endsWithSpace = RegExp(r'\s$');

  /// The start of a word that is not complete yet.
  String _pending = '';

  /// Adds [text] and returns the words it completes, in order.
  List<String> add(String text) {
    if (text.isEmpty) return const [];
    final combined = _pending + text;
    final words = [for (final match in _word.allMatches(combined)) match[0]!];
    if (words.isNotEmpty && !_endsWithSpace.hasMatch(combined)) {
      _pending = words.removeLast();
    } else {
      _pending = '';
    }
    return words;
  }

  /// Returns the last, unfinished word, or `null` when there is none, and
  /// empties the buffer. Call it when the text has ended.
  String? flush() {
    final last = _pending;
    _pending = '';
    return last.isEmpty ? null : last;
  }

  /// Drops the unfinished word, for text that ended with an error.
  void clear() => _pending = '';
}

/// Turns a stream of text pieces into a stream of words, with a
/// [WordBuffer].
///
/// The last word is released when the stream ends. An error drops the
/// unfinished word before it is passed on: the word may have been cut off.
class WordSplitter extends StreamTransformerBase<String, String> {
  const WordSplitter();

  @override
  Stream<String> bind(Stream<String> stream) =>
      Stream.eventTransformed(stream, _WordSink.new);
}

/// The [WordBuffer] of one listener of a [WordSplitter] stream.
class _WordSink implements EventSink<String> {
  _WordSink(this._out);

  final EventSink<String> _out;
  final _buffer = WordBuffer();

  @override
  void add(String text) => _buffer.add(text).forEach(_out.add);

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    _buffer.clear();
    _out.addError(error, stackTrace);
  }

  @override
  void close() {
    final last = _buffer.flush();
    if (last != null) _out.add(last);
    _out.close();
  }
}
