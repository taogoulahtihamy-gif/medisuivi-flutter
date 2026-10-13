import 'dart:convert';

import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../../app/theme_v2.dart';
import '../../core/assets/clinical_hero_photo.dart';
import '../../core/models/medical_models.dart';
import '../../core/state/store_context.dart';
import '../../core/widgets/clinical_components.dart';
import '../../core/widgets/medical_ui.dart';
import '../patients/new_patient_screen.dart';
import '../patients/patient_detail_screen.dart';
import '../settings/settings_screen.dart';

/// Accueil — Nocturne Clinique.
/// Présente immédiatement les informations cliniques utiles :
/// - Photo signature réorganisée (bandeau supérieur)
/// - Prochaine action requise (priorité clinique)
/// - Dossiers à revoir
/// - Dossiers récents
/// Pas de statistiques décoratives, pas de grille 2x2 uniforme.
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

  // Décompression unique de la photo fictive embarquée, y compris hors ligne.
  static final _photoBytes = base64Decode(clinicalHeroPhotoWebpBase64);

  @override
  Widget build(BuildContext context) {
    final p = _palette(context);
    final store = context.store;
    final patients = store.patients;
    final toReview = patients.where((pt) => pt.followUp).length;
    final pending = store.exams.where((e) => e.status == ExamStatus.pending).length;
    final today = DateTime.now();
    final coming = store.plannedFollowUps
        .where((plan) => !plan.isOverdue(today))
        .toList();
    final nextVisit = coming.isEmpty ? null : coming.first;

    void addPatient() => Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => const NewPatientScreen()));

    return ListView(
      key: const ValueKey('medisuivi-home'),
      physics: const BouncingScrollPhysics(),
      children: [
        ClinicalLayout(
          padding: const EdgeInsets.fromLTRB(
            ClinicalSpacing.screenPaddingHorizontal,
            ClinicalSpacing.md,
            ClinicalSpacing.screenPaddingHorizontal,
            105,
          ),
          child: ClinicalStaggered(
            children: [
              _buildHeader(context, p),
              const SizedBox(height: ClinicalSpacing.xl),
              _buildGreeting(context, p, today),
              const SizedBox(height: ClinicalSpacing.xl),
              _buildSignatureBanner(context, p, patients.length, onPatients, addPatient),
              const SizedBox(height: ClinicalSpacing.xxl),
              if (nextVisit != null) ...[
                _buildNextVisit(context, p, store, nextVisit, onFollowup),
                const SizedBox(height: ClinicalSpacing.xxl),
              ],
              if (toReview > 0 || pending > 0) ...[
                _buildAttentionRow(context, p, toReview, pending,
                  onFollowup, onExams),
                const SizedBox(height: ClinicalSpacing.xxl),
              ],
              _buildRecentSection(context, p, store, patients, onPatients),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, ClinicalPalette p) {
    return Row(
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: p.brandPrimarySoft,
            borderRadius: BorderRadius.circular(ClinicalRadius.sm),
          ),
          child: Icon(Icons.medical_services_outlined,
            color: p.brandPrimary, size: 22),
        ),
        const SizedBox(width: ClinicalSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('MediSuivi',
                style: ClinicalTypography.titleLarge.copyWith(
                  color: p.ink, fontWeight: FontWeight.w700,
                  letterSpacing: -0.4)),
              const SizedBox(height: 2),
              Text('Espace clinique personnel',
                style: ClinicalTypography.bodySmall.copyWith(
                  color: p.inkMuted)),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Paramètres',
          style: IconButton.styleFrom(
            backgroundColor: p.surfaceElevated,
            side: BorderSide(color: p.border),
            foregroundColor: p.ink,
          ),
          icon: const Icon(Icons.tune_rounded),
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => const SettingsScreen())),
        ),
      ],
    );
  }

  Widget _buildGreeting(BuildContext context, ClinicalPalette p, DateTime today) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(shortDate(today),
          style: ClinicalTypography.bodySmall.copyWith(
            color: p.inkMuted)),
        const SizedBox(height: ClinicalSpacing.xs),
        Text('Vos dossiers',
          style: ClinicalTypography.headlineLarge.copyWith(
            color: p.ink, fontWeight: FontWeight.w600,
            letterSpacing: -0.6)),
        const SizedBox(height: ClinicalSpacing.xs),
        Text('Vos prochaines actions cliniques.',
          style: ClinicalTypography.bodyMedium.copyWith(
            color: p.inkMuted)),
      ],
    );
  }

  /// Bandeau signature — photo de la professionnelle de santé,
  /// présentation réorganisée, texte lisible à gauche.
  Widget _buildSignatureBanner(
    BuildContext context,
    ClinicalPalette p,
    int total,
    VoidCallback onPatients,
    VoidCallback onAdd,
  ) {
    final isDark = p.isDark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(ClinicalRadius.cardElevated),
      child: SizedBox(
        height: 190,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Photo signature — cadrage d'origine conservé
            Image.memory(
              _photoBytes,
              fit: BoxFit.cover,
              alignment: Alignment.centerRight,
              filterQuality: FilterQuality.medium,
              excludeFromSemantics: true,
              color: isDark ? Colors.black.withValues(alpha: 0.35) : null,
              colorBlendMode: isDark ? BlendMode.darken : null,
            ),
            // Overlay latéral pour lisibilité — dégradé doux, pas de gradient artificiel
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  stops: const [0.0, 0.35, 0.65, 1.0],
                  colors: isDark
                    ? [
                        p.background.withValues(alpha: 0.92),
                        p.background.withValues(alpha: 0.75),
                        p.background.withValues(alpha: 0.25),
                        p.background.withValues(alpha: 0.05),
                      ]
                    : [
                        p.background.withValues(alpha: 0.90),
                        p.background.withValues(alpha: 0.70),
                        p.background.withValues(alpha: 0.20),
                        p.background.withValues(alpha: 0.05),
                      ],
                ),
              ),
            ),
            // Contenu — texte et actions à gauche
            Padding(
              padding: const EdgeInsets.all(ClinicalSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$total',
                          style: ClinicalTypography.monoLarge.copyWith(
                            color: p.ink, fontWeight: FontWeight.w700,
                            height: 1.0),
                        ),
                        const SizedBox(height: ClinicalSpacing.xs),
                        Text(
                          total == 1 ? 'patient enregistré' : 'patients enregistrés',
                          style: ClinicalTypography.bodyMedium.copyWith(
                            color: p.ink, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: ClinicalSpacing.lg),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            // Sur 320 px le double CTA dépassait le bandeau.
                            if (constraints.maxWidth < 310) {
                              return Row(children: [
                                Expanded(child: ClinicalButton(
                                  label: 'Nouveau patient',
                                  onPressed: onAdd,
                                  level: ClinicalButtonLevel.primary,
                                  height: 44,
                                  icon: Icons.add_rounded,
                                )),
                                const SizedBox(width: 8),
                                IconButton.outlined(
                                  tooltip: 'Mes dossiers',
                                  onPressed: onPatients,
                                  icon: const Icon(Icons.folder_open_outlined, size: 21),
                                  style: IconButton.styleFrom(
                                    foregroundColor: p.ink,
                                    backgroundColor: p.surface.withValues(alpha: 0.70),
                                    minimumSize: const Size(44, 44),
                                  ),
                                ),
                              ]);
                            }
                            return Row(children: [
                              ClinicalButton(
                                label: 'Nouveau patient',
                                onPressed: onAdd,
                                level: ClinicalButtonLevel.primary,
                                height: 44,
                                icon: Icons.add_rounded,
                                expanded: false,
                                minWidth: 140,
                              ),
                              const SizedBox(width: ClinicalSpacing.sm),
                              Flexible(child: ClinicalButton(
                                label: 'Mes dossiers',
                                onPressed: onPatients,
                                level: ClinicalButtonLevel.secondary,
                                height: 44,
                                expanded: false,
                              )),
                            ]);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Prochaine visite — action clinique prioritaire.
  Widget _buildNextVisit(
    BuildContext context,
    ClinicalPalette p,
    dynamic store,
    FollowUpPlan nextVisit,
    VoidCallback onFollowup,
  ) {
    final patient = store.patientById(nextVisit.patientId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClinicalSectionHeading(
          title: 'Prochaine visite',
          trailing: 'Calendrier',
          onTap: onFollowup,
        ),
        const SizedBox(height: ClinicalSpacing.md),
        ClinicalCard(
          variant: ClinicalCardVariant.elevated,
          onTap: onFollowup,
          padding: const EdgeInsets.all(ClinicalSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: p.accentAmberSoft,
                  borderRadius: BorderRadius.circular(ClinicalRadius.md),
                ),
                child: Icon(Icons.event_available_outlined,
                  size: 24, color: p.accentAmber),
              ),
              const SizedBox(width: ClinicalSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient?.name ?? 'Patient inconnu',
                      style: ClinicalTypography.titleLarge.copyWith(
                        color: p.ink, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: ClinicalSpacing.xs),
                    Text(
                      nextVisit.reason,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ClinicalTypography.bodyMedium.copyWith(
                        color: p.inkMuted),
                    ),
                    const SizedBox(height: ClinicalSpacing.xs),
                    Text(
                      '${shortDate(nextVisit.scheduledAt)} · '
                      '${nextVisit.scheduledAt.hour.toString().padLeft(2, '0')}:'
                      '${nextVisit.scheduledAt.minute.toString().padLeft(2, '0')}',
                      style: ClinicalTypography.monoMedium.copyWith(
                        color: p.accentAmber, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: p.inkMuted),
            ],
          ),
        ),
      ],
    );
  }

  /// Ligne d'attention — dossiers à revoir et bilans en attente.
  Widget _buildAttentionRow(
    BuildContext context,
    ClinicalPalette p,
    int toReview,
    int pending,
    VoidCallback onFollowup,
    VoidCallback onExams,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClinicalSectionHeading(title: 'À consulter'),
        const SizedBox(height: ClinicalSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (toReview > 0) ...[
              Expanded(
                child: _AttentionCard(
                  number: toReview,
                  label: toReview == 1 ? 'Patient à revoir' : 'Patients à revoir',
                  icon: Icons.event_repeat_rounded,
                  onTap: onFollowup,
                ),
              ),
              if (pending > 0) const SizedBox(width: ClinicalSpacing.md),
            ],
            if (pending > 0)
              Expanded(
                child: _AttentionCard(
                  number: pending,
                  label: pending == 1 ? 'Bilan en attente' : 'Bilans en attente',
                  icon: Icons.biotech_outlined,
                  onTap: onExams,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentSection(
    BuildContext context,
    ClinicalPalette p,
    dynamic store,
    List<Patient> patients,
    VoidCallback onPatients,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClinicalSectionHeading(
          title: 'Dossiers récents',
          trailing: 'Voir tout',
          onTap: onPatients,
        ),
        const SizedBox(height: ClinicalSpacing.md),
        if (patients.isEmpty)
          const ClinicalEmptyState(
            title: 'Aucun patient',
            detail: 'Ajoutez votre premier dossier.',
          )
        else
          ClinicalCard(
            variant: ClinicalCardVariant.default_,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < patients.take(4).length; i++) ...[
                  _RecentPatient(
                    patient: patients[i],
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => PatientDetailScreen(patientId: patients[i].id))),
                  ),
                  if (i < patients.take(4).length - 1)
                    Divider(height: 1, indent: 70, endIndent: 16, color: p.border),
                ],
              ],
            ),
          ),
        if (patients.length > 4) ...[
          const SizedBox(height: ClinicalSpacing.sm),
          Center(
            child: Text('+ ${patients.length - 4} autres dossiers',
              style: ClinicalTypography.bodySmall.copyWith(
                color: p.inkMuted)),
          ),
        ],
      ],
    );
  }

  ClinicalPalette _palette(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? ClinicalTheme.darkPalette()
        : ClinicalTheme.lightPalette();
  }
}

/// Carte d'attention — nombre + libellé + action.
class _AttentionCard extends StatelessWidget {
  const _AttentionCard({
    required this.number,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final int number;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = _palette(context);
    return ClinicalCard(
      variant: ClinicalCardVariant.default_,
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(
        ClinicalSpacing.md, ClinicalSpacing.lg, ClinicalSpacing.md, ClinicalSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: p.brandPrimary),
              const Spacer(),
              Icon(Icons.arrow_outward_rounded,
                size: 19, color: p.inkMuted),
            ],
          ),
          const SizedBox(height: ClinicalSpacing.lg),
          Text('$number',
            style: ClinicalTypography.monoLarge.copyWith(
              color: p.ink, fontWeight: FontWeight.w700, height: 1.0)),
          const SizedBox(height: ClinicalSpacing.xs),
          Text(label,
            maxLines: 2,
            style: ClinicalTypography.bodySmall.copyWith(
              color: p.ink, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  ClinicalPalette _palette(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? ClinicalTheme.darkPalette()
        : ClinicalTheme.lightPalette();
  }
}

/// Ligne patient récente.
class _RecentPatient extends StatelessWidget {
  const _RecentPatient({required this.patient, required this.onTap});

  final Patient patient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = _palette(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          ClinicalSpacing.md, ClinicalSpacing.md, ClinicalSpacing.md, ClinicalSpacing.md),
        child: Row(
          children: [
            ClinicalAvatar(initials: patient.initials, size: 44),
            const SizedBox(width: ClinicalSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(patient.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ClinicalTypography.titleLarge.copyWith(
                      color: p.ink, fontWeight: FontWeight.w600)),
                  const SizedBox(height: ClinicalSpacing.xs),
                  Text('${patient.id} · ${patient.age} ans',
                    style: ClinicalTypography.bodySmall.copyWith(
                      color: p.inkMuted)),
                ],
              ),
            ),
            if (patient.followUp)
              Icon(Icons.event_repeat_rounded,
                size: 18, color: p.brandPrimary),
            Icon(Icons.chevron_right_rounded,
              color: p.inkMuted, size: 22),
          ],
        ),
      ),
    );
  }

  ClinicalPalette _palette(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? ClinicalTheme.darkPalette()
        : ClinicalTheme.lightPalette();
  }
}