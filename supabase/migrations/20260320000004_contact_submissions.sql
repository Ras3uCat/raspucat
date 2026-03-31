-- Contact form submissions from the public marketing site
create table if not exists contact_submissions (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz default now(),
  name text not null,
  email text not null,
  message text not null,
  read boolean not null default false
);

-- Enable RLS
alter table contact_submissions enable row level security;

-- Allow anyone (anon) to insert — no auth required from the public site
create policy "anon_insert" on contact_submissions
  for insert to anon with check (true);

-- Only authenticated users (admin) can read
create policy "auth_select" on contact_submissions
  for select to authenticated using (true);
