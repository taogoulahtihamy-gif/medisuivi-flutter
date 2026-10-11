import 'package:flutter/material.dart';
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
    final filtered = all.where((p) => (!followUpOnly || p.followUp) &&
      (p.name.toLowerCase().contains(query.toLowerCase().trim()) || p.id.toLowerCase().contains(query.toLowerCase().trim()))).toList();
    return ListView(children: [ScreenWidth(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageTitle(title: 'Mes patients', subtitle: '${all.length} dossiers de démonstration',
        action: IconButton.filled(
          tooltip: 'Nouveau patient', icon: const Icon(Icons.add_rounded),
          onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const NewPatientScreen())))),
      const SizedBox(height: 20),
      TextField(onChanged: (v) => setState(() => query = v),
        textInputAction: TextInputAction.search,
        decoration: const InputDecoration(prefixIcon: Icon(Icons.search_rounded), hintText: 'Nom ou numéro de dossier')),
      const SizedBox(height: 13),
      Wrap(spacing: 9, children: [
        ChoiceChip(label: const Text('Tous les dossiers'), selected: !followUpOnly,
          onSelected: (_) => setState(() => followUpOnly = false)),
        ChoiceChip(label: const Text('À revoir'), selected: followUpOnly,
          onSelected: (_) => setState(() => followUpOnly = true)),
      ]),
      const SizedBox(height: 19),
      if (filtered.isEmpty)
        const EmptyResults(title: 'Aucun dossier trouvé', detail: 'Essayez une autre recherche.', icon: Icons.search_off_rounded)
      else for (final patient in filtered) ...[
        PatientRow(patient: patient, onTap: () => Navigator.push(context,
          MaterialPageRoute<void>(builder: (_) => PatientDetailScreen(patientId: patient.id)))),
        const SizedBox(height: 10),
      ],
      const SizedBox(height: 8),
      const DemoNotice(compact: true),
    ]))]);
  }
}
