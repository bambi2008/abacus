# Pocklume — App Store Launch Checklist

Status as of the Pocklume brand migration (2026-07-19). Items are grouped by
who has to do them. Everything under "Code — done" is committed; the
"Needs your input / account access" items can only be done by the account
owner and are what actually gate submission now.

## Code — done in this pass

- [x] Real custom app icon (replaced the default Flutter icon) — all
      iOS/Android/web sizes generated from `assets/app-icon-1024.png`.
- [x] Web manifest/title/description off the "A new Flutter project"
      defaults and onto the real app identity.
- [x] Color system reworked to distinct per-concept roles; no more
      everything-is-green; nav bar / chips no longer mis-tinted.
- [x] Typography consolidated into a named scale.
- [x] Removed the fake "Enable Reminders" onboarding page and the dead
      reminder-time settings tile (the app scheduled no notifications, so
      both promised a feature that didn't exist). Replaced with an honest
      "You're all set" completion page. **Reminders are a deliberate v1.1
      fast-follow** (needs real on-device notification scheduling +
      permission work).
- [x] Paywall offers one transparent non-consumable Founding Lifetime
      purchase, restores through RevenueCat, and only unlocks after the
      verified `pro` entitlement is active. No subscription ships in v1.
- [x] Usage analytics SDK removed from the iOS launch. Buddy sync is
      disabled until the user sees and accepts the data disclosure.
- [x] App privacy manifest added to the iOS target. It conservatively
      declares user ID, purchase history, and buddy-check-in interaction for
      App Functionality; none is used for tracking.
- [x] Transaction history is searchable and editable; full CSV export no
      longer silently limits data to 365 days.
- [x] A completed no-spend day now counts as an intentional daily check-in.
- [x] National-spending comparisons are labelled as selected benchmarks,
      not as money actually saved.
- [x] `ITSAppUsesNonExemptEncryption = false` in Info.plist so the export
      -compliance question is auto-answered on every upload.
- [x] Terms of Use written (`docs/legal/terms-of-use.md`); Privacy Policy
      dated and reconciled with the "v1 collects nothing" posture.
- [x] Product identity migrated from the working name to **Pocklume**;
      Apple App ID `com.pocklume.app` is registered and matches the project.
- [x] RevenueCat dependency lock regenerated; `flutter analyze` is clean and
      all 68 automated tests pass after the iOS purchase integration.

## Needs YOUR input (fill, then it's submittable)

- [x] Legal publisher and support email are present in both legal documents.
- [ ] **Host the two legal pages at public URLs** and set them in
      `app/lib/config/constants.dart` → `LegalLinks`. Current placeholders
      assume GitHub Pages under `bambi2008.github.io/abacus/`. Zero-cost
      path: render the two markdown files to HTML, publish via GitHub Pages
      from a public repo/branch, confirm both URLs load in a browser.
- [ ] **Supabase buddy-sync ON, analytics absent for v1.** The release build
      must pass
      `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`.
      Consequences handled in code: an in-app "Delete my savings-buddy
      data" control exists (Settings) for Guideline 5.1.1(v); the privacy
      policy discloses the anonymous account + the three synced fields.
- [ ] **Set up the Supabase project** (see `app/supabase/schema.sql`):
      create a project → SQL Editor → paste and run `schema.sql` (creates
      the two tables, RLS policies, the join + delete RPCs, and Realtime) →
      Authentication → Providers → **enable Anonymous sign-ins** → copy the
      Project URL and the anon/publishable key into the release build's
      dart-defines above. Verify buddy create/join/sync works two-device in
      TestFlight before submitting.

## App Store Connect — account owner steps

- [ ] Apple Developer Program membership active ($99/yr).
- [x] Register Apple App ID `com.pocklume.app`; it is already set in Xcode.
- [ ] Create the Pocklume app record in App Store Connect using that Bundle ID.
- [ ] Create one in-app purchase product matching
      `app/lib/config/constants.dart` → `ProductIds`:
      - `com.pocklume.pro.lifetime` — Non-Consumable, recommended launch price
        **US$19.99**.
- [ ] Create a RevenueCat project, connect App Store Connect, import the
      product above, create entitlement `pro`, attach the product, and pass
      the public iOS SDK key as
      `--dart-define=REVENUECAT_APPLE_API_KEY=...` in the release build.
- [ ] Set the "License Agreement" field to your Terms of Use (or use
      Apple's standard EULA), and add the Privacy Policy URL.
- [ ] App Privacy nutrition label — match the built privacy manifest and the
      final RevenueCat privacy report: User ID, Purchase History, and Product
      Interaction (the buddy date/check-in signal), used for App Functionality,
      linked to the app's pseudonymous identity, and **not used for tracking**.
      Payment-card information is entered outside the app and is not collected
      by Pocklume. Note the in-app account-deletion path.
- [ ] Metadata: name, subtitle, promotional text, description, keywords,
      support URL, category (Finance), age rating, and screenshots (6.7"
      is mandatory; 6.5"/5.5" as needed). ASO copy drafts: see
      `docs/promotion-plan.md`.

## Build & test — before submitting

- [ ] Build a release IPA in Xcode on macOS. The launch target is iPhone-only,
      portrait, iOS 13+; iPad and Android are deferred.
- [ ] **TestFlight on a real device — full regression** (nothing below has
      been device-verified; the web preview never rendered this session):
      - [ ] Fresh install → onboarding shows the **6** starter categories
            (Dining Out, Snacks & Drinks, Taxi & Rideshare, Clothing &
            Shopping, Subscriptions, Fun & Entertainment). Note: category
            seeding runs once at onboarding, so test on a **clean install**,
            not an overwrite of an older build.
      - [ ] Log-expense sheet shows all 6 categories, plus the **voice**
            (mic) and **photo/receipt-scan** (camera) buttons — these are
            hidden on web by design but should appear on device.
      - [ ] Voice input: mic → speak → amount/category prefilled, resolves
            (has a 20s timeout so it can't spin forever).
      - [ ] Receipt scan: camera/library → "Use Photo" returns and prefills
            (the nested-modal hang fix + timeout).
      - [ ] IAP sandbox: buy Founding Lifetime, restart offline/online, refund
            or revoke in sandbox, and **Restore** on a clean install. Pro must
            follow RevenueCat's verified `pro` entitlement in every case.
      - [ ] Pro-locked state before purchase looks correct.
      - [ ] Streak freeze auto-applies; boss-battle bars show the right
            dollar limits and green/orange/red states.
      - [ ] Paywall legal links open; one-time purchase and restore wording
            is visible; there is no subscription language.

## Deliberately deferred to v1.1 (not blockers, documented)

- Local reminder notifications (needs on-device scheduling + permission
  flow, built and tested on a real device).
- Optional analytics only after a separate privacy review, policy update,
  consent decision, and App Privacy declaration.
- Android release after the iOS retention, purchase, crash, and support data
  justify maintaining a second platform.
