-- Add logo_url and og_image_url to quotes for client branding assets.
ALTER TABLE public.quotes ADD COLUMN IF NOT EXISTS logo_url text;
ALTER TABLE public.quotes ADD COLUMN IF NOT EXISTS og_image_url text;

-- Public-read storage bucket for admin-uploaded assets (logos, OG images).
-- Writes are controlled by the admin-upload-asset Edge Function (service role).
INSERT INTO storage.buckets (id, name, public)
VALUES ('admin-assets', 'admin-assets', true)
ON CONFLICT (id) DO NOTHING;
