## Context

The app currently uses a full-screen black `Listener` widget that captures all touch events. Dot/dash classification is position-based (left half = dot, right half = dash). CharGap insertion happens automatically via a 400ms silence timer in the `GestureClassifier`, which is unreliable — the user has no explicit control over character boundaries within words.

The screen is locked to landscape orientation. The `GestureClassifier` receives `RawTouchEvent`s (with x and y positions) and classifies them into `GestureEvent`s emitted on a stream. The `TeachingOrchestrator` subscribes to this stream and manages the learning loop.

Three levels exist: digits (index 0), letters (index 1), words (index 2). The words level is the only one that uses `charGap` symbols in its patterns.

## Goals / Non-Goals

**Goals:**
- Give users explicit, tactile control over charGap insertion via a dedicated bottom input zone
- Make the bottom zone level-aware: charGap on words level, immediate InputComplete on other levels
- Provide haptic feedback on bottom zone tap for discoverability
- Remove automatic charGap timer (400ms) to eliminate ambiguity
- Keep the 1000ms silence timeout as a fallback submission mechanism

**Non-Goals:**
- No visual changes — screen stays fully black
- No changes to swipe gesture detection or navigation
- No changes to vibration patterns or teaching loop logic
- No changes to shake gesture handling

## Decisions

### 1. Zone detection in TouchSurface, not GestureClassifier

**Decision**: The `TouchSurface` widget determines whether a tap is in the bottom zone or the dot/dash zone based on Y position, then routes events differently.

**Rationale**: The `GestureClassifier` is a pure Dart class tested without a widget tree. Adding screen height awareness and level-aware routing there would couple it to session state and haptic feedback concerns. Instead, `TouchSurface` already has access to screen dimensions and Riverpod providers, making it the natural place for zone routing.

**Alternative considered**: Adding a `screenHeight` parameter to `GestureClassifier` and having it detect the zone internally. Rejected because the classifier would need session state access (to know the current level), which violates its current single-responsibility design.

### 2. New BottomZoneAction event type

**Decision**: Add a new `BottomZoneAction` sealed subtype to `GestureEvent`. The `TouchSurface` creates this event and sends it directly to the `GestureClassifier`'s event stream via a new `emitBottomZoneAction()` method.

**Rationale**: Using a dedicated event type keeps the gesture event stream as the single source of truth for all input events. The `TeachingOrchestrator` can then handle it alongside existing events without special-casing.

**Alternative considered**: Having `TouchSurface` directly call `insertCharGap()` / `submitInput()` on the classifier. Rejected because it bypasses the event stream and creates a parallel control flow that the orchestrator can't observe.

### 3. Level-aware behavior resolved in TeachingOrchestrator

**Decision**: The `BottomZoneAction` event is level-agnostic — it just means "the user tapped the bottom zone." The `TeachingOrchestrator` checks the current level and decides whether to insert a charGap into the buffer or trigger InputComplete.

**Rationale**: The orchestrator already has access to session state and manages the teaching flow. Putting level-awareness there keeps the gesture layer level-agnostic and testable in isolation.

**Alternative considered**: Having `TouchSurface` emit different events based on level (charGap event vs submit event). Rejected because it spreads level-dependent logic across multiple layers.

### 4. Bottom zone height: 15% of screen height

**Decision**: The bottom zone occupies the lower 15% of the screen (in landscape, this is ~15% of the shorter dimension). The boundary is calculated as `screenHeight * 0.85`.

**Rationale**: 15% provides a comfortable touch target (~50-60 logical pixels on typical phones in landscape) without significantly reducing the dot/dash input area.

### 5. Haptic feedback via short vibration pulse

**Decision**: Tapping the bottom zone triggers a short haptic pulse (single vibration of ~50ms) as confirmation feedback. This uses the existing `Vibration` package already in the project.

**Rationale**: Deaf-blind users rely entirely on haptic feedback. A distinct short pulse differentiates bottom-zone taps from dot/dash input (which does not produce haptic feedback) and gives immediate confirmation the tap was registered.

### 6. Swipe gestures work across the full screen

**Decision**: Swipe detection is not restricted to the dot/dash zone. Swipes starting in the bottom zone are still classified normally by the `GestureClassifier`.

**Rationale**: Restricting swipes to the upper area would create dead zones for navigation. Swipes are distinguished by distance/velocity, so there's no ambiguity with bottom-zone taps.

**Implementation**: `TouchSurface` only treats short taps in the bottom zone as bottom-zone actions. If the touch results in a swipe (detected on release by displacement/velocity), it's forwarded to the classifier normally.

### 7. Remove charGap auto-timer, keep silence timeout

**Decision**: Remove the `_charGapTimer` and `charGapThreshold` logic from `GestureClassifier._startSilenceTimer()`. Keep the `_silenceTimer` for `InputComplete` as a fallback. The `charGapThreshold` field stays in `GestureTimingConfig` but becomes unused (deprecated).

**Rationale**: With explicit charGap insertion, the auto-timer is no longer needed. Keeping silence timeout ensures input is eventually submitted even if the user forgets to tap the bottom zone.

## Risks / Trade-offs

- **[Discoverability]** New users may not know the bottom zone exists → Mitigation: The onboarding/teaching flow should introduce the zone when the user reaches the words level. Haptic feedback on tap helps users discover it through exploration.
- **[Accidental taps]** Users may accidentally tap the bottom zone while aiming for the dot/dash area → Mitigation: 15% height is small enough to minimize this. The zone boundary is at the very bottom edge where intentional taps are more likely than accidental ones.
- **[Swipe vs tap ambiguity in bottom zone]** A swipe starting from the bottom zone should still be a swipe, not a bottom-zone tap → Mitigation: Bottom-zone action only fires on short taps (non-swipe). The existing swipe detection in `GestureClassifier` handles the disambiguation naturally — if it's a swipe, the classifier emits a navigation event; if it's a tap, `TouchSurface` handles it as a bottom-zone action.
- **[Breaking change]** Removing auto charGap changes how word-level input works for existing users → Mitigation: Acceptable since the app is in early development. The explicit approach is more reliable and learnable.
