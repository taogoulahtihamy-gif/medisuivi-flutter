import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../core/state/demo_store.dart';
import '../features/exams/exams_screen.dart';
import '../features/followup/followup_screen.dart';
import '../features/home/home_screen.dart';
import '../features/patients/patients_screen.dart';
import 'theme.dart';
import 'design_tokens.dart';

class MediSuiviApp extends StatefulWidget {
  const MediSuiviApp({super.key});

  @override
  State<MediSuiviApp> createState() => _MediSuiviAppState();
}

class _MediSuiviAppState extends State<MediSuiviApp> {
  final DemoStore _store = DemoStore();

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DemoScope(
    store: _store,
    child: MaterialApp(
      title: 'MediSuivi',
      debugShowCheckedModeBanner: false,
      theme: MediTheme.light(),
      darkTheme: MediTheme.dark(),
      themeMode: ThemeMode.system,
      home: const MainShell(),
    ),
  );
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int selected = 0;

  void _select(int index) {
    if (index != selected) {
      setState(() => selected = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      HomeScreen(
        onPatients: () => _select(1),
        onExams: () => _select(2),
        onFollowup: () => _select(3),
      ),
      const PatientsScreen(),
      const ExamsScreen(),
      const FollowupScreen(),
    ];

    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final isIos = Theme.of(context).platform == TargetPlatform.iOS;

    final palette = Palette.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final showRail = width >= ClinicalBreakpoints.mobile;
    final expandedRail = width >= ClinicalBreakpoints.tablet;

    final content = SafeArea(
      bottom: false,
      child: AnimatedSwitcher(
        duration: reduceMotion ? Duration.zero : ClinicalMotion.brisk,
        switchInCurve: ClinicalMotion.easeOut,
        switchOutCurve: ClinicalMotion.easeInOut,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.025, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: KeyedSubtree(
          key: ValueKey<int>(selected),
          child: screens[selected],
        ),
      ),
    );

    return Scaffold(
      body: showRail
          ? SafeArea(
              child: Row(children: [
                NavigationRail(
                  selectedIndex: selected,
                  onDestinationSelected: _select,
                  extended: expandedRail,
                  minWidth: 76,
                  minExtendedWidth: 252,
                  backgroundColor: palette.surface,
                  indicatorColor: palette.tealSoft,
                  selectedIconTheme: IconThemeData(color: palette.forest, size: 24),
                  unselectedIconTheme: IconThemeData(color: palette.muted, size: 24),
                  selectedLabelTextStyle: TextStyle(
                    color: palette.ink, fontSize: 13, fontWeight: FontWeight.w700),
                  unselectedLabelTextStyle: TextStyle(
                    color: palette.muted, fontSize: 13),
                  labelType: expandedRail
                      ? NavigationRailLabelType.none
                      : NavigationRailLabelType.selected,
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 22),
                    child: Icon(Icons.medical_services_outlined,
                      color: palette.forest, size: 28),
                  ),
                  destinations: [
                    NavigationRailDestination(
                      icon: Icon(isIos ? CupertinoIcons.house : Icons.home_outlined),
                      selectedIcon: Icon(isIos ? CupertinoIcons.house_fill : Icons.home_rounded),
                      label: const Text('Accueil'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(isIos ? CupertinoIcons.person_2 : Icons.people_outline_rounded),
                      selectedIcon: Icon(isIos ? CupertinoIcons.person_2_fill : Icons.people_rounded),
                      label: const Text('Patients'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(isIos ? CupertinoIcons.doc_text : Icons.biotech_outlined),
                      selectedIcon: Icon(isIos ? CupertinoIcons.doc_text_fill : Icons.biotech_rounded),
                      label: const Text('Bilans'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(isIos ? CupertinoIcons.chart_bar : Icons.insights_outlined),
                      selectedIcon: Icon(isIos ? CupertinoIcons.chart_bar_fill : Icons.insights_rounded),
                      label: const Text('Suivi'),
                    ),
                  ],
                ),
                VerticalDivider(width: 1, thickness: 1, color: palette.border),
                Expanded(child: content),
              ]),
            )
          : content,
      bottomNavigationBar: showRail ? null : SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(14, 0, 14, 8),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Container(
              height: 64,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: palette.border),
                boxShadow: [
                  BoxShadow(
                    color: palette.night.withValues(
                      alpha: palette.isDark ? 0.22 : 0.08),
                    blurRadius: 16, offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(children: [
                _NavItem(
                  label: 'Accueil',
                  icon: isIos ? CupertinoIcons.house : Icons.home_outlined,
                  selectedIcon: isIos ? CupertinoIcons.house_fill : Icons.home_rounded,
                  selected: selected == 0,
                  onTap: () => _select(0),
                ),
                _NavItem(
                  label: 'Patients',
                  icon: isIos ? CupertinoIcons.person_2 : Icons.people_outline_rounded,
                  selectedIcon: isIos ? CupertinoIcons.person_2_fill : Icons.people_rounded,
                  selected: selected == 1,
                  onTap: () => _select(1),
                ),
                _NavItem(
                  label: 'Bilans',
                  icon: isIos ? CupertinoIcons.doc_text : Icons.biotech_outlined,
                  selectedIcon: isIos ? CupertinoIcons.doc_text_fill : Icons.biotech_rounded,
                  selected: selected == 2,
                  onTap: () => _select(2),
                ),
                _NavItem(
                  label: 'Suivi',
                  icon: isIos ? CupertinoIcons.chart_bar : Icons.insights_outlined,
                  selectedIcon: isIos ? CupertinoIcons.chart_bar_fill : Icons.insights_rounded,
                  selected: selected == 3,
                  onTap: () => _select(3),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final palette = Palette.of(context);
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: reduceMotion ? Duration.zero : ClinicalMotion.brisk,
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color: selected ? palette.tealSoft : Colors.transparent,
                borderRadius: BorderRadius.circular(19),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(selected ? selectedIcon : icon,
                    size: 21,
                    color: selected ? palette.forest : palette.muted),
                  const SizedBox(height: 2),
                  Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                    fontSize: 11, height: 1.0,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected ? palette.forest : palette.muted,
                  )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
