import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/models/medical_models.dart';
import '../../core/state/demo_store.dart';
import '../../core/widgets/medical_ui.dart';
import '../patients/patient_detail_screen.dart';
import 'exam_editor_screen.dart';

/// Lecture d'un bilan précis depuis le dossier patient ou la liste générale.
class ExamDetailScreen extends StatelessWidget {
  const ExamDetailScreen({super.key, required this.examId});
  final String examId;

  @override
  Widget build(BuildContext context) {
    // Toujours lire la version actuelle depuis le store, pas l'ancienne
    // instance transmise avant la saisie du compte rendu.
    final store = DemoScope.of(context);
    final exam = store.examById(examId);
    if (exam == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bilan médical')),
        body: const Center(child: Text('Bilan introuvable.')),
      );
    }
    final patient = store.patientById(exam.patientId);
    final completed = exam.status == ExamStatus.complete;
    return Scaffold(
      appBar: AppBar(title: const Text('Détail du bilan')),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          children: [
            ScreenWidth(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('EXAMEN MÉDICAL',
                    style: const TextStyle(
                      color: Palette.forest,
                      letterSpacing: .55,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Text(exam.title, style: const TextStyle(
                    color: Palette.ink, fontSize: 26, height: 1.2,
                    fontWeight: FontWeight.w700, letterSpacing: -.55)),
                  const SizedBox(height: 17),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13, vertical: 12),
                    decoration: BoxDecoration(
                      color: completed ? Palette.tealSoft : Palette.blueSoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(children: [
                      Icon(
                        completed
                          ? Icons.check_circle_outline_rounded
                          : Icons.hourglass_top_rounded,
                        color: Palette.forest, size: 21),
                      const SizedBox(width: 10),
                      Expanded(child: Text(
                        completed ? 'Résultat disponible' : 'Résultat en attente',
                        style: const TextStyle(
                          fontSize: 15.5, color: Palette.ink,
                          fontWeight: FontWeight.w600))),
                    ]),
                  ),
                  const SizedBox(height: 23),
                  const SectionHeading(title: 'Informations de l’examen'),
                  const SizedBox(height: 10),
                  SurfaceCard(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DetailField(
                        label: 'Patient',
                        value: patient?.name ?? 'Patient introuvable'),
                      const Divider(height: 26),
                      _DetailField(
                        label: 'Date de prescription',
                        value: shortDate(exam.date)),
                      if (exam.resultRecordedAt != null) ...[
                        const Divider(height: 26),
                        _DetailField(
                          label: 'Résultat enregistré le',
                          value: shortDate(exam.resultRecordedAt!)),
                      ],
                      const SizedBox(height: 11),
                      OutlinedButton.icon(
                        onPressed: patient == null ? null : () =>
                          Navigator.of(context).push(MaterialPageRoute<void>(
                            builder: (_) =>
                              PatientDetailScreen(patientId: exam.patientId))),
                        icon: const Icon(Icons.folder_shared_outlined, size: 20),
                        label: const Text('Ouvrir le dossier patient'),
                      ),
                    ],
                  )),
                  const SizedBox(height: 26),
                  SectionHeading(
                    title: completed ? 'Compte rendu de l’examen' : 'Compte rendu',
                  ),
                  const SizedBox(height: 10),
                  SurfaceCard(
                    child: completed
                      ? Column(crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(children: [
                              Icon(Icons.description_outlined,
                                color: Palette.forest, size: 21),
                              SizedBox(width: 9),
                              Expanded(child: Text('Résultat enregistré',
                                style: TextStyle(
                                  fontSize: 16, color: Palette.ink,
                                  fontWeight: FontWeight.w700))),
                            ]),
                            const Divider(height: 29),
                            SelectableText(
                              exam.result?.trim().isNotEmpty == true
                                ? exam.result! : 'Aucun texte de résultat.',
                              style: const TextStyle(
                                color: Palette.ink,
                                fontSize: 16, height: 1.6)),
                          ])
                      : const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.pending_actions_outlined,
                              size: 25, color: Palette.forest),
                            SizedBox(height: 10),
                            Text('Aucun résultat enregistré pour le moment.',
                              style: TextStyle(
                                fontSize: 15, height: 1.5,
                                color: Palette.ink)),
                            SizedBox(height: 7),
                            Text('Le compte rendu apparaîtra ici après sa saisie.',
                              style: TextStyle(
                                fontSize: 14, height: 1.5,
                                color: Palette.muted)),
                          ]),
                  ),
                  if (!completed) ...[
                    const SizedBox(height: 20),
                    SizedBox(width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ExamEditorScreen(
                              patientId: exam.patientId,
                              exam: exam,
                              openDetailOnSave: false,
                            ))),
                        icon: const Icon(Icons.edit_note_rounded),
                        label: const Text('Saisir le résultat'),
                      )),
                  ],
                  const SizedBox(height: 16),
                  const Text(
                    'Données temporaires : aucune sauvegarde durable '
                    'n’est encore configurée.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Palette.muted, fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailField extends StatelessWidget {
  const _DetailField({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(
        fontSize: 13.5, height: 1.35, color: Palette.muted)),
      const SizedBox(height: 6),
      Text(value, style: const TextStyle(
        fontSize: 16, height: 1.4,
        fontWeight: FontWeight.w600, color: Palette.ink)),
    ],
  );
}
