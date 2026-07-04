# Technical Architecture

## This is the simplest core loop of any project this session

No AI vision API, no LLM analysis needed for the MVP core loop at all —
manual expense entry is just structured data (amount, category, note, date).
This removes an entire class of risk present in HeelEase (medical evidence
correctness) and Regimen (vision-model accuracy, biometric-data handling).
AI is optional/Pro-tier polish here, not load-bearing for MVP.

## Flutter app (reuse from HeelEase/Regimen)

Same stack, same reasons, third time proven:
- **State management**: Provider + Hive, local-first — this time the local-
  only architecture isn't just a privacy nice-to-have, it's the literal
  product positioning ("no bank credentials, ever") in a category with a
  recent, well-known data-monetization scandal (Mint) to point at.
- **Analytics**: PostHog, same no-op-until-configured pattern, opt-out
  toggle, anonymous events only (log "expense_logged", never the amount or
  category).
- **Payments**: `in_app_purchase`, no weekly billing (same discipline as
  HeelEase/Regimen).

## Core data model

- `Expense`: amount, category, note, date — the single atomic unit, entered
  manually, no bank sync.
- `Category` + monthly budget limit per category (YNAB's "give every dollar
  a job" simplified for a lighter-weight, gamified product).
- `DailyLogCompletion`: did the user log at least one expense today, and
  did today's spending stay within budget — this is the thing the streak
  mechanic tracks, analogous to HeelEase's `RoutineCompletion`.

## The actual differentiation: Duolingo's mechanics, applied properly

Researched this session (Duolingo case studies, retention breakdowns).
Every mechanic below is a specific, named gap versus YNAB/Monarch/Copilot/
Goodbudget, none of which apply real habit-game design to the logging habit
itself:

1. **Streak framed around loss aversion, not achievement.** Copy reads "You're about to lose your 12-day streak" not "Keep your streak going" — prospect theory (Kahneman/Tversky): losing something hurts ~2x more than gaining the equivalent feels good. Applies directly to push-notification copy and the streak UI.
2. **Streak freeze**: one missed day doesn't zero the streak — prevents the "what-the-hell effect" where a single lapse causes total habit abandonment. Gate a limited number of free freezes, more for Pro — this is both a retention mechanic and a monetization lever.
3. **Buddy streak**: a shared streak between two users that only increments if *both* log an expense that day. This is the one mechanic that directly fixes the "no viral loop" weakness identified in HeelEase's business-model critique — a real, low-cost acquisition mechanic, not a marketing gimmick bolted on after the fact.
4. **Layered onboarding**: Day 1 has a guaranteed-achievable win (log your first expense), Day 7 introduces "a streak worth protecting," longer-term users get rarer badges — don't treat a Day 1 user and a Day 30 user identically.
5. **Personalized reminder timing**: let the user set it, and adjust based on when they actually engage — not a single fixed daily notification time for everyone.

## Optional Pro-tier AI layer (not MVP-critical)

A "spending insight" feature: periodically summarize the user's own
structured expense data (already fully known — no vision, no third-party
text) into a short natural-language observation ("You've spent 40% more on
dining out this month than your 3-month average"). This is a much lower-
risk AI use than HeelEase's medical content or Regimen's photo analysis —
it's describing the user's own numbers back to them, not making an
evidence claim or judging an image. Domestic or Western LLM APIs are both
fine here (unlike Regimen's photo pipeline) since there's no biometric data
and no Western-trust-positioning conflict — this is a case where the
earlier "no domestic API" rule doesn't apply, because the sensitivity
profile is different.

## Revenue engines beyond the program purchase — four lines, not two

Industry research this session: "2026's budgeting-app winners aren't the
best budgeters, they're the ones with revenue beyond subscription" (Rocket
Money's bill-negotiation cut, Empower's advisory upsell, Cleo's cash
advances). **We can't do Rocket Money's or Cleo's model** — both require
bank-account access or lending, which conflicts directly with the "no bank
credentials, ever" positioning, and Cleo's cash-advance model raises the
same predatory-lending-adjacent concern flagged when DraftKings/FanDuel
were ruled out earlier this session. Also explicitly rejected: **advertising**
(Duolingo's own ~7%-of-revenue ad line) — this would directly contradict the
"we don't monetize your attention or data" wedge that differentiates Abacus
from Mint, the exact competitor whose collapse is cited as market
validation.

Four lines survive, each checked against a real precedent:

1. **Referral revenue** (opt-in, financial products): when a user's own
   logged data shows consistent saving, suggest a high-yield savings account
   or index-fund/robo-advisor product, paid a bounty by the partner directly
   — no bank-credential access required. Bounty validated against real
   programs this session (Comenity Direct HYSA $150/CPL, Barclays $250-300/
   CPL, Chase $50, LendingClub $100, Betterment affiliate channel $150/sale)
   — the model's $30/referral assumption is conservative relative to this
   range. The one number still unvalidated is the participation rate
   (0.5-1.2% of active users/month) — no external benchmark exists for this,
   since it depends on Abacus's own in-app prompt design, not affiliate-
   network terms.
2. **Add-on ARPU (virtual goods + paid course)**: cosmetic streak-freeze
   packs / theme packs (Duolingo's own IAP line, ~5% of its revenue) plus a
   one-time paid course (e.g. "Zero-Based Budgeting Mastery") — feasible to
   build cheaply now that AI can draft structured lesson content for a human
   to review, unlike a Duolingo English Test-style accredited certification
   (which needs institutional recognition Abacus doesn't have and shouldn't
   claim). Sold via IAP, so store commission applies. Modeled as a small
   blended ARPU on the active-user base, scaled down from Duolingo's real
   mix since Abacus has no large free/ad-supported base to cross-sell
   against.
3. **B2B employer-benefit channel** — real, proven precedent in this exact
   category (SmartDollar/Ramsey Solutions, Brightside — the latter reports
   $56M returned to 800K+ families). Employers buy a bulk-seat benefit,
   employees use it free; this is a completely different acquisition path
   from the C2C funnel (enterprise/SMB self-serve sales, not app-store
   installs), which is exactly why it's valuable — it doesn't share failure
   modes with the referral-rate or ad-spend risk sitting on the C2C side.
   Modeled as a **self-serve SMB tier only** (no dedicated sales team,
   matching the small-team constraint), priced at $3-4.50/employee/month —
   anchored to real basic digital wellness-platform self-serve pricing
   ($3-5/employee/month found this session; full-service platforms with
   human coaching run far higher, $58+/employee/month, but that tier needs
   a service org Abacus doesn't have). Modeled to go live later than the
   C2C launch (month 10-15 depending on scenario) since a self-serve
   employer-benefit funnel needs a live product with organic traction to be
   credible in the first place.
4. **Program purchase** (lifetime + subscription) — unchanged, the
   best-anchored line (YNAB $109/yr, Monarch $99/yr).

## Operating costs — customer support, infra, and net profit (v3)

The model was revenue-only through v2. v3 adds an opex side so the target
is judged against **net profit**, not gross revenue — a stricter bar.

**Customer support headcount and cost**: modeled as tickets generated by
(Active User Base + B2B seats) × a ticket rate, divided by tickets an agent
can handle per month, priced at a real contractor rate.

- Ticket-handling capacity anchored to a real 2026 benchmark: 25-35
  tickets/agent/day, ~500-700/month.
- Agent cost anchored to real 2026 nearshore/offshore contractor rates
  ($7-22/hr found this session) — modeled at $12/hr (Conservative/Base) to
  $15/hr (Optimistic, buying more experienced agents at scale).
- The one un-benchmarked number here is the **ticket rate per user itself**
  (2.0%/1.5%/1.0% of active users per month across scenarios) — no
  published figure exists for "manual-entry budgeting app support ticket
  rate" specifically. Reasoned down from general consumer-app norms because
  Abacus's architecture structurally removes the #1 driver of budgeting-app
  support tickets industry-wide: bank-sync failures. There is nothing to
  sync, so there is nothing to break in that specific, high-volume way.

| | Conservative | Base Case | Optimistic |
|---|---|---|---|
| Month-36 support tickets/mo | 122 | 372 | 1,112 |
| Month-36 support FTE (fractional) | 0.24 | 0.68 | 1.71 |
| **Recommended headcount (rounded up)** | **1** | **1** | **2** |
| Month-36 support cost/mo | $469 | $1,298 | $4,107 |

**This does not require a support team in Year 1 for any scenario** — even
Base Case doesn't cross 1.0 FTE until later in the ramp. A realistic
operating plan: founder handles support directly through most of Year 1-2,
then brings on a single part-time nearshore/offshore contractor once ticket
volume crosses roughly 1 FTE-equivalent, rather than budgeting headcount
from month 1.

**Other opex**: Apple Developer Program ($99/yr = $8.25/mo, not sourced
elsewhere but a fixed real cost), plus an infra/tools line (hosting,
PostHog usage beyond free tier, AI-insights API calls, any lightweight
backend needed for referral/B2B tracking) — this line **is a planning
estimate, not a sourced benchmark**: $50→$200/mo (Conservative),
$75→$450/mo (Base), $150→$2,000/mo (Optimistic) across Years 1-3. No paid
user-acquisition/ad spend is budgeted anywhere in this model — growth is
assumed organic per `promotion-plan.md`; if paid acquisition is added
later, opex would be materially higher than modeled here.

| | Year 1 Opex | Year 2 Opex | Year 3 Opex | Year 1 Profit | Year 2 Profit | Year 3 Profit |
|---|---|---|---|---|---|---|
| Conservative | $1,803 | $4,330 | $7,348 | $2,414 | $10,591 | $25,815 |
| **Base Case** | $2,800 | $8,888 | $18,025 | $13,129 | $65,077 | $167,178 |
| Optimistic | $4,703 | $19,836 | $59,842 | $59,378 | $381,251 | $1,293,693 |

Opex stays low relative to revenue across all three scenarios (Base Case
Year 3 opex is under 10% of revenue) — the structural reason is the same
one behind the "no bank credentials" pitch: no bank-sync support burden, no
backend-heavy automated-categorization infrastructure to run, and a support
load driven by a simple, well-understood core product.

## Paid acquisition (v5) — organic + ads combined

v5 adds a paid-acquisition engine on top of the organic-only growth model.

**CAC/CPI benchmarks found this session**: general mobile app CPI runs
$1-5, with cost-per-paying-user $20-80 (freemium apps convert 2-5% of
installs, meaning true CPPU is 20-50x CPI). Fintech specifically runs much
higher: non-premium fintech/business apps at $3.50-8 CPI, premium banking/
investing keywords at $10-25 CPI (the latter reflects intense competition
for high-LTV users and wasn't used here — Abacus isn't competing for those
keywords). Modeled CPI: $6.00 (Conservative) → $5.00 (Base) → $3.50
(Optimistic), from the non-premium fintech/business range.

**Ad spend logic**: rather than assume a fixed ad budget (which begs the
question of where that cash comes from on day 1), ad spend is modeled as a
**reinvestment of a % of the prior month's net revenue** — 10% Conservative,
15% Base, 20% Optimistic. This is a self-funded growth model consistent
with this session's "no outside capital" bootstrap framing: there's
effectively no ad budget in month 1 (no revenue yet), and spend grows
organically in step with the business, rather than being budgeted
independent of what the business can actually afford. Paid installs **add
to** organic installs (which keep growing on their own separate trajectory)
— this is incremental growth on top of the existing organic plan, not a
replacement for it.

**Important caveat, stated plainly**: CPI is held constant regardless of
spend scale. Real customer acquisition cost rises as a channel saturates —
this model doesn't capture that. It shows up starkly in the Optimistic
scenario, where compounding (more revenue → more ad spend → more installs
→ more revenue) pushes month-36 ad spend to $58,512/mo at a flat $3.50 CPI
— in reality, spending that much in a niche budgeting-app category would
almost certainly drive CPI up substantially as the channel saturates. Base
Case and Conservative stay in a more believable range (ad spend under
$3,500/mo by month 36) where the constant-CPI simplification is less of a
distortion. Treat the Optimistic paid-acquisition numbers as an upper
bound illustrating the mechanic, not a real plan.

## v6: switching to Apple Search Ads specifically — an honest non-result

The founder's reaction to v5's numbers was correct: a ~$295 CAC against a
~$64 program-only LTV per converter is a bad ratio by any standard (the
industry benchmark for a healthy subscription business is **3:1 LTV:CAC**,
with elite payback in 5-7 months; under 1:1 means losing money per
customer). The more rigorous **per-install** framing (since ad spend buys
installs, not hand-picked converters, and non-converting installs still
generate referral/add-on revenue) put v5 at **0.96:1 in Year 1** and
**1.79:1 in Year 3** — better than losing money outright, but well below
the 3:1 healthy bar.

The natural next question was whether switching to a better-targeted
channel would fix this. Real research this session found Apple Search Ads
is structurally the best-fit paid channel for finance apps — finance-
category CPI of $4.13-8.23 with Day-1 retention of 35-45%, vs. Google
UAC's 25-35% or TikTok/Meta finance CPMs of $11+ for a worse-fit,
interruption-based audience. v6 modeled this directly: real ASA CPI
($7.00/$5.50/$4.00 across scenarios) plus a conversion-rate quality
multiplier (1.25x/1.35x/1.45x) applied only to paid-channel installs,
extrapolated from the real retention gap.

**The result, stated plainly: it barely moved the ratio.**

| | v5 (generic paid, $5.00 CPI) | v6 (Apple Search Ads, $5.50 CPI) |
|---|---|---|
| Year 1 ratio | 0.96:1 | 0.96:1 |
| Year 3 ratio | 1.79:1 | 1.77:1 |

The quality/conversion premium from higher-intent search traffic is real
(+35% conversion in Base Case) — but the *realistic* ASA CPI for finance
($5.50, from real 2026 data) is itself higher than the generic-fintech
guess used in v5 ($5.00), and the two effects roughly cancel out. This is
a useful negative result, not a wasted exercise: **the earlier
recommendation ("switch to Apple Search Ads, it'll be more efficient")
does not survive contact with the real numbers once modeled precisely.**
The honest conclusion isn't "pick a different channel" — it's that **paid
acquisition, on any channel, isn't a strong lever for this specific
product at this stage of its unit economics.** Organic growth (content,
ASO, the built-in buddy-streak viral mechanic) remains the primary growth
engine by default, not because paid channels weren't investigated, but
because they were investigated and didn't clear the bar.

## What's still unvalidated

Only one number in the whole model has no real-world anchor at all: the
**referral participation rate** (line 1 above). Everything else — referral
bounty size, add-on ARPU scale, B2B seat pricing, program pricing — is now
checked against a real disclosed number, even if the specific rate at which
Abacus's own users will behave is still a guess. That's a meaningfully
narrower risk surface than the original two-engine model, where the entire
referral line (bounty *and* rate) was ungrounded.
