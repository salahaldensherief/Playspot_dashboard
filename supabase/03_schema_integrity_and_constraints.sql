-- =============================================================================
-- 03_schema_integrity_and_constraints.sql
-- Financial Constraints, Timezone Standardization & Schema Integrity Fixes
-- =============================================================================

-- Enable btree_gist extension for exclusion constraints (booking overlap prevention)
CREATE EXTENSION IF NOT EXISTS btree_gist;

-- -----------------------------------------------------------------------------
-- 1. Financial Constraints Check Fixes
-- -----------------------------------------------------------------------------

-- Bookings Financial Checks
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'check_booking_prices_non_negative') THEN
    ALTER TABLE public.bookings
      ADD CONSTRAINT check_booking_prices_non_negative
      CHECK (
        (total_price IS NULL OR total_price >= 0) AND
        (addons_price IS NULL OR addons_price >= 0) AND
        (room_price IS NULL OR room_price >= 0)
      );
  END IF;
END $$;

-- Payments Financial Checks
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'check_payment_amounts_valid') THEN
    ALTER TABLE public.payments
      ADD CONSTRAINT check_payment_amounts_valid
      CHECK (
        amount >= 0 AND
        (discount_amount IS NULL OR (discount_amount >= 0 AND discount_amount <= amount))
      );
  END IF;
END $$;

-- Payouts Financial Checks
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'check_payout_amounts_valid') THEN
    ALTER TABLE public.payouts
      ADD CONSTRAINT check_payout_amounts_valid
      CHECK (
        total_amount >= 0
      );
  END IF;
END $$;


-- -----------------------------------------------------------------------------
-- 2. Timezone Standardization (TIMESTAMPTZ)
-- -----------------------------------------------------------------------------

-- Standardize timestamps in Bookings
DO $$
BEGIN
  ALTER TABLE public.bookings
    ALTER COLUMN created_at TYPE TIMESTAMPTZ USING created_at AT TIME ZONE 'UTC';
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Skipped bookings created_at timestamptz conversion: %', SQLERRM;
END $$;

-- Standardize timestamps in Payments
DO $$
BEGIN
  ALTER TABLE public.payments
    ALTER COLUMN created_at TYPE TIMESTAMPTZ USING created_at AT TIME ZONE 'UTC';
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Skipped payments created_at timestamptz conversion: %', SQLERRM;
END $$;

-- Standardize timestamps in Notifications
DO $$
BEGIN
  ALTER TABLE public.notifications
    ALTER COLUMN created_at TYPE TIMESTAMPTZ USING created_at AT TIME ZONE 'UTC';
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Skipped notifications created_at timestamptz conversion: %', SQLERRM;
END $$;

-- Standardize timestamps in Lounges & Rooms
DO $$
BEGIN
  ALTER TABLE public.lounges
    ALTER COLUMN created_at TYPE TIMESTAMPTZ USING created_at AT TIME ZONE 'UTC';
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Skipped lounges created_at timestamptz conversion: %', SQLERRM;
END $$;

DO $$
BEGIN
  ALTER TABLE public.rooms
    ALTER COLUMN created_at TYPE TIMESTAMPTZ USING created_at AT TIME ZONE 'UTC';
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Skipped rooms created_at timestamptz conversion: %', SQLERRM;
END $$;


-- -----------------------------------------------------------------------------
-- 3. Space Type Foreign Key Alignment (rooms.space_type_id -> space_types.id)
-- -----------------------------------------------------------------------------

-- Safely migrate rooms.space_type_id if it currently holds space_types.name text
DO $$
BEGIN
  -- Check if rooms.space_type_id is text type
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'rooms'
      AND column_name = 'space_type_id'
      AND data_type IN ('character varying', 'text')
  ) THEN
    -- Temporarily add new UUID column
    ALTER TABLE public.rooms ADD COLUMN space_type_uuid UUID;

    -- Update space_type_uuid by matching name or id in space_types
    UPDATE public.rooms r
    SET space_type_uuid = st.id
    FROM public.space_types st
    WHERE r.space_type_id = st.name OR r.space_type_id = st.id::text;

    -- Drop old column and rename new column
    ALTER TABLE public.rooms DROP COLUMN space_type_id;
    ALTER TABLE public.rooms RENAME COLUMN space_type_uuid TO space_type_id;

    -- Add Foreign Key Constraint
    ALTER TABLE public.rooms
      ADD CONSTRAINT fk_rooms_space_type
      FOREIGN KEY (space_type_id) REFERENCES public.space_types(id)
      ON DELETE SET NULL;
  END IF;
END $$;


-- -----------------------------------------------------------------------------
-- 4. Business Rules Constraints (Active Shifts)
-- -----------------------------------------------------------------------------

-- Prevent Multiple Open Shifts for the Same Lounge Simultaneously
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'unique_open_shift_per_lounge') THEN
    CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_open_shift_per_lounge
      ON public.shifts (lounge_id)
      WHERE (status = 'open' OR closed_at IS NULL);
  END IF;
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Skipped unique_open_shift_per_lounge index due to existing active shifts: %', SQLERRM;
END $$;
