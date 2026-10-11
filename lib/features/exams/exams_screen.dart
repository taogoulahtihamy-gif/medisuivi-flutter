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
  bool pendingOnly = false;
  @override
  Widget build(BuildContext context) {
    final store = DemoScope.of(context);
    final exams = store.exams.where((e) => !pendingOnly || e.status == ExamStatus.pending).toList();
    return ListView(children: [ScreenWidth(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const PageTitle(title: 'Bilans et examens', subtitle: 'Demandes et résultats par patient'),
      const SizedBox(height: 20),
      Wrap(spacing: 10, children: [
        ChoiceChip(label: const Text('Tous'), selected: !pendingOnly,
          onSelected: (_) => setState(() => pendingOnly = false)),
        ChoiceChip(label: const Text('En attente'), selected: pendingOnly,
          onSelected: (_) => setState(() => pendingOnly = true)),
      ]),
      const SizedBox(height: 16),
      if (exams.isEmpty)
        const EmptyResults(title: 'Aucun examen', detail: 'Les examens enregistrés apparaîtront ici.', icon: Icons.biotech_outlined)
      else for (final exam in exams) ...[
        SurfaceCard(onTap: () => Navigator.push(context, MaterialPageRoute<void>(
          builder: (_) => PatientDetailScreen(patientId: exam.patientId))),
          child: Row(children: [
            SoftIcon(icon: Icons.science_outlined,
              color: exam.status == ExamStatus.complete ? Palette.teal : const Color(0xFF966328),
              background: exam.status == ExamStatus.complete ? Palette.tealSoft : Palette.amberSoft),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(exam.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 5),
              Text(store.patientById(exam.patientId)?.name ?? 'Patient',
                style: const TextStyle(fontSize: 12, color: Palette.muted)),
              const SizedBox(height: 7),
              Text(exam.status == ExamStatus.complete ? 'Résultat disponible' : 'En attente de résultat',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                  color: exam.status == ExamStatus.complete ? Palette.teal : const Color(0xFF966328))),
            ])),
            const Icon(Icons.chevron_right_rounded, color: Palette.muted),
          ])),
        const SizedBox(height: 10),
      ],
      const SizedBox(height: 14),
      const DemoNotice(compact: true),
    ]))]);
  }
}
