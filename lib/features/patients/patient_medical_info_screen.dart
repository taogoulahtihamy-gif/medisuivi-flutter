import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../app/theme.dart';
import '../../core/models/medical_models.dart';
import '../../core/models/clinical_intake.dart';
import '../../core/state/store_context.dart';
import '../../core/widgets/medical_ui.dart';

/// Édition des informations du patient via le ClinicalStore chiffré.
class PatientMedicalInfoScreen extends StatefulWidget {
  const PatientMedicalInfoScreen({super.key, required this.patient});
  final Patient patient;
  @override
  State<PatientMedicalInfoScreen> createState() => _PatientMedicalInfoScreenState();
}

class _PatientMedicalInfoScreenState extends State<PatientMedicalInfoScreen> {
  bool _saving = false;
  bool _loadingProfile = true;
  bool _profileLoadFailed = false;
  bool _profileRequested = false;
  final neighborhood = TextEditingController();
  final address = TextEditingController();
  final emergencyName = TextEditingController();
  final emergencyPhone = TextEditingController();
  final medications = TextEditingController();
  final surgicalHistory = TextEditingController();
  final familyHistory = TextEditingController();
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_profileRequested) {
      _profileRequested = true;
      _loadProfile();
    }
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loadingProfile = true;
      _profileLoadFailed = false;
    });
    try {
      final profile = await context.store.patientProfile(widget.patient.id);
      if (!mounted) return;
      neighborhood.text = profile?.neighborhood ?? '';
      address.text = profile?.address ?? '';
      emergencyName.text = profile?.emergencyContactName ?? '';
      emergencyPhone.text = profile?.emergencyContactPhone ?? '';
      medications.text = profile?.currentMedications ?? '';
      surgicalHistory.text = profile?.surgicalHistory ?? '';
      familyHistory.text = profile?.familyHistory ?? '';
      setState(() => _loadingProfile = false);
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingProfile = false;
          _profileLoadFailed = true;
        });
      }
    }
  }

  Widget _entry(String label, TextEditingController controller, {
    bool multiline = false,
    TextInputType keyboardType = TextInputType.text,
  }) => TextFormField(
    controller: controller,
    keyboardType: multiline ? TextInputType.multiline : keyboardType,
    textCapitalization: TextCapitalization.sentences,
    minLines: multiline ? 2 : 1,
    maxLines: multiline ? 4 : 1,
    decoration: InputDecoration(labelText: label),
  );

  @override
  void dispose() {
    phone.dispose();
    allergies.dispose();
    history.dispose();
    for (final controller in [
      neighborhood, address, emergencyName, emergencyPhone,
      medications, surgicalHistory, familyHistory,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || _loadingProfile || _profileLoadFailed ||
        !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await context.store.updatePatientInfo(
        patientId: widget.patient.id,
        phone: phone.text,
        allergies: allergies.text,
        medicalHistory: history.text,
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
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Enregistrement impossible. Réessayez.'),
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Informations médicales')),
    body: SafeArea(child: SingleChildScrollView(
      child: ScreenWidth(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 36),
        child: _loadingProfile
          ? const Center(child: Padding(
              padding: EdgeInsets.all(28),
              child: CircularProgressIndicator(),
            ))
          : _profileLoadFailed
            ? Column(children: [
                const Text("Impossible de charger les informations enregistrées."),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _loadProfile,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Réessayer'),
                ),
              ])
            : Form(key: _formKey,
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
              const SizedBox(height: 14),
              ClinicalDisclosureSection(
                icon: Icons.location_on_outlined,
                title: 'Adresse et contact',
                subtitle: 'Informations complémentaires',
                child: Column(children: [
                  _entry('Quartier', neighborhood),
                  const SizedBox(height: 13),
                  _entry('Adresse', address, multiline: true),
                  const SizedBox(height: 13),
                  _entry("Nom du contact d'urgence", emergencyName),
                  const SizedBox(height: 13),
                  _entry("Téléphone du contact d'urgence", emergencyPhone,
                    keyboardType: TextInputType.phone),
                ]),
              ),
              const SizedBox(height: 14),
              ClinicalDisclosureSection(
                icon: Icons.medical_services_outlined,
                title: 'Antécédents complémentaires',
                child: Column(children: [
                  _entry('Traitements habituels', medications, multiline: true),
                  const SizedBox(height: 13),
                  _entry('Antécédents chirurgicaux', surgicalHistory, multiline: true),
                  const SizedBox(height: 13),
                  _entry('Antécédents familiaux', familyHistory, multiline: true),
                ]),
              ),

              const SizedBox(height: 13),
              Text(
                kIsWeb ? 'Version Web : données fictives temporaires.' : 'Données enregistrées localement ; synchronisation indisponible.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Palette.of(context).muted, fontSize: 12.5),
              ),
            ],
          ),
        ),
      ),
    )),
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
            onPressed: _saving || _loadingProfile || _profileLoadFailed
                ? null : _save,
            icon: const Icon(Icons.check_rounded),
            label: Text(_saving ? 'Enregistrement…' : 'Enregistrer les informations'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
