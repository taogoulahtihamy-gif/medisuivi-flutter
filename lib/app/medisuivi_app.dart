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
  void dispose() { _store.dispose(); super.dispose(); }
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
  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomeScreen(onPatients: () => setState(() => selected = 1)),
      const PatientsScreen(),
      const ExamsScreen(),
      const FollowupScreen(),
    ];
    final isIos = Theme.of(context).platform == TargetPlatform.iOS;
    return Scaffold(
      body: SafeArea(bottom: false, child: AnimatedSwitcher(
        duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero : const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutCubic,
        child: KeyedSubtree(key: ValueKey(selected), child: pages[selected]),
      )),
      bottomNavigationBar: isIos ? CupertinoTabBar(
        currentIndex: selected,
        activeColor: Palette.teal,
        inactiveColor: Palette.muted,
        backgroundColor: Palette.white,
        onTap: (i) => setState(() => selected = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.house), activeIcon: Icon(CupertinoIcons.house_fill), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.person_2), activeIcon: Icon(CupertinoIcons.person_2_fill), label: 'Patients'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.doc_text), activeIcon: Icon(CupertinoIcons.doc_text_fill), label: 'Bilans'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.chart_bar), activeIcon: Icon(CupertinoIcons.chart_bar_fill), label: 'Suivi'),
        ],
      ) : NavigationBar(
        selectedIndex: selected,
        height: 72,
        elevation: 0,
        backgroundColor: Palette.white,
        indicatorColor: Palette.tealSoft,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (i) => setState(() => selected = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Accueil'),
          NavigationDestination(icon: Icon(Icons.people_outline_rounded), selectedIcon: Icon(Icons.people_rounded), label: 'Patients'),
          NavigationDestination(icon: Icon(Icons.biotech_outlined), selectedIcon: Icon(Icons.biotech_rounded), label: 'Bilans'),
          NavigationDestination(icon: Icon(Icons.show_chart_rounded), selectedIcon: Icon(Icons.insights_rounded), label: 'Suivi'),
        ],
      ),
    );
  }
}
