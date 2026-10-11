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
    final pending = store.exams.where((e) =>
      e.status == ExamStatus.pending).length;
    final exams = store.exams.where((e) =>
      !pendingOnly || e.status == ExamStatus.pending).toList();

    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        ScreenWidth(
          padding: const EdgeInsets.fromLTRB(21, 27, 21, 40),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('EXAMENS', style: TextStyle(
              fontSize: 10.5, letterSpacing: 1.3,
              fontWeight: FontWeight.w800, color: Palette.forest)),
            const SizedBox(height: 8),
            const Text('Bilans médicaux', style: TextStyle(
              fontSize: 30, letterSpacing: -1,
              fontWeight: FontWeight.w800, color: Palette.laser)),
            const SizedBox(height: 7),
            const Text('Demandes et résultats par patient.',
              style: TextStyle(fontSize: 12.5, color: Palette.muted)),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Palette.laser,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('EN ATTENTE DE RÉSULTAT', style: TextStyle(
                      fontSize: 10, letterSpacing: 1.0,
                      color: Palette.laserMuted, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    Text('$pending', style: const TextStyle(
                      fontSize: 47, height: 1,
                      letterSpacing: -1.7, fontWeight: FontWeight.w800,
                      color: Palette.laser)),
                    const SizedBox(height: 5),
                    const Text('examens à suivre', style: TextStyle(
                      fontSize: 12, color: Palette.laserMuted)),
                  ],
                )),
                Container(
                  width: 55, height: 55,
                  decoration: BoxDecoration(
                    color: const Palette.laserVeil,
                    borderRadius: BorderRadius.circular(18)),
                  child: const Icon(Icons.biotech_outlined,
                    color: Palette.laser, size: 27),
                ),
              ]),
            ),
            const SizedBox(height: 22),
            Wrap(spacing: 9, children: [
              ChoiceChip(
                label: const Text('Tous les examens'),
                selected: !pendingOnly,
                onSelected: (_) => setState(() => pendingOnly = false)),
              ChoiceChip(
                label: const Text('En attente'),
                selected: pendingOnly,
                onSelected: (_) => setState(() => pendingOnly = true)),
            ]),
            const SizedBox(height: 24),
            Row(children: [
              const Expanded(child: Text('Dossiers', style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800))),
              Text('${exams.length} examens',
                style: const TextStyle(fontSize: 12, color: Palette.muted)),
            ]),
            const SizedBox(height: 13),
            if (exams.isEmpty)
              const EmptyResults(
                title: 'Aucun examen',
                detail: 'Les examens enregistrés apparaîtront ici.',
                icon: Icons.biotech_outlined)
            else for (final exam in exams) ...[
              SurfaceCard(
                padding: const EdgeInsets.all(15),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PatientDetailScreen(
                      patientId: exam.patientId))),
                child: Row(children: [
                  SoftIcon(
                    icon: Icons.science_outlined,
                    color: exam.status == ExamStatus.complete
                      ? Palette.forest : const Palette.laser,
                    background: exam.status == ExamStatus.complete
                      ? Palette.mintFog : Palette.amberSoft),
                  const SizedBox(width: 13),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(exam.title, style: const TextStyle(
                        fontSize: 13.5, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 5),
                      Text(store.patientById(exam.patientId)?.name ??
                        'Patient', style: const TextStyle(
                          fontSize: 11.5, color: Palette.muted)),
                      const SizedBox(height: 7),
                      Text(exam.status == ExamStatus.complete
                        ? 'Résultat disponible' : 'En attente de résultat',
                        style: TextStyle(fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: exam.status == ExamStatus.complete
                            ? Palette.forest : const Palette.laser)),
                    ],
                  )),
                  const Icon(Icons.chevron_right_rounded,
                    color: Palette.muted),
                ]),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 11),
            const DemoNotice(compact: true),
          ]),
        ),
      ],
    );
  }
}
