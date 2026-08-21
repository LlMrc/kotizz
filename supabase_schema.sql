-- =============================================================================
-- KOTIZZ DATABASE SCHEMA & PRODUCTION CONFIGURATION (SUPABASE)
-- =============================================================================

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. TRIGGER FUNCTION: AUTO-UPDATE updated_at
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- 3. TABLES
-- =============================================================================

-- TABLE: PROFILES
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID NOT NULL PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT UNIQUE,
  full_name TEXT,
  phone TEXT,
  avatar_url TEXT,
  fcm_token TEXT,
  trust_score SMALLINT NOT NULL DEFAULT 50 CHECK (trust_score >= 0 AND trust_score <= 100),
  phone_verified BOOLEAN NOT NULL DEFAULT false,
  id_verified BOOLEAN NOT NULL DEFAULT false,
  payout_method TEXT,
  payout_details TEXT,
  completed_cycles INT NOT NULL DEFAULT 0,
  disputes_count INT NOT NULL DEFAULT 0,
  plan TEXT NOT NULL DEFAULT 'free' CHECK (plan IN ('free', 'pro')),
  plan_expires_at TIMESTAMPTZ,
  language TEXT NOT NULL DEFAULT 'fr' CHECK (language IN ('fr', 'en', 'ht')),
  push_enabled BOOLEAN NOT NULL DEFAULT true,
  biometric_enabled BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- TABLE: GROUPS (SÒL / TONTINES)
CREATE TABLE IF NOT EXISTS public.groups (
  id UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
  organizer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  category TEXT DEFAULT 'Général',
  contribution_amount NUMERIC NOT NULL CHECK (contribution_amount > 0),
  currency TEXT NOT NULL DEFAULT 'HTG' CHECK (currency IN ('HTG', 'USD', 'EUR', 'CAD')),
  frequency TEXT NOT NULL DEFAULT 'monthly' CHECK (frequency IN ('weekly', 'biweekly', 'monthly')),
  order_type TEXT NOT NULL DEFAULT 'random' CHECK (order_type IN ('random', 'fixed')),
  start_date DATE,
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'active', 'completed', 'cancelled')),
  max_members SMALLINT CHECK (max_members IS NULL OR max_members >= 2),
  invite_code TEXT UNIQUE DEFAULT encode(gen_random_bytes(4), 'hex'),
  current_turn SMALLINT NOT NULL DEFAULT 1,
  whatsapp_link TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- TABLE: GROUP_MEMBERS
CREATE TABLE IF NOT EXISTS public.group_members (
  id UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  turn_order SMALLINT NOT NULL DEFAULT 1,
  status TEXT NOT NULL DEFAULT 'confirmed' CHECK (status IN ('pending', 'confirmed', 'left')),
  joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT unique_group_user UNIQUE (group_id, user_id)
);

-- TABLE: CONTRIBUTIONS
CREATE TABLE IF NOT EXISTS public.contributions (
  id UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  turn_number SMALLINT NOT NULL DEFAULT 1,
  amount NUMERIC NOT NULL CHECK (amount > 0),
  currency TEXT NOT NULL DEFAULT 'HTG',
  payment_status TEXT NOT NULL DEFAULT 'pending' CHECK (payment_status IN ('pending', 'confirmed', 'late', 'disputed')),
  proof_url TEXT,
  paid_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- TABLE: PAYOUTS
CREATE TABLE IF NOT EXISTS public.payouts (
  id UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
  recipient_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  turn_number SMALLINT NOT NULL DEFAULT 1,
  total_amount NUMERIC NOT NULL,
  currency TEXT NOT NULL DEFAULT 'HTG',
  status TEXT NOT NULL DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'paid', 'disputed')),
  scheduled_date DATE,
  paid_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- TABLE: ALERTS / NOTIFICATIONS
CREATE TABLE IF NOT EXISTS public.alerts (
  id UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  group_id UUID REFERENCES public.groups(id) ON DELETE CASCADE,
  type TEXT NOT NULL DEFAULT 'system',
  title TEXT NOT NULL,
  body TEXT,
  is_read BOOLEAN NOT NULL DEFAULT false,
  deep_link TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- TABLE: SUBSCRIPTIONS (REVENUECAT)
CREATE TABLE IF NOT EXISTS public.subscriptions (
  id UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  product_id TEXT NOT NULL,
  entitlement TEXT NOT NULL DEFAULT 'pro',
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'expired', 'cancelled', 'grace_period')),
  price_usd NUMERIC NOT NULL DEFAULT 9.99,
  started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ,
  cancelled_at TIMESTAMPTZ,
  revenuecat_tx_id TEXT UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================================
-- 4. QUOTA FUNCTIONS & RPCS (USED BY FLUTTER APP)
-- =============================================================================

-- RPC: can_create_group(p_user_id)
-- Plan FREE -> Max 1 groupe actif ou brouillon
-- Plan PRO  -> Illimité
CREATE OR REPLACE FUNCTION public.can_create_group(p_user_id UUID)
RETURNS BOOLEAN
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_plan TEXT;
  v_group_count INT;
BEGIN
  -- Récupère le plan actuel de l'utilisateur
  SELECT plan INTO v_plan FROM public.profiles WHERE id = p_user_id;

  -- Si utilisateur PRO, création illimitée
  IF v_plan = 'pro' THEN
    RETURN true;
  END IF;

  -- Compte les groupes actifs ou brouillons organisés par cet utilisateur
  SELECT COUNT(*) INTO v_group_count
  FROM public.groups
  WHERE organizer_id = p_user_id
    AND status IN ('draft', 'active');

  -- Limite FREE: 1 groupe
  RETURN v_group_count < 1;
END;
$$ LANGUAGE plpgsql;

-- RPC: can_add_member(p_group_id, p_organizer_id)
-- Plan FREE -> Max 5 membres (organisateur inclus)
-- Plan PRO  -> Illimité
CREATE OR REPLACE FUNCTION public.can_add_member(p_group_id UUID, p_organizer_id UUID)
RETURNS BOOLEAN
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_plan TEXT;
  v_member_count INT;
BEGIN
  SELECT plan INTO v_plan FROM public.profiles WHERE id = p_organizer_id;

  IF v_plan = 'pro' THEN
    RETURN true;
  END IF;

  SELECT COUNT(*) INTO v_member_count
  FROM public.group_members
  WHERE group_id = p_group_id
    AND status != 'left';

  -- Limite FREE: 5 membres
  RETURN v_member_count < 5;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- 5. TRIGGERS & AUTOMATIONS
-- =============================================================================

-- TRIGGER: Auto-create profile on Supabase Auth Sign Up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (
    id,
    full_name,
    avatar_url,
    language
  )
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    NEW.raw_user_meta_data->>'avatar_url',
    COALESCE(NEW.raw_user_meta_data->>'language', 'fr')
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- TRIGGER: Auto-add organizer as first group member on group creation
CREATE OR REPLACE FUNCTION public.handle_new_group()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.group_members (
    group_id,
    user_id,
    turn_order,
    status
  )
  VALUES (
    NEW.id,
    NEW.organizer_id,
    1,
    'confirmed'
  )
  ON CONFLICT (group_id, user_id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS on_group_created ON public.groups;
CREATE TRIGGER on_group_created
  AFTER INSERT ON public.groups
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_group();

-- TRIGGER: Enforce group quota before insert
CREATE OR REPLACE FUNCTION public.enforce_group_quota()
RETURNS TRIGGER
AS $$
BEGIN
  IF NOT public.can_create_group(NEW.organizer_id) THEN
    RAISE EXCEPTION 'subscription_required: FREE plan allows max 1 active group. Upgrade to PRO.';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS check_group_quota ON public.groups;
CREATE TRIGGER check_group_quota
  BEFORE INSERT ON public.groups
  FOR EACH ROW EXECUTE FUNCTION public.enforce_group_quota();

-- TRIGGER: Enforce member quota before insert
CREATE OR REPLACE FUNCTION public.enforce_member_quota()
RETURNS TRIGGER
AS $$
DECLARE
  v_organizer_id UUID;
BEGIN
  SELECT organizer_id INTO v_organizer_id FROM public.groups WHERE id = NEW.group_id;
  IF NOT public.can_add_member(NEW.group_id, v_organizer_id) THEN
    RAISE EXCEPTION 'member_limit_reached: FREE plan allows max 5 members per group. Upgrade to PRO.';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS check_member_quota ON public.group_members;
CREATE TRIGGER check_member_quota
  BEFORE INSERT ON public.group_members
  FOR EACH ROW EXECUTE FUNCTION public.enforce_member_quota();

-- UPDATED_AT TRIGGERS
DROP TRIGGER IF EXISTS tr_profiles_updated_at ON public.profiles;
CREATE TRIGGER tr_profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS tr_groups_updated_at ON public.groups;
CREATE TRIGGER tr_groups_updated_at BEFORE UPDATE ON public.groups FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS tr_contributions_updated_at ON public.contributions;
CREATE TRIGGER tr_contributions_updated_at BEFORE UPDATE ON public.contributions FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS tr_subscriptions_updated_at ON public.subscriptions;
CREATE TRIGGER tr_subscriptions_updated_at BEFORE UPDATE ON public.subscriptions FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- =============================================================================
-- 6. ROW LEVEL SECURITY (RLS) POLICIES
-- =============================================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.contributions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;

-- PROFILES POLICIES
DROP POLICY IF EXISTS "Public profiles are viewable by authenticated users" ON public.profiles;
CREATE POLICY "Public profiles are viewable by authenticated users"
  ON public.profiles FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
CREATE POLICY "Users can update their own profile"
  ON public.profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id);

-- GROUPS POLICIES
DROP POLICY IF EXISTS "Users can view groups they are part of or organize" ON public.groups;
CREATE POLICY "Users can view groups they are part of or organize"
  ON public.groups FOR SELECT
  TO authenticated
  USING (
    organizer_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM public.group_members
      WHERE group_id = public.groups.id AND user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Organizers can create groups" ON public.groups;
CREATE POLICY "Organizers can create groups"
  ON public.groups FOR INSERT
  TO authenticated
  WITH CHECK (organizer_id = auth.uid());

DROP POLICY IF EXISTS "Organizers can update their groups" ON public.groups;
CREATE POLICY "Organizers can update their groups"
  ON public.groups FOR UPDATE
  TO authenticated
  USING (organizer_id = auth.uid());

-- GROUP_MEMBERS POLICIES
DROP POLICY IF EXISTS "Members can view participants of their groups" ON public.group_members;
CREATE POLICY "Members can view participants of their groups"
  ON public.group_members FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.group_members gm
      WHERE gm.group_id = public.group_members.group_id AND gm.user_id = auth.uid()
    ) OR
    EXISTS (
      SELECT 1 FROM public.groups g
      WHERE g.id = public.group_members.group_id AND g.organizer_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Organizers or users can add members" ON public.group_members;
CREATE POLICY "Organizers or users can add members"
  ON public.group_members FOR INSERT
  TO authenticated
  WITH CHECK (
    user_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM public.groups g
      WHERE g.id = public.group_members.group_id AND g.organizer_id = auth.uid()
    )
  );

-- CONTRIBUTIONS POLICIES
DROP POLICY IF EXISTS "Users can view contributions in their groups" ON public.contributions;
CREATE POLICY "Users can view contributions in their groups"
  ON public.contributions FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM public.groups g
      WHERE g.id = public.contributions.group_id AND g.organizer_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Users can submit their contributions" ON public.contributions;
CREATE POLICY "Users can submit their contributions"
  ON public.contributions FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

-- PAYOUTS POLICIES
DROP POLICY IF EXISTS "Users can view payouts of their groups" ON public.payouts;
CREATE POLICY "Users can view payouts of their groups"
  ON public.payouts FOR SELECT
  TO authenticated
  USING (
    recipient_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM public.groups g
      WHERE g.id = public.payouts.group_id AND g.organizer_id = auth.uid()
    )
  );

-- ALERTS POLICIES
DROP POLICY IF EXISTS "Users can view their own alerts" ON public.alerts;
CREATE POLICY "Users can view their own alerts"
  ON public.alerts FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can update their own alerts (mark read)" ON public.alerts;
CREATE POLICY "Users can update their own alerts (mark read)"
  ON public.alerts FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid());

-- SUBSCRIPTIONS POLICIES
DROP POLICY IF EXISTS "Users can view their own subscriptions" ON public.subscriptions;
CREATE POLICY "Users can view their own subscriptions"
  ON public.subscriptions FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- =============================================================================
-- 7. PERFORMANCE INDEXES
-- =============================================================================
CREATE INDEX IF NOT EXISTS idx_groups_organizer ON public.groups(organizer_id);
CREATE INDEX IF NOT EXISTS idx_group_members_group ON public.group_members(group_id);
CREATE INDEX IF NOT EXISTS idx_group_members_user ON public.group_members(user_id);
CREATE INDEX IF NOT EXISTS idx_contributions_group ON public.contributions(group_id);
CREATE INDEX IF NOT EXISTS idx_contributions_user ON public.contributions(user_id);
CREATE INDEX IF NOT EXISTS idx_alerts_user_unread ON public.alerts(user_id, is_read);
