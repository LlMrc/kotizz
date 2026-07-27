import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../l10n/app_localizations.dart';

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
  bool _biometricEnabled = true;

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
            const _UserHeaderCard(),
            const SizedBox(height: 20),

            // Reputation & Stats Grid
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    value: '92',
                    unit: '/100',
                    label: t.profileTrustScore,
                    color: AppColors.marigold,
                    badge: '⭐ Premium',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    value: '5',
                    unit: ' cycles',
                    label: t.profileCompletedCycles,
                    color: AppColors.palm,
                    badge: '🏆 100%',
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
              'VÉRIFICATIONS ET SÉCURITÉ',
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
              subtitle: '+509 37 12 34 56',
              done: true,
            ),
            const SizedBox(height: 10),
            _VerificationRow(
              icon: Icons.badge_outlined,
              title: t.profileVerifyId,
              subtitle: 'Carte d\'Identité (CNI/Passeport)',
              done: true,
            ),
            const SizedBox(height: 10),
            _VerificationRow(
              icon: Icons.account_balance_wallet_rounded,
              title: 'Moyen de réception',
              subtitle: 'MonCash: +509 37 12 34 56',
              done: true,
            ),
            const SizedBox(height: 24),

            // Section Label Preferences
            Text(
              'PRÉFÉRENCES ET REGLAGES',
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
                      'Notifications Push',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    subtitle: Text(
                      'Alertes de tour et relances',
                      style: GoogleFonts.ibmPlexSans(fontSize: 12, color: AppColors.ash),
                    ),
                    value: _pushNotifications,
                    onChanged: (v) => setState(() => _pushNotifications = v),
                  ),
                  const Divider(height: 1, color: AppColors.paperDim),
                  SwitchListTile(
                    activeTrackColor: AppColors.marigold,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Biométrie / Face ID',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    subtitle: Text(
                      'Connexion sécurisée par empreinte',
                      style: GoogleFonts.ibmPlexSans(fontSize: 12, color: AppColors.ash),
                    ),
                    value: _biometricEnabled,
                    onChanged: (v) => setState(() => _biometricEnabled = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Log out button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {},
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
  const _UserHeaderCard();

  @override
  Widget build(BuildContext context) {
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
                  'LM',
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
                    Text(
                      'Louis Monplaisir',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.verified_rounded, color: AppColors.marigold, size: 18),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '@louis_m • Membre depuis Jan. 2024',
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
                    '+509 37 12 34 56',
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
