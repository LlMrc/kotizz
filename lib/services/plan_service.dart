import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Service centralisé pour la gestion des plans FREE / PRO.
///
/// FREE  : 1 groupe SOL max, 5 membres max par groupe.
/// PRO   : Groupes et membres illimités (9,99 $/mois via RevenueCat).
class PlanService {
  static const String _defaultOfferingIdentifier = 'default';

  static SupabaseClient get _db => Supabase.instance.client;

  static String? get _uid => _db.auth.currentUser?.id;

  // ── Plan de l'utilisateur courant ──────────────────────────────

  /// Retourne 'free' ou 'pro'. Retourne 'free' si non connecté.
  static Future<String> getUserPlan() async {
    if (_uid == null) return 'free';
    try {
      final data = await _db
          .from('profiles')
          .select('plan')
          .eq('id', _uid!)
          .single();
      return (data['plan'] as String?) ?? 'free';
    } catch (_) {
      return 'free';
    }
  }

  /// Retourne true si l'utilisateur a le plan PRO actif.
  static Future<bool> isPro() async => (await getUserPlan()) == 'pro';

  // ── Achats in-app (RevenueCat) ─────────────────────────────────

  /// Lance le processus d'achat via RevenueCat.
  /// Si l'achat réussit, met à jour le profil Supabase pour refléter le plan "pro".
  static Future<bool> purchasePro() async {
    if (_uid == null) return false;

    try {
      // Configure l'identifiant utilisateur dans RevenueCat pour le lier à Supabase
      await Purchases.logIn(_uid!);

      // Récupère les offres disponibles depuis l'offre RevenueCat "default"
      final offerings = await Purchases.getOfferings();
      final offering =
          offerings.getOffering(_defaultOfferingIdentifier) ??
          offerings.current;
      if (offering == null || offering.availablePackages.isEmpty) {
        debugPrint(
          'No RevenueCat offering found for identifier: $_defaultOfferingIdentifier',
        );
        return false;
      }

      // Lance l'achat du premier package disponible de l'offre configurée
      final package = offering.availablePackages.first;
      final customerInfo = await Purchases.purchasePackage(package);

      // Vérifie si l'utilisateur a l'entitlement actif (nommé 'Kotizz Pro' dans RevenueCat)
      final isProActive =
          customerInfo.entitlements.active.containsKey('Kotizz Pro') ||
          customerInfo.entitlements.active.containsKey('pro') ||
          customerInfo.entitlements.active.containsKey('kotizz_pro');

      if (isProActive) {
        // Mise à jour locale (le webhook s'en chargera aussi côté serveur)
        await _db.from('profiles').update({'plan': 'pro'}).eq('id', _uid!);
        return true;
      }

      return false;
    } catch (e) {
      // L'utilisateur a annulé ou erreur
      return false;
    }
  }

  // ── Quotas ─────────────────────────────────────────────────────

  /// L'utilisateur peut-il créer un nouveau groupe SOL ?
  ///   FREE → max 1 groupe actif/draft
  ///   PRO  → toujours vrai
  static Future<bool> canCreateGroup() async {
    if (_uid == null) return false;
    try {
      return await _db.rpc('can_create_group', params: {'p_user_id': _uid})
              as bool? ??
          false;
    } catch (_) {
      return false;
    }
  }

  /// L'organisateur peut-il ajouter un membre à ce groupe ?
  ///   FREE → max 5 membres (organisateur inclus)
  ///   PRO  → toujours vrai
  static Future<bool> canAddMember(String groupId) async {
    if (_uid == null) return false;
    try {
      return await _db.rpc(
                'can_add_member',
                params: {'p_group_id': groupId, 'p_organizer_id': _uid},
              )
              as bool? ??
          false;
    } catch (_) {
      return false;
    }
  }

  // ── Constantes de limites ──────────────────────────────────────

  /// Nombre max de groupes pour un compte FREE.
  static const int freeMaxGroups = 1;

  /// Nombre max de membres par groupe pour un compte FREE.
  static const int freeMaxMembers = 5;

  /// Prix mensuel du plan PRO (en USD).
  static const double proMonthlyPrice = 9.99;
}
