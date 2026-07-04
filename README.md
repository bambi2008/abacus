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
3-year financial model) — see `docs/`. No Flutter code yet.

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
  v2: four revenue engines (program, referral, add-on ARPU, B2B
  employer-benefit). **Base Case clears the $10,000/mo target at
  $19,293/mo by month 36** — up from $13,500/mo in the original two-engine
  version. Referral bounty, add-on ARPU, and B2B pricing are all now
  checked against real disclosed benchmarks; the one number still
  unvalidated is the referral participation rate, which needs real user
  data (a beta), not more desk research, to resolve.

## Next

West-first (China's trend is real but app payment-willingness there is
weaker — see `customer-and-market.md`). B2B and add-on engines are
documented and modeled but not built. Decide: run a beta to validate the
referral participation rate, or start the Flutter scaffold for the MVP
core loop (habit-tracking + program purchase), which doesn't depend on any
of the three secondary revenue engines to function.
