## Why

Housekeeping from [#13](https://github.com/nullhtp/feel-you/issues/13):

- `flutter-app-scaffold` requires a monorepo layout with an empty `packages/` directory "for future shared packages". No shared package has appeared since the scaffold, so the folder holds only a `.gitkeep`. The app stays in `app/`, the only Dart package.
- `app-identity` sets the first store version, `1.0.0+1`, but nothing about later versions. `pubspec.yaml` has never been bumped: the APKs attached to the GitHub releases v0.0.1 and v0.0.2 were both built as 1.0.0 (build 1), and there is no changelog. Store uploads need a build number that goes up every time.

## What Changes

- `flutter-app-scaffold`: *Repository directory structure* replaces *Monorepo directory structure*. The app stays in `app/`, and there is no `packages/` directory until a second package exists.
- `app-identity`: every release raises the build number by one, gets a `CHANGELOG.md` entry with its version and date, and is tagged `vX.Y.Z`.
- Outside the specs: `packages/` is removed, `CHANGELOG.md` is added, `app/README.md` gains the release steps, and `run-android.sh` becomes `run.sh <android|ios>`.

## Non-goals

- No change to the app: its code, behaviour and current version (`1.0.0+1`, the first store release) stay as they are.
- No flattening of `app/` into the repository root.
- No new tags or GitHub releases. The existing `v.0.0.2` tag keeps its stray dot.

## Accessibility

Nothing changes for the user. `run.sh` picks a real phone before an emulator or simulator, because the app's only output is vibration: the iOS simulator has no vibration motor, and an Android emulator's vibrations can't be felt.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `flutter-app-scaffold`: repository layout without `packages/`.
- `app-identity`: build number, changelog and tag for every release.

## Impact

- **Specs**: `openspec/specs/flutter-app-scaffold/spec.md` and `openspec/specs/app-identity/spec.md`, which also gains the `Purpose` and `Requirements` headers OpenSpec needs to merge a delta.
- **Repository**: `packages/` removed; `CHANGELOG.md` added; `run-android.sh` renamed to `run.sh`; `app/README.md` and `ROADMAP.md` updated.
- **Code, builds, store files**: none.
