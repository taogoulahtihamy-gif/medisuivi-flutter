/// Données structurées du Sprint 5, sans décision médicale automatique.
/// Ce contrat est préparatoire : il n'est PAS encore branché sur SQLite.
/// Ne pas utiliser pour de vrais dossiers avant la migration auditée.
library;

enum CareDisposition {
  undecided,
  outpatient,
  observation,
  hospitalization,
  referral,
}

/// Coordonnées et antécédents complémentaires du dossier patient.
///
/// Les champs historiques [Patient.name], [Patient.age], [Patient.sex],
/// [Patient.phone], [Patient.allergies] et [Patient.medicalHistory] restent
/// inchangés. Ce complément sera persisté par la migration dédiée du Sprint 5.
class PatientProfileSupplement {
  const PatientProfileSupplement({
    this.neighborhood = '',
    this.address = '',
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
    this.currentMedications = '',
    this.surgicalHistory = '',
    this.familyHistory = '',
  });

  final String neighborhood;
  final String address;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final String currentMedications;
  final String surgicalHistory;
  final String familyHistory;

  Map<String, Object?> toJson() => {
    'neighborhood': neighborhood,
    'address': address,
    'emergencyContactName': emergencyContactName,
    'emergencyContactPhone': emergencyContactPhone,
    'currentMedications': currentMedications,
    'surgicalHistory': surgicalHistory,
    'familyHistory': familyHistory,
  };

  factory PatientProfileSupplement.fromJson(Map<String, dynamic> json) =>
      PatientProfileSupplement(
        neighborhood: _text(json, 'neighborhood'),
        address: _text(json, 'address'),
        emergencyContactName: _text(json, 'emergencyContactName'),
        emergencyContactPhone: _text(json, 'emergencyContactPhone'),
        currentMedications: _text(json, 'currentMedications'),
        surgicalHistory: _text(json, 'surgicalHistory'),
        familyHistory: _text(json, 'familyHistory'),
      );
}

/// Bilan clinique saisi explicitement par le professionnel de santé.
///
/// Le motif, la température, la TA, le pouls et la SpO₂ existent déjà sur
/// [Visit]. Ces nouveaux champs complètent la consultation sans les dupliquer.
/// Le traitement est une transcription du prescripteur, jamais une suggestion
/// générée par l'application.
class ClinicalIntake {
  const ClinicalIntake({
    this.weightKg,
    this.heightCm,
    this.respiratoryRate,
    this.symptomHistory = '',
    this.associatedSigns = '',
    this.generalCondition = '',
    this.physicalExamination = '',
    this.systemsExamination = '',
    this.diagnosticHypotheses = '',
    this.diagnosis = '',
    this.investigationsRequested = '',
    this.investigationsInterpretation = '',
    this.managementPlan = '',
    this.outpatientTreatment = '',
    this.hospitalizationReason = '',
    this.referralDetails = '',
    this.followUpInstructions = '',
    this.careDisposition = CareDisposition.undecided,
  });

  /// Poids en kg. Absence de valeur = non mesuré, pas zéro.
  final double? weightKg;
  /// Taille en cm.
  final double? heightCm;
  /// Fréquence respiratoire en cycles par minute.
  final int? respiratoryRate;

  final String symptomHistory;
  final String associatedSigns;
  final String generalCondition;
  final String physicalExamination;
  final String systemsExamination;
  final String diagnosticHypotheses;
  final String diagnosis;
  final String investigationsRequested;
  final String investigationsInterpretation;
  final String managementPlan;
  final String outpatientTreatment;
  final String hospitalizationReason;
  final String referralDetails;
  final String followUpInstructions;
  final CareDisposition careDisposition;

  static const int schemaVersion = 1;

  /// Vérification de saisie uniquement : aucune conclusion médicale.
  List<String> validate() {
    final errors = <String>[];
    if (weightKg != null &&
        (!weightKg!.isFinite || weightKg! <= 0 || weightKg! > 500)) {
      errors.add('Poids en kilogrammes invalide.');
    }
    if (heightCm != null &&
        (!heightCm!.isFinite || heightCm! <= 0 || heightCm! > 300)) {
      errors.add('Taille en centimètres invalide.');
    }
    if (respiratoryRate != null &&
        (respiratoryRate! <= 0 || respiratoryRate! > 100)) {
      errors.add('Fréquence respiratoire invalide.');
    }
    if (careDisposition == CareDisposition.hospitalization &&
        hospitalizationReason.trim().isEmpty) {
      errors.add("Le motif d'hospitalisation est obligatoire.");
    }
    if (careDisposition == CareDisposition.referral &&
        referralDetails.trim().isEmpty) {
      errors.add('La destination du transfert est obligatoire.');
    }
    return errors;
  }

  /// Sérialisation versionnée : les champs vides restent distinguables de
  /// données ajoutées ultérieurement. Le schéma Drift sera migré séparément.
  Map<String, Object?> toJson() => {
    'schemaVersion': schemaVersion,
    'weightKg': weightKg,
    'heightCm': heightCm,
    'respiratoryRate': respiratoryRate,
    'symptomHistory': symptomHistory,
    'associatedSigns': associatedSigns,
    'generalCondition': generalCondition,
    'physicalExamination': physicalExamination,
    'systemsExamination': systemsExamination,
    'diagnosticHypotheses': diagnosticHypotheses,
    'diagnosis': diagnosis,
    'investigationsRequested': investigationsRequested,
    'investigationsInterpretation': investigationsInterpretation,
    'managementPlan': managementPlan,
    'outpatientTreatment': outpatientTreatment,
    'hospitalizationReason': hospitalizationReason,
    'referralDetails': referralDetails,
    'followUpInstructions': followUpInstructions,
    'careDisposition': careDisposition.name,
  };

  factory ClinicalIntake.fromJson(Map<String, dynamic> json) {
    final version = json['schemaVersion'];
    if (version != schemaVersion) {
      throw FormatException('Version de dossier clinique non prise en charge.');
    }
    final rawDisposition = _text(json, 'careDisposition', fallback: 'undecided');
    final disposition = CareDisposition.values.where(
      (value) => value.name == rawDisposition,
    );
    if (disposition.isEmpty) {
      throw FormatException('Décision de prise en charge non reconnue.');
    }
    return ClinicalIntake(
      weightKg: _optionalDouble(json, 'weightKg'),
      heightCm: _optionalDouble(json, 'heightCm'),
      respiratoryRate: _optionalInt(json, 'respiratoryRate'),
      symptomHistory: _text(json, 'symptomHistory'),
      associatedSigns: _text(json, 'associatedSigns'),
      generalCondition: _text(json, 'generalCondition'),
      physicalExamination: _text(json, 'physicalExamination'),
      systemsExamination: _text(json, 'systemsExamination'),
      diagnosticHypotheses: _text(json, 'diagnosticHypotheses'),
      diagnosis: _text(json, 'diagnosis'),
      investigationsRequested: _text(json, 'investigationsRequested'),
      investigationsInterpretation: _text(json, 'investigationsInterpretation'),
      managementPlan: _text(json, 'managementPlan'),
      outpatientTreatment: _text(json, 'outpatientTreatment'),
      hospitalizationReason: _text(json, 'hospitalizationReason'),
      referralDetails: _text(json, 'referralDetails'),
      followUpInstructions: _text(json, 'followUpInstructions'),
      careDisposition: disposition.first,
    );
  }
}

String _text(Map<String, dynamic> json, String key, {String fallback = ''}) {
  final value = json[key];
  if (value == null) return fallback;
  if (value is String) return value;
  throw FormatException('Champ $key : texte attendu.');
}

double? _optionalDouble(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is num) return value.toDouble();
  throw FormatException('Champ $key : nombre attendu.');
}

int? _optionalInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is int) return value;
  throw FormatException('Champ $key : entier attendu.');
}
