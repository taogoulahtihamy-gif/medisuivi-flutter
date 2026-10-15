import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'dev_auth_api.dart';

/// A practitioner-scoped development dossier, never sourced from DemoStore.
/// Only synthetic clinical records may be created from this screen.
class DevPatientDetail extends StatefulWidget {
  const DevPatientDetail({
    super.key,
    required this.api,
    required this.session,
    required this.patient,
  });
  final DevAuthApi api;
  final DevSession session;
  final DevPatient patient;

  @override
  State<DevPatientDetail> createState() => _DevPatientDetailState();
}

class _DevPatientDetailState extends State<DevPatientDetail> {
  late Future<DevClinicalBundle> _clinical;
  bool _saving = false;
  String? _error;

  String _date(DateTime date) {
    final value = date.toLocal();
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/${value.year}';
  }

  String _visitSubtitle(DevVisit visit) {
    final details = <String>[
      '${_date(visit.createdAt)} · Consultation enregistrée'
    ];
    if (visit.temperature != null) {
      details.add('${visit.temperature!.toStringAsFixed(1)} °C');
    }
    if (visit.systolic != null && visit.diastolic != null) {
      details.add('${visit.systolic}/${visit.diastolic} mmHg');
    }
    if (visit.pulse != null) details.add('${visit.pulse} bpm');
    if (visit.spo2 != null) details.add('SpO₂ ${visit.spo2}%');
    return details.join(' · ');
  }

  @override
  void initState() {
    super.initState();
    _clinical = widget.api.getPatientClinical(widget.session, widget.patient);
  }

  void _reload() => setState(() {
        _clinical =
            widget.api.getPatientClinical(widget.session, widget.patient);
      });

  Future<void> _mutate(Future<void> Function() action) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await action();
      if (mounted) _reload();
    } on DevApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Impossible d’enregistrer cet acte fictif.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _listTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required PaletteData palette,
    VoidCallback? onTap,
    String? keyName,
    Widget? trailing,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: Material(
          color: palette.surface.withValues(alpha: .70),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: palette.border.withValues(alpha: .7)),
          ),
          child: InkWell(
            key: keyName == null ? null : Key(keyName),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 17),
              child: Row(children: [
                Icon(icon, size: 19, color: palette.forest),
                const SizedBox(width: 13),
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: palette.ink,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        maxLines: 2,
                        style: TextStyle(color: palette.muted, fontSize: 12.8)),
                  ],
                )),
                if (trailing != null) trailing,
                if (trailing == null && onTap != null)
                  Icon(Icons.chevron_right_rounded,
                      size: 20, color: palette.muted),
              ]),
            ),
          ),
        ),
      );

  Widget _recordsTab({
    required List<Widget> rows,
    required String emptyText,
    required String actionTitle,
    required String actionKey,
    required Future<void> Function() onCreate,
    Future<void> Function()? onCreateAlternate,
    String? alternateTitle,
    String? alternateKey,
    required PaletteData palette,
  }) =>
      ListView(
        padding: const EdgeInsets.fromLTRB(21, 18, 21, 35),
        children: [
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 22),
              child: Text(emptyText,
                  style: TextStyle(color: palette.muted, fontSize: 14)),
            ),
          ...rows,
          const SizedBox(height: 16),
          FilledButton.icon(
            key: Key(actionKey),
            onPressed: _saving ? null : () => _mutate(onCreate),
            icon: const Icon(Icons.add_rounded),
            label: Text(actionTitle),
          ),
          if (onCreateAlternate != null && alternateTitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: TextButton.icon(
                key: Key(alternateKey ?? 'dev-clinical-alternate'),
                onPressed: _saving ? null : () => _mutate(onCreateAlternate),
                icon: const Icon(Icons.post_add_rounded),
                label: Text(alternateTitle),
              ),
            ),
          const SizedBox(height: 14),
          Text('Les actes créés ici sont entièrement fictifs.',
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.muted, fontSize: 12.5)),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(title: const Text('Dossier patient fictif'), actions: [
          IconButton(
              onPressed: _reload,
              tooltip: 'Actualiser le dossier',
              icon: const Icon(Icons.refresh_rounded)),
        ]),
        body: SafeArea(
            child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
            child: Row(children: [
              CircleAvatar(
                  radius: 27,
                  backgroundColor: p.tealSoft,
                  child: Icon(Icons.folder_shared_outlined,
                      color: p.forest, size: 25)),
              const SizedBox(width: 13),
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.patient.displayName,
                      key: const Key('dev-clinical-patient-name'),
                      style: TextStyle(
                          color: p.ink,
                          fontSize: 19,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('${widget.patient.age} ans · Dossier de test',
                      style: TextStyle(color: p.muted, fontSize: 13)),
                ],
              )),
            ]),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Text(_error!,
                  key: const Key('dev-clinical-error'),
                  style: TextStyle(color: p.danger, fontSize: 13)),
            ),
          const TabBar(
            tabs: [
              Tab(text: 'Consultations'),
              Tab(text: 'Bilans'),
              Tab(text: 'Suivi'),
            ],
          ),
          Expanded(
              child: FutureBuilder<DevClinicalBundle>(
            future: _clinical,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                    child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Text(
                            'Impossible d’ouvrir ce dossier pour ce compte.',
                            key: const Key('dev-clinical-load-error'),
                            textAlign: TextAlign.center,
                            style: TextStyle(color: p.danger, fontSize: 14))));
              }
              final records = snapshot.requireData;
              return TabBarView(children: [
                _recordsTab(
                  palette: p,
                  rows: [
                    for (final visit in records.visits)
                      _listTile(
                          title: visit.reason,
                          subtitle: _visitSubtitle(visit),
                          icon: Icons.medical_information_outlined,
                          palette: p),
                  ],
                  emptyText: 'Aucune consultation fictive enregistrée.',
                  actionTitle: 'Nouvelle consultation fictive',
                  actionKey: 'dev-add-synthetic-visit',
                  onCreate: () => widget.api
                      .createSyntheticVisit(widget.session, widget.patient),
                  alternateTitle: 'Tester des constantes fictives',
                  alternateKey: 'dev-add-synthetic-vitals',
                  onCreateAlternate: () => widget.api.createSyntheticVisit(
                      widget.session, widget.patient,
                      withVitals: true),
                ),
                _recordsTab(
                  palette: p,
                  rows: [
                    for (final exam in records.exams)
                      _listTile(
                          title: exam.title,
                          subtitle: exam.status == 'complete'
                              ? 'Résultat fictif enregistré'
                              : 'En attente d’un résultat fictif',
                          icon: Icons.biotech_outlined,
                          palette: p,
                          keyName: 'dev-exam-${exam.id}',
                          onTap: exam.status == 'pending' && !_saving
                              ? () => _mutate(() => widget.api
                                  .recordSyntheticExamResult(
                                      widget.session, exam))
                              : null),
                  ],
                  emptyText: 'Aucun examen fictif pour ce dossier.',
                  actionTitle: 'Nouvel examen fictif',
                  actionKey: 'dev-add-synthetic-exam',
                  onCreate: () => widget.api
                      .createSyntheticExam(widget.session, widget.patient),
                ),
                _recordsTab(
                  palette: p,
                  rows: [
                    for (final follow in records.followUps)
                      _listTile(
                          title: follow.reason,
                          subtitle: follow.status == 'planned'
                              ? 'Rendez-vous fictif programmé · ${_date(follow.scheduledAt)}'
                              : follow.status == 'cancelled'
                                  ? 'Suivi fictif annulé'
                                  : 'Suivi fictif clôturé',
                          icon: Icons.event_note_outlined,
                          palette: p,
                          trailing: follow.status == 'planned'
                              ? PopupMenuButton<String>(
                                  key: Key('dev-followup-options-${follow.id}'),
                                  tooltip: 'Options du suivi fictif',
                                  onSelected: (action) {
                                    if (action == 'reschedule') {
                                      _mutate(() => widget.api
                                          .rescheduleSyntheticFollowUp(
                                              widget.session, follow));
                                    } else if (action == 'cancel') {
                                      _mutate(() => widget.api
                                          .cancelSyntheticFollowUp(
                                              widget.session, follow));
                                    }
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(
                                        value: 'reschedule',
                                        child: Text('Reporter de 7 jours')),
                                    PopupMenuItem(
                                        value: 'cancel',
                                        child: Text('Annuler ce suivi fictif')),
                                  ],
                                )
                              : null,
                          keyName: 'dev-followup-${follow.id}',
                          onTap: follow.status == 'planned' && !_saving
                              ? () => _mutate(() => widget.api
                                  .closeSyntheticFollowUp(
                                      widget.session, follow))
                              : null),
                  ],
                  emptyText: 'Aucun suivi fictif pour ce dossier.',
                  actionTitle: 'Programmer un suivi fictif',
                  actionKey: 'dev-add-synthetic-followup',
                  onCreate: () => widget.api
                      .createSyntheticFollowUp(widget.session, widget.patient),
                ),
              ]);
            },
          )),
        ])),
      ),
    );
  }
}
