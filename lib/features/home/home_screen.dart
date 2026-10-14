import 'dart:async';
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
import '../onboarding/medisuivi_welcome_gate.dart';
import '../patients/patient_detail_screen.dart';
import '../settings/settings_screen.dart';
import '../notifications/clinical_alerts_screen.dart';

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
            8,
            ClinicalSpacing.screenPaddingHorizontal,
            86,
          ),
          child: ClinicalStaggered(
            children: [
              _buildHeader(context, p),
              const SizedBox(height: 12),
              _buildGreeting(context, p, today),
              const SizedBox(height: 12),
              _buildSignatureBanner(context, p, patients.length, onPatients, addPatient),
              const SizedBox(height: 16),
              if (nextVisit != null) ...[
                _buildNextVisit(context, p, store, nextVisit, onFollowup),
                const SizedBox(height: 16),
              ],
              if (toReview > 0 || pending > 0) ...[
                _buildAttentionRow(context, p, toReview, pending,
                  onFollowup, onExams),
                const SizedBox(height: 16),
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
          key: const Key('header-notifications'),
          tooltip: 'Notifications locales',
          style: IconButton.styleFrom(
            backgroundColor: p.surfaceElevated,
            side: BorderSide(color: p.border),
            foregroundColor: p.ink,
          ),
          icon: const Icon(Icons.notifications_none_rounded, size: 22),
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => const ClinicalAlertsScreen())),
        ),
        const SizedBox(width: 7),
        Tooltip(
          message: PractitionerPreviewScope.maybeOf(context)?.displayName.isNotEmpty == true
              ? PractitionerPreviewScope.maybeOf(context)!.displayName
              : 'Profil et paramètres',
          child: InkWell(
            key: const Key('header-profile'),
            borderRadius: BorderRadius.circular(28),
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => const SettingsScreen())),
            child: Builder(builder: (context) {
              final profile = PractitionerPreviewScope.maybeOf(context);
              return CircleAvatar(
                key: const Key('home-practitioner-avatar'),
                radius: 22,
                backgroundColor: p.brandPrimarySoft,
                foregroundImage: profile?.photo == null
                    ? null : MemoryImage(profile!.photo!),
                child: profile?.photo == null
                    ? Icon(Icons.person_rounded,
                        size: 24, color: p.brandPrimary)
                    : null,
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildGreeting(BuildContext context, ClinicalPalette p, DateTime today) {
    return _HomeSearchAndGreeting(palette: p, date: today);
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
        height: 176,
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
        const SizedBox(height: 8),
        ClinicalCard(
          variant: ClinicalCardVariant.elevated,
          onTap: onFollowup,
          padding: const EdgeInsets.all(14),
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
        const SizedBox(height: 8),
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
        const SizedBox(height: 8),
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

/// Recherche immédiate dans les dossiers locaux, sans requête réseau.
/// Le bloc titre/date est positionné à droite, y compris sur petit écran.
class _HomeSearchAndGreeting extends StatefulWidget {
  const _HomeSearchAndGreeting({required this.palette, required this.date});

  final ClinicalPalette palette;
  final DateTime date;

  @override
  State<_HomeSearchAndGreeting> createState() => _HomeSearchAndGreetingState();
}

class _HomeSearchAndGreetingState extends State<_HomeSearchAndGreeting> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';
  late DateTime _clock;
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _clock = widget.date;
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _clock = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    final term = _query.trim().toLowerCase();
    final matches = term.isEmpty
        ? <Patient>[]
        : context.store.patients.where((patient) =>
            patient.name.toLowerCase().contains(term) ||
            patient.id.toLowerCase().contains(term)).take(4).toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      LayoutBuilder(builder: (context, constraints) {
        final narrow = constraints.maxWidth < 390;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: narrow ? 6 : 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${shortDate(_clock)} · '
                    '${_clock.hour.toString().padLeft(2, '0')}:'
                    '${_clock.minute.toString().padLeft(2, '0')}',
                    key: const Key('home-greeting-date'),
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      color: p.inkMuted,
                      fontSize: narrow ? 10 : 11,
                    )),
                  const SizedBox(height: 3),
                  Text('Vos dossiers',
                    key: const Key('home-greeting-title'),
                    maxLines: 1,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      color: p.ink,
                      fontSize: narrow ? 19 : 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -.45,
                    )),
                  const SizedBox(height: 3),
                  Text('Vos prochaines actions cliniques.',
                    maxLines: 2,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      color: p.inkMuted,
                      fontSize: narrow ? 10.5 : 12,
                      height: 1.25,
                    )),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: narrow ? 5 : 6,
              child: Align(
                alignment: Alignment.centerRight,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Semantics(
                textField: true,
                label: 'Rechercher un patient',
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: p.surface.withValues(alpha: p.isDark ? .86 : .94),
                    borderRadius: BorderRadius.circular(23),
                    border: Border.all(color: p.border.withValues(alpha: .80)),
                  ),
                  child: TextField(
                    key: const Key('home-patient-search'),
                    controller: _controller,
                    onChanged: (value) => setState(() => _query = value),
                    textInputAction: TextInputAction.search,
                    maxLines: 1,
                    style: TextStyle(color: p.ink, fontSize: 12.5),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      hintText: narrow ? 'Patient…' : 'Chercher un patient',
                      hintStyle: TextStyle(
                        color: p.inkMuted, fontSize: narrow ? 11 : 12),
                      prefixIcon: Icon(Icons.search_rounded,
                        size: 19, color: p.inkMuted),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 34, minHeight: 40),
                      contentPadding: const EdgeInsets.only(
                        top: 12, bottom: 12, right: 8),
                      suffixIcon: _query.isEmpty ? null : IconButton(
                        key: const Key('home-clear-search'),
                        tooltip: 'Effacer la recherche',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32, minHeight: 40),
                        onPressed: () {
                          _controller.clear();
                          setState(() => _query = '');
                        },
                        icon: Icon(Icons.close_rounded, size: 16, color: p.inkMuted),
                      ),
                    ),
                  ),
                ),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
      if (term.isNotEmpty) ...[
        const SizedBox(height: 8),
        Container(
          key: const Key('home-search-results'),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: p.surfaceElevated,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: p.border),
          ),
          child: matches.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(9),
                  child: Text('Aucun patient trouvé',
                    style: TextStyle(color: p.inkMuted, fontSize: 12)),
                )
              : Column(
                  children: [
                    for (final patient in matches)
                      Material(
                        type: MaterialType.transparency,
                        child: ListTile(
                        key: Key('home-result-${patient.id}'),
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 7),
                        leading: Icon(Icons.person_outline_rounded,
                          color: p.brandPrimary, size: 20),
                        title: Text(patient.name,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: p.ink, fontSize: 13,
                            fontWeight: FontWeight.w600)),
                        subtitle: Text(patient.id,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: p.inkMuted, fontSize: 11)),
                        trailing: Icon(Icons.chevron_right_rounded,
                          color: p.inkMuted, size: 19),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                              PatientDetailScreen(patientId: patient.id))),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    ]);
  }
}
