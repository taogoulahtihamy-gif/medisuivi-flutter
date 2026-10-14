import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../app/theme.dart';
import '../../app/theme_controller.dart';
import '../../core/widgets/medical_ui.dart';
import '../../core/state/store_context.dart';
import '../onboarding/medisuivi_welcome_gate.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<int>? _pendingSyncCountFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Mise à jour seulement lors d'une dépendance InheritedNotifier,
    // pas à chaque reconstruction causée par FutureBuilder.
    if (!kIsWeb) {
      _pendingSyncCountFuture = context.store.pendingSyncCount;
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Paramètres')),
        body: SafeArea(
            child: ListView(children: [
          ScreenWidth(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                PageTitle(
                    title: 'Mon espace',
                    subtitle: 'État et paramètres de l’application'),
                const SizedBox(height: 15),
                const _AppearanceSettings(),
                const SizedBox(height: 10),
                Builder(builder: (context) {
                  final profile = PractitionerPreviewScope.maybeOf(context);
                  if (profile == null) {
                    return const _Item(
                      Icons.person_outline_rounded,
                      'Profil du praticien',
                      'Aucun compte personnel configuré.',
                    );
                  }
                  return SurfaceCard(
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      key: const Key('settings-practitioner-profile'),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                      leading: CircleAvatar(
                        radius: 23,
                        backgroundColor: Palette.of(context).tealSoft,
                        foregroundImage: profile.photo == null
                            ? null : MemoryImage(profile.photo!),
                        child: profile.photo == null
                            ? Icon(Icons.person_rounded,
                                color: Palette.of(context).forest) : null,
                      ),
                      title: Text(profile.displayName.isEmpty
                          ? 'Profil du praticien' : profile.displayName),
                      subtitle: const Text('Profil local de prévisualisation'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (formContext) => PractitionerPreviewForm(
                            controller: profile,
                            isWebDemo: kIsWeb,
                            onSaved: () => Navigator.of(formContext).pop(),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
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
                    future: _pendingSyncCountFuture,
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
                    style: TextStyle(
                        color: Palette.of(context).muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ]))
        ])),
      );
}

class _AppearanceSettings extends StatelessWidget {
  const _AppearanceSettings();

  @override
  Widget build(BuildContext context) {
    final controller = ClinicalThemeScope.maybeOf(context);
    final palette = Palette.of(context);
    final current = controller?.value ?? ThemeMode.system;
    const options = <(ThemeMode, String, IconData)>[
      (ThemeMode.light, 'Clair', Icons.light_mode_outlined),
      (ThemeMode.dark, 'Sombre', Icons.dark_mode_outlined),
      (ThemeMode.system, 'Auto', Icons.settings_suggest_outlined),
    ];
    return SurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Apparence', style: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w700, color: palette.ink)),
          const SizedBox(height: 5),
          Text('Choisir le thème de MediSuivi.',
            style: TextStyle(fontSize: 12, color: palette.muted)),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final option in options)
              ChoiceChip(
                key: Key('theme-${option.$1.name}'),
                label: Text(option.$2),
                avatar: Icon(option.$3, size: 17),
                selected: current == option.$1,
                onSelected: controller == null ? null :
                  (_) => controller.choose(option.$1),
              ),
          ]),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item(this.icon, this.title, this.subtitle);
  final IconData icon;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => SurfaceCard(
          child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SoftIcon(icon: icon),
          const SizedBox(width: 13),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 12,
                        color: Palette.of(context).muted,
                        height: 1.4)),
              ])),
        ],
      ));
}
