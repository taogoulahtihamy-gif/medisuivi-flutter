import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../app/theme.dart';
import '../../app/design_tokens.dart';
import '../../core/models/medical_models.dart';
import '../../core/state/store_context.dart';
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
    final List<Patient> all = List<Patient>.from(context.store.patients);
    final term = query.toLowerCase().trim();
    final filtered = all.where((p) =>
      (!followUpOnly || p.followUp) &&
      (p.name.toLowerCase().contains(term) || p.id.toLowerCase().contains(term))).toList();

    return ListView(
      key: const ValueKey('medisuivi-patients'),
      physics: const BouncingScrollPhysics(),
      children: [
        ScreenWidth(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 104),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 2),
            Row(children: [
              Expanded(child: Text('Mes patients', style: TextStyle(
                fontSize: 23, letterSpacing: -.65,
                fontWeight: FontWeight.w700, color: Palette.of(context).ink))),
              IconButton.filled(
                tooltip: 'Nouveau patient',
                onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => const NewPatientScreen())),
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).brightness == Brightness.dark
                      ? ClinicalColors.darkActionFill
                      : ClinicalColors.lightActionFill,
                  foregroundColor: ClinicalColors.actionOnDarkFill,
                  minimumSize: const Size(46, 46)),
                icon: const Icon(Icons.add_rounded),
              ),
            ]),
            const SizedBox(height: 8),
            Text('${all.length} dossiers enregistrés',
              style: TextStyle(color: Palette.of(context).muted, fontSize: 14)),
            const SizedBox(height: 23),
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
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Dossiers', style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 5),
                  Text('${filtered.length} résultats',
                    style: TextStyle(
                      color: Palette.of(context).muted, fontSize: 14)),
                ],
              )),
              SvgPicture.asset(
                'assets/illustrations/patient_records.svg',
                width: 112,
                height: 76,
                fit: BoxFit.contain,
                semanticsLabel: 'Illustration de dossiers patients',
              ),
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
    color: selected ? Palette.of(context).tealSoft : Palette.of(context).surface,
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        child: Text(label, style: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w600,
          color: selected ? Palette.of(context).forest : Palette.of(context).muted)),
      ),
    ),
  );
}
