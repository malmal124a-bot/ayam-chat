-- SVGA URL Overrides table
-- Maps local asset paths to remote CDN URLs with preview images
-- Used by SvgaAssetService to resolve SVGA animations from CDN
CREATE TABLE IF NOT EXISTS svga_url_overrides (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  local_path TEXT NOT NULL UNIQUE,
  remote_url TEXT NOT NULL,
  display_name TEXT DEFAULT '',
  preview_image_url TEXT DEFAULT '',
  category TEXT DEFAULT 'gift',
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS
ALTER TABLE svga_url_overrides ENABLE ROW LEVEL SECURITY;

-- Public read access (app needs to read these)
CREATE POLICY "Public read access" ON svga_url_overrides
  FOR SELECT USING (true);

-- Admin write access (dashboard manages these)
CREATE POLICY "Admin write access" ON svga_url_overrides
  FOR ALL USING (true);

-- Index for fast lookups
CREATE INDEX IF NOT EXISTS idx_svga_overrides_local_path ON svga_url_overrides(local_path);
CREATE INDEX IF NOT EXISTS idx_svga_overrides_category ON svga_url_overrides(category);
