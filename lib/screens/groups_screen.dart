import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../widgets/join_group_dialog.dart';
import 'create_sol_screen.dart';

String? normalizeWhatsAppLink(String? rawLink) {
  final trimmed = rawLink?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;

  final uri = Uri.tryParse(trimmed);
  if (uri == null) return null;
  if (uri.scheme != 'http' && uri.scheme != 'https') return null;
  if (!uri.host.toLowerCase().contains('whatsapp')) return null;

  return uri.toString();
}

Future<void> openWhatsAppLink(String? rawLink) async {
  final normalized = normalizeWhatsAppLink(rawLink);
  if (normalized == null) return;

  final uri = Uri.parse(normalized);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  int _selectedFilter = 0; // 0: Toutes, 1: Actives, 2: Terminées
  bool _isLoading = true;
  List<_GroupData> _realGroups = [];

  @override
  void initState() {
    super.initState();
    _loadUserGroups();
  }

  Future<void> _loadUserGroups() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await Supabase.instance.client
          .from('groups')
          .select('*, profiles!organizer_id(full_name), group_members(user_id, turn_order, profiles(full_name))')
          .order('created_at', ascending: false);

      final loaded = (response as List).map((map) {
        final isDraft = map['status'] == 'draft';
        final isCompleted = map['status'] == 'completed';
        final organizerName =
            map['profiles'] != null && map['profiles']['full_name'] != null
            ? map['profiles']['full_name'] as String
            : 'Organisateur';
        final organizerId = (map['organizer_id'] as String?) ?? '';
        final inviteCode = (map['invite_code'] as String?);
        final maxMembers = (map['max_members'] as int?) ?? 5;
        final currentTurn = (map['current_turn'] as int?) ?? 1;
        final amountNum = double.tryParse(map['contribution_amount'].toString()) ?? 0.0;
        final totalPotStr = '${(amountNum * maxMembers).toStringAsFixed(0)} ${map['currency'] ?? 'HTG'}';

        List<String> memberNames = [organizerName];
        if (map['group_members'] != null && (map['group_members'] as List).isNotEmpty) {
          final gmList = (map['group_members'] as List);
          memberNames = gmList.map((gm) {
            if (gm['profiles'] != null && gm['profiles']['full_name'] != null) {
              return gm['profiles']['full_name'] as String;
            }
            return 'Membre';
          }).toList();
        }

        return _GroupData(
          id: map['id'].toString(),
          name: (map['name'] as String?) ?? 'Sòl sans nom',
          category: isDraft ? 'Brouillon' : 'Tontine collective',
          organizer: organizerName,
          organizerId: organizerId,
          contributionAmount: map['contribution_amount'].toString(),
          currency: (map['currency'] as String?) ?? 'HTG',
          frequency: (map['frequency'] as String?) == 'monthly'
              ? 'Mensuelle'
              : (map['frequency'] as String?) == 'weekly'
              ? 'Hebdomadaire'
              : 'Bi-hebdomadaire',
          totalPot: totalPotStr,
          currentTurn: currentTurn,
          totalTurns: maxMembers,
          nextTurnDate: map['start_date'] as String? ?? 'À venir',
          status: isDraft
              ? _GroupStatus.dueSoon
              : (isCompleted ? _GroupStatus.completed : _GroupStatus.upToDate),
          members: memberNames,
          isActive: !isCompleted,
          color: isDraft ? AppColors.marigold : AppColors.palm,
          whatsappLink: map['whatsapp_link'] as String?,
          inviteCode: inviteCode,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _realGroups = loaded;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final filteredGroups = _realGroups.where((g) {
      if (_selectedFilter == 1) return g.isActive;
      if (_selectedFilter == 2) return !g.isActive;
      return true;
    }).toList();

    final activeCount = _realGroups.where((g) => g.isActive).length;
    final completedCount = _realGroups.where((g) => !g.isActive).length;

    return Scaffold(
      backgroundColor: AppColors.paper,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.marigold,
        foregroundColor: AppColors.ink,
        elevation: 3,
        onPressed: () => _showJoinGroupDialog(context),
        icon: const Icon(Icons.vpn_key_rounded, size: 20),
        label: Text(
          t.joinSol,
          style: GoogleFonts.ibmPlexSans(
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            MediaQuery.sizeOf(context).width >= 720 ? 32 : 20,
            16,
            MediaQuery.sizeOf(context).width >= 720 ? 32 : 20,
            100,
          ),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Actions
                  Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.groupsTitle,
                        style: GoogleFonts.bricolageGrotesque(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        t.registeredGroupsCount(_realGroups.length),
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 13,
                          color: AppColors.ash,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        tooltip: t.joinWithCode,
                        onPressed: () => _showJoinGroupDialog(context),
                        icon: const Icon(Icons.group_add_rounded, color: AppColors.ink),
                      ),
                      IconButton(
                        tooltip: t.createSol,
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const CreateSolScreen(),
                            ),
                          );
                          _loadUserGroups();
                        },
                        icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.marigold, size: 28),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Filter Chips
              Row(
                children: [
                  _FilterChip(
                    label: '${t.filterAll} (${_realGroups.length})',
                    selected: _selectedFilter == 0,
                    onTap: () => setState(() => _selectedFilter = 0),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: '${t.filterActive} ($activeCount)',
                    selected: _selectedFilter == 1,
                    onTap: () => setState(() => _selectedFilter = 1),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: '${t.filterCompleted} ($completedCount)',
                    selected: _selectedFilter == 2,
                    onTap: () => setState(() => _selectedFilter = 2),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Loading / Empty / List state
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.marigold),
                  ),
                )
              else if (filteredGroups.isEmpty)
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
                      const Icon(
                        Icons.groups_outlined,
                        size: 48,
                        color: AppColors.ash,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        t.noGroupsFound,
                        style: GoogleFonts.bricolageGrotesque(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t.createFirstGroupPrompt,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 12.5,
                          color: AppColors.ash,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const CreateSolScreen(),
                                ),
                              );
                              _loadUserGroups();
                            },
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: Text(t.createSol),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.marigold,
                              foregroundColor: AppColors.ink,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton.icon(
                            onPressed: () => _showJoinGroupDialog(context),
                            icon: const Icon(Icons.vpn_key_rounded, size: 18),
                            label: Text(t.joinWithCode),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.ink,
                              side: const BorderSide(color: AppColors.ink),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              else if (MediaQuery.sizeOf(context).width >= 720) ...[
                for (int i = 0; i < filteredGroups.length; i += 2) ...[
                  Row(
                    children: [
                      Expanded(
                        child: _GroupCardItem(
                          group: filteredGroups[i],
                          onTap: () => _showGroupDetailModal(context, filteredGroups[i]),
                        ),
                      ),
                      const SizedBox(width: 14),
                      if (i + 1 < filteredGroups.length)
                        Expanded(
                          child: _GroupCardItem(
                            group: filteredGroups[i + 1],
                            onTap: () => _showGroupDetailModal(context, filteredGroups[i + 1]),
                          ),
                        )
                      else
                        const Expanded(child: SizedBox.shrink()),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
              ] else
                for (final group in filteredGroups) ...[
                  _GroupCardItem(
                    group: group,
                    onTap: () => _showGroupDetailModal(context, group),
                  ),
                  const SizedBox(height: 14),
                ],
            ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showJoinGroupDialog(BuildContext context) =>
      showJoinGroupDialog(context, onGroupJoined: _loadUserGroups);

  void _showGroupDetailModal(BuildContext context, _GroupData group) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: _GroupDetailSheet(
              group: group,
              onGroupUpdated: _loadUserGroups,
            ),
          ),
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
          border: Border.all(
            color: selected ? AppColors.ink : AppColors.paperDim,
          ),
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

enum _GroupStatus { yourTurn, upToDate, dueSoon, completed }

class _GroupData {
  final String id,
      name,
      category,
      organizer,
      organizerId,
      contributionAmount,
      currency,
      frequency,
      totalPot,
      nextTurnDate;
  final int currentTurn, totalTurns;
  final _GroupStatus status;
  final List<String> members;
  final bool isActive;
  final Color color;
  final String? whatsappLink;
  final String? inviteCode;

  const _GroupData({
    required this.id,
    required this.name,
    required this.category,
    required this.organizer,
    required this.organizerId,
    required this.contributionAmount,
    required this.currency,
    required this.frequency,
    required this.totalPot,
    required this.currentTurn,
    required this.totalTurns,
    required this.nextTurnDate,
    required this.status,
    required this.members,
    required this.isActive,
    required this.color,
    this.whatsappLink,
    this.inviteCode,
  });
}

class _GroupCardItem extends StatelessWidget {
  final _GroupData group;
  final VoidCallback onTap;

  const _GroupCardItem({required this.group, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final progress = group.currentTurn / group.totalTurns;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.paperDim),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Category & Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: group.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    group.category,
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: group.color,
                    ),
                  ),
                ),
                _StatusBadge(status: group.status),
              ],
            ),
            const SizedBox(height: 12),

            // Group Name & Details
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: group.color,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    group.name.substring(0, 2).toUpperCase(),
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: GoogleFonts.bricolageGrotesque(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Org: ${group.organizer} • ${group.frequency}',
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

            // Contribution & Total Pot Info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cotisation / membre',
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 11,
                          color: AppColors.ash,
                        ),
                      ),
                      Text(
                        '${group.contributionAmount} ${group.currency}',
                        style: GoogleFonts.ibmPlexMono(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                  Container(height: 24, width: 1, color: AppColors.paperDim),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Cagnotte Totale',
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 11,
                          color: AppColors.ash,
                        ),
                      ),
                      Text(
                        group.totalPot,
                        style: GoogleFonts.ibmPlexMono(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.marigold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Progress bar & Turn details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tour ${group.currentTurn} sur ${group.totalTurns}',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  'Prochain: ${group.nextTurnDate}',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 12,
                    color: AppColors.ash,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 7,
                backgroundColor: AppColors.paperDim,
                valueColor: AlwaysStoppedAnimation<Color>(
                  group.status == _GroupStatus.yourTurn
                      ? AppColors.marigold
                      : group.color,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Member Avatars Stack
            Row(
              children: [
                _MemberAvatarsStack(members: group.members),
                const Spacer(),
                Row(
                  children: [
                    if (normalizeWhatsAppLink(group.whatsappLink) != null) ...[
                      GestureDetector(
                        onTap: () => openWhatsAppLink(group.whatsappLink),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF25D366,
                            ).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.chat_rounded,
                                size: 12,
                                color: Color(0xFF25D366),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'WhatsApp',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF25D366),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      'Détails',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: AppColors.ink,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final _GroupStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    String label;
    Color bg, fg;

    switch (status) {
      case _GroupStatus.yourTurn:
        label = "C'est votre tour ! 🎉";
        bg = AppColors.marigold.withValues(alpha: 0.2);
        fg = const Color(0xFFB87A1F);
        break;
      case _GroupStatus.upToDate:
        label = 'À jour';
        bg = AppColors.palm.withValues(alpha: 0.15);
        fg = AppColors.palm;
        break;
      case _GroupStatus.dueSoon:
        label = 'Cotisation due';
        bg = AppColors.coral.withValues(alpha: 0.15);
        fg = AppColors.coral;
        break;
      case _GroupStatus.completed:
        label = 'Terminé 🏆';
        bg = AppColors.ash.withValues(alpha: 0.15);
        fg = AppColors.ash;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.ibmPlexMono(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

class _MemberAvatarsStack extends StatelessWidget {
  final List<String> members;
  const _MemberAvatarsStack({required this.members});

  @override
  Widget build(BuildContext context) {
    final showCount = members.length > 4 ? 4 : members.length;
    final extra = members.length - showCount;

    return SizedBox(
      height: 30,
      width: (showCount * 22.0) + (extra > 0 ? 30 : 10),
      child: Stack(
        children: [
          for (int i = 0; i < showCount; i++)
            Positioned(
              left: i * 20.0,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.ink,
                  border: Border.all(color: AppColors.white, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  members[i].substring(0, 1),
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          if (extra > 0)
            Positioned(
              left: showCount * 20.0,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.paperDim,
                  border: Border.all(color: AppColors.white, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  '+$extra',
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GroupDetailSheet extends StatefulWidget {
  final _GroupData group;
  final VoidCallback? onGroupUpdated;

  const _GroupDetailSheet({
    required this.group,
    this.onGroupUpdated,
  });

  @override
  State<_GroupDetailSheet> createState() => _GroupDetailSheetState();
}

class _GroupDetailSheetState extends State<_GroupDetailSheet> {
  bool _isLoadingMembers = true;
  List<Map<String, dynamic>> _membersList = [];
  String? _currentInviteCode;
  int _currentTurn = 1;
  String _groupStatus = 'draft';
  Map<String, Map<String, dynamic>> _turnContributions = {};

  bool get _isOrganizer =>
      Supabase.instance.client.auth.currentUser?.id == widget.group.organizerId;

  @override
  void initState() {
    super.initState();
    _currentInviteCode = widget.group.inviteCode;
    _currentTurn = widget.group.currentTurn;
    _loadGroupMembers();
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = math.Random();
    return List.generate(6, (index) => chars[rnd.nextInt(chars.length)]).join();
  }

  Future<void> _loadGroupMembers() async {
    try {
      // 1. S'assurer qu'un code d'invitation existe
      if (_currentInviteCode == null || _currentInviteCode!.isEmpty) {
        final newCode = _generateInviteCode();
        await Supabase.instance.client
            .from('groups')
            .update({'invite_code': newCode})
            .eq('id', widget.group.id);
        if (mounted) {
          setState(() => _currentInviteCode = newCode);
        }
      }

      // 2. Récupérer l'état actuel du groupe (tour et statut)
      final groupDoc = await Supabase.instance.client
          .from('groups')
          .select('current_turn, status')
          .eq('id', widget.group.id)
          .maybeSingle();

      if (groupDoc != null) {
        _currentTurn = (groupDoc['current_turn'] as int?) ?? _currentTurn;
        _groupStatus = (groupDoc['status'] as String?) ?? _groupStatus;
      }

      // 3. Récupérer les membres réels
      final response = await Supabase.instance.client
          .from('group_members')
          .select('*, profiles:user_id(id, full_name, phone)')
          .eq('group_id', widget.group.id)
          .order('turn_order', ascending: true);

      // 4. Récupérer les cotisations du tour en cours
      final contribsResponse = await Supabase.instance.client
          .from('contributions')
          .select()
          .eq('group_id', widget.group.id)
          .eq('turn_number', _currentTurn);

      final Map<String, Map<String, dynamic>> turnContribs = {};
      for (final c in (contribsResponse as List)) {
        final uId = c['user_id'] as String?;
        if (uId != null) {
          turnContribs[uId] = Map<String, dynamic>.from(c);
        }
      }

      if (mounted) {
        setState(() {
          // Exclure les membres bannis (status = 'left') de la liste affichée
          _membersList = (response as List)
              .cast<Map<String, dynamic>>()
              .where((m) => (m['status'] as String?) != 'left')
              .toList();
          _turnContributions = turnContribs;
          _isLoadingMembers = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingMembers = false);
    }
  }

  /// Gérer le statut du paiement d'un membre (Organisateur uniquement)
  /// Affiche un menu avec 3 options : Confirmer / Tardif / En attente
  Future<void> _togglePayment(String memberUserId, String memberName) async {
    if (!_isOrganizer) return;

    final currentContrib = _turnContributions[memberUserId];
    final currentStatus = currentContrib?['payment_status'] as String? ?? 'pending';

    // Afficher un bottom sheet avec les choix
    final chosen = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.ash.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Statut — $memberName',
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink,
              ),
            ),
            Text(
              'Tour $_currentTurn · ${widget.group.contributionAmount} ${widget.group.currency}',
              style: GoogleFonts.ibmPlexSans(fontSize: 12.5, color: AppColors.ash),
            ),
            const SizedBox(height: 14),
            _paymentOptionTile(
              ctx: ctx,
              value: 'confirmed',
              icon: Icons.check_circle_rounded,
              color: AppColors.palm,
              label: 'Confirmer le paiement',
              subtitle: 'Le membre a versé sa cotisation',
              current: currentStatus,
            ),
            const SizedBox(height: 8),
            _paymentOptionTile(
              ctx: ctx,
              value: 'late',
              icon: Icons.watch_later_rounded,
              color: const Color(0xFFB87A1F),
              label: 'Marquer comme tardif',
              subtitle: 'Paiement reçu hors délai',
              current: currentStatus,
            ),
            const SizedBox(height: 8),
            _paymentOptionTile(
              ctx: ctx,
              value: 'pending',
              icon: Icons.pending_actions_rounded,
              color: AppColors.coral,
              label: 'Remettre en attente',
              subtitle: 'Annuler la confirmation',
              current: currentStatus,
            ),
          ],
        ),
      ),
    );

    if (chosen == null || chosen == currentStatus) return;

    try {
      final amountNum = double.tryParse(widget.group.contributionAmount) ?? 0.0;
      final isPaid = chosen == 'confirmed' || chosen == 'late';

      if (currentContrib != null) {
        await Supabase.instance.client
            .from('contributions')
            .update({
              'payment_status': chosen,
              'paid_at': isPaid ? DateTime.now().toIso8601String() : null,
            })
            .eq('id', currentContrib['id']);
      } else {
        await Supabase.instance.client
            .from('contributions')
            .insert({
              'group_id': widget.group.id,
              'user_id': memberUserId,
              'turn_number': _currentTurn,
              'amount': amountNum,
              'currency': widget.group.currency,
              'payment_status': chosen,
              'paid_at': isPaid ? DateTime.now().toIso8601String() : null,
            });
      }

      await _loadGroupMembers();
      widget.onGroupUpdated?.call();

      if (mounted) {
        final (msg, bg) = switch (chosen) {
          'confirmed' => ('Cotisation de $memberName confirmée ! 🟢', AppColors.palm),
          'late'      => ('$memberName marqué tardif 🟡', const Color(0xFFB87A1F)),
          _           => ('$memberName remis en attente 🔴', AppColors.ink),
        };
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: bg,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.coral,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Tuile d'option dans le bottom sheet de paiement
  Widget _paymentOptionTile({
    required BuildContext ctx,
    required String value,
    required IconData icon,
    required Color color,
    required String label,
    required String subtitle,
    required String current,
  }) {
    final isSelected = current == value;
    return GestureDetector(
      onTap: () => Navigator.of(ctx).pop(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.10) : AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : AppColors.paperDim,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.ibmPlexSans(
                    fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink,
                  )),
                  Text(subtitle, style: GoogleFonts.ibmPlexSans(
                    fontSize: 11.5, color: AppColors.ash,
                  )),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: color, size: 18),
          ],
        ),
      ),
    );
  }

  /// Retirer ou Bannir un membre de la Sòl (Organisateur uniquement)
  /// - Retirer : supprime la ligne → la place est libérée, le membre peut revenir
  /// - Bannir  : met status = 'left' → bloque le rejoin via code d'invitation
  Future<void> _removeMember(String memberDocId, String memberName, String memberUserId) async {
    // Choix : Retirer temporairement ou Bannir définitivement
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.ash.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Gérer $memberName',
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink,
              ),
            ),
            Text(
              'Choisissez une action pour ce membre',
              style: GoogleFonts.ibmPlexSans(fontSize: 12.5, color: AppColors.ash),
            ),
            const SizedBox(height: 14),
            // Option 1 : Retirer (libère la place)
            GestureDetector(
              onTap: () => Navigator.of(ctx).pop('remove'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.paperDim),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_remove_outlined, color: AppColors.coral, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Retirer de la Sòl', style: GoogleFonts.ibmPlexSans(
                            fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink,
                          )),
                          Text('La place est libérée. Le membre peut rejoindre à nouveau.',
                            style: GoogleFonts.ibmPlexSans(fontSize: 11.5, color: AppColors.ash)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Option 2 : Bannir (bloque définitivement)
            GestureDetector(
              onTap: () => Navigator.of(ctx).pop('ban'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.coral.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.coral.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.block_rounded, color: AppColors.coral, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Bannir définitivement', style: GoogleFonts.ibmPlexSans(
                            fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.coral,
                          )),
                          Text('Le membre ne pourra plus rejoindre cette Sòl.',
                            style: GoogleFonts.ibmPlexSans(fontSize: 11.5, color: AppColors.ash)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('Annuler', style: GoogleFonts.ibmPlexSans(color: AppColors.ash)),
              ),
            ),
          ],
        ),
      ),
    );

    if (action == null) return;

    if (!mounted) return;
    // Confirmation selon l'action
    final isBan = action == 'ban';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.paper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isBan ? '⛔ Bannir $memberName ?' : 'Retirer $memberName ?',
          style: GoogleFonts.bricolageGrotesque(
            fontWeight: FontWeight.w700,
            color: isBan ? AppColors.coral : AppColors.ink,
          ),
        ),
        content: Text(
          isBan
              ? '$memberName ne pourra plus rejoindre cette Sòl, même avec le code d\'invitation.'
              : 'Sa place sera libérée. Il pourra rejoindre à nouveau si vous partagez le code.',
          style: GoogleFonts.ibmPlexSans(fontSize: 14, color: AppColors.ash),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Annuler', style: GoogleFonts.ibmPlexSans(color: AppColors.ash)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.coral,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(isBan ? 'Bannir' : 'Retirer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      if (isBan) {
        // Bannir : met le statut à 'left' pour bloquer le rejoin
        await Supabase.instance.client
            .from('group_members')
            .update({'status': 'left'})
            .eq('id', memberDocId);
      } else {
        // Retirer : supprime la ligne (la place est libre)
        await Supabase.instance.client
            .from('group_members')
            .delete()
            .eq('id', memberDocId);
      }

      await _loadGroupMembers();
      widget.onGroupUpdated?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isBan
                ? '$memberName a été banni de la Sòl. ⛔'
                : '$memberName a été retiré de la Sòl.'),
            backgroundColor: AppColors.coral,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: AppColors.coral,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }


  /// Supprimer définitivement la Sòl (Organisateur uniquement)
  Future<void> _deleteGroup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.paper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Supprimer cette Sòl',
          style: GoogleFonts.bricolageGrotesque(
            fontWeight: FontWeight.w700,
            color: AppColors.coral,
          ),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer définitivement "${widget.group.name}" ? Toutes les données, cotisations et invitations associées seront annulées.',
          style: GoogleFonts.ibmPlexSans(fontSize: 14, color: AppColors.ash),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Annuler', style: GoogleFonts.ibmPlexSans(color: AppColors.ash)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.coral,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await Supabase.instance.client
          .from('groups')
          .delete()
          .eq('id', widget.group.id);

      if (mounted) {
        Navigator.of(context).pop(); // Ferme le modal
        widget.onGroupUpdated?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La Sòl a été supprimée avec succès.'),
            backgroundColor: AppColors.palm,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression : $e'),
            backgroundColor: AppColors.coral,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Passer au tour suivant ou clôturer la Sòl (Organisateur uniquement)
  Future<void> _advanceTurn() async {
    final nextTurn = _currentTurn + 1;
    final isLast = nextTurn > widget.group.totalTurns;

    // ── 1. Vérifier les impayés du tour en cours ──
    final activeMembers = _membersList.where((m) {
      final status = m['status'] as String? ?? 'confirmed';
      return status != 'left';
    }).toList();

    final unpaidMembers = activeMembers.where((m) {
      final uId = m['user_id'] as String?;
      final payStatus = _turnContributions[uId]?['payment_status'];
      return payStatus != 'confirmed' && payStatus != 'late';
    }).toList();

    if (unpaidMembers.isNotEmpty) {
      // Afficher un avertissement et demander si forcer quand même
      final force = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.paper,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            '⚠️ ${unpaidMembers.length} membre(s) n\'ont pas cotisé',
            style: GoogleFonts.bricolageGrotesque(
              fontWeight: FontWeight.w700, color: AppColors.coral,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ces membres sont en attente pour le Tour $_currentTurn :',
                style: GoogleFonts.ibmPlexSans(fontSize: 13, color: AppColors.ash),
              ),
              const SizedBox(height: 8),
              ...unpaidMembers.map((m) {
                final profile = m['profiles'] as Map<String, dynamic>?;
                final name = profile?['full_name'] as String? ?? 'Membre';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, size: 6, color: AppColors.coral),
                      const SizedBox(width: 8),
                      Text(name, style: GoogleFonts.ibmPlexSans(
                        fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink,
                      )),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 10),
              Text(
                'Voulez-vous tout de même passer au tour suivant ?',
                style: GoogleFonts.ibmPlexSans(fontSize: 13, color: AppColors.ash),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('Annuler', style: GoogleFonts.ibmPlexSans(color: AppColors.ash)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.coral,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Forcer le passage'),
            ),
          ],
        ),
      );
      if (force != true) return;
    }

    // ── 2. Confirmation normale ──
    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.paper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isLast ? 'Clôturer la Sòl 🏆' : 'Passer au Tour $nextTurn',
          style: GoogleFonts.bricolageGrotesque(
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        content: Text(
          isLast
              ? 'Félicitations ! Tous les tours ont été effectués. Souhaitez-vous marquer cette Sòl comme terminée ?'
              : 'Voulez-vous clôturer le Tour $_currentTurn et distribuer la cagnotte au bénéficiaire du Tour $nextTurn ?',
          style: GoogleFonts.ibmPlexSans(fontSize: 14, color: AppColors.ash),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Annuler', style: GoogleFonts.ibmPlexSans(color: AppColors.ash)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.marigold,
              foregroundColor: AppColors.ink,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(isLast ? 'Terminer la Sòl' : 'Passer au Tour $nextTurn'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // ── 3. Enregistrer le payout du tour en cours ──
      // Trouver le bénéficiaire du tour courant (index = _currentTurn - 1)
      final beneficiaryIndex = _currentTurn - 1;
      if (beneficiaryIndex >= 0 && beneficiaryIndex < activeMembers.length) {
        final beneficiary = activeMembers[beneficiaryIndex];
        final beneficiaryUserId = beneficiary['user_id'] as String?;
        if (beneficiaryUserId != null) {
          final amountNum = double.tryParse(widget.group.contributionAmount) ?? 0.0;
          final totalPayout = amountNum * activeMembers.length;
          // Upsert du payout pour éviter les doublons si on repasse
          await Supabase.instance.client
              .from('payouts')
              .upsert({
                'group_id': widget.group.id,
                'recipient_id': beneficiaryUserId,
                'turn_number': _currentTurn,
                'total_amount': totalPayout,
                'currency': widget.group.currency,
                'status': 'paid',
                'paid_at': DateTime.now().toIso8601String(),
              },
              onConflict: 'group_id,turn_number');
        }
      }

      // ── 4. Mise à jour du groupe ──
      if (isLast) {
        await Supabase.instance.client
            .from('groups')
            .update({'status': 'completed'})
            .eq('id', widget.group.id);
      } else {
        await Supabase.instance.client
            .from('groups')
            .update({
              'current_turn': nextTurn,
              'status': 'active',
            })
            .eq('id', widget.group.id);
      }

      setState(() {
        if (!isLast) _currentTurn = nextTurn;
      });
      await _loadGroupMembers();
      widget.onGroupUpdated?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isLast
                ? 'Sòl clôturée avec succès ! 🏆'
                : 'Bienvenue au Tour $nextTurn ! 🎉'),
            backgroundColor: AppColors.palm,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: AppColors.coral,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }


  /// Relancer les membres qui n'ont pas encore cotisé pour le tour actif
  void _remindUnpaidMembers() {
    final unpaidNames = <String>[];
    for (final m in _membersList) {
      final uId = m['user_id'] as String?;
      final isPaid = _turnContributions[uId]?['payment_status'] == 'confirmed';
      if (!isPaid) {
        final profile = m['profiles'] as Map<String, dynamic>?;
        unpaidNames.add(profile?['full_name'] as String? ?? 'Membre');
      }
    }

    final message = '''
🔔 *Rappel de Cotisation — Kotizz*
Sòl : "${widget.group.name}" (Tour $_currentTurn sur ${widget.group.totalTurns})
Montant de la cotisation : ${widget.group.contributionAmount} ${widget.group.currency}

Membres en attente de cotisation :
${unpaidNames.isNotEmpty ? unpaidNames.map((n) => '• $n').join('\n') : '• Tous les membres'}

Merci de régulariser votre versement dès que possible !
Télécharger l'app : https://apps.apple.com/app/id6795205027
''';

    SharePlus.instance.share(ShareParams(text: message));
  }

  void _showInviteModal(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final code = _currentInviteCode ?? widget.group.inviteCode ?? '';
    final message = '''
${t.inviteMessageIntro} "${widget.group.name}" !

${t.inviteMessageAmountLabel} : ${widget.group.contributionAmount} ${widget.group.currency}
${t.inviteMessageFrequencyLabel} : ${widget.group.frequency}
${t.inviteMessageStartLabel} : ${widget.group.nextTurnDate}
${code.isNotEmpty ? '\n${t.inviteCode} : $code\n' : ''}
${t.inviteMessageJoinLabel} :
https://apps.apple.com/app/id6795205027
''';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.inviteSheetTitle,
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              t.inviteSheetSubtitle,
              style: GoogleFonts.ibmPlexSans(
                fontSize: 13.5,
                color: AppColors.ash,
              ),
            ),
            if (code.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.marigold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.marigold),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.inviteCode.toUpperCase(),
                          style: GoogleFonts.ibmPlexMono(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                            color: const Color(0xFFB87A1F),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          code,
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.0,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, color: AppColors.ink),
                      tooltip: t.copyCode,
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: code));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(t.codeCopied),
                              backgroundColor: AppColors.palm,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.paperDim),
              ),
              child: Text(
                message,
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 12.5,
                  color: AppColors.ink,
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => SharePlus.instance.share(ShareParams(text: message)),
                icon: const Icon(Icons.share_rounded, size: 18),
                label: Text(t.shareInvite),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.marigold,
                  foregroundColor: AppColors.ink,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: GoogleFonts.ibmPlexSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  t.later,
                  style: GoogleFonts.ibmPlexSans(color: AppColors.ash),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final totalSlots = widget.group.totalTurns > 0 ? widget.group.totalTurns : 5;

    // Calcul du nombre de cotisations confirmées pour le tour actif
    int confirmedContribsCount = 0;
    for (final m in _membersList) {
      final uId = m['user_id'] as String?;
      if (_turnContributions[uId]?['payment_status'] == 'confirmed') {
        confirmedContribsCount++;
      }
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 30),
      height: MediaQuery.of(context).size.height * 0.88,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
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
          const SizedBox(height: 14),

          // Header avec Nom, Rôle et Menu Organisateur
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: widget.group.color,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.group.name.isNotEmpty
                      ? widget.group.name.substring(0, math.min(2, widget.group.name.length)).toUpperCase()
                      : 'SO',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.group.name,
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      'Tontine de $totalSlots membres • ${widget.group.totalPot}',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 13,
                        color: AppColors.ash,
                      ),
                    ),
                  ],
                ),
              ),
              // Menu Privilèges Organisateur
              if (_isOrganizer)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: AppColors.ink),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  onSelected: (val) {
                    if (val == 'advance') _advanceTurn();
                    if (val == 'remind') _remindUnpaidMembers();
                    if (val == 'delete') _deleteGroup();
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'advance',
                      child: Row(
                        children: [
                          const Icon(Icons.fast_forward_rounded, size: 18, color: AppColors.ink),
                          const SizedBox(width: 10),
                          Text('Passer au tour ${_currentTurn + 1}'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'remind',
                      child: const Row(
                        children: [
                          Icon(Icons.notifications_active_rounded, size: 18, color: Color(0xFFB87A1F)),
                          SizedBox(width: 10),
                          Text('Relancer les impayés'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'delete',
                      child: const Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.coral),
                          SizedBox(width: 10),
                          Text('Supprimer la Sòl', style: TextStyle(color: AppColors.coral)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Suivi des cotisations du tour en cours (Qui a payé ?) ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.paperDim),
              boxShadow: [
                BoxShadow(
                  color: AppColors.ink.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: (confirmedContribsCount == _membersList.length && _membersList.isNotEmpty)
                        ? AppColors.palm.withValues(alpha: 0.15)
                        : AppColors.marigold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    (confirmedContribsCount == _membersList.length && _membersList.isNotEmpty)
                        ? Icons.verified_rounded
                        : Icons.pending_actions_rounded,
                    size: 20,
                    color: (confirmedContribsCount == _membersList.length && _membersList.isNotEmpty)
                        ? AppColors.palm
                        : const Color(0xFFB87A1F),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Cotisations Tour $_currentTurn',
                            style: GoogleFonts.bricolageGrotesque(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          if (_isOrganizer) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.ink,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'ORG',
                                style: GoogleFonts.ibmPlexMono(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$confirmedContribsCount / ${_membersList.length} membre(s) à jour',
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 12,
                          color: AppColors.ash,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isOrganizer && confirmedContribsCount < _membersList.length)
                  GestureDetector(
                    onTap: _remindUnpaidMembers,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.marigold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.send_rounded, size: 13, color: Color(0xFFB87A1F)),
                          const SizedBox(width: 4),
                          Text(
                            'Relancer',
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFB87A1F),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Payout Order Header & Invite Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                t.payoutSchedule,
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: AppColors.ash,
                ),
              ),
              GestureDetector(
                onTap: () => _showInviteModal(context),
                child: Text(
                  '+ ${t.inviteMembers}',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFB87A1F),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Member turns list
          Expanded(
            child: _isLoadingMembers
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.marigold),
                  )
                : ListView.separated(
                    itemCount: totalSlots,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final turnNumber = index + 1;
                      final isCurrent = turnNumber == _currentTurn;
                      final isPassed = turnNumber < _currentTurn;

                      // Trouver si un membre est assigné à ce tour
                      Map<String, dynamic>? memberItem;
                      if (index < _membersList.length) {
                        memberItem = _membersList[index];
                      }

                      if (memberItem != null) {
                        final profile = memberItem['profiles'] as Map<String, dynamic>?;
                        final memberName = (profile?['full_name'] as String?) ??
                            (index == 0 ? widget.group.organizer : 'Membre');
                        final memberUserId = memberItem['user_id'] as String?;
                        final isUser = memberUserId == currentUserId;
                        final isMemberOrganizer = memberUserId == widget.group.organizerId;
                        // isPaid retiré : le statut est lu dans le Builder du badge ci-dessous

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? AppColors.marigold.withValues(alpha: 0.12)
                                : AppColors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isCurrent
                                  ? AppColors.marigold
                                  : AppColors.paperDim,
                              width: isCurrent ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isPassed
                                      ? AppColors.palm
                                      : isCurrent
                                      ? AppColors.marigold
                                      : AppColors.paperDim,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '$turnNumber',
                                  style: GoogleFonts.ibmPlexMono(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isPassed || isCurrent
                                        ? AppColors.white
                                        : AppColors.ink,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          memberName,
                                          style: GoogleFonts.ibmPlexSans(
                                            fontSize: 14,
                                            fontWeight: isUser
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            color: AppColors.ink,
                                          ),
                                        ),
                                        if (isUser) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.ink,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              t.youBadge,
                                              style: GoogleFonts.ibmPlexMono(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    Text(
                                      isPassed
                                          ? t.potReceived
                                          : isCurrent
                                          ? t.currentTurnBeneficiary
                                          : t.waitingTurn,
                                      style: GoogleFonts.ibmPlexSans(
                                        fontSize: 11.5,
                                        color: isPassed
                                            ? AppColors.palm
                                            : (isCurrent
                                                  ? const Color(0xFFB87A1F)
                                                  : AppColors.ash),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // ── Badge de paiement (Cliquable par l'organisateur) ──
                              if (isCurrent && memberUserId != null) ...[
                                Builder(builder: (_) {
                                  final payStatus = _turnContributions[memberUserId]?['payment_status'] as String? ?? 'pending';
                                  final isConfirmed = payStatus == 'confirmed';
                                  final isLate = payStatus == 'late';
                                  final badgeColor = isConfirmed
                                      ? AppColors.palm
                                      : isLate
                                          ? const Color(0xFFB87A1F)
                                          : AppColors.coral;
                                  final badgeIcon = isConfirmed
                                      ? Icons.check_circle_rounded
                                      : isLate
                                          ? Icons.watch_later_rounded
                                          : Icons.pending_actions_rounded;
                                  final badgeLabel = isConfirmed
                                      ? 'Payé ✓'
                                      : isLate
                                          ? 'Tardif'
                                          : 'En attente';
                                  return GestureDetector(
                                    onTap: _isOrganizer
                                        ? () => _togglePayment(memberUserId, memberName)
                                        : null,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: badgeColor.withValues(alpha: 0.13),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: badgeColor.withValues(alpha: 0.4),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(badgeIcon, size: 13, color: badgeColor),
                                          const SizedBox(width: 4),
                                          Text(
                                            badgeLabel,
                                            style: GoogleFonts.ibmPlexMono(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700,
                                              color: badgeColor,
                                            ),
                                          ),
                                          if (_isOrganizer) ...[
                                            const SizedBox(width: 2),
                                            Icon(Icons.edit_rounded, size: 11, color: badgeColor),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                                const SizedBox(width: 8),
                              ],

                              // ── Bouton Retirer / Bannir le membre (Organisateur) ──
                              if (_isOrganizer && !isMemberOrganizer) ...[
                                IconButton(
                                  icon: const Icon(
                                    Icons.person_remove_outlined,
                                    size: 18,
                                    color: AppColors.coral,
                                  ),
                                  tooltip: 'Retirer / Bannir',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: memberUserId == null
                                      ? null
                                      : () => _removeMember(
                                          memberItem!['id'].toString(),
                                          memberName,
                                          memberUserId,
                                        ),
                                ),
                                const SizedBox(width: 8),
                              ],


                              Text(
                                '${widget.group.contributionAmount} ${widget.group.currency}',
                                style: GoogleFonts.ibmPlexMono(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ink,
                                ),
                              ),
                            ],
                          ),
                        );
                      } else {
                        // Slot libre
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.paperDim,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.paperDim,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '$turnNumber',
                                  style: GoogleFonts.ibmPlexMono(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ash,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  t.freeSlot,
                                  style: GoogleFonts.ibmPlexSans(
                                    fontSize: 13.5,
                                    color: AppColors.ash,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _showInviteModal(context),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.marigold.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '+ ${t.inviteMembers}',
                                    style: GoogleFonts.ibmPlexSans(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFB87A1F),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                  ),
          ),
          const SizedBox(height: 14),

          // --- Section WhatsApp ---
          if (widget.group.whatsappLink != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF25D366).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF25D366).withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.chat_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Groupe WhatsApp',
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        Text(
                          'Rejoignez le groupe de la tontine',
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 11.5,
                            color: AppColors.ash,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      // Bouton copier le lien
                      GestureDetector(
                        onTap: () async {
                          await Clipboard.setData(
                            ClipboardData(text: widget.group.whatsappLink!),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Lien copié !',
                                  style: GoogleFonts.ibmPlexSans(),
                                ),
                                backgroundColor: const Color(0xFF25D366),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(
                                0xFF25D366,
                              ).withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Icon(
                            Icons.copy_rounded,
                            size: 16,
                            color: Color(0xFF25D366),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Bouton ouvrir WhatsApp
                      GestureDetector(
                        onTap: () => openWhatsAppLink(widget.group.whatsappLink),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF25D366),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Rejoindre',
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Action Buttons: Clôturer/Passer au tour suivant & Inviter des membres
          if (_isOrganizer)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _advanceTurn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.palm,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.fast_forward_rounded, size: 18),
                    label: Text(
                      _currentTurn >= widget.group.totalTurns
                          ? 'Clôturer la Sòl'
                          : 'Tour ${_currentTurn + 1}',
                      style: GoogleFonts.ibmPlexSans(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showInviteModal(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.ink,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: Text(
                      t.inviteMembers,
                      style: GoogleFonts.ibmPlexSans(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showInviteModal(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ink,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.share_rounded, size: 18),
                label: Text(
                  t.inviteMembers,
                  style: GoogleFonts.ibmPlexSans(fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
