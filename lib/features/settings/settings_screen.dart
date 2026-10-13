import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../app/theme.dart';
import '../../core/widgets/medical_ui.dart';
import '../../core/state/store_context.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Paramètres')),
    body: SafeArea(child: ListView(children: [ScreenWidth(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        PageTitle(title: 'Mon espace', subtitle: 'État et paramètres de l’application'),
        SizedBox(height: 21),
        _Item(
          Icons.info_outline_rounded,
          'Stockage actuel',
          kIsWeb
              ? 'Navigateur : données fictives temporaires. Elles disparaissent à la fermeture.'
              : 'Téléphone : données stockées localement. Validation du chiffrement sur appareil réel encore nécessaire.',
        ),
        const SizedBox(height: 10),
        _Item(
          Icons.lock_outline_rounded,
          'Protection des dossiers',
          'Application en développement. Ne pas enregistrer de données patients réelles avant la validation sécurité.',
        ),
        const SizedBox(height: 10),
        if (!kIsWeb) ...[
          FutureBuilder<int>(
            future: context.store.pendingSyncCount as Future<int>,
            builder: (context, snapshot) {
              final count = snapshot.data;
              final message = snapshot.hasError
                  ? 'Impossible de vérifier les opérations locales.'
                  : count == null
                      ? 'Vérification des opérations locales…'
                      : count == 0
                          ? 'Aucune modification en attente. Aucun serveur distant connecté.'
                          : '$count modification(s) conservée(s) sur ce téléphone, en attente d’un futur envoi.';
              return _Item(
                Icons.cloud_upload_outlined,
                'Modifications à envoyer',
                message,
              );
            },
          ),
          const SizedBox(height: 10),
        ],
        _Item(
          Icons.cloud_sync_outlined,
          'Synchronisation distante',
          'Non configurée. Aucune transmission automatique à un serveur.',
        ),
        SizedBox(height: 10),
        _Item(Icons.devices_rounded, 'iOS et Android',
          'Interface adaptative Flutter avec navigation propre à chaque plateforme.'),
        SizedBox(height: 23),
        Text('MediSuivi · Version de développement',
          style: TextStyle(color: Palette.of(context).muted, fontSize: 12, fontWeight: FontWeight.w600)),
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
        Text(subtitle, style: TextStyle(fontSize: 12, color: Palette.of(context).muted, height: 1.4)),
      ])),
    ],
  ));
}
