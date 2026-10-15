import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/models/clinical_intake.dart';
import '../../core/models/medical_models.dart';
import '../../core/state/store_context.dart';
import '../../core/widgets/medical_ui.dart';

/// Consultation enregistrée en lecture seule : pas de réécriture clinique.
class ConsultationDetailScreen extends StatefulWidget {
  const ConsultationDetailScreen({super.key, required this.visit});
  final Visit visit;

  @override
  State<ConsultationDetailScreen> createState() =>
      _ConsultationDetailScreenState();
}

class _ConsultationDetailScreenState extends State<ConsultationDetailScreen> {
  Future<ClinicalIntake?>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= context.store.visitIntake(widget.visit.id);
  }

  Widget _line(BuildContext context, String label, String? value) {
    if (value == null || value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: 12.5,
                color: Palette.of(context).muted,
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 5),
          SelectableText(value,
              style: TextStyle(
                fontSize: 14,
                height: 1.35,
                color: Palette.of(context).ink,
              )),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String title, IconData icon,
          List<Widget> entries) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: ClinicalFormSection(
          title: title,
          icon: icon,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: entries,
          ),
        ),
      );

  String _careLabel(CareDisposition disposition) => switch (disposition) {
        CareDisposition.undecided => 'Non déterminée',
        CareDisposition.outpatient => 'Traitement ambulatoire',
        CareDisposition.observation => 'Observation',
        CareDisposition.hospitalization => 'Hospitalisation',
        CareDisposition.referral => 'Orientation / transfert',
      };

  @override
  Widget build(BuildContext context) {
    final visit = widget.visit;
    return Scaffold(
      appBar: AppBar(title: const Text('Compte rendu de consultation')),
      body: SafeArea(
        child: ListView(
          children: [
            ScreenWidth(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 44),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PageTitle(
                    title: 'Consultation enregistrée',
                    subtitle: shortDate(visit.date),
                  ),
                  const SizedBox(height: 17),
                  _section(context, 'Motif et constantes',
                      Icons.monitor_heart_outlined, [
                    _line(context, 'Motif de consultation', visit.reason),
                    _line(context, 'Observations', visit.notes),
                    _line(context, 'Température (°C)',
                        visit.temperature?.toStringAsFixed(1)),
                    _line(
                        context,
                        'Tension (mmHg)',
                        visit.systolic == null || visit.diastolic == null
                            ? null
                            : '${visit.systolic} / ${visit.diastolic}'),
                    _line(context, 'Pouls (bpm)', visit.pulse?.toString()),
                    _line(context, 'SpO₂ (%)', visit.spo2?.toString()),
                  ]),
                  FutureBuilder<ClinicalIntake?>(
                    future: _future,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(
                            child: Padding(
                          padding: EdgeInsets.all(28),
                          child: CircularProgressIndicator(),
                        ));
                      }
                      if (snapshot.hasError) {
                        return const SurfaceCard(
                            child: Text(
                          'Le compte rendu complémentaire est inaccessible.',
                        ));
                      }
                      final intake = snapshot.data;
                      if (intake == null) {
                        return const SurfaceCard(
                            child: Text(
                          'Consultation antérieure : aucun complément clinique enregistré.',
                        ));
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _section(context, 'Mesures complémentaires',
                              Icons.scale_outlined, [
                            _line(context, 'Poids (kg)',
                                intake.weightKg?.toString()),
                            _line(context, 'Taille (cm)',
                                intake.heightCm?.toString()),
                            _line(context, 'Fréquence respiratoire (/min)',
                                intake.respiratoryRate?.toString()),
                          ]),
                          _section(context, 'Histoire et signes',
                              Icons.notes_outlined, [
                            _line(context, 'Histoire de la maladie',
                                intake.symptomHistory),
                            _line(context, 'Signes associés',
                                intake.associatedSigns),
                          ]),
                          _section(context, 'Examen physique',
                              Icons.personal_injury_outlined, [
                            _line(context, 'État général',
                                intake.generalCondition),
                            _line(context, 'Examen physique',
                                intake.physicalExamination),
                            _line(context, 'Examen par appareils',
                                intake.systemsExamination),
                          ]),
                          _section(context, 'Diagnostic',
                              Icons.medical_information_outlined, [
                            _line(context, 'Hypothèses diagnostiques',
                                intake.diagnosticHypotheses),
                            _line(
                                context, 'Diagnostic retenu', intake.diagnosis),
                          ]),
                          _section(context, 'Bilan et résultats',
                              Icons.biotech_outlined, [
                            _line(context, 'Bilan demandé',
                                intake.investigationsRequested),
                            _line(context, 'Résultats et interprétation',
                                intake.investigationsInterpretation),
                          ]),
                          _section(context, 'Prise en charge',
                              Icons.fact_check_outlined, [
                            _line(context, 'Conduite à tenir',
                                intake.managementPlan),
                            _line(context, 'Décision de prise en charge',
                                _careLabel(intake.careDisposition)),
                            _line(context, 'Traitement ambulatoire',
                                intake.outpatientTreatment),
                            _line(context, 'Motif d’hospitalisation',
                                intake.hospitalizationReason),
                            _line(context, 'Transfert / orientation',
                                intake.referralDetails),
                            _line(context, 'Consignes et suivi',
                                intake.followUpInstructions),
                          ]),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  Text(
                      'Document en lecture seule. Aucune synchronisation distante.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Palette.of(context).muted, fontSize: 12.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
