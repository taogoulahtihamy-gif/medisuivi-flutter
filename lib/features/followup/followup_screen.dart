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
    final visits = [...store.visits]..sort((a, b) => b.date.compareTo(a.date));
    void open(String id) => Navigator.push(
        context,
        MaterialPageRoute<void>(
            builder: (_) => PatientDetailScreen(patientId: id)));
    return ListView(children: [
      ScreenWidth(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const PageTitle(
            title: 'Suivi médical',
            subtitle: 'Une continuité, à chaque étape du parcours.'),
        const SizedBox(height: 24),
        AnimatedSection(
            child: MedicalHeader(
                eyebrow: 'Continuité des soins',
                title: '${followups.length} dossiers à revoir',
                description:
                    'Patients signalés dans les dossiers fictifs. Aucune recommandation automatique.',
                icon: Icons.event_repeat_outlined)),
        const SizedBox(height: 28),
        const SectionHeading(title: 'Patients à suivre'),
        const SizedBox(height: 12),
        if (followups.isEmpty)
          const EmptyState(
              title: 'Aucun suivi', detail: 'Aucun patient signalé à revoir.'),
        for (final p in followups)
          Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PatientCard(
                  patient: p,
                  subtitle:
                      '${p.id} · Dernière visite : ${store.visitsFor(p.id).isEmpty ? 'non renseignée' : shortDate(store.visitsFor(p.id).first.date)}',
                  onTap: () => open(p.id))),
        const SizedBox(height: 20),
        const SectionHeading(title: 'Dernières consultations'),
        const SizedBox(height: 12),
        if (visits.isEmpty)
          const EmptyState(
              title: 'Aucune consultation',
              detail: 'Les visites enregistrées apparaîtront ici.')
        else
          PremiumCard(
              child: MedicalTimeline(children: [
            for (final visit in visits)
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => open(visit.patientId),
                child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(shortDate(visit.date),
                              style: const TextStyle(
                                  color: Palette.forest,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Text(visit.reason,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(
                              store.patientById(visit.patientId)?.name ??
                                  'Dossier indisponible',
                              style: const TextStyle(color: Palette.muted)),
                          const SizedBox(height: 8),
                          const StatusIndicator(
                              label: 'Ouvrir le dossier',
                              icon: Icons.arrow_forward_rounded),
                        ])),
              )
          ])),
        const SizedBox(height: 24),
        const DemoNotice(compact: true),
      ]))
    ]);
  }
}
