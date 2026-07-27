import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../l10n/app_localizations.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  int _selectedFilter = 0; // 0: Toutes, 1: Actives, 2: Terminées

  static const _groups = [
    _GroupData(
      id: '1',
      name: 'Famille Monplaisir',
      category: 'Famille & Proches',
      organizer: 'Louis Monplaisir (Vous)',
      contributionAmount: '15 000',
      currency: 'HTG',
      frequency: 'Mensuelle',
      totalPot: '120 000 HTG',
      currentTurn: 3,
      totalTurns: 8,
      nextTurnDate: '15 Fév 2026',
      status: _GroupStatus.yourTurn,
      members: ['Louis M.', 'Marie P.', 'David P.', 'Jean S.', 'Sophie J.', 'Alex R.', 'Katia B.', 'Claude L.'],
      isActive: true,
      color: AppColors.marigold,
    ),
    _GroupData(
      id: '2',
      name: 'Collègues Vinpassport',
      category: 'Entreprise & Pro',
      organizer: 'Marie Duplan',
      contributionAmount: '100',
      currency: 'USD',
      frequency: 'Mensuelle',
      totalPot: '500 USD',
      currentTurn: 2,
      totalTurns: 5,
      nextTurnDate: '01 Mar 2026',
      status: _GroupStatus.upToDate,
      members: ['Marie D.', 'Louis M.', 'Patrick L.', 'Fabienne B.', 'Emmanuel R.'],
      isActive: true,
      color: AppColors.palm,
    ),
    _GroupData(
      id: '3',
      name: 'Quartier Turgeau',
      category: 'Communauté',
      organizer: 'Jean-Baptiste Pierre',
      contributionAmount: '20 000',
      currency: 'HTG',
      frequency: 'Bi-hebdomadaire',
      totalPot: '240 000 HTG',
      currentTurn: 7,
      totalTurns: 12,
      nextTurnDate: '10 Fév 2026',
      status: _GroupStatus.dueSoon,
      members: ['Jean-B. P.', 'Louis M.', 'Roseline K.', 'Marc A.', 'Nathalie V.', 'Joseph T.', 'Luce B.', 'Wilfrid D.', 'Carole H.', 'Gérard M.', 'Fritz L.', 'Evelyne C.'],
      isActive: true,
      color: AppColors.coral,
    ),
    _GroupData(
      id: '4',
      name: 'Épargne Projets 2025',
      category: 'Investissement',
      organizer: 'Louis Monplaisir (Vous)',
      contributionAmount: '10 000',
      currency: 'HTG',
      frequency: 'Mensuelle',
      totalPot: '60 000 HTG',
      currentTurn: 6,
      totalTurns: 6,
      nextTurnDate: 'Terminé',
      status: _GroupStatus.completed,
      members: ['Louis M.', 'Serge B.', 'Daphnée G.', 'Junior P.', 'Yolande F.', 'Hervé D.'],
      isActive: false,
      color: AppColors.ink,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final filteredGroups = _groups.where((g) {
      if (_selectedFilter == 1) return g.isActive;
      if (_selectedFilter == 2) return !g.isActive;
      return true;
    }).toList();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Search
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
                      '4 tontines • 420 000 HTG circulés',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 13,
                        color: AppColors.ash,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.paperDim),
                  ),
                  child: const Icon(Icons.search_rounded, color: AppColors.ink, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Summary Savings Header Card
            const _SavingsSummaryCard(),
            const SizedBox(height: 20),

            // Filter Chips
            Row(
              children: [
                _FilterChip(
                  label: 'Toutes (4)',
                  selected: _selectedFilter == 0,
                  onTap: () => setState(() => _selectedFilter = 0),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Actives (3)',
                  selected: _selectedFilter == 1,
                  onTap: () => setState(() => _selectedFilter = 1),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Terminées (1)',
                  selected: _selectedFilter == 2,
                  onTap: () => setState(() => _selectedFilter = 2),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Group List
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

class _SavingsSummaryCard extends StatelessWidget {
  const _SavingsSummaryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.paperDim),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.marigold.withOpacity(0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.marigold, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ÉPARGNE GLOBALE EN COURS',
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: AppColors.ash,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '360 000',
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'HTG',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ash,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.palm.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.arrow_upward_rounded, color: AppColors.palm, size: 14),
                const SizedBox(width: 2),
                Text(
                  '+15% ce mois',
                  style: GoogleFonts.ibmPlexSans(
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

enum _GroupStatus { yourTurn, upToDate, dueSoon, completed }

class _GroupData {
  final String id, name, category, organizer, contributionAmount, currency, frequency, totalPot, nextTurnDate;
  final int currentTurn, totalTurns;
  final _GroupStatus status;
  final List<String> members;
  final bool isActive;
  final Color color;

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
              color: AppColors.ink.withOpacity(0.03),
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: group.color.withOpacity(0.12),
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
                        style: GoogleFonts.ibmPlexSans(fontSize: 11, color: AppColors.ash),
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
                        style: GoogleFonts.ibmPlexSans(fontSize: 11, color: AppColors.ash),
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
                  group.status == _GroupStatus.yourTurn ? AppColors.marigold : group.color,
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
                    Text(
                      'Détails',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.ink),
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
        bg = AppColors.marigold.withOpacity(0.2);
        fg = const Color(0xFFB87A1F);
        break;
      case _GroupStatus.upToDate:
        label = 'À jour';
        bg = AppColors.palm.withOpacity(0.15);
        fg = AppColors.palm;
        break;
      case _GroupStatus.dueSoon:
        label = 'Cotisation due';
        bg = AppColors.coral.withOpacity(0.15);
        fg = AppColors.coral;
        break;
      case _GroupStatus.completed:
        label = 'Terminé 🏆';
        bg = AppColors.ash.withOpacity(0.15);
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
                color: AppColors.ash.withOpacity(0.3),
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
                final isUser = group.members[index].contains('Vous') || group.members[index].contains('Louis M.');

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isCurrent ? AppColors.marigold.withOpacity(0.12) : AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isCurrent ? AppColors.marigold : AppColors.paperDim,
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
                            color: isPassed || isCurrent ? AppColors.white : AppColors.ink,
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
                                    fontWeight: isUser ? FontWeight.w700 : FontWeight.w500,
                                    color: AppColors.ink,
                                  ),
                                ),
                                if (isUser) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                                color: isPassed ? AppColors.palm : (isCurrent ? AppColors.marigold : AppColors.ash),
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
