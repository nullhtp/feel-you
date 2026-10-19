import 'dart:math';

import 'package:feel_you/morse/morse.dart';

/// Returns the items of [level] the user has learned in [language].
typedef LearnedItemsOf =
    Set<String> Function(MorseLanguage language, Level level);

/// Draws the items the quiz plays.
///
/// An item is drawn at random from the learned items of the level, so the
/// quiz only asks for what the user has already met in the lessons. While
/// fewer than two items are learned, a quiz of one item (or none) would
/// teach nothing, so it draws from the whole level instead. It never draws
/// the item it is asked to replace, so the quiz always moves on.
class QuizItemPicker {
  /// Creates a picker that looks learned items up with [learnedItemsOf]
  /// (nothing learned by default) and draws with [random].
  QuizItemPicker({LearnedItemsOf? learnedItemsOf, Random? random})
    : _learnedItemsOf = learnedItemsOf ?? _nothingLearned,
      _random = random ?? Random();

  final LearnedItemsOf _learnedItemsOf;
  final Random _random;

  static Set<String> _nothingLearned(MorseLanguage language, Level level) =>
      const {};

  /// Draws a quiz item of [level] in [language], other than [previous].
  ///
  /// Learned items are looked up on every draw, so an item learned while the
  /// quiz was open counts from the next draw on.
  String pick(MorseLanguage language, Level level, {String? previous}) {
    final learned = _learnedItemsOf(language, level);
    // In level order, so a seeded draw does not depend on learning order.
    var pool = level.characters.where(learned.contains).toList();
    if (pool.length < 2) pool = List.of(level.characters);
    if (pool.length > 1) pool.remove(previous);
    return pool[_random.nextInt(pool.length)];
  }
}
