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
`docs/`. No Flutter code yet.

- [`docs/product-design.md`](docs/product-design.md) — screen inventory,
  onboarding flow (Day-1 guaranteed win, paywall delayed to Day 5+), the
  core logging loop, streak/buddy-streak/freeze UI, Progress and Paywall
  screens, and an explicit MVP out-of-scope list (no zero-based budgeting,
  no bank linking, no B2B console, no AI chat surface).

- [`docs/customer-and-market.md`](docs/customer-and-market.md) — the
  three-factor framework, persona, YNAB/Monarch/Mint-shutdown market data,
  competitor teardown, and the financial model's results.
- [`docs/technical-architecture.md`](docs/technical-architecture.md) —
  reuses the HeelEase/Regimen Provider+Hive+PostHog+IAP stack (this is the
  simplest core loop of the three — no AI vision/photo pipeline needed for
  MVP), the Duolingo gamification mechanics translated into specific
  features, and an honest flag on the unvalidated second revenue engine.
- [`docs/promotion-plan.md`](docs/promotion-plan.md) — content strategy
  around the ongoing "Mint alternative" search demand.
- [`docs/financial-model-year1-3.xlsx`](docs/financial-model-year1-3.xlsx) —
  v6: four revenue engines (program, referral, add-on ARPU, B2B
  employer-benefit) + opex (support headcount, infra, Apple fee) + a
  **paid-acquisition engine (Apple Search Ads specifically)**. **Base Case
  Year 3: $217,186 revenue, $30,616 ad spend, 1,299 paying customers,
  $166,488 net profit, 76.7% net margin.**
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

Product design is done — next is the Flutter scaffold, building exactly
the screens in `docs/product-design.md` (Today/Progress/Settings/Paywall +
onboarding), reusing the HeelEase/Regimen Provider+Hive+PostHog+IAP stack.
West-first (China's trend is real but app payment-willingness there is
weaker — see `customer-and-market.md`). B2B and add-on engines stay
documented-but-unbuilt until the MVP core loop is validated; paid
acquisition was modeled and found not worth prioritizing pre-scale.
