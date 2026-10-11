import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/theme.dart';
import '../../core/models/medical_models.dart';
import '../../core/state/demo_store.dart';
import '../../core/widgets/medical_ui.dart';
import '../patients/new_patient_screen.dart';
import '../patients/patient_detail_screen.dart';
import '../settings/settings_screen.dart';

/// Tableau de bord personnel : navigation et vrais nombres issus du DemoStore.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onPatients,
    required this.onExams,
    required this.onFollowup,
  });

  final VoidCallback onPatients;
  final VoidCallback onExams;
  final VoidCallback onFollowup;

  void _newPatient(BuildContext context) => Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const NewPatientScreen()),
  );

  @override
  Widget build(BuildContext context) {
    final store = DemoScope.of(context);
    final patients = store.patients;
    final followUps = patients.where((patient) => patient.followUp).length;
    final pending = store.exams.where((exam) =>
      exam.status == ExamStatus.pending).length;

    return ListView(
      key: const ValueKey('medisuivi-home'),
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      children: [
        ScreenWidth(
          padding: const EdgeInsets.fromLTRB(21, 20, 21, 38),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 41,
                  height: 41,
                  decoration: BoxDecoration(
                    color: Palette.forest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.health_and_safety_outlined,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 11),
                const Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('MediSuivi', style: TextStyle(
                      fontSize: 18.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.5,
                    )),
                    Text('Espace personnel', style: TextStyle(
                      fontSize: 11.5, color: Palette.muted,
                    )),
                  ],
                )),
                IconButton(
                  tooltip: 'Paramètres',
                  icon: const Icon(Icons.tune_rounded, size: 22),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Palette.border),
                  ),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SettingsScreen(),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 29),
              Text(
                shortDate(DateTime.now()),
                style: const TextStyle(
                  color: Palette.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Vue clinique',
                style: TextStyle(
                  fontSize: 32,
                  height: 1.04,
                  letterSpacing: -1.1,
                  fontWeight: FontWeight.w800,
                  color: Palette.charcoal,
                ),
              ),
              const SizedBox(height: 9),
              const Text('L’essentiel de vos dossiers, au même endroit.',
                style: TextStyle(fontSize: 12.5, color: Palette.muted)),
              const SizedBox(height: 23),
              EntranceReveal(
                child: _ActivityCard(
                  patientCount: patients.length,
                  followUpCount: followUps,
                  pendingCount: pending,
                  onNewPatient: () => _newPatient(context),
                  onPatients: onPatients,
                ),
              ),
              const SizedBox(height: 14),
              const DemoNotice(compact: true),
              const SizedBox(height: 29),
              const SectionHeading(title: 'Accès rapide'),
              const SizedBox(height: 13),
              Row(children: [
                Expanded(child: _ShortcutCard(
                  label: 'Patients à revoir',
                  value: '$followUps',
                  icon: Icons.event_repeat_rounded,
                  tint: Palette.mintFog,
                  onTap: onFollowup,
                )),
                const SizedBox(width: 11),
                Expanded(child: _ShortcutCard(
                  label: 'Bilans en attente',
                  value: '$pending',
                  icon: Icons.biotech_outlined,
                  tint: const Color(0xFFF0F2EC),
                  onTap: onExams,
                )),
              ]),
              const SizedBox(height: 29),
              SectionHeading(
                title: 'Dossiers récents',
                trailing: 'Tout voir',
                onTap: onPatients,
              ),
              const SizedBox(height: 11),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Palette.border),
                ),
                child: Column(children: [
                  for (var i = 0; i < patients.take(3).length; i++) ...[
                    _RecentPatient(
                      patient: patients[i],
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => PatientDetailScreen(
                            patientId: patients[i].id,
                          ),
                        ),
                      ),
                    ),
                    if (i < patients.take(3).length - 1)
                      const Divider(height: 1, indent: 65, endIndent: 18),
                  ],
                ]),
              ),
              const SizedBox(height: 22),
              _ArchiveNote(onTap: onPatients),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.patientCount,
    required this.followUpCount,
    required this.pendingCount,
    required this.onNewPatient,
    required this.onPatients,
  });

  final int patientCount;
  final int followUpCount;
  final int pendingCount;
  final VoidCallback onNewPatient;
  final VoidCallback onPatients;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(21, 21, 21, 20),
    decoration: BoxDecoration(
      color: Palette.charcoal,
      borderRadius: BorderRadius.circular(27),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.grid_view_rounded, color: Color(0xFFB7C9BE), size: 15),
          const SizedBox(width: 8),
          const Expanded(child: Text(
            'APERÇU DES DOSSIERS',
            style: TextStyle(
              color: Color(0xFFB9CCC1),
              fontSize: 10,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
          )),
          Container(
            width: 9, height: 9,
            decoration: const BoxDecoration(
              color: Color(0xFF71C9A0),
              shape: BoxShape.circle,
            ),
          ),
        ]),
        const SizedBox(height: 17),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('$patientCount', style: const TextStyle(
              color: Colors.white,
              fontSize: 51,
              height: 1,
              fontWeight: FontWeight.w700,
              letterSpacing: -2.5,
            )),
            const SizedBox(width: 11),
            const Padding(
              padding: EdgeInsets.only(bottom: 7),
              child: Text('patients\nrépertoriés',
                style: TextStyle(
                  height: 1.25,
                  fontSize: 12,
                  color: Color(0xFFD9E4DD),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 19),
        Row(children: [
          Expanded(child: _DarkMiniStat(
            count: followUpCount,
            label: 'À revoir',
            icon: Icons.calendar_today_outlined,
          )),
          const SizedBox(width: 10),
          Expanded(child: _DarkMiniStat(
            count: pendingCount,
            label: 'Bilans',
            icon: Icons.science_outlined,
          )),
        ]),
        const SizedBox(height: 17),
        Row(children: [
          Expanded(child: SizedBox(
            height: 46,
            child: FilledButton.icon(
              onPressed: onNewPatient,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Palette.charcoal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
                padding: const EdgeInsets.symmetric(horizontal: 9),
              ),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Nouveau patient',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
            ),
          )),
          const SizedBox(width: 9),
          SizedBox(
            width: 44, height: 46,
            child: IconButton(
              tooltip: 'Mes dossiers',
              onPressed: onPatients,
              style: IconButton.styleFrom(
                backgroundColor: Palette.charcoalSoft,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              ),
              icon: const Icon(Icons.arrow_outward_rounded, size: 20),
            ),
          ),
        ]),
      ],
    ),
  );
}

class _DarkMiniStat extends StatelessWidget {
  const _DarkMiniStat({
    required this.count,
    required this.label,
    required this.icon,
  });

  final int count;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    decoration: BoxDecoration(
      color: const Color(0xFF2C302E),
      borderRadius: BorderRadius.circular(17),
    ),
    child: Row(children: [
      Icon(icon, size: 16, color: const Color(0xFFC9DAD0)),
      const SizedBox(width: 9),
      Text('$count', style: const TextStyle(
        color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700,
      )),
      const SizedBox(width: 7),
      Expanded(child: Text(label,
        maxLines: 2, style: const TextStyle(
        color: Color(0xFFBECAC1), fontSize: 11.5, height: 1.1,
      ))),
    ]),
  );
}

class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.tint,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: tint,
    borderRadius: BorderRadius.circular(22),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        constraints: const BoxConstraints(minHeight: 133),
        padding: const EdgeInsets.fromLTRB(15, 15, 15, 17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: Palette.forest, size: 21),
              const Spacer(),
              const Icon(Icons.arrow_outward_rounded,
                color: Palette.forest, size: 17),
            ]),
            const SizedBox(height: 16),
            Text(value, style: const TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w800,
              letterSpacing: -.6,
              height: 1,
            )),
            const SizedBox(height: 7),
            Text(label, maxLines: 2, style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: Palette.ink, height: 1.2,
            )),
          ],
        ),
      ),
    ),
  );
}

class _RecentPatient extends StatelessWidget {
  const _RecentPatient({required this.patient, required this.onTap});
  final Patient patient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(13, 14, 13, 14),
      child: Row(children: [
        PatientAvatar(patient: patient, size: 40, hero: true),
        const SizedBox(width: 11),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(patient.name, style: const TextStyle(
              fontSize: 13.5, fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            Text('${patient.id}  ·  ${patient.age} ans',
              style: const TextStyle(color: Palette.muted, fontSize: 11.5)),
          ],
        )),
        if (patient.followUp)
          const Icon(Icons.event_repeat_rounded,
            color: Palette.forest, size: 17),
        const SizedBox(width: 8),
        const Icon(Icons.chevron_right_rounded,
          color: Palette.muted, size: 19),
      ]),
    ),
  );
}

class _ArchiveNote extends StatelessWidget {
  const _ArchiveNote({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SvgPicture.asset(
              'assets/illustrations/medical_care.svg',
              width: 72,
              height: 62,
              fit: BoxFit.cover,
              alignment: Alignment.centerRight,
              semanticsLabel: 'Illustration médicale',
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Historique médical', style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700,
              )),
              SizedBox(height: 5),
              Text('Consulter les dossiers et les visites.',
                style: TextStyle(fontSize: 11, color: Palette.muted)),
            ],
          )),
          const Icon(Icons.chevron_right_rounded,
            color: Palette.muted),
        ]),
      ),
    ),
  );
}
