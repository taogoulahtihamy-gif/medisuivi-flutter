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
  const HomeScreen({
    super.key,
    required this.onPatients,
    required this.onExams,
    required this.onFollowup,
  });

  final VoidCallback onPatients;
  final VoidCallback onExams;
  final VoidCallback onFollowup;

  @override
  Widget build(BuildContext context) {
    final store = DemoScope.of(context);
    final patients = store.patients;
    final pending = store.exams.where((exam) => exam.status == ExamStatus.pending).length;
    final followUps = patients.where((patient) => patient.followUp).length;

    return ListView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      children: [
        ScreenWidth(
          padding: const EdgeInsets.fromLTRB(20, 17, 20, 40),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 43, height: 43,
                decoration: BoxDecoration(
                  color: Palette.navy, borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.medical_information_outlined,
                  color: Colors.white, size: 23),
              ),
              const SizedBox(width: 11),
              const Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('MediSuivi', style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -.5)),
                  SizedBox(height: 1),
                  Text('Espace clinique personnel',
                    style: TextStyle(fontSize: 11, color: Palette.muted)),
                ],
              )),
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                child: IconButton(
                  tooltip: 'Paramètres',
                  icon: const Icon(Icons.tune_rounded, size: 22),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SettingsScreen())),
                ),
              ),
            ]),
            const SizedBox(height: 25),
            Text(shortDate(DateTime.now()).toUpperCase(),
              style: const TextStyle(fontSize: 11, letterSpacing: 1.3,
                fontWeight: FontWeight.w700, color: Palette.teal)),
            const SizedBox(height: 7),
            const Text('Votre espace de suivi',
              style: TextStyle(fontSize: 27, letterSpacing: -.9,
                fontWeight: FontWeight.w800, height: 1.14)),
            const SizedBox(height: 6),
            const Text('Patients, consultations et bilans au même endroit.',
              style: TextStyle(color: Palette.muted, fontSize: 12.5)),
            const SizedBox(height: 22),
            EntranceReveal(
              child: _CareHero(onNewPatient: () =>
                Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => const NewPatientScreen()))),
            ),
            const SizedBox(height: 14),
            const DemoNotice(compact: true),
            const SizedBox(height: 25),
            const SectionHeading(title: 'Vue d’ensemble'),
            const SizedBox(height: 13),
            Row(children: [
              Expanded(child: _Metric(
                value: patients.length.toString(),
                title: 'Patients',
                icon: Icons.people_alt_outlined,
                background: Palette.aqua, foreground: Palette.teal)),
              const SizedBox(width: 10),
              Expanded(child: _Metric(
                value: followUps.toString(),
                title: 'À revoir',
                icon: Icons.event_available_outlined,
                background: Palette.blueSoft, foreground: Palette.navy)),
              const SizedBox(width: 10),
              Expanded(child: _Metric(
                value: pending.toString(),
                title: 'Bilans',
                icon: Icons.biotech_outlined,
                background: Palette.lavenderSoft,
                foreground: const Color(0xFF65558D))),
            ]),
            const SizedBox(height: 27),
            const SectionHeading(title: 'Accès rapide'),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _QuickAction(
                icon: Icons.folder_shared_outlined,
                label: 'Mes dossiers',
                detail: 'Rechercher un patient',
                onTap: onPatients,
              )),
              const SizedBox(width: 11),
              Expanded(child: _QuickAction(
                icon: Icons.monitor_heart_outlined,
                label: 'Mes suivis',
                detail: 'Visites à revoir',
                onTap: onFollowup,
              )),
            ]),
            const SizedBox(height: 28),
            SectionHeading(title: 'Patients récents',
              trailing: 'Voir tout', onTap: onPatients),
            const SizedBox(height: 12),
            for (final patient in patients.take(3)) ...[
              PatientRow(
                patient: patient,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) =>
                    PatientDetailScreen(patientId: patient.id))),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onExams,
              icon: const Icon(Icons.science_outlined, size: 18),
              label: const Text('Consulter les bilans'),
            ),
          ]),
        ),
      ],
    );
  }
}

class _CareHero extends StatelessWidget {
  const _CareHero({required this.onNewPatient});
  final VoidCallback onNewPatient;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final narrow = constraints.maxWidth < 345;
      return Container(
        height: narrow ? 256 : 250,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          boxShadow: const [
            BoxShadow(color: Color(0x190C4C58), blurRadius: 23,
              offset: Offset(0, 11)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Stack(fit: StackFit.expand, children: [
            SvgPicture.asset('assets/illustrations/medical_care.svg',
              fit: BoxFit.cover, alignment: Alignment.centerRight,
              semanticsLabel: 'Illustration d’une professionnelle de santé'),
            Positioned(
              left: 21, top: 25,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Text('DOSSIERS MÉDICAUX',
                  style: TextStyle(color: Colors.white, fontSize: 9,
                    letterSpacing: 1, fontWeight: FontWeight.w700)),
              ),
            ),
            Positioned(
              left: 21, top: 68,
              right: narrow ? 94 : 132,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Chaque patient,\nun suivi précis.',
                    style: TextStyle(color: Colors.white,
                      height: 1.13, letterSpacing: -.65,
                      fontWeight: FontWeight.w800, fontSize: 23)),
                  SizedBox(height: 11),
                  Text('Retrouvez l’essentiel en quelques instants.',
                    style: TextStyle(color: Color(0xFFD8EFEB),
                      height: 1.4, fontSize: 11.5)),
                ],
              ),
            ),
            Positioned(
              left: 18, bottom: 19,
              child: ElevatedButton.icon(
                onPressed: onNewPatient,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Palette.navy,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15, vertical: 0),
                  minimumSize: const Size(0, 42),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13)),
                ),
                icon: const Icon(Icons.add_rounded, size: 19),
                label: const Text('Nouveau patient',
                  style: TextStyle(fontSize: 12.5)),
              ),
            ),
          ]),
        ),
      );
    },
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.title,
    required this.icon, required this.background, required this.foreground});
  final String value;
  final String title;
  final IconData icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 126),
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Palette.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 34, height: 34,
        decoration: BoxDecoration(color: background,
          borderRadius: BorderRadius.circular(11)),
        child: Icon(icon, color: foreground, size: 19),
      ),
      const SizedBox(height: 13),
      Text(value, style: const TextStyle(
        fontSize: 25, fontWeight: FontWeight.w800,
        height: 1, letterSpacing: -.5)),
      const SizedBox(height: 5),
      Text(title, style: const TextStyle(
        fontSize: 11.5, color: Palette.muted, fontWeight: FontWeight.w600)),
    ]),
  );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label,
    required this.detail, required this.onTap});
  final IconData icon;
  final String label;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Palette.border)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: Palette.teal, size: 23),
              const Spacer(),
              const Icon(Icons.arrow_outward_rounded,
                color: Palette.muted, size: 17),
            ]),
            const SizedBox(height: 16),
            Text(label, style: const TextStyle(fontSize: 14.5,
              fontWeight: FontWeight.w700)),
            const SizedBox(height: 5),
            Text(detail, maxLines: 2,
              style: const TextStyle(color: Palette.muted, fontSize: 10.5)),
          ],
        ),
      ),
    ),
  );
}
