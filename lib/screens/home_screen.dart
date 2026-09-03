import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../widgets/join_group_dialog.dart';
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
              _QuickActionsSection(onRefresh: _loadHomeData),
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
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.marigold,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              t.yourTurn.toUpperCase(),
                              style: GoogleFonts.ibmPlexMono(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            t.confirmedCount(currentTurn, totalTurns),
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 12,
                              color: AppColors.white.withValues(alpha: 0.7),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  amount,
                                  style: GoogleFonts.ibmPlexMono(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.marigold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  currency,
                                  style: GoogleFonts.ibmPlexSans(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.white.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
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

  static const double _wheelSize = 125.0;
  static const double _center = _wheelSize / 2; // 62.5
  static const double _radius = 46.0;
  static const double _nodeSize = 24.0;
  static const double _nodeRadius = _nodeSize / 2; // 12.0

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
          for (int i = 0; i < 8; i++)
            _buildNodePositioned(i),
        ],
      ),
    );
  }

  Widget _buildNodePositioned(int i) {
    final angle = i * (2 * math.pi / 8) - (math.pi / 2);
    final left = _center + _radius * math.cos(angle) - _nodeRadius;
    final top = _center + _radius * math.sin(angle) - _nodeRadius;

    return Positioned(
      top: top,
      left: left,
      child: (i + 1 == widget.currentTurn)
          ? AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: _nodeSize,
                  height: _nodeSize,
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
                      fontSize: 10,
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
              size: _nodeSize,
            ),
    );
  }
}

class _RingTrackPainter extends CustomPainter {
  final double radius;
  const _RingTrackPainter({this.radius = 46.0});

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
    this.size = 24.0,
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
  final VoidCallback onRefresh;
  const _QuickActionsSection({required this.onRefresh});

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
