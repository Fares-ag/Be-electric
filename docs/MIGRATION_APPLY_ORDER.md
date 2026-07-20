# Migration apply order (Flutter ↔ React convergence)

**Do not apply to production without explicit approval.**

## Single checklist (staging → prod)

1. Text-id RPCs (if not already live)  
   - `20260720120000_fix_update_work_order_assignees_text_id`  
   - `20260720130000_fix_upsert_work_order_text_id` (or Flutter `20260706120000`)
2. Requestor WO guards (React SSOT; mirrored into Flutter `supabase/migrations/`)  
   - `20260701120000_requestor_upsert_field_guard`  
   - `20260702120000_requestor_work_order_update_guard`  
   - `20260703120000_requestor_signoff_trigger_fix`
3. Notifications INSERT harden — `20260701130000_notifications_insert_admin_or_self`
4. Flutter-origin contracts (add to React if missing on remote)  
   - inventory technician SELECT  
   - orphan technician assignments (+ extend `pm_task_occurrences` when available)  
   - PM requestor read/confirm + pm_tasks tech UPDATE
5. Realtime publication — `20260720150000_enable_admin_tech_realtime`
6. **Security / tenant / storage** — `20260720160000_security_role_tenant_storage`  
   - Flutter: `scripts/sql/migrate_security_role_tenant_storage.sql`  
   - React: `supabase/migrations/20260720160000_security_role_tenant_storage.sql`

## Verify (run after apply)

```sql
SELECT public.get_my_role() IS DISTINCT FROM NULL AS role_ok; -- as active admin

SELECT tablename, policyname FROM pg_policies
WHERE tablename IN ('assets','companies') ORDER BY 1,2;

SELECT policyname, with_check FROM pg_policies
WHERE schemaname='storage' AND tablename='objects' AND policyname LIKE '%upload%';

SELECT tablename FROM pg_publication_tables
WHERE pubname='supabase_realtime' AND schemaname='public' ORDER BY 1;

SELECT p.proname, pg_get_function_identity_arguments(p.oid)
FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
WHERE n.nspname='public' AND p.proname IN ('update_work_order_assignees','upsert_work_order','is_true_admin');
```

Also use Flutter wrappers: `scripts/sql/verify_technician_backend.sql`, `verify_requestor_backend.sql`, `verify_orphan_technician_assignments.sql`.
