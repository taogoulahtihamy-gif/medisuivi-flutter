import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../core/models/medical_models.dart';
import '../../core/state/store_context.dart';
import '../../core/widgets/medical_ui.dart';

/// Informations complémentaires de la fiche. Données de session uniquement.
class PatientMedicalInfoScreen extends StatefulWidget {
  const PatientMedicalInfoScreen({super.key, required this.patient});
  final Patient patient;
  @override
  State<PatientMedicalInfoScreen> createState() => _PatientMedicalInfoScreenState();
}

class _PatientMedicalInfoScreenState extends State<PatientMedicalInfoScreen> {
  late final TextEditingController phone;
  late final TextEditingController allergies;
  late final TextEditingController history;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    phone = TextEditingController(text:
      widget.patient.phone == 'Non renseigné' ? '' : widget.patient.phone);
    allergies = TextEditingController(text:
      widget.patient.allergies == 'Non renseignées' ? '' : widget.patient.allergies);
    history = TextEditingController(text:
      widget.patient.medicalHistory == 'Non renseignés'
        ? '' : widget.patient.medicalHistory);
  }

  @override
  void dispose() {
    phone.dispose();
    allergies.dispose();
    history.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    context.store.updatePatientInfo(
      patientId: widget.patient.id,
      phone: phone.text,
      allergies: allergies.text,
      medicalHistory: history.text,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Informations médicales')),
    body: SafeArea(child: SingleChildScrollView(
      child: ScreenWidth(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 36),
        child: Form(key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageTitle(title: 'Compléter le dossier',
                subtitle: widget.patient.name),
              const SizedBox(height: 22),
              ClinicalFormSection(
                icon: Icons.medical_information_outlined,
                title: 'Antécédents et allergies',
                subtitle: 'Informations déclarées ou observées',
                child: Column(children: [
                  TextFormField(
                    controller: history,
                    maxLines: 4, minLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Antécédents médicaux',
                      alignLabelWithHint: true,
                      hintText: 'Antécédents connus, traitements habituels…'),
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: allergies,
                    maxLines: 3, minLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Allergies connues',
                      alignLabelWithHint: true,
                      hintText: 'Allergies rapportées ou non renseignées'),
                  ),
                ]),
              ),
              const SizedBox(height: 14),
              ClinicalFormSection(
                icon: Icons.contact_phone_outlined,
                title: 'Coordonnées',
                child: TextFormField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Téléphone', hintText: 'Numéro du patient'),
                ),
              ),
              const SizedBox(height: 21),
              ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check_rounded),
                label: const Text('Enregistrer les informations'),
              ),
              const SizedBox(height: 13),
              Text(
                'Enregistrement temporaire. Ces données ne sont pas conservées après fermeture.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Palette.of(context).muted, fontSize: 12.5),
              ),
            ],
          ),
        ),
      ),
    )),
  );
}
