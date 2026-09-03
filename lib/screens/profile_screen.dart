import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../services/plan_service.dart';

enum AppLanguage { english, french, creole }

extension AppLanguageExtension on AppLanguage {
  String get nativeLabel {
    switch (this) {
      case AppLanguage.english:
        return 'English';
      case AppLanguage.french:
        return 'Français';
      case AppLanguage.creole:
        return 'Kreyòl Ayisyen';
    }
  }
}

class ProfileScreen extends StatefulWidget {
  final AppLanguage currentLanguage;
  final ValueChanged<AppLanguage> onLanguageChanged;

  const ProfileScreen({
    super.key,
    required this.currentLanguage,
    required this.onLanguageChanged,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _pushNotifications = true;

  /// Plan courant de l'utilisateur ('free' ou 'pro'). Chargé depuis Supabase.
  String _plan = 'free';
  String _fullName = '';
  String _email = '';
  String _phone = '';
  int _trustScore = 50;
  int _completedCycles = 0;
  bool _phoneVerified = false;
  bool _idVerified = false;
  bool _planLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      
      final data = await Supabase.instance.client
          .from('profiles')
          .select('full_name, phone, plan, plan_expires_at, trust_score, completed_cycles, phone_verified, id_verified')
          .eq('id', user.id)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _email = user.email ?? '';
          _phone = (data?['phone'] as String?) ?? user.phone ?? '';
          _fullName = (data?['full_name'] as String?) ?? user.email?.split('@').first ?? 'Membre';
          _plan = (data?['plan'] as String?) ?? 'free';
          _trustScore = (data?['trust_score'] as int?) ?? 50;
          _completedCycles = (data?['completed_cycles'] as int?) ?? 0;
          _phoneVerified = (data?['phone_verified'] as bool?) ?? false;
          _idVerified = (data?['id_verified'] as bool?) ?? false;
          _planLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _planLoading = false);
    }
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    // AuthGate redirige automatiquement vers AuthScreen.
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              t.profileTitle,
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 18),

            // User Header Card
            _UserHeaderCard(
              fullName: _fullName,
              email: _email,
              phone: _phone,
            ),
            const SizedBox(height: 20),

            // Banner PRO / FREE
            if (!_planLoading)
              _PlanBanner(
                plan: _plan,
                onPlanUpdated: _loadProfile,
              ),
            const SizedBox(height: 16),

            // Reputation & Stats Grid
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    value: '$_trustScore',
                    unit: '/100',
                    label: t.profileTrustScore,
                    color: AppColors.marigold,
                    badge: _plan == 'pro' ? '⭐ PRO' : '🆓 ${t.badgeFree}',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    value: '$_completedCycles',
                    unit: ' ${t.cyclesUnit}',
                    label: t.profileCompletedCycles,
                    color: AppColors.palm,
                    badge: _completedCycles > 0 ? '🏆 100%' : 'Nouveau',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    value: '0',
                    unit: '',
                    label: t.profileDisputes,
                    color: AppColors.ash,
                    badge: '🛡️ Clean',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Section Label
            Text(
              t.sectionSecurity,
              style: GoogleFonts.ibmPlexMono(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: AppColors.ash,
              ),
            ),
            const SizedBox(height: 10),

            // Verification Items
            _VerificationRow(
              icon: Icons.phone_iphone_rounded,
              title: t.profileVerifyPhone,
              subtitle: _phone.isNotEmpty ? _phone : 'Non renseigné',
              done: _phoneVerified,
            ),
            const SizedBox(height: 10),
            _VerificationRow(
              icon: Icons.badge_outlined,
              title: t.identityVerified,
              subtitle: _idVerified ? 'Pièce vérifiée ✓' : 'Non vérifié',
              done: _idVerified,
            ),
            const SizedBox(height: 10),
            _VerificationRow(
              icon: Icons.account_balance_wallet_rounded,
              title: t.bankAccount,
              subtitle: _phone.isNotEmpty ? 'MonCash: $_phone' : 'Non configuré',
              done: _phone.isNotEmpty,
            ),
            const SizedBox(height: 24),

            // Section Label Preferences
            Text(
              t.sectionSettings,
              style: GoogleFonts.ibmPlexMono(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: AppColors.ash,
              ),
            ),
            const SizedBox(height: 12),

            // Language Selector
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.paperDim),
              ),
              child: Row(
                children: [
                  const Icon(Icons.language_rounded, size: 20, color: AppColors.ink),
                  const SizedBox(width: 10),
                  Text(
                    t.profileLanguage,
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  const Spacer(),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<AppLanguage>(
                      value: widget.currentLanguage,
                      isDense: true,
                      borderRadius: BorderRadius.circular(14),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: AppColors.ink),
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                      items: AppLanguage.values.map((lang) {
                        return DropdownMenuItem<AppLanguage>(
                          value: lang,
                          child: Text(lang.nativeLabel),
                        );
                      }).toList(),
                      onChanged: (lang) {
                        if (lang != null) widget.onLanguageChanged(lang);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Toggle Switches Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.paperDim),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    activeTrackColor: AppColors.marigold,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      t.pushNotifications,
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    subtitle: Text(
                      t.alertsTitle,
                      style: GoogleFonts.ibmPlexSans(fontSize: 12, color: AppColors.ash),
                    ),
                    value: _pushNotifications,
                    onChanged: (v) => setState(() => _pushNotifications = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Log out button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _signOut,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.coral,
                  side: const BorderSide(color: AppColors.coral, width: 1.2),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: Text(
                  t.logOut,
                  style: GoogleFonts.ibmPlexSans(fontWeight: FontWeight.w600, fontSize: 14.5),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // App Version Footer
            Center(
              child: Text(
                'Kotizz v1.2.0 • App Store Connect Ready',
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 11,
                  color: AppColors.ash,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserHeaderCard extends StatelessWidget {
  final String fullName;
  final String email;
  final String phone;

  const _UserHeaderCard({
    required this.fullName,
    required this.email,
    required this.phone,
  });

  String get _initials {
    if (fullName.trim().isEmpty) return 'U';
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName.substring(0, fullName.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final displayName = fullName.isNotEmpty ? fullName : 'Membre Kotizz';
    final displayPhone = phone.isNotEmpty ? phone : (email.isNotEmpty ? email : 'Non renseigné');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.marigold,
                  border: Border.all(color: AppColors.white, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  _initials,
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: AppColors.palm,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, color: AppColors.white, size: 14),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayName,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.bricolageGrotesque(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.verified_rounded, color: AppColors.marigold, size: 18),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  email.isNotEmpty ? email : 'Membre Kotizz',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 12,
                    color: AppColors.white.withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    displayPhone,
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 11,
                      color: AppColors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value, unit, label, badge;
  final Color color;

  const _StatCard({
    required this.value,
    required this.unit,
    required this.label,
    required this.color,
    required this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.paperDim),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              if (unit.isNotEmpty)
                Text(
                  unit,
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 11,
                    color: AppColors.ash,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.ibmPlexSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badge,
              style: GoogleFonts.ibmPlexMono(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerificationRow extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final bool done;

  const _VerificationRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.paperDim),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: AppColors.ink),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 12,
                    color: AppColors.ash,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.palm.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.palm),
                const SizedBox(width: 4),
                Text(
                  'Vérifié',
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.palm,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget : Bandeau du plan (FREE / PRO)
// ─────────────────────────────────────────────────────────────────────────────
class _PlanBanner extends StatefulWidget {
  final String plan;
  final VoidCallback onPlanUpdated;

  const _PlanBanner({required this.plan, required this.onPlanUpdated});

  @override
  State<_PlanBanner> createState() => _PlanBannerState();
}

class _PlanBannerState extends State<_PlanBanner> {
  bool _isPurchasing = false;

  Future<void> _handlePurchase() async {
    setState(() => _isPurchasing = true);
    final success = await PlanService.purchasePro();
    if (mounted) {
      setState(() => _isPurchasing = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Merci pour votre achat ! Vous êtes maintenant PRO.')),
        );
        widget.onPlanUpdated();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('L\'achat n\'a pas pu être finalisé.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPro = widget.plan == 'pro';

    if (isPro) {
      // Bandeau PRO actif
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.marigold.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: AppColors.marigold,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Plan PRO actif',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                  Text(
                    'Groupes et membres illimités',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 12,
                      color: AppColors.white.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.marigold.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '9,99\$/m',
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.marigold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Bandeau FREE → invitation à passer PRO
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.paperDim),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.marigold.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.marigold,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plan Gratuit',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      '1 groupe • ${PlanService.freeMaxMembers} membres max',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 12,
                        color: AppColors.ash,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isPurchasing ? null : _handlePurchase,
              icon: _isPurchasing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.ink,
                      ),
                    )
                  : const Icon(
                      Icons.workspace_premium_rounded,
                      size: 18,
                      color: AppColors.ink,
                    ),
              label: Text(
                _isPurchasing ? 'Traitement...' : 'Passer au PRO — 9,99\$/mois',
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.marigold,
                foregroundColor: AppColors.ink,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
