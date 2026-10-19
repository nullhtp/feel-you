## Why

The language picker ignores the app lifecycle ([#98](https://github.com/nullhtp/feel-you/issues/98)). When the app leaves the foreground while a language identifier plays, the vibration goes on in the background; when the user comes back, nothing plays, so they cannot tell which language is highlighted. The lessons stop in the background and replay their item on return, and the home menu (#41) cancels its letter and replays it. The picker breaks two design rules: nothing vibrates in the background, and every state the user cannot see gets a signal.

The picker and the menu also carry two copies of the same gesture code (tap, swipe, short drag, hold, the wait before the next screen). #41 deferred sharing it until the settings list (#45) would be the third user; the picker needs the menu's lifecycle now, so this is the moment to extract it once instead of copying it a third time.

## What Changes

- **The picker follows the app lifecycle, as the home menu does.** Leaving the foreground (inactive, hidden, paused or detached, once per trip) cancels an identifier in progress, so nothing vibrates in the background. Coming back plays the highlighted language's identifier once. This holds for both pickers: the one on the first launch and the one opened from the menu's Settings.
- **During the wait after a hold** (the identifier, then 0.5 s of silence, then the menu), a trip to the background does what it does on the menu: the identifier is cancelled, the return plays nothing more on the picker, and the choice still completes, so the menu opens and announces itself.
- **One shared touch chooser.** The menu and the picker are built on one piece that owns what they share: the highlight, tap, swipe (≥ 50 px, wrapping), short drag, the 1-second hold with its wait, ignoring gestures during that wait, the announce after vibration detection, the lifecycle, and the column frame. Each screen keeps its options, identifiers (through the codec), labels, hint line, screen-reader semantics and shakes. The settings list (#45) can be its third user. Nothing the user feels on the menu changes.

## Accessibility

- No new gesture or signal. The picker answers a return to the foreground the way the lessons and the menu already do, so the user always knows where they are.
- The first-launch picker still does not listen for shakes; the lifecycle handling does not start shake detection.

## Non-goals

- No change to the home menu's behaviour, gestures, signals or timings; it only moves onto the shared chooser.
- No wakelock on the picker or the menu.
- No change to what a screen does when it first appears while the app is already out of the foreground (see design.md, Risks).
- No settings list (#45) and no new picker languages.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `language-selection`: a new requirement, *Language picker in the background*, for both pickers: cancel in the background, replay on return, the wait after a hold, no wakelock.
- `integration-testing`: a new end-to-end test of the picker's lifecycle, run beside the menu's for comparison.

## Impact

- **UI** (`app/lib/ui/`): a new `chooser.dart` (the shared chooser and its column); `language_picker_surface.dart` and `home_menu_surface.dart` built on it. `ForegroundShakeListener` keeps handling shake detection and loses its `onBackground` / `onForeground` callbacks, which no screen uses any more.
- **Tests**: new picker lifecycle widget tests for both pickers; new end-to-end tests in `integration_test/app_lifecycle_test.dart` for both pickers and the menu. The existing picker, menu, navigation and end-to-end tests pass unchanged.
- **Docs**: README (the picker's lifecycle), `app/README.md` (`lib/ui/` row), CHANGELOG.
- **No change** to the lessons, the orchestrator, the session, the vibration service, the codecs or the stores.
