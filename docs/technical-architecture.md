# Technical Architecture

## This is the simplest core loop of any project this session

No cloud AI vision API or LLM is needed for the MVP core loop at all —
manual expense entry is just structured data (amount, category, note, date).
This removes an entire class of risk present in HeelEase (medical evidence
correctness) and Regimen (vision-model accuracy, biometric-data handling).
Cloud AI is optional/Pro-tier polish here, not load-bearing for MVP.
**2026-07-05: an on-device (not cloud) receipt-scan assist was added** — see
"Receipt OCR" below — but the core loop still works with zero AI of any kind
if the user just types the three fields.

## Receipt OCR (on-device entry-speed assist, not a step toward bank sync)

The single biggest lever on the "will people actually do fully-manual entry"
question isn't automating it away — that's Copilot/Monarch's territory and
conceding it would erase Abacus's whole positioning — it's making each
manual entry faster. `ReceiptOcrService` (`lib/services/receipt_ocr_service.dart`)
lets the user snap a photo of a receipt from the log-expense sheet; on iOS,
Apple's **Vision framework** (`VNRecognizeTextRequest`,
`ios/Runner/ReceiptOcrPlugin.swift`) recognizes the text; on Android,
**Google ML Kit's** on-device text recognizer
(`android/.../ReceiptOcrPlugin.kt`) does the same job behind an identical
method-channel contract (`com.abacus.app/receipt_ocr`, `recognizeText` →
`{"lines": [...]}`) so the Dart side needs zero platform branching beyond
`ReceiptOcrService.isAvailable`. Both run entirely on-device — the photo is
never uploaded anywhere, matching the "no cloud, no bank credentials"
positioning. Recognized lines cross the method channel back to Dart, where a
pure, independently-unit-tested heuristic (`parseReceiptText` in
`lib/models/receipt_scan_result.dart`) guesses an amount (prefers a "Total"
line, falls back to the largest amount on the receipt), a vendor (first
substantial text line), and a date. Every guessed field only **pre-fills**
the existing manual log-expense sheet — the user still confirms or edits it
before it becomes a real Expense, so OCR assists entry speed without ever
silently creating a transaction on its own.

iOS and Android only (`ReceiptOcrService.isAvailable`); the "Scan receipt"
button is hidden on other platforms (web, desktop) rather than shown broken,
since there's no text-recognition plugin wired up there. Tapping it offers a
choice of camera or photo library (`image_picker`'s `ImageSource`) — needed
for testing on the iOS Simulator (no camera hardware), and a real convenience
for real users who already have a receipt photo saved.

## Flutter app (reuse from HeelEase/Regimen)

Same stack, same reasons, third time proven:
- **State management**: Provider + Hive, local-first — this time the local-
  only architecture isn't just a privacy nice-to-have, it's the literal
  product positioning ("no bank credentials, ever") in a category with a
  recent, well-known data-monetization scandal (Mint) to point at.
- **Analytics**: no analytics SDK in iOS v1. The event façade is deliberately
  a no-op so instrumentation cannot silently expand the privacy surface.
- **Payments**: RevenueCat-backed App Store validation and one non-consumable
  Founding Lifetime product; the verified `pro` entitlement is authoritative.

## Savings-buddy backend (the one networked feature)

Everything financial in Abacus is local-first Hive, by design — but the
"省钱搭子" (savings buddy) mechanic is inherently two-device and can't work
without *some* server to broker it. Rather than ship it as a permanent local
stub, it's now backed by **Supabase** (hosted Postgres + anonymous auth +
row-level security), chosen for: a generous free tier, a first-class Flutter
SDK, RLS enforced in the database rather than trusted-client code, and
accessibility from mainland China (unlike Firebase).

**The privacy boundary is the whole point of this design**: the buddy tables
store only `(anonymous_user_id, date, logged: bool)` per person per day —
never an amount, category, or note. No expense data has ever left the
device, or ever will through this path. See `app/supabase/schema.sql` for
the two tables (`buddy_links`, `buddy_marks`), RLS policies (a user can only
read/write rows for links they belong to), and the `join_buddy_link`
security-definer RPC (needed because the joiner doesn't own the link row
yet, so plain RLS would hide it from them).

**Safe-by-default, same pattern as `AnalyticsService`**: `SupabaseConfig.url`
/ `anonKey` (`config/constants.dart`) come from `--dart-define` and default
to empty. `BuddyProvider.isConfigured` gates everything — with no keys
supplied, `BuddyStreakCard` renders its original local-only invite behavior
(on-device code, "waiting to sync" copy) and zero network calls are made.
The joint-streak calculation itself (`computeJointStreak` in
`services/buddy_backend.dart`) is pure/pubspec-free logic over two sets of
dates, independently unit-tested (`test/buddy_streak_test.dart`) since live
two-device sync can't be asserted in CI.

**Setup is manual, by design**: creating a Supabase project and running the
SQL is a one-time action for whoever owns the `bambi2008/abacus` project —
not something the app or CI does automatically, since it involves an
external account and real credentials.

**2026-07-06: live updates + honest local-mode copy.** Real device testing
surfaced that the buddy card was confusing: two devices only ever saw each
other's state on their *own* next local action (no push), and the
local-only fallback (no Supabase keys) has no join flow at all — a single
device testing it alone can never see it "work," which reads as broken
rather than as the intentional local-only placeholder it is. Fixed both:
- **Supabase Realtime**: `SupabaseBuddyBackend` subscribes to
  `postgres_changes` on `buddy_links`/`buddy_marks` for the active link
  (`schema.sql` adds both tables to the `supabase_realtime` publication);
  `BuddyProvider` listens to `BuddyBackend.changes` and calls `refresh()`
  automatically. RLS applies to Realtime exactly like normal queries — a
  device only ever receives events for rows it could already read.
- **Manual refresh stays available regardless** — Realtime delivery isn't
  guaranteed (dropped connection, backgrounded app), so `BuddyStreakCard`
  always has a refresh icon rather than assuming live updates alone are
  enough.
- **Local-mode copy is now explicit** that sync isn't enabled in that
  build ("Sync isn't enabled in this build — inviting won't actually
  connect two devices yet."), instead of implying a working feature that
  silently never completes.

## Voice input (on-device speech-to-text, same "assist, never auto-submit" rule as OCR)

Second entry-speed assist alongside receipt OCR, added for the same
reason: manual entry's friction is the thing to shrink, not the thing to
architect around. `VoiceInputService` (`lib/services/voice_input_service.dart`)
wraps the `speech_to_text` package, requesting **on-device** recognition
(`SpeechListenOptions(onDevice: true)`) where the platform supports it —
consistent with the no-cloud-by-default posture, though iOS falls back to
network recognition if the on-device language pack isn't downloaded, which
is a platform limitation this app can't control. Initialization is fully
lazy — nothing touches the `speech_to_text` plugin until the user taps the
mic button, the same startup-safety pattern the in_app_purchase web-crash
fix established (never call a platform API eagerly that a given
platform/build might not support).

The transcript crosses into a pure, independently-unit-tested heuristic
(`parseVoiceExpense` in `lib/models/voice_expense_result.dart`) that takes
the first number spoken as the amount and matches a category by checking
whether any of the user's own category names appears in the transcript.
Exactly like OCR: every guessed field only pre-fills the log-expense sheet,
the raw transcript always survives as the note even when parsing gets it
wrong, and the user still confirms before anything becomes a real Expense.

## Category "boss battle" — fixing an inverted metaphor (2026-07-06)

The founder tried to explain this mechanic back to us and couldn't — a
real signal the metaphor itself was backwards, not just under-explained.
The original version labeled the bar "boss health," decreasing as the user
spent — which reads as "I'm damaging the boss" (a winning action in every
combat game convention), but hitting zero actually meant the user lost
(overspent). The win screen then said "Boss Defeated" for the *opposite*
case (the bar survived to month-end) — so the same word meant opposite
things depending on when you read it.

**Fix: the bar is now explicitly the user's own shield, not the boss's
health.** Every dollar spent is the boss's attack chipping away at it —
empty shield (spend ≥ limit) means the boss broke through and the user
lost; surviving to month-end with any shield left means the user defeated
the boss. "Defeated" now only ever appears in the win case, so it always
means the same thing. Presentation also borrows directly from combat-game
HUD convention (the founder's ask) rather than a generic progress bar:
- **Green/orange/red bar color** at >50% / 20-50% / ≤20% shield — the
  universal HP-bar convention, not a flat single color.
- **An escalating threat emoji** next to the label (😈 → 👹 → 🔥 as the
  shield drops), and 💥 the moment it breaks — same idea as an enemy
  sprite growing more aggressive as a fight goes on.
- Copy: `🛡️ 91% shield left vs. this month's Food boss` while surviving,
  `The Food boss broke your shield — you're over budget this month` on
  loss. The win screen (`CategoryChallengeWinScreen`) is unchanged — it
  was already correct under the new framing.

## Owl evolution: from a silent number to an actual moment (2026-07-06)

Feedback was blunt and correct: the owl's "care score" was just a number
going up with no payoff — evolution stage transitions were already
detected (for the `owl_evolved` analytics event) but had zero user-facing
moment, and the four evolution stages (`EvolutionStages.names`) rendered
as the exact same 🦉 glyph regardless of stage, so "evolving" was a text
label swap nobody would ever notice. Three fixes, matching what the
founder asked for specifically (a transformation moment, not just more
numbers):

- **A real full-screen celebration on evolution** — `OwlState` gained an
  `evolutionCelebrationShown` flag (mirrors `BadgeRecord.celebrationShown`);
  `refreshOwlState()` arms it on a genuine stage transition, and
  `GamificationProvider.pendingOwlEvolutionCelebration` surfaces it the
  same way `pendingCelebration` does for badges — checked in
  `_showPendingCelebrationsIfAny()` on the next natural Today-screen visit.
  `OwlEvolutionCelebrationScreen` reuses the exact same
  `CelebrationBody`/confetti/haptic/share machinery as milestone and
  category-win celebrations, with per-stage flavor text
  (`EvolutionCelebrationCatalog` in `config/constants.dart`).
- **Stages actually look different now** — `_StagedOwl` in
  `companion_owl_card.dart` scales the emoji size up per stage (no new art
  assets needed) and adds a background "aura" circle whose color intensity
  increases with stage, plus a 👑 crown overlay at the top stage (Elder
  Owl). Still the same single Unicode glyph underneath, but the growth is
  now visible, not just named.
- **A visible progress bar toward the next stage** in the companion-owl
  detail sheet, computed from `EvolutionStages.thresholds` (duplicated,
  not derived, from `GamificationProvider.evolutionStage`'s cutoffs) —
  replacing the previous bare "Care score: 47" with no context for what it
  meant or how close the next stage was.

## Categories redefined around "beyond survival" spending (2026-07-06)

The founder proposed a sharper framing than "track your spending": track
spending you actually have a *choice* about, not baseline necessities that
don't respond to day-to-day willpower anyway. Cooking at home isn't
tracked; eating out is. Public transit isn't tracked; a taxi is. Clothing
is always tracked, on the reasoning that everyone already owns clothes, so
any purchase there is a want, not a need. This directly sharpens the
"avoid consumption traps" positioning that's been the product's core bet
all along — previous categories (Food, Transport, Fun, Everything Else)
were organized around *what you bought*, not *whether you had a real
choice about buying it*, which is the actual lever the app is trying to
pull.

`StarterCategories.presets` (`config/constants.dart`) is now: Dining Out,
Snacks & Drinks, Taxi & Rideshare, Clothing & Shopping, Subscriptions, Fun
& Entertainment. No "Everything Else" catch-all — a purchase that doesn't
fit one of these is very likely not the kind of spending this app exists
to catch, and a genuine edge case can still get a custom category via
Settings. The onboarding category picker (`_PickCategoriesPage`) already
supported selecting any subset via `FilterChip` toggles, so this only
required expanding the preset pool, not touching the picker's interaction
model. All six are pre-selected by default now (previously a fixed 4 of a
4-item list) since 6 items is still scannable at a glance.

## Monthly savings recap — "you spent less than average" (2026-07-06)

The founder's idea: at each month's close, tell the user roughly how much
less they spent than a typical consumer, and frame it as something
concrete they could do with that money — the abstract "I was disciplined
this month" turned into a specific, comparable number.

**The whole feature only works if the comparison is true**, so before
building anything we researched real benchmark data (2024 BLS Consumer
Expenditure Survey, https://www.bls.gov/news.release/cesan.nr0.htm) rather
than inventing plausible-sounding averages. Three categories have a single,
clean, government-sourced national average for the exact same survey year:
- Food away from home: $3,945/yr → benchmarks the combined **Dining Out +
  Snacks & Drinks** spend (BLS doesn't split these, so neither do we for
  this comparison)
- Apparel and services: $2,001/yr → **Clothing & Shopping**
- Entertainment fees & admissions: $935/yr → **Fun & Entertainment**

**Taxi & Rideshare and Subscriptions are deliberately excluded** from the
comparison. Every available estimate for those varies 3-4x across sources
depending on methodology — some measure spend *per active user of the
service* rather than *per average American* (a very different, much
higher denominator), and subscription-spend estimates range from $86
self-reported to $273 "actual" depending on which SaaS-adjacent blog is
selling you a subscription-tracking product. A comparison claim is only as
credible as the data behind it; those two categories are still tracked
normally, just without a "vs. average" badge, rather than built on numbers
that shaky.

`computeMonthlySavings` (`models/monthly_savings_result.dart`) is a pure,
independently-unit-tested function: for each benchmark group, if the user
tracks at least one of its category names, `max(0, benchmark - actual
spend)` counts toward the total; a category that's simply *absent* from
the user's list (deleted, never added) is excluded, not assumed to be a
free win — Abacus has no way to know whether the user actually avoided
that spending or just isn't tracking it. `GamificationProvider` evaluates
this at the same month-boundary check that already runs the category boss
battles, persists a `MonthlySavingsResult` keyed by `"yyyy-MM"` (idempotent,
same pattern as `CategoryChallengeResult`), and surfaces a pending
celebration only when the total is positive — a $0 month has nothing to
celebrate.

`MonthlySavingsCelebrationScreen` reuses the standard `CelebrationBody`
machinery and frames the saved amount against a **$500 starter emergency
fund** (the standard figure cited by consumer financial educators like the
CFPB) rather than a specific product price — a round, stable heuristic
that doesn't need upkeep the way "X months of a $15.49 subscription" would
once that price changes.

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
4. **Program purchase** — Founding Lifetime only in iOS v1. Launch price and
   later value gates are documented in `founding-lifetime-pricing-and-value.md`.

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
