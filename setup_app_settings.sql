-- =============================================================
-- WONN - Table de configuration (app_settings)
-- À exécuter dans Supabase Dashboard → SQL Editor
-- =============================================================

CREATE TABLE IF NOT EXISTS public.app_settings (
  key   TEXT PRIMARY KEY,
  value TEXT NOT NULL
);

-- Activer RLS pour sécuriser
ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;

-- Pas de policy publique : seules les fonctions SECURITY DEFINER ou service_role peuvent y accéder
