-- Run this in Supabase SQL Editor to add photo_url column
ALTER TABLE public.agencies ADD COLUMN IF NOT EXISTS photo_url text default '';
