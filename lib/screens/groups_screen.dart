import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';
import '../l10n/app_localizations.dart';
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
          .select('*, profiles!organizer_id(full_name)')
          .or('organizer_id.eq.${user.id}')
          .order('created_at', ascending: false);

      final loaded = (response as List).map((map) {
        final isDraft = map['status'] == 'draft';
        final isCompleted = map['status'] == 'completed';
        final organizerName =
            map['profiles'] != null && map['profiles']['full_name'] != null
            ? map['profiles']['full_name'] as String
            : 'Organisateur';

        return _GroupData(
          id: map['id'].toString(),
          name: (map['name'] as String?) ?? 'Sòl sans nom',
          category: isDraft ? 'Brouillon' : 'Tontine collective',
          organizer: organizerName,
          contributionAmount: map['contribution_amount'].toString(),
          currency: (map['currency'] as String?) ?? 'HTG',
          frequency: (map['frequency'] as String?) == 'monthly'
              ? 'Mensuelle'
              : (map['frequency'] as String?) == 'weekly'
              ? 'Hebdomadaire'
              : 'Bi-hebdomadaire',
          totalPot: '${map['contribution_amount']} ${map['currency']}',
          currentTurn: 1,
          totalTurns: 5,
          nextTurnDate: map['start_date'] as String? ?? 'À venir',
          status: isDraft
              ? _GroupStatus.dueSoon
              : (isCompleted ? _GroupStatus.completed : _GroupStatus.upToDate),
          members: [organizerName],
          isActive: !isCompleted,
          color: isDraft ? AppColors.marigold : AppColors.palm,
          whatsappLink: map['whatsapp_link'] as String?,
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

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Add
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
                      '${_realGroups.length} tontines enregistrées',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 13,
                        color: AppColors.ash,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: _loadUserGroups,
                  icon: const Icon(Icons.refresh_rounded, color: AppColors.ink),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Filter Chips
            Row(
              children: [
                _FilterChip(
                  label: 'Toutes (${_realGroups.length})',
                  selected: _selectedFilter == 0,
                  onTap: () => setState(() => _selectedFilter = 0),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Actives ($activeCount)',
                  selected: _selectedFilter == 1,
                  onTap: () => setState(() => _selectedFilter = 1),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Terminées ($completedCount)',
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
                      'Aucune tontine trouvée',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Créez votre premier groupe SOL pour démarrer l\'épargne collective.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 12.5,
                        color: AppColors.ash,
                      ),
                    ),
                    const SizedBox(height: 16),
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
                      label: const Text('Créer ma première Sòl'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.marigold,
                        foregroundColor: AppColors.ink,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
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
    );
  }

  void _showGroupDetailModal(BuildContext context, _GroupData group) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => _GroupDetailSheet(group: group),
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

  const _GroupData({
    required this.id,
    required this.name,
    required this.category,
    required this.organizer,
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

class _GroupDetailSheet extends StatelessWidget {
  final _GroupData group;
  const _GroupDetailSheet({required this.group});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 34),
      height: MediaQuery.of(context).size.height * 0.75,
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
          const SizedBox(height: 18),

          // Header
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: group.color,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(
                  group.name.substring(0, 2).toUpperCase(),
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
                      group.name,
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      'Tontine de ${group.totalTurns} membres • ${group.totalPot}',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 13,
                        color: AppColors.ash,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Payout Order Header
          Text(
            'CALENDRIER ET ORDRE DES TOURS',
            style: GoogleFonts.ibmPlexMono(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: AppColors.ash,
            ),
          ),
          const SizedBox(height: 10),

          // Member turns list
          Expanded(
            child: ListView.separated(
              itemCount: group.members.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final turnNumber = index + 1;
                final isCurrent = turnNumber == group.currentTurn;
                final isPassed = turnNumber < group.currentTurn;
                final isUser =
                    group.members[index].contains('Vous') ||
                    group.members[index].contains('Louis M.');

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
                                  group.members[index],
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
                                      'VOUS',
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
                                  ? 'Pot perçu ✓'
                                  : isCurrent
                                  ? 'Bénéficiaire du tour actuel'
                                  : 'En attente',
                              style: GoogleFonts.ibmPlexSans(
                                fontSize: 11.5,
                                color: isPassed
                                    ? AppColors.palm
                                    : (isCurrent
                                          ? AppColors.marigold
                                          : AppColors.ash),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${group.contributionAmount} ${group.currency}',
                        style: GoogleFonts.ibmPlexMono(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          // --- Section WhatsApp ---
          if (group.whatsappLink != null) ...[
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
                            ClipboardData(text: group.whatsappLink!),
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
                        onTap: () => openWhatsAppLink(group.whatsappLink),
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

          // Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
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
                'Inviter un membre dans cette tontine',
                style: GoogleFonts.ibmPlexSans(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
