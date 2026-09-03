-- =============================================================================
-- KOTIZZ — CORRECTIF FINAL RLS (basé sur le schéma réel)
-- Table des membres : group_members (avec s)
-- =============================================================================
-- Copiez l'intégralité de ce script dans Supabase → SQL Editor → RUN
-- =============================================================================

-- ─── 1. Supprimer TOUTES les politiques sur groups et group_members ───────────

DROP POLICY IF EXISTS "groups: créer" ON public.groups;
DROP POLICY IF EXISTS "groups: modifier (organisateur)" ON public.groups;
DROP POLICY IF EXISTS "groups: supprimer (organisateur)" ON public.groups;
DROP POLICY IF EXISTS "groups: voir (membres)" ON public.groups;
DROP POLICY IF EXISTS "Organizers can update their groups" ON public.groups;
DROP POLICY IF EXISTS "Users can view groups they are part of or organize" ON public.groups;
DROP POLICY IF EXISTS "Organizers can create groups" ON public.groups;

DROP POLICY IF EXISTS "group_members: gérer (organisateur)" ON public.group_members;
DROP POLICY IF EXISTS "group_members: voir (membres)" ON public.group_members;
DROP POLICY IF EXISTS "Members can view participants of their groups" ON public.group_members;
DROP POLICY IF EXISTS "Organizers or users can add members" ON public.group_members;

-- ─── 2. Créer deux fonctions SECURITY DEFINER ────────────────────────────────
-- Ces fonctions s'exécutent avec les droits du owner (contourne la RLS)
-- et cassent la boucle infinie.

-- Vérifie si un utilisateur est membre d'un groupe
CREATE OR REPLACE FUNCTION public.is_group_member(p_group_id UUID, p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.group_members
    WHERE group_id = p_group_id
      AND user_id  = p_user_id
  );
$$;

-- Vérifie si un utilisateur est organisateur d'un groupe
CREATE OR REPLACE FUNCTION public.is_group_organizer(p_group_id UUID, p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.groups
    WHERE id           = p_group_id
      AND organizer_id = p_user_id
  );
$$;

-- ─── 3. Nouvelles politiques propres sur `groups` ────────────────────────────

-- SELECT : organisateur OU membre (via fonction SECURITY DEFINER → pas de boucle)
CREATE POLICY "groups_select" ON public.groups
  FOR SELECT
  TO authenticated
  USING (
    organizer_id = auth.uid()
    OR public.is_group_member(id, auth.uid())
  );

-- INSERT : seul l'organisateur peut créer
CREATE POLICY "groups_insert" ON public.groups
  FOR INSERT
  TO authenticated
  WITH CHECK (organizer_id = auth.uid());

-- UPDATE : seul l'organisateur peut modifier
CREATE POLICY "groups_update" ON public.groups
  FOR UPDATE
  TO authenticated
  USING (organizer_id = auth.uid());

-- DELETE : seul l'organisateur peut supprimer
CREATE POLICY "groups_delete" ON public.groups
  FOR DELETE
  TO authenticated
  USING (organizer_id = auth.uid());

-- ─── 4. Nouvelles politiques propres sur `group_members` ─────────────────────

-- SELECT : voir ses propres lignes OU les membres de ses groupes (organisateur)
-- Utilise is_group_organizer (SECURITY DEFINER) pour éviter la récursion sur groups
CREATE POLICY "group_members_select" ON public.group_members
  FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid()
    OR public.is_group_organizer(group_id, auth.uid())
  );

-- INSERT : l'utilisateur peut s'ajouter lui-même OU l'organisateur peut ajouter
CREATE POLICY "group_members_insert" ON public.group_members
  FOR INSERT
  TO authenticated
  WITH CHECK (
    user_id = auth.uid()
    OR public.is_group_organizer(group_id, auth.uid())
  );

-- UPDATE : seul l'organisateur peut modifier les membres
CREATE POLICY "group_members_update" ON public.group_members
  FOR UPDATE
  TO authenticated
  USING (
    public.is_group_organizer(group_id, auth.uid())
  );

-- DELETE : l'utilisateur peut se retirer OU l'organisateur peut retirer un membre
CREATE POLICY "group_members_delete" ON public.group_members
  FOR DELETE
  TO authenticated
  USING (
    user_id = auth.uid()
    OR public.is_group_organizer(group_id, auth.uid())
  );

-- ─── 5. S'assurer que RLS est bien activé ────────────────────────────────────

ALTER TABLE public.groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_members ENABLE ROW LEVEL SECURITY;

-- ─── 6. Vérification finale ───────────────────────────────────────────────────
-- Exécutez cette requête après le script pour confirmer les nouvelles politiques

SELECT tablename, policyname, cmd, roles
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('groups', 'group_members')
ORDER BY tablename, policyname;

-- =============================================================================
-- Si tout s'est bien passé, vous devriez voir exactement 8 politiques :
--   groups         → groups_delete, groups_insert, groups_select, groups_update
--   group_members  → group_members_delete, group_members_insert,
--                    group_members_select, group_members_update
-- =============================================================================
