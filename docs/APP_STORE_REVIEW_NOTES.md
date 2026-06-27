# App Store Review — paste into App Store Connect

Copy the sections below into **App Review Information** when submitting **Be Electric Requestor**.

---

## Demo account (required)

| Field | Value |
|-------|--------|
| Username | `REPLACE_WITH_REVIEWER_EMAIL` |
| Password | `REPLACE_WITH_REVIEWER_PASSWORD` |

**Pre-submission checklist for this account:**

- [ ] Role is `requestor` in Supabase `users` table
- [ ] User is linked to a **company** with `companyId`
- [ ] Company has at least one **Siemens** and one **Kostad** charger asset (manufacturer set correctly)
- [ ] Login tested on a physical iPhone with the **release IPA** (not debug)

---

## How to test the app

1. Open the app and wait for the splash screen (~3 seconds).
2. Log in with the demo credentials above.
3. On the home screen, tap **Siemens** or **Kostad** to start a maintenance request.
4. Select a charger, describe the issue, optionally attach a photo, and submit.
5. Tap **More (⋯)** → **View My Requests** to see submitted requests and status.
6. Tap **Profile** for account info, Privacy Policy, and account deletion request.

---

## B2B / account creation

This is a **B2B app** for Be Electric clients. Users **cannot self-register**. Accounts are created by the customer’s administrator. The login screen states: “Accounts are created by your organization administrator.”

---

## Password reset

“Forgot password?” sends a reset email via Supabase. The user completes password reset by opening the **link in the email** (web page), not inside the app.

Ensure Supabase **custom SMTP** and **Site URL** are configured before submission so reviewers receive the email.

---

## Push / SMS / email notifications

This version does **not** use remote push notifications, SMS, or email alerts. In-app notification list is available; empty state is normal until request status changes.

Do **not** mention push notifications in App Store description or screenshots.

---

## Account deletion (Guideline 5.1.1(v))

Users can start account deletion from **Profile → Request account deletion**, which opens a pre-filled email to support. Employers may also remove accounts via their administrator.

---

## App Privacy (App Store Connect questionnaire)

Declare (linked to user, not used for tracking):

- **Contact Info:** Email, name, phone (optional on request form)
- **User Content:** Photos attached to maintenance requests, problem descriptions
- **Identifiers:** User ID for authentication and work order association

**Tracking:** No  
**App Tracking Transparency:** Not used

---

## Support & legal URLs

Set the same URLs in App Store Connect and in production `--dart-define`:

- Privacy Policy URL → `PRIVACY_POLICY_URL`
- Support URL → `SUPPORT_URL`
- Support email → `SUPPORT_EMAIL`

---

## Encryption

App uses standard HTTPS/TLS only. `ITSAppUsesNonExemptEncryption` is `false`.
