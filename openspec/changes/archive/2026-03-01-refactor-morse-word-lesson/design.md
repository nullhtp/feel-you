## Context

Word Morse data files (`morse_words.dart`, `morse_arabic_words.dart`) manually hardcode flat patterns for each word. These patterns are composed of the same letter patterns defined in `morse_alphabet.dart` and `morse_arabic.dart`, joined with `MorseSymbol.charGap` separators. The duplication means any alphabet change requires manually updating every word pattern, and the hand-written patterns risk silent drift from the canonical alphabet.

Currently, both word files export two symbols each:
- A `Map<String, List<MorseSymbol>>` (`morseWords` / `morseArabicWords`) — word-to-pattern map
- A `List<String>` (`morseWordsList` / `morseArabicWordsList`) — ordered word list

All downstream consumers (the `Level` class in `levels.dart`, the `TeachingOrchestrator`, and tests) depend on these exports.

## Goals / Non-Goals

**Goals:**
- Eliminate pattern duplication: word patterns become a pure function of alphabet patterns
- Add a reusable `composeWordPattern()` utility to `morse_utils.dart`
- Preserve the existing public API of both word files (same exported symbols, same types, same values at runtime)
- Update tests to focus on the composition utility and spot-check correctness

**Non-Goals:**
- Changing the word lists (same 20 English + 20 Arabic words)
- Making word patterns compile-time `const` (they become runtime-computed `final`)
- Modifying the Level system, session state, teaching loop, or any UI/gesture code
- Adding new words, dynamic word generation, or randomization

## Decisions

### 1. Composition utility in `morse_utils.dart`

**Decision**: Add `composeWordPattern(String word, Map<String, List<MorseSymbol>> alphabet)` to `morse_utils.dart`.

**Rationale**: `morse_utils.dart` already hosts letter-level encode/decode functions. A word-composition function is a natural extension of the same responsibility. It avoids creating a new file and keeps Morse encoding logic centralized.

**Alternative considered**: A separate `morse_word_builder.dart` — rejected because the function is small (~10 lines) and doesn't warrant its own file.

### 2. Function signature takes an explicit alphabet map

**Decision**: `composeWordPattern` accepts the alphabet map as a parameter rather than importing it internally.

**Rationale**: This keeps the function language-agnostic. English words pass `morseAlphabet`, Arabic words pass `morseArabicAlphabet`. The function itself has no language coupling. It also makes the function trivially testable with minimal fixtures.

### 3. Character normalization for Arabic special cases

**Decision**: The `composeWordPattern` function does character-by-character lookup in the provided alphabet map. Arabic word files must ensure that characters like `أ` (hamza on alif) and `ى` (alif maqsura) map to the `ا` pattern. This normalization stays in `morse_arabic_words.dart` as a character-mapping step before calling `composeWordPattern`, or the Arabic alphabet map includes these variant entries.

**Rationale**: Keeps the composition function simple (pure lookup + join). Arabic-specific character normalization is an Arabic data concern, not a general composition concern.

### 4. Runtime `final` instead of compile-time `const`

**Decision**: `morseWords` and `morseArabicWords` change from `const` to top-level `final` (lazy-initialized on first access).

**Rationale**: Dart cannot call functions in `const` contexts. The performance difference is negligible — the maps are small (20 entries each) and computed once. No downstream code depends on the `const`-ness of these maps.

### 5. Word list stays `const`

**Decision**: `morseWordsList` and `morseArabicWordsList` remain `const List<String>` — they are just string lists with no computed content.

**Rationale**: The word ordering is a design decision, not derived from data. Keeping them `const` communicates this intent.

## Risks / Trade-offs

**[Risk] Arabic character variants may not be in the alphabet map** → Mitigation: Add `أ` and `ى` as alias entries in the Arabic alphabet map, or add a normalization map in `morse_arabic_words.dart`. The spec will define the expected behavior.

**[Risk] Losing `const` on word maps** → Mitigation: No consumer relies on `const`-ness. The `Level` class constructor accepts `Map<String, List<MorseSymbol>>` (not `const Map`). Verified no code uses `identical()` or compile-time equality on these maps.

**[Trade-off] Slightly slower first access** → Acceptable: 20 map entries computed once. Sub-millisecond, undetectable by users.
