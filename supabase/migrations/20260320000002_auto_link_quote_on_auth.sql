-- ============================================================
-- Migration: 20260320000002_auto_link_quote_on_auth.sql
-- Server-side auto-link: when a user confirms their email or
-- signs in, link any unlinked quotes matching their email.
-- This is more reliable than the client-side auto-link which
-- can fail if the JWT isn't yet attached when the request fires.
-- ============================================================

create or replace function public.link_quotes_on_auth()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.quotes
  set user_id = new.id
  where client_email = new.email
    and user_id is null;
  return new;
end;
$$;

-- Fire on insert (new user) and on update of email/confirmed_at
create or replace trigger trg_link_quotes_on_auth
  after insert or update of email, confirmed_at, last_sign_in_at
  on auth.users
  for each row
  execute function public.link_quotes_on_auth();
