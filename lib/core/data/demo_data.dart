import '../models/medical_models.dart';

/// Jeu de données inventé, uniquement destiné aux maquettes et tests.
abstract final class DemoData {
  static final patients = <Patient>[
    Patient(id: 'PAT-00241', name: 'Aminata Diallo', age: 32, sex: 'F', phone: 'Non renseigné', createdAt: DateTime(2026, 9, 18), followUp: true),
    Patient(id: 'PAT-00240', name: 'Moussa Ndiaye', age: 45, sex: 'M', phone: 'Non renseigné', createdAt: DateTime(2026, 9, 22)),
    Patient(id: 'PAT-00239', name: 'Fatou Sarr', age: 27, sex: 'F', phone: 'Non renseigné', createdAt: DateTime(2026, 9, 25), followUp: true),
    Patient(id: 'PAT-00238', name: 'Ibrahima Fall', age: 61, sex: 'M', phone: 'Non renseigné', createdAt: DateTime(2026, 9, 27)),
    Patient(id: 'PAT-00237', name: 'Awa Ba', age: 38, sex: 'F', phone: 'Non renseigné', createdAt: DateTime(2026, 10, 1)),
  ];

  static final visits = <Visit>[
    Visit(id: 'VIS-001', patientId: 'PAT-00241', date: DateTime(2026, 10, 10), reason: 'Consultation de suivi', temperature: 37.2, systolic: 118, diastolic: 76, pulse: 78, spo2: 98, notes: 'Exemple fictif.'),
    Visit(id: 'VIS-002', patientId: 'PAT-00241', date: DateTime(2026, 10, 4), reason: 'Consultation initiale', temperature: 38.4, systolic: 121, diastolic: 80, pulse: 88, spo2: 97),
    Visit(id: 'VIS-003', patientId: 'PAT-00240', date: DateTime(2026, 10, 9), reason: 'Contrôle des constantes', temperature: 36.9, systolic: 129, diastolic: 81, pulse: 73),
    Visit(id: 'VIS-004', patientId: 'PAT-00239', date: DateTime(2026, 10, 8), reason: 'Consultation', temperature: 37.1, pulse: 82),
  ];

  static final exams = <LabExam>[
    LabExam(id: 'EXM-001', patientId: 'PAT-00241', title: 'Numération formule sanguine', date: DateTime(2026, 10, 10), status: ExamStatus.complete, result: 'Résultat fictif joint au dossier.'),
    LabExam(id: 'EXM-002', patientId: 'PAT-00241', title: 'Glycémie', date: DateTime(2026, 10, 10), status: ExamStatus.pending),
    LabExam(id: 'EXM-003', patientId: 'PAT-00239', title: 'Analyse biologique', date: DateTime(2026, 10, 8), status: ExamStatus.pending),
  ];
}
