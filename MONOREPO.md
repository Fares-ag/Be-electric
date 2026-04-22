# Monorepo layout

| Path | Role |
|------|------|
| `packages/cmms_core` | Shared Dart package: models, services, Supabase, providers, screens, assets. |
| `apps/requestor_cmms` | Store build for **requestor** users only. |
| `apps/technician_cmms` | Store build for **technician / manager / admin** users. |

## Run

```bash
cd apps/requestor_cmms && flutter pub get && flutter run
```

```bash
cd apps/technician_cmms && flutter pub get && flutter run
```

## Develop against the library only

```bash
cd packages/cmms_core && flutter pub get && flutter run
```

That runs the default entry (requestor) from `cmms_core/lib/main.dart` for quick iteration.

## Tests

```bash
cd packages/cmms_core && flutter test
cd apps/requestor_cmms && flutter test
cd apps/technician_cmms && flutter test
```

## Optional: Melos

If you use [Melos](https://melos.invertase.dev/), from the repo root run `melos bootstrap` to link packages.

## Images and `assets/`

UI images live under `packages/cmms_core/assets/`. The shell apps do **not** copy those files to their own `assets/` folder, so in code you must load them with `package: kCmmsCoreAssetPackage` (see `cmms_core/lib/utils/cmms_package_assets.dart`) on `Image.asset` and `AssetImage`. Otherwise Flutter looks in the **shell** bundle only and logos/backgrounds appear missing.

## iOS / Android

Each app has its own `applicationId` / bundle id (`com.beelectric.cmms.requestor_cmms` and `com.beelectric.cmms.technician_cmms`). Change them in each app’s `android/` and `ios/` when you register separate store listings.

## Role behaviour

- **Requestor app:** only the `requestor` role is allowed; other roles see a sign-out message.
- **Technician app:** `technician`, `manager`, and `admin` get the same flows as before; `requestor` is directed to the requestor app.

Configuration (Supabase, OneSignal) still comes from `cmms_core`’s `AppConfig` and `--dart-define=...` flags.
