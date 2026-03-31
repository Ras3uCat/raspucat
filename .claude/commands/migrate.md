Create a new Supabase migration: $ARGUMENTS

Generate a timestamped migration file with correct RLS boilerplate.

**Input expected:** Migration description (e.g., "add user_profiles table", "add is_premium to profiles")

**Steps:**

1. **Generate timestamp** in format `YYYYMMDDHHMMSS` using current date/time

2. **Derive filename**: `supabase/migrations/<timestamp>_<snake_case_description>.sql`

3. **Detect migration type** from the description:
   - "create" / "add table" → new table template
   - "add column" / "alter" → alter table template
   - "add index" → index template

4. **New table template:**
```sql
-- Purpose: <one-line purpose>

CREATE TABLE IF NOT EXISTS public.<table_name> (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.<table_name> ENABLE ROW LEVEL SECURITY;

CREATE POLICY "users_select_own" ON public.<table_name>
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "users_insert_own" ON public.<table_name>
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Rollback: DROP TABLE public.<table_name>;
```

5. **Alter table template:**
```sql
-- Purpose: <one-line purpose>

ALTER TABLE public.<table_name>
  ADD COLUMN IF NOT EXISTS <column_name> <type> <constraints>;

-- Rollback: ALTER TABLE public.<table_name> DROP COLUMN <column_name>;
```

6. **Create the file** at `supabase/migrations/<timestamp>_<description>.sql`

7. **Output:**
   - Full path of created file
   - Contents of the file
   - Reminder: run `supabase db reset` locally to test before pushing
