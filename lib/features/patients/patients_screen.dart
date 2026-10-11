import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/state/demo_store.dart';
import '../../core/widgets/medical_ui.dart';
import 'new_patient_screen.dart';
import 'patient_detail_screen.dart';

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key});

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  String query = '';
  bool followUpOnly = false;

  @override
  Widget build(BuildContext context) {
    final all = DemoScope.of(context).patients;
    final term = query.toLowerCase().trim();
    final filtered = all.where((patient) =>
      (!followUpOnly || patient.followUp) &&
      (patient.name.toLowerCase().contains(term) ||
        patient.id.toLowerCase().contains(term))).toList();

    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        ScreenWidth(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 40),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            PageTitle(
              title: 'Mes patients',
              subtitle: 'Retrouvez chaque dossier en un instant.',
              action: IconButton.filled(
                tooltip: 'Nouveau patient',
                icon: const Icon(Icons.add_rounded),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const NewPatientScreen())),
              ),
            ),
            const SizedBox(height: 22),
            EntranceReveal(child: Container(
              padding: const EdgeInsets.fromLTRB(20, 19, 20, 19),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [
                  Palette.navy, Color(0xFF137758),
                ], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(23),
              ),
              child: Row(children: [
                Container(
                  width: 49, height: 49,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .15),
                    borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.folder_shared_outlined,
                    color: Colors.white, size: 26),
                ),
                const SizedBox(width: 15),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${all.length} dossiers',
                      style: const TextStyle(color: Colors.white,
                        fontSize: 23, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    const Text('Historique, bilans et consultations',
                      style: TextStyle(color: Color(0xFFE8FFF2),
                        fontSize: 11.5, height: 1.3)),
                  ],
                )),
              ]),
            )),
            const SizedBox(height: 22),
            TextField(
              onChanged: (value) => setState(() => query = value),
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded, size: 22),
                hintText: 'Nom ou numéro de dossier',
              ),
            ),
            const SizedBox(height: 15),
            Wrap(spacing: 10, runSpacing: 8, children: [
              ChoiceChip(
                label: const Text('Tous les patients'),
                selected: !followUpOnly,
                onSelected: (_) => setState(() => followUpOnly = false)),
              ChoiceChip(
                label: const Text('À revoir'),
                selected: followUpOnly,
                onSelected: (_) => setState(() => followUpOnly = true)),
            ]),
            const SizedBox(height: 25),
            Row(children: [
              const Expanded(child: Text('Dossiers',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
              Text('${filtered.length} résultats',
                style: const TextStyle(color: Palette.muted, fontSize: 12)),
            ]),
            const SizedBox(height: 13),
            if (filtered.isEmpty)
              const EmptyResults(
                title: 'Aucun dossier trouvé',
                detail: 'Essayez une autre recherche.',
                icon: Icons.search_off_rounded)
            else for (final patient in filtered) ...[
              PatientRow(
                patient: patient,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) =>
                    PatientDetailScreen(patientId: patient.id))),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 10),
            const DemoNotice(compact: true),
          ]),
        ),
      ],
    );
  }
}
