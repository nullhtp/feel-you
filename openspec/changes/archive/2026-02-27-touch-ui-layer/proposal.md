## Why

All the core logic is built — gesture classification, vibration playback, session state, and the teaching orchestrator — but there is no way for a real user to interact with them. The app still shows a blank placeholder `Scaffold`. This change creates the single full-screen touch surface that connects real finger events to the gesture classifier, making the learning loop actually usable on a device.

## What Changes

- Add a full-screen `GestureDetector` widget that captures all touch events (`onPanDown`, `onPanUpdate`, `onPanEnd`) and converts them into `RawTouchEvent` objects for the `GestureClassifier`
- Replace the placeholder `Scaffold` in `app.dart` with the new touch surface as the app's home screen
- Keep the screen on with a wakelock to prevent the display from sleeping during a learning session
- Intercept back navigation (Android back button / iOS swipe-to-go-back) to prevent accidental exits
- Render a solid black screen with no visual elements — the entire interaction is haptic
- Auto-start the teaching orchestrator when the screen mounts (no start button — gesture capture begins immediately)

## Non-goals

- No start button or onboarding flow — the app launches directly into learning mode
- No accessibility metadata or semantic labels — deferred to Change 4 (Integration & Polish)
- No visual feedback, animations, or text display — the user is deaf-blind
- No persistence or analytics — session state remains in-memory only

## Capabilities

### New Capabilities
- `touch-surface`: Full-screen widget that captures raw touch events and feeds them to the gesture classifier, manages wakelock and back-navigation interception, and auto-starts the teaching loop on mount

### Modified Capabilities

## Impact

- **`app/lib/app.dart`**: Replace placeholder `Scaffold` with the new touch surface widget
- **`app/lib/` (new files)**: New widget file(s) in a `ui/` directory
- **`pubspec.yaml`**: Add `wakelock_plus` (or similar) dependency for keeping the screen on
- **Existing providers**: No changes to existing providers — the widget consumes them read-only via `ref.read` / `ref.watch`
