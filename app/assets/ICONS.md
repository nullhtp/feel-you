# App Icon Setup

Place your app icon at:

```
assets/icon/icon.png
```

Requirements:
- Format: PNG
- Size: 1024x1024 pixels
- No transparency/alpha channel (required by App Store)
- No rounded corners (platforms apply their own masking)

Then run:

```bash
cd app
dart run flutter_launcher_icons
```

This generates all required icon sizes for both Android and iOS.

For Android adaptive icons (optional), provide separate foreground/background layers
and update `flutter_launcher_icons.yaml` accordingly.
