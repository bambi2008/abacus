# Abacus — App Store Launch Checklist

Status as of the pre-submission audit (2026-07-11). Items are grouped by
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
- [x] Paywall now shows the App-Store-required auto-renewal disclosure
      (renewal terms, cancel path) and functional Terms of Use + Privacy
      Policy links. Settings has a Legal section with the same links.
- [x] `ITSAppUsesNonExemptEncryption = false` in Info.plist so the export
      -compliance question is auto-answered on every upload.
- [x] Terms of Use written (`docs/legal/terms-of-use.md`); Privacy Policy
      dated and reconciled with the "v1 collects nothing" posture.

## Needs YOUR input (fill, then it's submittable)

- [ ] **Legal name / publisher name** — fill `[YOUR NAME / COMPANY NAME]`
      in `docs/legal/privacy-policy.md` and `docs/legal/terms-of-use.md`.
- [ ] **Public support/contact email** — fill `[YOUR CONTACT EMAIL]` in
      both legal docs. Apple also requires a support URL or email in the
      listing.
- [ ] **Host the two legal pages at public URLs** and set them in
      `app/lib/config/constants.dart` → `LegalLinks`. Current placeholders
      assume GitHub Pages under `bambi2008.github.io/abacus/`. Zero-cost
      path: render the two markdown files to HTML, publish via GitHub Pages
      from a public repo/branch, confirm both URLs load in a browser.
- [ ] **Confirm v1 ships with analytics + cloud buddy-sync OFF** (the
      recommended default). This is automatic as long as the release build
      does **not** pass `--dart-define=POSTHOG_API_KEY=...` or
      `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`.
      Shipping off means: App Privacy nutrition label = "Data Not
      Collected", no anonymous accounts created, no account-deletion
      obligation (5.1.1(v)). Buddy sync degrades to its local-only mode.

## App Store Connect — account owner steps

- [ ] Apple Developer Program membership active ($99/yr).
- [ ] Create the app record in App Store Connect. Bundle ID
      `com.abacus.abacus` is already set in the Xcode project.
- [ ] Create two in-app purchase products matching
      `app/lib/config/constants.dart` → `ProductIds`:
      - `com.abacus.pro.lifetime` — Non-Consumable.
      - `com.abacus.pro.monthly` — Auto-Renewable Subscription (needs a
        subscription group).
      Until these exist and are "Ready to Submit", tapping a paid plan in a
      **release** build does nothing (the debug-only mock purchase is
      gated on `kDebugMode`) — this is a guaranteed rejection if shipped
      without them.
- [ ] Set the "License Agreement" field to your Terms of Use (or use
      Apple's standard EULA), and add the Privacy Policy URL.
- [ ] App Privacy nutrition label — with v1 shipping keys-off, declare
      "Data Not Collected".
- [ ] Metadata: name, subtitle, promotional text, description, keywords,
      support URL, category (Finance), age rating, and screenshots (6.7"
      is mandatory; 6.5"/5.5" as needed). ASO copy drafts: see
      `docs/promotion-plan.md`.

## Build & test — before submitting

- [ ] Build a release IPA on macOS/CI (Codemagic or a Mac). App is
      developed on Windows; iOS release builds need macOS.
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
      - [ ] IAP sandbox: buy Lifetime, buy Monthly, and **Restore** all
            unlock Pro; Pro-gated "Spending insight" shows real content.
      - [ ] Pro-locked state before purchase looks correct.
      - [ ] Streak freeze auto-applies; boss-battle bars show the right
            dollar limits and green/orange/red states.
      - [ ] Paywall legal links open; auto-renewal disclosure is visible.

## Deliberately deferred to v1.1 (not blockers, documented)

- Local reminder notifications (needs on-device scheduling + permission
  flow, built and tested on a real device).
- Optional: re-enable PostHog analytics / Supabase buddy-sync once you're
  ready to take on the App Privacy disclosures and account-deletion UI
  that come with them.
