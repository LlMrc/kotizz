-- =============================================================
-- Fix: user_plan_status view SECURITY DEFINER -> SECURITY INVOKER
-- Supabase Security Advisor: "View defined with SECURITY DEFINER"
--
-- Run this in Supabase Dashboard -> SQL Editor
-- Requires Postgres 15+ (all Supabase cloud projects qualify)
-- =============================================================

-- Option 1 (recommande - le plus simple, Postgres 15+)
-- Convertit la vue existante en SECURITY INVOKER sans la recreer.
ALTER VIEW public.user_plan_status SET (security_invoker = true);


-- =============================================================
-- Si Option 1 echoue (ex: Postgres < 15), utiliser Option 2 :
-- Recuperer d'abord la definition originale de la vue :
--   SELECT pg_get_viewdef('public.user_plan_status', true);
-- Puis la recreer avec security_invoker :
-- =============================================================

-- CREATE OR REPLACE VIEW public.user_plan_status
-- WITH (security_invoker = true)
-- AS
--   <coller ici le resultat de pg_get_viewdef ci-dessus>
-- ;

-- =============================================================
-- Verification apres execution
-- =============================================================
SELECT
  viewname,
  definition
FROM pg_views
WHERE schemaname = 'public'
  AND viewname = 'user_plan_status';
