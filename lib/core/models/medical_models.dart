/// Les modèles de la V0 sont utilisés uniquement avec des données fictives.
/// Les données médicales réelles exigeront stockage chiffré et permissions.
class Patient {
  const Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.sex,
    required this.phone,
    required this.createdAt,
    this.allergies = 'Non renseignées',
    this.medicalHistory = 'Non renseignés',
    this.followUp = false,
  });

  final String id;
  final String name;
  final int age;
  final String sex;
  final String phone;
  final DateTime createdAt;
  final String allergies;
  final String medicalHistory;
  final bool followUp;

  Patient copyWith({
    String? name,
    int? age,
    String? sex,
    String? phone,
    String? allergies,
    String? medicalHistory,
    bool? followUp,
  }) => Patient(
    id: id,
    name: name ?? this.name,
    age: age ?? this.age,
    sex: sex ?? this.sex,
    phone: phone ?? this.phone,
    createdAt: createdAt,
    allergies: allergies ?? this.allergies,
    medicalHistory: medicalHistory ?? this.medicalHistory,
    followUp: followUp ?? this.followUp,
  );

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }
}

class Visit {
  const Visit({
    required this.id,
    required this.patientId,
    required this.date,
    required this.reason,
    this.temperature,
    this.systolic,
    this.diastolic,
    this.pulse,
    this.spo2,
    this.notes = '',
  });

  final String id;
  final String patientId;
  final DateTime date;
  final String reason;
  final double? temperature;
  final int? systolic;
  final int? diastolic;
  final int? pulse;
  final int? spo2;
  final String notes;
}

class LabExam {
  const LabExam({
    required this.id,
    required this.patientId,
    required this.title,
    required this.date,
    required this.status,
    this.result,
  });

  final String id;
  final String patientId;
  final String title;
  final DateTime date;
  final ExamStatus status;
  final String? result;
}

enum ExamStatus { pending, complete }
