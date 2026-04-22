# Be Electric - App Store & Google Play Release Guide

Complete checklist for publishing the Be Electric CMMS app to both stores.

---

## Prerequisites

| Item | Details |
|------|---------|
| **Apple Developer Account** | $99/year — [developer.apple.com](https://developer.apple.com) |
| **Google Play Developer Account** | $25 one-time — [play.google.com/console](https://play.google.com/console) |
| **macOS with Xcode 15+** | Required for iOS builds and App Store submission |
| **Flutter SDK** | 3.x (already installed) |
| **Privacy Policy URL** | Host `PRIVACY_POLICY.md` on a public URL (e.g. your website) |

---

## 1. Android — Google Play

### 1.1 Create Upload Keystore

```bash
keytool -genkey -v \
  -keystore android/beelectric-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias beelectric
```

### 1.2 Configure Signing

Copy `android/key.properties.example` to `android/key.properties` and fill in:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=beelectric
storeFile=../beelectric-upload.jks
```

> **Never commit `key.properties` or `.jks` files.** They are in `.gitignore`.

### 1.3 Build AAB (App Bundle)

Google Play requires AAB for new apps (not APK).

```bash
cd qauto-cmms-main

flutter clean

flutter build appbundle --release \
  --dart-define=SUPABASE_URL=https://sdhqjyjeczrbnvukrmny.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_PRODUCTION_ANON_KEY \
  --dart-define=ONE_SIGNAL_APP_ID=YOUR_ONESIGNAL_APP_ID
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### 1.4 Build APK (for sideloading / testing)

```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://sdhqjyjeczrbnvukrmny.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_PRODUCTION_ANON_KEY \
  --dart-define=ONE_SIGNAL_APP_ID=YOUR_ONESIGNAL_APP_ID
```

### 1.5 Version Bumping

In `pubspec.yaml`:

```yaml
version: 1.0.0+1
#         ^^^^^  ^
#         name   build number (versionCode)
```

- **versionName** (1.0.0): Shown to users. Use semantic versioning.
- **versionCode** (+1): Must **increment** with every Play Store upload. Bump to +2, +3, etc.

### 1.6 Play Console Setup

1. **Create app** in [Play Console](https://play.google.com/console)
2. **App details:**
   - App name: `Be Electric`
   - Category: Business / Utilities
   - Default language: English (US)
3. **Store listing:**
   - Short description (80 chars): `EV charger maintenance management for technicians and requestors.`
   - Full description (4000 chars): Describe features, roles, work orders, etc.
   - Screenshots: Phone (2–8), Tablet (optional), Feature graphic (1024×500)
   - App icon: 512×512 PNG (use `assets/images/beelectric-insignia.png` scaled up)
4. **Content rating:** Complete IARC questionnaire (utility app, no violence/gambling)
5. **Data safety:**
   - Data collected: Name, email, photos, device ID, push tokens
   - Shared with third parties: No (Supabase and OneSignal are service providers, not third-party sharing)
   - Data encrypted in transit: Yes
   - Data deletion mechanism: Contact admin
6. **Privacy policy URL:** Link to hosted `PRIVACY_POLICY.md`
7. **Target audience:** 16+ (not designed for children)
8. **Upload AAB** to Internal testing track first, then promote to Production.

---

## 2. iOS — Apple App Store

**IPA builds require macOS with Xcode.** On Windows/Linux, use a Mac CI runner (Codemagic, GitHub Actions macOS, or a local Mac) to run `flutter build ipa`.

### 2.0 App Store readiness (already in this repo)

| Item | Location / notes |
|------|------------------|
| Bundle ID | `com.beelectric.app` (`ios/Runner.xcodeproj/project.pbxproj`) |
| Display name | Be Electric (`ios/Runner/Info.plist`) |
| Minimum iOS | 14.0 (`Podfile`, Xcode project) |
| Push (APNs) | `ios/Runner/Runner.entitlements` (`aps-environment`: production for release) |
| Permissions copy | Camera, Photos, Microphone, Location (`Info.plist`) |
| Photo library (save) | `NSPhotoLibraryAddUsageDescription` (`Info.plist`) |
| Export compliance | `ITSAppUsesNonExemptEncryption` = `false` (standard HTTPS only; aligns with App Store Connect “encryption” questions) |
| Privacy manifest | `ios/Runner/PrivacyInfo.xcprivacy` (tracking disabled; required for third‑party SDK / store checks) |
| Symbols for crashes | `ExportOptions.plist` has `uploadSymbols` = true |
| Launcher icons | `flutter_launcher_icons` in `pubspec.yaml` (`dart run flutter_launcher_icons` after icon changes) |

Regenerate iOS icons after changing `image_path` in `pubspec.yaml`:

```bash
dart run flutter_launcher_icons
```

### 2.1 Apple Developer Setup

1. Log in to [Apple Developer](https://developer.apple.com)
2. Register Bundle ID: `com.beelectric.app`
3. Enable capabilities:
   - **Push Notifications** (required for OneSignal)
   - **Background Modes → Remote notifications** (already in Info.plist)
4. Create **APNs Key** (p8) for OneSignal:
   - Certificates, Identifiers & Profiles → Keys → + → Apple Push Notifications service (APNs)
   - Download the `.p8` file, note Key ID and Team ID
   - Upload to OneSignal dashboard under Settings → Platforms → Apple iOS

### 2.2 Xcode Configuration (on macOS)

1. Open `ios/Runner.xcworkspace` in Xcode (not `.xcodeproj`, so CocoaPods integration is used).
2. Select Runner target → Signing & Capabilities:
   - Set Team to your Apple Developer team
   - Verify Bundle ID: `com.beelectric.app`
   - Enable **Automatic signing** (recommended)
3. Signing & Capabilities → + Capability:
   - **Push Notifications** (if not already present)
4. From the project root, run:

```bash
cd ios && pod install && cd ..
```

5. In Xcode, product **Archive** once to confirm signing and capabilities before relying on CLI-only builds.

### 2.3 Build IPA

```bash
cd qauto-cmms-main

flutter clean

flutter pub get

flutter build ipa --release \
  --dart-define=SUPABASE_URL=https://sdhqjyjeczrbnvukrmny.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_PRODUCTION_ANON_KEY \
  --dart-define=ONE_SIGNAL_APP_ID=YOUR_ONESIGNAL_APP_ID \
  --export-options-plist=ios/ExportOptions.plist
```

> **Important:** Edit `ios/ExportOptions.plist` and replace `YOUR_APPLE_TEAM_ID` with your [Apple Team ID](https://developer.apple.com/account#MembershipDetailsCard) (10-character string).

Output: `build/ios/ipa/*.ipa` (exact filename matches the product name; often `qauto_cmms.ipa` or `Runner.ipa` depending on Xcode settings).

### 2.4 Upload to App Store Connect

**Option A — Xcode:**
1. Open `build/ios/archive/Runner.xcarchive` in Xcode Organizer
2. Click Distribute App → App Store Connect → Upload

**Option B — Command line:**
```bash
xcrun altool --upload-app \
  --type ios \
  --file build/ios/ipa/qauto_cmms.ipa \
  --apiKey YOUR_API_KEY \
  --apiIssuer YOUR_ISSUER_ID
```

### 2.5 App Store Connect Setup

1. **Create app** in [App Store Connect](https://appstoreconnect.apple.com)
2. **App Information:**
   - Name: `Be Electric`
   - Primary language: English (U.S.)
   - Bundle ID: `com.beelectric.app`
   - SKU: `beelectric-cmms`
   - Primary category: Business
   - Secondary category: Utilities
3. **Pricing:** Free (or as needed)
4. **App Privacy (required):**

   | Data Type | Collected | Linked to Identity | Used for Tracking |
   |-----------|-----------|-------------------|-------------------|
   | Name | Yes | Yes | No |
   | Email | Yes | Yes | No |
   | Photos | Yes | No | No |
   | Device ID | Yes | No | No |
   | Push Token | Yes | No | No |
   | Usage Data | Yes | No | No |

5. **Screenshots:** iPhone 6.7" (1290×2796), iPhone 6.5" (1284×2778), iPad 12.9" (2048×2732)
6. **App Review Information:**
   - Demo account credentials (for Apple reviewer to log in and test)
   - Notes: "This is an enterprise CMMS app for EV charger technicians. Requires an account created by an admin."
7. **Export Compliance:** In App Store Connect, for “Does your app use encryption?” you can answer using standard HTTPS only; `ITSAppUsesNonExemptEncryption` is set to `false` in `Info.plist` for the same exemption category.
8. **TestFlight:** Upload the build, add internal testers, install on physical devices, then submit for **Beta App Review** (if using external testers) or promote to App Store when ready.

### 2.6 iOS build checklist

- [ ] `ExportOptions.plist` `teamID` updated
- [ ] `pod install` completed without errors
- [ ] Archive or `flutter build ipa` succeeds on Release
- [ ] Push: APNs key uploaded to OneSignal; test notification on a physical iPhone
- [ ] Privacy Policy URL set in App Store Connect (host `PRIVACY_POLICY.md` or equivalent)
- [ ] App Privacy questionnaire completed (name, email, photos, device ID, push token, etc.)
- [ ] Screenshots for required device sizes uploaded
- [ ] Demo account for App Review (technician or requestor) in “App Review Information”

---

## 3. Common for Both Stores

### 3.1 App Icon

Already configured via `flutter_launcher_icons` using `assets/images/beelectric-insignia.png`.

To regenerate after changing the source image:
```bash
dart run flutter_launcher_icons
```

### 3.2 Versioning Strategy

| Release | pubspec.yaml | Notes |
|---------|-------------|-------|
| First release | `1.0.0+1` | Initial submission |
| Bug fix | `1.0.1+2` | Bump patch + build number |
| Feature update | `1.1.0+3` | Bump minor + build number |
| Major update | `2.0.0+4` | Bump major + build number |

**Both stores require the build number (+N) to be strictly greater than the previous upload.**

### 3.3 Environment Variables for Production

Always pass production values via `--dart-define`:

```bash
--dart-define=SUPABASE_URL=https://sdhqjyjeczrbnvukrmny.supabase.co
--dart-define=SUPABASE_ANON_KEY=YOUR_PRODUCTION_KEY
--dart-define=ONE_SIGNAL_APP_ID=YOUR_ONESIGNAL_APP_ID
```

The defaults in `app_config.dart` are for development only.

### 3.4 Push Notification Setup

See `docs/ONESIGNAL_SETUP.md` for full OneSignal configuration:
- Android: FCM Server Key in OneSignal dashboard
- iOS: APNs Key (.p8) uploaded to OneSignal dashboard
- Supabase Edge Function: `send-push-notification` deployed with secrets

### 3.5 Testing Before Submission

- [ ] Release build installs and runs on physical device
- [ ] Login works (technician and requestor roles)
- [ ] Work orders load and display correctly
- [ ] Photos load (including Supabase Storage images)
- [ ] Push notifications arrive when work order is assigned
- [ ] Completion flow works (photos, signatures, corrective actions)
- [ ] App icon and name display correctly
- [ ] No crash on cold start

### 3.6 Screenshots Needed

| Platform | Size | Count |
|----------|------|-------|
| Android Phone | 1080×1920 or higher | 2–8 |
| Android Tablet (optional) | 1200×1920 | 1–8 |
| iPhone 6.7" | 1290×2796 | 3–10 |
| iPhone 6.5" | 1284×2778 | 3–10 |
| iPad 12.9" (if supporting iPad) | 2048×2732 | 3–10 |

**Suggested screenshots:**
1. Login screen
2. Work orders list
3. Work order detail with photos
4. Completion form with signature
5. Dashboard / analytics

---

## 4. Quick Command Reference

```bash
# ── Android ──────────────────────────────────────
# Build release AAB (for Play Store)
flutter build appbundle --release --dart-define=ONE_SIGNAL_APP_ID=xxx

# Build release APK (for sideloading)
flutter build apk --release --dart-define=ONE_SIGNAL_APP_ID=xxx

# ── iOS (macOS only) ────────────────────────────
# Install pods
cd ios && pod install && cd ..

# Build release IPA (for App Store)
flutter build ipa --release \
  --dart-define=ONE_SIGNAL_APP_ID=xxx \
  --export-options-plist=ios/ExportOptions.plist

# ── Both ─────────────────────────────────────────
# Regenerate app icons
dart run flutter_launcher_icons

# Bump version (edit pubspec.yaml, then)
flutter clean
```

---

## 5. Post-Launch

- **Monitor crashes:** Consider adding Sentry or Firebase Crashlytics
- **Analytics:** Track feature usage to prioritize improvements
- **Updates:** Bump version, rebuild, upload new AAB/IPA
- **Respond to reviews:** Both stores surface user feedback
