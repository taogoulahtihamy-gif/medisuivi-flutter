import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../core/state/demo_store.dart';
import '../../core/widgets/medical_ui.dart';

class NewPatientScreen extends StatefulWidget {
  const NewPatientScreen({super.key});

  @override
  State<NewPatientScreen> createState() => _NewPatientScreenState();
}

class _NewPatientScreenState extends State<NewPatientScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  final age = TextEditingController();
  final phone = TextEditingController();
  String sex = 'F';

  @override
  void dispose() {
    name.dispose();
    age.dispose();
    phone.dispose();
    super.dispose();
  }

  void save() {
    if (!(form.currentState?.validate() ?? false)) return;
    DemoScope.of(context).addPatient(
      name: name.text,
      age: int.parse(age.text.trim()),
      sex: sex,
      phone: phone.text,
    );
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(const SnackBar(
      content: Text('Fiche fictive ajoutée temporairement.'),
    ));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Nouveau patient')),
    body: SafeArea(
      child: SingleChildScrollView(
        child: ScreenWidth(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 38),
          child: Form(
            key: form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('DOSSIER PATIENT', style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 1.3,
                  color: Palette.laserMuted,
                  fontWeight: FontWeight.w700,
                )),
                const SizedBox(height: 8),
                const PageTitle(
                  title: 'Créer un dossier',
                  subtitle: 'Identité et coordonnées du patient.',
                ),
                const SizedBox(height: 20),
                const DemoNotice(),
                const SizedBox(height: 18),
                ClinicalFormSection(
                  title: 'Identité du patient',
                  subtitle: 'Informations d’identification',
                  icon: Icons.badge_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Nom complet',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 9),
                      TextFormField(
                        controller: name,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          hintText: 'Ex. Patient Démo',
                        ),
                        validator: (v) => (v?.trim().length ?? 0) < 2
                          ? 'Saisissez au moins deux caractères.' : null,
                      ),
                      const SizedBox(height: 17),
                      const Text('Âge en années',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 9),
                      TextFormField(
                        controller: age,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: 'Âge'),
                        validator: (v) {
                          final a = int.tryParse(v?.trim() ?? '');
                          return (a == null || a < 0 || a > 125)
                            ? 'Âge invalide.' : null;
                        },
                      ),
                      const SizedBox(height: 17),
                      const Text('Sexe',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      LayoutBuilder(builder: (context, box) => SizedBox(
                        width: box.maxWidth,
                        child: SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(
                              value: 'F', label: Text('Féminin')),
                            ButtonSegment(
                              value: 'M', label: Text('Masculin')),
                            ButtonSegment(
                              value: 'N', label: Text('Non précisé')),
                          ],
                          selected: {sex},
                          onSelectionChanged: (values) =>
                            setState(() => sex = values.first),
                          showSelectedIcon: false,
                        ),
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                ClinicalFormSection(
                  title: 'Coordonnées',
                  subtitle: 'Facultatif',
                  icon: Icons.call_outlined,
                  child: TextFormField(
                    controller: phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Téléphone',
                      hintText: 'Numéro de téléphone',
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                ElevatedButton.icon(
                  onPressed: save,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Ajouter ce patient démo'),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Les saisies en V0 ne sont pas sauvegardées après la fermeture.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Palette.laserMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
