# Store Listing Information

## General

- **App Name**: Feel You
- **Bundle ID**: com.feelyou.app
- **Version**: 1.0.0

## Category

- **Primary Category**: Education
- **Secondary Category**: Utilities (or Accessibility if available)
- **Google Play Category**: Education
- **App Store Category**: Education > Special Education

## Content Rating

- **Google Play**: Everyone (IARC questionnaire: no violence, no sexual content, no language, no controlled substances, no user interaction features)
- **App Store**: 4+ (no objectionable content)

## Supported Languages

Morse alphabets the app teaches (chosen in the in-app language picker):

- English (International Morse)
- Arabic (Arabic Morse)
- Russian (Russian Morse)

The app has no UI localisation: its text for sighted helpers (overlay labels, the picker hint, the "No vibration motor" screen) is in English only, and the picker shows each language's name in its own script. Store descriptions exist in English (`description-en.md`) and Arabic (`description-ar.md`).

## Contact Information

- **Developer Name**: FeelU
- **Contact Email**: null.htp@gmail.com
- **Website**: None
- **Privacy Policy URL**: https://github.com/nullhtp/feel-you/blob/master/store/privacy-policy.md

## Store Declarations

- **Ads**: No — the app contains no advertising
- **In-App Purchases**: No — the app is completely free with no IAP
- **Data Collection**: No — the app does not collect or transmit any user data. The only thing it stores is the chosen lesson language, locally on the device
- **Internet Access**: Not required — the app works entirely offline
- **Made for Kids**: No (but suitable for all ages)
- **Government Apps**: No
- **Encryption**: None — the app uses no encryption of its own and makes no network connections (exempt from export compliance)

## Device Requirements

- **Vibration Motor**: Required (core output mechanism). On a device that reports no motor the app shows a "No vibration motor" screen and cannot be used
- **Custom vibration patterns**: Needed for Morse timing. Every Android device can play them; on iOS they need Core Haptics (not available on iPhone 7 and older). Without them every vibration is the same fixed system buzz; the app still runs and its helper overlay shows `custom: no`
- **Accelerometer**: Required (shake = home, double shake = back to the language picker)
- **Orientation**: Landscape only
- **Minimum OS**: Android: Flutter's default `minSdk` (`flutter.minSdkVersion` in `app/android/app/build.gradle.kts`); iOS 15.0+ (`IPHONEOS_DEPLOYMENT_TARGET` in `app/ios/Runner.xcodeproj`)
- **iOS Devices**: iPhone only (no iPad, iPod touch, Apple Vision Pro or Mac)

### iOS: iPhone only

Vibration is the app's only output channel. Of the devices that can run an iOS app, only the iPhone can vibrate. On iPad, iPod touch, Apple Vision Pro and Mac the app would install and run, but the vibration calls do nothing, so a deaf-blind user would get no output at all.

What the build enforces:

- `TARGETED_DEVICE_FAMILY = 1` (iPhone) in every build configuration of `app/ios/Runner.xcodeproj`. The iPad-only orientation list (`UISupportedInterfaceOrientations~ipad`) was removed from `Info.plist`.
- `UIRequiredDeviceCapabilities` = `telephony` in `app/ios/Runner/Info.plist`. The device family alone is not enough, because the App Store still offers iPhone-only apps on iPad, where they run in compatibility mode. There is no capability value for a vibration motor. `telephony` matches the same set of devices: according to Apple's [device capability list](https://developer.apple.com/support/required-device-capabilities/), every iPhone has it, and no iPad (including Wi-Fi + Cellular models), iPod touch or Apple Vision Pro does.

Constraints:

- **Must ship in the first release.** For updates, Apple allows capability requirements only to stay the same or be relaxed ([UIRequiredDeviceCapabilities](https://developer.apple.com/documentation/bundleresources/information-property-list/uirequireddevicecapabilities)). `telephony` can't be added after 1.0 ships, but it can always be removed later.
- **App Review risk.** The app makes no phone calls, and Apple asks apps to declare only the capabilities they need. Explain the requirement in the App Review notes (text below). If review still rejects it, remove the key and ship with the iPhone device family alone. In that case iPad users can install the app, and the app has to tell them it can't work on their device. The in-app vibration check (issue #4, the "No vibration motor" screen) does not do that yet: on iOS the `vibration` plugin reports a motor on every physical device, iPad included.

Manual steps in App Store Connect. These can't be set in `Info.plist`. Go to the app → **Pricing and Availability** (requires the Account Holder, Admin or App Manager role):

- [ ] **iPhone and iPad Apps on Apple Silicon Mac** → *Apple Silicon Mac Availability* → deselect **Make this app available**. Apple silicon Macs get iPhone apps by default, and the app can't vibrate on a Mac. ([Apple help](https://developer.apple.com/help/app-store-connect/manage-your-apps-availability/manage-availability-of-iphone-and-ipad-apps-on-macs-with-apple-silicon))
- [ ] **iPhone and iPad Apps on Apple Vision Pro** → *Apple Vision Pro Availability* → deselect **Make this app available on Apple Vision Pro**. `telephony` should already exclude Vision Pro, and this makes the exclusion explicit. ([Apple help](https://developer.apple.com/help/app-store-connect/manage-your-apps-availability/manage-availability-of-iphone-and-ipad-apps-on-apple-vision-pro))
- Make these changes before the first release. Users who already downloaded the app on a Mac or Vision Pro keep it after you opt out.

Suggested App Review note:

> Feel You communicates with deaf-blind users only through vibration (Morse code). iPhone is the only device in the iOS family with a vibration motor; on iPad and iPod touch the app cannot produce any output. Because UIRequiredDeviceCapabilities has no value for a vibration motor, we declare `telephony`, which matches exactly the devices that have one, so that the app is not offered on devices where it cannot work.

## Pricing

- **Price**: Free
- **Distribution**: Worldwide
