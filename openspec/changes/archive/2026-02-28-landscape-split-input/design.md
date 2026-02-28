## Context

Feel You is a Morse code learning app for deaf-blind users. Input is entirely touch-based; output is entirely vibration-based. The screen is solid black with no visual elements.

Currently, dots and dashes are distinguished by **tap duration**: a short tap (< 150ms) = dot, a medium press (150-500ms) = dash. This requires the user to internalize precise timing — a significant cognitive load for someone who cannot see or hear any feedback during the press itself (vibration only comes after the gesture is classified).

The app currently allows any screen orientation. The `GestureClassifier` receives `TouchDown`/`TouchUp` events with timestamps and x-positions, and classifies them based on press duration.

## Goals / Non-Goals

**Goals:**
- Replace duration-based dot/dash classification with position-based: left half = dot, right half = dash
- Lock the app to landscape orientation to provide a wide, balanced two-handed input surface
- Simplify the gesture classifier by removing dot/dash timing thresholds
- Maintain all existing non-Morse gestures (swipe, reset, silence timeout) unchanged

**Non-Goals:**
- Adding any visual UI elements or indicators
- Supporting both input modes simultaneously
- Changing the teaching loop, vibration engine, or session management
- Changing the dead zone behavior (taps between dash-max and reset-min are no longer relevant for dot/dash, but the dead zone concept doesn't apply to position-based input)

## Decisions

### 1. Position-based classification uses screen width midpoint

**Decision**: The classifier determines dot vs dash by comparing the touch x-position against `screenWidth / 2`. Left of midpoint = dot, right of midpoint = dash. A tap exactly at the midpoint is classified as a dash (right side inclusive).

**Rationale**: The midpoint is the simplest possible boundary — no configuration needed, no edge cases. In landscape mode, each half is wide enough for comfortable one-handed tapping.

**Alternative considered**: Configurable split ratio (e.g., 40/60). Rejected — adds complexity with no clear benefit. The user can't see the boundary anyway, so ergonomics matter more than visual balance. The natural resting position of two hands on a landscape phone naturally falls near the midpoint.

### 2. Screen width is passed to the classifier, not queried internally

**Decision**: The `GestureClassifier` receives `screenWidth` as a constructor parameter. The `TouchSurface` widget provides the screen width from `MediaQuery` when creating or configuring the classifier.

**Rationale**: Keeps the classifier testable without widget dependencies. The classifier remains a pure Dart class with no Flutter imports. Tests can inject any screen width.

**Alternative considered**: Having the classifier access screen dimensions via a Flutter binding. Rejected — couples the classifier to Flutter, making unit tests harder.

### 3. Tap duration no longer determines dot vs dash

**Decision**: Remove `dotMaxDuration` and `dashMaxDuration` from `GestureTimingConfig`. Any non-swipe, non-reset tap is classified as dot or dash based purely on position. The dead zone between dash-max and reset-min disappears for Morse input — all taps shorter than reset threshold are classified by position.

**Rationale**: Duration-based classification is the core thing being replaced. Keeping the old thresholds around would be confusing and suggests a fallback that doesn't exist.

**Impact on dead zone**: Previously, taps between 500ms and 2000ms were ignored (dead zone). With position-based input, any tap shorter than the reset threshold (2000ms) that isn't a swipe will be classified as dot or dash by position. This is intentionally more forgiving — there's no reason to reject a 600ms tap when position alone determines the symbol.

### 4. Landscape lock at three levels

**Decision**: Lock to landscape at all three levels:
1. **Flutter level**: `SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight])` in `main()`.
2. **iOS level**: Remove portrait orientations from `Info.plist` `UISupportedInterfaceOrientations`.
3. **Android level**: Add `android:screenOrientation="sensorLandscape"` to `AndroidManifest.xml`.

**Rationale**: Triple-locking ensures the orientation is enforced regardless of OS-level overrides or Flutter edge cases. Each platform has its own mechanism and they don't always respect each other.

**Alternative considered**: Flutter-level only. Rejected — on some Android devices, the system can override Flutter's preference. Platform-level config is more reliable.

### 5. Swipe detection remains unchanged

**Decision**: Swipe gestures continue to work exactly as before — horizontal movement above distance and velocity thresholds triggers navigation. Swipes are checked before position-based classification, so a swipe always takes priority over a dot/dash input.

**Rationale**: Swipes use displacement (dx) between down and up positions. They are orthogonal to the position-based dot/dash system and don't conflict.

## Risks / Trade-offs

- **[Risk] User initially doesn't know which side is which** → The teaching loop already vibrates the expected pattern first, so the user will quickly learn through trial and error. The error vibration (long buzz) provides immediate feedback. Mitigation: the teaching loop naturally teaches the spatial mapping.

- **[Risk] Tap near the midpoint is ambiguous** → The boundary is deterministic (< midpoint = dot, >= midpoint = dash). There's no fuzzy zone. Users will naturally develop a feel for their phone's center. No mitigation needed beyond the deterministic rule.

- **[Risk] Landscape lock may frustrate initial setup** → The app launches directly into learning mode with no setup screen. The user (or their assistant) just needs to hold the phone sideways. Acceptable trade-off for the improved input ergonomics.

- **[Trade-off] Removing the dead zone means more taps are classified** → Previously, taps in the 500-2000ms range were ignored. Now all non-swipe, non-reset taps produce input. This is actually a benefit — fewer "lost" inputs — but it means accidental long taps will now register. Acceptable because the teaching loop handles wrong inputs gracefully.
