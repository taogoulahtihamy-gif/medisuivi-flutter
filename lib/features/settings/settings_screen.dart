import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../core/widgets/medical_ui.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Paramètres')),
    body: SafeArea(child: ListView(children: [const ScreenWidth(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        PageTitle(title: 'Mon espace', subtitle: 'État et paramètres de l’application'),
        SizedBox(height: 21),
        DemoNotice(),
        SizedBox(height: 22),
        _Item(Icons.lock_outline_rounded, 'Protection des dossiers',
          'À réaliser en V1 : stockage chiffré, authentification et verrouillage.'),
        SizedBox(height: 10),
        _Item(Icons.cloud_sync_outlined, 'Synchronisation hors ligne',
          'Prévue dans l’architecture. Aucun serveur n’est connecté en V0.'),
        SizedBox(height: 10),
        _Item(Icons.devices_rounded, 'iOS et Android',
          'Interface adaptative Flutter avec navigation propre à chaque plateforme.'),
        SizedBox(height: 23),
        Text('MediSuivi · Prototype 0.1.0',
          style: TextStyle(color: Palette.muted, fontSize: 12, fontWeight: FontWeight.w600)),
      ]))])),
  );
}

class _Item extends StatelessWidget {
  const _Item(this.icon, this.title, this.subtitle);
  final IconData icon;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => SurfaceCard(child: Row(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
      SoftIcon(icon: icon),
      const SizedBox(width: 13),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(subtitle, style: const TextStyle(fontSize: 12, color: Palette.muted, height: 1.4)),
      ])),
    ],
  ));
}
