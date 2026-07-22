# Pocklume Founding Lifetime pricing and value decision

_Decision date: July 17, 2026 — iOS launch, United States_

## Decision

- Launch **Founding Lifetime at US$19.99** as one non-consumable App Store
  purchase. Do not offer monthly or annual billing in v1.
- Keep the current core loop genuinely useful for free. Pro adds depth and
  resilience; it must not hold export, existing entries, or basic budgeting
  hostage.
- Raise the price for new buyers to **US$29.99** only after Pocklume ships at
  least three P1 value items from the roadmap below and demonstrates 30-day
  retention. A later **US$39.99–49.99** price requires cross-device backup/
  sync plus mature automation. Existing lifetime buyers remain unlocked.

## Evidence and interpretation

High-priced subscriptions are not direct price anchors for Pocklume. YNAB is
US$109/year or US$14.99/month and includes account import, goals, debt tools,
education, multi-device sync, and sharing. PocketGuard is US$74.99/year or
US$12.99/month and includes bank connectivity, bills, subscriptions, debt,
goals, rules, and support. Monarch positions around a roughly US$99/year,
connected household-finance product. Those prices pay for recurring data
connectivity, infrastructure, support, and continuing financial workflows.

Pocklume currently competes more directly with privacy-first manual trackers.
That market contains credible free products: MoneyNote advertises local,
offline storage, no account, no bank connection, no subscription, budgets,
reports, export, biometric lock, iCloud sync, and widgets. Expenses offers
private manual tracking, receipt scan, CSV import/export, iCloud sync,
collaboration, multi-platform support, widgets and Shortcuts. Pocklume cannot
credibly charge US$89.99 lifetime for a narrower first release merely because
the connected-budgeting category charges annual subscriptions.

Customer evidence is consistent: manual entry can create awareness, but the
same friction causes people to stop. Simplicity, speed, privacy, easy editing,
and a useful review loop are the job to be done. Gamification is a retention
aid, not sufficient recurring value by itself.

The nearby manual-tracker market spans free products, a US$9.99/year product,
and a simple competitor publicly offering US$14.99 lifetime; a more complete
privacy-first daily-budget product has sold lifetime access around US$39.99.
Pocklume v1 sits between those products but its paid tier is still narrow.

US$19.99 is therefore an early-adopter price, not a claim that the mature
product is worth only US$19.99. It is high enough to test willingness to pay
and low enough to reflect product and platform risk at launch. App Store price
testing should compare page conversion and purchase conversion, not rely only
on stated willingness to pay.

## What creates real continuing value

### P0 — launch value already promised

1. Fast manual entry, receipt scan, voice entry, category budgets.
2. Searchable, editable full transaction history and complete CSV export.
3. Honest monthly/category insights, streaks, no-spend check-ins, and owl.
4. One-device local privacy by default; buddy sync is explicit opt-in.
5. Verified purchase and restore, stable offline operation, and data deletion.

### P1 — first 90 days after launch

1. **Reliable reminders and widgets:** one-tap expense entry and daily budget
   status without opening the app.
2. **Recurring transactions:** bills, subscriptions, income, and suggested
   entries that the user confirms rather than retypes.
3. **Backup and restore:** encrypted iCloud backup with a clear recovery test.
4. **Better review loop:** weekly recap, controllable budget rollover, trends,
   and explanations based only on the user's own tracked data.
5. **Accessibility and trust:** Face ID lock, Dynamic Type/VoiceOver audit,
   clear data-status screens, and predictable export/import.

### P2 — supports US$39.99–49.99 for new buyers

1. Native iCloud sync across iPhone and iPad, conflict handling, and shared
   household budgets with explicit permissions.
2. Apple Watch and Shortcuts/App Intents for near-zero-friction logging.
3. Robust CSV import and migration from competing trackers.
4. Goals, sinking funds, debt payoff and cash-flow planning that users revisit
   throughout the month.
5. Personal rules and on-device suggestions that reduce entry effort without
   sending financial data to an advertising or model provider.

## Pricing guardrails

- Do not introduce a subscription merely to improve revenue optics. A
  subscription becomes defensible only if Pocklume operates costly, ongoing
  services users repeatedly receive: reliable family sync, hosted backup,
  bank connectivity, or continuously maintained premium intelligence.
- Never subscription-lock CSV export or access to the user's existing data.
- Do not promise "lifetime of the customer" or every future product. The offer
  covers the Pro entitlement in this app and compatible updates while the app
  is maintained.
- Do not show artificial countdowns or a fake crossed-out reference price.
  "Founding" ends on a disclosed product milestone or date.

## Launch measurement

Track without a third-party analytics SDK by using App Store Connect aggregate
metrics, RevenueCat purchase/entitlement totals, opt-in interviews, TestFlight
surveys, support tickets, and a voluntary in-app feedback link. The decision
gate after 30–45 days is:

- crash-free sessions at least 99.5%;
- purchase/restore defect rate below 1%;
- median expense entry time under 10 seconds in observed tests;
- at least 25% of activated users still logging in week four;
- at least 40% of retained users complete a weekly review;
- paid conversion interpreted together with acquisition channel and price,
  not as a standalone vanity number.

## Sources checked

- YNAB official pricing and feature page: https://www.ynab.com/pricing
- Monarch official pricing page: https://www.monarch.com/pricing
- PocketGuard official pricing page: https://pocketguard.com/pricing/
- MoneyNote U.S. App Store listing: https://apps.apple.com/us/app/expense-tracker-money-note/id1320730220
- Expenses U.S. App Store listing: https://apps.apple.com/us/app/expenses-spending-tracker/id1492055171
- Today's Budget App Store listing: https://apps.apple.com/ca/app/todays-budget-saving-is-fun/id1593868439
- Basal App Store listing (US$9.99/year at research date): https://apps.apple.com/us/app/basal-daily-expense-tracker/id6758315193
- OneLine Budget launch discussion (US$14.99 lifetime at research date): https://www.reddit.com/r/iosapps/comments/1rtleps/

Public prices and listings can change. Recheck them before changing the App
Store price tier.
