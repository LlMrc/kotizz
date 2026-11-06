-- =============================================================
-- WONN - Fonctions SQL pour l'Edge Function send-push-notifications
-- À exécuter dans Supabase Dashboard → SQL Editor
-- =============================================================

-- ---------------------------------------------------------------
-- 1. Membres non payés (pour le rappel mensuel)
--    Retourne tous les membres confirmés sans paiement confirmé
--    sur le tour courant, avec leur fcm_token
-- ---------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_unpaid_members_for_reminder()
RETURNS TABLE (
  user_id              UUID,
  fcm_token            TEXT,
  full_name            TEXT,
  group_name           TEXT,
  current_turn         INT,
  contribution_amount  NUMERIC,
  currency             TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
    SELECT
      gm.user_id,
      p.fcm_token,
      COALESCE(p.full_name, p.username, 'Membre')::TEXT AS full_name,
      g.name::TEXT                                       AS group_name,
      g.current_turn,
      g.contribution_amount,
      g.currency
    FROM public.group_members gm
    JOIN public.groups   g ON g.id = gm.group_id
    JOIN public.profiles p ON p.id = gm.user_id
    WHERE g.status    = 'active'
      AND gm.status   = 'confirmed'
      AND NOT EXISTS (
        SELECT 1
        FROM public.contributions c
        WHERE c.group_id        = g.id
          AND c.user_id         = gm.user_id
          AND c.turn_number     = g.current_turn
          AND c.payment_status IN ('confirmed', 'late')
      );
END;
$$;

-- ---------------------------------------------------------------
-- 2. Membres pénalisés aujourd'hui (pour les notifs de pénalité)
--    Retourne les membres dont une nouvelle entrée penalty_log
--    a été créée dans les dernières 24 heures
-- ---------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_penalized_members_today()
RETURNS TABLE (
  user_id              UUID,
  fcm_token            TEXT,
  full_name            TEXT,
  group_name           TEXT,
  current_turn         INT,
  contribution_amount  NUMERIC,
  currency             TEXT,
  days_overdue         INT,
  penalty_points       INT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
    SELECT
      pl.user_id,
      p.fcm_token,
      COALESCE(p.full_name, p.username, 'Membre')::TEXT AS full_name,
      g.name::TEXT                                       AS group_name,
      pl.turn_number,
      g.contribution_amount,
      g.currency,
      -- Recalculer les jours de retard
      (CURRENT_DATE - (
        g.start_date + ((pl.turn_number - 1) *
          CASE g.frequency
            WHEN 'weekly'   THEN 7
            WHEN 'biweekly' THEN 14
            ELSE 30
          END
        )
      ))::INT             AS days_overdue,
      pl.penalty_points
    FROM public.penalty_log  pl
    JOIN public.groups        g ON g.id = pl.group_id
    JOIN public.profiles      p ON p.id = pl.user_id
    WHERE pl.applied_at >= NOW() - INTERVAL '24 hours';
END;
$$;
