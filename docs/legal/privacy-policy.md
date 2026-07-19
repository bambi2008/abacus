# Pocklume Privacy Policy

_Last updated: July 17, 2026_

## 1. Introduction

Pocklume ("we", "our", "the app") is a manual, privacy-first budgeting app,
published by Mao Qin. Pocklume never connects to your bank
— this policy explains exactly what information the app does handle, and
how.

## 2. Information Collected

**Your financial data never leaves your device.** Every expense, category,
budget limit, streak, badge, owl state, no-spend day, and monthly savings
comparison you see in the app is stored locally on your device using
on-device storage (Hive). Pocklume does not operate a central account system
and cannot see this data — there is nothing for us to see it in.

**Nothing leaves your device unless you opt into the savings-buddy feature,
use an Apple service such as speech recognition, or the app checks or
validates an App Store purchase entitlement.** Usage analytics are not
included in the current App Store release.

The exceptions to the "stays on your device" rule are:

- **Savings-buddy sync**, only if you choose to start or join a buddy
  streak. To connect two devices we create a pseudonymous account for you
  (no email, no password, no name — just an anonymous identifier). The
  feature then syncs exactly three things per person per day: that
  anonymous identifier, a calendar date, and whether you completed your
  daily check-in (true/false). It never syncs an amount, a category, a note, or
  anything else about what you spent. If you never use the buddy streak
  feature, nothing about your account is ever created or synced. You can
  delete all of this anytime in Settings → Delete my savings-buddy data.
- **Receipt scanning**, only if you tap the camera icon to scan a receipt.
  Text recognition runs entirely on your iPhone using Apple's Vision
  framework. The photo is processed locally, is never uploaded by Pocklume,
  and is discarded once the scan completes.
- **Voice input**, only if you tap the microphone icon to speak an expense.
  Speech recognition is requested on-device where your iPhone supports it.
  On some devices, if the on-device language model isn't already
  downloaded, iOS may fall back to Apple's network-based speech
  recognition to process that one request — this is a platform behavior we
  don't control and can't fully guarantee against, so we're disclosing it
  rather than overpromising. We never store or transmit an audio
  recording ourselves.
- **Purchase processing**: Apple handles your payment details directly.
  RevenueCat receives App Store transaction and app-user identifiers to
  validate and restore your Pro entitlement. Neither Pocklume nor RevenueCat
  receives your card details from the app.

## 3. How Information Is Used

Your financial data (expenses, categories, budgets, streaks, and everything
else in Section 2's first paragraph) stays on your device and is used
solely to power the app's features for you — logging, budget tracking,
streaks, and the monthly savings comparison. We have no access to this
data and no way to reconstruct it. Buddy-sync signals (see Section 2) are
used only to make the savings-buddy feature work.

## 4. Data Storage

Your financial data is stored locally on your device (Hive). If you delete
the app, this data is deleted with it. Pocklume does not back up your data to
any server; if you want to keep a copy, use the in-app CSV export feature
(Settings → Export as CSV) before uninstalling.

The savings-buddy sync data described in Section 2 (anonymous id + date +
daily-check-in boolean) is stored on Supabase, a third-party database
provider, for as long as your buddy link stays active. This is the only
category of app-content data Pocklume stores off your device, and it is never
financial. App Store purchase validation records are separately handled by
Apple and RevenueCat.

## 5. Data Sharing

We do not sell or rent your data. We do not use advertising SDKs. Two
processors handle the narrow exceptions in Section 2 on our behalf:

- **Supabase** (savings-buddy sync) — anonymous id + date + boolean only,
  and only for users who opt into a buddy streak.
- **RevenueCat** (purchase validation) — App Store transaction and app-user
  identifiers needed to unlock and restore Pro.

Neither processor ever receives an expense amount, category, or note.

## 6. Your Rights

Because almost all of your data lives on your device, you control it
directly:

- **Export**: get a CSV copy of your data anytime via Settings → Export as
  CSV.
- **Delete**: uninstalling the app deletes all local data immediately.
- **Buddy sync**: if you've started or joined a buddy streak, delete the
  link, all synced logging days, and the anonymous account anytime, right
  in the app, via Settings → Delete my savings-buddy data. You can also
  contact us (Section 11).

## 7. Data Retention

Financial data persists on your device until you delete it or uninstall the
app. Savings-buddy sync data (Section 2/4) persists on Supabase until you
delete it in Settings. Purchase records may be retained by Apple and
RevenueCat as needed for entitlement restoration, fraud prevention, legal,
and accounting obligations.

## 8. Children's Privacy

Pocklume is not directed at children under 13 and we do not knowingly collect
information from children.

## 9. Financial Disclaimer

Pocklume is a budgeting and expense-tracking tool. It is not a financial
advisor, and nothing in the app — including the monthly savings comparison
against national spending averages — constitutes financial, investment, or
tax advice. Comparisons to published national averages (U.S. Bureau of
Labor Statistics Consumer Expenditure Survey) are provided for general
context only and may not reflect your personal financial situation. Always
consult a qualified professional for advice specific to your circumstances.

## 10. Changes to This Policy

We may update this policy from time to time. Material changes — including
any change to what Section 2 discloses — will be reflected in the app's
release notes.

## 11. Contact

Questions about this policy: mao8teen@gmail.com
