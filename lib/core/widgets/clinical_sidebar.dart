/// Navigation latérale flottante Nocturne Clinique (tablette et desktop).
///
/// Le NavigationRail reste présent pour les sémantiques et les tests existants.
/// AnimatedSize anime la largeur du panneau sans contraindre le rail
/// à une largeur intermédiaire susceptible de produire un RenderFlex overflow.
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app/theme.dart';

class ClinicalSidebar extends StatelessWidget {
  const ClinicalSidebar({
    super.key,
    required this.selectedIndex,
    required this.expanded,
    required this.onSelected,
    required this.onToggle,
    required this.onSettings,
  });

  final int selectedIndex;
  final bool expanded;
  final ValueChanged<int> onSelected;
  final VoidCallback onToggle;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final isIos = Theme.of(context).platform == TargetPlatform.iOS;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final panelWidth = expanded ? 256.0 : 72.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
      child: AnimatedSize(
        duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        alignment: Alignment.centerLeft,
        clipBehavior: Clip.hardEdge,
        child: Container(
          width: panelWidth,
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: palette.border),
            boxShadow: [
              BoxShadow(
                color: palette.night.withValues(
                  alpha: palette.isDark ? 0.24 : 0.08,
                ),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(21),
            child: Column(
              children: [
                SizedBox(
                  height: 84,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: expanded ? 15 : 12,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: palette.tealSoft,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.medical_services_outlined,
                            size: 23,
                            color: palette.forest,
                          ),
                        ),
                        if (expanded) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('MediSuivi',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 16,
                                    height: 1.25,
                                    fontWeight: FontWeight.w700,
                                    color: palette.ink,
                                  ),
                                ),
                                Text('Espace clinique',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: palette.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Divider(height: 1, color: palette.border),
                Expanded(
                  child: NavigationRail(
                    selectedIndex: selectedIndex,
                    onDestinationSelected: onSelected,
                    extended: expanded,
                    scrollable: true,
                    minWidth: 70,
                    minExtendedWidth: 248,
                    backgroundColor: palette.surface,
                    indicatorColor: palette.tealSoft,
                    selectedIconTheme: IconThemeData(
                      color: palette.forest, size: 23),
                    unselectedIconTheme: IconThemeData(
                      color: palette.muted, size: 23),
                    selectedLabelTextStyle: TextStyle(
                      color: palette.ink,
                      fontSize: expanded ? 14 : 12,
                      fontWeight: FontWeight.w700,
                    ),
                    unselectedLabelTextStyle: TextStyle(
                      color: palette.muted,
                      fontSize: expanded ? 14 : 12,
                      fontWeight: FontWeight.w500,
                    ),
                    labelType: expanded
                        ? NavigationRailLabelType.none
                        : NavigationRailLabelType.all,
                    destinations: [
                      NavigationRailDestination(
                        icon: Tooltip(
                          message: 'Accueil',
                          child: Icon(isIos
                            ? CupertinoIcons.house
                            : Icons.home_outlined),
                        ),
                        selectedIcon: Icon(isIos
                          ? CupertinoIcons.house_fill
                          : Icons.home_rounded),
                        label: const Text('Accueil'),
                      ),
                      NavigationRailDestination(
                        icon: Tooltip(
                          message: 'Patients',
                          child: Icon(isIos
                            ? CupertinoIcons.person_2
                            : Icons.people_outline_rounded),
                        ),
                        selectedIcon: Icon(isIos
                          ? CupertinoIcons.person_2_fill
                          : Icons.people_rounded),
                        label: const Text('Patients'),
                      ),
                      NavigationRailDestination(
                        icon: Tooltip(
                          message: 'Bilans',
                          child: Icon(isIos
                            ? CupertinoIcons.doc_text
                            : Icons.biotech_outlined),
                        ),
                        selectedIcon: Icon(isIos
                          ? CupertinoIcons.doc_text_fill
                          : Icons.biotech_rounded),
                        label: const Text('Bilans'),
                      ),
                      NavigationRailDestination(
                        icon: Tooltip(
                          message: 'Suivi',
                          child: Icon(isIos
                            ? CupertinoIcons.chart_bar
                            : Icons.insights_outlined),
                        ),
                        selectedIcon: Icon(isIos
                          ? CupertinoIcons.chart_bar_fill
                          : Icons.insights_rounded),
                        label: const Text('Suivi'),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: palette.border),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: expanded ? 12 : 10,
                    vertical: 10,
                  ),
                  child: Column(
                    children: [
                      _SidebarAction(
                        icon: Icons.settings_outlined,
                        label: 'Paramètres',
                        expanded: expanded,
                        onPressed: onSettings,
                        color: palette.ink,
                      ),
                      const SizedBox(height: 4),
                      _SidebarAction(
                        icon: expanded
                            ? Icons.keyboard_double_arrow_left_rounded
                            : Icons.keyboard_double_arrow_right_rounded,
                        label: expanded
                            ? 'Réduire la sidebar'
                            : 'Étendre la sidebar',
                        expanded: expanded,
                        onPressed: onToggle,
                        color: palette.muted,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarAction extends StatelessWidget {
  const _SidebarAction({
    required this.icon,
    required this.label,
    required this.expanded,
    required this.onPressed,
    required this.color,
  });

  final IconData icon;
  final String label;
  final bool expanded;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 44,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: expanded ? 10 : 0),
              child: Row(
                mainAxisAlignment: expanded
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 21),
                  if (expanded) ...[
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: color, fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
