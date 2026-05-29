# Money Map — Tattoo Shop

*Source signal: Industry Download + Ride-Along (tattoo-shop)*

---

## Section 1: The Candidate Problems (Ranked)

| # | Problem | 5BP Category | Monthly Cost | Pain | Build | Recurring | Score |
|---|---|---|---|---|---|---|---|
| 1 | No-shows + deposit non-enforcement | Manual repetitive + Disconnected systems | $2,400–$6,400/shop | ✅ | ✅ | ✅ | **9** |
| 2 | DMs as the entire booking system | Disconnected systems duct-taped together | $3,000–$6,000/shop | ✅ | ✅ | ✅ | **9** |
| 3 | Pre-consult intake gap / walkout loss | Manual repetitive work | $600–$1,200/artist | ✅ | ✅ | ✅ | **8** |
| 4 | Aftercare CRM + healed photo follow-up | Manual repetitive work | $300–$600/artist | ✅ | ✅ | ✅ | **7** |
| 5 | Flash drop / event booking chaos | Manual repetitive + Previously impossible | Hard to quantify | ⚠️ | ✅ | ✅ | **6** |
| 6 | BPP / health inspection compliance tracking | Compliance/revenue-critical | $200–$2,000/incident | ✅ | ✅ | ⚠️ | **5** |
| 7 | Artist retention / booth rental contract mgmt | Compliance/revenue-critical | $10K–$30K/departure | ✅ | ⚠️ | ⚠️ | **4** |
| 8 | Supply/inventory management | Manual repetitive work | $500–$2,000/quarter | ⚠️ | ✅ | ❌ | **3** |

**Note:** Problems 1, 2, and 3 are the same product. They surface from different pain entry points but any build attacking one necessarily addresses all three.

---

## Section 2: Why the Failed Candidates Got Cut

**Supply/inventory management** — Fails Recurring Revenue. $500–$2K/quarter is the entire pain. Hard to justify $1,500+/month for a restock alert system.

**Artist retention / booth rental management** — Fails Buildability and Recurring Revenue. The real pain is people and culture, not software. Contract tracking doesn't prevent departures — it just documents them.

**BPP / compliance tracking** — Fails Recurring Revenue at the shop level. Compliance incidents are infrequent. Hard to justify ongoing monthly cost when the catastrophic event happens once a year at most.

**Flash drop booking** — Pain filter is soft. "I sold out in 20 minutes" is said with pride, not frustration. Good Phase 2 feature; wrong first target.

---

## Section 3: Top 3 Survivors — Deep Dive

---

### #1 — Tattoo-Native Booking + No-Show Protection + Pre-Consult Intake

**The Specific Problem**

Three interlocking problems with one root cause: no structured entry point into the booking relationship. A client's first contact is an Instagram DM — unstructured, uncheckable, untrackable. From there, the artist manually negotiates style, placement, size, deposit, and timing over a thread that looks like group chat from 2014.

The result: no-shows (deposit too small to sting), consult walkovers (client was never pre-qualified), and 1–2 hours/day per artist burned on inbox management.

Ride-Along bleeding moments:
- **10:02 AM:** Artist eats a no-show rather than charge the forfeit — no system to make it non-awkward
- **11:30 AM:** Marcus loses a $600 three-hour block to a no-show protected by a $75 deposit
- **1:05 PM:** 40-minute consult ends with "I'll think about it" — zero automated follow-up scheduled

**Why It Bleeds Money**

For a 2-artist shop, 5 days/week:
- 1 no-show per artist/week × $240 shop cut = ~$2,000/month
- 1 consult walkover per artist/week × $750 avg value × 30% recapture = ~$450/month recoverable
- 90 min/day DM management per artist × $150/hr × 22 days = ~$4,950/month in time value

**Conservative combined total: $3,500–$7,000/month per shop, ongoing.**

**The Solution Shape**

A booking flow built for tattoo artists. Artist publishes a profile link (Instagram bio, Google Maps, website). Link shows portfolio filtered by style, available windows, and a structured intake form: style, placement, size, reference images (up to 6), skin tone, budget. Submitting routes to deposit payment with configurable forfeit window stated upfront. Automated SMS/email reminders at 48hr and 2hr. Cancel inside the window → forfeit triggered automatically. Session complete → aftercare instructions + 6-week healed photo request.

**5BP category:** Disconnected systems duct-taped together (Instagram + DMs + Square + Post-Its → one structured flow)

**Build time:** 2–3 weeks with Claude Code. Booking form + Supabase + Stripe deposits + Twilio SMS. No ML, no mobile app, no real-time hardware.

---

### #2 — Aftercare CRM + Healed Photo Follow-Up Loop

**The Specific Problem**

No structured post-session relationship. Instructions are verbal or printed. The 6-week healed window is entirely dependent on client memory. Artists give away touch-ups to clients with no documented aftercare compliance, and miss hundreds of portfolio-ready healed photos per year.

**Monthly cost:** $300–$750/month in unbillable touch-up labor per artist, plus compounding portfolio and Instagram growth drag.

**The Solution Shape**

Client record at session completion. Auto aftercare text on session end. 7-day check-in. 6-week healed photo request with one-tap upload. Photo lands in artist dashboard tagged to client + piece. Touch-up window tracked automatically.

**Build time:** 1–2 weeks as a module. CRM + SMS automation + image storage (Supabase Storage).

---

### #3 — Flash Drop Event Booking

**The Specific Problem**

Flash days currently run on Instagram Stories + DM claims + Venmo. Artists manually track who claimed what with no waitlist, no deposit enforcement, no real-time inventory.

**Monthly cost:** $300–$1,000 per event in lost conversions due to DM friction.

**The Solution Shape**

Artist creates a flash drop: uploads designs, sets price, opens at a specific time. Clients browse, claim a design, pay deposit in under 2 minutes. Sold designs gray out in real time. Waitlist auto-fills cancellations. Artist wakes up to a fully booked flash day.

**Build time:** 2 weeks. Time-gated booking with limited inventory slots + Stripe + image gallery.

---

## Section 4: The Pick

**Attack #1 first — the tattoo-native booking + no-show protection system.**

It beats the others on every dimension that matters. The dollar pain is the highest and most quantifiable ($3,500–$7,000/month per shop), the build is the most straightforward (form + Stripe + SMS), and every other problem on this list is either a natural feature extension of this product or a downstream benefit of solving this one first. Aftercare follow-up? Session-complete trigger. Flash drops? Event booking type. You're not building three products — you're building one with a clear upgrade path.

The competitive moat is positioning, not technology. Square and Vagaro technically do some of this. They just weren't built for tattoo culture and every artist knows it. "Deposit-to-credit logic," "style intake before consult," and "healed photo request at 6 weeks" are features no generic scheduling tool will ever build. That's the wedge.

**Next step:** Run discovery calls with 3–5 tattoo artists. Test: *"Is the no-show + deposit problem your biggest scheduling headache, or is it something else?"* If validated — and the Ride-Along strongly suggests it will be — you have your build target.
