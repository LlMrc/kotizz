import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../widgets/join_group_dialog.dart';
import '../widgets/pay_contribution_modal.dart';
import 'create_sol_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  String _displayName = 'Membre';
  String _initials = 'U';
  int _trustScore = 50;
  List<Map<String, dynamic>> _userGroups = [];
  Map<String, dynamic>? _nextPayout;
  num _totalSavings = 0;
  String _currency = 'HTG';
  int _confirmedContribsCount = 0;
  bool _isUserTurn = false;
  String? _turnBeneficiaryName;
  String? _turnBeneficiaryFullName;
  Map<String, dynamic>? _currentBeneficiary;
  String? _nextBeneficiaryName;
  int? _nextBeneficiaryTurn;
  List<Map<String, dynamic>> _activeGroupMembers = [];
  bool _hasUserPaid = false;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      // 1. Profil
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('full_name, trust_score')
          .eq('id', user.id)
          .maybeSingle();

      final fullName = (profile?['full_name'] as String?) ??
          user.email?.split('@').first ??
          'Membre';
      final nameParts = fullName.trim().split(' ');
      final firstName = nameParts.first;

      String initials = 'U';
      if (nameParts.length >= 2) {
        initials = '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
      } else if (firstName.isNotEmpty) {
        initials =
            firstName.substring(0, firstName.length >= 2 ? 2 : 1).toUpperCase();
      }

      // 2. Groupes de l'utilisateur uniquement (membre ou organisateur)
      final groupsResponse = await Supabase.instance.client
          .from('groups')
          .select('*, profiles!organizer_id(full_name), group_members!inner(user_id, turn_order, status, profiles(full_name))')
          .eq('group_members.user_id', user.id)
          .order('created_at', ascending: false);

      final groupsList = (groupsResponse as List).cast<Map<String, dynamic>>();

      // 3. Prochain Payout
      final nextPayout = await Supabase.instance.client
          .from('payouts')
          .select('*, groups(name)')
          .eq('recipient_id', user.id)
          .eq('status', 'scheduled')
          .order('scheduled_date', ascending: true)
          .limit(1)
          .maybeSingle();

      num totalSavings = 0;
      String curr = 'HTG';
      for (final g in groupsList) {
        if (g['status'] != 'completed') {
          final amt = g['contribution_amount'];
          if (amt is num) totalSavings += amt;
          if (g['currency'] != null) curr = g['currency'] as String;
        }
      }

      final activeGroups =
          groupsList.where((g) => g['status'] != 'completed').toList();
      final featuredGroup = activeGroups.isNotEmpty ? activeGroups.first : null;

      int confirmedContribsCount = 0;
      bool isUserTurn = false;
      String? turnBeneficiaryName;
      String? turnBeneficiaryFullName;
      Map<String, dynamic>? currentBeneficiary;
      String? nextBeneficiaryName;
      int? nextBeneficiaryTurn;
      List<Map<String, dynamic>> activeGroupMembers = [];
      bool hasUserPaid = false;

      if (featuredGroup != null) {
        final currentTurn = (featuredGroup['current_turn'] as int?) ?? 1;
        final totalTurns = (featuredGroup['max_members'] as int?) ?? 5;
        final groupId = featuredGroup['id'];

        // Récupérer tous les membres réels du groupe avec leurs profils
        List<Map<String, dynamic>> rawMembers = [];
        try {
          final membersResponse = await Supabase.instance.client
              .from('group_members')
              .select('id, user_id, turn_order, status, profiles:user_id(id, full_name, phone, payout_method, payout_details, trust_score)')
              .eq('group_id', groupId)
              .order('turn_order', ascending: true);

          rawMembers = (membersResponse as List)
              .cast<Map<String, dynamic>>()
              .where((m) => (m['status'] as String?) != 'left')
              .toList();
        } catch (_) {}

        // Récupérer les cotisations pour le tour courant
        Map<String, Map<String, dynamic>> turnContribs = {};
        try {
          final contribsResponse = await Supabase.instance.client
              .from('contributions')
              .select()
              .eq('group_id', groupId)
              .eq('turn_number', currentTurn);

          for (final c in (contribsResponse as List)) {
            final uid = c['user_id'] as String?;
            if (uid != null) {
              turnContribs[uid] = Map<String, dynamic>.from(c);
            }
          }
        } catch (_) {}

        confirmedContribsCount = turnContribs.values
            .where((c) => c['payment_status'] == 'confirmed')
            .length;

        // Identifier le Bénéficiaire courant (turn_order == currentTurn)
        Map<String, dynamic>? currentBeneficiaryMember;
        for (final m in rawMembers) {
          if (m['turn_order'] == currentTurn) {
            currentBeneficiaryMember = m;
            break;
          }
        }
        if (currentBeneficiaryMember == null && rawMembers.isNotEmpty) {
          final idx = (currentTurn - 1).clamp(0, rawMembers.length - 1);
          currentBeneficiaryMember = rawMembers[idx];
        }

        if (currentBeneficiaryMember != null) {
          final bUserId = currentBeneficiaryMember['user_id'] as String?;
          final prof = currentBeneficiaryMember['profiles'] as Map<String, dynamic>?;
          final bFullName = (prof?['full_name'] as String?)?.trim() ?? 'Membre';
          turnBeneficiaryFullName = bFullName;
          turnBeneficiaryName = bFullName.split(' ').first;
          isUserTurn = (bUserId == user.id);

          currentBeneficiary = {
            'user_id': bUserId,
            'full_name': bFullName,
            'phone': (prof?['phone'] as String?) ?? '',
            'payout_method': (prof?['payout_method'] as String?) ?? '',
            'payout_details': (prof?['payout_details'] as String?) ?? '',
            'turn_order': currentBeneficiaryMember['turn_order'] ?? currentTurn,
          };
        }

        // Identifier le Bénéficiaire suivant
        final maxT = rawMembers.isNotEmpty
            ? rawMembers.map((m) => (m['turn_order'] as int?) ?? 1).reduce(math.max)
            : totalTurns;
        final nextTurnNum = (currentTurn >= maxT) ? 1 : (currentTurn + 1);

        Map<String, dynamic>? nextBeneficiaryMember;
        for (final m in rawMembers) {
          if (m['turn_order'] == nextTurnNum) {
            nextBeneficiaryMember = m;
            break;
          }
        }
        if (nextBeneficiaryMember == null) {
          for (final m in rawMembers) {
            if ((m['turn_order'] as int? ?? 0) > currentTurn) {
              nextBeneficiaryMember = m;
              break;
            }
          }
        }
        if (nextBeneficiaryMember == null && rawMembers.isNotEmpty) {
          nextBeneficiaryMember = rawMembers.first;
        }

        if (nextBeneficiaryMember != null) {
          final nextProf = nextBeneficiaryMember['profiles'] as Map<String, dynamic>?;
          nextBeneficiaryName = (nextProf?['full_name'] as String?)?.trim() ?? 'Membre suivant';
          nextBeneficiaryTurn = (nextBeneficiaryMember['turn_order'] as int?) ?? nextTurnNum;
        }

        // Construire la liste ordonnée des membres avec statut de paiement
        for (final m in rawMembers) {
          final uid = m['user_id'] as String?;
          final prof = m['profiles'] as Map<String, dynamic>?;
          final mTurn = (m['turn_order'] as int?) ?? 1;
          final mFullName = (prof?['full_name'] as String?)?.trim() ?? 'Membre';
          final contrib = (uid != null) ? turnContribs[uid] : null;
          final payStatus = (contrib?['payment_status'] as String?) ?? 'pending';
          final isPaid = (payStatus == 'confirmed');

          if (uid == user.id && isPaid) {
            hasUserPaid = true;
          }

          activeGroupMembers.add({
            'id': m['id'],
            'user_id': uid,
            'full_name': mFullName,
            'phone': (prof?['phone'] as String?) ?? '',
            'payout_method': (prof?['payout_method'] as String?) ?? '',
            'payout_details': (prof?['payout_details'] as String?) ?? '',
            'turn_order': mTurn,
            'is_current_beneficiary': (mTurn == currentTurn),
            'is_next_beneficiary': (nextBeneficiaryMember != null && m['id'] == nextBeneficiaryMember['id']),
            'is_current_user': (uid == user.id),
            'payment_status': payStatus,
            'is_paid': isPaid,
          });
        }
      }

      if (mounted) {
        setState(() {
          _displayName = firstName;
          _initials = initials;
          _trustScore = (profile?['trust_score'] as int?) ?? 50;
          _userGroups = groupsList;
          _nextPayout = nextPayout;
          _totalSavings = totalSavings;
          _currency = curr;
          _confirmedContribsCount = confirmedContribsCount;
          _isUserTurn = isUserTurn;
          _turnBeneficiaryName = turnBeneficiaryName;
          _turnBeneficiaryFullName = turnBeneficiaryFullName;
          _currentBeneficiary = currentBeneficiary;
          _nextBeneficiaryName = nextBeneficiaryName;
          _nextBeneficiaryTurn = nextBeneficiaryTurn;
          _activeGroupMembers = activeGroupMembers;
          _hasUserPaid = hasUserPaid;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.marigold),
      );
    }

    final activeGroups =
        _userGroups.where((g) => g['status'] != 'completed').toList();
    final completedGroups =
        _userGroups.where((g) => g['status'] == 'completed').toList();
    final featuredGroup = activeGroups.isNotEmpty ? activeGroups.first : null;
    final latestCompletedGroup = completedGroups.isNotEmpty ? completedGroups.first : null;
    final isTablet = MediaQuery.sizeOf(context).width >= 720;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadHomeData,
        color: AppColors.marigold,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            isTablet ? 32 : 20,
            16,
            isTablet ? 32 : 20,
            100,
          ),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TopBar(
                    displayName: _displayName,
                    initials: _initials,
                    trustScore: _trustScore,
                  ),
                  const SizedBox(height: 18),
                  _SummaryStatsRow(
                    totalSavings: _totalSavings,
                    currency: _currency,
                    activeGroupsCount: activeGroups.length,
                    nextPayout: _nextPayout,
                    trustScore: _trustScore,
                  ),
                  const SizedBox(height: 18),
                  _WheelCard(
                    featuredGroup: featuredGroup,
                    completedGroup: latestCompletedGroup,
                    confirmedCount: _confirmedContribsCount,
                    isUserTurn: _isUserTurn,
                    beneficiaryName: _turnBeneficiaryName,
                    beneficiaryFullName: _turnBeneficiaryFullName,
                    currentBeneficiary: _currentBeneficiary,
                    hasUserPaid: _hasUserPaid,
                    onRefresh: _loadHomeData,
                  ),
                  if (featuredGroup != null && _activeGroupMembers.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _CycleMembersStatusSection(
                      group: featuredGroup,
                      currentTurn: (featuredGroup['current_turn'] as int?) ?? 1,
                      totalTurns: (featuredGroup['max_members'] as int?) ?? 5,
                      currentBeneficiaryName: _turnBeneficiaryFullName ?? _turnBeneficiaryName ?? 'Non défini',
                      nextBeneficiaryName: _nextBeneficiaryName,
                      nextBeneficiaryTurn: _nextBeneficiaryTurn,
                      members: _activeGroupMembers,
                      hasUserPaid: _hasUserPaid,
                      currentBeneficiary: _currentBeneficiary,
                      onRefresh: _loadHomeData,
                    ),
                  ],
                  const SizedBox(height: 22),
                  _GroupsPreview(
                    groups: activeGroups,
                    onGroupCreated: _loadHomeData,
                  ),
                  const SizedBox(height: 22),
                  _QuickActionsSection(
                    onRefresh: _loadHomeData,
                    featuredGroup: featuredGroup,
                    currentBeneficiary: _currentBeneficiary,
                    hasUserPaid: _hasUserPaid,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String displayName;
  final String initials;
  final int trustScore;

  const _TopBar({
    required this.displayName,
    required this.initials,
    required this.trustScore,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.marigold,
                  border: Border.all(color: AppColors.ink, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.greeting(displayName),
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                        letterSpacing: -0.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      t.welcomeSubtitle,
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 12,
                        color: AppColors.ash,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppColors.palm,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$trustScore ${t.trustScoreSuffix}',
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryStatsRow extends StatelessWidget {
  final num totalSavings;
  final String currency;
  final int activeGroupsCount;
  final Map<String, dynamic>? nextPayout;
  final int trustScore;

  const _SummaryStatsRow({
    required this.totalSavings,
    required this.currency,
    required this.activeGroupsCount,
    required this.nextPayout,
    required this.trustScore,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final nextAmount = nextPayout?['total_amount'] != null
        ? '${nextPayout!['total_amount']} ${nextPayout!['currency'] ?? currency}'
        : '0 $currency';
    final nextDate = nextPayout?['scheduled_date'] as String? ?? t.waitingTurn;

    final isWide = MediaQuery.sizeOf(context).width >= 720;

    final cards = [
      _MiniStatCard(
        title: t.globalSavingsTitle,
        value: '$totalSavings $currency',
        sub: t.activeTontinesCount(activeGroupsCount),
        icon: Icons.account_balance_wallet_rounded,
        iconColor: AppColors.marigold,
        isFlexible: isWide,
      ),
      _MiniStatCard(
        title: t.nextPotTitle,
        value: nextAmount,
        sub: nextPayout != null
            ? t.nextPotReceivedSub(nextDate, t.youBadge)
            : t.waitingTurn,
        icon: Icons.savings_rounded,
        iconColor: AppColors.palm,
        isFlexible: isWide,
      ),
      _MiniStatCard(
        title: t.trustScoreTitle,
        value: '$trustScore / 100',
        sub: trustScore >= 75 ? t.verifiedStatus : t.statusPending,
        icon: Icons.verified_user_rounded,
        iconColor: AppColors.coral,
        isFlexible: isWide,
      ),
    ];

    if (isWide) {
      return Row(
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(width: 14),
            Expanded(child: cards[i]),
          ],
        ],
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            cards[i],
          ],
        ],
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String title, value, sub;
  final IconData icon;
  final Color iconColor;
  final bool isFlexible;

  const _MiniStatCard({
    required this.title,
    required this.value,
    required this.sub,
    required this.icon,
    required this.iconColor,
    this.isFlexible = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isFlexible ? null : 175,
      padding: EdgeInsets.all(isFlexible ? 16 : 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.paperDim),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                    color: AppColors.ash,
                  ),
                ),
              ),
              Icon(icon, size: 16, color: iconColor),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.ibmPlexMono(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: GoogleFonts.ibmPlexSans(
              fontSize: 11,
              color: AppColors.ash,
            ),
          ),
        ],
      ),
    );
  }
}

class _WheelCard extends StatelessWidget {
  final Map<String, dynamic>? featuredGroup;
  final Map<String, dynamic>? completedGroup;
  final int confirmedCount;
  final bool isUserTurn;
  final String? beneficiaryName;
  final String? beneficiaryFullName;
  final Map<String, dynamic>? currentBeneficiary;
  final bool hasUserPaid;
  final VoidCallback onRefresh;

  const _WheelCard({
    required this.featuredGroup,
    this.completedGroup,
    required this.onRefresh,
    this.confirmedCount = 0,
    this.isUserTurn = false,
    this.beneficiaryName,
    this.beneficiaryFullName,
    this.currentBeneficiary,
    this.hasUserPaid = false,
  });

  Future<void> _restartCompletedGroup(BuildContext context, Map<String, dynamic> group) async {
    final t = AppLocalizations.of(context)!;
    final groupId = group['id'];
    final groupName = group['name'] ?? 'Sòl';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.paper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          t.restartSolDialogTitle,
          style: GoogleFonts.bricolageGrotesque(
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        content: Text(
          t.restartSolDialogMessage(groupName),
          style: GoogleFonts.ibmPlexSans(fontSize: 14, color: AppColors.ash),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t.cancel, style: GoogleFonts.ibmPlexSans(color: AppColors.ash)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.palm,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(t.restartSolConfirmAction),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await Supabase.instance.client
          .from('groups')
          .update({
            'current_turn': 1,
            'status': 'active',
            'start_date': DateTime.now().toIso8601String().split('T').first,
          })
          .eq('id', groupId);

      await Supabase.instance.client
          .from('contributions')
          .delete()
          .eq('group_id', groupId);

      // Notifier les membres
      final gmList = (group['group_members'] as List?) ?? [];
      final alerts = gmList
          .where((m) => m['status'] != 'left' && m['user_id'] != null)
          .map((m) => {
                'user_id': m['user_id'],
                'group_id': groupId,
                'type': 'system',
                'title': 'Nouveau cycle démarré ! 🚀',
                'body': 'L\'organisateur a relancé un cycle pour "$groupName". Le Tour 1 est actif !',
                'is_read': false,
              })
          .toList();

      if (alerts.isNotEmpty) {
        try {
          await Supabase.instance.client.from('alerts').insert(alerts);
        } catch (_) {}
      }

      onRefresh();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.restartSolSuccess),
            backgroundColor: AppColors.palm,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
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

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    if (featuredGroup == null) {
      // Si une tontine a été complétée, afficher la célébration + option de redémarrage
      if (completedGroup != null) {
        final cName = (completedGroup!['name'] as String?) ?? 'Sòl';
        final isOrganizer = completedGroup!['organizer_id'] == currentUserId;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: 0.15),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.marigold,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      t.solCompletedBadge,
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  const Icon(Icons.check_circle_rounded, color: AppColors.palm, size: 24),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                t.rotationCompletedTitle(cName),
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                t.allMembersPaidSubtitle,
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 13,
                  color: AppColors.white.withValues(alpha: 0.72),
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (isOrganizer)
                    ElevatedButton.icon(
                      onPressed: () => _restartCompletedGroup(context, completedGroup!),
                      icon: const Icon(Icons.restart_alt_rounded, size: 18),
                      label: Text(t.restartSolButton),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.marigold,
                        foregroundColor: AppColors.ink,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CreateSolScreen()),
                      );
                      onRefresh();
                    },
                    icon: const Icon(Icons.add_rounded, size: 18, color: AppColors.white),
                    label: Text(t.createSol, style: const TextStyle(color: AppColors.white)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.paperDim),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.marigold,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    t.appTitle,
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              t.createFirstGroupPrompt,
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Créez une tontine pour activer la roue de rotation des tours.',
              style: GoogleFonts.ibmPlexSans(
                fontSize: 13,
                color: AppColors.white.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CreateSolScreen()),
                    );
                    onRefresh();
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
                OutlinedButton.icon(
                  onPressed: () => showJoinGroupDialog(context, onGroupJoined: onRefresh),
                  icon: const Icon(Icons.vpn_key_rounded, size: 16, color: AppColors.marigold),
                  label: Text(
                    t.joinWithCode,
                    style: const TextStyle(color: AppColors.white),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.marigold),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final groupName =
        (featuredGroup!['name'] as String?) ?? 'Tontine active';
    final currentTurn = (featuredGroup!['current_turn'] as int?) ?? 1;
    final totalTurns = (featuredGroup!['max_members'] as int?) ?? 5;
    final amount = featuredGroup!['contribution_amount']?.toString() ?? '0';
    final currency = (featuredGroup!['currency'] as String?) ?? 'HTG';
    final amountNum = double.tryParse(amount) ?? 0.0;
    final totalPot = '${(amountNum * totalTurns).toStringAsFixed(0)} $currency';
    final rawFreq = featuredGroup!['frequency'] as String?;
    final freq = rawFreq == 'monthly'
        ? t.freqMonthly
        : (rawFreq == 'weekly' ? t.freqWeekly : t.freqBiweekly);
    final startDate = (featuredGroup!['start_date'] as String?) ??
        (featuredGroup!['status'] == 'active' ? t.statusUpToDate : t.waitingTurn);
    final isWide = MediaQuery.sizeOf(context).width >= 720;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.15),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            top: -90,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.marigold.withValues(alpha: 0.35),
                    AppColors.marigold.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  groupName.toUpperCase(),
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 11,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white.withValues(alpha: 0.5),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  t.wheelSectionLabel,
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _RotationWheel(
                      currentTurn: currentTurn,
                      totalTurns: totalTurns,
                    ),
                    const SizedBox(width: 18),
                    Flexible(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isUserTurn
                                ? t.yourTurn
                                : (beneficiaryName != null &&
                                        beneficiaryName!.isNotEmpty
                                    ? 'Tour de $beneficiaryName'
                                    : 'Tour $currentTurn'),
                            style: GoogleFonts.bricolageGrotesque(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            t.confirmedCount(confirmedCount, totalTurns),
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 12.5,
                              color: AppColors.white.withValues(alpha: 0.65),
                            ),
                            softWrap: true,
                          ),
                          const SizedBox(height: 12),
                          _buildAmountDisplay(amount, currency),
                        ],
                      ),
                    ),
                    // Panneau enrichi pour iPad / écran large
                    if (isWide) ...[
                      Container(
                        width: 1,
                        height: 120,
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        color: AppColors.white.withValues(alpha: 0.12),
                      ),
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            Expanded(
                              child: _WheelDetailMetric(
                                title: 'POT TOTAL',
                                value: totalPot,
                                icon: Icons.savings_rounded,
                                iconColor: AppColors.palm,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _WheelDetailMetric(
                                title: 'CYCLE',
                                value: '$freq • $totalTurns pers.',
                                icon: Icons.repeat_rounded,
                                iconColor: AppColors.marigold,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _WheelDetailMetric(
                                title: 'DÉMARRAGE',
                                value: startDate,
                                icon: Icons.calendar_today_rounded,
                                iconColor: const Color(0xFF64B5F6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                // Bénéficiaire courant
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.white.withValues(alpha: 0.12)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.marigold,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.ink, width: 1.2),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.stars_rounded, color: AppColors.ink, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'BÉNÉFICIAIRE COURANT',
                              style: GoogleFonts.ibmPlexMono(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: AppColors.white.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              beneficiaryFullName ?? (beneficiaryName != null ? 'Tour de $beneficiaryName' : 'Non défini'),
                              style: GoogleFonts.bricolageGrotesque(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (isUserTurn)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.marigold,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'C\'est vous !',
                            style: GoogleFonts.ibmPlexMono(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Bouton Payer votre cotisation
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasUserPaid ? AppColors.palm : AppColors.marigold,
                      foregroundColor: hasUserPaid ? AppColors.white : AppColors.ink,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      PayContributionModal.show(
                        context,
                        group: featuredGroup!,
                        beneficiary: currentBeneficiary,
                        hasPaid: hasUserPaid,
                        onPaymentUpdated: onRefresh,
                      );
                    },
                    icon: Icon(
                      hasUserPaid ? Icons.check_circle_rounded : Icons.payments_rounded,
                      size: 19,
                    ),
                    label: Text(
                      hasUserPaid ? 'Cotisation payée ✓ (Voir infos)' : 'Payer votre cotisation',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
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

  Widget _buildAmountDisplay(String rawAmount, String currency) {
    final numVal = double.tryParse(rawAmount.replaceAll(' ', '').replaceAll(',', '')) ?? 0.0;
    final intVal = numVal.toInt();

    String topPart;
    String bottomPart;

    if (intVal >= 1000) {
      final thousands = intVal ~/ 1000;
      final remainder = intVal % 1000;
      topPart = thousands.toString();
      bottomPart = remainder.toString().padLeft(3, '0');
    } else {
      topPart = intVal.toString();
      bottomPart = '';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          topPart,
          style: GoogleFonts.ibmPlexMono(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppColors.marigold,
            height: 1.05,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            if (bottomPart.isNotEmpty) ...[
              Text(
                bottomPart,
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.marigold,
                  height: 1.05,
                ),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              currency,
              style: GoogleFonts.ibmPlexMono(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.marigold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WheelDetailMetric extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _WheelDetailMetric({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  title,
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.white.withValues(alpha: 0.6),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.ibmPlexSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

enum _NodeState { done, upcoming }

class _RotationWheel extends StatefulWidget {
  final int currentTurn;
  final int totalTurns;

  const _RotationWheel({
    this.currentTurn = 1,
    this.totalTurns = 5,
  });

  @override
  State<_RotationWheel> createState() => _RotationWheelState();
}

class _RotationWheelState extends State<_RotationWheel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  static const double _wheelSize = 154.0;
  static const double _center = _wheelSize / 2; // 77.0
  static const double _radius = 52.0;
  static const double _nodeSize = 28.0;
  static const double _haloSize = 44.0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final turnsCount = math.max(2, widget.totalTurns);
    final nodeSize = turnsCount > 8 ? 24.0 : 28.0;
    final haloSize = turnsCount > 8 ? 38.0 : 44.0;

    return SizedBox(
      width: _wheelSize,
      height: _wheelSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _RingTrackPainter(radius: _radius),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${widget.currentTurn}/${widget.totalTurns}',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  t.currentTurnLabel,
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 7.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                    color: AppColors.marigold,
                  ),
                ),
              ],
            ),
          ),
          for (int i = 0; i < turnsCount; i++)
            _buildNodePositioned(i, turnsCount, nodeSize, haloSize),
        ],
      ),
    );
  }

  Widget _buildNodePositioned(
    int i,
    int turnsCount,
    double nodeSize,
    double haloSize,
  ) {
    final nodeRadius = nodeSize / 2;
    final haloRadius = haloSize / 2;
    final angle = i * (2 * math.pi / turnsCount) - (math.pi / 2);
    final left = _center + _radius * math.cos(angle) - nodeRadius;
    final top = _center + _radius * math.sin(angle) - nodeRadius;
    final isCurrent = (i + 1 == widget.currentTurn);

    if (isCurrent) {
      final haloOffset = haloRadius - nodeRadius;
      return Positioned(
        top: top - haloOffset,
        left: left - haloOffset,
        child: SizedBox(
          width: haloSize,
          height: haloSize,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Container(
                width: haloSize,
                height: haloSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.white.withValues(alpha: 0.08),
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.18),
                    width: 1.5,
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: nodeSize,
                    height: nodeSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.marigold,
                      border: Border.all(color: AppColors.ink, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.marigold.withValues(
                            alpha: 0.4 + 0.4 * _pulseController.value,
                          ),
                          blurRadius: 6 + 4 * _pulseController.value,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${i + 1}',
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: turnsCount > 8 ? 9 : 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    }

    return Positioned(
      top: top,
      left: left,
      child: _StaticNode(
        state: (i + 1 < widget.currentTurn)
            ? _NodeState.done
            : _NodeState.upcoming,
        label: '${i + 1}',
        size: nodeSize,
      ),
    );
  }
}

class _RingTrackPainter extends CustomPainter {
  final double radius;
  const _RingTrackPainter({this.radius = 52.0});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final trackPaint = Paint()
      ..color = AppColors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, radius, trackPaint);
  }

  @override
  bool shouldRepaint(covariant _RingTrackPainter oldDelegate) =>
      oldDelegate.radius != radius;
}

class _StaticNode extends StatelessWidget {
  final _NodeState state;
  final String label;
  final double size;

  const _StaticNode({
    required this.state,
    required this.label,
    this.size = 28.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = state == _NodeState.done;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color:
            isDone ? AppColors.palm : AppColors.white.withValues(alpha: 0.14),
        border: Border.all(color: AppColors.ink, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: GoogleFonts.ibmPlexMono(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color:
              isDone ? AppColors.white : AppColors.white.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

class _GroupsPreview extends StatelessWidget {
  final List<Map<String, dynamic>> groups;
  final VoidCallback onGroupCreated;

  const _GroupsPreview({
    required this.groups,
    required this.onGroupCreated,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isWide = MediaQuery.sizeOf(context).width >= 720;
    final displayGroups = groups.take(isWide ? 4 : 3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              t.activeGroups,
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            Text(
              t.seeAll,
              style: GoogleFonts.ibmPlexSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.ash,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (groups.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.paperDim),
            ),
            child: Column(
              children: [
                const Icon(Icons.groups_outlined,
                    size: 36, color: AppColors.ash),
                const SizedBox(height: 8),
                Text(
                  t.noGroupsFound,
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  t.createFirstGroupPrompt,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 12,
                    color: AppColors.ash,
                  ),
                ),
              ],
            ),
          )
        else if (isWide) ...[
          for (int i = 0; i < displayGroups.length; i += 2) ...[
            Row(
              children: [
                Expanded(
                  child: _buildGroupCard(displayGroups[i], t),
                ),
                const SizedBox(width: 14),
                if (i + 1 < displayGroups.length)
                  Expanded(
                    child: _buildGroupCard(displayGroups[i + 1], t),
                  )
                else
                  const Expanded(child: SizedBox.shrink()),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ] else
          for (final g in displayGroups) ...[
            _buildGroupCard(g, t),
            const SizedBox(height: 10),
          ],
      ],
    );
  }

  Widget _buildGroupCard(Map<String, dynamic> g, AppLocalizations t) {
    return _GroupCard(
      name: (g['name'] as String?) ?? 'Sòl',
      meta:
          '${g['max_members'] ?? 5} membres • ${g['contribution_amount']} ${g['currency'] ?? 'HTG'}',
      label: g['status'] == 'active'
          ? t.statusUpToDate
          : (g['status'] == 'draft'
              ? t.statusPending
              : t.statusDispute),
      color: g['status'] == 'active'
          ? AppColors.palm
          : AppColors.marigold,
      bg: g['status'] == 'active'
          ? AppColors.palm.withValues(alpha: 0.15)
          : AppColors.marigold.withValues(alpha: 0.18),
      fg: g['status'] == 'active'
          ? AppColors.palm
          : const Color(0xFFB87A1F),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final String name, meta, label;
  final Color color, bg, fg;

  const _GroupCard({
    required this.name,
    required this.meta,
    required this.label,
    required this.color,
    required this.bg,
    required this.fg,
  });

  String get _initials {
    if (name.trim().isEmpty) return 'S';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.paperDim),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(13),
            ),
            alignment: Alignment.center,
            child: Text(
              _initials,
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  meta,
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 12,
                    color: AppColors.ash,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              style: GoogleFonts.ibmPlexMono(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CycleMembersStatusSection extends StatelessWidget {
  final Map<String, dynamic> group;
  final int currentTurn;
  final int totalTurns;
  final String currentBeneficiaryName;
  final String? nextBeneficiaryName;
  final int? nextBeneficiaryTurn;
  final List<Map<String, dynamic>> members;
  final bool hasUserPaid;
  final Map<String, dynamic>? currentBeneficiary;
  final VoidCallback onRefresh;

  const _CycleMembersStatusSection({
    required this.group,
    required this.currentTurn,
    required this.totalTurns,
    required this.currentBeneficiaryName,
    required this.nextBeneficiaryName,
    required this.nextBeneficiaryTurn,
    required this.members,
    required this.hasUserPaid,
    required this.currentBeneficiary,
    required this.onRefresh,
  });

  Future<void> _togglePaymentStatus(BuildContext context, Map<String, dynamic> member) async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final organizerId = group['organizer_id'] as String?;
    final isOrganizer = (currentUserId != null && organizerId == currentUserId);

    // Si ce n'est pas l'organisateur, il ne peut pas modifier le statut
    if (!isOrganizer) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seul l\'organisateur de la tontine peut valider et confirmer les paiements.'),
          backgroundColor: AppColors.ink,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final memberUserId = member['user_id'] as String?;
    final memberName = (member['full_name'] as String?) ?? 'Membre';
    if (memberUserId == null) return;

    final bool isCurrentlyPaid = member['is_paid'] == true;

    // Dialogue de validation pour l'organisateur
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
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.ash.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Validation cotisation — $memberName',
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Tour $currentTurn • ${group['contribution_amount']} ${group['currency'] ?? 'HTG'}',
              style: GoogleFonts.ibmPlexSans(fontSize: 13, color: AppColors.ash),
            ),
            const SizedBox(height: 18),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: isCurrentlyPaid ? AppColors.palm : AppColors.paperDim,
                  width: isCurrentlyPaid ? 1.5 : 1,
                ),
              ),
              tileColor: AppColors.white,
              leading: const Icon(Icons.check_circle_rounded, color: AppColors.palm, size: 24),
              title: Text(
                'Confirmer le paiement (Payé)',
                style: GoogleFonts.ibmPlexSans(fontWeight: FontWeight.w700, color: AppColors.ink),
              ),
              subtitle: Text(
                'Valider la réception de la cotisation pour ce tour',
                style: GoogleFonts.ibmPlexSans(fontSize: 12, color: AppColors.ash),
              ),
              trailing: isCurrentlyPaid
                  ? const Icon(Icons.check_rounded, color: AppColors.palm)
                  : null,
              onTap: () => Navigator.of(ctx).pop('confirmed'),
            ),
            const SizedBox(height: 10),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: !isCurrentlyPaid ? const Color(0xFFE65100) : AppColors.paperDim,
                  width: !isCurrentlyPaid ? 1.5 : 1,
                ),
              ),
              tileColor: AppColors.white,
              leading: const Icon(Icons.hourglass_top_rounded, color: Color(0xFFE65100), size: 24),
              title: Text(
                'Marquer comme Non payé',
                style: GoogleFonts.ibmPlexSans(fontWeight: FontWeight.w700, color: AppColors.ink),
              ),
              subtitle: Text(
                'Cotisation en attente de versement',
                style: GoogleFonts.ibmPlexSans(fontSize: 12, color: AppColors.ash),
              ),
              trailing: !isCurrentlyPaid
                  ? const Icon(Icons.check_rounded, color: Color(0xFFE65100))
                  : null,
              onTap: () => Navigator.of(ctx).pop('pending'),
            ),
          ],
        ),
      ),
    );

    if (chosen == null || (chosen == 'confirmed' && isCurrentlyPaid) || (chosen == 'pending' && !isCurrentlyPaid)) {
      return;
    }

    try {
      final groupId = group['id'] as String;
      final rawAmt = group['contribution_amount'];
      final amountNum = double.tryParse(rawAmt?.toString() ?? '0') ?? 0.0;
      final currency = (group['currency'] as String?) ?? 'HTG';
      final groupName = (group['name'] as String?) ?? 'Tontine';

      // Vérifier si un enregistrement existe déjà dans contributions
      final existing = await Supabase.instance.client
          .from('contributions')
          .select('id')
          .eq('group_id', groupId)
          .eq('user_id', memberUserId)
          .eq('turn_number', currentTurn)
          .maybeSingle();

      if (existing != null) {
        await Supabase.instance.client
            .from('contributions')
            .update({
              'payment_status': chosen,
              'paid_at': chosen == 'confirmed' ? DateTime.now().toIso8601String() : null,
            })
            .eq('id', existing['id']);
      } else {
        await Supabase.instance.client
            .from('contributions')
            .insert({
              'group_id': groupId,
              'user_id': memberUserId,
              'turn_number': currentTurn,
              'amount': amountNum,
              'currency': currency,
              'payment_status': chosen,
              'paid_at': chosen == 'confirmed' ? DateTime.now().toIso8601String() : null,
            });
      }

      // Si confirmé, notifier le membre
      if (chosen == 'confirmed') {
        try {
          await Supabase.instance.client.from('alerts').insert({
            'user_id': memberUserId,
            'group_id': groupId,
            'type': 'payment',
            'title': 'Cotisation confirmée ! 🟢',
            'body': 'L\'organisateur a confirmé que vous avez payé votre cotisation pour le Tour $currentTurn de "$groupName".',
            'is_read': false,
          });
        } catch (_) {}
      }

      onRefresh();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(chosen == 'confirmed'
                ? 'Paiement de $memberName confirmé (Payé) 🟢'
                : 'Statut de $memberName remis à Non payé ⏳'),
            backgroundColor: chosen == 'confirmed' ? AppColors.palm : AppColors.ink,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
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

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final organizerId = group['organizer_id'] as String?;
    final isOrganizer = (currentUserId != null && organizerId == currentUserId);

    final paidCount = members.where((m) => m['is_paid'] == true).length;
    final totalCount = members.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Carte Bénéficiaire Suivant
        if (nextBeneficiaryName != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.paperDim),
              boxShadow: [
                BoxShadow(
                  color: AppColors.ink.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.marigold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.skip_next_rounded,
                    color: Color(0xFFB87A1F),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'BÉNÉFICIAIRE SUIVANT',
                            style: GoogleFonts.ibmPlexMono(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: AppColors.ash,
                            ),
                          ),
                          if (nextBeneficiaryTurn != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: AppColors.ink.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Tour $nextBeneficiaryTurn',
                                style: GoogleFonts.ibmPlexMono(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        nextBeneficiaryName!,
                        style: GoogleFonts.bricolageGrotesque(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.ash),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Liste des membres avec statuts de paiement
        Container(
          width: double.infinity,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Statut des cotisations',
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isOrganizer
                              ? 'Tour $currentTurn • $paidCount/$totalCount payés (Touchez pour valider)'
                              : 'Tour $currentTurn sur $totalTurns • $paidCount/$totalCount payés',
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 12,
                            color: isOrganizer ? const Color(0xFFB87A1F) : AppColors.ash,
                            fontWeight: isOrganizer ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: (paidCount == totalCount && totalCount > 0)
                          ? AppColors.palm.withValues(alpha: 0.15)
                          : AppColors.marigold.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$paidCount/$totalCount payés',
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: (paidCount == totalCount && totalCount > 0)
                            ? AppColors.palm
                            : const Color(0xFFB87A1F),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Barre de progression
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: totalCount > 0 ? (paidCount / totalCount) : 0,
                  minHeight: 6,
                  backgroundColor: AppColors.paperDim,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    paidCount == totalCount ? AppColors.palm : AppColors.marigold,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: AppColors.paperDim),
              const SizedBox(height: 8),

              // Membres de la tontine
              for (int i = 0; i < members.length; i++) ...[
                if (i > 0) const Divider(height: 14, color: AppColors.paperDim),
                _MemberStatusTile(
                  member: members[i],
                  currentTurn: currentTurn,
                  isOrganizer: isOrganizer,
                  onToggleStatus: isOrganizer
                      ? () => _togglePaymentStatus(context, members[i])
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Seul l\'organisateur peut confirmer qu\'une personne a payé.'),
                              backgroundColor: AppColors.ink,
                              behavior: SnackBarBehavior.floating,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                  onViewBeneficiary: members[i]['is_current_beneficiary'] == true
                      ? () => PayContributionModal.show(
                            context,
                            group: group,
                            beneficiary: currentBeneficiary,
                            hasPaid: hasUserPaid,
                            onPaymentUpdated: onRefresh,
                          )
                      : null,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MemberStatusTile extends StatelessWidget {
  final Map<String, dynamic> member;
  final int currentTurn;
  final bool isOrganizer;
  final VoidCallback onToggleStatus;
  final VoidCallback? onViewBeneficiary;

  const _MemberStatusTile({
    required this.member,
    required this.currentTurn,
    required this.isOrganizer,
    required this.onToggleStatus,
    this.onViewBeneficiary,
  });

  String get _initials {
    final name = (member['full_name'] as String?)?.trim() ?? 'M';
    if (name.isEmpty) return 'M';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final fullName = (member['full_name'] as String?) ?? 'Membre';
    final turnOrder = (member['turn_order'] as int?) ?? 1;
    final isBeneficiary = member['is_current_beneficiary'] == true;
    final isCurrentUser = member['is_current_user'] == true;
    final isPaid = member['is_paid'] == true;

    return InkWell(
      onTap: isOrganizer ? onToggleStatus : (isBeneficiary ? onViewBeneficiary : onToggleStatus),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isBeneficiary
                    ? AppColors.marigold
                    : (isPaid ? AppColors.palm.withValues(alpha: 0.15) : AppColors.paperDim),
                border: Border.all(
                  color: isBeneficiary ? AppColors.ink : Colors.transparent,
                  width: 1.2,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                _initials,
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isBeneficiary
                      ? AppColors.ink
                      : (isPaid ? AppColors.palm : AppColors.ash),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Nom et tags
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          fullName,
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCurrentUser) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.ink,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Vous',
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
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        'Tour $turnOrder',
                        style: GoogleFonts.ibmPlexMono(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.ash,
                        ),
                      ),
                      if (isBeneficiary) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.marigold.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '👑 Bénéficiaire',
                            style: GoogleFonts.ibmPlexMono(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF8A5A0A),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Badge Statut interactif : [Payé] ou [Non payé]
            GestureDetector(
              onTap: onToggleStatus,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isPaid
                      ? AppColors.palm.withValues(alpha: 0.12)
                      : const Color(0xFFE65100).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isPaid
                        ? AppColors.palm.withValues(alpha: 0.3)
                        : const Color(0xFFE65100).withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPaid ? Icons.check_circle_rounded : Icons.schedule_rounded,
                      size: 13,
                      color: isPaid ? AppColors.palm : const Color(0xFFE65100),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isPaid ? 'Payé' : 'Non payé',
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: isPaid ? AppColors.palm : const Color(0xFFE65100),
                      ),
                    ),
                    if (isOrganizer) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.edit_rounded,
                        size: 11,
                        color: isPaid ? AppColors.palm : const Color(0xFFE65100),
                      ),
                    ],
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

class _QuickActionsSection extends StatelessWidget {
  final VoidCallback onRefresh;
  final Map<String, dynamic>? featuredGroup;
  final Map<String, dynamic>? currentBeneficiary;
  final bool hasUserPaid;

  const _QuickActionsSection({
    required this.onRefresh,
    this.featuredGroup,
    this.currentBeneficiary,
    this.hasUserPaid = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.quickActions,
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 5,
              child: _ActionTile(
                icon: Icons.vpn_key_rounded,
                iconColor: const Color(0xFFB87A1F),
                bgColor: AppColors.marigold.withValues(alpha: 0.15),
                borderColor: AppColors.marigold.withValues(alpha: 0.6),
                label: t.joinSol,
                tag: 'CODE',
                onTap: () => showJoinGroupDialog(context, onGroupJoined: onRefresh),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 4,
              child: _ActionTile(
                icon: Icons.add_circle_outline_rounded,
                label: t.createSol,
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CreateSolScreen(),
                    ),
                  );
                  onRefresh();
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 4,
              child: _ActionTile(
                icon: Icons.payments_rounded,
                iconColor: hasUserPaid ? AppColors.palm : AppColors.marigold,
                label: hasUserPaid ? 'Payé ✓' : 'Payer sòl',
                onTap: () {
                  if (featuredGroup != null) {
                    PayContributionModal.show(
                      context,
                      group: featuredGroup!,
                      beneficiary: currentBeneficiary,
                      hasPaid: hasUserPaid,
                      onPaymentUpdated: onRefresh,
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Aucune tontine active pour le moment.'),
                        backgroundColor: AppColors.ink,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? bgColor;
  final Color? borderColor;
  final String? tag;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.bgColor,
    this.borderColor,
    this.tag,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: bgColor ?? AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor ?? AppColors.paperDim),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 22, color: iconColor ?? AppColors.ink),
                if (tag != null)
                  Positioned(
                    top: -6,
                    right: -14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: AppColors.marigold,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tag!,
                        style: GoogleFonts.ibmPlexMono(
                          fontSize: 7.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.ibmPlexSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
