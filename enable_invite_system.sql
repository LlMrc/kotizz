-- =============================================================================
-- KOTIZZ — ACTIVATION DU SYSTÈME DE CODE D'INVITATION & FONCTION DE JOINTURE
-- =============================================================================
-- Copiez tout ce script dans Supabase → SQL Editor → RUN
-- =============================================================================

-- ─── 1. Mettre à jour la politique SELECT sur `groups` ───────────────────────
-- Permet aux utilisateurs authentifiés de rechercher un groupe par son code
DROP POLICY IF EXISTS "groups_select" ON public.groups;

CREATE POLICY "groups_select" ON public.groups
  FOR SELECT
  TO authenticated
  USING (
    organizer_id = auth.uid()
    OR public.is_group_member(id, auth.uid())
    OR invite_code IS NOT NULL
  );

-- ─── 2. Fonction RPC sécurisée : join_group_by_code ──────────────────────────
-- S'exécute en SECURITY DEFINER pour effectuer les vérifications et l'ajout
-- en une seule transaction atomique et sécurisée.

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
BEGIN
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'unauthenticated');
  END IF;

  -- 1. Trouver le groupe avec ce code (insensible à la casse et sans espaces)
  SELECT id, name, max_members, organizer_id, status
  INTO v_group
  FROM public.groups
  WHERE UPPER(TRIM(invite_code)) = UPPER(TRIM(p_code))
  LIMIT 1;

  IF v_group.id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'invalid_code');
  END IF;

  -- 2. Vérifier si l'utilisateur est déjà membre
  IF EXISTS (
    SELECT 1 FROM public.group_members 
    WHERE group_id = v_group.id AND user_id = v_user_id
  ) THEN
    RETURN jsonb_build_object('success', false, 'error', 'already_member');
  END IF;

  -- 3. Vérifier la capacité maximale du groupe
  SELECT COUNT(*) INTO v_member_count
  FROM public.group_members
  WHERE group_id = v_group.id;

  IF v_member_count >= COALESCE(v_group.max_members, 5) THEN
    RETURN jsonb_build_object('success', false, 'error', 'group_full');
  END IF;

  -- 4. Insérer le nouveau membre au tour suivant
  INSERT INTO public.group_members (
    id, group_id, user_id, turn_order, status, joined_at
  )
  VALUES (
    gen_random_uuid(),
    v_group.id,
    v_user_id,
    v_member_count + 1,
    'confirmed',
    NOW()
  );

  RETURN jsonb_build_object(
    'success', true,
    'group_id', v_group.id,
    'group_name', v_group.name,
    'turn_order', v_member_count + 1
  );
END;
$$;

-- ─── 3. Accorder les permissions d'exécution à l'utilisateur authentifié ──────
GRANT EXECUTE ON FUNCTION public.join_group_by_code(TEXT) TO authenticated;
