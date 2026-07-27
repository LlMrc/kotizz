import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../l10n/app_localizations.dart';

/// Seuil de largeur au-delà duquel on bascule du BottomNavigationBar
/// (mobile) vers le NavigationRail (tablette / desktop / web large).
const double kRailBreakpoint = 720;

class ResponsiveShell extends StatefulWidget {
  final List<Widget> screens;
  final VoidCallback onCreateSol;

  const ResponsiveShell({
    super.key,
    required this.screens,
    required this.onCreateSol,
  });

  @override
  State<ResponsiveShell> createState() => _ResponsiveShellState();
}

class _ResponsiveShellState extends State<ResponsiveShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final destinations = [
      (icon: Icons.grid_view_rounded, label: t.appTitle == 'Kotizz' ? 'Accueil' : 'Home'),
      (icon: Icons.groups_rounded, label: t.groupsTitle),
      (icon: Icons.notifications_rounded, label: t.alertsTitle),
      (icon: Icons.person_rounded, label: t.profileTitle),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= kRailBreakpoint;

        if (isWide) {
          // ---------- Écran large : NavigationRail à gauche ----------
          return Scaffold(
            backgroundColor: AppColors.paper,
            body: Row(
              children: [
                NavigationRail(
                  backgroundColor: AppColors.paper,
                  selectedIndex: _index,
                  onDestinationSelected: (i) => setState(() => _index = i),
                  labelType: NavigationRailLabelType.all,
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: FloatingActionButton.small(
                      backgroundColor: AppColors.marigold,
                      foregroundColor: AppColors.ink,
                      elevation: 0,
                      onPressed: widget.onCreateSol,
                      child: const Icon(Icons.add_rounded),
                    ),
                  ),
                  selectedIconTheme: const IconThemeData(color: AppColors.marigold),
                  selectedLabelTextStyle: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedIconTheme: IconThemeData(color: AppColors.ash),
                  unselectedLabelTextStyle: TextStyle(color: AppColors.ash),
                  destinations: [
                    for (final d in destinations)
                      NavigationRailDestination(
                        icon: Icon(d.icon),
                        selectedIcon: Icon(d.icon),
                        label: Text(d.label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1, color: AppColors.paperDim),
                Expanded(child: widget.screens[_index]),
              ],
            ),
          );
        }

        // ---------- Mobile : BottomNavigationBar ----------
        return Scaffold(
          backgroundColor: AppColors.paper,
          body: widget.screens[_index],
          floatingActionButton: _index == 0
              ? FloatingActionButton(
                  backgroundColor: AppColors.marigold,
                  foregroundColor: AppColors.ink,
                  elevation: 0,
                  onPressed: widget.onCreateSol,
                  child: const Icon(Icons.add_rounded),
                )
              : null,
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _index,
            onTap: (i) => setState(() => _index = i),
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppColors.paper,
            selectedItemColor: AppColors.ink,
            unselectedItemColor: AppColors.ash,
            selectedIconTheme: const IconThemeData(color: AppColors.marigold),
            showUnselectedLabels: true,
            items: [
              for (int i = 0; i < destinations.length; i++)
                BottomNavigationBarItem(
                  icon: i == 2
                      ? Badge(
                          label: const Text('3', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.white)),
                          backgroundColor: AppColors.coral,
                          child: Icon(destinations[i].icon),
                        )
                      : Icon(destinations[i].icon),
                  label: destinations[i].label,
                ),
            ],
          ),
        );
      },
    );
  }
}
