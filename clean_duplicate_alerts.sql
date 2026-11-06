-- =============================================================
-- WONN - Nettoyage des doublons d'alertes existants (corrigé)
-- À exécuter dans Supabase Dashboard → SQL Editor
-- =============================================================

-- 1. Supprimer les doublons en conservant uniquement la plus ancienne
WITH ranked_alerts AS (
  SELECT 
    id,
    ROW_NUMBER() OVER (
      PARTITION BY user_id, group_id, type, title, body, (created_at::date)
      ORDER BY created_at ASC
    ) AS row_num
  FROM public.alerts
)
DELETE FROM public.alerts
WHERE id IN (
  SELECT id FROM ranked_alerts WHERE row_num > 1
);

-- 2. Remplir le dedupe_key pour les alertes restantes sans clé
UPDATE public.alerts
SET dedupe_key = type || '_' || COALESCE(group_id::text, 'nogroup') || '_' || user_id || '_' || TO_CHAR(created_at, 'YYYY_MM_DD_HH24_MI_SS')
WHERE dedupe_key IS NULL;
