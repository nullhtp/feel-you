## 1. Landscape Orientation Lock

- [x] 1.1 Update `app/lib/main.dart` to call `SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight])` before `runApp`
- [x] 1.2 Update `app/ios/Runner/Info.plist` to remove portrait orientations from `UISupportedInterfaceOrientations` (keep only `UIInterfaceOrientationLandscapeLeft` and `UIInterfaceOrientationLandscapeRight` for both iPhone and iPad arrays)
- [x] 1.3 Update `app/android/app/src/main/AndroidManifest.xml` to add `android:screenOrientation="sensorLandscape"` to the main activity element

## 2. Gesture Timing Config Changes

- [x] 2.1 Remove `dotMaxDuration` and `dashMaxDuration` from `GestureTimingConfig` in `app/lib/gestures/gesture_timing_config.dart`
- [x] 2.2 Update all references to `dotMaxDuration` and `dashMaxDuration` across the codebase (classifier, tests, providers)

## 3. Gesture Classifier — Position-Based Classification

- [x] 3.1 Add `screenWidth` parameter to `GestureClassifier` constructor
- [x] 3.2 Rewrite `_onTouchUp` to classify dot/dash by x-position relative to `screenWidth / 2` instead of press duration. Any non-swipe tap shorter than `resetMinDuration` is classified by position (left half = dot, right half = dash, midpoint inclusive to dash)
- [x] 3.3 Remove dead zone logic — taps between old dash-max and reset-min should now be classified by position instead of ignored
- [x] 3.4 Update `GestureClassifier` Riverpod provider in `app/lib/gestures/gesture_providers.dart` to accept and pass `screenWidth`

## 4. Touch Surface — Provide Screen Width

- [x] 4.1 Update `TouchSurface` in `app/lib/ui/touch_surface.dart` to obtain screen width from `MediaQuery` and pass it to the `GestureClassifier` provider/constructor

## 5. Tests

- [x] 5.1 Update gesture classifier unit tests: replace all duration-based dot/dash test cases with position-based equivalents (left half = dot, right half = dash, midpoint = dash)
- [x] 5.2 Add test cases for previously-dead-zone taps (500-2000ms) now being classified by position
- [x] 5.3 Verify swipe detection still works correctly with position-based classification (swipe takes priority over dot/dash)
- [x] 5.4 Verify reset (long hold) behavior is unchanged
- [x] 5.5 Verify silence timeout and input buffer behavior is unchanged
- [x] 5.6 Run `flutter analyze` and `flutter test` from `app/` to confirm zero warnings and all tests pass
