import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          t.greeting('Louis'),
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
            letterSpacing: -0.3,
          ),
        ),
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

class _WheelCard extends StatelessWidget {
  const _WheelCard();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 22),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(28),
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
                      AppColors.marigold.withOpacity(0.35),
                      AppColors.marigold.withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.wheelGroupExample.toUpperCase(),
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 11,
                    letterSpacing: 1.1,
                    color: AppColors.white.withOpacity(0.55),
                  ),
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
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.yourTurn,
                            style: GoogleFonts.bricolageGrotesque(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: AppColors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            t.confirmedCount(6, 8),
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 12.5,
                              color: AppColors.white.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '15 000',
                                style: GoogleFonts.ibmPlexMono(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.marigold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'HTG',
                                style: GoogleFonts.ibmPlexSans(
                                  fontSize: 11,
                                  color: AppColors.white.withOpacity(0.55),
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
    const size = 164.0;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.white.withOpacity(0.12),
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
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                t.currentTurnLabel,
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 0.6,
                  color: AppColors.white.withOpacity(0.55),
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
                                color: AppColors.marigold.withOpacity(
                                  0.22 - v * 0.12,
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
                              fontWeight: FontWeight.w600,
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
        color: isDone ? AppColors.palm : AppColors.white.withOpacity(0.14),
        border: Border.all(color: AppColors.ink, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: GoogleFonts.ibmPlexMono(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isDone ? AppColors.white : AppColors.white.withOpacity(0.6),
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
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            Text(
              t.seeAll,
              style: GoogleFonts.ibmPlexSans(
                fontSize: 12,
                color: AppColors.ash,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _GroupCard(
          initials: 'FM',
          color: AppColors.marigold,
          name: t.wheelGroupExample,
          meta: '8 · 4j',
          label: t.statusPending,
          bg: AppColors.marigold.withOpacity(0.16),
          fg: const Color(0xFFB87A1F),
        ),
        const SizedBox(height: 10),
        _GroupCard(
          initials: 'CV',
          color: AppColors.palm,
          name: 'Collègues Vinpassport',
          meta: '5',
          label: t.statusUpToDate,
          bg: AppColors.palm.withOpacity(0.12),
          fg: AppColors.palm,
        ),
        const SizedBox(height: 10),
        _GroupCard(
          initials: 'QT',
          color: AppColors.coral,
          name: 'Quartier Turgeau',
          meta: '12',
          label: t.statusDispute,
          bg: AppColors.coral.withOpacity(0.13),
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
            fontSize: 16,
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
                iconBg: AppColors.marigold.withOpacity(0.18),
                label: t.createSol,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionButton(
                icon: '✅',
                iconBg: AppColors.palm.withOpacity(0.15),
                label: t.iPaid,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String icon, label;
  final Color iconBg;
  const _ActionButton({
    required this.icon,
    required this.iconBg,
    required this.label,
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
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: Text(icon, style: const TextStyle(fontSize: 15)),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.ibmPlexSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
