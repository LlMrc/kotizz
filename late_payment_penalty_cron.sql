-- =============================================================
-- WONN - Pénalités de retard de paiement (-2 pts / 10 jours)
-- Avec DÉDUPLICATION stricte (DISTINCT + dedupe_key)
-- À exécuter dans Supabase Dashboard → SQL Editor
-- =============================================================

CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS http;

CREATE UNIQUE INDEX IF NOT EXISTS idx_alerts_dedupe_key
  ON public.alerts (dedupe_key)
  WHERE dedupe_key IS NOT NULL;

CREATE TABLE IF NOT EXISTS public.penalty_log (
  id              BIGSERIAL    PRIMARY KEY,
  user_id         UUID         NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  group_id        UUID         NOT NULL REFERENCES public.groups(id)   ON DELETE CASCADE,
  turn_number     INT          NOT NULL,
  penalty_slot    INT          NOT NULL,
  penalty_points  INT          NOT NULL,
  applied_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, group_id, turn_number, penalty_slot)
);

CREATE INDEX IF NOT EXISTS idx_penalty_log_lookup
  ON public.penalty_log (user_id, group_id, turn_number);

-- Fonction principale
CREATE OR REPLACE FUNCTION public.apply_late_payment_penalties()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_group         RECORD;
  v_member        RECORD;
  v_freq_days     INT;
  v_expected_date DATE;
  v_days_overdue  INT;
  v_slot_current  INT;
  v_slot_applied  INT;
  v_new_slots     INT;
  v_penalty       INT;
  v_supabase_url  TEXT;
  v_cron_secret   TEXT;
  v_dedupe_key    TEXT;
BEGIN
  SELECT value INTO v_supabase_url FROM public.app_settings WHERE key = 'supabase_url';
  SELECT value INTO v_cron_secret  FROM public.app_settings WHERE key = 'cron_secret';

  FOR v_group IN
    SELECT id, name, start_date, current_turn,
           frequency, contribution_amount, currency
    FROM public.groups
    WHERE status      = 'active'
      AND start_date  IS NOT NULL
  LOOP
    v_freq_days := CASE v_group.frequency
      WHEN 'weekly'   THEN 7
      WHEN 'biweekly' THEN 14
      ELSE 30
    END;

    v_expected_date := v_group.start_date
                       + ((v_group.current_turn - 1) * v_freq_days);

    IF CURRENT_DATE <= v_expected_date THEN
      CONTINUE;
    END IF;

    v_days_overdue := CURRENT_DATE - v_expected_date;

    IF v_days_overdue < 10 THEN
      CONTINUE;
    END IF;

    v_slot_current := v_days_overdue / 10;

    -- DISTINCT pour éviter qu'un membre avec plusieurs parts ne soit traité plusieurs fois
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
      SELECT COALESCE(MAX(penalty_slot), 0)
        INTO v_slot_applied
        FROM public.penalty_log
       WHERE user_id     = v_member.user_id
         AND group_id    = v_group.id
         AND turn_number = v_group.current_turn;

      v_new_slots := v_slot_current - v_slot_applied;

      IF v_new_slots <= 0 THEN
        CONTINUE;
      END IF;

      v_penalty := v_new_slots * 2;

      UPDATE public.profiles
         SET trust_score = GREATEST(0, trust_score - v_penalty),
             updated_at  = NOW()
       WHERE id = v_member.user_id;

      INSERT INTO public.penalty_log
        (user_id, group_id, turn_number, penalty_slot, penalty_points)
      VALUES
        (v_member.user_id, v_group.id, v_group.current_turn,
         v_slot_current, v_penalty)
      ON CONFLICT (user_id, group_id, turn_number, penalty_slot) DO NOTHING;

      v_dedupe_key := 'penalty_' || v_group.id || '_' || v_member.user_id || '_' || v_group.current_turn || '_slot_' || v_slot_current;

      INSERT INTO public.alerts (user_id, group_id, type, title, body, is_read, dedupe_key)
      VALUES (
        v_member.user_id,
        v_group.id,
        'penalty',
        '⚠️ Pénalité de retard',
        'Votre cotisation pour "' || v_group.name
          || '" (Tour ' || v_group.current_turn
          || ') est en retard de ' || v_days_overdue || ' jours. '
          || v_penalty || ' point(s) de confiance ont été déduits.',
        false,
        v_dedupe_key
      )
      ON CONFLICT (dedupe_key) DO NOTHING;

    END LOOP;
  END LOOP;

  IF v_supabase_url IS NOT NULL AND v_cron_secret IS NOT NULL THEN
    PERFORM http_post(
      v_supabase_url || '/functions/v1/send-push-notifications',
      json_build_object('type', 'penalty', 'secret', v_cron_secret)::text,
      'application/json'
    );
  END IF;

END;
$$;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'daily-late-payment-penalty') THEN
    PERFORM cron.unschedule('daily-late-payment-penalty');
  END IF;
END;
$$;

SELECT cron.schedule(
  'daily-late-payment-penalty',
  '0 2 * * *',
  'SELECT public.apply_late_payment_penalties()'
);
