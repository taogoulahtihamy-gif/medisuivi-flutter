import 'package:flutter/material.dart';
import 'dart:convert';

import '../../core/assets/clinical_hero_photo.dart';
import '../../app/theme.dart';
import '../../core/models/medical_models.dart';
import '../../core/state/demo_store.dart';
import '../../core/widgets/medical_ui.dart';
import '../patients/new_patient_screen.dart';
import '../patients/patient_detail_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onPatients,
    required this.onExams, required this.onFollowup});
  final VoidCallback onPatients;
  final VoidCallback onExams;
  final VoidCallback onFollowup;

  @override
  Widget build(BuildContext context) {
    final store = DemoScope.of(context);
    final patients = store.patients;
    final toReview = patients.where((p) => p.followUp).length;
    final pending = store.exams.where((e) => e.status == ExamStatus.pending).length;
    final today = DateTime.now();
    final coming = store.plannedFollowUps
      .where((plan) => !plan.isOverdue(today)).toList();
    final nextVisit = coming.isEmpty ? null : coming.first;
    void addPatient() => Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => const NewPatientScreen()));

    return ListView(
      key: const ValueKey('medisuivi-home'),
      physics: const BouncingScrollPhysics(),
      children: [
        ScreenWidth(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 105),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 43, height: 43,
                decoration: BoxDecoration(color: Palette.tealSoft,
                  borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.medical_services_outlined,
                  color: Palette.forest, size: 23)),
              const SizedBox(width: 11),
              const Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('MediSuivi', style: TextStyle(
                    fontSize: 19, fontWeight: FontWeight.w700, letterSpacing: -.35)),
                  SizedBox(height: 2),
                  Text('Espace clinique personnel', style: TextStyle(
                    fontSize: 13.5, color: Palette.muted)),
                ])),
              IconButton(
                tooltip: 'Paramètres',
                style: IconButton.styleFrom(backgroundColor: Palette.white,
                  side: const BorderSide(color: Palette.border)),
                icon: const Icon(Icons.tune_rounded),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SettingsScreen())),
              ),
            ]),
            const SizedBox(height: 25),
            Text(shortDate(DateTime.now()),
              style: const TextStyle(fontSize: 14, color: Palette.muted)),
            const SizedBox(height: 6),
            const Text('Suivi des patients', style: TextStyle(
              fontSize: 27, letterSpacing: -.6,
              fontWeight: FontWeight.w700, height: 1.18)),
            const SizedBox(height: 6),
            const Text('Vos dossiers et vos prochaines actions.',
              style: TextStyle(fontSize: 14, color: Palette.muted)),
            const SizedBox(height: 20),
            EntranceReveal(child: _Summary(
              total: patients.length,
              onAdd: addPatient, onPatients: onPatients)),
            const SizedBox(height: 26),
            const SectionHeading(title: 'À consulter'),
            const SizedBox(height: 11),
            Row(children: [
              Expanded(child: _QuickStat(
                number: toReview, label: 'Patients à revoir',
                icon: Icons.event_repeat_rounded, onTap: onFollowup)),
              const SizedBox(width: 11),
              Expanded(child: _QuickStat(
                number: pending, label: 'Bilans en attente',
                icon: Icons.biotech_outlined, onTap: onExams)),
            ]),
            if (nextVisit != null) ...[
              const SizedBox(height: 23),
              SectionHeading(title: 'Prochaine visite',
                trailing: 'Calendrier', onTap: onFollowup),
              const SizedBox(height: 10),
              Material(
                color: Palette.white,
                borderRadius: BorderRadius.circular(17),
                child: InkWell(
                  onTap: onFollowup,
                  borderRadius: BorderRadius.circular(17),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15, vertical: 13),
                    decoration: BoxDecoration(
                      border: Border.all(color: Palette.border),
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: Row(children: [
                      const SoftIcon(icon: Icons.event_available_outlined),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(store.patientById(nextVisit.patientId)?.name ??
                            'Patient inconnu',
                            style: const TextStyle(
                              fontSize: 14.5, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(nextVisit.reason,
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14, color: Palette.muted)),
                          const SizedBox(height: 4),
                          Text('${shortDate(nextVisit.scheduledAt)} · '
                            '${nextVisit.scheduledAt.hour.toString().padLeft(2, '0')}:'
                            '${nextVisit.scheduledAt.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              fontSize: 12.5, color: Palette.forest,
                              fontWeight: FontWeight.w600)),
                        ],
                      )),
                      const Icon(Icons.chevron_right_rounded,
                        color: Palette.muted),
                    ]),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 27),
            SectionHeading(title: 'Dossiers récents',
              trailing: 'Voir tout', onTap: onPatients),
            const SizedBox(height: 11),
            if (patients.isEmpty)
              const EmptyResults(
                title: 'Aucun patient',
                detail: 'Ajoutez votre premier dossier.')
            else Container(
              decoration: BoxDecoration(
                color: Palette.white,
                borderRadius: BorderRadius.circular(19),
                border: Border.all(color: Palette.border)),
              child: Column(children: [
                for (var i = 0; i < patients.take(3).length; i++) ...[
                  _RecentPatient(patient: patients[i],
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) =>
                        PatientDetailScreen(patientId: patients[i].id)))),
                  if (i < patients.take(3).length - 1)
                    const Divider(height: 1, indent: 70, endIndent: 16),
                ],
              ]),
            ),

          ]),
        ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.total,
    required this.onAdd,
    required this.onPatients,
  });

  final int total;
  final VoidCallback onAdd;
  final VoidCallback onPatients;

  // Décompression unique de la photo fictive embarquée, y compris hors ligne.
  static final _photoBytes = base64Decode(clinicalHeroPhotoWebpBase64);

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(22),
    child: Stack(
      children: [
        const Positioned.fill(
          child: ColoredBox(color: Palette.navy),
        ),
        // Image à droite. On garde les textes et actions indépendants.
        Positioned(
          top: 0,
          right: 0,
          bottom: 0,
          width: 205,
          child: Image.memory(
            _photoBytes,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.medium,
            excludeFromSemantics: true,
          ),
        ),
        // Gauche opaque pour les chiffres, droite plus photographique.
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                stops: [0, .35, .68, 1],
                colors: [
                  Palette.navy,
                  Palette.navy,
                  Color(0x86193F34),
                  Color(0x0C193F34),
                ],
              ),
            ),
          ),
        ),
        // Bande inférieure foncée pour les boutons et le séparateur.
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0, .48, .78, 1],
                colors: [
                  Color(0x00193F34),
                  Color(0x00193F34),
                  Color(0x7D193F34),
                  Palette.navy,
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.folder_shared_outlined,
                    color: Palette.white, size: 19),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text('MES DOSSIERS',
                      style: TextStyle(
                        color: Palette.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: .7,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$total', style: const TextStyle(
                          color: Palette.white, fontSize: 43,
                          height: 1, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        const Text('patients enregistrés',
                          maxLines: 2,
                          style: TextStyle(
                            color: Palette.white, fontSize: 14)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 105, height: 95),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(height: 1, color: Color(0x5CFFFFFF)),
              const SizedBox(height: 17),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: ElevatedButton.icon(
                        onPressed: onAdd,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Palette.white,
                          foregroundColor: Palette.navy,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: const Text('Nouveau patient',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 47,
                    height: 46,
                    child: IconButton(
                      tooltip: 'Mes dossiers',
                      onPressed: onPatients,
                      style: IconButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0x5CFFFFFF)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      icon: const Icon(Icons.arrow_forward_rounded,
                        color: Palette.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _QuickStat extends StatelessWidget {
  const _QuickStat({required this.number, required this.label,
    required this.icon, required this.onTap});
  final int number;
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Palette.white,
    borderRadius: BorderRadius.circular(19),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(19),
      child: Container(
        padding: const EdgeInsets.fromLTRB(15, 16, 13, 17),
        constraints: const BoxConstraints(minHeight: 134),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(19),
          border: Border.all(color: Palette.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 22, color: Palette.forest),
            const Spacer(),
            const Icon(Icons.arrow_outward_rounded,
              size: 19, color: Palette.muted),
          ]),
          const SizedBox(height: 17),
          Text('$number', style: const TextStyle(
            fontSize: 27, fontWeight: FontWeight.w700, height: 1)),
          const SizedBox(height: 7),
          Text(label, maxLines: 2, style: const TextStyle(
            color: Palette.ink, fontSize: 13, fontWeight: FontWeight.w500)),
        ]),
      ),
    ),
  );
}

class _RecentPatient extends StatelessWidget {
  const _RecentPatient({required this.patient, required this.onTap});
  final Patient patient;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 13, 14),
      child: Row(children: [
        PatientAvatar(patient: patient, size: 44, hero: true),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(patient.name, maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('${patient.id} · ${patient.age} ans',
              style: const TextStyle(
                fontSize: 13.5, color: Palette.muted)),
          ])),
        if (patient.followUp) const Icon(
          Icons.event_repeat_rounded, size: 18, color: Palette.forest),
        const Icon(Icons.chevron_right_rounded,
          color: Palette.muted, size: 22),
      ]),
    ),
  );
}
