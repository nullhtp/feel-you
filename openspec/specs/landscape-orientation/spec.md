### Requirement: App locked to landscape orientation
The app SHALL only run in landscape orientation (both landscape-left and landscape-right). Portrait orientation SHALL NOT be supported. The orientation lock SHALL be enforced at the Flutter level, iOS platform level, and Android platform level.

#### Scenario: App launches in landscape
- **WHEN** the app is launched on any device
- **THEN** the app SHALL display in landscape orientation regardless of how the user is holding the device

#### Scenario: Device rotation to portrait is ignored
- **WHEN** the user rotates the device to portrait orientation while the app is running
- **THEN** the app SHALL remain in landscape orientation and NOT rotate to portrait

#### Scenario: Both landscape directions supported
- **WHEN** the user rotates the device from landscape-left to landscape-right (or vice versa)
- **THEN** the app SHALL rotate to follow the new landscape direction

### Requirement: Flutter-level orientation lock
The app SHALL call `SystemChrome.setPreferredOrientations` with `[DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]` before `runApp` in the main entry point.

#### Scenario: Preferred orientations set at startup
- **WHEN** the app's `main()` function executes
- **THEN** `SystemChrome.setPreferredOrientations` SHALL be called with landscape-left and landscape-right before `runApp`

### Requirement: iOS orientation lock
The iOS `Info.plist` SHALL only include landscape orientations in `UISupportedInterfaceOrientations`. Portrait and portrait-upside-down SHALL be removed.

#### Scenario: iOS Info.plist contains only landscape orientations
- **WHEN** a developer inspects the iOS `Info.plist` `UISupportedInterfaceOrientations` array
- **THEN** it SHALL contain only `UIInterfaceOrientationLandscapeLeft` and `UIInterfaceOrientationLandscapeRight`

#### Scenario: iPad orientations are landscape only
- **WHEN** a developer inspects the iOS `Info.plist` `UISupportedInterfaceOrientations~ipad` array
- **THEN** it SHALL contain only `UIInterfaceOrientationLandscapeLeft` and `UIInterfaceOrientationLandscapeRight`

### Requirement: Android orientation lock
The Android `AndroidManifest.xml` SHALL set `android:screenOrientation="sensorLandscape"` on the main activity element.

#### Scenario: Android manifest locks to landscape
- **WHEN** a developer inspects the Android `AndroidManifest.xml` main activity
- **THEN** the activity SHALL have `android:screenOrientation="sensorLandscape"` attribute
