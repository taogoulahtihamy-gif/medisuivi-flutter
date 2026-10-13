import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:medisuivi/core/models/clinical_intake.dart';

void main() {
  group('Sprint 5A : contrat clinique', () {
    test('les nouvelles rubriques complètes conservent leurs valeurs', () {
      const intake = ClinicalIntake(
        weightKg: 72.5,
        heightCm: 169,
        respiratoryRate: 18,
        symptomHistory: 'Symptômes fictifs depuis 2 jours',
        associatedSigns: 'Fatigue fictive',
        generalCondition: 'État général renseigné',
        physicalExamination: 'Examen physique renseigné',
        systemsExamination: 'Appareil respiratoire renseigné',
        diagnosticHypotheses: 'Hypothèse fictive',
        diagnosis: 'Diagnostic à confirmer',
        investigationsRequested: 'Bilan demandé',
        investigationsInterpretation: 'Résultats examinés',
        managementPlan: 'Surveillance et réévaluation',
        outpatientTreatment: 'Prescription rédigée par le praticien',
        followUpInstructions: 'Revoir sous contrôle',
        careDisposition: CareDisposition.outpatient,
      );
      final serialized = jsonEncode(intake.toJson());
      final restored = ClinicalIntake.fromJson(
        jsonDecode(serialized) as Map<String, dynamic>,
      );
      expect(restored.weightKg, 72.5);
      expect(restored.heightCm, 169);
      expect(restored.respiratoryRate, 18);
      expect(restored.associatedSigns, 'Fatigue fictive');
      expect(restored.generalCondition, 'État général renseigné');
      expect(restored.physicalExamination, 'Examen physique renseigné');
      expect(restored.systemsExamination, 'Appareil respiratoire renseigné');
      expect(restored.diagnosticHypotheses, 'Hypothèse fictive');
      expect(restored.diagnosis, 'Diagnostic à confirmer');
      expect(restored.investigationsRequested, 'Bilan demandé');
      expect(restored.investigationsInterpretation, 'Résultats examinés');
      expect(restored.managementPlan, 'Surveillance et réévaluation');
      expect(restored.outpatientTreatment, contains('praticien'));
      expect(restored.followUpInstructions, 'Revoir sous contrôle');
      expect(restored.careDisposition, CareDisposition.outpatient);
      expect(restored.validate(), isEmpty);
    });

    test('le complément patient garde quartier et contact urgence', () {
      const profile = PatientProfileSupplement(
        neighborhood: 'Quartier fictif',
        address: 'Adresse fictive',
        emergencyContactName: 'Personne test',
        emergencyContactPhone: '000000000',
        currentMedications: 'Médicament fictif',
        surgicalHistory: 'Non communiqué',
        familyHistory: 'Non communiqué',
      );
      final restored = PatientProfileSupplement.fromJson(
        jsonDecode(jsonEncode(profile.toJson())) as Map<String, dynamic>,
      );
      expect(restored.neighborhood, 'Quartier fictif');
      expect(restored.address, 'Adresse fictive');
      expect(restored.emergencyContactName, 'Personne test');
      expect(restored.currentMedications, 'Médicament fictif');
      expect(restored.familyHistory, 'Non communiqué');
    });

    test('une nouvelle fiche vide ne fabrique pas de constat clinique', () {
      const intake = ClinicalIntake();
      expect(intake.careDisposition, CareDisposition.undecided);
      expect(intake.weightKg, isNull);
      expect(intake.toJson()['diagnosis'], '');
      expect(intake.toJson()['outpatientTreatment'], '');
      expect(intake.validate(), isEmpty);
    });

    test('les mesures incohérentes sont refusées sans suggérer de diagnostic', () {
      const intake = ClinicalIntake(
        weightKg: -2,
        heightCm: double.infinity,
        respiratoryRate: 110,
        careDisposition: CareDisposition.hospitalization,
      );
      expect(intake.validate(), hasLength(4));
    });

    test('hospitalisation et transfert exigent leur justification', () {
      expect(
        const ClinicalIntake(careDisposition: CareDisposition.hospitalization)
            .validate(),
        isNotEmpty,
      );
      expect(
        const ClinicalIntake(careDisposition: CareDisposition.referral)
            .validate(),
        isNotEmpty,
      );
      expect(
        const ClinicalIntake(
          careDisposition: CareDisposition.hospitalization,
          hospitalizationReason: 'Motif saisi par le praticien',
        ).validate(),
        isEmpty,
      );
    });

    test('un format clinique inconnu échoue sans perdre silencieusement les données', () {
      expect(
        () => ClinicalIntake.fromJson({'schemaVersion': 99}),
        throwsFormatException,
      );
      expect(
        () => ClinicalIntake.fromJson({
          'schemaVersion': 1,
          'careDisposition': 'unknown',
        }),
        throwsFormatException,
      );
      expect(
        () => ClinicalIntake.fromJson({
          'schemaVersion': 1,
          'respiratoryRate': '18',
        }),
        throwsFormatException,
      );
    });
  });
}
