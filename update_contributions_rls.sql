-- =============================================================================
-- KOTIZZ — POLITIQUES RLS POUR LA GESTION DES COTISATIONS (CONTRIBUTIONS)
-- =============================================================================
-- À exécuter dans Supabase → SQL Editor → RUN
-- Permet à l'organisateur du groupe de :
--   1. Consulter toutes les cotisations du groupe
--   2. Enregistrer / insérer une cotisation pour un membre
--   3. Valider / modifier le statut d'une cotisation ('confirmed', 'pending', etc.)
-- =============================================================================

ALTER TABLE public.contributions ENABLE ROW LEVEL SECURITY;

-- 1. Supprimer les anciennes politiques sur contributions
DROP POLICY IF EXISTS "Users can view contributions in their groups" ON public.contributions;
DROP POLICY IF EXISTS "Users can submit their contributions" ON public.contributions;
DROP POLICY IF EXISTS "contributions_select" ON public.contributions;
DROP POLICY IF EXISTS "contributions_insert" ON public.contributions;
DROP POLICY IF EXISTS "contributions_update" ON public.contributions;
DROP POLICY IF EXISTS "contributions_delete" ON public.contributions;

-- 2. SELECT : L'utilisateur peut voir ses propres cotisations OU l'organisateur peut voir toutes celles de son groupe
CREATE POLICY "contributions_select" ON public.contributions
  FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid()
    OR public.is_group_organizer(group_id, auth.uid())
    OR public.is_group_member(group_id, auth.uid())
  );

-- 3. INSERT : L'utilisateur peut soumettre sa propre cotisation OU l'organisateur peut l'enregistrer
CREATE POLICY "contributions_insert" ON public.contributions
  FOR INSERT
  TO authenticated
  WITH CHECK (
    user_id = auth.uid()
    OR public.is_group_organizer(group_id, auth.uid())
  );

-- 4. UPDATE : L'organisateur peut valider/modifier le statut de n'importe quelle cotisation du groupe
--            L'utilisateur peut mettre à jour sa propre preuve de paiement
CREATE POLICY "contributions_update" ON public.contributions
  FOR UPDATE
  TO authenticated
  USING (
    user_id = auth.uid()
    OR public.is_group_organizer(group_id, auth.uid())
  );

-- 5. DELETE : Seul l'organisateur peut supprimer une cotisation erronée
CREATE POLICY "contributions_delete" ON public.contributions
  FOR DELETE
  TO authenticated
  USING (
    public.is_group_organizer(group_id, auth.uid())
  );
