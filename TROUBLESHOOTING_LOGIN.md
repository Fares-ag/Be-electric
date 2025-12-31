# Troubleshooting Login Issues

## Issue: User exists in database but can't log in

### Most Common Cause: No Password Set

When you create a user via SQL in the `users` table, they still need a **password set in Supabase Auth** to log in.

### Solution 1: Set Password via Supabase Dashboard (Recommended)

1. Go to your Supabase Dashboard
2. Navigate to **Authentication** → **Users**
3. Find the user `zmohammed@q-auto.com`
4. Click on the user to open their details
5. Click **"Send password reset email"** or **"Reset password"**
6. The user will receive an email to set their password

### Solution 2: Use Password Reset from App

1. On the login screen, click **"Forgot Password"** (if available)
2. Enter `zmohammed@q-auto.com`
3. Check email for password reset link
4. Set a new password

### Solution 3: Verify User Setup

Run this SQL query in Supabase to verify the user exists:

```sql
-- Check if user exists in users table
SELECT id, email, name, role, "companyId", "isActive" 
FROM users 
WHERE email = 'zmohammed@q-auto.com';

-- Check if user exists in Supabase Auth
SELECT id, email, confirmed_at, encrypted_password IS NOT NULL as has_password
FROM auth.users 
WHERE email = 'zmohammed@q-auto.com';
```

### Common Issues:

1. **No password**: `has_password` will be `false` - user needs to set password
2. **Email mismatch**: Check for typos or case differences
3. **User not confirmed**: `confirmed_at` should not be NULL
4. **User inactive**: Check `isActive` in users table is `true`
5. **RLS blocking**: Check RLS policies allow the user to read their own record

### Debug Steps:

1. Check app logs for error messages:
   - "Sign in failed" = Password issue
   - "User not authenticated" = Auth state issue
   - "User not found" = User doesn't exist in users table

2. Verify the user ID matches:
   - Supabase Auth ID: `061a29db-0771-4ce5-b664-dc6562437bcb`
   - Users table ID: Should match or be a readable ID like `USER-zmohammed`

3. Test with a known working account to verify the login flow works

