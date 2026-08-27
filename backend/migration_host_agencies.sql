-- ============================================================
-- Migration: Add missing columns to host_agencies table
-- Run in: Supabase SQL Editor > New query > Run
--
-- This adds columns that the dashboard expects but were missing
-- from the original supabase_schema_dashboard.sql
-- ============================================================

-- Add missing columns to host_agencies (safe: IF NOT EXISTS equivalent)
ALTER TABLE public.host_agencies ADD COLUMN IF NOT EXISTS is_active boolean default true;
ALTER TABLE public.host_agencies ADD COLUMN IF NOT EXISTS total_diamonds_earned double precision default 0;
ALTER TABLE public.host_agencies ADD COLUMN IF NOT EXISTS monthly_diamonds double precision default 0;
ALTER TABLE public.host_agencies ADD COLUMN IF NOT EXISTS tier text default 'bronze';
ALTER TABLE public.host_agencies ADD COLUMN IF NOT EXISTS photo_url text;
ALTER TABLE public.host_agencies ADD COLUMN IF NOT EXISTS country text;
ALTER TABLE public.host_agencies ADD COLUMN IF NOT EXISTS is_hall_of_fame boolean default false;
ALTER TABLE public.host_agencies ADD COLUMN IF NOT EXISTS description text;
ALTER TABLE public.host_agencies ADD COLUMN IF NOT EXISTS phone text;

-- Verify
SELECT column_name, data_type FROM information_schema.columns
WHERE table_name = 'host_agencies' AND table_schema = 'public'
ORDER BY ordinal_position;
