import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_colors.dart';
import '../l10n/app_localizations.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  int _selectedFilter = 0; // 0: Toutes, 1: Non lues, 2: Cotisations
  bool _isLoading = true;
  List<_AlertItem> _realAlerts = [];

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final data = await Supabase.instance.client
          .from('notifications')
          .select('*')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      final loaded = (data as List).map((map) {
        final typeStr = (map['type'] as String?) ?? 'system';
        _AlertType type = _AlertType.system;
        if (typeStr == 'payment') type = _AlertType.payment;
        if (typeStr == 'payout') type = _AlertType.payout;
        if (typeStr == 'reminder') type = _AlertType.reminder;
        if (typeStr == 'member') type = _AlertType.memberJoined;

        return _AlertItem(
          id: map['id'].toString(),
          title: (map['title'] as String?) ?? 'Notification',
          body: (map['body'] as String?) ?? '',
          groupName: 'Kotizz',
          timeAgo: 'Récemment',
          dateCategory: 'Notification',
          type: type,
          isUnread: (map['read'] as bool?) == false,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _realAlerts = loaded;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final filteredAlerts = _realAlerts.where((a) {
      if (_selectedFilter == 1) return a.isUnread;
      if (_selectedFilter == 2) return a.type == _AlertType.payment || a.type == _AlertType.payout;
      return true;
    }).toList();

    final unreadCount = _realAlerts.where((a) => a.isUnread).length;

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
                      '$unreadCount notification${unreadCount > 1 ? 's' : ''} non lue${unreadCount > 1 ? 's' : ''}',
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
                      for (var a in _realAlerts) {
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
                  label: 'Toutes (${_realAlerts.length})',
                  selected: _selectedFilter == 0,
                  onTap: () => setState(() => _selectedFilter = 0),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Non lues ($unreadCount)',
                  selected: _selectedFilter == 1,
                  onTap: () => setState(() => _selectedFilter = 1),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.marigold),
                ),
              )
            else if (filteredAlerts.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.paperDim),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.notifications_none_rounded, size: 48, color: AppColors.ash),
                    const SizedBox(height: 12),
                    Text(
                      'Aucune alerte pour le moment',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Vous recevrez ici les rappels de cotisation et les alertes de votre tontine.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.ibmPlexSans(fontSize: 12.5, color: AppColors.ash),
                    ),
                  ],
                ),
              )
            else
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
                  color: AppColors.ash.withValues(alpha: 0.3),
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
                color: AppColors.ink.withValues(alpha: 0.8),
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
          color: alert.isUnread ? AppColors.white : AppColors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: alert.isUnread ? AppColors.marigold.withValues(alpha: 0.5) : AppColors.paperDim,
            width: alert.isUnread ? 1.5 : 1.0,
          ),
          boxShadow: alert.isUnread
              ? [
                  BoxShadow(
                    color: AppColors.marigold.withValues(alpha: 0.06),
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
                      color: AppColors.ink.withValues(alpha: 0.7),
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
        bg = AppColors.marigold.withValues(alpha: 0.18);
        fg = AppColors.marigold;
        break;
      case _AlertType.payment:
        icon = Icons.check_circle_rounded;
        bg = AppColors.palm.withValues(alpha: 0.18);
        fg = AppColors.palm;
        break;
      case _AlertType.reminder:
        icon = Icons.alarm_rounded;
        bg = AppColors.coral.withValues(alpha: 0.18);
        fg = AppColors.coral;
        break;
      case _AlertType.memberJoined:
        icon = Icons.person_add_rounded;
        bg = AppColors.ink.withValues(alpha: 0.12);
        fg = AppColors.ink;
        break;
      case _AlertType.system:
        icon = Icons.verified_user_rounded;
        bg = AppColors.palm.withValues(alpha: 0.18);
        fg = AppColors.palm;
        break;
      case _AlertType.completed:
        icon = Icons.emoji_events_rounded;
        bg = AppColors.marigold.withValues(alpha: 0.18);
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

