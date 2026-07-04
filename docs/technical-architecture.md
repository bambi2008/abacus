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

## Second revenue engine — the honest gap

Industry research this session: "2026's budgeting-app winners aren't the
best budgeters, they're the ones with revenue beyond subscription" (Rocket
Money's bill-negotiation cut, Empower's advisory upsell, Cleo's cash
advances). **We can't do Rocket Money's or Cleo's model** — both require
bank-account access or lending, which conflicts directly with the "no bank
credentials, ever" positioning, and Cleo's cash-advance model raises the
same predatory-lending-adjacent concern flagged when DraftKings/FanDuel
were ruled out earlier this session. The honest second-line candidate:
**opt-in referrals to high-yield savings accounts or index-fund/robo-
advisor products** when a user's own logged data shows they're
consistently saving well — helpful, not predatory, and doesn't require
touching their bank credentials. This needs real validation before being
load-bearing in the financial model; flagged as the equivalent of
Regimen's affiliate-gear engine, but unproven here.

**Update after building the financial model**: this caution turned out to
be load-bearing, not hypothetical — the Base Case scenario clears its
$10,000/mo target specifically *because* referral revenue is modeled at
63% of month-36 run-rate, on an invented $30/referral, 0.5-1.2%-of-active-
users-per-month assumption with no real fintech-affiliate benchmark behind
it (see `customer-and-market.md` final verdict). Before this number is
trusted for a go/no-go decision, get real numbers from an actual HYSA or
robo-advisor affiliate program, not a guess.
