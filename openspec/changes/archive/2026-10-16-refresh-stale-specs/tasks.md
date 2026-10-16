## 1. Specs

- [x] 1.1 Add the `Purpose` and `Requirements` headers to `store-metadata/spec.md` and `flutter-app-scaffold/spec.md`, so the deltas can be archived
- [x] 1.2 `store-metadata`: list English, Arabic and Russian as supported languages
- [x] 1.3 `flutter-app-scaffold`: require iOS 15+ and Android API 24+

## 2. Verification

- [x] 2.1 Check `store/store-info.md` lists Russian
- [x] 2.2 Check the iOS deployment target is 15.0 and the Android `minSdk` resolves to 24
- [x] 2.3 `openspec validate refresh-stale-specs --strict`
