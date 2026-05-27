-- leads: all prospects regardless of source channel
CREATE TABLE public.leads (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_name text NOT NULL,
  website text,
  industry text NOT NULL,
  city text,
  state text,
  phone text,
  email text,
  email_source text,
  score int NOT NULL DEFAULT 0 CHECK (score BETWEEN 0 AND 100),
  status text NOT NULL DEFAULT 'prospect'
    CHECK (status IN (
      'prospect', 'contacted', 'replied', 'call_booked',
      'proposal_sent', 'closed_won', 'closed_lost', 'unsubscribed'
    )),
  source text NOT NULL DEFAULT 'manual',
  google_place_id text,
  notes text,
  last_contacted_at timestamptz,
  next_followup_at timestamptz,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX leads_status_idx ON public.leads (status);
CREATE INDEX leads_score_idx ON public.leads (score DESC);
CREATE INDEX leads_followup_idx ON public.leads (next_followup_at);
CREATE UNIQUE INDEX leads_place_id_idx ON public.leads (google_place_id)
  WHERE google_place_id IS NOT NULL;

-- outreach_emails: one row per email (drafts have sent_at = NULL)
CREATE TABLE public.outreach_emails (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  lead_id uuid NOT NULL REFERENCES public.leads(id) ON DELETE CASCADE,
  resend_id text,
  subject text NOT NULL,
  body_html text NOT NULL,
  sequence_step int NOT NULL DEFAULT 1,
  sent_at timestamptz,
  opened_at timestamptz,
  clicked_at timestamptz,
  replied_at timestamptz,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX outreach_emails_lead_idx ON public.outreach_emails (lead_id);
CREATE INDEX outreach_emails_resend_idx ON public.outreach_emails (resend_id)
  WHERE resend_id IS NOT NULL;

-- outreach_settings: singleton config row
CREATE TABLE public.outreach_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  emails_per_run int NOT NULL DEFAULT 3,
  runs_per_week int NOT NULL DEFAULT 2,
  follow_up_days int NOT NULL DEFAULT 3,
  max_follow_ups int NOT NULL DEFAULT 2,
  target_industries text[] NOT NULL DEFAULT '{}',
  target_cities text[] NOT NULL DEFAULT '{}',
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE public.leads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.outreach_emails ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.outreach_settings ENABLE ROW LEVEL SECURITY;
-- No policies — service_role only via Edge Functions.

-- rollback:
-- DROP TABLE IF EXISTS public.outreach_emails;
-- DROP TABLE IF EXISTS public.leads;
-- DROP TABLE IF EXISTS public.outreach_settings;
