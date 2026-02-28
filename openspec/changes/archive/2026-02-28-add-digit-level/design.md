## Context

The app currently teaches Morse code for the 26 letters A-Z. The user navigates with swipe left/right and resets with long tap. There is no concept of "levels" — the session state holds a single `letterIndex` into a flat `morseLetters` list.

To teach digits (0-9), we need a level abstraction that groups characters into sets, lets the user switch between sets, and keeps the existing within-level navigation intact. The architecture should be expandable for future character sets (punctuation, etc.) without structural changes.

The user is deaf-blind. All interactions are touch gestures in, vibration patterns out. No visual or audio feedback exists or can be added.

## Goals / Non-Goals

**Goals:**
- Introduce a `Level` abstraction that represents an ordered set of learnable characters with their Morse patterns.
- Add digits 0-9 as a new level, ordered before letters in the level sequence.
- Add vertical swipe gestures (up/down) for switching between levels.
- Add phone shake detection as a "home" gesture that resets to digits level, position 0.
- Keep long tap scoped to resetting within the current level only.
- App starts on the digits level at position 0.

**Non-Goals:**
- Persisting level progress or position across restarts.
- Dynamic level ordering or user-configurable level sequences.
- Adding punctuation or other character sets (future change).
- Visual level indicators (the user cannot see).

## Decisions

### 1. Level data model: Static registry of ordered Level objects

**Decision:** Define a `Level` class containing a name, an ordered list of characters, and a map of characters to Morse patterns. A top-level `levels` list provides the ordered sequence. Digits come first (index 0), letters second (index 1).

**Rationale:** This keeps the level system simple and data-driven. Adding a new level later is just adding an entry to the list. No inheritance, no interfaces — just data.

**Alternative considered:** Enum-based levels with switch statements. Rejected because it doesn't scale and requires code changes in multiple places to add a level.

### 2. Session state: Replace letterIndex with levelIndex + positionIndex

**Decision:** `SessionState` gains a `levelIndex` field (int, default 0 = digits). The existing `letterIndex` is renamed to `positionIndex` to reflect it indexes into whichever level is active. A `currentCharacter` getter replaces `currentLetter`, reading from `levels[levelIndex].characters[positionIndex]`.

**Rationale:** Minimal state expansion. Two integers fully describe where the user is. The level system resolves what character and pattern that means.

**Alternative considered:** Store the level name as a string. Rejected — index-based is simpler, matches existing pattern, and avoids string lookups.

### 3. Vertical swipe detection: Reuse existing swipe logic with axis discrimination

**Decision:** Extend `GestureClassifier` to detect vertical swipes using the same distance/velocity thresholds as horizontal swipes. On touch-up, compute both horizontal and vertical displacement. The axis with the larger absolute displacement wins. This prevents diagonal ambiguity.

**Rationale:** Reuses existing threshold config. Dominant-axis selection is a standard gesture disambiguation technique. No new timing parameters needed.

**Alternative considered:** Separate vertical swipe thresholds. Rejected for now — same thresholds are reasonable and simpler.

### 4. Shake detection: Use sensors_plus accelerometer, classify in a dedicated ShakeDetector

**Decision:** Add `sensors_plus` package dependency. Create a `ShakeDetector` class that subscribes to the accelerometer stream, computes magnitude, and emits a `Home` gesture event when a shake is detected (magnitude exceeds threshold, with cooldown to prevent repeats). The `ShakeDetector` is a separate class from `GestureClassifier` — it has its own stream but emits the same `GestureEvent` type.

**Rationale:** Shake is fundamentally different from touch gestures — it comes from a different sensor. Keeping it in a separate detector avoids polluting the touch classifier with accelerometer logic. The teaching orchestrator can merge both streams.

**Alternative considered:** Integrate shake detection into `GestureClassifier`. Rejected because it mixes two unrelated input sources and complicates testing.

### 5. Gesture event stream merging: Orchestrator merges touch + shake streams

**Decision:** The `TeachingOrchestrator` subscribes to both the `GestureClassifier.events` stream and the `ShakeDetector.events` stream. Both emit `GestureEvent` subtypes. The orchestrator handles them identically.

**Rationale:** Simple merge at the consumer level. No need for a combined gesture provider. Each detector remains independently testable.

### 6. New gesture events: NavigateUp, NavigateDown, Home

**Decision:** Add three new `GestureEvent` subtypes:
- `NavigateUp` — vertical swipe up, moves to next level
- `NavigateDown` — vertical swipe down, moves to previous level
- `Home` — shake detected, resets to level 0 position 0

**Rationale:** These map directly to the three new user intents. Keeping them as distinct event types allows the orchestrator to handle each case explicitly.

### 7. Level switching always starts at position 0

**Decision:** When switching levels (up/down/home), the `positionIndex` resets to 0 for the target level. No position memory across levels.

**Rationale:** User requested this explicitly. Simpler state management — no need to store per-level positions.

### 8. Morse digit data: Extend existing morse_alphabet.dart

**Decision:** Add digit patterns to a new `morseDigits` map and `morseDigitsList` ordered list in a new `morse_digits.dart` file. The `Level` objects reference these data sources. `morse_utils.dart` encode/decode must cover both letters and digits.

**Rationale:** Keeps data files focused. Letters and digits have separate ordered lists since they belong to different levels.

## Risks / Trade-offs

- **[Risk] Accelerometer availability** — Some devices may not have accelerometers, or the `sensors_plus` package may have platform issues. → Mitigation: Make `ShakeDetector` fail gracefully (no-op if sensor unavailable). Home gesture is a convenience, not the only way to navigate.

- **[Risk] Vertical/horizontal swipe disambiguation** — Diagonal swipes could trigger unexpected level switches. → Mitigation: Dominant-axis selection (larger displacement wins) plus existing distance/velocity thresholds filter out small or slow gestures.

- **[Risk] Shake false positives** — Walking or bumping the phone could trigger home. → Mitigation: Require a high magnitude threshold and cooldown period. Tunable via config.

- **[Trade-off] No position memory across levels** — User always starts at 0 when switching. This is simpler but could be inconvenient if switching frequently. → Accepted per user requirement.

- **[Trade-off] sensors_plus dependency** — Adds a native dependency that increases binary size and platform surface area. → Acceptable for the value shake gesture provides.
