import 'package:flutter/material.dart';

import '../core/state/demo_store.dart';
import '../core/widgets/clinical_sidebar.dart';
import '../core/widgets/clinical_bottom_dock.dart';
import '../features/patients/new_patient_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/exams/exams_screen.dart';
import '../features/followup/followup_screen.dart';
import '../features/home/home_screen.dart';
import '../features/patients/patients_screen.dart';
import 'theme.dart';
import 'theme_controller.dart';
import 'design_tokens.dart';

class MediSuiviApp extends StatefulWidget {
  const MediSuiviApp({super.key, this.themeMode = ThemeMode.system});

  final ThemeMode themeMode;

  @override
  State<MediSuiviApp> createState() => _MediSuiviAppState();
}

class _MediSuiviAppState extends State<MediSuiviApp> {
  final DemoStore _store = DemoStore();
  late final ThemeModeController _themeController =
      ThemeModeController(initial: widget.themeMode);

  @override
  void initState() {
    super.initState();
    if (widget.themeMode == ThemeMode.system) {
      _themeController.load();
    }
  }

  @override
  void dispose() {
    _store.dispose();
    _themeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ClinicalThemeScope(
    controller: _themeController,
    child: AnimatedBuilder(
      animation: _themeController,
      builder: (context, _) => DemoScope(
        store: _store,
        child: MaterialApp(
          title: 'MediSuivi',
          debugShowCheckedModeBanner: false,
          theme: MediTheme.light(),
          darkTheme: MediTheme.dark(),
          themeMode: _themeController.value,
          home: const MainShell(),
        ),
      ),
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
  bool? _expandedOverride;

  void _toggleSidebar() {
    final isDesktop = MediaQuery.sizeOf(context).width >= ClinicalBreakpoints.tablet;
    setState(() => _expandedOverride = !(_expandedOverride ?? isDesktop));
  }

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
      const SettingsScreen(),
    ];

    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final width = MediaQuery.sizeOf(context).width;
    final showRail = width >= ClinicalBreakpoints.mobile;
    final expandedRail = _expandedOverride ?? width >= ClinicalBreakpoints.tablet;

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
                ClinicalSidebar(
                  selectedIndex: selected,
                  expanded: expandedRail,
                  onSelected: _select,
                  onToggle: _toggleSidebar,
                  onSettings: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SettingsScreen(),
                    ),
                  ),
                ),
                Expanded(child: content),
              ]),
            )
          : content,
      bottomNavigationBar: showRail ? null : ClinicalBottomDock(
        selectedIndex: selected,
        onSelected: _select,
        onCreate: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const NewPatientScreen(),
          ),
        ),
      ),
    );
  }
}
