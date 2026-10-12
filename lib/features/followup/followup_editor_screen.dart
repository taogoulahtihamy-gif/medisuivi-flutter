import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/models/medical_models.dart';
import '../../core/state/store_context.dart';
import '../../core/widgets/medical_ui.dart';

/// Planification locale d'un suivi, sans création de notification système.
class FollowUpEditorScreen extends StatefulWidget {
  const FollowUpEditorScreen({super.key, this.patientId, this.plan});

  final String? patientId;
  final FollowUpPlan? plan;

  @override
  State<FollowUpEditorScreen> createState() => _FollowUpEditorScreenState();
}

class _FollowUpEditorScreenState extends State<FollowUpEditorScreen> {
  final formKey = GlobalKey<FormState>();
  final reason = TextEditingController();
  final notes = TextEditingController();

  late DateTime scheduledAt;
  String? patientId;

  @override
  void initState() {
    super.initState();
    patientId = widget.plan?.patientId ?? widget.patientId;
    scheduledAt = widget.plan?.scheduledAt ??
      DateTime(DateTime.now().year, DateTime.now().month,
        DateTime.now().day + 1, 9);
    reason.text = widget.plan?.reason ?? '';
    notes.text = widget.plan?.notes ?? '';
  }

  @override
  void dispose() {
    reason.dispose();
    notes.dispose();
    super.dispose();
  }

  Future<void> chooseDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: scheduledAt,
      firstDate: DateTime(2020),
      lastDate: DateTime(DateTime.now().year + 5, 12, 31),
      helpText: 'Date du prochain suivi',
      cancelText: 'Annuler',
      confirmText: 'Choisir',
    );
    if (!mounted || selected == null) return;
    setState(() => scheduledAt = DateTime(selected.year, selected.month,
      selected.day, scheduledAt.hour, scheduledAt.minute));
  }

  Future<void> chooseTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(scheduledAt),
      helpText: 'Heure du prochain suivi',
    );
    if (!mounted || selected == null) return;
    setState(() => scheduledAt = DateTime(scheduledAt.year, scheduledAt.month,
      scheduledAt.day, selected.hour, selected.minute));
  }

  void save() {
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (patientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Sélectionnez un dossier patient.')));
      return;
    }
    final store = context.store;
    if (widget.plan == null) {
      store.scheduleFollowUp(
        patientId: patientId!,
        scheduledAt: scheduledAt,
        reason: reason.text,
        notes: notes.text,
      );
    } else {
      store.rescheduleFollowUp(
        followUpId: widget.plan!.id,
        scheduledAt: scheduledAt,
        reason: reason.text,
        notes: notes.text,
      );
    }
    Navigator.of(context).pop();
  }

  String formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/${date.year}';

  @override
  Widget build(BuildContext context) {
    final List<Patient> patients = List<Patient>.from(context.store.patients);
    return Scaffold(
      appBar: AppBar(title: Text(
        widget.plan == null ? 'Programmer un suivi' : 'Modifier le suivi')),
      body: SafeArea(child: SingleChildScrollView(
        child: ScreenWidth(
          padding: const EdgeInsets.fromLTRB(20, 13, 20, 40),
          child: Form(key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageTitle(
                  title: widget.plan == null
                    ? 'Prochaine consultation' : 'Reporter la consultation',
                  subtitle: 'Organiser le suivi dans le dossier médical.',
                ),
                const SizedBox(height: 22),
                ClinicalFormSection(
                  title: 'Dossier concerné',
                  icon: Icons.folder_shared_outlined,
                  child: DropdownButtonFormField<String>(
                    initialValue: patientId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Patient',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    items: [
                      for (final patient in patients)
                        DropdownMenuItem<String>(
                          value: patient.id,
                          child: Text(patient.name,
                            overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: widget.plan == null
                      ? (id) => setState(() => patientId = id) : null,
                    validator: (id) => id == null
                      ? 'Choisissez un patient.' : null,
                  ),
                ),
                const SizedBox(height: 14),
                ClinicalFormSection(
                  title: 'Date et heure',
                  icon: Icons.event_available_outlined,
                  subtitle: 'Le suivi apparaîtra dans les échéances.',
                  child: LayoutBuilder(builder: (context, constraints) {
                    Widget dateButton() => OutlinedButton.icon(
                      onPressed: chooseDate,
                      icon: const Icon(Icons.calendar_today_outlined, size: 18),
                      label: Text(formatDate(scheduledAt),
                        overflow: TextOverflow.ellipsis),
                    );
                    Widget timeButton() => OutlinedButton.icon(
                      onPressed: chooseTime,
                      icon: const Icon(Icons.schedule_outlined, size: 18),
                      label: Text(TimeOfDay.fromDateTime(scheduledAt)
                        .format(context), overflow: TextOverflow.ellipsis),
                    );
                    // Des boutons pleine largeur préservent les dates même
                    // à 320 px et avec un texte agrandi par l'utilisateur.
                    if (constraints.maxWidth < 340) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          dateButton(),
                          const SizedBox(height: 8),
                          timeButton(),
                        ],
                      );
                    }
                    return Row(children: [
                      Expanded(child: dateButton()),
                      const SizedBox(width: 10),
                      Expanded(child: timeButton()),
                    ]);
                  }),                ),
                const SizedBox(height: 14),
                ClinicalFormSection(
                  title: 'Motif du suivi',
                  icon: Icons.assignment_outlined,
                  child: Column(children: [
                    TextFormField(
                      controller: reason,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Motif de la prochaine consultation',
                        hintText: 'Ex. Réévaluation, contrôle biologique…',
                      ),
                      validator: (text) => (text?.trim().length ?? 0) < 3
                        ? 'Renseignez le motif du suivi.' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: notes,
                      minLines: 3,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Notes de préparation (facultatif)',
                        alignLabelWithHint: true,
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 22),
                ElevatedButton.icon(
                  onPressed: save,
                  icon: const Icon(Icons.check_rounded),
                  label: Text(widget.plan == null
                    ? 'Programmer le suivi' : 'Enregistrer la modification'),
                ),
                const SizedBox(height: 12),
                Text(
                  'Les suivis restent temporaires et ne déclenchent pas '
                  'de notification automatique.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Palette.of(context).muted, fontSize: 12.5),
                ),
              ],
            ),
          ),
        ),
      )),
    );
  }
}
