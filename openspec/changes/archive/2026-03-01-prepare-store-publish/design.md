## Context

Feel You is a Flutter app targeting iOS and Android that teaches deaf-blind users Morse code through vibration. Phase 1 is feature-complete but the app is not configured for store publishing. Current state:

- **Android**: Application ID `com.feelyou.feel_you`, release build uses debug signing keys, display name is `feel_you`, no ProGuard rules, no VIBRATE permission declared explicitly
- **iOS**: Bundle ID `com.feelyou.feelYou`, no development team configured, `CFBundleName` is `feel_you`
- **Both**: Version 1.0.0+1, no app icon generation pipeline, no store metadata, no privacy policy

## Goals / Non-Goals

**Goals:**
- Produce signable release builds for both platforms
- Unify app identity (bundle ID `com.feelyou.app`, display name "Feel You") across platforms
- Set up icon generation pipeline using user-provided icon assets
- Create store listing metadata for both App Store and Google Play
- Provide a privacy policy that satisfies store requirements
- Ensure the VIBRATE permission is explicitly declared on Android

**Non-Goals:**
- CI/CD pipelines or automated deployment
- Splash screen customization
- Generating actual icon artwork
- Setting up App Store Connect or Google Play Console accounts
- Fastlane or other deployment automation
- Screenshot or marketing asset generation

## Decisions

### 1. Bundle ID: `com.feelyou.app`

Unify both platforms to `com.feelyou.app`. The current IDs differ (`feel_you` vs `feelYou`) which is confusing and non-standard.

**Alternatives considered:**
- `com.feelyou.feelyou` — redundant, longer
- Keep current IDs — inconsistent, harder to manage

**Changes required:**
- Android: Update `namespace` and `applicationId` in `build.gradle.kts`
- iOS: Update `PRODUCT_BUNDLE_IDENTIFIER` in Xcode project.pbxproj

### 2. Android Release Signing: key.properties + keystore approach

Use the standard Flutter approach: a `key.properties` file (git-ignored) that references a keystore file. The `build.gradle.kts` reads this file for the release signing config.

**Alternatives considered:**
- Environment variables only — less portable for local dev
- Gradle properties — less conventional for Flutter projects

**Implementation:**
- Create `key.properties.example` template (committed to git)
- Add `key.properties` to `.gitignore`
- Update `build.gradle.kts` to load signing config from `key.properties`
- Document keystore generation command

### 3. iOS Release Signing: Automatic signing with team ID

Keep `CODE_SIGN_STYLE = Automatic` but ensure `DEVELOPMENT_TEAM` is set. The user will configure their team ID in Xcode. We'll add a placeholder and document the setup.

**Alternatives considered:**
- Manual signing with explicit provisioning profiles — overkill for initial release, adds complexity
- Match/Fastlane — out of scope (no CI/CD)

### 4. App Icons: flutter_launcher_icons package

Use `flutter_launcher_icons` as a dev dependency with a config file at `app/flutter_launcher_icons.yaml`. The user provides a single high-res icon (1024x1024 PNG), and the tool generates all platform-specific sizes.

**Alternatives considered:**
- Manual icon placement — error-prone, tedious (20+ sizes needed)
- flutter_native_splash — only handles splash, not icons

### 5. ProGuard/R8: Minimal Flutter rules

Add a `proguard-rules.pro` with standard Flutter rules. R8 is enabled by default in release builds; we just need to ensure Flutter's rules are preserved.

### 6. Store Metadata: Markdown files in a metadata directory

Create `store/` directory at project root containing:
- `description-en.md` — Full English description for both stores
- `description-ar.md` — Arabic description
- `keywords.md` — Keywords/tags for discoverability
- `privacy-policy.md` — Privacy policy document
- `store-info.md` — Category, content rating, contact info

**Alternatives considered:**
- Fastlane metadata structure — tied to Fastlane, which is out of scope
- Store console only — no version control for metadata

### 7. Version Strategy: Semantic versioning via pubspec.yaml

Keep current `version: 1.0.0+1` format where:
- `1.0.0` = display version (versionName on Android, CFBundleShortVersionString on iOS)
- `+1` = build number (versionCode on Android, CFBundleVersion on iOS)

Increment build number for each store submission. Bump version for feature releases.

## Risks / Trade-offs

- **[Bundle ID change breaks existing installs]** → Since the app hasn't been published, there are no existing installs to break. This is the right time to change it.
- **[Keystore loss means no app updates]** → Document that the keystore must be backed up securely. Once an app is published with a keystore, losing it means you cannot push updates.
- **[iOS team ID is developer-specific]** → Cannot commit this value. Document the setup steps clearly so the user knows what to configure in Xcode.
- **[VIBRATE permission on newer Android]** → The `vibration` Flutter package should handle this via its own manifest merge, but we'll declare it explicitly to be safe.
- **[Privacy policy may need legal review]** → We provide a reasonable template covering data collection (none) and permissions used. User should review with legal counsel before publishing.
