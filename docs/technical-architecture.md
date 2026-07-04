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

## What's still unvalidated

Only one number in the whole model has no real-world anchor at all: the
**referral participation rate** (line 1 above). Everything else — referral
bounty size, add-on ARPU scale, B2B seat pricing, program pricing — is now
checked against a real disclosed number, even if the specific rate at which
Abacus's own users will behave is still a guess. That's a meaningfully
narrower risk surface than the original two-engine model, where the entire
referral line (bounty *and* rate) was ungrounded.
