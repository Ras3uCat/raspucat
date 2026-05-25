-- Booking system: availability_rules, availability_blocks, bookings
-- All client access goes through Edge Functions (service_role key bypasses RLS).
-- No direct Flutter client writes to any of these tables.

-- availability_rules: Ryan's recurring weekly availability
CREATE TABLE public.availability_rules (
  id          uuid    PRIMARY KEY DEFAULT gen_random_uuid(),
  day_of_week int     NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
  start_time  time    NOT NULL,
  end_time    time    NOT NULL,
  is_active   boolean NOT NULL DEFAULT true,
  created_at  timestamptz DEFAULT now()
);

ALTER TABLE public.availability_rules ENABLE ROW LEVEL SECURITY;
-- No policies: only service_role (Edge Functions) can access.

-- availability_blocks: admin-blocked time ranges (vacation, hold)
CREATE TABLE public.availability_blocks (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  blocked_from timestamptz NOT NULL,
  blocked_until timestamptz NOT NULL,
  reason       text,
  created_at   timestamptz DEFAULT now(),
  CONSTRAINT no_zero_duration CHECK (blocked_until > blocked_from)
);

ALTER TABLE public.availability_blocks ENABLE ROW LEVEL SECURITY;
-- No policies: only service_role (Edge Functions) can access.

-- bookings: individual confirmed/cancelled/rescheduled bookings
CREATE TABLE public.bookings (
  id                 uuid  PRIMARY KEY DEFAULT gen_random_uuid(),
  session_type       text  NOT NULL CHECK (session_type IN ('discovery_call', 'project_checkin')),
  start_at           timestamptz NOT NULL,
  end_at             timestamptz NOT NULL,
  status             text  NOT NULL DEFAULT 'confirmed'
                           CHECK (status IN ('confirmed', 'cancelled', 'rescheduled')),
  name               text  NOT NULL,
  email              text  NOT NULL,
  message            text,
  quote_id           uuid  REFERENCES public.quotes(id) ON DELETE SET NULL,
  cancellation_token uuid  NOT NULL DEFAULT gen_random_uuid() UNIQUE,
  google_event_id    text,
  meet_url           text,
  created_at         timestamptz DEFAULT now(),
  CONSTRAINT no_zero_duration CHECK (end_at > start_at)
);

CREATE INDEX bookings_start_at_idx       ON public.bookings (start_at);
CREATE INDEX bookings_status_idx         ON public.bookings (status);
CREATE INDEX bookings_cancellation_token ON public.bookings (cancellation_token);

ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
-- No policies: only service_role (Edge Functions) can access.

-- rollback:
-- DROP TABLE IF EXISTS public.bookings;
-- DROP TABLE IF EXISTS public.availability_blocks;
-- DROP TABLE IF EXISTS public.availability_rules;
