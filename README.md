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
  **Base Case clears the $10,000/mo target** ($13,500/mo by month 36) —
  first project this session to do so — but 63% of that comes from a
  referral-revenue assumption with no real benchmark behind it yet. Program
  revenue alone (the well-anchored part) still beats HeelEase's entire
  Base Case outcome.

## Next

Get real fintech-referral-program economics before trusting the financial
model's headline number, then decide whether to scaffold.
