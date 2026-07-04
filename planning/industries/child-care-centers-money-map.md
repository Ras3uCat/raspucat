# Money Map — Child Care Centers

## Section 1: The Candidate Problems (Ranked)

| # | Problem | Category | Monthly Cost | Pain Filter | Buildability Filter | Recurring Revenue Filter | Score |
|---|---|---|---|---|---|---|---|
| 1 | No online tour/waitlist booking — inquiries die in phone tag | Disconnected systems | $1,000-$3,000+ (1-3 lost enrollments/mo at $1,000-$1,230 tuition each) | ✅ Directly tied to real tuition figures | ✅ Web app: live availability, booking calendar, automated confirmations — core Raspucat stack | ✅ $147-297/mo retainer, in line with what centers already pay for CCMS tools | 9 |
| 2 | CCAP/subsidy paperwork & reimbursement tracking | Compliance/revenue-critical | $1,400+ per subsidized family during a redetermination lag | ✅ Concrete cash-flow gap per family, recurring every redetermination cycle | ✅ Deadline tracker + document checklist + status dashboard, no external API needed | ✅ $150-250/mo, scales with subsidized-family caseload | 7 |
| 3 | Staff certification & ratio compliance dashboard | Compliance/revenue-critical | Risk-based — a single citation can mean a multi-day enrollment freeze, which at $1,000+/child/month across a full room is real revenue | ✅ Quantifiable via the cost of a forced capacity freeze, not just an abstract fine | ✅ Expiry tracking + alerts, straightforward CRUD + notifications | ✅ Sits naturally alongside #2 as one compliance product | 6 |
| 4 | Tuition collection & late-payment dunning | Manual repetitive / revenue-critical | Admin hours + occasional bad debt | ✅ Real but modest | ✅ Automated reminders, Stripe autopay | ❌ Already bundled into Procare/Brightwheel's existing $85-300/mo — hard to charge a new $1,500+/mo line item for something they already nominally have | 4 |
| 5 | Staff turnover / substitute-scheduling coordination | Manual repetitive | $7,000 per turnover event, chronic understaffing | ✅ Large, well-documented industry-wide cost | ⚠️ Can only automate the notification/coordination layer (auto-text the sub list) — cannot fix the actual substitute-teacher shortage, which is the real cost driver | ❌ A free group chat does 80% of what a paid tool would; hard to justify $1,500+/mo for the remaining 20% | 3 |

---

## Section 2: Why The Failed Candidates Failed

**Tuition collection & dunning** looks painful in the ride-along (the director hand-texting a parent who's two weeks behind) but it fails the Recurring Revenue Filter, not the Pain Filter. Procare and Brightwheel — tools centers already pay for — already include billing and autopay. Charging a separate $1,500+/month retainer for something that's a checkbox feature in a tool they already own is a hard sell. This is exactly the "favor the unsexy, watch for saturation" trap — the pain is real, but the market already sells a solution to it, bundled cheap.

**Staff turnover / substitute-scheduling coordination** has the biggest raw dollar number on the whole list ($7,000/turnover) but fails the Buildability-to-Pain mapping. The actual cost driver is a nationwide substitute-teacher shortage — no software fixes that. The only piece a Claude-built tool could actually address is auto-texting the approved sub list the moment someone's marked absent, which is a real but narrow convenience most directors are already solving for free with a group chat. Don't confuse "this number is huge" with "software fixes this."

---

## Section 3: The Top 3 Survivors — Deep Dive

### #1 — No Online Tour/Waitlist Booking

**The Specific Problem:**
A prospective family finds the center, calls, and the call goes to voicemail because staff are legally in ratio with children and can't answer. By the time the director calls back — often hours later, at naptime — the family has already toured or enrolled at the next center on their list. In the ride-along, this happens by 8:35 AM (three missed calls) and resolves at 12:05 PM with a confirmed loss: "She already enrolled somewhere else."

**What they currently do about it:** Nothing structural — it's a sticky note and a callback whenever the director surfaces from ratio. Some centers have a DIY Wix/Squarespace site, but it doesn't show live per-room availability and doesn't talk to whatever CCMS they run day-to-day.

**Why It Bleeds Money:**
At $1,000-$1,230/month average tuition, losing even one family a month to a faster-responding competitor is $12,000-$14,760/year in lost recurring revenue — and this is happening in a seller's market where demand already outstrips supply, meaning the lost family isn't a maybe, it's a family who was ready to enroll somewhere. This recurs every single week a center doesn't have this system, for as long as the center exists.

**The Solution Shape:**
A center website with live per-room (age-group) availability, online tour booking with automated confirmation, and a digital enrollment application that replaces the phone-call intake — the exact front door Raspucat already builds, extended with a booking/availability layer. Category: Disconnected systems duct-taped together (phone + DIY site + CCMS that don't talk to each other). Claude can build this because it's forms, a database, a booking calendar, and automated email/SMS — no exotic integration required, and it's the same shape as every other Raspucat client-delivery build.

---

### #2 — CCAP/Subsidy Paperwork & Reimbursement Tracking

**The Specific Problem:**
Subsidized families' eligibility has to be redetermined by the state on a recurring schedule. Missing the deadline lapses the subsidy — the center still has to serve the child, but stops getting paid for that seat until it's resolved. In the ride-along, this surfaces at 10:20 AM: two families' CCAP paperwork due Friday, "$1,400 of tuition I front for a family while the state catches up on its own paperwork."

**What they currently do about it:** A physical folder, flipped through manually, hoping nothing's missed.

**Why It Bleeds Money:**
$1,400+ per family per lapse, recurring every redetermination cycle (typically every 6-12 months per family depending on state), multiplied across every subsidized family on the roster. For a center with 8-10 subsidized families, that's a real, recurring cash-flow exposure the director is currently managing with a folder.

**The Solution Shape:**
A deadline-and-document tracking dashboard: every subsidized family's redetermination date, required documents, and status, with automated alerts before a deadline lapses. Category: Compliance/revenue-critical workflow. Claude can build this as a straightforward tracking app — no need to integrate with the state's CCAP system directly, since the value is in never missing a deadline, not in automating the state's own paperwork.

---

### #3 — Staff Certification & Ratio Compliance Dashboard

**The Specific Problem:**
CPR cards, background check renewals, and staff certifications sit in a binder. A licensing inspector can show up unannounced, and one expired card is a citation — in serious cases, enough citations mean a forced capacity reduction or license action.

**What they currently do about it:** A physical binder, checked manually, usually only right before an expected inspection.

**Why It Bleeds Money:**
The dollar exposure isn't a fixed monthly fee — it's the cost of a forced capacity freeze if a citation escalates. At $1,000+/month/child, even a partial-room closure for a few weeks while a citation is resolved is a multi-thousand-dollar hit, and it's entirely preventable with a tracking system.

**The Solution Shape:**
An expiry-tracking dashboard for every staff certification and licensing document, with alerts before anything lapses — a natural companion product to the CCAP tracker (#2), since both are "don't let a deadline silently lapse" problems for the same director. Category: Compliance/revenue-critical workflow.

---

## Section 4: The Pick

**If you only attack one of these first, attack #1 — the online tour/waitlist booking and lead-capture website.**

It beats the other two on opportunity score because the pain is universal — every single center, subsidized or not, in every state, loses enrollments to phone tag and slow response, whereas the CCAP tracker only matters to centers with a meaningful subsidized caseload and the compliance dashboard is closer to insurance than a felt daily pain. It's also the lowest-risk first build: it's the exact same shape of product Raspucat already delivers (a managed website + booking system), just with a childcare-specific availability/waitlist layer bolted on — no new technical territory, no new integration risk. The ROI pitch is a one-liner a director can say yes to in the first call: "one enrollment that doesn't go to a competitor because you answered first covers a year of this."

Next step: run `/discovery-script child care centers` to get the actual questions for a first call, and validate that a real director will pay $147-297/month for exactly this — then use the CCAP and compliance dashboards as natural upsells once the first relationship is live.
