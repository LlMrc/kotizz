-- =============================================================================
-- KOTIZZ — CORRECTIF RLS (version adaptée au schéma réel)
-- =============================================================================
-- Exécutez d'abord ÉTAPE 1 pour voir vos tables et politiques réelles,
-- puis ÉTAPE 2 pour appliquer le correctif.
-- =============================================================================

-- ═══════════════════════════════════════════════════════════════════
-- ÉTAPE 1 : DIAGNOSTIC — Copiez uniquement cette section et faites RUN
--           pour voir vos tables et politiques existantes.
-- ═══════════════════════════════════════════════════════════════════

-- Liste de toutes vos tables publiques
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;

-- Liste de toutes les politiques RLS actives
SELECT tablename, policyname, cmd, qual
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- =============================================================================
-- ÉTAPE 2 : CORRECTIF — Après avoir identifié le vrai nom de la table,
--           exécutez UNIQUEMENT la section correspondante ci-dessous.
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- CAS A : Si la table s'appelle "group_members" (avec s)
-- ─────────────────────────────────────────────────────────────────────────────

-- 2A-1. Supprimer toutes les politiques existantes sur les deux tables
DO $$
DECLARE
  pol RECORD;
BEGIN
  FOR pol IN
    SELECT policyname, tablename
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename IN ('groups', 'group_members')
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON %I', pol.policyname, pol.tablename);
    RAISE NOTICE 'Dropped policy % on %', pol.policyname, pol.tablename;
  END LOOP;
END $$;

-- 2A-2. Fonction helper SECURITY DEFINER (contourne la RLS → brise la boucle)
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

-- 2A-3. Politiques sur `groups`
CREATE POLICY "groups_select" ON public.groups
  FOR SELECT USING (
    organizer_id = auth.uid()
    OR public.is_group_member(id, auth.uid())
  );

CREATE POLICY "groups_insert" ON public.groups
  FOR INSERT WITH CHECK (organizer_id = auth.uid());

CREATE POLICY "groups_update" ON public.groups
  FOR UPDATE USING (organizer_id = auth.uid());

CREATE POLICY "groups_delete" ON public.groups
  FOR DELETE USING (organizer_id = auth.uid());

-- 2A-4. Politiques sur `group_members`
CREATE POLICY "group_members_select" ON public.group_members
  FOR SELECT USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.groups g
      WHERE g.id = group_members.group_id
        AND g.organizer_id = auth.uid()
    )
  );

CREATE POLICY "group_members_insert" ON public.group_members
  FOR INSERT WITH CHECK (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.groups g
      WHERE g.id = group_members.group_id
        AND g.organizer_id = auth.uid()
    )
  );

CREATE POLICY "group_members_update" ON public.group_members
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.groups g
      WHERE g.id = group_members.group_id
        AND g.organizer_id = auth.uid()
    )
  );

CREATE POLICY "group_members_delete" ON public.group_members
  FOR DELETE USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.groups g
      WHERE g.id = group_members.group_id
        AND g.organizer_id = auth.uid()
    )
  );

ALTER TABLE public.groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_members ENABLE ROW LEVEL SECURITY;

-- ─────────────────────────────────────────────────────────────────────────────
-- CAS B : Si vos groupes n'ont pas du tout de table membres séparée
--         et que l'erreur vient d'un TRIGGER ou d'une FONCTION
-- ─────────────────────────────────────────────────────────────────────────────

-- Lister tous les triggers sur la table groups
-- SELECT trigger_name, event_manipulation, action_statement
-- FROM information_schema.triggers
-- WHERE event_object_schema = 'public'
--   AND event_object_table = 'groups';

-- Si vous voyez un trigger qui référence group_member (singulier), désactivez-le :
-- DROP TRIGGER IF EXISTS <nom_du_trigger> ON public.groups;

-- =============================================================================
-- FIN DU SCRIPT
-- =============================================================================
