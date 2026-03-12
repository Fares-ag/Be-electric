-- ============================================================
-- DIAGNOSE 403 on work_orders
-- Run each block separately in SQL Editor and share the output.
-- ============================================================

-- Block 1: List all rows in admin_users (tells us exactly what emails are in there)
SELECT email, is_admin, is_manager, updated_at
FROM public.admin_users
ORDER BY updated_at DESC;

-- Block 2: List all auth users (tells us the exact email used to log in)
SELECT id, email, created_at, last_sign_in_at
FROM auth.users
ORDER BY last_sign_in_at DESC NULLS LAST
LIMIT 10;

-- Block 3: Check if emails match between auth.users and admin_users
SELECT
  au.email AS auth_email,
  au.id    AS auth_id,
  adm.email AS admin_users_email,
  adm.is_admin,
  adm.is_manager
FROM auth.users au
LEFT JOIN public.admin_users adm ON lower(trim(adm.email)) = lower(trim(au.email))
ORDER BY au.last_sign_in_at DESC NULLS LAST
LIMIT 10;
