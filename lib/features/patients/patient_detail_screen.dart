import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../core/models/medical_models.dart';
import '../../core/models/clinical_intake.dart';
import '../consultations/consultation_detail_screen.dart';
import '../../core/state/store_context.dart';
import '../../core/widgets/medical_ui.dart';
import '../consultations/new_consultation_screen.dart';
import '../exams/exam_editor_screen.dart';
import '../exams/exam_detail_screen.dart';
import '../followup/followup_editor_screen.dart';
import 'patient_medical_info_screen.dart';

class PatientDetailScreen extends StatefulWidget {
  const PatientDetailScreen({super.key, required this.patientId});
  final String patientId;

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  int _section = 0;

  Widget _navigation() {
    const labels = <(String, IconData)>[
      ('Dossier', Icons.person_outline_rounded),
      ('Consultations', Icons.medical_services_outlined),
      ('Bilans', Icons.biotech_outlined),
      ('Suivi', Icons.event_repeat_rounded),
    ];
    final palette = Palette.of(context);
    return SizedBox(
      height: 45,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(labels.length, (index) {
            final selected = _section == index;
            return Padding(
              padding: const EdgeInsets.only(right: 7),
              child: ChoiceChip(
                key: Key('patient-tab-$index'),
                selected: selected,
                showCheckmark: false,
                avatar: Icon(labels[index].$2, size: 17,
                  color: selected ? palette.forest : palette.muted),
                label: Text(labels[index].$1),
                labelStyle: TextStyle(fontSize: 12.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? palette.forest : palette.ink),
                onSelected: (_) => setState(() => _section = index),
              ),
            );
          }),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final patientId = widget.patientId;
    final store = context.store;
    final Patient? patient = store.patientById(patientId);
    if (patient == null) return const Scaffold(body: Center(child: Text('Dossier introuvable.')));
    final List<Visit> visits = List<Visit>.from(store.visitsFor(patient.id));
    final List<LabExam> exams = List<LabExam>.from(store.examsFor(patient.id));
    final last = visits.isEmpty ? null : visits.first;
    final pending = exams.where((e) => e.status == ExamStatus.pending).length;
    final planned = List<FollowUpPlan>.from(store.followUpsFor(patient.id))
      .where((plan) => plan.isPlanned).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Dossier médical')),
      body: SafeArea(child: ListView(
        physics: const BouncingScrollPhysics(),
        children: [ScreenWidth(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 34),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          EntranceReveal(
            child: _PatientProfileHeader(patient: patient),
          ),
          const SizedBox(height: 16),
          Center(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ElevatedButton.icon(
                  key: const Key('new-consultation-cta'),
                  onPressed: () => Navigator.push(context,
                    MaterialPageRoute<void>(builder: (_) =>
                      NewConsultationScreen(patient: patient))),
                  icon: const Icon(Icons.add_rounded, size: 19),
                  label: const Text('Consultation'),
                ),
                SizedBox(width: 46, height: 46, child: IconButton.outlined(
                  tooltip: 'Prescrire un bilan',
                  icon: const Icon(Icons.biotech_outlined),
                  onPressed: () => Navigator.push(context,
                    MaterialPageRoute<void>(builder: (_) =>
                      ExamEditorScreen(patientId: patientId))),
                )),
              ],
            ),
          ),
          const SizedBox(height: 13),
          SurfaceCard(
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
            child: Row(children: [
              Expanded(child: _CountCard(count: visits.length, label: 'Consultations')),
              _MetricRule(),
              Expanded(child: _CountCard(count: exams.length, label: 'Bilans')),
              _MetricRule(),
              Expanded(child: _CountCard(count: pending, label: 'En attente')),
            ]),
          ),
          const SizedBox(height: 16),
          _navigation(),
          const SizedBox(height: 18),
          if (_section == 0) ...[
          const SectionHeading(title: 'Dernières constantes'),
          const SizedBox(height: 8),
          if (last == null)
            SurfaceCard(child: Text('Aucune mesure enregistrée.', style: TextStyle(color: Palette.of(context).muted)))
          else SurfaceCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(shortDate(last.date), style: TextStyle(color: Palette.of(context).muted, fontSize: 12)),
            const SizedBox(height: 13),
            Row(children: [
              Expanded(child: _Vital(label: 'Température', value: last.temperature == null ? '—' : '${last.temperature!.toStringAsFixed(1)} °C', icon: Icons.thermostat_rounded)),
              Expanded(child: _Vital(label: 'Tension', value: last.systolic == null || last.diastolic == null ? '—' : '${last.systolic}/${last.diastolic}', icon: Icons.monitor_heart_outlined)),
            ]),
            const Divider(height: 19),
            Row(children: [
              Expanded(child: _Vital(label: 'Pouls', value: last.pulse == null ? '—' : '${last.pulse} bpm', icon: Icons.favorite_border_rounded)),
              Expanded(child: _Vital(label: 'SpO₂', value: last.spo2 == null ? '—' : '${last.spo2} %', icon: Icons.air_rounded)),
            ]),
          ])),
          const SizedBox(height: 16),
          SectionHeading(title: 'Informations médicales', trailing: 'Modifier',
            onTap: () async {
              await Navigator.push(context, MaterialPageRoute<void>(
                builder: (_) => PatientMedicalInfoScreen(patient: patient)));
              if (mounted) setState(() {});
            }),
          const SizedBox(height: 8),
          SurfaceCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: _Fact(label: 'Sexe', value: switch (patient.sex) {
                'F' => 'Féminin', 'M' => 'Masculin', _ => 'Non précisé' })),
              Expanded(child: _Fact(label: 'Téléphone', value: patient.phone)),
            ]),
            const Divider(height: 28),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: _Fact(label: 'Antécédents médicaux',
                value: patient.medicalHistory)),
              const SizedBox(width: 12),
              Expanded(child: _Fact(label: 'Allergies connues',
                value: patient.allergies)),
            ]),
          ])),
          const SizedBox(height: 14),
          FutureBuilder<PatientProfileSupplement?>(
            future: store.patientProfile(patient.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.all(14),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return const SurfaceCard(child:
                  Text('Complément du dossier indisponible.'));
              }
              final extra = snapshot.data;
              if (extra == null) return const SizedBox.shrink();
              final entries = <MapEntry<String, String>>[
                MapEntry('Quartier', extra.neighborhood),
                MapEntry('Adresse', extra.address),
                MapEntry("Contact d'urgence", extra.emergencyContactName),
                MapEntry("Téléphone d'urgence", extra.emergencyContactPhone),
                MapEntry('Traitements habituels', extra.currentMedications),
                MapEntry('Antécédents chirurgicaux', extra.surgicalHistory),
                MapEntry('Antécédents familiaux', extra.familyHistory),
              ].where((item) => item.value.trim().isNotEmpty).toList();
              if (entries.isEmpty) return const SizedBox.shrink();
              return SizedBox(
                width: double.infinity,
                child: SurfaceCard(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Coordonnées et antécédents',
                      style: TextStyle(fontWeight: FontWeight.w700,
                        fontSize: 14.5, color: Palette.of(context).ink)),
                    const SizedBox(height: 12),
                    for (var i = 0; i < entries.length; i++) ...[
                      _Fact(label: entries[i].key, value: entries[i].value),
                      if (i < entries.length - 1)
                        const Divider(height: 22),
                    ],
                  ],
                )),
              );
            },
          ),
          ],
          if (_section == 1) ...[
          SectionHeading(title: 'Historique des consultations',
            trailing: 'Ajouter', onTap: () => Navigator.push(context,
              MaterialPageRoute<void>(builder: (_) =>
                NewConsultationScreen(patient: patient)))),
          const SizedBox(height: 10),
          if (visits.isEmpty) const SurfaceCard(child: Text('Aucune consultation.'))
          else SurfaceCard(child: Column(children: [
            for (var i = 0; i < visits.length; i++) ...[
              _VisitLine(
                visit: visits[i],
                onTap: () => Navigator.push(context, MaterialPageRoute<void>(
                  builder: (_) => ConsultationDetailScreen(visit: visits[i]),
                )),
              ),
              if (i < visits.length - 1) const Divider(height: 22),
            ],
          ])),
          ],
          if (_section == 2) ...[
          SectionHeading(title: 'Bilans et examens',
            trailing: 'Prescrire', onTap: () => Navigator.push(context,
              MaterialPageRoute<void>(builder: (_) =>
                ExamEditorScreen(patientId: patientId)))),
          const SizedBox(height: 10),
          if (exams.isEmpty) const SurfaceCard(child: Text('Aucun examen prescrit.'))
          else SurfaceCard(child: Column(children: [
            for (var i = 0; i < exams.length; i++) ...[
              _ExamLine(
                exam: exams[i],
                onOpen: () => Navigator.push(context,
                  MaterialPageRoute<void>(builder: (_) =>
                    ExamDetailScreen(examId: exams[i].id))),
                onResult: () => Navigator.push(context,
                  MaterialPageRoute<void>(builder: (_) =>
                    ExamEditorScreen(patientId: patientId, exam: exams[i]))),
              ),
              if (i < exams.length - 1) const Divider(height: 22),
            ],
          ])),
          ],
          if (_section == 3) ...[
          SectionHeading(title: 'Suivi du patient', trailing: 'Programmer',
            onTap: () => Navigator.push(context, MaterialPageRoute<void>(
              builder: (_) => FollowUpEditorScreen(patientId: patientId)))),
          const SizedBox(height: 11),
          SurfaceCard(child: Column(children: [
            Row(children: [
              const SoftIcon(icon: Icons.event_repeat_rounded),
              const SizedBox(width: 11),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Patient à revoir', style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600)),
                  SizedBox(height: 5),
                  Text('Signaler un besoin de suivi.',
                    style: TextStyle(color: Palette.of(context).muted, fontSize: 12.5)),
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
                  Icon(Icons.event_available_outlined,
                    color: Palette.of(context).forest, size: 19),
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
                        style: TextStyle(
                          color: Palette.of(context).muted, fontSize: 13)),
                    ],
                  )),
                  IconButton(
                    tooltip: 'Modifier le rendez-vous',
                    icon: Icon(Icons.edit_calendar_outlined,
                      color: Palette.of(context).forest),
                    onPressed: () => Navigator.push(context,
                      MaterialPageRoute<void>(builder: (_) =>
                        FollowUpEditorScreen(plan: plan))),
                  ),
                ]),
                const SizedBox(height: 8),
              ],
            ],
          ])),
          ],
        ]))])),
    );
  }
}

/// Couverture compacte du dossier : identité centrée sans carte latérale.
class _PatientProfileHeader extends StatelessWidget {
  const _PatientProfileHeader({required this.patient});

  final Patient patient;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final sex = switch (patient.sex) {
      'F' => 'Féminin',
      'M' => 'Masculin',
      _ => 'Non précisé',
    };
    return SizedBox(
      key: const Key('patient-profile-header'),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            key: const Key('patient-profile-avatar'),
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.tealSoft,
              border: Border.all(color: palette.border, width: 1.25),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.person_rounded, size: 36,
              color: palette.forest),
          ),
          const SizedBox(height: 10),
          Text(
            patient.name,
            key: const Key('patient-profile-name'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              height: 1.2,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.55,
              color: palette.ink,
            ),
          ),
          const SizedBox(height: 5),
          Text('${patient.age} ans  ·  $sex',
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.muted, fontSize: 12.5)),
          const SizedBox(height: 3),
          Text('Dossier ${patient.id}',
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.muted, fontSize: 11.5)),
          if (patient.followUp) ...[
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 5,
              children: [
                Icon(Icons.event_repeat_rounded, size: 15,
                  color: palette.forest),
                Text('Visite de suivi à prévoir',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: palette.forest,
                    fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricRule extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1, height: 36, color: Palette.of(context).border,
  );
}

class _CountCard extends StatelessWidget {
  const _CountCard({required this.count, required this.label});
  final int count;
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 5),
    child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Text('$count', style: TextStyle(
        fontSize: 19, fontWeight: FontWeight.w700,
        color: Palette.of(context).ink)),
      const SizedBox(height: 3),
      Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 10.5,
          color: Palette.of(context).muted)),
    ]),
  );
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: TextStyle(fontSize: 12, color: Palette.of(context).muted)),
    const SizedBox(height: 5),
    Text(value, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
  ]);
}

class _Vital extends StatelessWidget {
  const _Vital({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [Icon(icon, size: 16, color: Palette.of(context).teal), const SizedBox(width: 6),
      Flexible(child: Text(label, style: TextStyle(fontSize: 13, color: Palette.of(context).muted)))]),
    const SizedBox(height: 5),
    Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
  ]);
}

class _VisitLine extends StatelessWidget {
  const _VisitLine({required this.visit, required this.onTap});
  final Visit visit;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const SoftIcon(icon: Icons.medical_services_outlined),
    const SizedBox(width: 12),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(visit.reason, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      const SizedBox(height: 5),
      Text(shortDate(visit.date), style: TextStyle(fontSize: 13, color: Palette.of(context).muted)),
      if (visit.notes.isNotEmpty) ...[
        const SizedBox(height: 7),
        Text(visit.notes, style: TextStyle(fontSize: 13, color: Palette.of(context).muted)),
      ],
    ])),
    Icon(Icons.chevron_right_rounded, size: 20,
      color: Palette.of(context).muted),
  ]),
    ),
  );
}

class _ExamLine extends StatelessWidget {
  const _ExamLine({
    required this.exam,
    required this.onOpen,
    required this.onResult,
  });

  final LabExam exam;
  final VoidCallback onOpen;
  final VoidCallback onResult;

  @override
  Widget build(BuildContext context) {
    final ready = exam.status == ExamStatus.complete;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SoftIcon(
              icon: ready
                ? Icons.description_outlined : Icons.biotech_outlined,
              color: Palette.of(context).forest,
              background: ready ? Palette.of(context).tealSoft : Palette.of(context).blueSoft,
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exam.title, style: TextStyle(
                  fontSize: 16, height: 1.35,
                  fontWeight: FontWeight.w600, color: Palette.of(context).ink)),
                const SizedBox(height: 6),
                Text(shortDate(exam.date), style: TextStyle(
                  fontSize: 13.5, color: Palette.of(context).muted)),
                const SizedBox(height: 7),
                Text(
                  ready ? 'Résultat disponible' : 'Résultat en attente',
                  style: TextStyle(
                    fontSize: 14, height: 1.35,
                    fontWeight: FontWeight.w600,
                    color: Palette.of(context).forest),
                ),
                if (ready && exam.result?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Text(
                    exam.result!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14, height: 1.45,
                      color: Palette.of(context).ink),
                  ),
                ],
                const SizedBox(height: 9),
                OutlinedButton.icon(
                  onPressed: ready ? onOpen : onResult,
                  icon: Icon(ready
                    ? Icons.visibility_outlined : Icons.edit_note_rounded,
                    size: 19),
                  label: Text(ready
                    ? 'Voir le résultat' : 'Saisir le résultat'),
                ),
              ],
            )),
            Icon(Icons.chevron_right_rounded,
              color: Palette.of(context).forest, size: 22),
          ],
        ),
      ),
    );
  }
}
