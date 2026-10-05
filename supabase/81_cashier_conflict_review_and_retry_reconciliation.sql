-- =============================================================================
-- Migration: 81_cashier_conflict_review_and_retry_reconciliation.sql
-- Description: Cashier Conflict Resolution Audit Trail and Retry Reconciliation
-- =============================================================================

CREATE TABLE IF NOT EXISTS private.cashier_conflict_reviews (
  review_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  lounge_id uuid NOT NULL REFERENCES public.lounges(id) ON DELETE CASCADE,
  operation_id uuid NOT NULL,
  reviewer_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  reason text NOT NULL CHECK (char_length(trim(reason)) BETWEEN 10 AND 1000),
  status text NOT NULL DEFAULT 'approved' CHECK (status IN ('approved', 'rejected')),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_cashier_conflict_reviews_op
  ON private.cashier_conflict_reviews(lounge_id, operation_id);

CREATE OR REPLACE FUNCTION public.get_cashier_sync_conflicts(
  p_lounge_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_caller uuid;
  v_is_authorized boolean := false;
  v_result jsonb;
BEGIN
  v_caller := auth.uid();
  IF v_caller IS NULL THEN
    RAISE EXCEPTION 'UNAUTHORIZED' USING ERRCODE = '42501';
  END IF;

  -- Verify caller is super admin, lounge owner, or lounge manager
  IF EXISTS (SELECT 1 FROM public.profiles WHERE id = v_caller AND role = 'super_admin') THEN
    v_is_authorized := true;
  ELSIF EXISTS (SELECT 1 FROM public.lounges WHERE id = p_lounge_id AND owner_id = v_caller) THEN
    v_is_authorized := true;
  ELSIF EXISTS (
    SELECT 1 FROM public.lounge_staff
    WHERE user_id = v_caller
      AND lounge_id = p_lounge_id
      AND role IN ('manager', 'admin')
      AND is_active = true
  ) THEN
    v_is_authorized := true;
  END IF;

  IF NOT v_is_authorized THEN
    RAISE EXCEPTION 'PERMISSION_DENIED' USING ERRCODE = '42501';
  END IF;

  SELECT COALESCE(
    jsonb_agg(
      jsonb_build_object(
        'operation_id', r.operation_id::text,
        'booking_id', COALESCE(r.request->>'booking_id', '')::text,
        'actor_id', r.actor_id::text,
        'kind', COALESCE(r.request->>'kind', '')::text,
        'code', COALESCE(r.result->>'code', 'CONFLICT')::text,
        'sequence', r.sequence::int,
        'retry_pending', EXISTS (
          SELECT 1 FROM private.cashier_conflict_reviews rev
          WHERE rev.operation_id = r.operation_id AND rev.status = 'approved'
        )
      ) ORDER BY r.sequence ASC
    ),
    '[]'::jsonb
  ) INTO v_result
  FROM private.cashier_operation_receipts r
  WHERE r.lounge_id = p_lounge_id
    AND r.result->>'status' = 'conflict';

  RETURN v_result;
END;
$$;

REVOKE ALL ON FUNCTION public.get_cashier_sync_conflicts(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_cashier_sync_conflicts(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.approve_cashier_conflict_retry(
  p_lounge_id uuid,
  p_operation_id uuid,
  p_review_id uuid,
  p_reason text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_caller uuid;
  v_is_authorized boolean := false;
  v_clean_reason text;
  v_existing private.cashier_conflict_reviews%ROWTYPE;
BEGIN
  v_caller := auth.uid();
  IF v_caller IS NULL THEN
    RAISE EXCEPTION 'UNAUTHORIZED' USING ERRCODE = '42501';
  END IF;

  v_clean_reason := trim(COALESCE(p_reason, ''));
  IF char_length(v_clean_reason) < 10 OR char_length(v_clean_reason) > 1000 THEN
    RAISE EXCEPTION 'INVALID_REASON' USING ERRCODE = '22023';
  END IF;

  -- Verify caller is super admin, lounge owner, or lounge manager
  IF EXISTS (SELECT 1 FROM public.profiles WHERE id = v_caller AND role = 'super_admin') THEN
    v_is_authorized := true;
  ELSIF EXISTS (SELECT 1 FROM public.lounges WHERE id = p_lounge_id AND owner_id = v_caller) THEN
    v_is_authorized := true;
  ELSIF EXISTS (
    SELECT 1 FROM public.lounge_staff
    WHERE user_id = v_caller
      AND lounge_id = p_lounge_id
      AND role IN ('manager', 'admin')
      AND is_active = true
  ) THEN
    v_is_authorized := true;
  END IF;

  IF NOT v_is_authorized THEN
    RAISE EXCEPTION 'PERMISSION_DENIED' USING ERRCODE = '42501';
  END IF;

  -- Check if review already processed (idempotency)
  SELECT * INTO v_existing FROM private.cashier_conflict_reviews WHERE review_id = p_review_id;
  IF FOUND THEN
    IF v_existing.lounge_id = p_lounge_id AND v_existing.operation_id = p_operation_id THEN
      RETURN jsonb_build_object(
        'lounge_id', p_lounge_id,
        'operation_id', p_operation_id,
        'review_id', p_review_id,
        'status', 'approved'
      );
    ELSE
      RAISE EXCEPTION 'REVIEW_MISMATCH' USING ERRCODE = '22023';
    END IF;
  END IF;

  -- Ensure the operation was actually recorded as conflict
  IF NOT EXISTS (
    SELECT 1 FROM private.cashier_operation_receipts
    WHERE lounge_id = p_lounge_id
      AND operation_id = p_operation_id
      AND result->>'status' = 'conflict'
  ) THEN
    RAISE EXCEPTION 'CONFLICT_NOT_FOUND' USING ERRCODE = 'P0002';
  END IF;

  -- Record audit trail
  INSERT INTO private.cashier_conflict_reviews (
    review_id,
    lounge_id,
    operation_id,
    reviewer_id,
    reason,
    status
  ) VALUES (
    p_review_id,
    p_lounge_id,
    p_operation_id,
    v_caller,
    v_clean_reason,
    'approved'
  );

  -- Remove the conflict receipt so the cashier device can retry the operation
  DELETE FROM private.cashier_operation_receipts
  WHERE lounge_id = p_lounge_id
    AND operation_id = p_operation_id
    AND result->>'status' = 'conflict';

  RETURN jsonb_build_object(
    'lounge_id', p_lounge_id,
    'operation_id', p_operation_id,
    'review_id', p_review_id,
    'status', 'approved'
  );
END;
$$;

REVOKE ALL ON FUNCTION public.approve_cashier_conflict_retry(uuid, uuid, uuid, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.approve_cashier_conflict_retry(uuid, uuid, uuid, text) TO authenticated;
