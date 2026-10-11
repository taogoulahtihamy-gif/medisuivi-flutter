import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../app/theme.dart';
import '../../core/models/medical_models.dart';
import '../../core/state/demo_store.dart';
import '../../core/widgets/medical_ui.dart';
import '../patients/new_patient_screen.dart';
import '../patients/patient_detail_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen(
      {super.key,
      required this.onPatients,
      required this.onExams,
      required this.onFollowup});
  final VoidCallback onPatients, onExams, onFollowup;
  @override
  Widget build(BuildContext context) {
    final store = DemoScope.of(context);
    final patients = [...store.patients]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    void newPatient() => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const NewPatientScreen()));
    return ListView(children: [
      ScreenWidth(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                  color: Palette.forest,
                  borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.medical_information_outlined,
                  color: Colors.white)),
          const SizedBox(width: 12),
          const Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('MediSuivi',
                    style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.5)),
                Text('Espace clinique personnel',
                    style: TextStyle(fontSize: 12, color: Palette.muted)),
              ])),
          IconButton(
              tooltip: 'Paramètres',
              icon: Icon(AppIcons.settings(context)),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                      builder: (_) => const SettingsScreen()))),
        ]),
        const SizedBox(height: 32),
        Text(shortDate(DateTime.now()).toUpperCase(),
            style: const TextStyle(
                fontSize: 12,
                letterSpacing: 1.2,
                color: Palette.forest,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('Votre espace de suivi',
            style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 8),
        const Text('Une vue claire pour accompagner chaque patient.',
            style: TextStyle(color: Palette.muted, fontSize: 14)),
        const SizedBox(height: 24),
        AnimatedSection(child: _CareHero(onNewPatient: newPatient)),
        const SizedBox(height: 16),
        const DemoNotice(compact: true),
        const SizedBox(height: 28),
        const SectionHeading(title: 'Vue d’ensemble'),
        const SizedBox(height: 12),
        AdaptiveColumns(minWidth: 90, children: [
          MedicalMetricCard(
              label: 'Patients',
              value: '${patients.length}',
              icon: Icons.people_outline,
              onTap: onPatients),
          MedicalMetricCard(
              label: 'À revoir',
              value: '${patients.where((p) => p.followUp).length}',
              icon: Icons.event_repeat_outlined,
              onTap: onFollowup),
          MedicalMetricCard(
              label: 'Bilans en attente',
              value:
                  '${store.exams.where((e) => e.status == ExamStatus.pending).length}',
              icon: Icons.science_outlined,
              onTap: onExams),
        ]),
        const SizedBox(height: 28),
        const SectionHeading(title: 'Accès rapide'),
        const SizedBox(height: 12),
        AdaptiveColumns(children: [
          _QuickAction(
              icon: Icons.person_add_alt,
              label: 'Créer un patient',
              detail: 'Créer un dossier',
              onTap: newPatient),
          _QuickAction(
              icon: Icons.search_rounded,
              label: 'Rechercher',
              detail: 'Trouver un patient',
              onTap: onPatients),
          _QuickAction(
              icon: Icons.science_outlined,
              label: 'Consulter les bilans',
              detail: 'Examens et résultats',
              onTap: onExams),
          _QuickAction(
              icon: Icons.monitor_heart_outlined,
              label: 'Suivi médical',
              detail: 'Continuité des soins',
              onTap: onFollowup),
        ]),
        const SizedBox(height: 28),
        SectionHeading(
            title: 'Patients récents',
            trailing: 'Voir tout',
            onTap: onPatients),
        const Text('Derniers dossiers créés',
            style: TextStyle(color: Palette.muted, fontSize: 12)),
        const SizedBox(height: 12),
        if (patients.isEmpty)
          const EmptyState(
              title: 'Votre premier dossier',
              detail: 'Ajoutez un patient fictif pour explorer MediSuivi.'),
        for (final patient in patients.take(3))
          Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PatientCard(
                  patient: patient,
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                          builder: (_) =>
                              PatientDetailScreen(patientId: patient.id))))),
      ]))
    ]);
  }
}

class _CareHero extends StatelessWidget {
  const _CareHero({required this.onNewPatient});
  final VoidCallback onNewPatient;
  @override
  Widget build(BuildContext context) => Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
            color: Palette.forest,
            borderRadius: BorderRadius.circular(AppRadius.hero),
            boxShadow: AppShadows.soft),
        child: LayoutBuilder(builder: (context, constraints) {
          final wide = constraints.maxWidth > 480 &&
              MediaQuery.textScalerOf(context).scale(14) < 21;
          final copy = Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('LE SOIN, EN CONTINUITÉ',
                        style: TextStyle(
                            color: Palette.mintFog,
                            fontSize: 12,
                            letterSpacing: 1)),
                    const SizedBox(height: 14),
                    const Text('Chaque patient,\nun suivi précis.',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            height: 1.15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -.7)),
                    const SizedBox(height: 12),
                    const Text(
                        'L’essentiel du dossier, du premier échange au prochain rendez-vous.',
                        style: TextStyle(
                            color: Palette.mintFog, fontSize: 14, height: 1.5)),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                        onPressed: onNewPatient,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Palette.mintFog,
                            foregroundColor: Palette.deepForest),
                        icon: const Icon(Icons.add_rounded),
                        label: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text('Nouveau patient'))),
                  ]));
          final art = ExcludeSemantics(
              child: SvgPicture.asset(
                  'assets/illustrations/care_continuity.svg',
                  height: wide ? 240 : 130,
                  fit: BoxFit.contain));
          return wide
              ? Row(children: [
                  Expanded(flex: 3, child: copy),
                  Expanded(flex: 2, child: art)
                ])
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [copy, art]);
        }),
      );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction(
      {required this.icon,
      required this.label,
      required this.detail,
      required this.onTap});
  final IconData icon;
  final String label, detail;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => PremiumCard(
      onTap: onTap,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: Palette.forest),
        const SizedBox(height: 16),
        Text(label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(detail,
            style: const TextStyle(fontSize: 12, color: Palette.muted)),
      ]));
}
