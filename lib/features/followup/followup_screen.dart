import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        ScreenWidth(
          padding: const EdgeInsets.fromLTRB(21, 27, 21, 42),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('CONTINUITÉ DES SOINS', style: TextStyle(
              fontSize: 12, letterSpacing: .5,
              color: Palette.forest, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('Suivi médical', style: TextStyle(
              fontSize: 27, letterSpacing: -.6,
              color: Palette.ink, fontWeight: FontWeight.w700)),
            const SizedBox(height: 7),
            const Text('Retrouvez les patients à revoir.',
              style: TextStyle(fontSize: 14, color: Palette.muted)),
            const SizedBox(height: 23),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              decoration: BoxDecoration(
                color: Palette.white,
                borderRadius: BorderRadius.circular(21),
                border: Border.all(color: Palette.border),
              ),
              child: Row(children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('DOSSIERS À REVOIR', style: TextStyle(
                      fontSize: 12, color: Palette.muted,
                      letterSpacing: 1.1, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text('${followups.length}', style: const TextStyle(
                      fontSize: 39, height: 1,
                      letterSpacing: -1, fontWeight: FontWeight.w700,
                      color: Palette.ink)),
                    const SizedBox(height: 7),
                    const Text('Suivi signalé dans les dossiers',
                      style: TextStyle(fontSize: 13, color: Palette.muted)),
                  ],
                )),
                SvgPicture.asset(
                  'assets/illustrations/care_calendar.svg',
                  width: 112,
                  height: 91,
                  fit: BoxFit.contain,
                  semanticsLabel: 'Illustration de calendrier de soins',
                ),
              ]),
            ),
            const SizedBox(height: 28),
            const SectionHeading(title: 'Patients à suivre'),
            const SizedBox(height: 12),
            if (followups.isEmpty)
              const EmptyResults(
                title: 'Aucun suivi',
                detail: 'Les dossiers à revoir apparaîtront ici.')
            else for (final p in followups) ...[
              PatientRow(
                patient: p,
                subtitle: 'Dernière consultation : ${store.visitsFor(p.id).isEmpty ? 'non renseignée' : shortDate(store.visitsFor(p.id).first.date)}',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PatientDetailScreen(patientId: p.id))),
              ),
              const SizedBox(height: 9),
            ],
            const SizedBox(height: 17),

          ]),
        ),
      ],
    );
  }
}
