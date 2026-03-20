-- Replace the single-row self-link policy with one that allows bulk linking
-- (all unlinked quotes matching the client's email in one update call).

drop policy if exists "clients can self-link their quote" on quotes;

create policy "clients can self-link their quotes"
on quotes
for update
to authenticated
using (
  client_email = (auth.jwt() ->> 'email')
  and user_id is null
)
with check (
  user_id = auth.uid()
);
