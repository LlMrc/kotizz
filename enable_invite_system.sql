-- =============================================================================
-- KOTIZZ — ACTIVATION COMPLÈTE DU SYSTÈME D'INVITATION & REJOINDRE AVEC CODE
-- =============================================================================
-- Ce script résout :
-- 1. La visibilité des groupes via invite_code pour les utilisateurs non-membres
-- 2. La visibilité des membres pour calculer le tour suivant sans conflit
-- 3. La fonction RPC atomique `join_group_by_code`
-- =============================================================================
-- Copiez TOUT le script ci-dessous dans Supabase → SQL Editor → RUN
-- =============================================================================

-- ─── 1. Politique SELECT sur `groups` ────────────────────────────────────────
DROP POLICY IF EXISTS "groups_select" ON public.groups;

CREATE POLICY "groups_select" ON public.groups
  FOR SELECT
  TO authenticated
  USING (
    organizer_id = auth.uid()
    OR public.is_group_member(id, auth.uid())
    OR invite_code IS NOT NULL
  );

-- ─── 2. Politique SELECT sur `group_members` ─────────────────────────────────
-- Permet de voir les membres d'une tontine pour afficher la roue et calculer le tour
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

-- ─── 3. Fonction RPC atomique et sécurisée : `join_group_by_code` ───────────
CREATE OR REPLACE FUNCTION public.join_group_by_code(p_code TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_group RECORD;
  v_user_id UUID := auth.uid();
  v_member_count INT;
  v_next_turn INT;
BEGIN
  -- 1. Vérification de l'authentification
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'unauthenticated');
  END IF;

  -- 2. Trouver le groupe correspondant au code
  SELECT id, name, max_members, organizer_id, status
  INTO v_group
  FROM public.groups
  WHERE UPPER(TRIM(invite_code)) = UPPER(TRIM(p_code))
  LIMIT 1;

  IF v_group.id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'invalid_code');
  END IF;

  -- 3. Vérifier si l'utilisateur est déjà membre
  IF EXISTS (
    SELECT 1 FROM public.group_members 
    WHERE group_id = v_group.id AND user_id = v_user_id
  ) THEN
    RETURN jsonb_build_object('success', false, 'error', 'already_member');
  END IF;

  -- 4. Vérifier la capacité maximale et calculer le prochain tour sans doublon
  SELECT COUNT(*), COALESCE(MAX(turn_order), 0) + 1
  INTO v_member_count, v_next_turn
  FROM public.group_members
  WHERE group_id = v_group.id;

  IF v_member_count >= COALESCE(v_group.max_members, 5) THEN
    RETURN jsonb_build_object('success', false, 'error', 'group_full');
  END IF;

  -- 5. Insérer le nouveau membre avec son numéro de tour
  INSERT INTO public.group_members (
    id, group_id, user_id, turn_order, status, joined_at
  )
  VALUES (
    gen_random_uuid(),
    v_group.id,
    v_user_id,
    v_next_turn,
    'confirmed',
    NOW()
  );

  RETURN jsonb_build_object(
    'success', true,
    'group_id', v_group.id,
    'group_name', v_group.name,
    'turn_order', v_next_turn
  );
END;
$$;

-- ─── 4. Accorder les droits d'exécution ───────────────────────────────────────
GRANT EXECUTE ON FUNCTION public.join_group_by_code(TEXT) TO authenticated;
