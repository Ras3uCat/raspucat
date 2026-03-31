Run a quick environment health check for this project.

Check the following and report status for each:

1. **Flutter SDK**
   - Run: `flutter --version`
   - Report: version string or NOT_FOUND

2. **Dart Analyzer**
   - Run: `dart analyze lib/ --no-fatal-infos 2>&1 | tail -3`
   - Report: error count or CLEAN

3. **Supabase CLI**
   - Run: `supabase --version`
   - Report: version string or NOT_FOUND

4. **Stripe CLI**
   - Run: `stripe --version`
   - Report: version string or NOT_FOUND

5. **Active Feature**
   - Check: `planning/features/01_active/` for .md files
   - Report: filename and mode (FLOW/STUDIO) if present, or NO_ACTIVE_FEATURE

6. **MCP Servers**
   - Check `.claude/settings.local.json` for configured mcpServers
   - Report which servers are configured; flag any with placeholder credentials

Output a single status table:

| Component | Status | Notes |
|-----------|--------|-------|
| Flutter   | ...    | ...   |
| Dart      | ...    | ...   |
| Supabase  | ...    | ...   |
| Stripe    | ...    | ...   |
| Feature   | ...    | ...   |
| MCP       | ...    | ...   |

For any NOT_FOUND component, show the fix command on the next line.
