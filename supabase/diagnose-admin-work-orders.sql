-- ============================================================
-- Why don't requestor-created work orders show in the admin portal?
-- Run in Supabase Dashboard → SQL Editor (as a user with DB access).
-- ============================================================
-- Replace YOUR_ADMIN_EMAIL with the admin's auth email to check that user.
-- Or run the "current session" block while logged in as that admin in the app.

-- ---------- Option A: Check a specific email ----------
DO $$
DECLARE
  v_email text := 'YOUR_ADMIN_EMAIL';  -- e.g. 'beelectric@q-auto.com'
  v_uid uuid;
  v_in_users boolean;
  v_users_role text;
  v_in_admin_users boolean;
  v_is_admin_or_manager boolean;
  v_wo_count bigint;
BEGIN
  SELECT id INTO v_uid FROM auth.users WHERE email = v_email LIMIT 1;
  IF v_uid IS NULL THEN
    RAISE NOTICE 'No auth.users row for email: %', v_email;
    RETURN;
  END IF;

  SELECT EXISTS (SELECT 1 FROM public.users WHERE id = v_uid), (SELECT role::text FROM public.users WHERE id = v_uid LIMIT 1)
  INTO v_in_users, v_users_role;

  SELECT EXISTS (SELECT 1 FROM public.admin_users WHERE email = v_email),
         EXISTS (SELECT 1 FROM public.admin_users WHERE email = v_email AND (is_admin OR is_manager))
  INTO v_in_admin_users, v_is_admin_or_manager;

  SELECT count(*) INTO v_wo_count FROM public.work_orders;

  RAISE NOTICE 'User: % (id: %)', v_email, v_uid;
  RAISE NOTICE '  In public.users: %, role: %', v_in_users, v_users_role;
  RAISE NOTICE '  In public.admin_users: %, is_admin OR is_manager: %', v_in_admin_users, v_is_admin_or_manager;
  RAISE NOTICE '  get_my_role() when running as this user would check admin_users first → admin if in admin_users with is_admin/is_manager.';
  RAISE NOTICE '  Total work_orders in DB: %', v_wo_count;
  IF NOT v_is_admin_or_manager THEN
    RAISE NOTICE '  → FIX: Add this email to public.admin_users with is_admin = true or is_manager = true.';
  END IF;
END $$;

-- ---------- Option B: What does get_my_role() return for a given email? ----------
-- (Run as superuser; replaces auth.uid() with the user's id for that email.)
-- SELECT public.get_my_role();  -- only works in the session of the logged-in user.

-- ---------- Option C: List admin_users (so you can confirm admin emails) ----------
-- SELECT email, is_admin, is_manager FROM public.admin_users ORDER BY email;
