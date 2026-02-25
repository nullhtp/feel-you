## Context

Feel You is a greenfield Flutter project with no application code yet. Before any feature development can start, we need a properly structured Flutter monorepo with tooling foundations in place. The project targets iOS and Android only, and the entire user interaction model is touch-in / vibration-out (no visual or audio UI).

The repo currently contains only planning documents (`README.md`, `openspec/`). We need to bootstrap a Flutter app in `app/` with the right SDK constraints, analysis rules, and state management wired up.

## Goals / Non-Goals

**Goals:**
- Runnable Flutter app shell in `app/` that builds and runs on iOS and Android
- Monorepo directory structure at root level that accommodates future packages
- Strict Dart analysis enforced from day one
- Riverpod wired as the state management foundation
- Clean separation between monorepo root config and Flutter app config

**Non-Goals:**
- No Melos or other monorepo orchestration tooling
- No feature code, UI screens, or business logic
- No CI/CD, code generation, or build automation
- No web/desktop platform targets
- No custom theme or design system

## Decisions

### 1. App lives in `app/` directory

**Choice**: Flutter project in `app/` rather than repo root or `apps/feel_you/`.

**Rationale**: The user chose a simpler single-app convention. `app/` keeps the root clean for monorepo-level config (`.gitignore`, `README.md`, future `melos.yaml`) while being shorter than `apps/feel_you/`. If we add packages later, they go in `packages/`.

**Alternatives considered**:
- Repo root: Simpler but pollutes root with Flutter artifacts, makes future multi-package setup harder.
- `apps/feel_you/`: More conventional for multi-app monorepos but over-engineered for a single app.

### 2. Riverpod for state management

**Choice**: `flutter_riverpod` + `riverpod_annotation` as the state management foundation.

**Rationale**: Riverpod is compile-safe, testable, and has minimal boilerplate for simple state. The app's Phase 1 state is trivial (current letter index), but Riverpod scales well for future phases (speech-to-Morse, real-time conversation). It also works well with Flutter's widget lifecycle.

**Alternatives considered**:
- Provider: Simpler but less type-safe, harder to test in isolation.
- flutter_bloc: More boilerplate for the simple state model we need in Phase 1.
- Signals: Too new/emerging for a production accessibility app.

### 3. `very_good_analysis` for linting

**Choice**: Use `very_good_analysis` package for Dart analysis rules.

**Rationale**: Stricter than `flutter_lints`, catches more issues at compile time. For an accessibility app where bugs can make the app unusable (user can't see errors), strict analysis is worth the upfront cost.

**Alternative considered**:
- `flutter_lints`: Less strict, would miss some issues. We can always relax individual rules if needed.

### 4. Platform targets: iOS 14+ and Android API 21+

**Choice**: Minimum iOS 14, minimum Android SDK 21 (Android 5.0).

**Rationale**: iOS 14+ covers 99%+ of active iPhones and gives us access to modern haptic APIs. Android API 21 is Flutter's default minimum and covers 98%+ of active devices. Both platforms have good vibration/haptic support at these levels.

### 5. Directory structure

```
feel-you/
  README.md
  .gitignore
  openspec/             # planning docs (existing)
  app/                  # Flutter application
    pubspec.yaml
    analysis_options.yaml
    lib/
      main.dart
      app.dart          # MaterialApp with ProviderScope
    test/
    ios/
    android/
  packages/             # future shared packages (empty for now)
```

## Risks / Trade-offs

- **[Risk] No Melos means manual dependency management** -> Acceptable for a single-app setup. We add Melos when we actually have multiple packages.
- **[Risk] `very_good_analysis` may be too strict initially** -> We can add rule overrides in `analysis_options.yaml` for specific cases. Better to start strict and relax than the reverse.
- **[Risk] Riverpod without code generation** -> We'll include `riverpod_annotation` but won't set up `build_runner` in this change. Code generation can be added when we have actual providers to generate.
- **[Trade-off] Empty `packages/` directory** -> Signals monorepo intent but contains nothing yet. A `.gitkeep` file preserves it in git.
