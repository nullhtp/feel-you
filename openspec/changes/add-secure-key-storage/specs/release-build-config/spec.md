## ADDED Requirements

### Requirement: Android backup leaves out the secure storage
The Android app SHALL declare backup rules for Android 11 and lower (`android:fullBackupContent`) and data extraction rules for Android 12 and higher (`android:dataExtractionRules`) that leave the secure storage files out of cloud backup and device-to-device transfer. Backup SHALL stay enabled, and the rules SHALL leave out nothing else, so the app's other preferences keep being backed up.

#### Scenario: Both rule sets are declared
- **WHEN** the merged Android manifest is inspected
- **THEN** the application element SHALL reference a full backup content rules file and a data extraction rules file
- **AND** `android:allowBackup` SHALL NOT be `false`

#### Scenario: Secure storage files are excluded
- **WHEN** the full backup content rules, and the cloud backup and device transfer sections of the data extraction rules, are inspected
- **THEN** each SHALL exclude, in the `sharedpref` domain, `FlutterSecureStorage.xml`, `FlutterSecureKeyStorage.xml` and `FlutterSecureStorageConfiguration:FlutterSecureStorage.xml`
- **AND** none SHALL contain any other include or exclude rule

#### Scenario: Other preferences are still backed up
- **WHEN** the app's data is backed up or transferred to another phone
- **THEN** `FlutterSharedPreferences.xml`, which holds the saved language and learned items, SHALL be included
