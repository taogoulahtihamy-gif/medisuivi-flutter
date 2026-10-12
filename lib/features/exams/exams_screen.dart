import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/theme.dart';
import '../../core/models/medical_models.dart';
import '../../core/state/demo_store.dart';
import '../../core/widgets/medical_ui.dart';
import 'exam_detail_screen.dart';

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
      !pendingOnly || e.status == ExamStatus.pending).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        ScreenWidth(
          padding: const EdgeInsets.fromLTRB(20, 23, 20, 104),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('EXAMENS', style: TextStyle(
              fontSize: 12, letterSpacing: .5,
              fontWeight: FontWeight.w700, color: Palette.of(context).forest)),
            const SizedBox(height: 8),
            Text('Bilans médicaux', style: TextStyle(
              fontSize: 23, letterSpacing: -.7,
              fontWeight: FontWeight.w700, color: Palette.of(context).ink)),
            const SizedBox(height: 7),
            Text('Demandes et résultats par patient.',
              style: TextStyle(fontSize: 14, color: Palette.of(context).muted)),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Palette.of(context).surface,
                borderRadius: BorderRadius.circular(21),
                border: Border.all(color: Palette.of(context).border),
              ),
              child: Row(children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('EN ATTENTE DE RÉSULTAT', style: TextStyle(
                      fontSize: 12, letterSpacing: .5,
                      color: Palette.of(context).muted, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    Text('$pending', style: TextStyle(
                      fontSize: 34, height: 1,
                      letterSpacing: -1.7, fontWeight: FontWeight.w700,
                      color: Palette.of(context).ink)),
                    const SizedBox(height: 5),
                    Text('examens à suivre', style: TextStyle(
                      fontSize: 14, color: Palette.of(context).ink)),
                  ],
                )),
                SvgPicture.asset(
                  'assets/illustrations/laboratory.svg',
                  width: 112,
                  height: 91,
                  fit: BoxFit.contain,
                  semanticsLabel: "Illustration de laboratoire et d'analyses",
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
                fontSize: 18, fontWeight: FontWeight.w700))),
              Text('${exams.length} examens',
                style: TextStyle(fontSize: 14, height: 1.4, color: Palette.of(context).muted)),
            ]),
            const SizedBox(height: 13),
            if (exams.isEmpty)
              const EmptyResults(
                title: 'Aucun examen',
                detail: 'Les examens enregistrés apparaîtront ici.',
                icon: Icons.biotech_outlined)
            else for (final exam in exams) ...[
              SurfaceCard(
                padding: const EdgeInsets.fromLTRB(15, 17, 14, 17),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ExamDetailScreen(examId: exam.id))),
                child: Row(children: [
                  SoftIcon(
                    icon: exam.status == ExamStatus.complete
                      ? Icons.description_outlined : Icons.science_outlined,
                    color: exam.status == ExamStatus.complete
                      ? Palette.of(context).forest : Palette.of(context).forest,
                    background: exam.status == ExamStatus.complete
                      ? Palette.of(context).tealSoft : Palette.of(context).blueSoft),
                  const SizedBox(width: 13),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(exam.title, style: const TextStyle(
                        fontSize: 16, height: 1.25, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 5),
                      Text(store.patientById(exam.patientId)?.name ??
                        'Patient', style: TextStyle(
                          fontSize: 13, color: Palette.of(context).muted)),
                      const SizedBox(height: 7),
                      Text(exam.status == ExamStatus.complete
                        ? 'Résultat disponible' : 'En attente de résultat',
                        style: TextStyle(fontSize: 14, height: 1.3,
                          fontWeight: FontWeight.w600,
                          color: exam.status == ExamStatus.complete
                            ? Palette.of(context).forest : Palette.of(context).ink)),
                    ],
                  )),
                  Icon(Icons.chevron_right_rounded,
                    color: Palette.of(context).forest, size: 24),
                ]),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 11),

          ]),
        ),
      ],
    );
  }
}
