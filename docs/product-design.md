# Product Design

Screen-by-screen design for the MVP core loop, translating
`technical-architecture.md`'s data model and Duolingo mechanics into actual
screens and copy. Written before Flutter scaffolding starts, same
sequencing as HeelEase/Regimen (design → code, not the other way around).

## Navigation shell

Reuses the HeelEase/Regimen `home_shell.dart` bottom-nav pattern, three tabs:

1. **Today** — the core loop (log an expense, see today's status, streak)
2. **Progress** — spending trends, category breakdown, streak history
3. **Settings** — pricing, referral, buddy-data controls, legal links

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
2. **Screen 2 — Pick starter categories** from a preset list (Dining Out,
   Snacks & Drinks, Taxi & Rideshare, Clothing & Shopping, Subscriptions,
   Fun & Entertainment — see "Categories & Budgets" below for why these
   six specifically), all pre-selected by default, with emoji icons, tap
   to deselect, editable later. A trailing **"Add custom"** chip opens a
   name+emoji dialog for anything that doesn't fit the presets — added
   2026-07-06 after the founder noticed the copy ("you can add... anytime")
   wasn't actually backed by an add flow here. Deliberately not YNAB's
   "give every dollar a job" zero-based setup — that's the exact
   complexity this product is positioned against.
3. **Screen 3 — Log your first expense right now**: a pre-filled example
   ("Coffee, $5") the user edits and confirms — not a blank form. The
   preview card's category label/emoji dynamically match whatever the user
   actually selected on Screen 2 (preferring "Snacks & Drinks" if picked,
   since that's the clearest real-world fit for a coffee purchase) — this
   used to be hardcoded to a stale "Food" category left over from an
   earlier category set, which meant what the card showed and what
   actually got logged didn't match; fixed alongside the "Add custom" chip.
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
- **"Log an expense" button** — the single most important tappable element
  in the app (the entire core loop runs through it), styled with
  full-saturation primary color and bold/larger text rather than Material
  3's default muted FAB — deliberately no idle animation on it, since
  unlike a one-time celebration this gets tapped many times a day and
  constant motion on something that frequent would tire rather than draw
  the eye. Opens a 3-field bottom sheet: amount (numeric keypad,
  auto-focused), category (horizontal chip picker, most-recently-used
  first), optional note. Two entry-speed assists sit directly under the
  amount field, not up in the sheet header — one-handed thumb reach is
  better lower in the sheet than at its very top — both on-device and both
  "pre-fill only, never auto-submit" (see `docs/technical-architecture.md`):
  a **mic icon** (any non-web platform) that transcribes a spoken
  amount/category via on-device speech-to-text, and a **camera icon** (iOS
  only — see "Receipt OCR") that lets the user snap a receipt instead of
  typing the amount. No date picker (always today; editing past days
  happens in Progress). Confirm → haptic tick → sheet dismisses → running
  total updates.
- **Category spend this month**, one line per category plus the boss
  battle shield bar — no chart, terse by design. **2026-07-06: dropped
  the original daily-pace bar** ("Food: $23 of $40" framing, where $40
  was silently derived as monthlyLimit÷30) — the founder asked what "$0
  of $7" meant and the honest answer was "an arbitrary number nobody set,
  from a framing that never fit discretionary spending anyway" (nobody
  budgets $6.67/day on snacks; that spending happens in occasional
  lumps). Monthly is the natural unit for the new discretionary
  categories, and the boss battle bar already covers it — showing a daily
  pace *and* a monthly one was two progress metrics for the same
  underlying number.
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

Reached from Progress → the tune icon → "Manage categories"
(`CategoryManagementScreen`). List of categories, each with a monthly
limit and an emoji, tap to edit, swipe to delete (a confirmation is honest
that past expenses aren't deleted, just show as "Uncategorized" — the
Progress screen's recent-entries list already handled a missing category
gracefully before this screen existed to ever trigger it). A trailing "+"
in the app bar adds a new one. Deliberately no zero-based-budgeting
requirement (categories can be under- or over-allocated relative to
income — that rigor is exactly what YNAB owns and what this product is
*not* trying to compete on).

**This screen didn't exist until 2026-07-06** — onboarding was the only
place a category could ever be created; nothing after that could add,
edit, or delete one, despite this doc describing the screen since the
original design pass. Built alongside a fix to the starter presets'
default monthly limits: every category used to get the same flat $200,
which (once the categories became discretionary-specific, see below)
made limits like "Subscriptions: $200" meaningless — `StarterCategories.presets`
now carries a distinct starting limit per category
(`config/constants.dart`), all still freely editable here.

**2026-07-06: starter categories redefined around "beyond survival"
spending** — Dining Out, Snacks & Drinks, Taxi & Rideshare, Clothing &
Shopping, Subscriptions, Fun & Entertainment (see
`docs/technical-architecture.md`). Necessities you don't really have a
day-to-day choice about (groceries you cook, rent, public transit) aren't
in the default set at all; no "Everything Else" catch-all either, on the
reasoning that a purchase not fitting one of these six is unlikely to be
the kind of spending this app exists to catch.

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
- **Monthly savings recap (2026-07-06)**: a full-screen celebration at
  month's close comparing the user's spend in three categories against
  real 2024 BLS national averages, framed as progress toward a $500
  starter emergency fund — not gated behind Pro, same reasoning as
  milestone badges (a retention/motivation hook, not a monetization
  lever). See `docs/technical-architecture.md` for exactly which
  categories are compared and why two are deliberately excluded.
  **A "Monthly savings" history list was added to Progress the same
  day** — the celebration only ever fires once per month, and until
  this existed that was the *only* place the number was ever visible;
  afterward it was computed, persisted, and effectively invisible
  forever. The list shows every evaluated month, including $0 ones —
  showing only the wins would make it decorative rather than an honest
  record.

## Paywall

Triggered contextually, not on a timer alone: first shown after the Day-5
milestone *or* the first time a free-tier limit is hit (2nd streak freeze
attempt in a month, or tapping the locked insight card) — whichever comes
first. Matches the "no weekly billing, always monthly + lifetime" rule
established across all three projects this session.

- **Lifetime — $89.99**, visually primary/highlighted card ("Pay once,
  budget forever" — echoes the "no subscription trap" positioning against
  YNAB's no-free-tier $109/yr model).
- **No recurring plan in v1.** Founding Lifetime launches at $19.99; see
  `founding-lifetime-pricing-and-value.md` for the evidence and price gates.
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
- No analytics SDK in the privacy-first iOS launch.
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
