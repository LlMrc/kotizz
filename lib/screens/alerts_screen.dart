import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../l10n/app_localizations.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.alertsTitle,
              style: GoogleFonts.bricolageGrotesque(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.notifications_none_rounded, size: 40, color: AppColors.ash.withOpacity(0.5)),
                    const SizedBox(height: 12),
                    Text(t.alertsEmpty, style: GoogleFonts.ibmPlexSans(fontSize: 13.5, color: AppColors.ash)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
