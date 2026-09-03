-- =============================================================================
-- KOTIZZ — CORRECTIF BOUCLE INFINIE RLS (infinite recursion in policy)
-- =============================================================================
-- Problème : Les politiques RLS sur `group_member` et `groups` se référencent
-- mutuellement → boucle infinie lors de l'INSERT dans `groups`.
--
-- Solution : Utiliser des fonctions SECURITY DEFINER pour briser la récursion.
--
-- MODE D'EMPLOI :
--   1. Ouvrez Supabase → SQL Editor
--   2. Collez tout ce script et cliquez sur RUN
-- =============================================================================

-- ─── 1. Supprimer les politiques problématiques existantes ───────────────────

-- Table: groups
DROP POLICY IF EXISTS "Users can view their groups" ON groups;
DROP POLICY IF EXISTS "Users can create groups" ON groups;
DROP POLICY IF EXISTS "Organizer can update their groups" ON groups;
DROP POLICY IF EXISTS "Organizer can delete their groups" ON groups;
DROP POLICY IF EXISTS "Members can view their groups" ON groups;
DROP POLICY IF EXISTS "select_groups_policy" ON groups;
DROP POLICY IF EXISTS "insert_groups_policy" ON groups;
DROP POLICY IF EXISTS "update_groups_policy" ON groups;
DROP POLICY IF EXISTS "delete_groups_policy" ON groups;

-- Table: group_member (peut aussi s'appeler group_members selon votre schéma)
DROP POLICY IF EXISTS "Users can view their memberships" ON group_member;
DROP POLICY IF EXISTS "Organizer can manage members" ON group_member;
DROP POLICY IF EXISTS "Users can join groups" ON group_member;
DROP POLICY IF EXISTS "select_group_member_policy" ON group_member;
DROP POLICY IF EXISTS "insert_group_member_policy" ON group_member;
DROP POLICY IF EXISTS "update_group_member_policy" ON group_member;
DROP POLICY IF EXISTS "delete_group_member_policy" ON group_member;

-- Variante pluriel
DROP POLICY IF EXISTS "Users can view their memberships" ON group_members;
DROP POLICY IF EXISTS "Organizer can manage members" ON group_members;
DROP POLICY IF EXISTS "select_group_members_policy" ON group_members;
DROP POLICY IF EXISTS "insert_group_members_policy" ON group_members;
DROP POLICY IF EXISTS "update_group_members_policy" ON group_members;
DROP POLICY IF EXISTS "delete_group_members_policy" ON group_members;

-- ─── 2. Créer une fonction helper SECURITY DEFINER (contourne la RLS) ────────
-- Cette fonction vérifie si l'utilisateur est membre d'un groupe
-- SANS déclencher la RLS → casse la boucle infinie.

CREATE OR REPLACE FUNCTION is_group_member(p_group_id UUID, p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM group_member
    WHERE group_id = p_group_id
      AND user_id  = p_user_id
  );
$$;

-- Variante si la table s'appelle group_members
CREATE OR REPLACE FUNCTION is_group_member_v2(p_group_id UUID, p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
AS $$
DECLARE
  tbl_exists BOOLEAN;
BEGIN
  -- Détecte si la table s'appelle group_member ou group_members
  SELECT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name = 'group_member'
  ) INTO tbl_exists;

  IF tbl_exists THEN
    RETURN EXISTS (
      SELECT 1 FROM group_member
      WHERE group_id = p_group_id AND user_id = p_user_id
    );
  ELSE
    RETURN EXISTS (
      SELECT 1 FROM group_members
      WHERE group_id = p_group_id AND user_id = p_user_id
    );
  END IF;
END;
$$;

-- ─── 3. Nouvelles politiques sur `groups` (sans référence directe à group_member) ──

-- SELECT : l'utilisateur voit les groupes dont il est organisateur OU membre
CREATE POLICY "groups_select_policy" ON groups
  FOR SELECT USING (
    organizer_id = auth.uid()
    OR is_group_member(id, auth.uid())
  );

-- INSERT : tout utilisateur authentifié peut créer un groupe
CREATE POLICY "groups_insert_policy" ON groups
  FOR INSERT WITH CHECK (
    organizer_id = auth.uid()
  );

-- UPDATE : seul l'organisateur peut modifier
CREATE POLICY "groups_update_policy" ON groups
  FOR UPDATE USING (
    organizer_id = auth.uid()
  );

-- DELETE : seul l'organisateur peut supprimer
CREATE POLICY "groups_delete_policy" ON groups
  FOR DELETE USING (
    organizer_id = auth.uid()
  );

-- ─── 4. Nouvelles politiques sur `group_member` (sans référence à groups via RLS) ──

-- SELECT : on voit ses propres lignes de membership
CREATE POLICY "group_member_select_policy" ON group_member
  FOR SELECT USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM groups g
      WHERE g.id = group_member.group_id
        AND g.organizer_id = auth.uid()
    )
  );

-- INSERT : l'organisateur du groupe peut ajouter des membres
CREATE POLICY "group_member_insert_policy" ON group_member
  FOR INSERT WITH CHECK (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM groups g
      WHERE g.id = group_member.group_id
        AND g.organizer_id = auth.uid()
    )
  );

-- UPDATE : l'organisateur peut mettre à jour
CREATE POLICY "group_member_update_policy" ON group_member
  FOR UPDATE USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM groups g
      WHERE g.id = group_member.group_id
        AND g.organizer_id = auth.uid()
    )
  );

-- DELETE : l'organisateur peut retirer des membres
CREATE POLICY "group_member_delete_policy" ON group_member
  FOR DELETE USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM groups g
      WHERE g.id = group_member.group_id
        AND g.organizer_id = auth.uid()
    )
  );

-- ─── 5. S'assurer que RLS est bien activé sur les deux tables ────────────────

ALTER TABLE groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_member ENABLE ROW LEVEL SECURITY;

-- =============================================================================
-- FIN DU SCRIPT — Testez maintenant la création de groupe dans l'application.
-- =============================================================================
