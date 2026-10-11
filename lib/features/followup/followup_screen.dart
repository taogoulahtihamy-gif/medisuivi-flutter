import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../core/state/demo_store.dart';
import '../../core/widgets/medical_ui.dart';
import '../patients/patient_detail_screen.dart';

class FollowupScreen extends StatelessWidget {
  const FollowupScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final store = DemoScope.of(context);
    final followups = store.patients.where((p) => p.followUp).toList();
    return ListView(children: [ScreenWidth(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const PageTitle(title: 'Suivi médical', subtitle: 'Continuité des soins et visites à revoir'),
      const SizedBox(height: 23),
      SurfaceCard(child: Row(children: [
        const SoftIcon(icon: Icons.event_repeat_rounded),
        const SizedBox(width: 13),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${followups.length} dossiers à revoir', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          const Text('Patients signalés pour un suivi dans les données fictives.',
            style: TextStyle(fontSize: 12, height: 1.4, color: Palette.muted)),
        ])),
      ])),
      const SizedBox(height: 27),
      const SectionHeading(title: 'Patients à suivre'),
      const SizedBox(height: 13),
      if (followups.isEmpty)
        const EmptyResults(title: 'Aucun suivi', detail: 'Les prochains suivis apparaîtront ici.')
      else for (final p in followups) ...[
        PatientRow(patient: p,
          subtitle: 'Dernière visite : ${store.visitsFor(p.id).isEmpty ? 'non renseignée' : shortDate(store.visitsFor(p.id).first.date)}',
          onTap: () => Navigator.push(context,
            MaterialPageRoute<void>(builder: (_) => PatientDetailScreen(patientId: p.id)))),
        const SizedBox(height: 9),
      ],
      const SizedBox(height: 21),
      const DemoNotice(compact: true),
    ]))]);
  }
}
