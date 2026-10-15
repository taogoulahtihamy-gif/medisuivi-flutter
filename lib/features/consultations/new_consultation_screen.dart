import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../core/models/medical_models.dart';
import '../../core/models/clinical_intake.dart';
import '../../core/state/store_context.dart';
import '../../core/widgets/medical_ui.dart';

class NewConsultationScreen extends StatefulWidget {
  const NewConsultationScreen({super.key, required this.patient});
  final Patient patient;

  @override
  State<NewConsultationScreen> createState() => _NewConsultationScreenState();
}

class _NewConsultationScreenState extends State<NewConsultationScreen> {
  bool _saving = false;
  final form = GlobalKey<FormState>();
  final reason = TextEditingController();
  final temp = TextEditingController();
  final systolic = TextEditingController();
  final diastolic = TextEditingController();
  final pulse = TextEditingController();
  final spo2 = TextEditingController();
  final notes = TextEditingController();
  final weight = TextEditingController();
  final height = TextEditingController();
  final respiratoryRate = TextEditingController();
  final symptomHistory = TextEditingController();
  final associatedSigns = TextEditingController();
  final generalCondition = TextEditingController();
  final physicalExamination = TextEditingController();
  final systemsExamination = TextEditingController();
  final diagnosticHypotheses = TextEditingController();
  final diagnosis = TextEditingController();
  final investigationsRequested = TextEditingController();
  final investigationsInterpretation = TextEditingController();
  final managementPlan = TextEditingController();
  final outpatientTreatment = TextEditingController();
  final hospitalizationReason = TextEditingController();
  final referralDetails = TextEditingController();
  final followUpInstructions = TextEditingController();
  CareDisposition _disposition = CareDisposition.undecided;

  @override
  void dispose() {
    for (final c in [
      reason,
      temp,
      systolic,
      diastolic,
      pulse,
      spo2,
      notes,
      weight,
      height,
      respiratoryRate,
      symptomHistory,
      associatedSigns,
      generalCondition,
      physicalExamination,
      systemsExamination,
      diagnosticHypotheses,
      diagnosis,
      investigationsRequested,
      investigationsInterpretation,
      managementPlan,
      outpatientTreatment,
      hospitalizationReason,
      referralDetails,
      followUpInstructions,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double? number(String value) =>
      double.tryParse(value.trim().replaceAll(',', '.'));

  String? checkNumber(String? input, double min, double max, bool integerOnly) {
    if (input == null || input.trim().isEmpty) return null;
    final n = number(input);
    if (n == null ||
        !n.isFinite ||
        n < min ||
        n > max ||
        (integerOnly && n != n.truncateToDouble())) {
      return 'Valeur invalide.';
    }
    return null;
  }

  Widget field(String label, TextEditingController controller, double min,
          double max,
          {bool integerOnly = true}) =>
      TextFormField(
        controller: controller,
        keyboardType: TextInputType.numberWithOptions(decimal: !integerOnly),
        decoration: InputDecoration(labelText: label),
        validator: (value) => checkNumber(value, min, max, integerOnly),
      );

  Widget pair(Widget left, Widget right) => LayoutBuilder(
      builder: (context, box) => box.maxWidth < 390
          ? Column(children: [
              left,
              const SizedBox(height: 12),
              right,
            ])
          : Row(children: [
              Expanded(child: left),
              const SizedBox(width: 12),
              Expanded(child: right),
            ]));

  Widget _textEntry(
    String label,
    TextEditingController controller, {
    int lines = 3,
    String? hint,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
        minLines: lines == 1 ? 1 : 2,
        maxLines: lines,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
            labelText: label, hintText: hint, alignLabelWithHint: lines > 1),
        validator: validator,
      );

  Widget _divider() => const SizedBox(height: 13);

  ClinicalIntake _intake() => ClinicalIntake(
        weightKg: number(weight.text),
        heightCm: number(height.text),
        respiratoryRate: int.tryParse(respiratoryRate.text.trim()),
        symptomHistory: symptomHistory.text.trim(),
        associatedSigns: associatedSigns.text.trim(),
        generalCondition: generalCondition.text.trim(),
        physicalExamination: physicalExamination.text.trim(),
        systemsExamination: systemsExamination.text.trim(),
        diagnosticHypotheses: diagnosticHypotheses.text.trim(),
        diagnosis: diagnosis.text.trim(),
        investigationsRequested: investigationsRequested.text.trim(),
        investigationsInterpretation: investigationsInterpretation.text.trim(),
        managementPlan: managementPlan.text.trim(),
        outpatientTreatment: _disposition == CareDisposition.outpatient
            ? outpatientTreatment.text.trim()
            : '',
        hospitalizationReason: _disposition == CareDisposition.hospitalization
            ? hospitalizationReason.text.trim()
            : '',
        referralDetails: _disposition == CareDisposition.referral
            ? referralDetails.text.trim()
            : '',
        followUpInstructions: followUpInstructions.text.trim(),
        careDisposition: _disposition,
      );

  /// Les sections repliées ne doivent pas contourner la validation numérique.
  String? _hiddenMeasurementError() {
    final measurements =
        <(String, TextEditingController, double, double, bool)>[
      ('Température', temp, 25, 45, false),
      ('Pouls', pulse, 20, 250, true),
      ('TA systolique', systolic, 40, 300, true),
      ('TA diastolique', diastolic, 20, 200, true),
      ('SpO₂', spo2, 0, 100, true),
      ('Poids', weight, 0.1, 500, false),
      ('Taille', height, 0.1, 300, false),
      ('Fréquence respiratoire', respiratoryRate, 1, 100, true),
    ];
    for (final (label, controller, min, max, integerOnly) in measurements) {
      if (checkNumber(controller.text, min, max, integerOnly) != null) {
        return 'Mesure invalide : $label';
      }
    }
    return null;
  }

  Future<void> save() async {
    if (_saving || !(form.currentState?.validate() ?? false)) return;
    final measurementError = _hiddenMeasurementError();
    if (measurementError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(measurementError)),
      );
      return;
    }
    final intake = _intake();
    final issues = intake.validate();
    if (issues.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(issues.first)),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await context.store.addVisit(
        patientId: widget.patient.id,
        reason: reason.text,
        temperature: number(temp.text),
        systolic: int.tryParse(systolic.text),
        diastolic: int.tryParse(diastolic.text),
        pulse: int.tryParse(pulse.text),
        spo2: int.tryParse(spo2.text),
        notes: notes.text.trim(),
        intake: intake,
      );
      if (!mounted) return;
      Navigator.pop(context);
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
        appBar: AppBar(title: const Text('Nouvelle consultation')),
        body: SafeArea(
            child: SingleChildScrollView(
                child: ScreenWidth(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 38),
          child: Form(
            key: form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('CONSULTATION CLINIQUE',
                    style: TextStyle(
                      color: Palette.of(context).laserMuted,
                      letterSpacing: 1.2,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    )),
                const SizedBox(height: 9),
                PageTitle(title: 'Consultation', subtitle: widget.patient.name),
                const SizedBox(height: 18),
                ClinicalFormSection(
                  title: 'Informations de visite',
                  icon: Icons.description_outlined,
                  subtitle: 'Motif et observations',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Motif de consultation',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 9),
                      TextFormField(
                        controller: reason,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                            hintText: 'Ex. Visite de contrôle'),
                        validator: (v) => (v?.trim().length ?? 0) < 3
                            ? 'Indiquez le motif.'
                            : null,
                      ),
                      const SizedBox(height: 17),
                      const Text('Observations',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 9),
                      TextFormField(
                        controller: notes,
                        minLines: 3,
                        maxLines: 5,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                            hintText: 'Notes de consultation'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                ClinicalDisclosureSection(
                  title: 'Constantes vitales',
                  initiallyExpanded: true,
                  icon: Icons.monitor_heart_outlined,
                  subtitle: 'Mesures lors de la visite',
                  child: Column(children: [
                    pair(
                      field('Température (°C)', temp, 25, 45,
                          integerOnly: false),
                      field('Pouls (bpm)', pulse, 20, 250),
                    ),
                    const SizedBox(height: 12),
                    pair(
                      field('TA syst. (mmHg)', systolic, 40, 300),
                      field('TA diast. (mmHg)', diastolic, 20, 200),
                    ),
                    const SizedBox(height: 12),
                    field('Saturation SpO₂ (%)', spo2, 0, 100),
                  ]),
                ),
                const SizedBox(height: 14),
                ClinicalDisclosureSection(
                  title: 'Mesures complémentaires',
                  icon: Icons.scale_outlined,
                  subtitle: 'Facultatif ; unités indiquées',
                  child: Column(children: [
                    pair(
                      field('Poids (kg)', weight, 0.1, 500, integerOnly: false),
                      field('Taille (cm)', height, 0.1, 300,
                          integerOnly: false),
                    ),
                    _divider(),
                    field('Fréquence respiratoire (/min)', respiratoryRate, 1,
                        100),
                  ]),
                ),
                const SizedBox(height: 14),
                ClinicalDisclosureSection(
                  title: 'Histoire et signes',
                  icon: Icons.notes_outlined,
                  child: Column(children: [
                    _textEntry('Histoire de la maladie', symptomHistory),
                    _divider(),
                    _textEntry('Signes associés', associatedSigns),
                  ]),
                ),
                const SizedBox(height: 14),
                ClinicalDisclosureSection(
                  title: 'Examen physique',
                  icon: Icons.personal_injury_outlined,
                  child: Column(children: [
                    _textEntry('État général', generalCondition),
                    _divider(),
                    _textEntry('Examen physique', physicalExamination),
                    _divider(),
                    _textEntry('Examen par appareils', systemsExamination,
                        hint: 'Respiratoire, cardiovasculaire, digestif…'),
                  ]),
                ),
                const SizedBox(height: 14),
                ClinicalDisclosureSection(
                  title: 'Diagnostic',
                  icon: Icons.medical_information_outlined,
                  child: Column(children: [
                    _textEntry(
                        'Hypothèses diagnostiques', diagnosticHypotheses),
                    _divider(),
                    _textEntry('Diagnostic retenu', diagnosis),
                  ]),
                ),
                const SizedBox(height: 14),
                ClinicalDisclosureSection(
                  title: 'Bilan et résultats',
                  icon: Icons.biotech_outlined,
                  subtitle:
                      'Les examens prescrits disposent aussi de leur suivi dédié.',
                  child: Column(children: [
                    _textEntry('Bilan demandé', investigationsRequested),
                    _divider(),
                    _textEntry('Résultats et interprétation du praticien',
                        investigationsInterpretation),
                  ]),
                ),
                const SizedBox(height: 14),
                ClinicalDisclosureSection(
                  title: 'Conduite à tenir',
                  icon: Icons.fact_check_outlined,
                  child: Column(children: [
                    _textEntry('Plan de prise en charge', managementPlan),
                    _divider(),
                    DropdownButtonFormField<CareDisposition>(
                      initialValue: _disposition,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Décision de prise en charge',
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: CareDisposition.undecided,
                            child: Text('Non déterminée')),
                        DropdownMenuItem(
                            value: CareDisposition.outpatient,
                            child: Text('Traitement ambulatoire')),
                        DropdownMenuItem(
                            value: CareDisposition.observation,
                            child: Text('Observation')),
                        DropdownMenuItem(
                            value: CareDisposition.hospitalization,
                            child: Text('Hospitalisation')),
                        DropdownMenuItem(
                            value: CareDisposition.referral,
                            child: Text('Orientation / transfert')),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _disposition = value);
                      },
                    ),
                    if (_disposition == CareDisposition.outpatient) ...[
                      _divider(),
                      _textEntry('Traitement ambulatoire', outpatientTreatment),
                    ],
                    if (_disposition == CareDisposition.hospitalization) ...[
                      _divider(),
                      _textEntry(
                          "Motif d'hospitalisation", hospitalizationReason,
                          validator: (value) => (value?.trim().isEmpty ?? true)
                              ? "Précisez le motif d'hospitalisation."
                              : null),
                    ],
                    if (_disposition == CareDisposition.referral) ...[
                      _divider(),
                      _textEntry(
                          'Destination et motif du transfert', referralDetails,
                          validator: (value) => (value?.trim().isEmpty ?? true)
                              ? 'Précisez la destination du transfert.'
                              : null),
                    ],
                    _divider(),
                    _textEntry('Consignes et suivi', followUpInstructions),
                  ]),
                ),
              ],
            ),
          ),
        ))),
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
                    onPressed: _saving ? null : save,
                    icon: const Icon(Icons.check_rounded),
                    label: Text(_saving
                        ? 'Enregistrement…'
                        : 'Enregistrer la consultation'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
