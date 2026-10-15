import 'package:feel_you/morse/morse.dart';
import 'package:feel_you/session/session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_doubles/fixed_levels_session.dart';

/// A registry smaller than the app's: English has two levels (three digits,
/// then the letters E and T) and Arabic has three (the digits, then two
/// one-letter levels). Russian has only the digits.
MorseAlphabetRegistry _smallRegistry() {
  final arabicLetters = arabicAlphabet.characterOrder;
  return MorseAlphabetRegistry([
    MorseAlphabet(
      language: null,
      characters: digitAlphabet.characters,
      characterOrder: const ['0', '1', '2'],
      levels: [
        Level(
          name: 'small-digits',
          characters: const ['0', '1', '2'],
          patterns: digitAlphabet.characters,
        ),
      ],
    ),
    MorseAlphabet(
      language: MorseLanguage.english,
      characters: englishAlphabet.characters,
      characterOrder: const ['E', 'T'],
      levels: [
        Level(
          name: 'small-letters',
          characters: const ['E', 'T'],
          patterns: englishAlphabet.characters,
          language: MorseLanguage.english,
        ),
      ],
    ),
    MorseAlphabet(
      language: MorseLanguage.arabic,
      characters: arabicAlphabet.characters,
      characterOrder: arabicLetters,
      levels: [
        Level(
          name: 'arabic-first',
          characters: [arabicLetters[0]],
          patterns: arabicAlphabet.characters,
          language: MorseLanguage.arabic,
        ),
        Level(
          name: 'arabic-second',
          characters: [arabicLetters[1]],
          patterns: arabicAlphabet.characters,
          language: MorseLanguage.arabic,
        ),
      ],
    ),
  ]);
}

void main() {
  group('SessionState registry', () {
    test('defaults to the global morseRegistry', () {
      const state = SessionState(language: MorseLanguage.english);
      expect(state.registry, same(morseRegistry));
      expect(
        state.levels,
        same(morseRegistry.levelsForLanguage(MorseLanguage.english)),
      );
    });

    test('resolves levels from an injected registry', () {
      final registry = _smallRegistry();
      final state = SessionState(
        language: MorseLanguage.english,
        levelIndex: 1,
        positionIndex: 1,
        registry: registry,
      );
      expect(state.registry, same(registry));
      expect(state.levels.map((l) => l.name), [
        'small-digits',
        'small-letters',
      ]);
      expect(state.currentLevel.name, 'small-letters');
      expect(state.currentCharacter, 'T');
    });

    test('levels is the same cached instance on every read', () {
      final state = SessionState(
        language: MorseLanguage.arabic,
        registry: _smallRegistry(),
      );
      expect(state.levels, same(state.levels));
    });

    test('copyWith keeps the registry', () {
      final registry = _smallRegistry();
      final state = SessionState(
        language: MorseLanguage.english,
        registry: registry,
      ).copyWith(levelIndex: 1, phase: SessionPhase.listening);
      expect(state.registry, same(registry));
      expect(state.currentLevel.name, 'small-letters');
    });

    test('copyWith re-resolves levels when the language changes', () {
      final registry = _smallRegistry();
      final english = SessionState(
        language: MorseLanguage.english,
        registry: registry,
      );
      final arabic = english.copyWith(
        language: MorseLanguage.arabic,
        levelIndex: 2,
      );
      expect(
        arabic.levels,
        same(registry.levelsForLanguage(MorseLanguage.arabic)),
      );
      expect(arabic.currentLevel.name, 'arabic-second');
      expect(english.levels.length, 2);
    });
  });

  group('SessionState equality with a registry', () {
    test('a default state equals one built with the global registry', () {
      const implicit = SessionState(
        language: MorseLanguage.english,
        levelIndex: 1,
        positionIndex: 4,
        phase: SessionPhase.feedback,
      );
      final explicit = SessionState(
        language: MorseLanguage.english,
        levelIndex: 1,
        positionIndex: 4,
        phase: SessionPhase.feedback,
        registry: morseRegistry,
      );
      expect(explicit, implicit);
      expect(explicit.hashCode, implicit.hashCode);
    });

    test('states with the same registry and fields are equal', () {
      final registry = _smallRegistry();
      final a = SessionState(
        language: MorseLanguage.english,
        levelIndex: 1,
        registry: registry,
      );
      final b = SessionState(
        language: MorseLanguage.english,
        levelIndex: 1,
        registry: registry,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a.copyWith(), a);
    });

    test('a phase round trip through copyWith compares equal', () {
      final state = SessionState(
        language: MorseLanguage.english,
        registry: _smallRegistry(),
      );
      final roundTrip = state
          .copyWith(phase: SessionPhase.listening)
          .copyWith(phase: SessionPhase.playing);
      expect(roundTrip, state);
    });

    test('states resolving from different registries are not equal', () {
      final a = SessionState(
        language: MorseLanguage.english,
        registry: _smallRegistry(),
      );
      final b = SessionState(
        language: MorseLanguage.english,
        registry: _smallRegistry(),
      );
      expect(a, isNot(b));
      expect(a, isNot(const SessionState(language: MorseLanguage.english)));
    });

    test('the default notifier state still equals a const state', () {
      final notifier = SessionNotifier(MorseLanguage.english);
      addTearDown(notifier.dispose);
      expect(
        notifier.state,
        const SessionState(language: MorseLanguage.english),
      );
    });
  });

  group('SessionNotifier with an injected registry', () {
    late MorseAlphabetRegistry registry;
    late SessionNotifier notifier;

    setUp(() {
      registry = _smallRegistry();
      notifier = SessionNotifier(MorseLanguage.english, registry: registry);
      addTearDown(notifier.dispose);
    });

    test('defaults to the global morseRegistry', () {
      final defaultNotifier = SessionNotifier(MorseLanguage.english);
      addTearDown(defaultNotifier.dispose);
      expect(defaultNotifier.registry, same(morseRegistry));
      expect(defaultNotifier.state.registry, same(morseRegistry));
    });

    test('starts on the first level of the injected registry', () {
      expect(notifier.registry, same(registry));
      expect(notifier.state.registry, same(registry));
      expect(notifier.state.currentLevel.name, 'small-digits');
      expect(notifier.state.currentCharacter, '0');
    });

    test('nextPosition clamps at the end of the injected level', () {
      notifier
        ..nextPosition()
        ..nextPosition();
      expect(notifier.state.currentCharacter, '2');

      final before = notifier.state;
      notifier.nextPosition();
      expect(notifier.state, before);
      expect(notifier.state.positionIndex, 2);
    });

    test('nextLevel stops at the last level of the injected registry', () {
      notifier.nextLevel();
      expect(notifier.state.levelIndex, 1);
      expect(notifier.state.currentLevel.name, 'small-letters');

      final before = notifier.state;
      notifier.nextLevel();
      expect(notifier.state, before);
      expect(notifier.state.levelIndex, 1);
    });

    test('previousLevel stops at the first level', () {
      notifier
        ..nextLevel()
        ..previousLevel();
      expect(notifier.state.currentLevel.name, 'small-digits');

      final before = notifier.state;
      notifier.previousLevel();
      expect(notifier.state, before);
      expect(notifier.state.levelIndex, 0);
    });

    test('home returns to the start and keeps the registry', () {
      notifier
        ..nextLevel()
        ..nextPosition()
        ..setPhase(SessionPhase.feedback)
        ..home();
      expect(
        notifier.state,
        SessionState(language: MorseLanguage.english, registry: registry),
      );
      expect(notifier.state.registry, same(registry));
    });

    test('selectLanguage switches levels within the injected registry', () {
      notifier.selectLanguage(MorseLanguage.arabic);
      expect(notifier.state.registry, same(registry));
      expect(notifier.state.levels.map((l) => l.name), [
        'small-digits',
        'arabic-first',
        'arabic-second',
      ]);

      notifier
        ..nextLevel()
        ..nextLevel();
      expect(notifier.state.currentLevel.name, 'arabic-second');

      notifier.nextLevel();
      expect(notifier.state.levelIndex, 2);
    });

    test('selectLanguage to a language with only universal levels', () {
      notifier
        ..selectLanguage(MorseLanguage.russian)
        ..nextLevel();
      expect(notifier.state.levelIndex, 0);
      expect(notifier.state.currentLevel.name, 'small-digits');
    });
  });

  group('SessionNotifier with a reordered registry', () {
    test('navigates in the registry order, words first', () {
      final notifier = SessionNotifier(
        MorseLanguage.english,
        registry: reorderedEnglishRegistry(),
      );
      addTearDown(notifier.dispose);

      expect(notifier.state.currentLevel.kind, LevelKind.words);

      notifier.nextLevel();
      expect(notifier.state.currentLevel.name, 'letters');
      expect(notifier.state.currentCharacter, 'A');

      notifier.nextLevel();
      expect(notifier.state.currentLevel.name, 'digits');
      expect(notifier.state.currentCharacter, '0');

      notifier.nextLevel();
      expect(notifier.state.levelIndex, 2);
    });
  });

  group('FixedLevelsSessionNotifier', () {
    test('navigation stays within the fixed levels', () {
      final levels = reorderedEnglishLevels();
      final notifier = FixedLevelsSessionNotifier(
        FixedLevelsSessionState(
          levels: levels,
          language: MorseLanguage.english,
          levelIndex: 2,
        ),
      );
      addTearDown(notifier.dispose);

      expect(notifier.state.currentLevel, levels[2]);
      notifier.nextLevel();
      expect(notifier.state.levelIndex, 2);

      notifier.home();
      expect(notifier.state.currentLevel, levels[0]);

      notifier.selectLanguage(MorseLanguage.arabic);
      expect(notifier.state.levels, levels);
    });
  });

  group('sessionNotifierProvider', () {
    test('uses the global registry by default', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(sessionNotifierProvider.notifier).registry,
        same(morseRegistry),
      );
      expect(
        container.read(sessionNotifierProvider),
        const SessionState(language: MorseLanguage.english),
      );
    });

    test('uses an overridden morseRegistryProvider', () {
      final registry = _smallRegistry();
      final container = ProviderContainer(
        overrides: [morseRegistryProvider.overrideWithValue(registry)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(sessionNotifierProvider.notifier);
      expect(notifier.registry, same(registry));
      expect(container.read(sessionNotifierProvider).registry, same(registry));

      notifier
        ..nextLevel()
        ..nextLevel();
      final state = container.read(sessionNotifierProvider);
      expect(state.levelIndex, 1);
      expect(state.currentLevel.name, 'small-letters');
    });
  });
}
