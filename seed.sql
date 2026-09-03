-- =============================================================================
-- KOTIZZ SEED DATA SCRIPT (Pour tests et captures d'écran App Store)
-- =============================================================================
-- Ce script remplit votre base de données Supabase avec des données riches et
-- réalistes (profils, groupes de Sòl, cotisations, alertes, etc.).
--
-- MODE D'EMPLOI :
-- 1. Connectez-vous une fois dans l'application avec votre e-mail (ex: demo@kotizz.app).
-- 2. Ouvrez la console Supabase -> SQL Editor.
-- 3. Collez ce script et cliquez sur RUN.
-- 4. Rouvrez ou rafraîchissez l'application Kotizz : toutes les données apparaîtront !
-- =============================================================================

DO $$
DECLARE
  v_user_id UUID;
  v_group1_id UUID;
  v_group2_id UUID;
  v_group3_id UUID;
  v_group4_id UUID;
  
  v_member1_id UUID := gen_random_uuid();
  v_member2_id UUID := gen_random_uuid();
  v_member3_id UUID := gen_random_uuid();
  v_member4_id UUID := gen_random_uuid();
BEGIN
  -- 1. Récupère l'ID du premier utilisateur authentifié trouvé dans auth.users
  SELECT id INTO v_user_id FROM auth.users ORDER BY created_at DESC LIMIT 1;

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Aucun utilisateur trouvé dans auth.users ! Veuillez d''abord vous connecter au moins une fois dans l''application pour créer votre compte.';
  END IF;

  RAISE NOTICE 'Utilisation du compte utilisateur ID: %', v_user_id;

  -- 2. Mise à jour du profil principal pour qu'il soit attractif (Score élevé, PRO, etc.)
  INSERT INTO public.profiles (
    id, username, full_name, phone, trust_score, phone_verified, id_verified,
    completed_cycles, plan, language, push_enabled, biometric_enabled
  )
  VALUES (
    v_user_id,
    'jean_louis',
    'Jean-Marc Louis',
    '+509 37 12 3456',
    95,
    true,
    true,
    6,
    'pro',
    'fr',
    true,
    true
  )
  ON CONFLICT (id) DO UPDATE SET
    full_name = EXCLUDED.full_name,
    trust_score = 95,
    completed_cycles = 6,
    plan = 'pro',
    phone_verified = true,
    id_verified = true;

  -- 3. Création des faux profils pour les autres membres des groupes
  -- (Création directe dans auth.users puis profiles pour respecter les contraintes FK)
  
  -- Membre 1 : Marie
  INSERT INTO auth.users (id, email, raw_user_meta_data)
  VALUES (v_member1_id, 'marie.claire@kotizz.app', '{"full_name": "Marie-Claire Joseph"}')
  ON CONFLICT (id) DO NOTHING;
  
  INSERT INTO public.profiles (id, username, full_name, trust_score, plan)
  VALUES (v_member1_id, 'marie_c', 'Marie-Claire Joseph', 98, 'free')
  ON CONFLICT (id) DO NOTHING;

  -- Membre 2 : Fabrice
  INSERT INTO auth.users (id, email, raw_user_meta_data)
  VALUES (v_member2_id, 'fabrice.b@kotizz.app', '{"full_name": "Fabrice Bien-Aimé"}')
  ON CONFLICT (id) DO NOTHING;
  
  INSERT INTO public.profiles (id, username, full_name, trust_score, plan)
  VALUES (v_member2_id, 'fabrice_b', 'Fabrice Bien-Aimé', 90, 'pro')
  ON CONFLICT (id) DO NOTHING;

  -- Membre 3 : Sandra
  INSERT INTO auth.users (id, email, raw_user_meta_data)
  VALUES (v_member3_id, 'sandra.c@kotizz.app', '{"full_name": "Sandra Casimir"}')
  ON CONFLICT (id) DO NOTHING;
  
  INSERT INTO public.profiles (id, username, full_name, trust_score, plan)
  VALUES (v_member3_id, 'sandra_c', 'Sandra Casimir', 94, 'free')
  ON CONFLICT (id) DO NOTHING;

  -- Membre 4 : Dieudonné
  INSERT INTO auth.users (id, email, raw_user_meta_data)
  VALUES (v_member4_id, 'dieudonne.p@kotizz.app', '{"full_name": "Dieudonné Pierre"}')
  ON CONFLICT (id) DO NOTHING;
  
  INSERT INTO public.profiles (id, username, full_name, trust_score, plan)
  VALUES (v_member4_id, 'dieudonne_p', 'Dieudonné Pierre', 88, 'free')
  ON CONFLICT (id) DO NOTHING;

  -- 4. Nettoyage des anciens groupes de test de cet utilisateur (optionnel)
  DELETE FROM public.groups WHERE organizer_id = v_user_id;

  -- 5. Création des GROUPES DE SÒL
  
  -- Groupe 1 : Tontine Entrepreneurs (Active)
  INSERT INTO public.groups (
    organizer_id, name, description, category, contribution_amount,
    currency, frequency, order_type, start_date, status, max_members,
    current_turn, whatsapp_link
  )
  VALUES (
    v_user_id,
    'Tontine Entrepreneurs 2026',
    'Fonds de roulement et investissement mensuel pour projets commerciaux.',
    'Entrepreneuriat',
    50000,
    'HTG',
    'monthly',
    'fixed',
    CURRENT_DATE - INTERVAL '15 days',
    'active',
    5,
    2,
    'https://chat.whatsapp.com/demo1234567890'
  ) RETURNING id INTO v_group1_id;

  -- Groupe 2 : Sòl Fanmi & Zanmi (Active)
  INSERT INTO public.groups (
    organizer_id, name, description, category, contribution_amount,
    currency, frequency, order_type, start_date, status, max_members,
    current_turn, whatsapp_link
  )
  VALUES (
    v_user_id,
    'Sòl Fanmi & Zanmi',
    'Épargne solidaire bimensuelle pour la famille et amis proches.',
    'Famille',
    15000,
    'HTG',
    'biweekly',
    'random',
    CURRENT_DATE - INTERVAL '30 days',
    'active',
    4,
    3,
    'https://chat.whatsapp.com/familygroup123'
  ) RETURNING id INTO v_group2_id;

  -- Groupe 3 : Kotizz Tech & Équipements (Active)
  INSERT INTO public.groups (
    organizer_id, name, description, category, contribution_amount,
    currency, frequency, order_type, start_date, status, max_members,
    current_turn, whatsapp_link
  )
  VALUES (
    v_user_id,
    'Kotizz Tech & Matériel',
    'Cotisation en dollars pour renouvellement du matériel informatique.',
    'Technologie',
    250,
    'USD',
    'monthly',
    'fixed',
    CURRENT_DATE - INTERVAL '5 days',
    'active',
    4,
    1,
    'https://chat.whatsapp.com/techgroup456'
  ) RETURNING id INTO v_group3_id;

  -- Groupe 4 : Sòl Vakans Cap-Haïtien (Terminée / Archivée)
  INSERT INTO public.groups (
    organizer_id, name, description, category, contribution_amount,
    currency, frequency, order_type, start_date, status, max_members,
    current_turn, whatsapp_link
  )
  VALUES (
    v_user_id,
    'Sòl Vakans Cap-Haïtien',
    'Épargne réussie pour les vacances d''été.',
    'Voyages',
    20000,
    'HTG',
    'monthly',
    'fixed',
    CURRENT_DATE - INTERVAL '120 days',
    'completed',
    5,
    5,
    NULL
  ) RETURNING id INTO v_group4_id;

  -- 6. AJOUT DES MEMBRES DANS LES GROUPES
  -- Groupe 1 (5 membres)
  INSERT INTO public.group_members (group_id, user_id, turn_order, status)
  VALUES
    (v_group1_id, v_member1_id, 2, 'confirmed'),
    (v_group1_id, v_member2_id, 3, 'confirmed'),
    (v_group1_id, v_member3_id, 4, 'confirmed'),
    (v_group1_id, v_member4_id, 5, 'confirmed')
  ON CONFLICT DO NOTHING;

  -- Groupe 2 (4 membres)
  INSERT INTO public.group_members (group_id, user_id, turn_order, status)
  VALUES
    (v_group2_id, v_member1_id, 2, 'confirmed'),
    (v_group2_id, v_member3_id, 3, 'confirmed'),
    (v_group2_id, v_member4_id, 4, 'confirmed')
  ON CONFLICT DO NOTHING;

  -- Groupe 3 (4 membres)
  INSERT INTO public.group_members (group_id, user_id, turn_order, status)
  VALUES
    (v_group3_id, v_member2_id, 2, 'confirmed'),
    (v_group3_id, v_member3_id, 3, 'confirmed'),
    (v_group3_id, v_member4_id, 4, 'confirmed')
  ON CONFLICT DO NOTHING;

  -- 7. AJOUT DES COTISATIONS RÉCENTES
  INSERT INTO public.contributions (group_id, user_id, turn_number, amount, currency, payment_status, paid_at)
  VALUES
    (v_group1_id, v_user_id, 2, 50000, 'HTG', 'confirmed', NOW() - INTERVAL '2 days'),
    (v_group1_id, v_member1_id, 2, 50000, 'HTG', 'confirmed', NOW() - INTERVAL '3 days'),
    (v_group1_id, v_member2_id, 2, 50000, 'HTG', 'pending', NULL),
    (v_group2_id, v_user_id, 3, 15000, 'HTG', 'confirmed', NOW() - INTERVAL '1 day'),
    (v_group3_id, v_user_id, 1, 250, 'USD', 'confirmed', NOW() - INTERVAL '4 days');

  -- 8. AJOUT DES PAIEMENTS / POTS (PAYOUTS)
  INSERT INTO public.payouts (group_id, recipient_id, turn_number, total_amount, currency, status, scheduled_date, paid_at)
  VALUES
    (v_group1_id, v_member1_id, 2, 250000, 'HTG', 'scheduled', CURRENT_DATE + INTERVAL '12 days', NULL),
    (v_group2_id, v_user_id, 3, 60000, 'HTG', 'scheduled', CURRENT_DATE + INTERVAL '5 days', NULL),
    (v_group4_id, v_user_id, 5, 100000, 'HTG', 'paid', CURRENT_DATE - INTERVAL '10 days', NOW() - INTERVAL '10 days');

  -- 9. AJOUT DES ALERTES / NOTIFICATIONS DIVERSES
  DELETE FROM public.alerts WHERE user_id = v_user_id;

  INSERT INTO public.alerts (user_id, group_id, type, title, body, is_read, created_at)
  VALUES
    (
      v_user_id,
      v_group2_id,
      'payout',
      '🎉 Votre tour arrive bientôt !',
      'Vous êtes le bénéficiaire du prochain pot de 60 000 HTG le 8 septembre.',
      false,
      NOW() - INTERVAL '15 minutes'
    ),
    (
      v_user_id,
      v_group1_id,
      'payment',
      'Cotisation reçue de Marie-Claire',
      'Marie-Claire Joseph a confirmé son versement de 50 000 HTG pour le tour #2.',
      false,
      NOW() - INTERVAL '2 hours'
    ),
    (
      v_user_id,
      v_group3_id,
      'reminder',
      'Rappel de cotisation',
      'Le tour #1 du groupe "Kotizz Tech & Matériel" (250 USD) est en cours.',
      true,
      NOW() - INTERVAL '1 day'
    ),
    (
      v_user_id,
      v_group1_id,
      'member',
      'Nouveau membre confirmé',
      'Dieudonné Pierre a rejoint "Tontine Entrepreneurs 2026".',
      true,
      NOW() - INTERVAL '3 days'
    );

  RAISE NOTICE '✅ SEED TERMINÉ AVEC SUCCÈS ! Les données de démonstration sont prêtes.';
END $$;
