# Customer & Market

## The three-factor framework this idea is judged against

Coined this session after HeelEase's failure and refined through Regimen/
dating-coach analysis. A habit-app idea needs all three:

1. **Real, strong need** (not a nice-to-have).
2. **Self-discipline reliably produces the outcome** — effort maps to result
   with minimal dependence on luck, other people, or market timing.
3. **The need is perpetual** — it never gets "solved" and doesn't self-
   resolve (this is specifically why HeelEase failed: plantar fasciitis
   heals, so subscriber LTV was capped by nature of the condition).

Budgeting/money-habit formation is the cleanest fit for all three found this
session: financial stress is universal and severe (real need); consistent
spending discipline reliably improves financial position largely
independent of market returns, luck, or other people (unlike dating, where
practiced conversation skill doesn't guarantee a match says yes); and
personal finance management is lifelong, never "done" (unlike a healing
injury).

## Market geography — West-first, China deliberately deferred

Raised and resolved this session: the underlying "money stress + return to
rational spending" trend is real in China too, not just the West — 2026
research shows a genuine "分级/理性回归" (stratification + return to
rationality) shift, defensive saving becoming mainstream, and a documented
"disappearing middle class" narrative tied to real-estate decline. China
also has an existing, non-gamified competitor field (随手记 dominant,
挖财记账 for investment sync, 鲨鱼记账 for voice-input speed, 网易有钱
defunct after 6 years — a Mint-shutdown parallel) with the same gamification
gap found in the West. Separately, Chinese consumer apps have a strong
precedent for gamification mechanics working at massive scale outside
finance-as-entertainment (Alipay's 蚂蚁森林/Ant Forest), which argues the
core bet (gamified daily habit tracking) could land at least as well there.

**Decision: launch West-first anyway.** Chinese users have a well-documented
lower willingness-to-pay for non-gaming utility/productivity apps — the
dominant monetization pattern is free+ads or free+IAP-in-games, not
recurring subscriptions for a budgeting tool, which is the opposite of this
project's core bet (a paid, subscription/lifetime-purchase habit app with no
ad-supported free tier). YNAB and Monarch's proof of a real paying market
is Western. China is a real Phase 2 expansion candidate once the West-first
version is validated, not a day-one target — the payment-willingness gap is
a bigger open risk than the demand-side trend is a bonus.

## Persona

Broader than the male-specific framing of the prior two projects (HeelEase,
Regimen) — money stress isn't gendered. Core target: financially anxious
young adults (skews Gen Z/younger Millennial), digital-native, distrustful
of linking bank credentials to a third-party app (post-Mint data-selling
backlash), overwhelmed by "serious" spreadsheet-style budgeting (YNAB's
learning curve is a documented complaint), wants something that feels more
like a habit-tracker/game than an accounting tool.

### Who YNAB actually serves, and who it structurally can't (researched)

YNAB's real traffic skews 25-34 (33%) and 35-44 (21%), ~80%+ US-based,
households of two-plus sharing budget access, and — per YNAB's own
positioning — people actively paying off debt who want a system that
forces behavior change, not passive tracking. These users accept a steep
learning curve and a $109/yr price because the zero-based methodology is
the whole value proposition for them.

Three segments are named directly in user criticism as underserved by
YNAB, each for a structural reason (not just "YNAB could do this better"):

1. **Price-sensitive budget beginners (under ~$50K income)** — $109/yr
   with no free tier is explicitly called out as prohibitive for this
   group. This is a pricing-model gap, not a feature gap.
2. **Internationally-located users** — YNAB has limited bank-linking
   support outside the US/UK/EU. This is the sharpest, most structurally-
   matched gap for Pocklume specifically: YNAB's limitation exists *because*
   it's a bank-linking product, and international bank API coverage is
   incomplete. Pocklume's core architecture never needed bank-linking in the
   first place ("no bank credentials, ever" — chosen originally as a
   privacy/trust wedge) — so this isn't a market Pocklume has to build new
   capability to serve, it's a market its existing architecture already
   fits. Worth treating as a real secondary segment, not just an
   afterthought.
3. **Complexity-averse users** — direct quotes describe YNAB as
   "unnecessarily complicated," with its own vocabulary ("budget" doesn't
   mean what you think it means). This is the segment the gamification bet
   was already aimed at; this research confirms it by name rather than
   just inferring it from YNAB's UI.

**One segment is explicitly NOT a fit, and worth ruling out on purpose**:
"set-and-forgetters" who want automation, not manual entry — YNAB doesn't
serve them well, but neither does Pocklume (also manual-entry-first). That
segment's actual home is Monarch/Copilot (bank-linked, automated). Chasing
them would mean abandoning the "no bank credentials" architecture that is
Pocklume's core differentiation — not a segment to target, a segment to
consciously not chase.

## Market sizing — real, proven, not speculative

- **YNAB**: ~$49M ARR, bootstrapped, profitable, no outside capital,
  $14.99/mo or $109/yr, no free tier, no ads, no data-selling, no affiliate
  bank fees — pure subscription. Industry framing: "the market's most
  durable franchise — low growth but extremely high retention."
- **Mint's 2024 shutdown** (3.6M active users, was free/ad-supported/
  data-monetized) validated that users will pay ~$100/year for a
  replacement — Monarch Money grew subscribers 20x absorbing that gap.
- **Category ceiling, stated plainly by industry analysts**: "pure
  subscription budgeting is a $100M business, not a $1B one." This is
  bigger than every previous idea this session (HeelEase, Regimen,
  Rapport-adjacent dating coaches all top out in the single-digit millions
  for a realistic small-team outcome) but smaller than Duolingo-scale
  ($563M) or platform-scale (billions) — a real, honest ceiling to plan
  against.
- **Named trend validating this exact positioning**: "privacy-first,
  no-bank-linking" alternatives (Goodbudget, Finny) are called out as a
  rising segment specifically in reaction to Mint's data-monetization
  model — this is the same "local-first, don't hand over your data" wedge
  that worked as positioning in HeelEase and Regimen, here applied to a
  category with an actual recent scandal (Mint) to point at.

## Competitor teardown

| App | Model | Pricing | Notes |
|---|---|---|---|
| **YNAB** | Bank-linkable, manual "zero-based" methodology (give every dollar a job) | $14.99/mo or $109/yr, no free tier | ~$49M ARR, category leader, steep learning curve is a common complaint, no gamification layer |
| **Monarch Money** | Bank-linked, automated categorization | $14.99/mo or $99/yr | Grew 20x post-Mint-shutdown; positioned as "what Mint could have become" |
| **Copilot Money** | Bank-linked, praised UI | Subscription | iOS/Mac only — no Android, a real gap |
| **Rocket Money** | Bank-linked | Subscription + takes a cut of negotiated bill savings | Second revenue engine beyond subscription — the pattern industry analysts say separates 2026's winners |
| **Mint** (defunct 2024) | Free, ad-supported, sold user data | Free | Cautionary tale: the free/data-monetization model proved unsustainable and got shut down by Intuit |
| **Goodbudget / Finny** | Manual entry, no bank credentials required (envelope budgeting) | Free tier + paid | Closest positioning match (privacy-first, manual) — but not gamified in the Duolingo sense |

**The gap**: every competitor competes on bank-linking convenience and
automation (or, for Goodbudget/Finny, on privacy positioning alone). **None
apply real Duolingo-style habit mechanics** — loss-aversion-framed streaks,
a streak-freeze safety net, buddy/friend accountability streaks, or a
layered onboarding-achievement curve — to the daily logging habit itself.
The market has picked between "convenient but hands-off" (bank-linked,
weaker adherence per the same research that found manual/enforced methods
produce 20-30% better budget adherence) and "manual but plain" (Goodbudget).
Nobody has combined manual/private with genuinely gamified.

## Honest verdict

**What's real**: this category has the cleanest fit yet against the
three-factor framework, a proven $49M-ARR bootstrapped category leader
(YNAB) with no venture funding needed to reach that scale, a recent market
disruption (Mint's shutdown) proving demand is real and portable, and a
specific, named execution gap (gamification) in an otherwise mature field.

**What's not proven**: whether gamifying manual expense entry (vs. YNAB's
serious methodology or Monarch's automation) is what's actually missing, or
whether users who want budgeting help specifically want automation to
reduce effort — not more game mechanics layered onto a chore. The research
note that "automation-first apps achieve 2x higher retention among busy
users" cuts directly against a manual-entry-first bet. This is the load-
bearing assumption for this whole concept and needs to be pressure-tested
with real users, not just argued from first principles.

### Follow-up research (2026-07-05): is manual entry actually a viable daily ask?

Two real data points partially de-risk this, though they don't fully
resolve it:

- **Real transaction volume is lower than intuition suggests.** The Federal
  Reserve's 2026 Diary of Consumer Payment Choice found consumers average
  16 credit + 15 debit + 6 cash payments per month — **~37/month, ~1.2
  transactions/day**. Card + digital payments are ~2/3 of all transactions;
  cash is ~1 in 7 and concentrated in demographics *outside* Pocklume's
  target (households under $25K/year, ages 55+, rural) — meaning the
  actual target user (younger, urban, digital-native) likely transacts
  even more card-heavy than the average. The core mechanic only requires
  logging *at least one* expense per day to hold a streak — at ~1.2
  transactions/day average, that's close to "log the one thing you did
  today," not "reconstruct a full ledger from memory every night."
- **Manual friction may be a feature, not just a retention cost.** NBER
  research found people who manually record transactions **spend 15-20%
  less** than people relying on automated bank-linked tools — the same
  friction that automation researchers cite as a retention drag is also
  the mechanism behind the actual behavior change budgeting apps are
  supposed to produce. Separately, research on why manual tracking gets
  abandoned points to **consistency collapse, not per-entry effort**: "miss
  two days and the backlog grows, so people quit" — which is exactly the
  failure mode the existing streak-freeze mechanic (auto-applied, no user
  action) was already built to intercept, not a new problem to solve.

**Net effect on the open question**: this doesn't prove gamified manual
entry beats automation for THIS product specifically — that still needs
real users. But it does undercut the strongest version of the counter-
argument ("nobody will do this daily") — the daily ask is smaller than it
sounds, and the mechanism already built (streak freeze) targets the
specific way manual tracking actually fails in practice.

**Score against the framework**: cleaner fit than HeelEase, Regimen, or the
dating-coach idea on the "self-discipline reliably produces the outcome"
axis — but competing in the most mature, best-funded field attempted this
session. The opportunity is a specific execution bet (gamified manual
entry), not a demand bet — demand for budgeting help is already proven at
scale by YNAB and Monarch.

## Final verdict, after running the numbers (`financial-model-year1-3.xlsx`)

Same methodology as HeelEase/Regimen: 3 scenarios, 36-month cohort model,
verified zero formula errors via LibreOffice recalculation, cross-checked
against an independent Python simulation. Target: **$10,000/mo** (carried
forward from Regimen for comparability).

**v2 update**: the model now has **four revenue engines**, not two — added
add-on ARPU (virtual goods + paid course) and a B2B employer-benefit channel
alongside the original program purchase and referral lines (see
`technical-architecture.md` for what each one is and what it's anchored to).

| | Year 1 | Year 2 | Year 3 | Month-36 run-rate |
|---|---|---|---|---|
| Conservative | $4,217 | $14,921 | $33,163 | $3,248/mo |
| **Base Case** | $15,929 | $73,965 | $185,203 | **$19,293/mo** |
| Optimistic | $64,081 | $401,087 | $1,353,535 | $154,561/mo |

Base Case month-36 run-rate nearly doubled versus the two-engine version
($13,500/mo → $19,293/mo) and clears the $10,000/mo target with more room.
More importantly, the composition changed:

| Engine | Month-36 $ (Base Case) | Share |
|---|---|---|
| Referral | $8,537 | 44% |
| Program (lifetime + sub) | $4,963 | 26% |
| B2B employer-benefit | $3,777 | 20% |
| Add-on (virtual goods + course) | $2,016 | 10% |

**The catch is smaller now, and more precisely located.** In the two-engine
version, 63% of revenue sat on referral revenue, and *both* its inputs
(bounty size and participation rate) were unchecked guesses. After
validating the bounty against real fintech affiliate programs this session
(Comenity Direct $150/CPL, Barclays $250-300/CPL, Betterment $150/sale — all
above the model's conservative $30 assumption), referral's share of the
*true unvalidated risk* drops even though its *revenue share* (44%) is
still the largest single line. The **only number in the entire model with
zero real-world anchor is the referral participation rate**
(0.5-1.2% of active users/month) — bounty size, add-on ARPU, and B2B seat
pricing are now all checked against disclosed real terms, even though the
specific rate at which Pocklume's own users behave in each case is still
inferred, not measured.

B2B's contribution is modest and plausible for a bootstrapped, no-sales-team
motion: ~54 active SMB contracts averaging 20 employees each by month 36
(Base Case) — not a number that requires an enterprise sales org to
believe, unlike, say, a model that assumed hundreds of large-employer deals.

**Bottom line**: this model is more diversified and better-anchored than
the two-engine version, but the fundamental caveat from before still
applies in a narrower form — the single largest revenue line (referral, 44%)
still rests on a participation-rate assumption that can only be resolved
with real user data, not further desk research. If referral participation
comes in at a quarter of what's modeled, month-36 run-rate drops to roughly
$12,900/mo (still clears the $10,000/mo target, unlike the old two-engine
model's equivalent scenario) — the added diversification is what changes
the outcome, not just the bigger headline number.

## v3: net profit (not just revenue), and a market-share reality check

v3 adds operating costs (customer support headcount, infra/tools, Apple
fee — see `technical-architecture.md` for the full breakdown) and judges
the $10,000/mo target against **net profit**, a stricter bar than the
revenue-only figures above.

| | Year 1 Profit | Year 2 Profit | Year 3 Profit | Month-36 Profit Run-Rate |
|---|---|---|---|---|
| Conservative | $2,414 | $10,591 | $25,815 | $2,570/mo |
| **Base Case** | $13,129 | $65,077 | $167,178 | **$17,536/mo** |
| Optimistic | $59,378 | $381,251 | $1,293,693 | $148,446/mo |

Base Case still clears $10,000/mo even after opex — because opex stays
structurally low (Year 3 opex is under 10% of Year 3 revenue in every
scenario), the profit haircut versus the revenue-only numbers is modest.

**Customer service headcount, the number asked for directly**: Base Case
needs a **recommended 1 person** (rounded up from 0.68 fractional FTE) by
month 36; Conservative also rounds to 1 (0.24 FTE — mostly idle capacity);
Optimistic needs **2** (1.71 FTE). None of the three scenarios require a
support hire in Year 1 — a founder can realistically handle support solo
through most of the ramp.

### Year-by-year detail (Base Case)

| | Year 1 | Year 2 | Year 3 |
|---|---|---|---|
| Net Revenue | $15,929 | $73,965 | $185,203 |
| Paying Customers (end of year) | 124 | 444 | 1,034 |
| Market Share of Category TAM | 0.005% | 0.018% | 0.041% |
| Total Opex | $2,800 | $8,888 | $18,025 |
| Net Profit | $13,129 | $65,077 | $167,178 |
| Net Margin (= Gross Margin here) | 82.4% | 88.0% | 90.3% |

Conservative and Optimistic year-by-year tables are in the spreadsheet
(`financial-model-year1-3.xlsx`, Summary tab) — same structure, all three
scenarios side by side.

**On margin**: net margin and gross margin are the same number in this
model because there's no separate COGS/SG&A split — Total Opex (support +
infra + Apple fee) is the only cost layer, and no paid user-acquisition
spend is budgeted anywhere (growth is assumed organic, per
`promotion-plan.md`). A business that spent on paid acquisition or added
headcount beyond support would see gross margin stay high while net margin
fell below it — that gap doesn't show up here because that spending isn't
modeled. Margin climbs over the 3 years in every scenario because revenue
grows faster than the support/infra costs that scale with it (a low-
overhead product structurally benefits from this kind of operating
leverage) — Base Case goes from 82% to 90% net margin Year 1 to Year 3.

### v5→v6: adding paid acquisition, then testing whether a better channel fixes the ratio

**v5** modeled generic paid acquisition: ad spend as a % of the *prior*
month's net revenue reinvested into paid installs (10%/15%/20% across
Conservative/Base/Optimistic) at a generic fintech CPI (~$3.50-8) —
self-funded, no outside capital. Paid installs add to organic installs;
they don't replace them.

The founder's reaction to v5's numbers (a ~$295 Year-1 CAC per converted
customer against a ~$64 program-only LTV) was that the ROI looked bad. It
was right to react that way: the rigorous framing — **cost per install vs.
blended value per install** (program revenue × conversion + referral +
add-on, since ad spend buys installs, not hand-picked converters) — put
v5's ratio at **0.96:1 in Year 1** and **1.79:1 in Year 3**, both below the
industry-standard **3:1 "healthy" LTV:CAC benchmark** (payback under 12
months, elite operators hit 5-7 months; under 1:1 means losing money per
customer).

**v6 tested the obvious fix**: switch to Apple Search Ads specifically,
the best-fit paid channel for finance apps per real 2026 data (finance CPI
$4.13-8.23, Day-1 retention 35-45% vs. Google UAC's 25-35% or TikTok/Meta
finance CPMs of $11+). Modeled with real ASA CPI ($7.00/$5.50/$4.00) and a
conversion-quality multiplier for paid installs (1.25x/1.35x/1.45x,
extrapolated from the retention gap).

**Result — an honest non-improvement**: the ratio barely moved (0.96:1 →
0.96:1 Year 1; 1.79:1 → 1.77:1 Year 3). The higher-intent traffic's better
conversion is real, but realistic ASA CPI for finance ($5.50) is itself
higher than the earlier generic guess ($5.00) — the two effects roughly
cancel. **The conclusion isn't "try a different channel," it's that paid
acquisition on any channel isn't a strong lever for this product yet.**

| | Year 1 | Year 2 | Year 3 |
|---|---|---|---|
| Net Revenue | $16,812 | $81,711 | $217,186 |
| Ad Spend | $2,144 | $11,135 | $30,616 |
| Paid Installs Bought | 390 | 2,024 | 5,567 |
| Paying Customers (end of year) | 133 | 514 | 1,299 |
| Market Share of Category TAM | 0.005% | 0.021% | 0.052% |
| Total Opex (excl. ads) | $2,879 | $9,483 | $20,081 |
| Net Profit (after ads + opex) | $11,789 | $61,093 | $166,488 |
| Net Margin | 70.1% | 74.8% | 76.7% |

*(Base Case shown, v6/ASA numbers; Conservative and Optimistic are in the
spreadsheet.)*

**Practical takeaway**: don't budget for a paid-acquisition program in
Year 1 expecting it to be profitable on its own — at these unit
economics it's roughly break-even at best. Lean on organic (FinTok-style
educational content, ASO, the built-in buddy-streak viral mechanic) as the
real growth engine; treat any paid spend (ASA or otherwise) as a small,
opportunistic supplement once Year 2-3 conversion rates make the ratio
look better (1.77:1, still below 3:1 but no longer break-even), not a
primary lever to plan around.

**Where this breaks down — read before trusting the Optimistic scenario**:
the model holds CPI constant regardless of spend scale. Optimistic
compounds into ~$59,730/mo of ad spend by month 36 — spending that much in
a niche category at a flat CPI is not realistic; real channels saturate.
Treat Optimistic's paid-acquisition figures as illustrating the mechanic's
upper bound, not a real 3-year plan. Base Case and Conservative stay in a
believable spend range.

**Market share — the honest, humbling number**: using the global
"budgeting app" category's ~$260M 2026 revenue estimate (a figure that
should be treated with real skepticism — a different 2026 source puts the
US market alone at ~$0.34B, which cannot be reconciled with a $0.26B global
figure; published TAM sizing for this specific sub-category is inconsistent
across research firms) and an assumed ~$104/year category ARPU (anchored to
YNAB's $109/yr and Monarch's $99/yr), the implied total paying-customer
base for the category is ~2.5M people.

Pocklume's Base Case active paying-customer base at month 36 (active
subscribers + cumulative lifetime buyers) is **~1,034 people** — an implied
market share of **~0.04%**. A more concrete, single-anchor comparison: that
is **~0.23% of YNAB's own implied customer count** (YNAB's $49M ARR ÷ $109
≈ 450,000 customers). This is not a rounding error to explain away — it is
the realistic scale of a 3-year-old bootstrapped niche entrant, and it is
worth sitting with plainly: **the unit economics clearing the profit target
does not mean the business has meaningfully dented the category** — it
means the product can be profitable at a very small scale because it is
low-overhead and high-margin, not because it has won meaningful share.
Category leadership was never the 3-year plan and these numbers confirm it
shouldn't be treated as one.
