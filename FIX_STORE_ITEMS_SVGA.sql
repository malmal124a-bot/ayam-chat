-- Ensure store_items table exists with svga_url column
CREATE TABLE IF NOT EXISTS public.store_items (
  id text primary key,
  name text not null default '',
  category text default '',
  item_type text default 'gift',
  price double precision default 0,
  image_url text,
  svga_url text,
  animated boolean default false,
  min_level int default 1,
  is_active boolean default true,
  "order" int default 0,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Add svga_url column if it doesn't exist (for existing tables)
ALTER TABLE store_items ADD COLUMN IF NOT EXISTS svga_url text;

-- Ensure RLS
ALTER TABLE store_items ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'store_items_select') THEN
    CREATE POLICY store_items_select ON store_items FOR SELECT USING (true);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'store_items_insert') THEN
    CREATE POLICY store_items_insert ON store_items FOR INSERT WITH CHECK (true);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'store_items_update') THEN
    CREATE POLICY store_items_update ON store_items FOR UPDATE USING (true) WITH CHECK (true);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'store_items_delete') THEN
    CREATE POLICY store_items_delete ON store_items FOR DELETE USING (true);
  END IF;
END $$;
