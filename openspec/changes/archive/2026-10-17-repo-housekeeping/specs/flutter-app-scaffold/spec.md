## REMOVED Requirements

### Requirement: Monorepo directory structure
**Reason**: No shared package was ever added, so `packages/` held only a `.gitkeep`.
**Migration**: Replaced by *Repository directory structure*. The app stays in `app/`.

## ADDED Requirements

### Requirement: Repository directory structure
The repository SHALL keep the Flutter app, its only Dart package, in `app/`. It SHALL NOT have a `packages/` directory until a second package exists. Files and directories at the root SHALL concern the repository as a whole (documentation, CI, OpenSpec, store listing, helper scripts), not the Flutter build.

#### Scenario: Root directory contains expected structure
- **WHEN** a developer clones the repository
- **THEN** the root contains `app/`, `openspec/`, `README.md`, and `.gitignore`
- **THEN** there is no `packages/` directory

#### Scenario: Flutter commands run from app/
- **WHEN** a developer runs a `flutter` command such as `flutter pub get` or `flutter test`
- **THEN** they run it from `app/`, which holds `pubspec.yaml`
