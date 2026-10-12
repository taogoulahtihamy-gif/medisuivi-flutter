import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../core/models/medical_models.dart';
import '../../core/state/demo_store.dart';
import '../../core/widgets/medical_ui.dart';

class NewConsultationScreen extends StatefulWidget {
  const NewConsultationScreen({super.key, required this.patient});
  final Patient patient;

  @override
  State<NewConsultationScreen> createState() => _NewConsultationScreenState();
}

class _NewConsultationScreenState extends State<NewConsultationScreen> {
  final form = GlobalKey<FormState>();
  final reason = TextEditingController();
  final temp = TextEditingController();
  final systolic = TextEditingController();
  final diastolic = TextEditingController();
  final pulse = TextEditingController();
  final spo2 = TextEditingController();
  final notes = TextEditingController();

  @override
  void dispose() {
    for (final c in [reason, temp, systolic, diastolic, pulse, spo2, notes]) {
      c.dispose();
    }
    super.dispose();
  }

  double? number(String value) =>
    double.tryParse(value.trim().replaceAll(',', '.'));

  String? checkNumber(String? input, double min, double max, bool integerOnly) {
    if (input == null || input.trim().isEmpty) return null;
    final n = number(input);
    if (n == null || n < min || n > max ||
        (integerOnly && n != n.truncateToDouble())) {
      return 'Valeur invalide.';
    }
    return null;
  }

  Widget field(String label, TextEditingController controller,
    double min, double max, {bool integerOnly = true}) =>
      TextFormField(
        controller: controller,
        keyboardType: TextInputType.numberWithOptions(decimal: !integerOnly),
        decoration: InputDecoration(labelText: label),
        validator: (value) => checkNumber(value, min, max, integerOnly),
      );

  Widget pair(Widget left, Widget right) =>
    LayoutBuilder(builder: (context, box) => box.maxWidth < 390
      ? Column(children: [
          left, const SizedBox(height: 12), right,
        ])
      : Row(children: [
          Expanded(child: left),
          const SizedBox(width: 12),
          Expanded(child: right),
        ]));

  void save() {
    if (!(form.currentState?.validate() ?? false)) return;
    DemoScope.of(context).addVisit(
      patientId: widget.patient.id,
      reason: reason.text,
      temperature: number(temp.text),
      systolic: int.tryParse(systolic.text),
      diastolic: int.tryParse(diastolic.text),
      pulse: int.tryParse(pulse.text),
      spo2: int.tryParse(spo2.text),
      notes: notes.text,
    );
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(const SnackBar(
      content: Text('Consultation ajoutée pour cette session.'),
    ));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Nouvelle consultation')),
    body: SafeArea(child: SingleChildScrollView(child: ScreenWidth(
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
                      ? 'Indiquez le motif.' : null,
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
            ClinicalFormSection(
              title: 'Constantes vitales',
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
            const SizedBox(height: 21),
            ElevatedButton.icon(
              onPressed: save,
              icon: const Icon(Icons.check_rounded),
              label: const Text('Enregistrer la consultation'),
            ),
            const SizedBox(height: 12),
            Text(
              'Aucune donnée n’est envoyée à un serveur ou conservée après fermeture.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13, color: Palette.of(context).laserMuted),
            ),
          ],
        ),
      ),
    ))),
  );
}
