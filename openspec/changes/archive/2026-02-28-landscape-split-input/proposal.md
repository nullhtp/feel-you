## Why

The current input model distinguishes dots from dashes by tap duration (short tap = dot, long press = dash). This requires precise timing from users who cannot see or hear — a significant cognitive and motor burden. Switching to a spatial model (left half = dot, right half = dash) makes input faster, less error-prone, and more intuitive: the user just needs to know *where* to tap, not *how long* to hold. Locking to landscape orientation provides a wider, more balanced split surface for two-handed input.

## What Changes

- **BREAKING**: Lock the app to landscape orientation only (both landscape-left and landscape-right). Portrait mode will no longer be supported.
- **BREAKING**: Replace duration-based dot/dash classification with position-based classification. Any tap on the left half of the screen produces a dot; any tap on the right half produces a dash. Tap duration no longer determines dot vs dash.
- Remove dot/dash timing thresholds (`dotMaxDuration`, `dashMaxDuration`) from gesture configuration since they are no longer needed for Morse input classification.
- Retain swipe gestures (navigation), long-hold (reset), silence timeout (input complete), and dead zone behavior unchanged.
- The split screen has no visual divider, no labels — the surface remains completely black and clean.

## Non-goals

- Adding any visual UI elements, dividers, or labels to the split surface.
- Changing swipe, reset, or input-complete behavior.
- Supporting both input modes (old duration-based and new position-based) simultaneously.
- Changing the teaching loop, vibration engine, or session management logic.

## Capabilities

### New Capabilities
- `landscape-orientation`: Lock the app to landscape-only orientation on both iOS and Android.
- `split-input`: Position-based Morse input — left half = dot, right half = dash — replacing duration-based classification.

### Modified Capabilities
- `gesture-recognition`: Dot/dash classification changes from duration-based to position-based. Timing thresholds for dot/dash are removed. The classifier now receives and uses the x-position of the touch relative to screen width to determine dot vs dash.
- `touch-surface`: Touch events must include screen width context so the classifier can determine which half was tapped.

## Impact

- **Gesture classifier** (`lib/gestures/gesture_classifier.dart`): Core classification logic rewritten — dot/dash determined by x-position vs screen midpoint instead of press duration.
- **Gesture timing config** (`lib/gestures/gesture_timing_config.dart`): `dotMaxDuration` and `dashMaxDuration` removed; screen-width dependency added.
- **Touch surface** (`lib/ui/touch_surface.dart`): Must pass screen width to the classifier so position-based classification can work.
- **iOS config** (`ios/Runner/Info.plist`): Remove portrait orientations from supported list.
- **Android config** (`android/app/src/main/AndroidManifest.xml`): Add `android:screenOrientation="sensorLandscape"` to the activity.
- **Flutter main** (`lib/main.dart`): Add `SystemChrome.setPreferredOrientations` for landscape-only as a Flutter-level enforcement.
- **Tests**: All gesture classification tests for dot/dash need rewriting to use position instead of duration.
