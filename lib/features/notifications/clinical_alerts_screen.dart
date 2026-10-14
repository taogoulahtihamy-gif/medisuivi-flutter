import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/models/medical_models.dart';
import '../../core/state/store_context.dart';
import '../../core/widgets/medical_ui.dart';

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
                if (exams > 0)
                  SurfaceCard(child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.biotech_outlined),
                    title: Text('$exams examen(s) en attente'),
                    subtitle: const Text('Consultez vos bilans pour les traiter.'),
                  )),
                if (exams > 0 && overdue > 0) const SizedBox(height: 10),
                if (overdue > 0)
                  SurfaceCard(child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_busy_outlined),
                    title: Text('$overdue suivi(s) en retard'),
                    subtitle: const Text('Consultez votre planning de suivi.'),
                  )),
                if (exams == 0 && overdue == 0)
                  const SurfaceCard(child: Text('Aucune alerte clinique locale.')),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
