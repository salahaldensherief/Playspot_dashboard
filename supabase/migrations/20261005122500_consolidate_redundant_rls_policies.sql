-- Migration: 20261005122500_consolidate_redundant_rls_policies.sql
-- Description: Consolidate redundant multiple permissive policies on public tables to improve
--              query planning performance and eliminate duplicate evaluations:
--              1. promotions: remove duplicate public select policy.
--              2. loyalty_levels: remove redundant authenticated select policy (covered by public policy).
--              3. points_transactions: remove redundant select policy (covered by points_transactions_select).
--              4. referrals: remove redundant select policy (covered by referrals_select).
--              5. canteen_orders: remove legacy staff update policy (superseded by canteen_orders_staff_update).
--              6. service_calls: remove redundant staff update and select policies (superseded by scoped policies).

-- 1. promotions
DROP POLICY IF EXISTS "allow_read_clean_promotions" ON public.promotions;

-- 2. loyalty_levels
DROP POLICY IF EXISTS "loyalty_levels_read" ON public.loyalty_levels;

-- 3. points_transactions
DROP POLICY IF EXISTS "Users can view their own points history" ON public.points_transactions;

-- 4. referrals
DROP POLICY IF EXISTS "Users can view referrals they made" ON public.referrals;

-- 5. canteen_orders
DROP POLICY IF EXISTS "Staff can update lounge canteen orders" ON public.canteen_orders;

-- 6. service_calls
DROP POLICY IF EXISTS "Staff can update lounge service calls" ON public.service_calls;
DROP POLICY IF EXISTS "Service call staff can update lounge calls" ON public.service_calls;
DROP POLICY IF EXISTS "Service call staff can view lounge calls" ON public.service_calls;
