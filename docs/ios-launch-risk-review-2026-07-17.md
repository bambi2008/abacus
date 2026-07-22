# Pocklume iOS launch risk review

_Reviewed July 17 and updated for the Pocklume migration on July 19, 2026.
Product/engineering review, not legal advice._

## Launch decision

**No-go for App Review today; suitable for a TestFlight release after the
account-side blockers below are closed.** The prior implementation had
purchase-verification, privacy-consent, history-integrity, RLS, and claim-
wording defects. Those code paths have been corrected, but the new dependency
graph and real store/backend configuration have not been built or device-
tested in this environment.

## Corrected in this change

### Technical and security

- Local `is_pro` is no longer purchase proof. RevenueCat's verified `pro`
  entitlement is authoritative; cancellation, pending payment, restore, and
  already-purchased states have explicit behavior.
- Network purchase and buddy initialization no longer blocks first render.
- Buddy sync creates no anonymous account until the user accepts a specific
  disclosure. In-app deletion removes marks, link membership, and the auth
  identity.
- Buddy link claiming is atomic. RLS prevents a user from moving a mark to a
  link they do not belong to. Both copies of the deployment schema match.
- Full history can be searched, edited, deleted with undo, and completely
  exported. Moving/deleting a transaction repairs the daily streak records.
- A deliberate no-spend check-in counts without forcing a fake transaction.

### Experience and commercial honesty

- iOS v1 has one Founding Lifetime purchase and no recurring subscription.
- The paywall uses the live App Store localized price and is disabled when
  the store product cannot be loaded; it never presents a hard-coded fake
  purchase price.
- The old high-yield-account referral tile was removed because it had no
  working destination or validated user value.
- “Money saved” claims are now labelled “below selected benchmarks” and state
  that they cover only tracked categories and are not total savings.
- Launch scope is iPhone-only, portrait, iOS 13+. iPad and Android are
  deferred until the first platform is stable.

### Privacy and App Store

- The analytics SDK and toggle were removed. The event façade sends nothing.
- Privacy Policy and Terms disclose Supabase, RevenueCat, Apple speech/OCR,
  retention, deletion, and one-time purchase terms.
- The iOS privacy manifest conservatively declares app-functionality user ID,
  purchase history, and buddy product interaction, linked to the pseudonymous
  app identity and not used for tracking.
- Purchase restore and in-app account deletion align with Apple's current
  guidelines. Final App Privacy answers still must be reconciled with Xcode's
  generated third-party SDK privacy report.

## Remaining release blockers

### P0 — before the first external TestFlight build

1. **Completed:** dependency resolution now uses RevenueCat, the lockfile is
   current, `flutter analyze` reports no issues, and all 68 tests pass.
2. Build and archive with the release Flutter/Xcode versions, then verify the
   new RevenueCat integration on a physical iPhone through TestFlight.
3. Configure the App Store Connect non-consumable
   `com.pocklume.pro.lifetime`, RevenueCat entitlement `pro`, and the public iOS
   SDK key. Test purchase, cancel, Ask to Buy/pending, restore, reinstall,
   refund/revocation, offline launch, and a missing-product configuration.
4. Deploy the reviewed Supabase schema in a fresh project and enable anonymous
   sign-in. Test concurrent code claims, two-device Realtime, offline recovery,
   RLS denial, link deletion from either role, and account deletion.
5. Enable and verify GitHub Pages. Both in-app legal URLs must return 200
   without authentication before submission.
6. Set the Apple development team, distribution certificate/profile, support
   URL, privacy answers, screenshots, review notes, and a support contact.

### P0 — legal/product owner checks

1. Have qualified counsel review Terms/Privacy for the actual storefronts.
2. Run formal trademark/name clearance for the coined mark “Pocklume” and the
   icon before investing further in launch assets; preliminary public searches
   found no exact finance-app match, but code review is not legal clearance.
3. Confirm rights/licenses for every icon, font, image, sound, and benchmark.
4. Recheck the BLS benchmark year and category mapping before each release
   that displays the comparison. Avoid “save,” “average American,” or outcome
   guarantees in screenshots, ads, metadata, and creator scripts.

### P1 — before App Review

1. Real-device accessibility pass: VoiceOver, Dynamic Type at 200%, contrast,
   Reduce Motion, keyboard focus, and screen-reader labels for charts/icons.
2. Test fresh install, migration from the old Hive adapters, low storage,
   airplane mode, month/time-zone changes, corrupted import, and background
   termination during write/purchase/delete flows.
3. Verify RevenueCat and every packaged SDK privacy manifest/signature in the
   archived binary, not merely in source.
4. Add specific App Review notes explaining local financial storage, optional
   anonymous buddy sync, the deletion path, and how to find/test the IAP.

## Residual risks accepted for v1

- Financial entries are local-only and can be lost with device loss or app
  deletion. CSV export mitigates this but encrypted backup/restore is the most
  important P1 value feature.
- Manual entry improves awareness for some users but creates abandonment risk.
  Entry time, week-four retention, and weekly-review completion must determine
  whether the concept works.
- “Lifetime” creates long support obligations without recurring revenue.
  Price increases for new buyers must follow delivered value; existing buyers
  remain entitled.

## Go/no-go gate

Submit to App Review only when every P0 item has evidence attached (build log,
test result, store screenshot, backend test, URL check, or owner sign-off),
crash-free TestFlight sessions are at least 99.5%, and there is no unresolved
purchase, data-loss, account-deletion, or misleading-claim defect.
