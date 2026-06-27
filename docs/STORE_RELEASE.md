# Be Electric — App Store & Google Play release guide

Monorepo layout: shared code in `packages/cmms_core`, binaries in `apps/requestor_cmms` and `apps/technician_cmms`. Treat those as **two separate store listings** (different bundle IDs / package names).

---

## App Store Connect — one-page checklist (iOS)

Use this list right before you upload each `.ipa`. Duplicate it mentally for **both** apps (requestor + technician) — same answers, different bundle IDs and screenshots.

| Step | Action |
|------|--------|
| 1 | **Apple Developer:** Register both bundle IDs (`com.beelectric.cmms.requestorCmms`, `com.beelectric.cmms.technicianCmms`). Do **not** enable Push Notifications unless you add APNs again later. |
| 2 | **Xcode:** Open `ios/Runner.xcworkspace` (never `.xcodeproj` alone). Runner → Signing & Capabilities → **Team** = your team, **Automatic** signing. Remove any leftover “Push Notifications” capability if Xcode added it historically. |
| 3 | **`ExportOptions.plist`:** Replace `YOUR_APPLE_TEAM_ID` with your [10-character Team ID](https://developer.apple.com/account#MembershipDetailsCard). |
| 4 | **Build:** From repo root, `./scripts/build_production.sh requestor ipa` and `./scripts/build_production.sh technician ipa` (or `flutter build ipa` per §2.3). Bump `pubspec.yaml` `version: x.y.z+build` before **every** re-upload (`+build` must increase). |
| 5 | **Upload:** Transporter, Xcode Organizer, or `xcrun altool` / `notarytool` flow you already use. |
| 6 | **App Store Connect → App Privacy:** **App Tracking Transparency:** No (you don’t use IDFA for tracking). **Data collection** — typical answers for this CMMS: **Contact Info** (name, email) — linked to user, app functionality / account; **User Content** (photos) — maintenance attachments, not used for tracking. **Tracking:** No. Adjust if you add analytics SDKs or change behavior. |
| 7 | **Encryption / export compliance:** App uses standard TLS only. `ITSAppUsesNonExemptEncryption` is `false` in `Info.plist`; answer App Store Connect questions consistently (“only standard encryption”). |
| 8 | **Review notes:** Demo Supabase account for a reviewer (technician + requestor if both ship). Explain login is required; mention EV charger CMMS context. |
| 9 | **Screenshots & metadata:** Required device sizes, age rating, support URL, privacy policy URL (host `PRIVACY_POLICY.md` or equivalent). |
|10 | **Capabilities sanity check:** This repo does **not** ship remote push (OneSignal removed). `Info.plist` has no `UIBackgroundModes` for push; entitlements are empty. If App Review asks about push, answer that remote notifications are not used in this build. |

---

## Prerequisites

| Item | Details |
|------|---------|
| **Apple Developer Account** | $99/year — [developer.apple.com](https://developer.apple.com) |
| **Google Play Developer Account** | $25 one-time — [play.google.com/console](https://play.google.com/console) |
| **macOS with current Xcode** | Required for iOS archive / IPA |
| **Flutter SDK** | 3.x stable |
| **Privacy policy URL** | Public URL (required by both stores) |

---

## 1. Android — Google Play

### 1.1 Keystore & signing

Copy `android/key.properties.example` → `android/key.properties` (never commit). Create a keystore if you do not have one.

### 1.2 Build AAB (Play Store)

```bash
cd apps/requestor_cmms   # or technician_cmms

flutter clean
flutter pub get
flutter build appbundle --release \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### 1.3 Version bumping

In each app’s `pubspec.yaml`:

```yaml
version: 1.0.0+1   # name + build number (must increase for every upload)
```

### 1.4 Play Console — Data safety

Declare data you actually collect (e.g. account email, name, photos attached to work orders). **Push tokens:** only if you add FCM push later. Encryption in transit: yes. No IDFA unless you add an ads SDK.

---

## 2. iOS — Apple App Store

### 2.0 Repo facts (current)

| Item | Requestor | Technician |
|------|-----------|------------|
| App folder | `apps/requestor_cmms` | `apps/technician_cmms` |
| Bundle ID | `com.beelectric.cmms.requestorCmms` | `com.beelectric.cmms.technicianCmms` |
| Display name | Be Electric Requestor | Be Electric Tech |
| Min iOS | 13.0 (`Podfile` + Xcode) | 13.0 |
| Push (APNs) | **Not used** (no entitlement) | **Not used** |
| `Info.plist` usage | Camera, Photo Library (read for attachments) | Same |
| Privacy manifest | `ios/Runner/PrivacyInfo.xcprivacy` | Same |
| Export compliance | `ITSAppUsesNonExemptEncryption` = false | Same |

Regenerate launcher icons after changing `packages/cmms_core/pubspec.yaml` `flutter_launcher_icons.image_path`:

```bash
cd packages/cmms_core && dart run flutter_launcher_icons
```

### 2.1 Xcode (macOS)

1. Open `apps/<app>/ios/Runner.xcworkspace`.
2. Runner → Signing & Capabilities: select **Team**, **Automatic** signing.
3. `cd ios && pod install` after dependency changes.

### 2.2 Build IPA

```bash
cd apps/requestor_cmms   # or technician_cmms

flutter clean
flutter pub get
cd ios && pod install && cd ..

flutter build ipa --release \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY \
  --export-options-plist=ios/ExportOptions.plist
```

**Important:** Set real `teamID` in `ios/ExportOptions.plist`.

### 2.3 Upload

Use Xcode Organizer, **Transporter**, or CLI upload with an App Store Connect API key.

### 2.4 iOS checklist (detail)

- [ ] `ExportOptions.plist` `teamID` is real (not placeholder).
- [ ] `pod install` succeeds; open **workspace** in Xcode.
- [ ] Release archive / `flutter build ipa` succeeds with your Team selected.
- [ ] No Push capability unless you intentionally re-enable APNs.
- [ ] Privacy Policy URL in App Store Connect.
- [ ] App Privacy questionnaire completed (no tracking unless you add it).
- [ ] Screenshots for required device sizes.
- [ ] Demo credentials in App Review notes.

---

## 3. Common

### 3.1 Production defines

```bash
--dart-define=SUPABASE_URL=https://your-project.supabase.co
--dart-define=SUPABASE_ANON_KEY=your_anon_key
--dart-define=PRIVACY_POLICY_URL=https://your-domain.com/privacy
--dart-define=TERMS_OF_SERVICE_URL=https://your-domain.com/terms
--dart-define=SUPPORT_URL=https://your-domain.com/support
--dart-define=SUPPORT_EMAIL=support@your-domain.com
```

Or copy `scripts/defines.production.json.example` → `scripts/defines.production.json` with real values (never commit secrets).

### 3.2 Repo scripts

From repo root:

```bash
./scripts/build_production.sh requestor ipa
./scripts/build_production.sh technician ipa
```

Uses `scripts/defines.production.json` if present (see `defines.production.json.example`). Never commit secrets.

### 3.3 Optional: push later

If you add APNs again: re-add **Push Notifications** in Apple Developer, restore `aps-environment` entitlements, add `UIBackgroundModes` → `remote-notification` only when needed, and update App Privacy for push-related data.

Historical OneSignal docs (if you revive it): `docs/ONESIGNAL_SETUP.md`.

### 3.4 Pre-submission smoke test

- [ ] Release build installs on a physical device.
- [ ] Login and role-appropriate flows work.
- [ ] Photos / attachments work end-to-end.
- [ ] App icon and display names correct.
- [ ] No debug-only banners in release.

---

## 4. Quick command reference

```bash
# iOS — install pods
cd apps/requestor_cmms/ios && pod install && cd ../..

# iOS — IPA (after Team + ExportOptions.plist)
cd apps/requestor_cmms && flutter build ipa --release --export-options-plist=ios/ExportOptions.plist

# Android — AAB
cd apps/requestor_cmms && flutter build appbundle --release

# Icons (from cmms_core)
cd packages/cmms_core && dart run flutter_launcher_icons
```

---

## 5. Post-launch

- Monitor crashes (e.g. Xcode Organizer, or add a crash reporter if needed).
- Bump `version` in `pubspec.yaml` for every store upload.
- Reply to store reviews.
