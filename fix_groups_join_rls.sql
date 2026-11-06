-- =============================================================================
-- KOTIZZ — FIX CRITIQUE : Adhésion par code & Standardisation 6 caractères
-- =============================================================================
-- Ce script résout :
-- 1. La visibilité des groupes par code d'invitation (invite_code IS NOT NULL)
-- 2. La visibilité des membres pour calculer le tour suivant
-- 3. La fonction RPC sécurisée join_group_by_code
-- 4. Le format par défaut universel de 6 caractères majuscules (ex: H7K2P9)
--
-- INSTRUCTIONS :
--   Supabase Dashboard → SQL Editor → coller tout ce script → RUN
-- =============================================================================

-- ─── 1. Remplacer la politique SELECT sur `groups` ───────────────────────────
DROP POLICY IF EXISTS "groups_select" ON public.groups;

CREATE POLICY "groups_select" ON public.groups
  FOR SELECT
  TO authenticated
  USING (
    organizer_id = auth.uid()
    OR public.is_group_member(id, auth.uid())
    OR invite_code IS NOT NULL
  );

-- ─── 2. Remplacer la politique SELECT sur `group_members` ─────────────────────
DROP POLICY IF EXISTS "group_members_select" ON public.group_members;

CREATE POLICY "group_members_select" ON public.group_members
  FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid()
    OR public.is_group_organizer(group_id, auth.uid())
    OR public.is_group_member(group_id, auth.uid())
    OR EXISTS (
      SELECT 1 FROM public.groups
      WHERE id = group_members.group_id
        AND invite_code IS NOT NULL
    )
  );

-- ─── 3. Fonction RPC atomique SECURITY DEFINER : join_group_by_code ─────────
CREATE OR REPLACE FUNCTION public.join_group_by_code(p_code TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_group   RECORD;
  v_user_id UUID := auth.uid();
  v_member_count INT;
  v_next_turn    INT;
BEGIN
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'unauthenticated');
  END IF;

  SELECT id, name, max_members, organizer_id, status
  INTO v_group
  FROM public.groups
  WHERE UPPER(TRIM(invite_code)) = UPPER(TRIM(p_code))
  LIMIT 1;

  IF v_group.id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'invalid_code');
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.group_members
    WHERE group_id = v_group.id AND user_id = v_user_id
  ) THEN
    RETURN jsonb_build_object('success', false, 'error', 'already_member');
  END IF;

  SELECT COUNT(*), COALESCE(MAX(turn_order), 0) + 1
  INTO v_member_count, v_next_turn
  FROM public.group_members
  WHERE group_id = v_group.id;

  IF v_member_count >= COALESCE(v_group.max_members, 5) THEN
    RETURN jsonb_build_object('success', false, 'error', 'group_full');
  END IF;

  INSERT INTO public.group_members (id, group_id, user_id, turn_order, status, joined_at)
  VALUES (gen_random_uuid(), v_group.id, v_user_id, v_next_turn, 'confirmed', NOW());

  RETURN jsonb_build_object(
    'success',    true,
    'group_id',   v_group.id,
    'group_name', v_group.name,
    'turn_order', v_next_turn
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.join_group_by_code(TEXT) TO authenticated;

-- ─── 4. Générateur par défaut de codes à 6 caractères majuscules en base ─────
CREATE OR REPLACE FUNCTION public.generate_invite_code()
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
  chars TEXT := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  result TEXT := '';
  i INT;
BEGIN
  FOR i IN 1..6 LOOP
    result := result || substr(chars, floor(random() * length(chars) + 1)::int, 1);
  END LOOP;
  RETURN result;
END;
$$;

ALTER TABLE public.groups 
  ALTER COLUMN invite_code SET DEFAULT public.generate_invite_code();
