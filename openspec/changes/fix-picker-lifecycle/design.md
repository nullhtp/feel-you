## Context

See proposal.md for why. The current state:

- **Two copies of one chooser.** `LanguagePickerSurface` and `HomeMenuSurface` (`app/lib/ui/`) each hold a highlighted option, a `HorizontalDragGestureRecognizer` measured from touch-down (≥ 50 px moves the highlight and wraps, shorter replays it), a 1-second `LongPressGestureRecognizer`, a `GestureDetector` per column for taps, the announce once `vibrationCapabilitiesProvider` has resolved, a "busy" flag (`_started` in the picker, `_entering` in the menu) that silences every gesture once an option is confirmed, and the wait for the identifier plus `TeachingTimingConfig.postFeedbackPause` before the route changes (#28). #41's design (decision 4) copied the picker into the menu and deferred sharing it until #45.
- **Lifecycle.** The menu cancels vibration and replays its letter through `ForegroundShakeListener`'s `onBackground` / `onForeground` callbacks; the same listener pauses shake detection in the background. The picker opened from Settings uses the listener only for its double shake back; the first-launch picker has no listener at all and never touches shake detection (`language-selection`: shaking does nothing there). Neither screen keeps the screen on.

## Goals / Non-Goals

**Goals:**
- The picker gets exactly the menu's lifecycle, edge cases included.
- One reusable chooser that both screens use and the settings list (#45) can use as a third, without changing what either screen does.

**Non-Goals:**
- Changing how `ForegroundShakeListener` pauses and resumes shake detection, the shake hand-over between screens, or who owns detection. It only loses its two lifecycle callbacks (decision 2).
- Fixing how a screen behaves when it first appears while the app is already out of the foreground (Risks).

## Decisions

### 1. The chooser is a mixin on the screen's `ConsumerState`

`mixin Chooser<W extends ConsumerStatefulWidget, T> on ConsumerState<W>` in `app/lib/ui/chooser.dart`. A screen mixes it in and supplies four members, which are the whole contract:

- `List<T> get options`: left to right (`HomeMenuMode.values`, `MorseLanguage.values`);
- `T get initialOption`: read once in `initState` (the mode the menu was told to highlight; the saved language or English);
- `Future<void> playIdentifier(T option)`: vibrates the identifier and completes when it has finished (each screen encodes its letters with its codec);
- `void onChosen(T option)`: runs after the identifier and the silence, while the screen is still shown on a device that can vibrate (the menu hands shakes over and opens the mode; the picker saves, selects and opens the menu).

The mixin provides `highlighted`, `highlight(option)` (a column tap), `replayHighlighted()` (the menu's double shake), `choose(option)` (the hold and the screen-reader buttons), `tryLeave()` (the picker's double shake back: claims the busy flag, or refuses while a choice is under way), and `buildChooser(child:)`: `PopScope(canPop: false)`, the black `Scaffold` and the `RawGestureDetector` with the drag and hold recognizers around the screen's own content. `ChooserColumn` is the shared column: the tap detector, the padding that leaves room for the hint line, and the rounded frame drawn inverted while highlighted.

Alternatives:
- *A `Chooser<T>` widget with builders.* Each screen would pass a column builder (contents and semantics), the overlay, and still need a controller to reach in from outside: the menu replays on a double shake, the picker leaves on one, and both choose from their semantics buttons. More indirection for the same result, and the widget tree, which the semantics tests pin, would change.
- *A plain controller class (like `ForegroundShakeListener`) with callbacks.* It needs the State's `setState`, `mounted`, `ref`, the timing config and the navigator, so it would take half a dozen callbacks, and the gesture recognizers would still be built in each screen.
- A `State` mixin is how Flutter shares State behaviour (`TickerProviderStateMixin`, `RestorationMixin`): it has `ref`, `mounted`, `setState` and `this` (the recognizers' `debugOwner`) directly, and each screen's `build` keeps its tree as it was.

### 2. The chooser owns the lifecycle with its own `AppLifecycleListener`

The first-launch picker has no `ForegroundShakeListener` and must not start shake detection, so the lifecycle cannot ride on that listener. The chooser registers an `AppLifecycleListener` in `initState` and disposes it in `dispose`:

- the first non-`resumed` state of a trip (`inactive`, `hidden`, `paused`, `detached`) cancels vibration (`VibrationService.cancel`), once per trip, as the lessons and the menu do;
- `resumed` after a trip calls `replayHighlighted()`, which does nothing while the screen is busy (choosing or leaving) or cannot vibrate.

The menu drops its `onBackground` / `onForeground` callbacks and keeps the listener for shakes only, which still pauses detection in the background and resumes it on return. With no caller left, the two callbacks are removed from `ForegroundShakeListener`, and its tests check only what it does to detection and to shake events. The menu's behaviour is unchanged: the listener called `onForeground` only before its hand-over, and the menu hands over only after `_entering` is set, so the busy flag gives the same answer.

### 3. Edge cases follow the menu

| Moment | Menu before | Both now (menu and pickers) |
|---|---|---|
| Leaving the foreground while an identifier plays | cancel, once per trip | same |
| Inactive only (a call, Control Center) | counts as leaving | same |
| Coming back | the highlighted identifier, once | same |
| Leaving during the wait after a hold (identifier or silence) | cancel; the wait goes on; the return replays nothing; the mode opens when the wait ends | same; the picker still saves and selects the language and opens the menu |
| Leaving after the picker's double shake back, during the transition | (n/a) | the picker replays nothing; the menu, already mounted, replays its letter |
| Leaving after a hand-over, during the transition | the outgoing menu still cancels | same for the outgoing picker |

While the app is hidden or paused, the engine draws no frame, so a route pushed when the wait ends is built on the return, and the next screen announces itself then.

### 4. What stays in each screen

Options and their identifiers (the codec), the column contents (labels, letters, patterns), the hint line, the screen-reader semantics (button nodes, labels, hints, the route name), shakes and where a choice leads. The `confirmHoldDuration` constants stay on both widgets as aliases of `chooserHoldDuration`, since tests and the end-to-end helpers use them.

### 5. Tests

- Widget tests in `language_picker_non_visual_test.dart`, for both pickers: background mid-identifier → one `cancel`, nothing more while away, and the first-launch picker leaves shake detection alone; inactive only; return → the highlighted identifier once per trip; a trip during the wait after a hold → no replay, the language still starts; no wakelock toggle; and the double shake back during a trip. The menu's own lifecycle tests are unchanged and still pass.
- End to end in `integration_test/app_lifecycle_test.dart`, on the real lifecycle (`handleAppLifecycleStateChanged` through the harness's `sendToBackground` / `bringToForeground`): for the first-launch picker, the picker from Settings and, as the reference, the menu. A recording vibration service whose playbacks last 800 ms unless cancelled lets the test leave while an identifier is still playing.

### Vibration timings

Default timing (dot 100 ms, dash 300 ms, 100 ms between elements; `postFeedbackPause` 500 ms). Nothing new is played; the picker's return plays the identifier it already has:

| Moment on the picker | Vibration | Duration |
|---|---|---|
| App leaves the foreground | the identifier in progress is cancelled | |
| App comes back (not during a choice) | highlighted identifier once: E `·`, ع `· − · −`, Р `· − ·`, Ñ `− − · − −`, É `· · − · ·`, Ü `· · − −` | 100, 1100, 700, 1700, 1100, 1100 ms |
| App comes back during the wait after a hold | nothing on the picker; the menu announces L (first launch) or S (from Settings) when it appears | 900 / 500 ms |

## Risks / Trade-offs

- [A screen that first appears while the app is already out of the foreground does not know it.] The chooser, like `ForegroundShakeListener` and `TouchSurface`, assumes it is created in the foreground and reacts only to later changes. When a hold's wait ends while the app is only `inactive` (frames still drawn, e.g. Control Center), the next screen is built at once: the menu plays its letter, or the lessons start their loop, before the app is resumed. This is the menu's existing behaviour, kept unchanged here; reported as a follow-up (check `WidgetsBinding.instance.lifecycleState` when a screen mounts).
- [A mixin with abstract members can be misused (a screen forgetting `super.initState()`).] → `@mustCallSuper` on `State.initState` / `dispose` makes the analyzer flag it; both screens are covered by their full widget suites.
- [Two lifecycle listeners on the menu (the chooser's and the shake listener's).] → They act on different things (vibration, shake detection); the order between them does not matter.

## Migration Plan

None: nothing is stored or sent differently. Rolling back restores the two copies and the picker without lifecycle handling.
