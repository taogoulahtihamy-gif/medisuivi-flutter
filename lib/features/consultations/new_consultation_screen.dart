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
    for (final c in [reason, temp, systolic, diastolic, pulse, spo2, notes]) { c.dispose(); }
    super.dispose();
  }
  double? number(String value) => double.tryParse(value.trim().replaceAll(',', '.'));
  String? checkNumber(String? input, double min, double max, bool integerOnly) {
    if (input == null || input.trim().isEmpty) return null;
    final n = number(input);
    if (n == null || n < min || n > max || (integerOnly && n != n.truncateToDouble())) return 'Valeur invalide.';
    return null;
  }
  Widget field(String label, TextEditingController controller, double min, double max, {bool integerOnly = true}) =>
    TextFormField(controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: !integerOnly),
      decoration: InputDecoration(labelText: label),
      validator: (v) => checkNumber(v, min, max, integerOnly));
  void save() {
    if (!(form.currentState?.validate() ?? false)) return;
    DemoScope.of(context).addVisit(
      patientId: widget.patient.id, reason: reason.text,
      temperature: number(temp.text), systolic: int.tryParse(systolic.text),
      diastolic: int.tryParse(diastolic.text), pulse: int.tryParse(pulse.text),
      spo2: int.tryParse(spo2.text), notes: notes.text);
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(const SnackBar(content: Text('Consultation fictive enregistrée temporairement.')));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Nouvelle consultation')),
    body: SafeArea(child: SingleChildScrollView(child: ScreenWidth(child: Form(key: form,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        PageTitle(title: 'Consultation', subtitle: widget.patient.name),
        const SizedBox(height: 17),
        const DemoNotice(),
        const SizedBox(height: 22),
        const Text('Motif de consultation', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 9),
        TextFormField(controller: reason, textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Ex. Visite de contrôle'),
          validator: (v) => (v?.trim().length ?? 0) < 3 ? 'Indiquez le motif.' : null),
        const SizedBox(height: 23),
        const SectionHeading(title: 'Constantes vitales'),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: field('Temp. (°C)', temp, 25, 45, integerOnly: false)),
          const SizedBox(width: 10),
          Expanded(child: field('Pouls (bpm)', pulse, 20, 250)),
        ]),
        const SizedBox(height: 11),
        Row(children: [
          Expanded(child: field('TA syst. (mmHg)', systolic, 40, 300)),
          const SizedBox(width: 10),
          Expanded(child: field('TA diast. (mmHg)', diastolic, 20, 200)),
        ]),
        const SizedBox(height: 11),
        field('Saturation SpO₂ (%)', spo2, 0, 100),
        const SizedBox(height: 23),
        const Text('Observations', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 9),
        TextFormField(controller: notes, maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Notes fictives de consultation')),
        const SizedBox(height: 25),
        ElevatedButton.icon(onPressed: save, icon: const Icon(Icons.check_rounded),
          label: const Text('Enregistrer la visite démo')),
        const SizedBox(height: 12),
        const Text('Aucune donnée n’est envoyée à un serveur ou conservée après fermeture.',
          textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Palette.muted)),
      ]))))),
  );
}
