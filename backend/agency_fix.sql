-- Add photo_url column to agencies table for agency profile image
ALTER TABLE public.agencies ADD COLUMN IF NOT EXISTS photo_url text default '';
