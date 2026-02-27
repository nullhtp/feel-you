## 1. Dependencies & Setup

- [x] 1.1 Add `wakelock_plus` dependency to `app/pubspec.yaml` and run `flutter pub get`
- [x] 1.2 Create `app/lib/ui/` directory for UI layer files

## 2. TouchSurface Widget

- [x] 2.1 Create `app/lib/ui/touch_surface.dart` with a `ConsumerStatefulWidget` that renders a full-screen solid black `Container` inside a `Listener` widget to capture all pointer events
- [x] 2.2 Implement `onPointerDown` handler: convert `PointerDownEvent` to `TouchDown(timestamp, x-position)` and call `gestureClassifier.handleTouch`
- [x] 2.3 Implement `onPointerUp` handler: convert `PointerUpEvent` to `TouchUp(timestamp, x-position)` and call `gestureClassifier.handleTouch`
- [x] 2.4 Wrap the widget tree in `PopScope(canPop: false)` to prevent back-navigation exits

## 3. Lifecycle Management

- [x] 3.1 In `initState`, enable wakelock via `WakelockPlus.enable()` and schedule a post-frame callback to call `ref.read(teachingOrchestratorProvider.notifier).start()`
- [x] 3.2 In `dispose`, disable wakelock via `WakelockPlus.disable()` and call `ref.read(teachingOrchestratorProvider.notifier).stop()`

## 4. App Integration

- [x] 4.1 Update `app/lib/app.dart` to use `TouchSurface` as the `home` widget, replacing the placeholder `Scaffold`

## 5. Tests

- [x] 5.1 Write widget test: verify `TouchSurface` renders a full-screen black container
- [x] 5.2 Write widget test: verify pointer down/up events are forwarded to `GestureClassifier.handleTouch` as `TouchDown`/`TouchUp` with correct timestamp and x-position
- [x] 5.3 Write widget test: verify `PopScope` prevents back navigation (canPop is false)
- [x] 5.4 Write widget test: verify teaching orchestrator `start()` is called on mount and `stop()` is called on dispose
- [x] 5.5 Run `flutter test` from `app/` and verify all existing and new tests pass
