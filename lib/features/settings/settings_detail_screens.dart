import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../core/models/medical_models.dart';
import '../../core/state/store_context.dart';
import '../../core/widgets/medical_ui.dart';
import '../../core/widgets/clinical_tab_route.dart';
import '../patients/patients_screen.dart';
import '../exams/exams_screen.dart';

/// Actions réellement disponibles sur l'appareil. Les fonctions serveur
/// absentes ne sont pas présentées comme des réglages activables.
class SettingsDataPage extends StatefulWidget {
  const SettingsDataPage({super.key});

  @override
  State<SettingsDataPage> createState() => _SettingsDataPageState();
}

class _SettingsDataPageState extends State<SettingsDataPage> {
  Future<int>? _pending;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!kIsWeb) _pending = context.store.pendingSyncCount;
  }

  void _refresh() {
    if (!kIsWeb) setState(() => _pending = context.store.pendingSyncCount);
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final store = context.store;
    final patients = store.patients.length;
    final exams = store.exams.length;
    final pending = store.exams.where((e) => e.status == ExamStatus.pending).length;
    return Scaffold(
      appBar: AppBar(title: const Text('Données et stockage')),
      body: SafeArea(child: ListView(
        padding: const EdgeInsets.fromLTRB(21, 14, 21, 36),
        children: [
          Text('Sur cet appareil', style: TextStyle(
            color: p.ink, fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(kIsWeb ? 'Données de démonstration du navigateur.'
              : 'État actuel des données locales.',
            style: TextStyle(color: p.muted, fontSize: 13.5)),
          const SizedBox(height: 24),
          _StatStrip(values: [
            ('$patients', 'Patients'),
            ('$exams', 'Examens'),
            ('$pending', 'En attente'),
          ]),
          const SizedBox(height: 25),
          Text('Accès rapide', style: TextStyle(
            color: p.muted, fontSize: 11.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          ClinicalGroupedList(children: [
            ClinicalListRow(
              key: const Key('data-view-patients'),
              leading: Icon(Icons.people_outline_rounded, color: p.forest),
              title: 'Consulter les patients',
              subtitle: '$patients dossiers dans cet espace',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) =>
                  const ClinicalTabRoute(
                    title: 'Mes patients',
                    child: PatientsScreen(),
                  ))),
            ),
            ClinicalListRow(
              key: const Key('data-view-exams'),
              leading: Icon(Icons.biotech_outlined, color: p.forest),
              title: 'Consulter les bilans',
              subtitle: '$pending en attente de résultat',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) =>
                  const ClinicalTabRoute(
                    title: 'Bilans médicaux',
                    child: ExamsScreen(),
                  ))),
            ),
          ]),
          const SizedBox(height: 23),
          if (!kIsWeb) ...[
            Row(children: [
              Expanded(child: Text('Opérations hors connexion',
                style: TextStyle(color: p.ink, fontSize: 15,
                  fontWeight: FontWeight.w600))),
              TextButton.icon(
                key: const Key('data-refresh'),
                onPressed: _refresh,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Actualiser')),
            ]),
            FutureBuilder<int>(
              future: _pending,
              builder: (context, snapshot) => Text(snapshot.hasError
                ? 'Impossible de lire les opérations locales.'
                : snapshot.data == null
                  ? 'Vérification en cours…'
                  : '${snapshot.data} opération(s) conservée(s) localement.',
                style: TextStyle(color: p.muted, fontSize: 13)),
            ),
            const SizedBox(height: 18),
          ],
          Text(kIsWeb
            ? 'La démonstration n’est pas un compte personnel permanent.'
            : 'Aucun transfert, export ou sauvegarde cloud automatique n’est activé.',
            style: TextStyle(color: p.muted, fontSize: 12.5, height: 1.45)),
        ],
      )),
    );
  }
}

class _StatStrip extends StatelessWidget {
  const _StatStrip({required this.values});
  final List<(String, String)> values;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.border),
      ),
      child: Row(children: [
        for (var i = 0; i < values.length; i++) ...[
          if (i != 0) Container(width: 1, height: 32, color: p.border),
          Expanded(child: Column(children: [
            Text(values[i].$1, style: TextStyle(color: p.ink,
              fontSize: 21, fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            Text(values[i].$2, textAlign: TextAlign.center,
              style: TextStyle(color: p.muted, fontSize: 11)),
          ])),
        ],
      ]),
    );
  }
}

class SettingsSyncPage extends StatelessWidget {
  const SettingsSyncPage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Synchronisation')),
      body: SafeArea(child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 17, 22, 35),
        children: [
          Text('État des synchronisations', style: TextStyle(
            fontSize: 23, fontWeight: FontWeight.w700, color: p.ink)),
          const SizedBox(height: 10),
          Text('Aucun serveur distant n’est connecté.',
            style: TextStyle(fontSize: 14, color: p.muted)),
          const SizedBox(height: 22),
          ClinicalGroupedList(children: [
            ClinicalListRow(
              leading: Icon(Icons.phonelink_lock_outlined, color: p.forest),
              title: 'Données sur cet appareil',
              subtitle: kIsWeb ? 'Démonstration temporaire dans le navigateur'
                : 'Dossiers conservés dans le stockage local',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SettingsDataPage())),
            ),
            ClinicalListRow(
              leading: Icon(Icons.cloud_off_outlined, color: p.forest),
              title: 'Compte et serveur',
              subtitle: 'Non configurés : aucun transfert automatique',
              onTap: () => showDialog<void>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Aucun serveur connecté'),
                  content: const Text(
                    'Le service de comptes sécurisés n’est pas encore disponible. '
                    'Il n’est pas possible d’activer la synchronisation actuellement.'),
                  actions: [TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Fermer'))],
                ),
              ),
            ),
          ]),
          const SizedBox(height: 24),
          Text('Les futures sauvegardes et restaurations seront proposées '
            'uniquement après validation des contrôles de confidentialité.',
            style: TextStyle(color: p.muted, fontSize: 12.5, height: 1.5)),
        ],
      )),
    );
  }
}

class SettingsPrivacyPage extends StatelessWidget {
  const SettingsPrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Confidentialité')),
      body: SafeArea(child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 35),
        children: [
          Text('Confidentialité et protection',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700,
              color: p.ink)),
          const SizedBox(height: 10),
          Text('Vérifiez le fonctionnement actuel de MediSuivi.',
            style: TextStyle(color: p.muted, fontSize: 13.5)),
          const SizedBox(height: 23),
          ClinicalGroupedList(children: [
            ClinicalListRow(
              leading: Icon(Icons.storage_rounded, color: p.forest),
              title: 'Mes données locales',
              subtitle: 'Consulter les dossiers présents sur cet appareil',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SettingsDataPage())),
            ),
            ClinicalListRow(
              leading: Icon(Icons.cloud_off_outlined, color: p.forest),
              title: 'Connexions distantes',
              subtitle: 'Aucune synchronisation activée',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SettingsSyncPage())),
            ),
          ]),
          const SizedBox(height: 25),
          Text('Cette version n’est pas validée pour la saisie de données '
            'patients réelles. Le contrôle d’accès par compte et la '
            'restauration sécurisée restent à développer.',
            style: TextStyle(color: p.muted, fontSize: 13, height: 1.5)),
        ],
      )),
    );
  }
}

class SettingsAboutPage extends StatelessWidget {
  const SettingsAboutPage({super.key});
  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('À propos')),
      body: SafeArea(child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 19, 22, 34),
        children: [
          Text('MediSuivi', style: TextStyle(fontSize: 26,
            fontWeight: FontWeight.w700, color: p.ink)),
          const SizedBox(height: 5),
          Text('Prototype de suivi clinique · Version 0.1.0',
            style: TextStyle(color: p.muted, fontSize: 13)),
          const SizedBox(height: 25),
          ClinicalGroupedList(children: [
            ClinicalListRow(
              key: const Key('about-licenses'),
              leading: Icon(Icons.description_outlined, color: p.forest),
              title: 'Licences et composants',
              subtitle: 'Consulter les licences Open Source',
              onTap: () => showLicensePage(
                context: context, applicationName: 'MediSuivi'),
            ),
            ClinicalListRow(
              leading: Icon(Icons.image_outlined, color: p.forest),
              title: 'Crédits photographiques',
              subtitle: 'Photographies cliniques Pexels intégrées hors ligne',
              onTap: () => showAboutDialog(
                context: context, applicationName: 'MediSuivi',
                children: [const Text(
                  'Les photographies de présentation proviennent de Pexels '
                  'et sont utilisées conformément à leur licence.')]),
            ),
          ]),
          const SizedBox(height: 21),
          Text('Aucun compte utilisateur ni serveur médical réel connecté.',
            style: TextStyle(color: p.muted, fontSize: 12.5)),
        ],
      )),
    );
  }
}
