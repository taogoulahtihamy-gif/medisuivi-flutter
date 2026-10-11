import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/models/medical_models.dart';
import '../../core/state/demo_store.dart';
import '../../core/widgets/medical_ui.dart';
import '../patients/new_patient_screen.dart';
import '../patients/patient_detail_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onPatients});
  final VoidCallback onPatients;

  @override
  Widget build(BuildContext context) {
    final store = DemoScope.of(context);
    final patients = store.patients;
    final pending = store.exams.where((e) => e.status == ExamStatus.pending).length;
    final followUps = patients.where((p) => p.followUp).length;
    return ListView(children: [ScreenWidth(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 43, height: 43,
          decoration: BoxDecoration(color: Palette.teal, borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.medical_services_outlined, color: Colors.white)),
        const SizedBox(width: 12),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('MediSuivi', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          Text('Mon espace clinique', style: TextStyle(fontSize: 12, color: Palette.muted)),
        ])),
        IconButton(tooltip: 'Paramètres', icon: const Icon(Icons.settings_outlined),
          onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const SettingsScreen()))),
      ]),
      const SizedBox(height: 29),
      Text(shortDate(DateTime.now()), style: const TextStyle(color: Palette.muted, fontWeight: FontWeight.w600, fontSize: 13)),
      const SizedBox(height: 8),
      const Text('Votre suivi, en toute clarté.',
        style: TextStyle(fontSize: 30, height: 1.15, letterSpacing: -1.2, fontWeight: FontWeight.w800)),
      const SizedBox(height: 14),
      const DemoNotice(compact: true),
      const SizedBox(height: 23),
      Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(color: Palette.tealDark, borderRadius: BorderRadius.circular(23)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.folder_shared_outlined, color: Colors.white70, size: 20), SizedBox(width: 9),
            Text('DOSSIER PATIENT', style: TextStyle(fontSize: 11, color: Colors.white70, letterSpacing: 1.2, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 18),
          const Text('Une information retrouvée.\nUn meilleur suivi.',
            style: TextStyle(fontSize: 23, height: 1.2, letterSpacing: -0.7, color: Colors.white, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          const Text('Consultations, constantes et bilans au même endroit.',
            style: TextStyle(color: Color(0xFFD0E0DD), fontSize: 13)),
          const SizedBox(height: 21),
          Wrap(spacing: 8, runSpacing: 10, children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Palette.tealDark),
              onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const NewPatientScreen())),
              icon: const Icon(Icons.person_add_alt_1_rounded), label: const Text('Nouveau patient')),
            TextButton(onPressed: onPatients,
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              child: const Text('Mes dossiers  →')),
          ]),
        ]),
      ),
      const SizedBox(height: 24),
      const SectionHeading(title: 'En un regard'),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _Metric(icon: Icons.people_outline_rounded, value: '${patients.length}', label: 'Patients')),
        const SizedBox(width: 10),
        Expanded(child: _Metric(icon: Icons.event_repeat_rounded, value: '$followUps', label: 'À revoir')),
        const SizedBox(width: 10),
        Expanded(child: _Metric(icon: Icons.biotech_outlined, value: '$pending', label: 'Bilans en attente')),
      ]),
      const SizedBox(height: 26),
      SectionHeading(title: 'Dossiers récents', trailing: 'Tout voir', onTap: onPatients),
      const SizedBox(height: 12),
      for (final p in patients.take(3)) ...[
        PatientRow(patient: p, onTap: () => Navigator.push(context,
          MaterialPageRoute<void>(builder: (_) => PatientDetailScreen(patientId: p.id)))),
        const SizedBox(height: 9),
      ],
    ]))]);
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => SurfaceCard(padding: const EdgeInsets.all(13), child: Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: Palette.teal, size: 20),
      const SizedBox(height: 13),
      Text(value, style: const TextStyle(fontSize: 25, letterSpacing: -0.6, fontWeight: FontWeight.w800)),
      const SizedBox(height: 5),
      Text(label, maxLines: 2, style: const TextStyle(fontSize: 11.5, height: 1.25, color: Palette.muted)),
    ],
  ));
}
