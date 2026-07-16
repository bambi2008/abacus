# Abacus

A gamified, privacy-first (no bank-account linking) manual budgeting app.
Third project this session, after HeelEase (plantar fasciitis recovery —
business model didn't clear its revenue target) and Regimen (men's grooming
— pivoted away on founder skepticism before building further).

## Why this one

Refined a three-factor test from HeelEase's failure: a habit-app idea needs
(1) a real strong need, (2) an outcome that self-discipline reliably
produces (not luck/other-people/market-dependent), and (3) a need that's
perpetual, not self-resolving. Budgeting is the cleanest fit found this
session — cleaner than HeelEase (which fails #3, the condition heals) and
cleaner than a dating-coach concept explored and dropped (which fails #2 —
practiced conversation skill doesn't reliably produce "getting a date,"
since that outcome depends on another person's choice, not just your own
effort).

Separately, researched Duolingo's retention playbook (streak loss-aversion
framing, streak-freeze mechanic, buddy/friend streaks, layered onboarding)
as a transferable execution methodology — this project applies it to a
market (budgeting apps) that's proven at real scale (YNAB: ~$49M ARR,
bootstrapped, profitable) but where no competitor has applied real
Duolingo-style gamification to the daily-logging habit itself.

## Status

Full evaluation done (customer/market, technical architecture, promotion,
3-year financial model) plus a screen-by-screen product design — see
`docs/`. **Flutter scaffold built** — `app/`, `flutter analyze` clean,
`flutter test` passing.

- `app/` — MVP core loop implemented per `docs/product-design.md`:
  Provider+Hive local-first stack with RevenueCat-verified iOS purchases. 4-step
  onboarding (positioning → pick categories → log first expense → notification
  ask), Today screen (streak counter with loss-aversion copy, log-expense
  bottom sheet, per-category budget bars, auto-applying streak freeze),
  Progress screen (category bar chart via `fl_chart`, streak calendar,
  swipe-to-delete recent entries, locked Pro insight card), Settings
  (opt-in buddy streak, complete CSV export, legal and data-deletion controls,
  low-key referral placement), and a single Founding Lifetime paywall
  (US$19.99 launch recommendation; no subscription). Buddy sync uses Supabase
  only after explicit user consent.

- [`docs/product-design.md`](docs/product-design.md) — screen inventory,
  onboarding flow (Day-1 guaranteed win, paywall delayed to Day 5+), the
  core logging loop, streak/buddy-streak/freeze UI, Progress and Paywall
  screens, and an explicit MVP out-of-scope list (no zero-based budgeting,
  no bank linking, no B2B console, no AI chat surface).

- [`docs/customer-and-market.md`](docs/customer-and-market.md) — the
  three-factor framework, persona, YNAB/Monarch/Mint-shutdown market data,
  competitor teardown, and the financial model's results.
- [`docs/technical-architecture.md`](docs/technical-architecture.md) —
  uses a Provider+Hive local-first architecture (the core loop
  needs no cloud AI at all; an on-device OCR receipt-scan assist (Vision on
  iOS, ML Kit on Android) was added later purely to speed up manual entry,
  never a step toward bank sync), the Duolingo gamification mechanics
  translated into specific features, and an honest flag on the unvalidated
  second revenue engine.
- [`docs/promotion-plan.md`](docs/promotion-plan.md) — content strategy
  around the ongoing "Mint alternative" search demand.
- [`docs/ios-launch-risk-review-2026-07-17.md`](docs/ios-launch-risk-review-2026-07-17.md)
  — current go/no-go verdict, corrected risks, and evidence required before
  TestFlight/App Review.
- [`docs/founding-lifetime-pricing-and-value.md`](docs/founding-lifetime-pricing-and-value.md)
  — US$19.99 Founding Lifetime decision and the feature gates for later prices.
- [`docs/financial-model-year1-3.xlsx`](docs/financial-model-year1-3.xlsx) —
  v6: four revenue engines (program, referral, add-on ARPU, B2B
  employer-benefit) + opex (support headcount, infra, Apple fee) + a
  **paid-acquisition engine (Apple Search Ads specifically)**. **Base Case
  Year 3: $217,186 revenue, $30,616 ad spend, 1,299 paying customers,
  $166,488 net profit, 76.7% net margin.**
- [`docs/legal/privacy-policy.md`](docs/legal/privacy-policy.md) — what the
  app actually collects (almost nothing — local-first by design) and the
  narrow, disclosed exceptions: opt-in savings-buddy sync, RevenueCat purchase
  validation, and Apple OCR/voice services invoked by the user.
  **Honest finding on paid acquisition**: the rigorous LTV:CAC ratio (value
  per install vs. cost per install) is **0.96:1 in Year 1 and 1.77:1 in
  Year 3 — below the industry-healthy 3:1 benchmark**. Switching from
  generic paid social to Apple Search Ads (the best-fit channel for finance
  apps, per real 2026 CPI/retention data) barely moved this ratio — the
  better conversion quality and the genuinely higher realistic CPI roughly
  cancel out. **Conclusion: paid acquisition isn't a strong lever for this
  product yet, on any channel** — organic (content, ASO, the built-in
  buddy-streak viral mechanic) should carry Year 1-2 growth; paid spend is
  a small opportunistic supplement once conversion rates mature, not a
  primary plan. Market share stays ~0.05% of category TAM by month 36 even
  with paid acquisition added.
  See `customer-and-market.md` for full per-scenario tables and the
  YNAB-persona-gap research (price-sensitive under-$50K users,
  internationally-located users structurally underserved by YNAB's
  bank-linking requirement — a segment Abacus's no-bank-sync architecture
  already fits).

## Next

Core loop scaffold is done. Before TestFlight, create the App Store
non-consumable `com.abacus.pro.lifetime`, configure RevenueCat entitlement
`pro`, deploy the Supabase schema, host the legal pages, and supply the release
build keys. Reminder scheduling is a documented v1.1 item. West-first (China's trend is real
but app payment-willingness there is weaker — see `customer-and-market.md`).
B2B and add-on revenue engines stay documented-but-unbuilt until the MVP
core loop is validated with real users; paid acquisition was modeled and
found not worth prioritizing pre-scale.
