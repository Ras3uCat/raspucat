-- Allow authenticated clients to self-link their quote on first portal login.
-- The magic link flow guarantees the email is verified, so matching on
-- client_email is safe. The policy only fires when user_id is still null.

create policy "clients can self-link their quote"
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
