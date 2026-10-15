import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../app/theme.dart';
import '../../core/models/clinical_intake.dart';
import '../../core/state/store_context.dart';
import '../../core/state/connected_clinical_store.dart';
import '../auth/dev_auth_api.dart';
import '../../core/widgets/medical_ui.dart';

class NewPatientScreen extends StatefulWidget {
  const NewPatientScreen({super.key});

  @override
  State<NewPatientScreen> createState() => _NewPatientScreenState();
}

class _NewPatientScreenState extends State<NewPatientScreen> {
  bool _saving = false;
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  final age = TextEditingController();
  final phone = TextEditingController();
  final neighborhood = TextEditingController();
  final address = TextEditingController();
  final emergencyName = TextEditingController();
  final emergencyPhone = TextEditingController();
  final medications = TextEditingController();
  final surgicalHistory = TextEditingController();
  final familyHistory = TextEditingController();
  String sex = 'F';

  @override
  void dispose() {
    name.dispose();
    age.dispose();
    for (final controller in [
      phone,
      neighborhood,
      address,
      emergencyName,
      emergencyPhone,
      medications,
      surgicalHistory,
      familyHistory,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (_saving || !(form.currentState?.validate() ?? false)) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _saving = true);
    try {
      await context.store.addPatient(
        name: name.text,
        age: int.parse(age.text.trim()),
        sex: sex,
        phone: phone.text.trim(),
        profile: PatientProfileSupplement(
          neighborhood: neighborhood.text.trim(),
          address: address.text.trim(),
          emergencyContactName: emergencyName.text.trim(),
          emergencyContactPhone: emergencyPhone.text.trim(),
          currentMedications: medications.text.trim(),
          surgicalHistory: surgicalHistory.text.trim(),
          familyHistory: familyHistory.text.trim(),
        ),
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        final message = error is DevApiException
            ? error.message
            : 'Enregistrement impossible. Réessayez.';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _input(
    String label,
    TextEditingController controller, {
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
  }) =>
      TextFormField(
        controller: controller,
        keyboardType: maxLines > 1 ? TextInputType.multiline : keyboard,
        textCapitalization: TextCapitalization.sentences,
        minLines: maxLines > 1 ? 2 : 1,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label),
      );

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
                    Text('DOSSIER PATIENT',
                        style: TextStyle(
                          fontSize: 12,
                          letterSpacing: 1.3,
                          color: Palette.of(context).laserMuted,
                          fontWeight: FontWeight.w700,
                        )),
                    const SizedBox(height: 8),
                    const PageTitle(
                      title: 'Créer un dossier',
                      subtitle: 'Identité et coordonnées du patient.',
                    ),
                    const SizedBox(height: 20),
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
                            decoration: InputDecoration(
                              hintText:
                                  context.dependOnInheritedWidgetOfExactType<
                                              ConnectedClinicalScope>() !=
                                          null
                                      ? 'Nom complet du patient'
                                      : 'Nom complet du patient',
                            ),
                            validator: (v) => (v?.trim().length ?? 0) < 2
                                ? 'Saisissez au moins deux caractères.'
                                : null,
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
                                  ? 'Âge invalide.'
                                  : null;
                            },
                          ),
                          const SizedBox(height: 17),
                          const Text('Sexe',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 10),
                          LayoutBuilder(
                              builder: (context, box) => SizedBox(
                                    width: box.maxWidth,
                                    child: SegmentedButton<String>(
                                      segments: const [
                                        ButtonSegment(
                                            value: 'F', label: Text('Féminin')),
                                        ButtonSegment(
                                            value: 'M',
                                            label: Text('Masculin')),
                                        ButtonSegment(
                                            value: 'N',
                                            label: Text('Non précisé')),
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
                    const SizedBox(height: 14),
                    ClinicalDisclosureSection(
                      title: 'Adresse et contact',
                      subtitle: 'Facultatif',
                      icon: Icons.location_on_outlined,
                      child: Column(children: [
                        _input('Quartier', neighborhood),
                        const SizedBox(height: 13),
                        _input('Adresse', address, maxLines: 2),
                        const SizedBox(height: 13),
                        _input("Nom du contact d'urgence", emergencyName),
                        const SizedBox(height: 13),
                        _input("Téléphone du contact d'urgence", emergencyPhone,
                            keyboard: TextInputType.phone),
                      ]),
                    ),
                    const SizedBox(height: 14),
                    ClinicalDisclosureSection(
                      title: 'Informations médicales complémentaires',
                      subtitle: 'À renseigner si connues',
                      icon: Icons.medical_information_outlined,
                      child: Column(children: [
                        _input('Traitements habituels', medications,
                            maxLines: 3),
                        const SizedBox(height: 13),
                        _input('Antécédents chirurgicaux', surgicalHistory,
                            maxLines: 3),
                        const SizedBox(height: 13),
                        _input('Antécédents familiaux', familyHistory,
                            maxLines: 3),
                      ]),
                    ),
                    const SizedBox(height: 18),
                    // Also expose the save action inside the scrollable form.
                    // This remains reachable when Android hides the bottom bar
                    // while the soft keyboard is open.
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        key: const Key('patient-save-inline'),
                        onPressed: _saving ? null : save,
                        icon: const Icon(Icons.check_rounded),
                        label: Text(_saving
                            ? 'Enregistrement…'
                            : 'Enregistrer le patient'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.dependOnInheritedWidgetOfExactType<
                                  ConnectedClinicalScope>() !=
                              null
                          ? 'Enregistrement sécurisé du dossier.'
                          : kIsWeb
                              ? 'Environnement de test : données fictives uniquement.'
                              : 'Enregistrement local hors connexion ; synchronisation distante indisponible.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13, color: Palette.of(context).laserMuted),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Center(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    key: const Key('patient-save-bottom'),
                    onPressed: _saving ? null : save,
                    icon: const Icon(Icons.check_rounded),
                    label: Text(
                        _saving ? 'Enregistrement…' : 'Enregistrer le patient'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
