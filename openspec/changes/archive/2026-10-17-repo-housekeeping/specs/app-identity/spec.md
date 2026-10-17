## MODIFIED Requirements

### Requirement: Version management
The app version SHALL follow semantic versioning via `pubspec.yaml` in `version: X.Y.Z+N` format where `X.Y.Z` is the display version and `N` is the build number. The initial store release SHALL be version `1.0.0+1`. Every release (a store upload or an APK attached to a GitHub release) SHALL raise the build number `N` by one, SHALL have an entry in `CHANGELOG.md` at the repository root, and SHALL be tagged `vX.Y.Z`.

#### Scenario: Version propagates to both platforms
- **WHEN** `version: 1.0.0+1` is set in pubspec.yaml
- **THEN** Android versionName is `1.0.0` and versionCode is `1`
- **THEN** iOS CFBundleShortVersionString is `1.0.0` and CFBundleVersion is `1`

#### Scenario: Every release raises the build number
- **WHEN** a release is prepared and the previous release had build number `N`
- **THEN** `pubspec.yaml` has build number `N+1`

#### Scenario: Every release is in the changelog and tagged
- **WHEN** version `X.Y.Z` is released
- **THEN** `CHANGELOG.md` has a `[X.Y.Z]` section with the release date and the changes since the previous release
- **THEN** the released commit is tagged `vX.Y.Z`
