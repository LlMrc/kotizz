-- =============================================================================
-- KOTIZZ — AUTOMATISATION DU SCORE DE CONFIANCE (TRUST SCORE) & CYCLES
-- =============================================================================
-- À exécuter dans Supabase Dashboard -> SQL Editor -> RUN
--
-- RÈGLES APPLIQUÉES AUTOMATIQUEMENT :
--   1. Tontine terminée (status = 'completed') :
--      -> +5 points de confiance (plafonné à 100)
--      -> +1 cycle complété (completed_cycles) pour chaque membre actif
--
--   2. Membre banni d'une tontine (status = 'left') :
--      -> -15 points de confiance (plancher à 0)
--      -> +1 litige (disputes_count)
-- =============================================================================

-- 1. TRIGGER: Clôture d'une Sòl -> Récompense des membres fiables
CREATE OR REPLACE FUNCTION public.handle_group_completed()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Se déclenche uniquement quand le statut bascule vers 'completed'
  IF NEW.status = 'completed' AND (OLD.status IS DISTINCT FROM 'completed') THEN
    UPDATE public.profiles p
    SET
      completed_cycles = p.completed_cycles + 1,
      trust_score = LEAST(100, p.trust_score + 5),
      updated_at = NOW()
    FROM public.group_members gm
    WHERE gm.group_id = NEW.id
      AND gm.user_id = p.id
      AND gm.status = 'confirmed';

    RAISE NOTICE 'Score de confiance et cycles mis à jour pour le groupe %', NEW.id;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_group_completed ON public.groups;
CREATE TRIGGER trg_group_completed
  AFTER UPDATE OF status ON public.groups
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_group_completed();


-- 2. TRIGGER: Membre banni -> Pénalité de confiance
CREATE OR REPLACE FUNCTION public.handle_member_status_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Se déclenche si le membre passe au statut 'left' (banni)
  IF NEW.status = 'left' AND (OLD.status IS DISTINCT FROM 'left') THEN
    UPDATE public.profiles
    SET
      trust_score = GREATEST(0, trust_score - 15),
      disputes_count = disputes_count + 1,
      updated_at = NOW()
    WHERE id = NEW.user_id;

    RAISE NOTICE 'Pénalité de confiance appliquée à l''utilisateur %', NEW.user_id;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_member_status_change ON public.group_members;
CREATE TRIGGER trg_member_status_change
  AFTER UPDATE OF status ON public.group_members
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_member_status_change();


-- 3. Vérification de l'installation des triggers
SELECT
  trigger_name,
  event_manipulation,
  event_object_table,
  action_statement
FROM information_schema.triggers
WHERE trigger_schema = 'public'
  AND trigger_name IN ('trg_group_completed', 'trg_member_status_change');
