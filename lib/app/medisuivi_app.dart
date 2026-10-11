import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../core/state/demo_store.dart';
import '../features/exams/exams_screen.dart';
import '../features/followup/followup_screen.dart';
import '../features/home/home_screen.dart';
import '../features/patients/patients_screen.dart';
import 'theme.dart';

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

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: AnimatedSwitcher(
          duration: reduceMotion ? Duration.zero :
            const Duration(milliseconds: 240),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
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
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(14, 0, 14, 8),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Container(
              height: 72,
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
              decoration: BoxDecoration(
                color: Palette.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Palette.border),
                boxShadow: const [
                  BoxShadow(
                    color: const Color(0x0B20362D),
                    blurRadius: 17,
                    offset: Offset(0, 6),
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
              duration: reduceMotion ? Duration.zero :
                const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color: selected ? Palette.tealSoft : Colors.transparent,
                borderRadius: BorderRadius.circular(19),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(selected ? selectedIcon : icon,
                    size: 22,
                    color: selected ? Palette.forest : Palette.muted),
                  const SizedBox(height: 4),
                  Text(label, style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? Palette.forest : Palette.muted,
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
