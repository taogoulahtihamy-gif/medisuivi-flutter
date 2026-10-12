import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../core/models/medical_models.dart';
import '../../core/state/demo_store.dart';
import '../../core/widgets/medical_ui.dart';
import '../consultations/new_consultation_screen.dart';
import '../exams/exam_editor_screen.dart';
import '../followup/followup_editor_screen.dart';
import 'patient_medical_info_screen.dart';

class PatientDetailScreen extends StatelessWidget {
  const PatientDetailScreen({super.key, required this.patientId});
  final String patientId;

  @override
  Widget build(BuildContext context) {
    final store = DemoScope.of(context);
    final patient = store.patientById(patientId);
    if (patient == null) return const Scaffold(body: Center(child: Text('Dossier introuvable.')));
    final visits = store.visitsFor(patient.id);
    final exams = store.examsFor(patient.id);
    final last = visits.isEmpty ? null : visits.first;
    final pending = exams.where((e) => e.status == ExamStatus.pending).length;
    final planned = store.followUpsFor(patient.id)
      .where((plan) => plan.isPlanned).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Dossier médical')),
      body: SafeArea(child: ListView(children: [ScreenWidth(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          EntranceReveal(child: Container(
            padding: const EdgeInsets.all(19),
            decoration: BoxDecoration(
              color: Palette.white,
              border: Border.all(color: Palette.border),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(children: [
              PatientAvatar(patient: patient, size: 68, hero: true),
              const SizedBox(width: 15),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(patient.name,
                    style: const TextStyle(fontSize: 21,
                      color: Palette.ink, fontWeight: FontWeight.w700,
                      letterSpacing: -.6)),
                  const SizedBox(height: 6),
                  Text('${patient.id} · ${patient.age} ans',
                    style: const TextStyle(
                      color: Palette.muted, fontSize: 12.5)),
                  if (patient.followUp) ...[
                    const SizedBox(height: 8),
                    const Text('Visite de suivi à prévoir',
                      style: TextStyle(color: Palette.muted,
                        fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ],
                ],
              )),
            ]),
          )),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(child: SizedBox(height: 48, child: ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute<void>(
                builder: (_) => NewConsultationScreen(patient: patient))),
              icon: const Icon(Icons.add_rounded, size: 19),
              label: const Text('Nouvelle consultation',
                maxLines: 1, overflow: TextOverflow.ellipsis),
            ))),
            const SizedBox(width: 9),
            SizedBox(height: 48, width: 49, child: IconButton.outlined(
              tooltip: 'Prescrire un bilan',
              icon: const Icon(Icons.biotech_outlined),
              onPressed: () => Navigator.push(context, MaterialPageRoute<void>(
                builder: (_) => ExamEditorScreen(patientId: patientId))),
            )),
          ]),
          const SizedBox(height: 26),
          Row(children: [
            Expanded(child: _CountCard(count: visits.length, label: 'Consultations')),
            const SizedBox(width: 9),
            Expanded(child: _CountCard(count: exams.length, label: 'Bilans')),
            const SizedBox(width: 9),
            Expanded(child: _CountCard(count: pending, label: 'En attente')),
          ]),
          const SizedBox(height: 26),
          SectionHeading(title: 'Informations médicales', trailing: 'Modifier',
            onTap: () => Navigator.push(context, MaterialPageRoute<void>(
              builder: (_) => PatientMedicalInfoScreen(patient: patient)))),
          const SizedBox(height: 11),
          SurfaceCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: _Fact(label: 'Sexe', value: switch (patient.sex) {
                'F' => 'Féminin', 'M' => 'Masculin', _ => 'Non précisé' })),
              Expanded(child: _Fact(label: 'Téléphone', value: patient.phone)),
            ]),
            const Divider(height: 28),
            _Fact(label: 'Antécédents médicaux', value: patient.medicalHistory),
            const Divider(height: 28),
            _Fact(label: 'Allergies connues', value: patient.allergies),
          ])),
          const SizedBox(height: 26),
          const SectionHeading(title: 'Dernières constantes'),
          const SizedBox(height: 11),
          if (last == null)
            const SurfaceCard(child: Text('Aucune mesure enregistrée.', style: TextStyle(color: Palette.muted)))
          else SurfaceCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(shortDate(last.date), style: const TextStyle(color: Palette.muted, fontSize: 12)),
            const SizedBox(height: 13),
            Row(children: [
              Expanded(child: _Vital(label: 'Température', value: last.temperature == null ? '—' : '${last.temperature!.toStringAsFixed(1)} °C', icon: Icons.thermostat_rounded)),
              Expanded(child: _Vital(label: 'Tension', value: last.systolic == null || last.diastolic == null ? '—' : '${last.systolic}/${last.diastolic}', icon: Icons.monitor_heart_outlined)),
            ]),
            const Divider(height: 27),
            Row(children: [
              Expanded(child: _Vital(label: 'Pouls', value: last.pulse == null ? '—' : '${last.pulse} bpm', icon: Icons.favorite_border_rounded)),
              Expanded(child: _Vital(label: 'SpO₂', value: last.spo2 == null ? '—' : '${last.spo2} %', icon: Icons.air_rounded)),
            ]),
          ])),
          const SizedBox(height: 25),
          SectionHeading(title: 'Historique des consultations',
            trailing: 'Ajouter', onTap: () => Navigator.push(context,
              MaterialPageRoute<void>(builder: (_) =>
                NewConsultationScreen(patient: patient)))),
          const SizedBox(height: 10),
          if (visits.isEmpty) const SurfaceCard(child: Text('Aucune consultation.'))
          else SurfaceCard(child: Column(children: [
            for (var i = 0; i < visits.length; i++) ...[
              _VisitLine(visit: visits[i]),
              if (i < visits.length - 1) const Divider(height: 22),
            ],
          ])),
          const SizedBox(height: 25),
          SectionHeading(title: 'Bilans et examens',
            trailing: 'Prescrire', onTap: () => Navigator.push(context,
              MaterialPageRoute<void>(builder: (_) =>
                ExamEditorScreen(patientId: patientId)))),
          const SizedBox(height: 10),
          if (exams.isEmpty) const SurfaceCard(child: Text('Aucun examen prescrit.'))
          else SurfaceCard(child: Column(children: [
            for (var i = 0; i < exams.length; i++) ...[
              _ExamLine(exam: exams[i],
                onResult: () => Navigator.push(context,
                  MaterialPageRoute<void>(builder: (_) =>
                    ExamEditorScreen(patientId: patientId, exam: exams[i])))),
              if (i < exams.length - 1) const Divider(height: 22),
            ],
          ])),
          const SizedBox(height: 26),
          SectionHeading(title: 'Suivi du patient', trailing: 'Programmer',
            onTap: () => Navigator.push(context, MaterialPageRoute<void>(
              builder: (_) => FollowUpEditorScreen(patientId: patientId)))),
          const SizedBox(height: 11),
          SurfaceCard(child: Column(children: [
            Row(children: [
              const SoftIcon(icon: Icons.event_repeat_rounded),
              const SizedBox(width: 11),
              const Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Patient à revoir', style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600)),
                  SizedBox(height: 5),
                  Text('Signaler un besoin de suivi.',
                    style: TextStyle(color: Palette.muted, fontSize: 12.5)),
                ],
              )),
              Switch.adaptive(value: patient.followUp,
                onChanged: (value) => store.setFollowUp(
                  patientId, toReview: value)),
            ]),
            if (planned.isNotEmpty) ...[
              const Divider(height: 23),
              for (final plan in planned) ...[
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.event_available_outlined,
                    color: Palette.forest, size: 19),
                  const SizedBox(width: 9),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(plan.reason, style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('${shortDate(plan.scheduledAt)} · '
                        '${plan.scheduledAt.hour.toString().padLeft(2, '0')}:'
                        '${plan.scheduledAt.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          color: Palette.muted, fontSize: 13)),
                    ],
                  )),
                  IconButton(
                    tooltip: 'Modifier le rendez-vous',
                    icon: const Icon(Icons.edit_calendar_outlined,
                      color: Palette.forest),
                    onPressed: () => Navigator.push(context,
                      MaterialPageRoute<void>(builder: (_) =>
                        FollowUpEditorScreen(plan: plan))),
                  ),
                ]),
                const SizedBox(height: 8),
              ],
            ],
          ])),
        ]))])),
    );
  }
}

class _CountCard extends StatelessWidget {
  const _CountCard({required this.count, required this.label});
  final int count;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 83),
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
    decoration: BoxDecoration(color: Palette.tealSoft,
      borderRadius: BorderRadius.circular(15)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('$count', style: const TextStyle(
        fontSize: 23, fontWeight: FontWeight.w700, color: Palette.ink)),
      const SizedBox(height: 5),
      Text(label, maxLines: 2, style: const TextStyle(
        fontSize: 12.5, height: 1.2, color: Palette.muted)),
    ]),
  );
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(fontSize: 13, color: Palette.muted)),
    const SizedBox(height: 7),
    Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
  ]);
}

class _Vital extends StatelessWidget {
  const _Vital({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [Icon(icon, size: 16, color: Palette.teal), const SizedBox(width: 6),
      Flexible(child: Text(label, style: const TextStyle(fontSize: 13, color: Palette.muted)))]),
    const SizedBox(height: 7),
    Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
  ]);
}

class _VisitLine extends StatelessWidget {
  const _VisitLine({required this.visit});
  final Visit visit;
  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const SoftIcon(icon: Icons.medical_services_outlined),
    const SizedBox(width: 12),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(visit.reason, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      const SizedBox(height: 5),
      Text(shortDate(visit.date), style: const TextStyle(fontSize: 13, color: Palette.muted)),
      if (visit.notes.isNotEmpty) ...[
        const SizedBox(height: 7),
        Text(visit.notes, style: const TextStyle(fontSize: 13, color: Palette.muted)),
      ],
    ])),
  ]);
}

class _ExamLine extends StatelessWidget {
  const _ExamLine({required this.exam, required this.onResult});
  final LabExam exam;
  final VoidCallback onResult;
  @override
  Widget build(BuildContext context) {
    final ready = exam.status == ExamStatus.complete;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SoftIcon(icon: Icons.biotech_outlined,
        color: ready ? Palette.teal : Palette.laser,
        background: ready ? Palette.tealSoft : Palette.amberSoft),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(exam.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 5),
        Text(ready ? 'Résultat disponible' : 'Résultat en attente', style: TextStyle(
          fontSize: 12, color: ready ? Palette.teal : Palette.laser)),
        if (ready && exam.result != null) ...[
          const SizedBox(height: 6),
          Text(exam.result!, style: const TextStyle(fontSize: 13, color: Palette.muted)),
        ],
        if (!ready) ...[
          const SizedBox(height: 9),
          OutlinedButton.icon(
            onPressed: onResult,
            icon: const Icon(Icons.edit_note_rounded, size: 18),
            label: const Text('Saisir le résultat'),
          ),
        ],
      ])),
    ]);
  }
}
