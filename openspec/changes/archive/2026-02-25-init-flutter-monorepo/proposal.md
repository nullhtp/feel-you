## Why

The Feel You project has no application code yet — only planning documents. Before any feature work can begin (Morse learning, vibration engine, etc.), we need a working Flutter project with a monorepo structure that supports future growth. This is the foundational scaffolding that everything else builds on.

## What Changes

- Create a Flutter application in `app/` directory with iOS and Android targets only
- Set up monorepo directory structure at root level (no Melos tooling yet, just conventions)
- Configure strict Dart analysis with `very_good_analysis` (or `flutter_lints`)
- Add Riverpod as the state management foundation
- Configure minimum platform targets: iOS 14+, Android API 21+
- Add `.gitignore`, root-level config files, and workspace conventions

## Non-goals

- No feature code (Morse learning, vibration patterns, etc.) — this is infrastructure only
- No Melos or other monorepo tooling — just directory structure for now
- No CI/CD pipeline setup
- No web or desktop platform targets
- No custom theming or UI components

## Capabilities

### New Capabilities

- `flutter-app-scaffold`: Core Flutter application shell in `app/` with Riverpod, analysis rules, and platform targets configured. This is the runnable app that all features will be built into.

### Modified Capabilities

(none — greenfield project)

## Impact

- **New files**: Flutter project in `app/`, root-level monorepo config files
- **Dependencies**: Flutter SDK (latest stable), Riverpod, analysis package
- **Platforms**: iOS 14+ and Android API 21+ only
- **Developer workflow**: `flutter run` from `app/` directory to launch the app
