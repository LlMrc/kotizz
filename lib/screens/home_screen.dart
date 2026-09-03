import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_colors.dart';
import '../l10n/app_localizations.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _TopBar(),
            SizedBox(height: 18),
            _SummaryStatsRow(),
            SizedBox(height: 18),
            _WheelCard(),
            SizedBox(height: 22),
            _GroupsPreview(),
            SizedBox(height: 22),
            _QuickActionsSection(),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatefulWidget {
  const _TopBar();

  @override
  State<_TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<_TopBar> {
  String _displayName = 'Membre';
  String _initials = 'U';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('full_name')
          .eq('id', user.id)
          .maybeSingle();

      final fullName = (profile?['full_name'] as String?) ?? user.email?.split('@').first ?? 'Membre';
      final nameParts = fullName.trim().split(' ');
      final firstName = nameParts.first;

      String initials = 'U';
      if (nameParts.length >= 2) {
        initials = '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
      } else if (firstName.isNotEmpty) {
        initials = firstName.substring(0, firstName.length >= 2 ? 2 : 1).toUpperCase();
      }

      if (mounted) {
        setState(() {
          _displayName = firstName;
          _initials = initials;
        });
      }
    } catch (_) {}
  }

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
                  _initials,
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
                      t.greeting(_displayName),
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
                '92 ${t.trustScoreSuffix}',
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
  const _SummaryStatsRow();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _MiniStatCard(
            title: t.globalSavingsTitle,
            value: '360 000 HTG',
            sub: t.activeTontinesCount(3),
            icon: Icons.account_balance_wallet_rounded,
            iconColor: AppColors.marigold,
          ),
          const SizedBox(width: 12),
          _MiniStatCard(
            title: t.nextPotTitle,
            value: '15 000 HTG',
            sub: t.nextPotReceivedSub('15 Fév.', 'Vous'),
            icon: Icons.savings_rounded,
            iconColor: AppColors.palm,
          ),
          const SizedBox(width: 12),
          _MiniStatCard(
            title: t.trustScoreTitle,
            value: '92 / 100',
            sub: t.verifiedStatus,
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
  const _WheelCard();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
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
                        '${t.featuredTontine}: FAMILLE MONPLAISIR',
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.marigold.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        t.turnIndicator(3, 8),
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
                    const _RotationWheel(),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                            t.confirmedCount(6, 8),
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
                                '15 000',
                                style: GoogleFonts.ibmPlexMono(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.marigold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'HTG',
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

enum _NodeState { done, active, upcoming }

class _RotationWheel extends StatefulWidget {
  const _RotationWheel();

  @override
  State<_RotationWheel> createState() => _RotationWheelState();
}

class _RotationWheelState extends State<_RotationWheel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  static const _nodes = [
    (top: 0.06, left: 0.50, state: _NodeState.done, label: '1'),
    (top: 0.20, left: 0.79, state: _NodeState.done, label: '2'),
    (top: 0.50, left: 0.93, state: _NodeState.active, label: '3'),
    (top: 0.80, left: 0.79, state: _NodeState.upcoming, label: '4'),
    (top: 0.94, left: 0.50, state: _NodeState.upcoming, label: '5'),
    (top: 0.80, left: 0.21, state: _NodeState.upcoming, label: '6'),
    (top: 0.50, left: 0.07, state: _NodeState.upcoming, label: '7'),
    (top: 0.20, left: 0.21, state: _NodeState.upcoming, label: '8'),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
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
    const size = 154.0;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.14),
                width: 2,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                t.turnCounter(3, 8),
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                t.currentTurnLabel,
                style: TextStyle(
                  fontSize: 9.5,
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w600,
                  color: AppColors.marigold,
                ),
              ),
            ],
          ),
          for (final node in _nodes)
            Positioned(
              top:
                  node.top * size - (node.state == _NodeState.active ? 18 : 15),
              left:
                  node.left * size -
                  (node.state == _NodeState.active ? 18 : 15),
              child: node.state == _NodeState.active
                  ? AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final v = _pulseController.value;
                        return Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.marigold,
                            border: Border.all(color: AppColors.ink, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.marigold.withValues(alpha: 
                                  0.3 - v * 0.15,
                                ),
                                spreadRadius: 5 + v * 4,
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            node.label,
                            style: GoogleFonts.ibmPlexMono(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                        );
                      },
                    )
                  : _StaticNode(state: node.state, label: node.label),
            ),
        ],
      ),
    );
  }
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
        color: isDone ? AppColors.palm : AppColors.white.withValues(alpha: 0.14),
        border: Border.all(color: AppColors.ink, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: GoogleFonts.ibmPlexMono(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isDone ? AppColors.white : AppColors.white.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

class _GroupsPreview extends StatelessWidget {
  const _GroupsPreview();

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
        _GroupCard(
          initials: 'FM',
          color: AppColors.marigold,
          name: 'Famille Monplaisir',
          meta: '8 membres • 15 000 HTG / mois',
          label: "C'est votre tour !",
          bg: AppColors.marigold.withValues(alpha: 0.18),
          fg: const Color(0xFFB87A1F),
        ),
        const SizedBox(height: 10),
        _GroupCard(
          initials: 'CV',
          color: AppColors.palm,
          name: 'Collègues Vinpassport',
          meta: '5 membres • 100 USD / mois',
          label: t.statusUpToDate,
          bg: AppColors.palm.withValues(alpha: 0.15),
          fg: AppColors.palm,
        ),
        const SizedBox(height: 10),
        _GroupCard(
          initials: 'QT',
          color: AppColors.coral,
          name: 'Quartier Turgeau',
          meta: '12 membres • 20 000 HTG / bi-hebdo',
          label: 'Cotisation due',
          bg: AppColors.coral.withValues(alpha: 0.15),
          fg: AppColors.coral,
        ),
      ],
    );
  }
}

class _GroupCard extends StatelessWidget {
  final String initials, name, meta, label;
  final Color color, bg, fg;
  const _GroupCard({
    required this.initials,
    required this.color,
    required this.name,
    required this.meta,
    required this.label,
    required this.bg,
    required this.fg,
  });

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
              initials,
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
              child: _ActionButton(
                icon: '➕',
                iconBg: AppColors.marigold.withValues(alpha: 0.18),
                label: t.createSol,
                subLabel: 'Créer un groupe',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionButton(
                icon: '✅',
                iconBg: AppColors.palm.withValues(alpha: 0.15),
                label: t.iPaid,
                subLabel: 'Cotisation versée',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String icon, label, subLabel;
  final Color iconBg;
  const _ActionButton({
    required this.icon,
    required this.iconBg,
    required this.label,
    required this.subLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.paperDim),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.center,
            child: Text(icon, style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  subLabel,
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 11,
                    color: AppColors.ash,
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

