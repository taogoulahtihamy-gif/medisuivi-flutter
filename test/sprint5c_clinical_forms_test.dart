import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medisuivi/app/theme.dart';
import 'package:medisuivi/core/models/clinical_intake.dart';
import 'package:medisuivi/core/state/demo_store.dart';
import 'package:medisuivi/features/consultations/new_consultation_screen.dart';
import 'package:medisuivi/features/consultations/consultation_detail_screen.dart';
import 'package:medisuivi/features/patients/new_patient_screen.dart';
import 'package:medisuivi/features/patients/patient_medical_info_screen.dart';

void main() {
  late DemoStore store;

  setUp(() => store = DemoStore());
  tearDown(() => store.dispose());

  Future<void> openScreen(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(DemoScope(
      store: store,
      child: MaterialApp(
        theme: MediTheme.light(),
        home: Builder(builder: (context) => Scaffold(
          body: Center(child: ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => screen),
            ),
            child: const Text('Ouvrir le formulaire'),
          )),
        )),
      ),
    ));
    await tester.tap(find.text('Ouvrir le formulaire'));
    await tester.pumpAndSettle();
  }

  testWidgets('Sprint 5C : patient avec quartier enregistré par le formulaire',
      (tester) async {
    final count = store.patients.length;
    await openScreen(tester, const NewPatientScreen());
    await tester.enterText(find.byType(TextFormField).at(0), 'Patient Fictif');
    await tester.enterText(find.byType(TextFormField).at(1), '39');
    final quarter = find.widgetWithText(TextFormField, 'Quartier');
    await tester.ensureVisible(quarter);
    await tester.enterText(quarter, 'Quartier de test');
    final save = find.text('Ajouter le patient');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(store.patients, hasLength(count + 1));
    final profile = await store.patientProfile(store.patients.first.id);
    expect(profile?.neighborhood, 'Quartier de test');
  });

  testWidgets('Sprint 5C : édition conserve les champs complémentaires',
      (tester) async {
    final patient = store.patients.first;
    await store.updatePatientInfo(
      patientId: patient.id,
      phone: '100',
      allergies: 'Aucune connue (fictif)',
      medicalHistory: 'Antécédent fictif',
      profile: const PatientProfileSupplement(
        neighborhood: 'Quartier enregistré',
        emergencyContactPhone: '999',
      ),
    );
    await openScreen(tester, PatientMedicalInfoScreen(
      patient: store.patientById(patient.id)!,
    ));
    await tester.pumpAndSettle();
    expect(find.text('Adresse et contact'), findsOneWidget);
    final save = find.text('Enregistrer les informations');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final saved = await store.patientProfile(patient.id);
    expect(saved?.neighborhood, 'Quartier enregistré');
    expect(saved?.emergencyContactPhone, '999');
  });

  testWidgets('Sprint 5C : consultation structurée et lecture seule',
      (tester) async {
    final patient = store.patients.first;
    final originalCount = store.visitsFor(patient.id).length;
    await openScreen(tester, NewConsultationScreen(patient: patient));
    await tester.enterText(find.byType(TextFormField).first,
      'Consultation fictive');
    final weight = find.widgetWithText(TextFormField, 'Poids (kg)');
    await tester.ensureVisible(weight);
    await tester.enterText(weight, '68,5');
    final save = find.text('Enregistrer la consultation');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(store.visitsFor(patient.id), hasLength(originalCount + 1));
    final visit = store.visitsFor(patient.id).first;
    final saved = await store.visitIntake(visit.id);
    expect(saved?.weightKg, 68.5);
    expect(saved?.careDisposition, CareDisposition.undecided);

    await openScreen(tester, ConsultationDetailScreen(visit: visit));
    await tester.pumpAndSettle();
    expect(find.text('Consultation enregistrée'), findsOneWidget);
    expect(find.text('Poids (kg)'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
