import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/theme.dart';
import '../../core/models/medical_models.dart';
import '../../core/state/store_context.dart';
import '../../core/widgets/medical_ui.dart';
import '../patients/patient_detail_screen.dart';
import 'followup_editor_screen.dart';

class FollowupScreen extends StatefulWidget {
  const FollowupScreen({super.key});
  @override
  State<FollowupScreen> createState() => _FollowupScreenState();
}

class _FollowupScreenState extends State<FollowupScreen> {
  bool showHistory = false;

  void openEditor({String? patientId, FollowUpPlan? plan}) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => FollowUpEditorScreen(
        patientId: patientId, plan: plan)));
  }

  Future<void> closePlan(FollowUpPlan plan, {required bool completed}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(completed ? 'Terminer ce suivi ?' : 'Annuler ce suivi ?'),
        content: Text(completed
          ? 'Le rendez-vous sera classé dans l’historique des suivis.'
          : 'La date sera annulée et conservée dans l’historique.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Retour'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(completed ? 'Terminer' : 'Annuler le suivi'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    context.store.closeFollowUp(plan.id, completed: completed);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final now = DateTime.now();
    final planned = List<FollowUpPlan>.from(store.plannedFollowUps);
    final overdue = planned
      .where((plan) => plan.isOverdue(now)).toList();
    final today = planned
      .where((plan) => plan.isToday(now)).toList();
    final upcoming = planned
      .where((plan) => plan.isUpcoming(now)).toList();
    final List<Patient> noDate = List<Patient>.from(store.followUpsWithoutDate);
    final List<FollowUpPlan> history = List<FollowUpPlan>.from(store.pastFollowUps);

    Widget group(String title, List<FollowUpPlan> plans, {
      String? subtitle,
    }) {
      if (plans.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: Text(title, style: TextStyle(
              fontSize: 18, color: Palette.of(context).ink, fontWeight: FontWeight.w700))),
            Text('${plans.length}', style: TextStyle(
              fontSize: 14, color: Palette.of(context).muted)),
          ]),
          if (subtitle != null) ...[
            const SizedBox(height: 5),
            Text(subtitle, style: TextStyle(
              fontSize: 14, color: Palette.of(context).muted)),
          ],
          const SizedBox(height: 11),
          for (final plan in plans) ...[
            _FollowUpCard(
              plan: plan,
              patient: store.patientById(plan.patientId),
              onOpenPatient: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) =>
                  PatientDetailScreen(patientId: plan.patientId))),
              onEdit: () => openEditor(plan: plan),
              onComplete: () => closePlan(plan, completed: true),
              onCancel: () => closePlan(plan, completed: false),
            ),
            const SizedBox(height: 10),
          ],
        ],
      );
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        ScreenWidth(
          padding: const EdgeInsets.fromLTRB(20, 23, 20, 105),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CONTINUITÉ DES SOINS', style: TextStyle(
                      fontSize: 13, letterSpacing: .5,
                      color: Palette.of(context).forest, fontWeight: FontWeight.w700)),
                    SizedBox(height: 9),
                    Text('Suivi médical', style: TextStyle(
                      fontSize: 23, letterSpacing: -.7,
                      color: Palette.of(context).ink, fontWeight: FontWeight.w700)),
                    SizedBox(height: 6),
                    Text('Rendez-vous et prochaines visites.',
                      style: TextStyle(fontSize: 14, color: Palette.of(context).muted)),
                  ],
                )),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: 'Programmer un suivi',
                  onPressed: () => openEditor(),
                  icon: const Icon(Icons.add_rounded),
                ),
              ]),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: Palette.of(context).surface,
                  border: Border.all(color: Palette.of(context).border),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SUIVIS À TRAITER', style: TextStyle(
                        fontSize: 13.5, color: Palette.of(context).muted,
                        fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text('${overdue.length + today.length}',
                        style: TextStyle(
                          fontSize: 34, color: Palette.of(context).ink,
                          fontWeight: FontWeight.w700, height: 1)),
                      const SizedBox(height: 7),
                      Text('${overdue.length} en retard · ${today.length} aujourd’hui',
                        style: TextStyle(
                          fontSize: 14, color: Palette.of(context).muted)),
                    ],
                  )),
                  SvgPicture.asset(
                    'assets/illustrations/care_calendar.svg',
                    width: 100,
                    height: 90,
                    fit: BoxFit.contain,
                    semanticsLabel: 'Illustration de calendrier de soins',
                  ),
                ]),
              ),
              if (overdue.isNotEmpty) ...[
                const SizedBox(height: 13),
                _InfoStrip(
                  icon: Icons.schedule_outlined,
                  text: '${overdue.length} suivi(s) avec une date dépassée. '
                    'Vérifiez les dossiers concernés.',
                ),
              ],
              if (overdue.isEmpty && today.isEmpty &&
                  upcoming.isEmpty && noDate.isEmpty) ...[
                const SizedBox(height: 28),
                const EmptyResults(
                  title: 'Aucun suivi en attente',
                  detail: 'Programmez une visite depuis un dossier patient.'),
              ],
              group('En retard', overdue,
                subtitle: 'Échéances précédant aujourd’hui'),
              group('Aujourd’hui', today),
              group('À venir', upcoming),
              if (noDate.isNotEmpty) ...[
                const SizedBox(height: 24),
                const SectionHeading(title: 'À programmer'),
                const SizedBox(height: 7),
                Text('Suivis signalés sans date précise.',
                  style: TextStyle(fontSize: 13, color: Palette.of(context).muted)),
                const SizedBox(height: 11),
                for (final patient in noDate) ...[
                  SurfaceCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 11),
                    child: Row(children: [
                      PatientAvatar(patient: patient, size: 41),
                      const SizedBox(width: 10),
                      Expanded(child: Text(patient.name, style:
                        const TextStyle(fontSize: 14,
                          fontWeight: FontWeight.w600))),
                      IconButton(
                        tooltip: 'Choisir une date',
                        onPressed: () => openEditor(patientId: patient.id),
                        icon: Icon(Icons.event_available_outlined,
                          color: Palette.of(context).forest),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 9),
                ],
              ],
              const SizedBox(height: 23),
              TextButton.icon(
                onPressed: () => setState(() => showHistory = !showHistory),
                icon: Icon(showHistory
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.history_rounded),
                label: Text(showHistory
                  ? 'Masquer l’historique'
                  : 'Historique des suivis (${history.length})'),
              ),
              if (showHistory) ...[
                if (history.isEmpty)
                  Text('Aucun suivi clôturé.',
                    style: TextStyle(color: Palette.of(context).muted, fontSize: 14, height: 1.4)),
                group('Suivis terminés ou annulés', history),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoStrip extends StatelessWidget {
  const _InfoStrip({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
    decoration: BoxDecoration(
      color: Palette.of(context).tealSoft,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(children: [
      Icon(icon, size: 20, color: Palette.of(context).forest),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: TextStyle(
        fontSize: 14, color: Palette.of(context).ink, height: 1.3))),
    ]),
  );
}

class _FollowUpCard extends StatelessWidget {
  const _FollowUpCard({
    required this.plan,
    required this.patient,
    required this.onOpenPatient,
    required this.onEdit,
    required this.onComplete,
    required this.onCancel,
  });
  final FollowUpPlan plan;
  final Patient? patient;
  final VoidCallback onOpenPatient;
  final VoidCallback onEdit;
  final VoidCallback onComplete;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final date = plan.scheduledAt;
    final dateLabel = '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
    final timeLabel = '${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}';
    final isHistory = !plan.isPlanned;
    final statusLabel = switch (plan.status) {
      FollowUpStatus.planned => '',
      FollowUpStatus.completed => 'Terminé',
      FollowUpStatus.cancelled => 'Annulé',
    };
    return Material(
      color: Palette.of(context).surface,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.fromLTRB(15, 15, 12, 15),
        decoration: BoxDecoration(
          border: Border.all(color: Palette.of(context).border),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: onOpenPatient,
              child: Row(children: [
                if (patient != null)
                  PatientAvatar(patient: patient!, size: 41)
                else const SoftIcon(icon: Icons.folder_outlined),
                const SizedBox(width: 11),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(patient?.name ?? 'Patient introuvable',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16, height: 1.3, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('$dateLabel · $timeLabel',
                      style: TextStyle(
                        fontSize: 13, color: Palette.of(context).muted)),
                  ],
                )),
                if (!isHistory)
                  PopupMenuButton<String>(
                    tooltip: 'Actions du suivi',
                    onSelected: (action) {
                      if (action == 'edit') onEdit();
                      if (action == 'done') onComplete();
                      if (action == 'cancel') onCancel();
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit',
                        child: Text('Modifier la date')),
                      PopupMenuItem(value: 'done',
                        child: Text('Marquer terminé')),
                      PopupMenuItem(value: 'cancel',
                        child: Text('Annuler le rendez-vous')),
                    ],
                  )
                else Icon(Icons.check_circle_outline_rounded,
                  color: Palette.of(context).muted, size: 20),
              ]),
            ),
            const SizedBox(height: 11),
            Text(plan.reason, style: TextStyle(
              color: Palette.of(context).ink, fontSize: 15.5, height: 1.4,
              fontWeight: FontWeight.w600)),
            if (plan.notes.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(plan.notes, maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Palette.of(context).muted, fontSize: 13)),
            ],
            if (isHistory) ...[
              const SizedBox(height: 7),
              Text(statusLabel, style: TextStyle(
                color: Palette.of(context).forest, fontSize: 13,
                fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      ),
    );
  }
}
