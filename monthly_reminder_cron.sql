-- =============================================================
-- WONN - Rappel mensuel de cotisation (25 du mois)
-- Avec DÉDUPLICATION stricte (DISTINCT + dedupe_key)
-- À exécuter dans Supabase Dashboard → SQL Editor
-- =============================================================

CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS http;

-- 1. Index unique sur dedupe_key pour bloquer tout doublon au niveau de la DB
CREATE UNIQUE INDEX IF NOT EXISTS idx_alerts_dedupe_key
  ON public.alerts (dedupe_key)
  WHERE dedupe_key IS NOT NULL;

-- 2. Fonction principale de rappel
CREATE OR REPLACE FUNCTION public.send_monthly_contribution_reminder()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_group        RECORD;
  v_member       RECORD;
  v_supabase_url TEXT;
  v_cron_secret  TEXT;
  v_dedupe_key   TEXT;
BEGIN
  -- Récupérer la configuration depuis app_settings
  SELECT value INTO v_supabase_url FROM public.app_settings WHERE key = 'supabase_url';
  SELECT value INTO v_cron_secret  FROM public.app_settings WHERE key = 'cron_secret';

  -- ── Étape 1 : insérer les alertes in-app ──────────────────────────────────
  FOR v_group IN
    SELECT id, name, current_turn, contribution_amount, currency
    FROM public.groups
    WHERE status = 'active'
  LOOP
    -- DISTINCT pour éviter les doublons si un membre possède plusieurs mains/tours dans le groupe
    FOR v_member IN
      SELECT DISTINCT gm.user_id
      FROM public.group_members gm
      WHERE gm.group_id = v_group.id
        AND gm.status   = 'confirmed'
        AND NOT EXISTS (
          SELECT 1
          FROM public.contributions c
          WHERE c.group_id        = v_group.id
            AND c.user_id         = gm.user_id
            AND c.turn_number     = v_group.current_turn
            AND c.payment_status IN ('confirmed', 'late')
        )
    LOOP
      -- Clé unique par membre, groupe, tour et mois (ex: reminder_GRP_USER_T1_2026_11)
      v_dedupe_key := 'reminder_' || v_group.id || '_' || v_member.user_id || '_' || v_group.current_turn || '_' || TO_CHAR(CURRENT_DATE, 'YYYY_MM');

      -- N'insérer que si l'alerte n'existe pas encore pour ce mois
      INSERT INTO public.alerts (user_id, group_id, type, title, body, is_read, dedupe_key)
      VALUES (
        v_member.user_id,
        v_group.id,
        'reminder',
        '💰 Rappel de cotisation',
        'Votre cotisation de '
          || v_group.contribution_amount || ' ' || v_group.currency
          || ' pour "' || v_group.name
          || '" (Tour ' || v_group.current_turn
          || ') n''est pas encore confirmée. Pensez à payer avant la fin du mois !',
        false,
        v_dedupe_key
      )
      ON CONFLICT (dedupe_key) DO NOTHING;
    END LOOP;
  END LOOP;

  -- ── Étape 2 : appeler l'Edge Function pour les push FCM ──────────────────
  IF v_supabase_url IS NOT NULL AND v_cron_secret IS NOT NULL THEN
    PERFORM http_post(
      v_supabase_url || '/functions/v1/send-push-notifications',
      json_build_object('type', 'reminder', 'secret', v_cron_secret)::text,
      'application/json'
    );
  END IF;

END;
$$;

-- 3. Planification cron
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'monthly-contribution-reminder') THEN
    PERFORM cron.unschedule('monthly-contribution-reminder');
  END IF;
END;
$$;

SELECT cron.schedule(
  'monthly-contribution-reminder',
  '0 9 25 * *',
  'SELECT public.send_monthly_contribution_reminder()'
);
