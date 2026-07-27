import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../l10n/app_localizations.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  int _selectedFilter = 0; // 0: Toutes, 1: Non lues, 2: Cotisations

  static final List<_AlertItem> _alerts = [
    _AlertItem(
      id: '1',
      title: "C'est votre tour de recevoir le pot ! 🎉",
      body: 'Le pot de 15 000 HTG du groupe Famille Monplaisir est prêt pour versement sur votre compte MonCash.',
      groupName: 'Famille Monplaisir',
      timeAgo: 'Il y a 15 min',
      dateCategory: 'Aujourd\'hui',
      type: _AlertType.payout,
      isUnread: true,
    ),
    _AlertItem(
      id: '2',
      title: 'Cotisation reçue de Marie L. ✅',
      body: 'Marie L. a validé son versement de 100 USD pour le cycle en cours.',
      groupName: 'Collègues Vinpassport',
      timeAgo: 'Il y a 2h',
      dateCategory: 'Aujourd\'hui',
      type: _AlertType.payment,
      isUnread: true,
    ),
    _AlertItem(
      id: '3',
      title: 'Rappel : Cotisation due dans 2 jours ⏰',
      body: 'N\'oubliez pas d\'effectuer votre virement de 20 000 HTG pour Quartier Turgeau avant le 10 Février.',
      groupName: 'Quartier Turgeau',
      timeAgo: 'Hier à 18:30',
      dateCategory: 'Hier',
      type: _AlertType.reminder,
      isUnread: true,
    ),
    _AlertItem(
      id: '4',
      title: 'Nouveau membre dans la tontine 🤝',
      body: 'Jean-Marc V. s\'est inscrit à Famille Monplaisir suite à votre invitation.',
      groupName: 'Famille Monplaisir',
      timeAgo: 'Hier à 14:15',
      dateCategory: 'Hier',
      type: _AlertType.memberJoined,
      isUnread: false,
    ),
    _AlertItem(
      id: '5',
      title: 'Identité & Score de confiance validés 🛡️',
      body: 'Votre pièce d\'identité a été vérifiée avec succès. Votre Score de Confiance passe à 92/100.',
      groupName: 'Wonn Sécurité',
      timeAgo: 'Il y a 3 jours',
      dateCategory: 'Cette semaine',
      type: _AlertType.system,
      isUnread: false,
    ),
    _AlertItem(
      id: '6',
      title: 'Tontine clôturée avec succès 🏆',
      body: 'Le groupe Épargne Projets 2025 a bouclé ses 6 tours de cotisation sans aucun retard !',
      groupName: 'Épargne Projets 2025',
      timeAgo: 'Il y a 5 jours',
      dateCategory: 'Cette semaine',
      type: _AlertType.completed,
      isUnread: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final filteredAlerts = _alerts.where((a) {
      if (_selectedFilter == 1) return a.isUnread;
      if (_selectedFilter == 2) return a.type == _AlertType.payment || a.type == _AlertType.payout;
      return true;
    }).toList();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar Title & Mark read action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.alertsTitle,
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '3 notifications non lues',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 13,
                        color: AppColors.ash,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      for (var a in _alerts) {
                        a.isUnread = false;
                      }
                    });
                  },
                  icon: const Icon(Icons.done_all_rounded, size: 16, color: AppColors.palm),
                  label: Text(
                    'Tout lire',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.palm,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Filter Chips
            Row(
              children: [
                _FilterChip(
                  label: 'Toutes (${_alerts.length})',
                  selected: _selectedFilter == 0,
                  onTap: () => setState(() => _selectedFilter = 0),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Non lues (3)',
                  selected: _selectedFilter == 1,
                  onTap: () => setState(() => _selectedFilter = 1),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Cotisations (2)',
                  selected: _selectedFilter == 2,
                  onTap: () => setState(() => _selectedFilter = 2),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Alert List Grouped
            for (final alert in filteredAlerts) ...[
              _AlertCard(
                alert: alert,
                onTap: () {
                  setState(() => alert.isUnread = false);
                  _showAlertDetailSheet(context, alert);
                },
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }

  void _showAlertDetailSheet(BuildContext context, _AlertItem alert) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.ash.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                _AlertIconBadge(type: alert.type),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.groupName,
                        style: GoogleFonts.ibmPlexMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ash,
                        ),
                      ),
                      Text(
                        alert.timeAgo,
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
            const SizedBox(height: 16),
            Text(
              alert.title,
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              alert.body,
              style: GoogleFonts.ibmPlexSans(
                fontSize: 14,
                color: AppColors.ink.withOpacity(0.8),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ink,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Voir la tontine',
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : AppColors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? AppColors.ink : AppColors.paperDim),
        ),
        child: Text(
          label,
          style: GoogleFonts.ibmPlexSans(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.white : AppColors.ash,
          ),
        ),
      ),
    );
  }
}

enum _AlertType { payout, payment, reminder, memberJoined, system, completed }

class _AlertItem {
  final String id, title, body, groupName, timeAgo, dateCategory;
  final _AlertType type;
  bool isUnread;

  _AlertItem({
    required this.id,
    required this.title,
    required this.body,
    required this.groupName,
    required this.timeAgo,
    required this.dateCategory,
    required this.type,
    required this.isUnread,
  });
}

class _AlertCard extends StatelessWidget {
  final _AlertItem alert;
  final VoidCallback onTap;

  const _AlertCard({required this.alert, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: alert.isUnread ? AppColors.white : AppColors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: alert.isUnread ? AppColors.marigold.withOpacity(0.5) : AppColors.paperDim,
            width: alert.isUnread ? 1.5 : 1.0,
          ),
          boxShadow: alert.isUnread
              ? [
                  BoxShadow(
                    color: AppColors.marigold.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AlertIconBadge(type: alert.type),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        alert.groupName,
                        style: GoogleFonts.ibmPlexMono(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ash,
                        ),
                      ),
                      Text(
                        alert.timeAgo,
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 11,
                          color: AppColors.ash,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alert.title,
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 15,
                      fontWeight: alert.isUnread ? FontWeight.w700 : FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alert.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 12.5,
                      color: AppColors.ink.withOpacity(0.7),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            if (alert.isUnread) ...[
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.marigold,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AlertIconBadge extends StatelessWidget {
  final _AlertType type;
  const _AlertIconBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color bg, fg;

    switch (type) {
      case _AlertType.payout:
        icon = Icons.payments_rounded;
        bg = AppColors.marigold.withOpacity(0.18);
        fg = AppColors.marigold;
        break;
      case _AlertType.payment:
        icon = Icons.check_circle_rounded;
        bg = AppColors.palm.withOpacity(0.18);
        fg = AppColors.palm;
        break;
      case _AlertType.reminder:
        icon = Icons.alarm_rounded;
        bg = AppColors.coral.withOpacity(0.18);
        fg = AppColors.coral;
        break;
      case _AlertType.memberJoined:
        icon = Icons.person_add_rounded;
        bg = AppColors.ink.withOpacity(0.12);
        fg = AppColors.ink;
        break;
      case _AlertType.system:
        icon = Icons.verified_user_rounded;
        bg = AppColors.palm.withOpacity(0.18);
        fg = AppColors.palm;
        break;
      case _AlertType.completed:
        icon = Icons.emoji_events_rounded;
        bg = AppColors.marigold.withOpacity(0.18);
        fg = AppColors.marigold;
        break;
    }

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: fg, size: 22),
    );
  }
}
