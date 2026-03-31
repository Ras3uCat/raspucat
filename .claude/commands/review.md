Review the code changes in the current session or the specified file/feature: $ARGUMENTS

Perform a structured code review covering:

1. **Architecture Compliance**
   - Repository pattern in place (no direct Supabase calls from controllers or widgets)
   - No business logic in widgets
   - GetX wiring correct (`GetView<TController>`, `Obx()`, `.obs` RxTypes)

2. **The Nevers Check**
   - [ ] No business logic in Widgets
   - [ ] No file exceeds 300 lines
   - [ ] No client-side auth/permission/payment state decisions
   - [ ] No bypass of Repository pattern
   - [ ] No contradiction with `planning/DECISIONS.md`

3. **Design Token Compliance**
   - EColors, ESpacing, ETextStyles used — no inline hex or magic numbers

4. **Security Audit**
   Invoke the security-auditor agent on all changed files.
   Append findings under "## Security Findings".
   Any CRITICAL or HIGH finding → overall review status is FAIL.

5. **Test Coverage**
   - Corresponding test file exists for every new repository/controller

Output a markdown report with PASS / WARN / FAIL per section and file:line citations for issues.
