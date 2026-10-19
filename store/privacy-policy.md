# Privacy Policy

**Feel You**
**Effective Date**: 2026-10-15
**Last Updated**: 2026-10-19

This policy is published at https://github.com/nullhtp/feel-you/blob/master/store/privacy-policy.md

## Overview

Feel You is a Morse code learning app designed for deaf-blind users. This privacy policy explains how the app handles your information.

## Data Collection

**Feel You does not collect, store, or transmit any personal data.** The app operates entirely on your device with no network communication: the released Android app does not even request internet access. There are no accounts, no analytics, no tracking, and no telemetry.

Specifically, Feel You does NOT:
- Collect personal information of any kind
- Track your location
- Access your contacts, photos, or files
- Send data to any server
- Use cookies or similar tracking technologies
- Share any information with third parties
- Contain advertising or ad tracking

## Device Features and Permissions

Feel You uses the following device features, solely for core app functionality:

### Vibration
- **Purpose**: Vibration is the app's only output channel. It is used to play Morse code patterns, success and error feedback, and the identifier of each language in the language picker.
- **Permission**: On Android the app declares the `VIBRATE` permission, which the system grants at install without asking. iOS needs no permission.
- **Usage**: On-device only. No data is transmitted.

### Accelerometer (Motion Sensors)
- **Purpose**: The accelerometer detects shaking the phone: one shake returns to the start of the lessons ("Home"), and a double shake returns to the language picker.
- **Permission**: None needed on Android or iOS.
- **Usage**: Sensor data is processed in real time, on the device, while the lesson screen is in use. No motion data is stored or transmitted.

### Keep Screen Awake
- **Purpose**: The app keeps the screen on during lessons so that the touch surface stays responsive and the screen does not time out while the user is interacting with the app. This stops when the app leaves the foreground.
- **Permission**: None needed on Android or iOS.
- **Usage**: On-device only. No data is transmitted.

The app requests no other permissions. In particular, it does not use the camera, microphone, location, contacts, photos or files, and it never shows a permission prompt.

## Data Storage

Feel You stores two things on your device: the lesson language you chose (English, Arabic, Russian, Spanish, French or German), so that the next launch can skip the language picker, and the digits, letters and words you have answered correctly in the lessons, so that the quiz can test you on them. Both are kept in the platform's standard app preferences storage (SharedPreferences on Android, UserDefaults on iOS). Your place in the lessons is not saved: every launch starts again at digit 0.

The app never sends this data anywhere, and it is deleted when you uninstall the app. Like any app's settings, it may be included in your device's own backups (such as Android backup or iCloud backup) if you have turned them on; those backups are made by your device's operating system under your account, not by Feel You.

The app can also keep one more thing for the cloud features planned for a later version: an OpenRouter key that the person assisting you enters. This version offers no way to enter one, so it stores no key. A key, once entered, is kept only in the platform's secure storage (the Keychain on iOS; on Android, encrypted with a key held in the Android Keystore), never in the app preferences above. It stays on this device: it is not synced through iCloud Keychain, not restored to another iPhone from a backup, and left out of Android backup and device-to-device transfer. The app never shows it in full (only its first and last characters, such as `sk-or-...a1b2`) and never writes it to a log. On Android it is deleted when you uninstall the app. iOS keeps Keychain items after an app is deleted, so reinstalling the app on the same iPhone finds the key again; deleting the key in the app, or erasing the iPhone, removes it.

## Children's Privacy

Feel You does not collect any data from any users, including children. The app is suitable for users of all ages.

## Changes to This Policy

If we make changes to this privacy policy, we will update the "Last Updated" date at the top. We encourage you to review this policy periodically.

## Contact

If you have questions about this privacy policy, please contact us at:

null.htp@gmail.com

---

*This privacy policy applies to the Feel You mobile application for iOS and Android, as distributed on the Apple App Store and Google Play Store.*
