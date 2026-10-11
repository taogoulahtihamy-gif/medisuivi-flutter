import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../core/models/medical_models.dart';
import '../../core/state/demo_store.dart';
import '../../core/widgets/medical_ui.dart';
import '../consultations/new_consultation_screen.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('Dossier patient')),
      body: SafeArea(child: ListView(children: [ScreenWidth(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          EntranceReveal(child: Container(
            padding: const EdgeInsets.all(19),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Palette.charcoal, Palette.charcoalSoft],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(children: [
              PatientAvatar(patient: patient, size: 68, hero: true),
              const SizedBox(width: 15),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(patient.name,
                    style: const TextStyle(fontSize: 22,
                      color: Colors.white, fontWeight: FontWeight.w800,
                      letterSpacing: -.6)),
                  const SizedBox(height: 6),
                  Text('${patient.id} · ${patient.age} ans',
                    style: const TextStyle(
                      color: Color(0xFFE8FFF2), fontSize: 12.5)),
                  if (patient.followUp) ...[
                    const SizedBox(height: 8),
                    const Text('Visite de suivi à prévoir',
                      style: TextStyle(color: Color(0xFFD4F6E2),
                        fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ],
              )),
            ]),
          )),
          const SizedBox(height: 18),
          const DemoNotice(compact: true),
          const SizedBox(height: 17),
          SizedBox(width: double.infinity, child: ElevatedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute<void>(
              builder: (_) => NewConsultationScreen(patient: patient))),
            icon: const Icon(Icons.add_rounded), label: const Text('Nouvelle consultation démo'))),
          const SizedBox(height: 26),
          const SectionHeading(title: 'Informations générales'),
          const SizedBox(height: 11),
          SurfaceCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: _Fact(label: 'Sexe', value: switch (patient.sex) {
                'F' => 'Féminin', 'M' => 'Masculin', _ => 'Non précisé' })),
              Expanded(child: _Fact(label: 'Téléphone', value: patient.phone)),
            ]),
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
          SectionHeading(title: 'Historique des consultations', trailing: '${visits.length} visite(s)'),
          const SizedBox(height: 10),
          if (visits.isEmpty) const SurfaceCard(child: Text('Aucune consultation.'))
          else SurfaceCard(child: Column(children: [
            for (var i = 0; i < visits.length; i++) ...[
              _VisitLine(visit: visits[i]),
              if (i < visits.length - 1) const Divider(height: 22),
            ],
          ])),
          const SizedBox(height: 25),
          SectionHeading(title: 'Bilans et examens', trailing: '${exams.length} bilan(s)'),
          const SizedBox(height: 10),
          if (exams.isEmpty) const SurfaceCard(child: Text('Aucun examen prescrit.'))
          else SurfaceCard(child: Column(children: [
            for (var i = 0; i < exams.length; i++) ...[
              _ExamLine(exam: exams[i]),
              if (i < exams.length - 1) const Divider(height: 22),
            ],
          ])),
        ]))])),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(fontSize: 12, color: Palette.muted)),
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
      Flexible(child: Text(label, style: const TextStyle(fontSize: 12, color: Palette.muted)))]),
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
      Text(shortDate(visit.date), style: const TextStyle(fontSize: 12, color: Palette.muted)),
      if (visit.notes.isNotEmpty) ...[
        const SizedBox(height: 7),
        Text(visit.notes, style: const TextStyle(fontSize: 12, color: Palette.muted)),
      ],
    ])),
  ]);
}

class _ExamLine extends StatelessWidget {
  const _ExamLine({required this.exam});
  final LabExam exam;
  @override
  Widget build(BuildContext context) {
    final ready = exam.status == ExamStatus.complete;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SoftIcon(icon: Icons.biotech_outlined,
        color: ready ? Palette.teal : const Color(0xFF966328),
        background: ready ? Palette.tealSoft : Palette.amberSoft),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(exam.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 5),
        Text(ready ? 'Résultat disponible' : 'Résultat en attente', style: TextStyle(
          fontSize: 12, color: ready ? Palette.teal : const Color(0xFF966328))),
        if (ready && exam.result != null) ...[
          const SizedBox(height: 6),
          Text(exam.result!, style: const TextStyle(fontSize: 12, color: Palette.muted)),
        ],
      ])),
    ]);
  }
}
