import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_colors.dart';
import '../l10n/app_localizations.dart';
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

      // 2. Groupes de l'utilisateur
      final groupsResponse = await Supabase.instance.client
          .from('groups')
          .select('*, profiles!organizer_id(full_name)')
          .or('organizer_id.eq.${user.id}')
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

      if (mounted) {
        setState(() {
          _displayName = firstName;
          _initials = initials;
          _trustScore = (profile?['trust_score'] as int?) ?? 50;
          _userGroups = groupsList;
          _nextPayout = nextPayout;
          _totalSavings = totalSavings;
          _currency = curr;
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
    final featuredGroup = activeGroups.isNotEmpty ? activeGroups.first : null;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadHomeData,
        color: AppColors.marigold,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
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
                onRefresh: _loadHomeData,
              ),
              const SizedBox(height: 22),
              _GroupsPreview(
                groups: activeGroups,
                onGroupCreated: _loadHomeData,
              ),
              const SizedBox(height: 22),
              const _QuickActionsSection(),
            ],
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
    final nextDate = nextPayout?['scheduled_date'] as String? ?? 'À venir';

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _MiniStatCard(
            title: t.globalSavingsTitle,
            value: '$totalSavings $currency',
            sub: t.activeTontinesCount(activeGroupsCount),
            icon: Icons.account_balance_wallet_rounded,
            iconColor: AppColors.marigold,
          ),
          const SizedBox(width: 12),
          _MiniStatCard(
            title: t.nextPotTitle,
            value: nextAmount,
            sub: nextPayout != null
                ? t.nextPotReceivedSub(nextDate, 'Vous')
                : 'Aucun pot en attente',
            icon: Icons.savings_rounded,
            iconColor: AppColors.palm,
          ),
          const SizedBox(width: 12),
          _MiniStatCard(
            title: t.trustScoreTitle,
            value: '$trustScore / 100',
            sub: trustScore >= 75 ? t.verifiedStatus : 'En cours',
            icon: Icons.verified_user_rounded,
            iconColor: AppColors.coral,
          ),
        ],
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String title, value, sub;
  final IconData icon;
  final Color iconColor;

  const _MiniStatCard({
    required this.title,
    required this.value,
    required this.sub,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 175,
      padding: const EdgeInsets.all(14),
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
  final VoidCallback onRefresh;

  const _WheelCard({
    required this.featuredGroup,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    if (featuredGroup == null) {
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${t.featuredTontine}: ${groupName.toUpperCase()}',
                        style: GoogleFonts.ibmPlexMono(
                          fontSize: 10.5,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w600,
                          color: AppColors.marigold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.marigold.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        t.turnIndicator(currentTurn, totalTurns),
                        style: GoogleFonts.ibmPlexMono(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.marigold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  t.wheelSectionLabel,
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.marigold,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              t.yourTurn.toUpperCase(),
                              style: GoogleFonts.ibmPlexMono(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            t.confirmedCount(currentTurn, totalTurns),
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 12.5,
                              color: AppColors.white.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                amount,
                                style: GoogleFonts.ibmPlexMono(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.marigold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                currency,
                                style: GoogleFonts.ibmPlexSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.white.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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

  static const _nodes = [
    (top: 0.06, left: 0.50, label: '1'),
    (top: 0.20, left: 0.79, label: '2'),
    (top: 0.50, left: 0.93, label: '3'),
    (top: 0.79, left: 0.79, label: '4'),
    (top: 0.93, left: 0.50, label: '5'),
    (top: 0.79, left: 0.21, label: '6'),
    (top: 0.50, left: 0.07, label: '7'),
    (top: 0.20, left: 0.21, label: '8'),
  ];

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
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _RingTrackPainter(),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${widget.currentTurn}/${widget.totalTurns}',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  t.currentTurnLabel,
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: AppColors.marigold,
                  ),
                ),
              ],
            ),
          ),
          for (int i = 0; i < _nodes.length; i++)
            Positioned(
              top: _nodes[i].top * 140 - 15,
              left: _nodes[i].left * 140 - 15,
              child: (i + 1 == widget.currentTurn)
                  ? AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.marigold,
                            border: Border.all(color: AppColors.ink, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.marigold.withValues(
                                  alpha: 0.4 + 0.4 * _pulseController.value,
                                ),
                                blurRadius: 8 + 6 * _pulseController.value,
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${i + 1}',
                            style: GoogleFonts.ibmPlexMono(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                        );
                      },
                    )
                  : _StaticNode(
                      state: (i + 1 < widget.currentTurn)
                          ? _NodeState.done
                          : _NodeState.upcoming,
                      label: '${i + 1}',
                    ),
            ),
        ],
      ),
    );
  }
}

class _RingTrackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.43;

    final trackPaint = Paint()
      ..color = AppColors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, radius, trackPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StaticNode extends StatelessWidget {
  final _NodeState state;
  final String label;
  const _StaticNode({required this.state, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDone = state == _NodeState.done;
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color:
            isDone ? AppColors.palm : AppColors.white.withValues(alpha: 0.14),
        border: Border.all(color: AppColors.ink, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: GoogleFonts.ibmPlexMono(
          fontSize: 11,
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
        else
          for (final g in groups.take(3)) ...[
            _GroupCard(
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
            ),
            const SizedBox(height: 10),
          ],
      ],
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

class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection();

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
              child: _ActionTile(
                icon: Icons.add_circle_outline_rounded,
                label: t.createSol,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CreateSolScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionTile(
                icon: Icons.check_circle_outline_rounded,
                label: t.iPaid,
                onTap: () {},
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

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.paperDim),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: AppColors.ink),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
