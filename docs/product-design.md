# Product Design

Screen-by-screen design for the MVP core loop, translating
`technical-architecture.md`'s data model and Duolingo mechanics into actual
screens and copy. Written before Flutter scaffolding starts, same
sequencing as HeelEase/Regimen (design → code, not the other way around).

## Navigation shell

Reuses the HeelEase/Regimen `home_shell.dart` bottom-nav pattern, three tabs:

1. **Today** — the core loop (log an expense, see today's status, streak)
2. **Progress** — spending trends, category breakdown, streak history
3. **Settings** — pricing, analytics opt-out, referral, account

No separate "Categories" tab — category management lives inside the
logging flow and a Progress sub-screen, not a top-level destination,
because it's a setup task done once, not a daily habit.

## Onboarding (Day 1 — guaranteed win)

Per the layered-onboarding mechanic in `technical-architecture.md`: Day 1
must be a guaranteed-achievable win, not a setup chore.

1. **Screen 1 — Positioning, not a form**: one sentence + one image.
   "Track spending without connecting your bank. Ever." Single CTA:
   "Get Started." (No email/account wall here — that's a documented
   drop-off point for budgeting apps; delay auth until after first value.)
2. **Screen 2 — Pick 4 starter categories** from a preset list (Food,
   Transport, Fun, Everything Else) with emoji icons, tap to select,
   editable later. Deliberately not YNAB's "give every dollar a job"
   zero-based setup — that's the exact complexity this product is
   positioned against.
3. **Screen 3 — Log your first expense right now**: a pre-filled example
   ("Coffee, $5, Food") the user edits and confirms — not a blank form.
   Completing this fires the Day-1 win: a full-screen animated confirmation
   ("Day 1 🔥 — you're on your way") and starts the streak at 1.
4. **Screen 4 — Notification permission**, asked *after* the first win
   (not before), framed around the mechanic, not generic: "Get a nudge
   before your streak resets" — ties the ask directly to something the
   user just experienced, not an abstract permission request.
5. Paywall is **not** shown during onboarding — first exposure is after
   3-5 days of engagement (see Paywall section). Forcing a purchase
   decision before the user has felt the habit is a documented mistake in
   HeelEase's early design that was corrected there; carried forward as a
   standing rule.

## Today screen (the core loop)

- **Streak counter**, top of screen, large — number + flame icon.
  Loss-aversion copy activates contextually: normal day shows "🔥 12-day
  streak"; if the user hasn't logged anything by evening (local time,
  push-triggered), copy shifts to **"You're about to lose your 12-day
  streak"** per the Kahneman/Tversky framing already decided — never
  "Don't forget to log today," always loss-framed once the deadline is
  close.
- **"Log an expense" button** — the single largest tappable element on
  the screen. Opens a 3-field bottom sheet: amount (numeric keypad,
  auto-focused), category (horizontal chip picker, most-recently-used
  first), optional note. Two entry-speed assists sit next to the sheet
  title, both on-device and both "pre-fill only, never auto-submit" (see
  `docs/technical-architecture.md`): a **mic icon** (any non-web platform)
  that transcribes a spoken amount/category via on-device speech-to-text,
  and a **camera icon** (iOS only — see "Receipt OCR") that lets the user
  snap a receipt instead of typing the amount. No date picker (always
  today; editing past days happens in Progress). Confirm → haptic tick →
  sheet dismisses → running total updates.
- **Today's spending vs. budget**, a simple bar per category, not a
  chart — "Food: $23 of $40." Deliberately terse; the daily screen is for
  logging, not analysis (that's Progress's job).
- **Streak-freeze indicator**: a small shield icon next to the streak
  count when a freeze is available (see below), tapped to see remaining
  freeze count — visible but not intrusive, so it functions as a safety
  net the user is aware of, not a hidden mechanic.
- **"That's everything I spent today" (2026-07-05)** — a low-key text
  button shown once the user has logged at least one expense that day.
  Considered and rejected: raising the streak's requirement from 1 log/day
  to a fixed count (3-5) to make the streak actually mean "complete data" —
  rejected because a fixed count is arbitrary on days with genuinely few
  transactions and would raise the core loop's daily friction right after
  the opposite direction (lower the psychological bar) was chosen. Instead
  this is a self-declared, opt-in bonus that only feeds the owl's care
  score — the streak itself never requires more than one log.

## Streak mechanics (UI surface for the retention system)

- **Streak freeze**: 1 free freeze available at any time for free users,
  auto-applies the first time a day is missed (no user action needed —
  friction-free is the point, this is what prevents the "what-the-hell
  effect" from HeelEase's original research). A push notification confirms
  after the fact: "Your streak survived — you used a freeze." Pro users get
  3 concurrent freezes and can bank one per week.
- **Buddy streak** (the viral mechanic — 2026-07-05: elevated to its own
  main-line card on Today, `BuddyStreakCard`, parallel in visual weight to
  the streak card and the companion owl card: the streak card is the
  individual habit metric, the owl is the individual emotional/growth
  metric, this card is the relational one — not buried in Settings behind
  a single list tile anymore). "Start a buddy streak" generates a share
  link/code. Once a second person joins, a **separate, second streak
  counter** appears on the Today screen (visually distinct color) that only
  increments if **both** parties log an expense that day. Losing a buddy
  streak shows both parties a joint notification — social accountability is the
  mechanic, not shame copy. **2026-07-05: real two-device sync shipped**
  (Supabase + anonymous auth, `BuddyProvider`/`SupabaseBuddyBackend`) — see
  `docs/technical-architecture.md`. Only an anonymous id, a date, and a
  logged/not-logged boolean ever leave the device; when no Supabase project
  is configured the card silently falls back to the original local-only
  invite behavior, so the app still works with zero backend.
  **2026-07-06**: real-device testing found the card confusing — added a
  Supabase Realtime subscription so both sides update live, a manual
  refresh icon as a fallback (Realtime delivery isn't guaranteed), and
  made the local-only fallback's copy explicit that sync isn't enabled in
  that build rather than implying a working feature that quietly never
  completes.
- **Milestone badges**: Day 7, 30, 100, 365 — full-screen celebration +
  a shareable image card (reuses HeelEase's shareable-achievement-card
  pattern), not gated behind Pro (badges are a retention hook, not a
  monetization lever — the Pro gate is on freeze count and insights, not
  on core achievement recognition).

## Categories & Budgets (setup screen, not a daily destination)

Reached from Progress → "Edit Budgets." List of categories, each with a
monthly limit (numeric input) and an emoji/color picker. Add/remove/reorder.
Deliberately no zero-based-budgeting requirement (categories can be
under- or over-allocated relative to income — that rigor is exactly what
YNAB owns and what this product is *not* trying to compete on).

## Progress screen

- **This month vs. last month**, one bar chart per category (reuse
  `fl_chart`, same package as HeelEase's pain-trend chart).
- **Streak history calendar** — a month grid, filled/hollow flame per day,
  same visual language as Duolingo's own streak calendar (a proven,
  recognizable pattern worth reusing rather than reinventing).
- **Edit past entries** — tap any day to see/edit/delete that day's
  logged expenses (the only place past data is editable; Today only ever
  shows today).
- **Pro: "Spending insight"** card at the top — one sentence, generated
  from the user's own structured data per the technical-architecture.md
  spec ("You've spent 40% more on dining out this month than your 3-month
  average"). Free users see a blurred/locked version of this card as the
  paywall trigger point, not a separate ad screen.

## Paywall

Triggered contextually, not on a timer alone: first shown after the Day-5
milestone *or* the first time a free-tier limit is hit (2nd streak freeze
attempt in a month, or tapping the locked insight card) — whichever comes
first. Matches the "no weekly billing, always monthly + lifetime" rule
established across all three projects this session.

- **Lifetime — $89.99**, visually primary/highlighted card ("Pay once,
  budget forever" — echoes the "no subscription trap" positioning against
  YNAB's no-free-tier $109/yr model).
- **Monthly — $7.99**, secondary card.
- Both unlock: unlimited streak freezes, buddy streaks, spending insights,
  budget history beyond 3 months.
- "Restore Purchases" link, standard placement, bottom of screen.

## Settings

- Buddy-streak invite/status lives on Today (`BuddyStreakCard`) now — the
  Settings entry here is a pointer, not a duplicate interactive control.
- **Referral**: "Know someone who'd like a high-yield savings account?" —
  surfaced here (not pushed proactively in Year 1, per the unresolved
  participation-rate question in `customer-and-market.md`) — opt-in,
  low-pressure placement rather than an aggressive prompt, since the
  conversion assumption behind this revenue line is still unvalidated and
  an aggressive placement would be the wrong thing to ship before that's
  tested.
- Analytics opt-out toggle (PostHog, same pattern as HeelEase/Regimen)
- Export data (CSV) — a genuine trust signal for the "your data, not
  ours" positioning; also functionally necessary since there's no bank
  sync to fall back on if a user wants their history elsewhere.
- Notification timing preference (supports the personalized-reminder-
  timing mechanic from technical-architecture.md)

## Deliberately out of scope for MVP

- Zero-based budgeting / envelope methodology (YNAB's territory)
- Bank account linking of any kind (the core positioning)
- B2B/employer admin console (Phase 2, not needed until the employer-
  benefit channel has an actual first customer)
- Roleplay/AI chat interfaces of any kind (this app's AI usage is limited
  to the one-sentence Pro insight card — no conversational surface)
