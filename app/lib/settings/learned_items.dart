import 'dart:async';

import 'package:feel_you/morse/morse.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Remembers which items the user has learned, per language and level, so
/// the quiz keeps growing from one launch to the next.
///
/// Items are kept as the items themselves ("K", "ВОДА"), not as positions,
/// so a change to a level's item list never shifts them onto other items.
abstract interface class LearnedItemsStore {
  /// The items saved as learned for [level] in [language].
  ///
  /// Empty when none are saved or the stored value is not a string list
  /// (e.g. corrupt, or written by another version). The items are returned
  /// as stored: they are not checked against the level.
  List<String> read(MorseLanguage language, Level level);

  /// Saves [items] as the learned items of [level] in [language], replacing
  /// whatever was saved for it.
  ///
  /// Best effort: a failed write is logged, never thrown, so it can't
  /// interrupt a lesson.
  Future<void> write(MorseLanguage language, Level level, List<String> items);
}

/// A [LearnedItemsStore] backed by [SharedPreferences], so learned items
/// survive app restarts.
///
/// Each language and level has its own string list under [storageKey]. The
/// key contains the level's [Level.name], so renaming a level orphans its
/// saved items: a rename must move the old key's value to the new one.
class SharedPreferencesLearnedItemsStore implements LearnedItemsStore {
  /// Creates a store that keeps learned items in the given preferences.
  SharedPreferencesLearnedItemsStore(this._preferences);

  /// The [SharedPreferences] key holding the learned items of [level] in
  /// [language], e.g. `learned_items.russian.russian-letters`.
  static String storageKey(MorseLanguage language, Level level) =>
      'learned_items.${language.name}.${level.name}';

  final SharedPreferences _preferences;

  @override
  List<String> read(MorseLanguage language, Level level) {
    // `get` rather than `getStringList`: a value of another type must not
    // throw.
    final stored = _preferences.get(storageKey(language, level));
    if (stored is! List) return const [];
    return List.unmodifiable(stored.whereType<String>());
  }

  @override
  Future<void> write(
    MorseLanguage language,
    Level level,
    List<String> items,
  ) async {
    try {
      final saved = await _preferences.setStringList(
        storageKey(language, level),
        items,
      );
      if (!saved) debugPrint('Could not save the learned items.');
    } on Exception catch (error) {
      debugPrint('Could not save the learned items: $error');
    }
  }
}

/// A [LearnedItemsStore] that only lasts as long as the app runs.
///
/// Used when [SharedPreferences] can't be loaded, and by default when
/// [learnedItemsStoreProvider] is not overridden (e.g. in tests).
class InMemoryLearnedItemsStore implements LearnedItemsStore {
  /// Creates a store that starts with nothing saved.
  InMemoryLearnedItemsStore();

  final Map<(MorseLanguage, String), List<String>> _items = {};

  @override
  List<String> read(MorseLanguage language, Level level) =>
      _items[(language, level.name)] ?? const [];

  @override
  Future<void> write(
    MorseLanguage language,
    Level level,
    List<String> items,
  ) async => _items[(language, level.name)] = List.unmodifiable(items);
}

/// Loads the persistent [LearnedItemsStore].
///
/// Call before `runApp` and override [learnedItemsStoreProvider] with the
/// result, so learned items are known before the first frame. Falls back to
/// an [InMemoryLearnedItemsStore] (learned items last for the current run
/// only) if the platform storage can't be loaded.
Future<LearnedItemsStore> loadLearnedItemsStore() async {
  try {
    return SharedPreferencesLearnedItemsStore(
      await SharedPreferences.getInstance(),
    );
  } on Exception catch (error) {
    debugPrint(
      'Could not load preferences, learned items will not be saved: $error',
    );
    return InMemoryLearnedItemsStore();
  }
}

/// Provides the [LearnedItemsStore].
///
/// `main` overrides it with the store from [loadLearnedItemsStore]. The
/// default keeps learned items in memory only, so widgets and tests work
/// without any setup.
final learnedItemsStoreProvider = Provider<LearnedItemsStore>(
  (ref) => InMemoryLearnedItemsStore(),
);

/// The items the user has learned, per language and level.
///
/// An item is learned the first time the user answers it correctly in the
/// lessons, and stays learned. The quiz draws from these items.
@immutable
class LearnedItems {
  /// Creates a value with nothing learned.
  const LearnedItems() : _items = const {};

  const LearnedItems._(this._items);

  /// Learned items keyed by language and [Level.name], in the order they
  /// were learned.
  final Map<(MorseLanguage, String), Set<String>> _items;

  /// The learned items of [level] in [language], in the order they were
  /// learned.
  Set<String> of(MorseLanguage language, Level level) =>
      _items[(language, level.name)] ?? const {};

  /// Returns a copy in which [item] of [level] is learned in [language].
  LearnedItems adding(MorseLanguage language, Level level, String item) {
    final key = (language, level.name);
    return LearnedItems._(
      Map.unmodifiable({
        ..._items,
        key: Set<String>.unmodifiable({...?_items[key], item}),
      }),
    );
  }
}

/// Keeps the [LearnedItems] in memory, so they can be read on hot paths and
/// watched, and saves each change to a [LearnedItemsStore].
///
/// Everything is read from the store once, on creation: every level of every
/// language of the registry. Stored items that are not items of their level
/// (e.g. a word removed from a level) are dropped.
class LearnedItemsNotifier extends StateNotifier<LearnedItems> {
  /// Creates a notifier with the items saved in the given store for the
  /// levels of [registry] (the global [morseRegistry] by default).
  LearnedItemsNotifier(this._store, {MorseAlphabetRegistry? registry})
    : super(_load(_store, registry ?? morseRegistry));

  final LearnedItemsStore _store;

  static LearnedItems _load(
    LearnedItemsStore store,
    MorseAlphabetRegistry registry,
  ) {
    var items = const LearnedItems();
    for (final language in MorseLanguage.values) {
      for (final level in registry.levelsForLanguage(language)) {
        final known = level.characters.toSet();
        for (final item in store.read(language, level)) {
          if (known.contains(item)) {
            items = items.adding(language, level, item);
          }
        }
      }
    }
    return items;
  }

  /// Marks [item] of [level] as learned in [language] and saves the level's
  /// learned items.
  ///
  /// No-op if it is already learned. The new state is published at once; the
  /// save is best effort and not awaited, so a slow or failed write never
  /// holds up the lesson.
  void add(MorseLanguage language, Level level, String item) {
    if (state.of(language, level).contains(item)) return;
    state = state.adding(language, level, item);
    unawaited(
      _store.write(language, level, state.of(language, level).toList()),
    );
  }
}

/// Provides the [LearnedItemsNotifier] and the current [LearnedItems].
///
/// Loaded from [learnedItemsStoreProvider], for the levels of
/// [morseRegistryProvider].
final learnedItemsProvider =
    StateNotifierProvider<LearnedItemsNotifier, LearnedItems>(
      (ref) => LearnedItemsNotifier(
        ref.watch(learnedItemsStoreProvider),
        registry: ref.watch(morseRegistryProvider),
      ),
    );
