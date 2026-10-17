## 1. Repository

- [x] 1.1 Remove `packages/.gitkeep`, and with it `packages/`
- [x] 1.2 Rename `run-android.sh` to `run.sh`, taking the platform (`android` or `ios`) as its first argument; prefer a real device, and refuse profile and release builds on the iOS simulator
- [x] 1.3 Add `CHANGELOG.md` with the v0.0.1 and v0.0.2 releases and the unreleased changes since
- [x] 1.4 Add the release steps to `app/README.md` and point its run instructions at `run.sh`
- [x] 1.5 Update `ROADMAP.md`: housekeeping done, the `expanded-word-levels` skeleton gone

## 2. Specs

- [x] 2.1 Add the `Purpose` and `Requirements` headers to `app-identity/spec.md`, so the delta can be archived
- [x] 2.2 `flutter-app-scaffold`: replace the monorepo layout requirement with one without `packages/`
- [x] 2.3 `app-identity`: build number, changelog entry and tag for every release

## 3. Verification

- [x] 3.1 `shellcheck run.sh`; run `run.sh` with a stubbed `flutter` against Android and iOS device lists (real device, emulator or simulator only, none) and bad arguments
- [x] 3.2 `openspec validate repo-housekeeping --strict`
