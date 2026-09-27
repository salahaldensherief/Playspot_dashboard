-- Migration to add image_url and stock management columns to the extras table
ALTER TABLE public.extras ADD COLUMN IF NOT EXISTS image_url TEXT;
ALTER TABLE public.extras ADD COLUMN IF NOT EXISTS stock_quantity INT DEFAULT 0;
ALTER TABLE public.extras ADD COLUMN IF NOT EXISTS track_stock BOOLEAN DEFAULT false;
ALTER TABLE public.extras ADD COLUMN IF NOT EXISTS min_stock_alert INT DEFAULT 5;
