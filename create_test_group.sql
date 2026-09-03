-- =============================================================================
-- KOTIZZ — CRÉATION D'UN GROUPE FICTIF DE TEST
-- Code d'invitation à tester dans l'app : TEST99
-- =============================================================================
-- Copiez et exécutez ce script dans Supabase → SQL Editor → RUN.
-- Ensuite, dans l'application Kotizz, cliquez sur "Rejoindre avec un code"
-- et entrez le code : TEST99
-- =============================================================================

DO $$
DECLARE
  v_organizer_id UUID := gen_random_uuid();
  v_member2_id   UUID := gen_random_uuid();
  v_group_id     UUID := gen_random_uuid();
BEGIN

  -- 1. Nettoyer l'ancien groupe de test s'il existait déjà
  DELETE FROM public.group_members WHERE group_id IN (
    SELECT id FROM public.groups WHERE invite_code = 'TEST99'
  );
  DELETE FROM public.groups WHERE invite_code = 'TEST99';

  -- 2. Créer deux faux profils membres (Organisateur + 1er membre)
  INSERT INTO public.profiles (
    id, username, full_name, phone, trust_score, phone_verified, id_verified,
    completed_cycles, plan, language
  )
  VALUES 
    (
      v_organizer_id,
      'marc_aurele',
      'Marc Aurèle',
      '+509 38 44 1122',
      92,
      true,
      true,
      4,
      'pro',
      'fr'
    ),
    (
      v_member2_id,
      'nadine_petit',
      'Nadine Petit',
      '+509 46 12 3344',
      88,
      true,
      false,
      2,
      'free',
      'fr'
    )
  ON CONFLICT (id) DO NOTHING;

  -- 3. Créer le groupe de test avec le code 'TEST99'
  INSERT INTO public.groups (
    id,
    organizer_id,
    name,
    description,
    category,
    contribution_amount,
    currency,
    frequency,
    order_type,
    start_date,
    status,
    max_members,
    current_turn,
    invite_code,
    whatsapp_link
  )
  VALUES (
    v_group_id,
    v_organizer_id,
    'Sòl Solidarité 2026',
    'Tontine collective de test Kotizz - 6 places au total',
    'Tontine collective',
    5000,
    'HTG',
    'monthly',
    'fixed',
    CURRENT_DATE + INTERVAL '7 days',
    'active',
    6,
    1,
    'TEST99',
    'https://chat.whatsapp.com/test-kotizz-groupe'
  );

  -- 4. Ajouter les 2 premiers membres dans group_members
  -- Tour 1 : Marc Aurèle (Organisateur)
  INSERT INTO public.group_members (
    id, group_id, user_id, turn_order, status, joined_at
  )
  VALUES (
    gen_random_uuid(),
    v_group_id,
    v_organizer_id,
    1,
    'confirmed',
    NOW() - INTERVAL '2 days'
  );

  -- Tour 2 : Nadine Petit
  INSERT INTO public.group_members (
    id, group_id, user_id, turn_order, status, joined_at
  )
  VALUES (
    gen_random_uuid(),
    v_group_id,
    v_member2_id,
    2,
    'confirmed',
    NOW() - INTERVAL '1 day'
  );

  RAISE NOTICE '✅ Groupe créé avec succès ! Code d''invitation : TEST99';

END $$;
