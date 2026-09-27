-- Migration for Admin Dashboard: Support Settings, Policies, FAQs, and Support Tickets

-- 1. App Settings Table
CREATE TABLE IF NOT EXISTS public.app_settings (
  id TEXT PRIMARY KEY DEFAULT 'global',
  support_whatsapp TEXT NOT NULL DEFAULT '',
  support_phone TEXT NOT NULL DEFAULT '',
  support_email TEXT NOT NULL DEFAULT '',
  vodafone_cash_number TEXT NOT NULL DEFAULT '',
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  updated_by UUID REFERENCES auth.users(id)
);

-- Seed initial row for app_settings if not exists
INSERT INTO public.app_settings (id, support_whatsapp, support_phone, support_email, vodafone_cash_number)
VALUES ('global', '+201000000000', '+201000000000', 'support@playspot.app', '01000000000')
ON CONFLICT (id) DO NOTHING;

-- 2. App Policies Table
CREATE TABLE IF NOT EXISTS public.app_policies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  policy_type TEXT UNIQUE NOT NULL CHECK (policy_type IN ('terms', 'privacy', 'cancellation')),
  title_ar TEXT NOT NULL DEFAULT '',
  title_en TEXT NOT NULL DEFAULT '',
  content_ar TEXT NOT NULL DEFAULT '',
  content_en TEXT NOT NULL DEFAULT '',
  sections_ar JSONB DEFAULT '[]'::jsonb,
  sections_en JSONB DEFAULT '[]'::jsonb,
  is_published BOOLEAN DEFAULT true,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  updated_by UUID REFERENCES auth.users(id)
);

-- Seed initial default policies if not exists
INSERT INTO public.app_policies (policy_type, title_ar, title_en, content_ar, content_en)
VALUES
('terms', 'شروط الاستخدام', 'Terms of Use', 'شروط وأحكام استخدام تطبيق بلاي سبوت.', 'Terms and conditions for using PlaySpot app.'),
('privacy', 'سياسة الخصوصية', 'Privacy Policy', 'سياسة حماية البيانات والخصوصية.', 'Data protection and privacy policy.'),
('cancellation', 'سياسة الإلغاء والاسترجاع', 'Cancellation & Refund Policy', 'شروط إلغاء الحجوزات واسترداد المبالغ.', 'Booking cancellation and refund conditions.')
ON CONFLICT (policy_type) DO NOTHING;

-- 3. FAQs Table
CREATE TABLE IF NOT EXISTS public.faqs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  question_ar TEXT NOT NULL,
  answer_ar TEXT NOT NULL,
  question_en TEXT NOT NULL,
  answer_en TEXT NOT NULL,
  category TEXT NOT NULL CHECK (category IN ('bookings', 'payments', 'technical', 'general')),
  display_order INT DEFAULT 0,
  is_published BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Support Tickets Table
CREATE TABLE IF NOT EXISTS public.support_tickets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id),
  user_name TEXT NOT NULL,
  user_phone TEXT NOT NULL,
  issue_type TEXT NOT NULL CHECK (issue_type IN ('booking', 'payment', 'technical', 'lounge', 'other')),
  subject TEXT NOT NULL,
  message TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'new' CHECK (status IN ('new', 'under_review', 'resolved')),
  admin_notes TEXT,
  resolved_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS on all tables
ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_policies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.faqs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.support_tickets ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any to avoid errors on rerun
DROP POLICY IF EXISTS "Public read app_settings" ON public.app_settings;
DROP POLICY IF EXISTS "SuperAdmin manage app_settings" ON public.app_settings;

DROP POLICY IF EXISTS "Public read app_policies" ON public.app_policies;
DROP POLICY IF EXISTS "SuperAdmin manage app_policies" ON public.app_policies;

DROP POLICY IF EXISTS "Public read faqs" ON public.faqs;
DROP POLICY IF EXISTS "SuperAdmin manage faqs" ON public.faqs;

DROP POLICY IF EXISTS "User create tickets" ON public.support_tickets;
DROP POLICY IF EXISTS "User read own tickets" ON public.support_tickets;
DROP POLICY IF EXISTS "SuperAdmin manage tickets" ON public.support_tickets;

-- Policies for app_settings
CREATE POLICY "Public read app_settings" ON public.app_settings FOR SELECT USING (true);
CREATE POLICY "SuperAdmin manage app_settings" ON public.app_settings FOR ALL USING (
  EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'super_admin')
);

-- Policies for app_policies
CREATE POLICY "Public read app_policies" ON public.app_policies FOR SELECT USING (is_published = true);
CREATE POLICY "SuperAdmin manage app_policies" ON public.app_policies FOR ALL USING (
  EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'super_admin')
);

-- Policies for faqs
CREATE POLICY "Public read faqs" ON public.faqs FOR SELECT USING (is_published = true);
CREATE POLICY "SuperAdmin manage faqs" ON public.faqs FOR ALL USING (
  EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'super_admin')
);

-- Policies for support_tickets
CREATE POLICY "User create tickets" ON public.support_tickets FOR INSERT WITH CHECK (auth.uid() = user_id OR user_id IS NULL);
CREATE POLICY "User read own tickets" ON public.support_tickets FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "SuperAdmin manage tickets" ON public.support_tickets FOR ALL USING (
  EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'super_admin')
);
