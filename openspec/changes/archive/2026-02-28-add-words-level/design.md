## Context

The app currently teaches individual Morse characters across two levels: digits (0–9) and letters (A–Z). Users interact entirely through touch input and vibration output. The `Level` data model maps single-character string keys to `List<MorseSymbol>` patterns, where `MorseSymbol` is an enum with `dot` and `dash` values.

To add word-level practice, the system must represent multi-character patterns. The key challenge: a word's Morse pattern contains inter-character gaps that are longer than inter-symbol gaps but aren't dots or dashes. The current `MorseSymbol` enum has no way to represent this.

## Goals / Non-Goals

**Goals:**
- Add a `charGap` value to `MorseSymbol` to represent inter-character silence within a word
- Create a flat Morse pattern for each of 20 common English words (2–5 letters, sorted by length then frequency)
- Register a "words" level at index 2, navigable via the existing swipe-up/swipe-down gestures
- Handle `charGap` correctly in vibration output (longer silence) and input evaluation (recognizing the gap in user taps)

**Non-Goals:**
- Word-gap (inter-word) support for sentences
- Any visual or audio UI
- Custom word lists or word selection
- Spaced repetition or progression logic

## Decisions

### Decision 1: Add `charGap` to `MorseSymbol` enum

**Choice:** Extend `MorseSymbol` with a third value `charGap`.

**Rationale:** This is the minimal change that lets word patterns be represented as a flat `List<MorseSymbol>`. The existing `Level.patterns` type (`Map<String, List<MorseSymbol>>`) stays the same — word entries just use multi-character string keys (e.g., `"THE"`) mapped to patterns like `[dash, charGap, dot, dot, dot, dot, charGap, dot]`.

**Alternative considered:** Using `List<List<MorseSymbol>>` (nested per-letter patterns). Rejected because it would require changing the `Level` data model, the `VibrationService.playMorsePattern` signature, `patternsEqual`, and the teaching orchestrator's evaluation logic — far more invasive for the same result.

**Alternative considered:** Separate "word level" class. Rejected because the `Level` class is already generic enough — the only missing piece is the gap symbol.

### Decision 2: Timing for `charGap`

**Choice:** Add `interCharGap` to `MorseTimingConfig` with a default of 300ms (3× dot duration, per ITU standard Morse timing).

**Rationale:** Standard Morse inter-character gap is 3 dot-lengths. With a 100ms dot, that's 300ms. This is distinct from the inter-symbol gap (100ms) and clearly separable during both playback and input.

### Decision 3: Input recognition of `charGap`

**Choice:** Classify silence duration between taps to distinguish inter-symbol gaps from inter-character gaps. The gesture classifier already has a `silenceTimeout` (1000ms) for input-complete. Add a `charGapThreshold` (e.g., 400ms) — silence shorter than this is an inter-symbol gap, silence between `charGapThreshold` and `silenceTimeout` is a `charGap`, and silence beyond `silenceTimeout` is input-complete.

**Rationale:** The user needs a way to "type" a character gap when tapping back a word. A timing-based threshold is the only option since input is purely touch-based. The 400ms threshold gives a comfortable margin above the 300ms playback gap.

**Risk:** Users may struggle to consistently produce the right silence duration. Mitigation: the threshold is configurable via `GestureTimingConfig`, and users can practice the timing since the app repeats the pattern indefinitely.

### Decision 4: Word selection — 20 words, 2–5 letters, sorted by length then frequency

**Choice:** Curate 20 words from the most frequent English words, filtered to 2–5 letters, sorted first by length (shortest first) then by usage frequency within each length group.

Proposed word list:
1. **2-letter:** IT, IS, TO, IN, AT
2. **3-letter:** THE, AND, FOR, ARE, BUT
3. **4-letter:** THAT, WITH, HAVE, THIS, FROM
4. **5-letter:** THEIR, ABOUT, WHICH, WOULD, THERE

**Rationale:** Starts with the easiest (shortest) words and progresses. High-frequency words maximize real-world utility.

### Decision 5: Level position — index 2

**Choice:** Place "words" at index 2 in the `levels` list, after digits (0) and letters (1).

**Rationale:** Natural progression — learn characters first, then combine them. Swipe-up from letters reaches words.

## Risks / Trade-offs

- **[charGap timing is hard for users]** → Mitigation: The app plays the word pattern repeatedly, so users hear the timing before attempting. The `charGapThreshold` is tunable. Future improvement: adaptive thresholds based on user behavior.
- **[Adding `charGap` to `MorseSymbol` affects switch expressions]** → Mitigation: Dart's exhaustive switch will catch all sites at compile time. Only `buildMorseVibrationPattern` and `patternsEqual` need updates — both are small, well-tested functions.
- **[`patternsEqual` uses `listEquals` which handles `charGap` automatically]** → No special handling needed since `MorseSymbol.charGap` is just another enum value. The comparison works as-is.
- **[Gesture classifier complexity increases]** → The `InputComplete` event currently fires after `silenceTimeout`. Now it needs to emit `charGap` symbols during the input sequence. This is a moderate change to `GestureClassifier` state management.
