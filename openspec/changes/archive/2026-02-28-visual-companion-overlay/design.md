## Context

The Feel You app currently renders a completely black screen — intentionally, since the target users are deaf-blind and interact purely via touch and vibration. However, sighted companions (caretakers, teachers, friends) have no way to see what is happening during a learning session. This makes it difficult to assist or observe the deaf-blind user's progress.

The proposal introduces an always-visible visual overlay that shows zone boundaries, labels, the current symbol/word, morse pattern, level, progress, input buffer, and session phase — all rendered on top of the existing black touch surface without affecting touch handling or vibration behavior.

## Goals / Non-Goals

**Goals:**
- Render a visual overlay on the `TouchSurface` that displays all session-relevant information for sighted observers
- Keep the overlay purely read-only: it observes state but never modifies it
- Preserve all existing touch handling — the `Listener` widget must remain the topmost hit-test target
- Expose the gesture classifier's input buffer as observable state so the overlay can display accumulated dots/dashes
- Keep the overlay lightweight with minimal redraws

**Non-Goals:**
- Toggle mechanism for the overlay (always visible)
- Visual tap feedback (no flash/animation on touch events)
- Audio feedback
- Any changes to the gesture system, teaching loop, or vibration engine
- Persisting overlay settings or preferences

## Decisions

### 1. Overlay architecture: Stack with IgnorePointer

**Decision:** Wrap the `Listener` and overlay in a `Stack`. The overlay widgets sit on top wrapped in `IgnorePointer` so all touches pass through to the underlying `Listener`.

**Rationale:** The `Listener` currently receives all pointer events via `HitTestBehavior.opaque`. By placing visual widgets above it in a `Stack` but wrapping them in `IgnorePointer`, we guarantee zero interference with touch handling. The alternative — placing visuals below the `Listener` — would require the `Listener`'s child to be transparent, which is more fragile.

**Alternatives considered:**
- `CustomPaint` on the `SizedBox.expand()` child: More complex, harder to maintain, mixes layout concerns
- Separate overlay route/page: Unnecessary complexity for a non-interactive visual layer

### 2. Exposing the input buffer: ValueNotifier on GestureClassifier

**Decision:** Add a `ValueNotifier<List<MorseSymbol>>` to `GestureClassifier` that emits an unmodifiable copy of the input buffer whenever it changes. The overlay watches this via a Riverpod provider.

**Rationale:** The input buffer is currently private (`_inputBuffer`) with no external visibility. Rather than making it public (breaking encapsulation) or adding a separate stream (heavyweight), a `ValueNotifier` is lightweight, synchronous, and integrates cleanly with Flutter's `ValueListenableBuilder` or Riverpod.

**Alternatives considered:**
- Exposing `_inputBuffer` directly: Breaks encapsulation, allows mutation
- Adding a `Stream<List<MorseSymbol>>`: Heavier than needed for synchronous state
- Separate `InputBufferNotifier` Riverpod provider: Over-engineering for a simple list

### 3. Widget decomposition: Single CompanionOverlay widget

**Decision:** Create a single `CompanionOverlay` widget in `app/lib/ui/companion_overlay.dart` that reads all necessary state via Riverpod and renders the full overlay layout using `Positioned` widgets in a `Stack`.

**Rationale:** All overlay elements share the same data dependencies (session state, level data, input buffer). A single widget avoids redundant provider watches and keeps the overlay self-contained. Internal decomposition into private helper methods keeps the build method readable.

**Alternatives considered:**
- Multiple small widgets (ZoneLabel, SymbolDisplay, etc.): More files and complexity for a read-only overlay
- Putting overlay code directly in `TouchSurface`: Bloats an already-complex widget

### 4. Layout approach: Positioned widgets with fractional offsets

**Decision:** Use `Positioned` widgets within the overlay's `Stack` to place elements at specific screen locations. Zone divider lines use `Container` with thin borders. Text uses Flutter's `Text` widget with explicit styles.

**Rationale:** The layout is fixed (landscape only, known zone proportions). Absolute positioning via `Positioned` is simple and predictable for this use case.

### 5. Text styling: Large bold center, smaller peripheral elements

**Decision:**
- Current symbol/word: White, bold, ~72sp (scaled down for longer words), centered on screen
- Morse pattern: White, ~24sp, centered below the symbol
- Zone labels ("DOT", "DASH", "SUBMIT"): White, ~16sp, 30% opacity, positioned in their zones
- Level, progress, phase: White, ~14sp, positioned at corners/top-center
- Input buffer: White, ~20sp, positioned above the bottom zone
- Zone dividers: White lines at 10% opacity

**Rationale:** The primary purpose is showing the current character prominently. Peripheral elements stay subdued to avoid visual clutter. High contrast (white on black) ensures readability in all lighting.

## Risks / Trade-offs

- **[Risk] Input buffer exposure adds public API surface to GestureClassifier** → Mitigated by using `ValueNotifier` (read-only external access). The internal `_inputBuffer` remains private.
- **[Risk] Overlay redraws on every input event** → Mitigated by `ValueListenableBuilder` / Riverpod `select()` which only rebuilds the specific text widget that changed, not the entire overlay.
- **[Risk] Long words overflow screen width** → Mitigated by scaling font size down for words (the longest word is "WOULD" at 5 chars — fits comfortably even at 48sp).
- **[Trade-off] Always-visible overlay means no "pure black" mode** → Accepted. The overlay does not affect touch/vibration, and deaf-blind users cannot see it. A toggle could be added later if needed.
- **[Trade-off] Input buffer `ValueNotifier` allocates a new list on each update** → Acceptable for the low frequency of input events (human typing speed).
