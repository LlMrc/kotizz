-- ============================================================
-- Migration : Notifications automatiques — crons J-3 & J+2
-- À appliquer dans : Supabase Dashboard → SQL Editor
-- ============================================================

-- ── 1. Fonction RPC : membres non payés dont le tour est dans 3 jours ──
DROP FUNCTION IF EXISTS get_unpaid_members_for_reminder();
CREATE OR REPLACE FUNCTION get_unpaid_members_for_reminder()
RETURNS TABLE (
  user_id          uuid,
  fcm_token        text,
  full_name        text,
  group_name       text,
  current_turn     int,
  contribution_amount numeric,
  currency         text,
  days_until_turn  int
)
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT
    p.id                             AS user_id,
    p.fcm_token,
    p.full_name,
    g.name                           AS group_name,
    g.current_turn,
    g.contribution_amount::numeric,
    g.currency,
    -- Calcul approximatif : jours restants avant la date de tour attendue
    -- (tour_date = start_date + (current_turn - 1) * 30 jours si pas de date précise)
    GREATEST(0,
      EXTRACT(day FROM
        (COALESCE(g.start_date::date, NOW()::date) + ((g.current_turn - 1) * interval '30 days'))
        - NOW()::date
      )::int
    )                                AS days_until_turn
  FROM group_members gm
  JOIN profiles p ON p.id = gm.user_id
  JOIN groups g   ON g.id = gm.group_id
  WHERE g.status = 'active'
    AND gm.status = 'confirmed'
    AND p.fcm_token IS NOT NULL
    AND p.push_enabled IS DISTINCT FROM false
    -- Membre non payé pour ce tour
    AND NOT EXISTS (
      SELECT 1 FROM contributions c
      WHERE c.group_id = g.id
        AND c.user_id  = gm.user_id
        AND c.turn_number = g.current_turn
        AND c.payment_status IN ('confirmed', 'late')
    )
    -- Tour dans 1 à 4 jours (fenêtre de rappel J-3)
    AND GREATEST(0,
      EXTRACT(day FROM
        (COALESCE(g.start_date::date, NOW()::date) + ((g.current_turn - 1) * interval '30 days'))
        - NOW()::date
      )::int
    ) BETWEEN 1 AND 4;
$$;

-- ── 2. Fonction RPC : membres non confirmés J+2 après le début du tour ──
DROP FUNCTION IF EXISTS get_late_unpaid_members();
CREATE OR REPLACE FUNCTION get_late_unpaid_members()
RETURNS TABLE (
  user_id              uuid,
  fcm_token            text,
  full_name            text,
  group_name           text,
  current_turn         int,
  contribution_amount  numeric,
  currency             text
)
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT
    p.id                             AS user_id,
    p.fcm_token,
    p.full_name,
    g.name                           AS group_name,
    g.current_turn,
    g.contribution_amount::numeric,
    g.currency
  FROM group_members gm
  JOIN profiles p ON p.id = gm.user_id
  JOIN groups g   ON g.id = gm.group_id
  WHERE g.status = 'active'
    AND gm.status = 'confirmed'
    AND p.fcm_token IS NOT NULL
    AND p.push_enabled IS DISTINCT FROM false
    -- Membre non payé pour ce tour
    AND NOT EXISTS (
      SELECT 1 FROM contributions c
      WHERE c.group_id = g.id
        AND c.user_id  = gm.user_id
        AND c.turn_number = g.current_turn
        AND c.payment_status IN ('confirmed', 'late')
    )
    -- Tour démarré depuis plus de 2 jours
    AND (
      COALESCE(g.start_date::date, NOW()::date)
      + ((g.current_turn - 1) * interval '30 days')
    ) <= NOW()::date - interval '2 days';
$$;

-- ── 3. Activer pg_cron (si pas encore activé) ──
-- Note : pg_cron doit être activé dans Supabase Dashboard
-- Database → Extensions → pg_cron
-- (si déjà activé, cette ligne est ignorée)

-- ── 4. Cron J-3 : rappel quotidien à 9h UTC ──
SELECT cron.schedule(
  'kotizz-reminder-j3',          -- nom unique du job
  '0 9 * * *',                   -- tous les jours à 9h00 UTC
  $$
    SELECT net.http_post(
      url     := current_setting('app.supabase_url') || '/functions/v1/send-push-notifications',
      headers := jsonb_build_object(
        'Content-Type',  'application/json',
        'Authorization', 'Bearer ' || current_setting('app.supabase_service_key')
      ),
      body    := jsonb_build_object(
        'type',   'reminder',
        'secret', current_setting('app.cron_secret')
      )
    );
  $$
);

-- ── 5. Cron J+2 : alerte tardive quotidienne à 10h UTC ──
SELECT cron.schedule(
  'kotizz-late-alert-j2',
  '0 10 * * *',
  $$
    SELECT net.http_post(
      url     := current_setting('app.supabase_url') || '/functions/v1/send-push-notifications',
      headers := jsonb_build_object(
        'Content-Type',  'application/json',
        'Authorization', 'Bearer ' || current_setting('app.supabase_service_key')
      ),
      body    := jsonb_build_object(
        'type',   'late_alert',
        'secret', current_setting('app.cron_secret')
      )
    );
  $$
);

-- ── 6. Cron pénalité : tous les jours à 11h UTC ──
SELECT cron.schedule(
  'kotizz-penalty-daily',
  '0 11 * * *',
  $$
    SELECT net.http_post(
      url     := current_setting('app.supabase_url') || '/functions/v1/send-push-notifications',
      headers := jsonb_build_object(
        'Content-Type',  'application/json',
        'Authorization', 'Bearer ' || current_setting('app.supabase_service_key')
      ),
      body    := jsonb_build_object(
        'type',   'penalty',
        'secret', current_setting('app.cron_secret')
      )
    );
  $$
);

-- ── Vérifier les crons actifs ──
-- SELECT * FROM cron.job;
