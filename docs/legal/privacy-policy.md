# Abacus Privacy Policy

_Last updated: July 11, 2026_

## 1. Introduction

Abacus ("we", "our", "the app") is a manual, privacy-first budgeting app,
published by Mao Qin. Abacus never connects to your bank
— this policy explains exactly what information the app does handle, and
how.

## 2. Information Collected

**Your financial data never leaves your device.** Every expense, category,
budget limit, streak, badge, owl state, no-spend day, and monthly savings
comparison you see in the app is stored locally on your device using
on-device storage (Hive). Abacus does not operate a central account system
and cannot see this data — there is nothing for us to see it in.

**The current App Store version of Abacus collects nothing at all** —
anonymous analytics and cloud savings-buddy sync are disabled in this
release, so no data of any kind leaves your device. The sections below
describe what those features would handle _if a future version enables
them_; we describe them here so this policy stays accurate and complete
either way.

Subject to that, the only exceptions to the "stays on your device" rule
are:

- **Anonymous, aggregate usage analytics** (via PostHog), to understand
  which parts of the app are used and where people get stuck. These events
  record that an action happened — e.g. "an expense was logged," "a
  milestone was reached," "the paywall was viewed" — **never the content of
  that action**: not the amount, not the category, not any note you wrote.
  Analytics events are not linked to your name, email, or any other
  personal identifier. You can turn this off anytime in Settings →
  Anonymous usage analytics.
- **Savings-buddy sync**, only if you choose to start or join a buddy
  streak. This feature syncs exactly three things per person per day: an
  anonymous device identifier, a calendar date, and whether you logged
  anything that day (true/false). It never syncs an amount, a category, a
  note, or anything else about what you spent. If you never use the buddy
  streak feature, nothing about your account is ever created or synced.
- **Receipt scanning**, only if you tap the camera icon to scan a receipt.
  Text recognition runs entirely on your device — Apple's Vision framework
  on iOS, Google's ML Kit on Android — the photo is processed locally and
  is never uploaded anywhere, and is discarded once the scan completes. (On
  Android, ML Kit's on-device model may need a one-time download of a few
  megabytes from Google Play Services the first time you scan — that
  download contains no data of yours, only the recognition model itself.)
- **Voice input**, only if you tap the microphone icon to speak an expense.
  Speech recognition is requested on-device where your iPhone supports it.
  On some devices, if the on-device language model isn't already
  downloaded, iOS may fall back to Apple's network-based speech
  recognition to process that one request — this is a platform behavior we
  don't control and can't fully guarantee against, so we're disclosing it
  rather than overpromising. We never store or transmit an audio
  recording ourselves.
- **Purchase processing**: Apple handles your payment details directly
  when you buy Abacus Pro; we receive only a purchase confirmation (no
  card details) to unlock Pro features.

## 3. How Information Is Used

Your financial data (expenses, categories, budgets, streaks, and everything
else in Section 2's first paragraph) stays on your device and is used
solely to power the app's features for you — logging, budget tracking,
streaks, and the monthly savings comparison. We have no access to this
data and no way to reconstruct it. Anonymous analytics events and buddy-sync
signals (see Section 2) are used only in aggregate, to improve the app and
to make the savings-buddy feature work.

## 4. Data Storage

Your financial data is stored locally on your device (Hive). If you delete
the app, this data is deleted with it. Abacus does not back up your data to
any server; if you want to keep a copy, use the in-app CSV export feature
(Settings → Export as CSV) before uninstalling.

The savings-buddy sync data described in Section 2 (anonymous id + date +
logged/not-logged boolean) is stored on Supabase, a third-party database
provider, for as long as your buddy link stays active. This is the only
category of data Abacus stores off your device, and it's never anything
financial.

## 5. Data Sharing

We do not sell or rent your data. We do not use advertising SDKs. Two
processors handle the narrow exceptions in Section 2 on our behalf:

- **PostHog** (analytics) — anonymous, aggregate event names only.
- **Supabase** (savings-buddy sync) — anonymous id + date + boolean only,
  and only for users who opt into a buddy streak.

Neither processor ever receives an expense amount, category, or note.

## 6. Your Rights

Because almost all of your data lives on your device, you control it
directly:

- **Export**: get a CSV copy of your data anytime via Settings → Export as
  CSV.
- **Delete**: uninstalling the app deletes all local data immediately.
- **Buddy sync**: if you've started or joined a buddy streak, that link and
  its associated sync data can be abandoned by no longer using the feature;
  contact us (Section 11) if you'd like it deleted sooner.
- **Analytics opt-out**: Settings → Anonymous usage analytics, off anytime.

## 7. Data Retention

Financial data persists on your device until you delete it or uninstall the
app. Savings-buddy sync data (Section 2/4) persists on Supabase for as long
as the buddy link is active.

## 8. Children's Privacy

Abacus is not directed at children under 13 and we do not knowingly collect
information from children.

## 9. Financial Disclaimer

Abacus is a budgeting and expense-tracking tool. It is not a financial
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
