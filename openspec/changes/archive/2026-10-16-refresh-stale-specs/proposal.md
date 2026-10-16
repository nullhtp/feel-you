## Why

Two main specs no longer match the app ([#30](https://github.com/nullhtp/feel-you/issues/30)):

- `store-metadata` requires `store/store-info.md` to list the supported languages as English and Arabic. Russian has been supported since `add-russian-morse`, and `store-info.md` already lists it.
- `flutter-app-scaffold` requires iOS 14 and Android API 21. Since #24 the app targets iOS 15 (`IPHONEOS_DEPLOYMENT_TARGET`) and Flutter's default Android `minSdk`, which is 24.

## What Changes

- `store-metadata`: the store info file lists English, Arabic and Russian as supported languages.
- `flutter-app-scaffold`: the app builds and runs on iOS 15+ and Android API 24+.

## Non-goals

- No change to the app, its build settings or the store files. The specs catch up with what is already shipped.
- No change to the monorepo layout requirement, which waits on the repo-layout decision in #13.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `store-metadata`: supported languages include Russian.
- `flutter-app-scaffold`: platform minimums are iOS 15 and Android API 24.

## Impact

- **Specs only**: `openspec/specs/store-metadata/spec.md` and `openspec/specs/flutter-app-scaffold/spec.md`, which also gain the `Purpose` and `Requirements` headers OpenSpec needs to merge a delta.
- **Code, builds, store files**: none.
