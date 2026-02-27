## Context

The Feel You app has all core logic implemented: gesture classification (`GestureClassifier` consuming `RawTouchEvent` via `handleTouch`), vibration playback (`VibrationService`), session state (`SessionNotifier`), and the teaching orchestrator (`TeachingOrchestrator`) that wires them together. However, the app still renders a blank placeholder `Scaffold` — there is no widget translating real finger touches into `RawTouchEvent` objects.

The `GestureClassifier` was deliberately designed to accept `RawTouchEvent` (a sealed class with `TouchDown` and `TouchUp` subtypes carrying timestamp and x-position) rather than Flutter gesture objects directly. This means the UI layer's job is straightforward: capture raw pointer/pan events and convert them into `TouchDown`/`TouchUp` calls.

## Goals / Non-Goals

**Goals:**
- Create a single full-screen widget that captures all touch events and feeds them to the existing `GestureClassifier`
- Auto-start the `TeachingOrchestrator` when the widget mounts so learning begins immediately
- Prevent the screen from sleeping during a session (wakelock)
- Prevent accidental back-navigation exits (Android back button, iOS swipe-back)

**Non-Goals:**
- No visual UI elements, text, or animations
- No start button or onboarding screen
- No accessibility semantics (deferred to Change 4)
- No new state management — the widget only consumes existing providers

## Decisions

### 1. Use `Listener` widget instead of `GestureDetector`

**Decision**: Use Flutter's `Listener` widget (raw pointer events) rather than `GestureDetector`.

**Rationale**: `GestureDetector` uses gesture arena disambiguation which introduces delays and can swallow events when multiple recognizers compete. The `GestureClassifier` already handles all gesture classification — it needs raw touch-down and touch-up events with timestamps and positions. `Listener` provides `onPointerDown` and `onPointerUp` directly, with no arena delays. This avoids double-classification and gives us the lowest-latency path to the classifier.

**Alternatives considered**:
- `GestureDetector` with `onPanDown`/`onPanEnd`/`onPanUpdate`: Would add latency from gesture arena resolution and could miss events during disambiguation. The roadmap mentioned this approach, but raw `Listener` is a better fit since our classifier handles all gesture logic.
- `RawGestureRecognizer`: More control than `GestureDetector` but still involves the arena. Unnecessary complexity since `Listener` suffices.

### 2. Widget structure: single ConsumerStatefulWidget

**Decision**: Create a single `TouchSurface` widget as a `ConsumerStatefulWidget` in `app/lib/ui/touch_surface.dart`.

**Rationale**: The widget needs `initState` / `dispose` lifecycle for starting/stopping the orchestrator and managing wakelock. It needs `ref` access for reading providers. `ConsumerStatefulWidget` provides both.

**Alternatives considered**:
- `HookConsumerWidget` with flutter_hooks: Would reduce boilerplate but adds a new dependency for a single widget. Not worth it.
- Separate `ProviderScope` wrapper: No benefit since we only need to read existing providers, not override them.

### 3. Wakelock via `wakelock_plus` package

**Decision**: Add `wakelock_plus` dependency and enable wakelock in `initState`, disable in `dispose`.

**Rationale**: `wakelock_plus` is the actively maintained fork of the original `wakelock` package. It supports both iOS and Android with a simple `WakelockPlus.enable()` / `WakelockPlus.disable()` API. The user cannot see the screen, so if it sleeps they lose their session without knowing.

**Alternatives considered**:
- `keep_screen_on` package: Less popular, similar API. No significant advantage.
- Platform channels: Unnecessary when a well-maintained package exists.

### 4. Back-navigation interception via `PopScope`

**Decision**: Wrap the widget tree in Flutter's `PopScope` (replaces deprecated `WillPopScope`) with `canPop: false` to prevent all back navigation.

**Rationale**: This is the simplest approach. Since the app has only one screen and no navigation stack, preventing all pops is correct. The user exits by pressing the home button or switching apps, not by going "back."

**Alternatives considered**:
- `Navigator` with custom route: Overkill for a single-screen app.
- Platform-specific back button handling: `PopScope` already handles this cross-platform.

### 5. Timestamp source: use `Duration` from stopwatch

**Decision**: Create a `Stopwatch` in the widget, start it on mount, and use `stopwatch.elapsed` as the timestamp for `RawTouchEvent` objects.

**Rationale**: `GestureClassifier` expects `Duration` timestamps. Flutter's `PointerEvent.timeStamp` is a `Duration` since the process epoch, which is suitable. However, using a local `Stopwatch` ensures timestamps are monotonic and relative to the session start, which is simpler to reason about. Either approach works — we'll use the pointer event's built-in `timeStamp` since it's already a `Duration` and avoids maintaining extra state.

**Revised decision**: Use `PointerEvent.timeStamp` directly — it's already a `Duration`, monotonic, and requires zero extra state.

### 6. Auto-start orchestrator on mount

**Decision**: In `initState`, schedule a post-frame callback that calls `ref.read(teachingOrchestratorProvider.notifier).start()`.

**Rationale**: The orchestrator must start after the widget is fully mounted and providers are initialized. `WidgetsBinding.instance.addPostFrameCallback` ensures this. We avoid starting in the constructor to prevent provider read-during-build errors.

## Risks / Trade-offs

- **[Risk] Pointer event accuracy on different devices** → The `Listener` widget provides raw pointer data that should be consistent across devices. Timing thresholds are already configurable via `GestureTimingConfig`.

- **[Risk] Wakelock battery drain** → The screen stays on indefinitely. Mitigation: the screen is solid black, which is zero-power on OLED displays. LCD devices will consume more battery, but this is acceptable for an assistive tool where the user has no way to know the screen slept.

- **[Risk] User cannot exit the app via back button** → Intentional trade-off. The user is deaf-blind and doesn't use the back button. A sighted helper can use the home button or app switcher. In Change 4, we can add a specific exit gesture if needed.

- **[Trade-off] No visual debug feedback** → During development/testing, there's no way to see what the app is "thinking." Mitigation: the teaching orchestrator already has state (playing/listening/feedback) observable via providers; debug tools or tests can watch these.
