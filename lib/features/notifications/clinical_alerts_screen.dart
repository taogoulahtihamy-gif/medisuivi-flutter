import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/models/medical_models.dart';
import '../../core/state/store_context.dart';
import '../../core/widgets/medical_ui.dart';
import '../exams/exams_screen.dart';
import '../followup/followup_screen.dart';

/// Alertes tirées exclusivement du stockage local : pas de serveur push.
class ClinicalAlertsScreen extends StatelessWidget {
  const ClinicalAlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final exams = store.exams
        .where((e) => e.status == ExamStatus.pending).length;
    final overdue = store.plannedFollowUps
        .where((plan) => plan.isOverdue(DateTime.now())).length;
    final p = Palette.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: SafeArea(
        child: ListView(children: [
          ScreenWidth(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('À surveiller', style: TextStyle(
                    color: p.ink, fontSize: 19, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('Alertes calculées sur cet appareil. '
                    'Aucune notification serveur n’est activée.',
                  style: TextStyle(color: p.muted, fontSize: 13)),
                const SizedBox(height: 18),
                if (exams > 0 || overdue > 0)
                  ClinicalGroupedList(children: [
                    if (exams > 0)
                      ClinicalListRow(
                        title: '$exams examen(s) en attente',
                        subtitle: 'Consultez les bilans pour les traiter.',
                        leading: Icon(Icons.biotech_outlined, color: p.forest),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const ExamsScreen())),
                      ),
                    if (overdue > 0)
                      ClinicalListRow(
                        title: '$overdue suivi(s) en retard',
                        subtitle: 'Consultez votre planning de suivi.',
                        leading: Icon(Icons.event_busy_outlined, color: p.forest),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const FollowupScreen())),
                      ),
                  ])
                else
                  const EmptyResults(title: 'Aucune alerte clinique locale',
                    detail: 'Aucune action urgente pour le moment.',
                    icon: Icons.notifications_none_rounded),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
