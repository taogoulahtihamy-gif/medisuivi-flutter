import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../core/models/medical_models.dart';
import '../../core/state/demo_store.dart';
import '../../core/widgets/medical_ui.dart';
import '../patients/patient_detail_screen.dart';

class ExamsScreen extends StatefulWidget {
  const ExamsScreen({super.key});
  @override
  State<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends State<ExamsScreen> {
  ExamStatus? filter;
  @override
  Widget build(BuildContext context) {
    final store = DemoScope.of(context);
    final exams = store.exams
        .where((e) => filter == null || e.status == filter)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return ListView(children: [
      ScreenWidth(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const PageTitle(
            title: 'Bilans et examens',
            subtitle: 'Retrouvez chaque prescription et son résultat.'),
        const SizedBox(height: 24),
        AnimatedSection(
            child: MedicalHeader(
                eyebrow: 'Examens prescrits',
                title: '${store.exams.length} examens enregistrés',
                description:
                    '${store.exams.where((e) => e.status == ExamStatus.pending).length} en attente de résultat. Les valeurs sont présentées sans interprétation médicale.',
                icon: Icons.science_outlined)),
        const SizedBox(height: 20),
        Wrap(spacing: 8, runSpacing: 8, children: [
          ChoiceChip(
              label: const Text('Tous'),
              selected: filter == null,
              onSelected: (_) => setState(() => filter = null)),
          ChoiceChip(
              label: const Text('En attente'),
              selected: filter == ExamStatus.pending,
              onSelected: (_) => setState(() => filter = ExamStatus.pending)),
          ChoiceChip(
              label: const Text('Disponibles'),
              selected: filter == ExamStatus.complete,
              onSelected: (_) => setState(() => filter = ExamStatus.complete)),
        ]),
        const SizedBox(height: 20),
        if (exams.isEmpty)
          const EmptyState(
              title: 'Aucun examen',
              detail: 'Aucun examen ne correspond à ce filtre.',
              icon: Icons.science_outlined),
        for (final exam in exams)
          Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PremiumCard(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                          builder: (_) =>
                              PatientDetailScreen(patientId: exam.patientId))),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const SoftIcon(icon: Icons.science_outlined),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(exam.title,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(height: 4),
                                Text(
                                    store.patientById(exam.patientId)?.name ??
                                        'Dossier indisponible',
                                    style:
                                        const TextStyle(color: Palette.muted)),
                              ])),
                          const Icon(Icons.chevron_right_rounded,
                              color: Palette.muted)
                        ]),
                        const Divider(height: 28),
                        StatusIndicator(
                            label: exam.status == ExamStatus.complete
                                ? 'Résultat disponible'
                                : 'En attente de résultat',
                            pending: exam.status == ExamStatus.pending,
                            icon: exam.status == ExamStatus.complete
                                ? Icons.task_alt_rounded
                                : Icons.schedule_rounded),
                        const SizedBox(height: 8),
                        Text('Prescription · ${shortDate(exam.date)}',
                            style: const TextStyle(
                                fontSize: 12, color: Palette.muted)),
                        if (exam.status == ExamStatus.complete &&
                            exam.result != null) ...[
                          const SizedBox(height: 12),
                          Text(exam.result!,
                              style:
                                  const TextStyle(fontSize: 14, height: 1.5)),
                        ],
                      ]))),
        const SizedBox(height: 12),
        const DemoNotice(compact: true),
      ]))
    ]);
  }
}
