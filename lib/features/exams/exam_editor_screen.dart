import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../core/models/medical_models.dart';
import '../../core/state/demo_store.dart';
import '../../core/widgets/medical_ui.dart';
import 'exam_detail_screen.dart';

/// Saisie d'une prescription ou d'un résultat, sans interprétation automatique.
class ExamEditorScreen extends StatefulWidget {
  const ExamEditorScreen({super.key, required this.patientId, this.exam,
    this.openDetailOnSave = true});
  final String patientId;
  final LabExam? exam;
  final bool openDetailOnSave;

  @override
  State<ExamEditorScreen> createState() => _ExamEditorScreenState();
}

class _ExamEditorScreenState extends State<ExamEditorScreen> {
  final form = GlobalKey<FormState>();
  final title = TextEditingController();
  final result = TextEditingController();

  bool get isResult => widget.exam != null;

  @override
  void initState() {
    super.initState();
    if (widget.exam != null) {
      title.text = widget.exam!.title;
      result.text = widget.exam!.result ?? '';
    }
  }

  @override
  void dispose() {
    title.dispose();
    result.dispose();
    super.dispose();
  }

  void _save() {
    if (!form.currentState!.validate()) return;
    final store = DemoScope.of(context);
    late final String examId;
    if (isResult) {
      examId = widget.exam!.id;
      store.recordExamResult(examId: examId, result: result.text);
    } else {
      examId = store.addExam(
        patientId: widget.patientId, title: title.text);
    }
    if (!mounted) return;
    if (widget.openDetailOnSave) {
      Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
        builder: (_) => ExamDetailScreen(examId: examId)));
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(isResult ? 'Résultat du bilan' : 'Prescrire un bilan')),
    body: SafeArea(child: SingleChildScrollView(
      child: ScreenWidth(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 36),
        child: Form(
          key: form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageTitle(
                title: isResult ? 'Renseigner le résultat' : 'Nouvel examen',
                subtitle: isResult
                  ? 'Associer le résultat au bilan prescrit.'
                  : 'Créer une prescription dans le dossier.',
              ),
              const SizedBox(height: 24),
              ClinicalFormSection(
                icon: Icons.biotech_outlined,
                title: isResult ? 'Examen prescrit' : 'Prescription',
                child: isResult
                  ? Text(widget.exam!.title,
                    style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600))
                  : TextFormField(
                    controller: title,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Nom de l’examen',
                      hintText: 'Ex. NFS, glycémie, analyse biologique…'),
                    validator: (value) =>
                      (value?.trim().length ?? 0) < 3
                        ? 'Renseignez le nom de l’examen.' : null,
                  ),
              ),
              if (isResult) ...[
                const SizedBox(height: 14),
                ClinicalFormSection(
                  icon: Icons.assignment_turned_in_outlined,
                  title: 'Compte rendu',
                  subtitle: 'Recopier fidèlement le résultat disponible.',
                  child: TextFormField(
                    controller: result,
                    minLines: 4,
                    maxLines: 9,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Résultat et observations',
                      alignLabelWithHint: true),
                    validator: (value) =>
                      (value?.trim().isEmpty ?? true)
                        ? 'Un résultat est nécessaire.' : null,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check_rounded),
                label: Text(isResult ? 'Enregistrer le résultat'
                  : 'Ajouter la prescription'),
              ),
              const SizedBox(height: 12),
              const Text(
                'Saisie temporaire : ces informations ne sont pas conservées après fermeture.',
                style: TextStyle(color: Palette.muted, fontSize: 13.5, height: 1.4),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    )),
  );
}
