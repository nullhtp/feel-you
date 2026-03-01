## Context

The Morse domain layer (`app/lib/morse/`) has 11 files serving as the pure-data core for the Feel You app. It provides Morse code encoding/decoding for English and Arabic, plus a level system for learning progression. The layer works but has accumulated structural debt:

- `MorseSymbol` mixes user-facing signals (dot/dash) with structural separators (charGap), forcing 3-case handling everywhere when only 2 are user-facing.
- `morse_utils.dart` is a 116-line grab-bag of 7 unrelated functions tightly coupled to all alphabet imports.
- Encode/decode APIs are asymmetric — `encodeLetter` tries all languages blindly, while decoding has two variants with different signatures.
- Adding a language requires modifying 5+ files. No extension point exists.
- The `Level` class uses only `name` for equality, and the global `levels` list is mutable.

Current file count: 11 Morse files + 3 vibration-related files + 5 consumer files + 10 test files.

## Goals / Non-Goals

**Goals:**
- Separate signal atoms (dot/dash) from word-structure tokens (charGap) into distinct types
- Create a registry-based alphabet system where adding a language means adding one file
- Provide symmetric, language-aware encode/decode API
- Split utilities into focused, single-responsibility modules
- Integrate levels into the alphabet registry for cohesive language definitions
- Fix Level equality and levels list mutability
- Update all consumers and tests for consistency

**Non-Goals:**
- Adding new languages (Russian, etc.) — we enable it but don't do it
- Changing vibration engine, gesture recognition, or teaching loop behavior
- Adding persistence, new UI screens, or changing the learning flow
- Performance optimization — current data sizes are tiny (< 100 entries per alphabet)

## Decisions

### 1. MorseSignal enum + sealed MorseToken class

**Decision:** Replace `MorseSymbol` with two types:
- `MorseSignal` enum with `dot` and `dash` — used everywhere a user-facing signal is needed (gesture input, single-character patterns, input buffers)
- `MorseToken` sealed class with `Signal(MorseSignal)` and `CharGap()` subtypes — used only in word-level patterns where structural separators are needed

**Rationale:** The current `MorseSymbol` forces every consumer to handle `charGap` even when it's irrelevant (gesture classifier, single-letter encode/decode, vibration of single characters). A sealed class gives exhaustive switch coverage while making the type system enforce the distinction.

**Alternatives considered:**
- *Nested lists (`List<List<MorseSignal>>`) for words*: Simpler but loses the flat-pattern representation needed by the vibration engine, which expects a single sequential list of durations. Would require flattening logic at every vibration call site.
- *Keep charGap with documentation*: Minimal disruption but doesn't fix the root problem — consumers still need dead branches for charGap handling.

### 2. Split morse_utils.dart into three focused modules

**Decision:** Replace `morse_utils.dart` with:
- `morse_encoder.dart` — `encodeLetter(String, MorseLanguage)` and `decodePattern(List<MorseSignal>, MorseLanguage)`, both using the registry
- `morse_pattern.dart` — `patternsEqual()`, `isValidPattern()` — pure comparison/validation utilities
- `morse_word_builder.dart` — `composeWordPattern()`, `buildWordPatterns()` — word composition utilities

**Rationale:** Each file has a single responsibility. The encoder depends on the registry; the pattern utils are pure functions with no alphabet dependency; the word builder takes an alphabet map as a parameter (no import coupling).

**Alternatives considered:**
- *Single MorseCodec class*: Object-oriented approach wrapping encode/decode. Adds unnecessary ceremony for what are fundamentally pure functions. Dart idiom favors top-level functions for stateless operations.
- *Keep as one file*: Smallest change but leaves the SRP violation and tight coupling intact.

### 3. MorseAlphabet class + MorseAlphabetRegistry

**Decision:** Introduce:
```dart
class MorseAlphabet {
  final MorseLanguage? language;  // null = universal (digits)
  final Map<String, List<MorseSignal>> characters;
  final List<String> characterOrder;
  final List<String>? wordList;
  final Map<String, List<MorseToken>>? wordPatterns;
  final List<Level> levels;  // levels defined by this alphabet
}
```

A top-level `MorseAlphabetRegistry` holds all registered alphabets and provides lookup methods:
```dart
class MorseAlphabetRegistry {
  List<MorseAlphabet> get all;
  MorseAlphabet? forLanguage(MorseLanguage language);
  MorseAlphabet get universal;  // digits
  List<Level> levelsForLanguage(MorseLanguage language);
  // encode/decode delegate to registered alphabets
}
```

Each language defines its alphabet data in one file (`english_alphabet.dart`, `arabic_alphabet.dart`, `digit_alphabet.dart`) and registers it.

**Rationale:** Open/Closed Principle — adding a language means adding one data file that constructs a `MorseAlphabet` and registering it. No existing files need modification. The registry also owns the `levelsForLanguage()` logic, keeping level resolution cohesive with alphabet data.

**Alternatives considered:**
- *Convention-based without registry*: Standardize file naming but keep the current import-everything pattern. Doesn't solve the coupling problem — `morse_encoder.dart` would still need to import every alphabet file.
- *Keep current scattered maps*: Minimal change but adding a language still requires touching 5+ files.

### 4. Symmetric language-aware encode/decode

**Decision:** Both functions require a `MorseLanguage` parameter:
```dart
List<MorseSignal>? encodeLetter(String letter, MorseLanguage language);
String? decodePattern(List<MorseSignal> pattern, MorseLanguage language);
```

Both use the registry internally: look up the alphabet for the given language, plus always include the universal (digits) alphabet.

**Rationale:** Eliminates ambiguity. The current `encodeLetter` silently tries Arabic if English fails, which could produce surprising results. With explicit language, the API is predictable and the caller knows exactly which alphabet is being used.

**Alternatives considered:**
- *Both try all languages*: Simple but ambiguous when patterns overlap (English 'A' and Arabic 'ا' share `[dot, dash]`).
- *Auto-detect with optional override*: Flexible but the "auto" path is a footgun for the same overlap reason.

### 5. Levels integrated into MorseAlphabet

**Decision:** Each `MorseAlphabet` defines its own levels as part of its data. The registry aggregates them via `levelsForLanguage()` which returns universal levels + language-specific levels in order.

`Level` equality updated to use all fields (`name`, `characters`, `patterns`, `language`). The aggregated list is returned as `List.unmodifiable()`.

**Rationale:** Levels are inherently tied to alphabet data — a "letters" level is meaningless without its alphabet. Co-locating them makes each language self-contained and eliminates the need for a separate `levels.dart` that imports every alphabet.

### 6. Barrel export updated

**Decision:** `morse.dart` barrel export updated to re-export the new modules. Consumers continue importing `package:feel_you/morse/morse.dart` — the barrel hides the internal restructure.

**Rationale:** Minimizes import churn across the codebase. Consumers don't need to know about the internal file reorganization.

### 7. Consumer migration approach

**Decision:** Update all consumers in-place during this refactor rather than providing backward-compatible wrappers.

Migration points:
- **Gestures**: `MorseSymbol` → `MorseSignal` in `MorseInput`, `InputComplete`, input buffer, and classifier
- **Vibration**: `buildMorseVibrationPattern` gains two overloads — one for `List<MorseSignal>` (single characters) and one for `List<MorseToken>` (words)
- **Session**: Use registry's `levelsForLanguage()` instead of the standalone function
- **Teaching**: Use `patternsEqual` from `morse_pattern.dart`, pattern lookups from level data
- **UI language picker**: Use registry to look up identifier patterns instead of hardcoding `[dot]` and `[dot, dash, dot, dash]`

## Risks / Trade-offs

**[Risk] Large blast radius across many files** → Mitigated by the barrel export pattern — most consumers only need type renames (`MorseSymbol` → `MorseSignal`), not import path changes. Tests verify correctness after migration.

**[Risk] Sealed class overhead for MorseToken** → The sealed class adds one level of wrapping compared to a flat enum. This is negligible for the data sizes involved (word patterns are < 50 tokens). The type safety benefit outweighs the minimal overhead.

**[Risk] Registry pattern adds indirection** → The registry is a simple list with lookup methods, not a service locator or DI container. It's initialized at module load time with const data. The indirection cost is one function call, and the extensibility benefit is significant.

**[Trade-off] Breaking all existing tests** → Every Morse test file needs updating. This is acceptable because: (a) the tests are well-structured and the changes are mechanical type renames, (b) updating tests alongside code ensures nothing falls through the cracks, (c) the new structure makes tests easier to write going forward.

**[Trade-off] Cannot make word-level `MorseAlphabet` fields const** → Word patterns are computed at runtime via `buildWordPatterns`. The `MorseAlphabet` instances for words levels won't be `const`. This is the same trade-off as the current `levels` list and is acceptable.
