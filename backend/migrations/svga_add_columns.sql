-- Migration: Add display_name and preview_image_url to svga_url_overrides
-- Run this ONLY if the table already exists without these columns

ALTER TABLE svga_url_overrides
  ADD COLUMN IF NOT EXISTS display_name TEXT DEFAULT '';

ALTER TABLE svga_url_overrides
  ADD COLUMN IF NOT EXISTS preview_image_url TEXT DEFAULT '';

CREATE INDEX IF NOT EXISTS idx_svga_overrides_category ON svga_url_overrides(category);
