-- =============================================================
-- Fix: Contrainte UNIQUE sur payouts (group_id, turn_number)
-- Necessaire pour que le UPSERT dans _advanceTurn() fonctionne
-- =============================================================
-- Executer dans Supabase Dashboard -> SQL Editor

-- Ajout de la contrainte avec verification (DO block)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'payouts_group_turn_unique'
      AND conrelid = 'public.payouts'::regclass
  ) THEN
    ALTER TABLE public.payouts
      ADD CONSTRAINT payouts_group_turn_unique
      UNIQUE (group_id, turn_number);
    RAISE NOTICE 'Contrainte ajoutee.';
  ELSE
    RAISE NOTICE 'Contrainte deja existante, aucune action.';
  END IF;
END;
$$;

-- Activer RLS sur payouts
ALTER TABLE public.payouts ENABLE ROW LEVEL SECURITY;

-- Politique SELECT : membres et organisateur peuvent voir les payouts
DROP POLICY IF EXISTS "payouts_select" ON public.payouts;
CREATE POLICY "payouts_select" ON public.payouts
  FOR SELECT TO authenticated
  USING (
    public.is_group_member(group_id, auth.uid())
    OR public.is_group_organizer(group_id, auth.uid())
  );

-- Politique INSERT : seul l'organisateur peut enregistrer un payout
DROP POLICY IF EXISTS "payouts_insert" ON public.payouts;
CREATE POLICY "payouts_insert" ON public.payouts
  FOR INSERT TO authenticated
  WITH CHECK (public.is_group_organizer(group_id, auth.uid()));

-- Politique UPDATE : seul l'organisateur peut modifier un payout
DROP POLICY IF EXISTS "payouts_update" ON public.payouts;
CREATE POLICY "payouts_update" ON public.payouts
  FOR UPDATE TO authenticated
  USING (public.is_group_organizer(group_id, auth.uid()));

-- Verification finale
SELECT conname, contype
FROM pg_constraint
WHERE conrelid = 'public.payouts'::regclass;
