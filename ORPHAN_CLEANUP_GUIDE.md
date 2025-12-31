# Orphan Cleanup & Data Validation Guide

This repo now contains guardrails that keep Firestore data aligned, plus a
utility to purge legacy “orphaned” work orders / PM tasks. Follow these steps
whenever you reset or migrate the database.

## 1. Seed Users & Assets First
1. Clear the existing collections (`users`, `assets`, `work_orders`, `pm_tasks`)
   in Firestore.
2. Import all users and assets before creating work orders or PM tasks. The app
   validates references, so missing base records will cause writes to fail.

## 2. Authentication Is Required
All reference validation and auto-recovery calls invoke Firestore. Ensure the
app is authenticated (Firebase Auth service account or signed-in user) before
launching. Without auth, the client can’t verify IDs and will refuse writes.

## 3. Run the Orphan Cleanup (Optional)
After reseeding, you can scan for lingering orphans in either of two ways:

- **Settings → Data Maintenance (admins only):** open the Settings tab,
  scroll to the “Data Maintenance” card, and tap **Dry Run** or
  **Delete Orphans**.
- **Admin Dashboard button:** open the Admin menu (⋮) and choose
  `Orphan Cleanup (Dry Run)` to see a report or
  `Orphan Cleanup (Delete)` to purge orphaned work orders/PM tasks.
- **Programmatically:** call `OrphanCleanupService.run()` from a script or
  debug action:

```dart
final report = await OrphanCleanupService.instance.run(delete: true);
debugPrint('Deleted ${report.deletedWorkOrderIds.length} work orders');
```

- Set `delete: false` to perform a dry run.
- The service deletes work orders / PM tasks whose requestor, technicians, or
  asset IDs are missing in Firestore.

## 4. Runtime Protections
- `UnifiedDataService.validateReferences` is called before every work order /
  PM task write. A descriptive exception is thrown if a user or asset ID does
  not exist.
- Real-time streams automatically fetch any missing user/asset documents the
  moment a work order references them, keeping the UI hydrated.

## 5. Monitor Logs
If a mismatch sneaks in (for example, due to a backend bypass), the provider
logs the missing ID and the validation helper rejects the write. Treat those
warnings as blocking issues and fix the source immediately.

Following this checklist keeps the environment clean and prevents the legacy
“Unassigned / asset not found” noise from resurfacing in production.

