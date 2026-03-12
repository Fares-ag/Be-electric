-- Add the Be Electric admin so RLS get_my_role() returns 'admin' and work_orders/data are visible.
-- RLS does NOT use auth.users.raw_user_meta_data.role; it only checks public.users and public.admin_users.
DO $$
BEGIN
  INSERT INTO public.admin_users (email, is_admin, is_manager, updated_at)
  VALUES ('beelectric@q-auto.com', true, true, now());
EXCEPTION
  WHEN unique_violation THEN
    UPDATE public.admin_users
    SET is_admin = true, is_manager = true, updated_at = now()
    WHERE email = 'beelectric@q-auto.com';
END $$;
