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
    final filtered = all.where((p) =>
      (!followUpOnly || p.followUp) &&
      (p.name.toLowerCase().contains(term) || p.id.toLowerCase().contains(term))).toList();

    return ListView(
      key: const ValueKey('medisuivi-patients'),
      physics: const BouncingScrollPhysics(),
      children: [
        ScreenWidth(
          padding: const EdgeInsets.fromLTRB(21, 27, 21, 42),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('RÉPERTOIRE', style: TextStyle(
              color: Palette.forest, fontSize: 10.5,
              fontWeight: FontWeight.w800, letterSpacing: 1.3)),
            const SizedBox(height: 8),
            Row(children: [
              const Expanded(child: Text('Mes patients', style: TextStyle(
                fontSize: 30, letterSpacing: -1,
                fontWeight: FontWeight.w800, color: Palette.charcoal))),
              IconButton.filled(
                tooltip: 'Nouveau patient',
                onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => const NewPatientScreen())),
                style: IconButton.styleFrom(
                  backgroundColor: Palette.charcoal,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(48, 48)),
                icon: const Icon(Icons.add_rounded),
              ),
            ]),
            const SizedBox(height: 8),
            Text('${all.length} dossiers de démonstration',
              style: const TextStyle(color: Palette.muted, fontSize: 12.5)),
            const SizedBox(height: 22),
            TextField(
              onChanged: (text) => setState(() => query = text),
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded, size: 22),
                hintText: 'Nom ou numéro de dossier'),
            ),
            const SizedBox(height: 15),
            Wrap(spacing: 9, children: [
              _FilterChip(
                label: 'Tous', selected: !followUpOnly,
                onTap: () => setState(() => followUpOnly = false)),
              _FilterChip(
                label: 'À revoir', selected: followUpOnly,
                onTap: () => setState(() => followUpOnly = true)),
            ]),
            const SizedBox(height: 26),
            Row(children: [
              const Expanded(child: Text('Dossiers', style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800))),
              Text('${filtered.length} résultats', style: const TextStyle(
                color: Palette.muted, fontSize: 12)),
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
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => PatientDetailScreen(patientId: patient.id))),
              ),
              const SizedBox(height: 9),
            ],
            const SizedBox(height: 10),
            const DemoNotice(compact: true),
          ]),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? Palette.charcoal : Colors.white,
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        child: Text(label, style: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w700,
          color: selected ? Colors.white : Palette.ink)),
      ),
    ),
  );
}
