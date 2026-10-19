import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/settings/learned_items.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// An in-memory store that counts its writes.
class _CountingStore implements LearnedItemsStore {
  final _store = InMemoryLearnedItemsStore();
  int writes = 0;

  @override
  List<String> read(MorseLanguage language, Level level) =>
      _store.read(language, level);

  @override
  Future<void> write(
    MorseLanguage language,
    Level level,
    List<String> items,
  ) async {
    writes++;
    await _store.write(language, level, items);
  }
}

Level _level(MorseLanguage language, int index) =>
    morseRegistry.levelsForLanguage(language)[index];

void main() {
  final englishDigits = _level(MorseLanguage.english, 0);
  final englishLetters = _level(MorseLanguage.english, 1);
  final englishWords = _level(MorseLanguage.english, 2);
  final russianDigits = _level(MorseLanguage.russian, 0);

  group('LearnedItemsNotifier', () {
    test('starts with the saved items of every language and level', () async {
      final store = InMemoryLearnedItemsStore();
      await store.write(MorseLanguage.english, englishLetters, ['A', 'B']);
      await store.write(MorseLanguage.russian, russianDigits, ['7']);

      final learned = LearnedItemsNotifier(store).state;

      expect(learned.of(MorseLanguage.english, englishLetters), {'A', 'B'});
      expect(learned.of(MorseLanguage.russian, russianDigits), {'7'});
      expect(learned.of(MorseLanguage.english, englishDigits), isEmpty);
    });

    test('drops stored items that are not in their level', () async {
      final store = InMemoryLearnedItemsStore();
      await store.write(MorseLanguage.english, englishWords, [
        'HI',
        'GOODBYE',
        'OK',
      ]);

      final learned = LearnedItemsNotifier(store).state;

      expect(learned.of(MorseLanguage.english, englishWords), {'HI', 'OK'});
    });

    test('add makes an item learned and saves the level', () async {
      final store = InMemoryLearnedItemsStore();
      LearnedItemsNotifier(store)
        ..add(MorseLanguage.english, englishLetters, 'K')
        ..add(MorseLanguage.english, englishLetters, 'A');
      await pumpEventQueue();

      expect(store.read(MorseLanguage.english, englishLetters), ['K', 'A']);
      expect(
        LearnedItemsNotifier(
          store,
        ).state.of(MorseLanguage.english, englishLetters),
        {'K', 'A'},
      );
    });

    test('add publishes the new state at once', () {
      final notifier = LearnedItemsNotifier(InMemoryLearnedItemsStore());
      final seen = <Set<String>>[];
      notifier
        ..addListener(
          (learned) =>
              seen.add(learned.of(MorseLanguage.english, englishLetters)),
          fireImmediately: false,
        )
        ..add(MorseLanguage.english, englishLetters, 'K');

      expect(seen, [
        {'K'},
      ]);
    });

    test('adding a learned item again changes and writes nothing', () async {
      final store = _CountingStore();
      final notifier = LearnedItemsNotifier(store)
        ..add(MorseLanguage.english, englishLetters, 'K');
      final before = notifier.state;

      notifier.add(MorseLanguage.english, englishLetters, 'K');
      await pumpEventQueue();

      expect(store.writes, 1);
      expect(notifier.state, same(before));
    });

    test('keeps digits learned in one language out of the others', () {
      final notifier = LearnedItemsNotifier(InMemoryLearnedItemsStore())
        ..add(MorseLanguage.english, englishDigits, '5');

      expect(notifier.state.of(MorseLanguage.english, englishDigits), {'5'});
      expect(notifier.state.of(MorseLanguage.russian, russianDigits), isEmpty);
    });
  });

  group('learnedItemsProvider', () {
    test('loads from learnedItemsStoreProvider', () async {
      final store = InMemoryLearnedItemsStore();
      await store.write(MorseLanguage.english, englishLetters, ['Z']);
      final container = ProviderContainer(
        overrides: [learnedItemsStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);

      expect(
        container
            .read(learnedItemsProvider)
            .of(MorseLanguage.english, englishLetters),
        {'Z'},
      );
    });
  });
}
