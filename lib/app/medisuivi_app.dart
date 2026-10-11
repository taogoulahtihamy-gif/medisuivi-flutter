import '../core/widgets/floating_bottom_navigation.dart';
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

    final reduceMotion =
        AppMotion.duration(context, AppMotion.transition) == Duration.zero;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: AnimatedSwitcher(
          duration:
              reduceMotion ? Duration.zero : const Duration(milliseconds: 290),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.035, 0),
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
      bottomNavigationBar:
          FloatingBottomNavigation(selected: selected, onSelected: _select),
    );
  }
}
