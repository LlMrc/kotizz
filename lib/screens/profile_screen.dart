import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../l10n/app_localizations.dart';

enum AppLanguage { english, french }

extension AppLanguageExtension on AppLanguage {
  String get nativeLabel {
    switch (this) {
      case AppLanguage.english:
        return 'English';
      case AppLanguage.french:
        return 'Français';
    }
  }
}

class ProfileScreen extends StatelessWidget {
  final AppLanguage currentLanguage;
  final ValueChanged<AppLanguage> onLanguageChanged;

  const ProfileScreen({
    super.key,
    required this.currentLanguage,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.profileTitle,
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 20),

            // ---------- Stats de réputation ----------
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    value: '92',
                    label: t.profileTrustScore,
                    color: AppColors.marigold,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    value: '5',
                    label: t.profileCompletedCycles,
                    color: AppColors.palm,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    value: '0',
                    label: t.profileDisputes,
                    color: AppColors.coral,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // ---------- Vérifications ----------
            _ActionRow(
              icon: Icons.phone_iphone_rounded,
              label: t.profileVerifyPhone,
              done: true,
            ),
            const SizedBox(height: 10),
            _ActionRow(
              icon: Icons.badge_outlined,
              label: t.profileVerifyId,
              done: false,
            ),
            const SizedBox(height: 28),

            // ---------- Sélecteur de langue ----------
            Text(
              t.profileLanguage,
              style: GoogleFonts.ibmPlexSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: AppLanguage.values.map((lang) {
                final selected = lang == currentLanguage;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(lang.nativeLabel),
                    selected: selected,
                    onSelected: (_) => onLanguageChanged(lang),
                    selectedColor: AppColors.ink,
                    backgroundColor: AppColors.white,
                    labelStyle: GoogleFonts.ibmPlexSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: selected ? AppColors.white : AppColors.ink,
                    ),
                    side: BorderSide(color: AppColors.paperDim),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.coral,
                  side: const BorderSide(color: AppColors.coral),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  t.logOut,
                  style: GoogleFonts.ibmPlexSans(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value, label;
  final Color color;
  const _StatCard({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.paperDim),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.ibmPlexMono(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.ibmPlexSans(
              fontSize: 10.5,
              color: AppColors.ash,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool done;
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.paperDim),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.ink),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.ibmPlexSans(
                fontSize: 13.5,
                color: AppColors.ink,
              ),
            ),
          ),
          Icon(
            done ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
            size: 18,
            color: done ? AppColors.palm : AppColors.ash,
          ),
        ],
      ),
    );
  }
}
