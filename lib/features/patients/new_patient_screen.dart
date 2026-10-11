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
        phone: phone.text);
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(
        const SnackBar(content: Text('Fiche fictive ajoutée temporairement.')));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Nouveau patient')),
        body: SafeArea(
            child: SingleChildScrollView(
                child: ScreenWidth(
                    child: Form(
                        key: form,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const PageTitle(
                                  title: 'Créer un dossier',
                                  subtitle:
                                      'Identité du patient · démonstration'),
                              const SizedBox(height: 20),
                              const DemoNotice(),
                              const SizedBox(height: 20),
                              const Text('Nom complet',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 9),
                              CustomTextField(
                                  label: 'Nom complet',
                                  controller: name,
                                  hint: 'Ex. Patient Démo',
                                  validator: (v) => (v?.trim().length ?? 0) < 2
                                      ? 'Saisissez au moins deux caractères.'
                                      : null),
                              const SizedBox(height: 17),
                              const Text('Âge en années',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 9),
                              CustomTextField(
                                  label: 'Âge en années',
                                  controller: age,
                                  keyboardType: TextInputType.number,
                                  validator: (v) {
                                    final a = int.tryParse(v?.trim() ?? '');
                                    return (a == null || a < 0 || a > 125)
                                        ? 'Âge invalide.'
                                        : null;
                                  }),
                              const SizedBox(height: 17),
                              const Text('Sexe',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 9),
                              Wrap(spacing: 8, runSpacing: 8, children: [
                                for (final entry in const {
                                  'F': 'Féminin',
                                  'M': 'Masculin',
                                  'N': 'Non précisé'
                                }.entries)
                                  ChoiceChip(
                                      label: Text(entry.value),
                                      selected: sex == entry.key,
                                      onSelected: (_) =>
                                          setState(() => sex = entry.key)),
                              ]),
                              const SizedBox(height: 17),
                              const Text('Téléphone (facultatif)',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 9),
                              CustomTextField(
                                  label: 'Téléphone (facultatif)',
                                  controller: phone,
                                  keyboardType: TextInputType.phone),
                              const SizedBox(height: 28),
                              PrimaryButton(
                                  onPressed: save,
                                  icon: Icons.check_rounded,
                                  label: 'Ajouter ce patient démo'),
                              const SizedBox(height: 12),
                              const Text(
                                  'Les saisies en V0 ne sont pas sauvegardées après la fermeture.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 12, color: Palette.muted)),
                            ]))))),
      );
}
