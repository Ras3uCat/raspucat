# 003_ui_audit_fixes / 003_missing_sections

## Status
- [x] Backlog (Draft)
- [ ] Approved
- [ ] In Progress
- [ ] Completed

---

## Overview
The site currently has two sections: Hero and Projects. Four sections are missing that
are expected in any professional portfolio: About, Skills/Tech Stack, Contact, and Footer.
The brand copy for Footer already exists in `EBrand` but is unused.

---

## User Stories
- As a potential client, I want to read a bio so I know who I'm hiring.
- As a potential client, I want to see the tech stack so I know if you fit my needs.
- As a visitor, I want a contact method so I can reach out without hunting for an email.
- As a visitor, I expect a footer with basic links and attribution.

---

## Acceptance Criteria (Binary Pass/Fail)

### About Section
- [ ] Section exists between Hero and Projects (or after Projects — owner to confirm order).
- [ ] Contains a professional bio (copy provided by owner before implementation).
- [ ] Uses existing `SectionContainer` and `NeonText` heading pattern.
- [ ] Responsive: stacks on mobile.

### Skills / Tech Stack Section
- [ ] Section displays primary technologies (Flutter, Dart, GetX, Supabase, Stripe, Firebase, etc.).
- [ ] Each skill is displayed as a neon badge/tag — reuses the tech tag pattern from `ProjectScreen`.
- [ ] Skills are grouped by category (e.g., Mobile, Backend, Tools).
- [ ] Skill tags animate in on scroll using `AnimatedOnView`.

### Contact Section
- [ ] Section has a heading and brief copy inviting contact.
- [ ] "Get In Touch" `NeonButton` opens `mailto:meow@raspucat.com`.
- [ ] Social/professional links are present (GitHub, LinkedIn — owner to confirm which).
- [ ] Icons use `FontAwesome` (already a dependency) or Flutter `Icons`.
- [ ] Links open in a new tab on web.

### Footer
- [ ] Footer exists at the bottom of the page.
- [ ] Uses `EBrand.footerText` (`"Sync complete △ M3OW"`).
- [ ] Contains copyright line (e.g., `© 2026 Ras3uCat`).
- [ ] Contains link to `raspucat.com/legal/bingequest` (or a generic legal page).
- [ ] Minimal — single row on desktop, stacked on mobile.

---

## Design Decisions
| Decision | Choice | Rationale |
| :--- | :--- | :--- |
| Section order | Hero → About → Skills → Projects → Plans → Contact → Footer | Natural narrative flow: who → what → work → hire |
| About layout | Text-focused, centered or left-aligned | No profile photo requirement; copy-first |
| Skills layout | Animated tag grid, grouped by category | Reuses existing neon badge widget |
| Contact layout | Centered CTA + icon row | Simple, no backend needed |
| Footer height | Minimal (single row) | Portfolio footer should not compete with content |
| Social links | Owner to confirm (GitHub minimum) | Cannot assume which profiles exist |

---

## Open Questions (Owner to Confirm Before Moving to Active)
1. What is the bio copy for the About section?
2. What is the complete list of skills/technologies to display?
3. Which social/professional links should appear in Contact and Footer?
4. Preferred section order on the page?

---

## Implementation Detail
**Files created:**
- `lib/app/modules/screens/about_screen.dart`
- `lib/app/modules/screens/skills_screen.dart`
- `lib/app/modules/screens/contact_screen.dart`
- `lib/common/widgets/site_footer.dart`
- `lib/app/data/models/skill_model.dart`
- `lib/app/data/projects/skill_data.dart` — static list of skills with categories

**Files modified:**
- `lib/app/modules/screens/home_screen.dart` — add new sections to scroll layout
- `lib/utils/constants/text.dart` — add section headings and copy strings

---

## Edge Cases & QA
- [ ] `mailto:` link works on both desktop (opens email client) and mobile (opens Mail app).
- [ ] Social links open in a new browser tab (`LaunchMode.externalApplication`).
- [ ] Footer legal link routes to `/legal/bingequest` without breaking SPA routing.
- [ ] Skills section doesn't overflow on screens < 360px wide.
- [ ] All new sections respect the `SectionContainer` height pattern.
