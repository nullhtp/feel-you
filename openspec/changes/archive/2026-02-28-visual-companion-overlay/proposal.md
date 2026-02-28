## Why

The app's entirely black screen makes it impossible for sighted companions (caretakers, friends, teachers) to understand what is happening during a learning session. A visual overlay showing input zones, the current symbol/word being taught, and session state would let a sighted person follow along and assist the deaf-blind user without interfering with the touch/vibration experience.

## What Changes

- Add an always-visible visual overlay to the `TouchSurface` screen showing:
  - **Zone boundaries**: thin white divider lines separating the left (dot), right (dash), and bottom (submit) input zones
  - **Zone labels**: "DOT", "DASH", and "SUBMIT" text in their respective zones
  - **Current symbol/word**: large, bold, high-contrast white text centered on screen (e.g., "A", "7", "HELLO")
  - **Morse pattern**: dot/dash notation below the current symbol (e.g., "· —" for A)
  - **Level indicator**: current level name displayed top-left (e.g., "LETTERS")
  - **Position progress**: current position within the level displayed top-right (e.g., "3/26")
  - **Input buffer**: accumulated user input (dots/dashes) displayed above the bottom submit zone
  - **Phase indicator**: current session phase (PLAYING / LISTENING / FEEDBACK) displayed top-center
- The overlay is purely visual — it does not affect touch handling, vibration output, or any existing functionality
- No new gestures or interactions are added

## Non-goals

- Toggling the overlay on/off (always visible since it doesn't affect the deaf-blind user's experience)
- Visual tap feedback (flashes, animations on touch)
- Sound or audio feedback
- Persisting any overlay settings
- Changing the existing gesture system or teaching loop behavior

## Capabilities

### New Capabilities
- `companion-overlay`: Visual overlay layer on the touch surface showing zone boundaries, zone labels, current symbol/word, morse pattern, level, progress, input buffer, and phase — for sighted companions to follow the learning session

### Modified Capabilities
- `touch-surface`: The touch surface widget needs to render the overlay widgets on top of the existing black `SizedBox.expand()`, while preserving all existing touch handling behavior

## Impact

- **Code**: `app/lib/ui/touch_surface.dart` — primary modification target; will need to read session state, level data, and input buffer to render overlay
- **State access**: The overlay needs to observe `sessionProvider`, level/position data from the session notifier, and the gesture input buffer — all already available via Riverpod providers
- **Dependencies**: No new packages required — Flutter's built-in `Text`, `Container`, `Positioned` widgets suffice
- **Performance**: Minimal — static text overlay with infrequent updates (on input, phase change, or navigation)
- **Testing**: Existing integration tests should continue to pass; new widget tests needed for overlay rendering
