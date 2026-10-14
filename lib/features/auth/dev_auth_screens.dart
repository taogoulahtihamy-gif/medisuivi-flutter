import 'dart:async' show unawaited;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'dev_auth_api.dart';
import 'dev_profile_editor.dart';
import 'dev_patient_detail.dart';

/// These screens never use DemoScope/PersistentScope. Remote patients
/// originate only from the signed-in API session.
class DevAuthScreen extends StatefulWidget {
  const DevAuthScreen({
    super.key, required this.api, required this.isRegister,
    required this.onAuthenticated, required this.onBack,
    required this.onToggle,
    this.onVerificationRequired,
    this.onForgotPassword,
  });

  final DevAuthApi api;
  final bool isRegister;
  final ValueChanged<DevSession> onAuthenticated;
  final VoidCallback onBack;
  final VoidCallback onToggle;
  final ValueChanged<String>? onVerificationRequired;
  final VoidCallback? onForgotPassword;

  @override
  State<DevAuthScreen> createState() => _DevAuthScreenState();
}

class _DevAuthScreenState extends State<DevAuthScreen> {
  final _key = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _first = TextEditingController();
  final _last = TextEditingController();
  bool _busy = false;
  bool _showPassword = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _first.dispose();
    _last.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !(_key.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final session = widget.isRegister
          ? await widget.api.createAccount(
              email: _email.text, password: _password.text,
              firstName: _first.text, lastName: _last.text)
          : await widget.api.signIn(_email.text, _password.text);
      if (mounted) widget.onAuthenticated(session);
    } on DevVerificationRequired catch (error) {
      if (mounted) {
        if (widget.onVerificationRequired != null) {
          widget.onVerificationRequired!(error.email);
        } else {
          setState(() => _error = 'Vérifiez votre adresse e-mail avant de vous connecter.');
        }
      }
    } on DevApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() =>
          _error = 'Impossible de terminer l’opération. Réessayez.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final register = widget.isRegister;
    final viewport = MediaQuery.sizeOf(context);
    return Scaffold(
      backgroundColor: p.canvas,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(22, 13, 22,
              viewport.height < 690 ? 25 : 48),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 470),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      key: const Key('dev-auth-back'),
                      onPressed: _busy ? null : widget.onBack,
                      icon: const Icon(Icons.arrow_back_rounded, size: 19),
                      label: const Text('Retour'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 9)),
                    ),
                  ),
                  SizedBox(height: viewport.height >= 760 ? 47 : 13),
                  Row(children: [
                    Container(
                      key: const Key('dev-auth-brand-icon'),
                      height: 46, width: 46,
                      decoration: BoxDecoration(
                        color: p.tealSoft,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: p.border),
                      ),
                      child: Icon(Icons.health_and_safety_outlined,
                          size: 24, color: p.forest),
                    ),
                    const SizedBox(width: 12),
                    Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('MediSuivi', style: TextStyle(
                          color: p.ink, fontSize: 20,
                          fontWeight: FontWeight.w700, letterSpacing: -.5)),
                        const SizedBox(height: 2),
                        Text('ESPACE PRATICIEN', style: TextStyle(
                          color: p.muted, fontSize: 10,
                          fontWeight: FontWeight.w700, letterSpacing: 1.25)),
                      ],
                    ),
                  ]),
                  const SizedBox(height: 32),
                  Text(register ? 'Créer un compte' : 'Bienvenue',
                    style: TextStyle(
                      color: p.ink, fontSize: 30, letterSpacing: -.9,
                      height: 1.16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 9),
                  Text(register
                      ? 'Renseignez vos informations pour ouvrir votre espace.'
                      : 'Connectez-vous pour retrouver vos dossiers.',
                    style: TextStyle(
                      color: p.muted, fontSize: 14, height: 1.45)),
                  const SizedBox(height: 26),
                  DecoratedBox(
                    key: const Key('dev-auth-surface'),
                    decoration: BoxDecoration(
                      color: p.surface,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: p.border),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(19, 23, 19, 20),
                      child: Form(
                        key: _key,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (register) ...[
                              TextFormField(
                                key: const Key('dev-register-first-name'),
                                controller: _first,
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Prénom',
                                  prefixIcon: Icon(Icons.person_outline_rounded)),
                                validator: (value) =>
                                  (value?.trim().isEmpty ?? true)
                                    ? 'Prénom obligatoire' : null,
                              ),
                              const SizedBox(height: 13),
                              TextFormField(
                                key: const Key('dev-register-last-name'),
                                controller: _last,
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Nom',
                                  prefixIcon: Icon(Icons.badge_outlined)),
                                validator: (value) =>
                                  (value?.trim().isEmpty ?? true)
                                    ? 'Nom obligatoire' : null,
                              ),
                              const SizedBox(height: 13),
                            ],
                            TextFormField(
                              key: const Key('dev-auth-email'),
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.email],
                              decoration: const InputDecoration(
                                labelText: 'Adresse e-mail',
                                prefixIcon: Icon(Icons.alternate_email_rounded)),
                              validator: (value) {
                                final email = value?.trim() ?? '';
                                return email.contains('@') && email.contains('.')
                                  ? null : 'Adresse e-mail invalide';
                              },
                            ),
                            const SizedBox(height: 13),
                            TextFormField(
                              key: const Key('dev-auth-password'),
                              controller: _password,
                              obscureText: !_showPassword,
                              autofillHints: [
                                register
                                  ? AutofillHints.newPassword
                                  : AutofillHints.password,
                              ],
                              decoration: InputDecoration(
                                labelText: 'Mot de passe',
                                prefixIcon: const Icon(Icons.lock_outline_rounded),
                                suffixIcon: IconButton(
                                  tooltip: _showPassword
                                    ? 'Masquer le mot de passe'
                                    : 'Afficher le mot de passe',
                                  onPressed: () =>
                                    setState(() => _showPassword = !_showPassword),
                                  icon: Icon(_showPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined),
                                ),
                              ),
                              validator: (value) => (value?.length ?? 0) <
                                  (register ? 12 : 1)
                                ? register
                                  ? '12 caractères minimum'
                                  : 'Mot de passe obligatoire'
                                : null,
                              onFieldSubmitted: (_) => _submit(),
                            ),
                            if (!register && widget.onForgotPassword != null)
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  key: const Key('dev-auth-forgot-password'),
                                  onPressed: _busy
                                      ? null : widget.onForgotPassword,
                                  child: const Text('Mot de passe oublié ?'),
                                ),
                              ),
                            if (_error != null) ...[
                              const SizedBox(height: 14),
                              Text(_error!, key: const Key('dev-auth-error'),
                                style: TextStyle(
                                  color: p.danger, fontSize: 13, height: 1.45)),
                            ],
                            const SizedBox(height: 22),
                            SizedBox(
                              height: 49,
                              child: FilledButton(
                                key: const Key('dev-auth-submit'),
                                onPressed: _busy ? null : _submit,
                                child: _busy
                                  ? const SizedBox(
                                      width: 20, height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                  : Text(register
                                      ? 'Créer mon compte' : 'Se connecter'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextButton(
                    key: const Key('dev-auth-toggle'),
                    onPressed: _busy ? null : widget.onToggle,
                    child: Text(register
                        ? 'Déjà inscrit ? Se connecter'
                        : 'Pas de compte ? Créer un compte'),
                  ),
                  const SizedBox(height: 18),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(Icons.info_outline_rounded, size: 16,
                        color: p.muted),
                    const SizedBox(width: 9),
                    Expanded(child: Text(
                      'Environnement de test. Utilisez uniquement '
                      'des informations et des dossiers fictifs.',
                      key: const Key('dev-auth-warning'),
                      style: TextStyle(
                        color: p.muted, fontSize: 11.5, height: 1.5),
                    )),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DevConnectedWorkspace extends StatefulWidget {
  const DevConnectedWorkspace({
    super.key, required this.api, required this.session,
    required this.onSignedOut,
  });

  final DevAuthApi api;
  final DevSession session;
  final VoidCallback onSignedOut;

  @override
  State<DevConnectedWorkspace> createState() => _DevConnectedWorkspaceState();
}

class _DevConnectedWorkspaceState extends State<DevConnectedWorkspace> {
  late Future<List<DevPatient>> _patients;
  late DevPractitioner _profile;
  Uint8List? _avatar;
  final TextEditingController _search = TextEditingController();
  bool _working = false;
  String? _error;
  int _selectedTab = 0;
  Future<List<_PendingFollowUp>>? _followUps;

  @override
  void initState() {
    super.initState();
    _profile = widget.session.practitioner;
    _patients = widget.api.listPatients(widget.session);
    if (_profile.hasAvatar) unawaited(_loadAvatar());
  }

  @override
  void didUpdateWidget(covariant DevConnectedWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A reused widget must never keep account A's cached lists or avatar
    // when the parent replaces its authenticated session with account B.
    if (!identical(oldWidget.session, widget.session) ||
        oldWidget.api != widget.api) {
      _profile = widget.session.practitioner;
      _patients = widget.api.listPatients(widget.session);
      _avatar = null;
      _followUps = null;
      _selectedTab = 0;
      _error = null;
      _working = false;
      _search.clear();
      if (_profile.hasAvatar) unawaited(_loadAvatar());
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadAvatar() async {
    final session = widget.session;
    try {
      final bytes = await widget.api.loadAvatar(session);
      if (mounted && identical(widget.session, session) && session.isActive) {
        setState(() => _avatar = bytes);
      }
    } catch (_) {
      // Do not block the entire workspace if a profile photo is unavailable.
    }
  }

  Future<void> _openProfile() async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => DevProfileEditor(
        api: widget.api,
        session: widget.session,
        initial: _profile,
        avatar: _avatar,
        onChanged: (updated, bytes) {
          if (mounted) setState(() {
            _profile = updated;
            _avatar = bytes;
          });
        },
        onPasswordChanged: () {
          // Backend revoked every device; abandon profile & sensitive routes.
          if (!mounted) return;
          Navigator.of(context).popUntil((route) => route.isFirst);
          _avatar = null;
          widget.onSignedOut();
        },
      ),
    ));
  }

  void _reload() {
    if (!widget.session.isActive || !mounted) return;
    setState(() {
      _patients = widget.api.listPatients(widget.session);
      _followUps = null;
      if (_selectedTab == 2) _followUps = _loadFollowUps();
    });
  }

  Future<void> _addSyntheticPatient() async {
    if (_working || !widget.session.isActive) return;
    final session = widget.session;
    setState(() { _working = true; _error = null; });
    try {
      await widget.api.createSyntheticPatient(session);
      if (mounted && identical(widget.session, session)) _reload();
    } on DevApiException catch (error) {
      if (mounted && identical(widget.session, session)) {
        setState(() => _error = error.message);
      }
    } finally {
      if (mounted && identical(widget.session, session)) {
        setState(() => _working = false);
      }
    }
  }

  Future<void> _signOut({bool allDevices = false}) async {
    if (_working || !widget.session.isActive) return;
    final session = widget.session;
    setState(() { _working = true; _error = null; });
    String? failure;
    try {
      if (allDevices) {
        await widget.api.signOutEverywhere(session);
      } else {
        await widget.api.signOut(session);
      }
    } catch (_) {
      failure = 'La session locale est effacée. La révocation serveur '
          'n’a pas pu être confirmée. Réessayez lorsque le réseau revient.';
    } finally {
      session.clear();
      if (mounted && identical(widget.session, session)) {
        _avatar = null;
        if (failure != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(failure)));
        }
        widget.onSignedOut();
      }
    }
  }

  Future<void> _confirmSignOutEverywhere() async {
    if (_working) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Déconnecter tous les appareils ?'),
        content: const Text('Toutes les sessions de ce compte seront '
          'révoquées, y compris sur vos autres appareils.'),
        actions: [
          TextButton(
            key: const Key('dev-session-cancel-all'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            key: const Key('dev-session-confirm-all'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Tout déconnecter'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _signOut(allDevices: true);
    }
  }

  void _onSessionAction(String action) {
    if (action == 'all') {
      unawaited(_confirmSignOutEverywhere());
    } else if (action == 'switch') {
      // Explicit account switch: revoke the current device first.
      unawaited(_signOut());
    }
  }

  Future<List<_PendingFollowUp>> _loadFollowUps() async {
    final patients = await _patients;
    // Only practitioner-owned patients returned by this session's API.
    final bundles = await Future.wait(patients.map((patient) =>
        widget.api.getPatientClinical(widget.session, patient)));
    final result = <_PendingFollowUp>[];
    for (var index = 0; index < patients.length; index++) {
      for (final followUp in bundles[index].followUps) {
        if (followUp.status == 'planned') {
          result.add(_PendingFollowUp(patients[index], followUp));
        }
      }
    }
    result.sort((a, b) =>
        a.followUp.scheduledAt.compareTo(b.followUp.scheduledAt));
    return result;
  }

  void _selectTab(int index) {
    if (_working || !widget.session.isActive) return;
    setState(() {
      _selectedTab = index;
      if (index == 2 && _followUps == null) {
        _followUps = _loadFollowUps();
      }
    });
  }

  Future<void> _openPatient(DevPatient patient) async {
    if (!widget.session.isActive) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => DevPatientDetail(
        api: widget.api,
        session: widget.session,
        patient: patient,
      ),
    ));
    if (mounted && widget.session.isActive) _reload();
  }

  Widget _patientTile(DevPatient patient, PaletteData p) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Material(
      color: p.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(17),
        side: BorderSide(color: p.border)),
      child: InkWell(
        key: Key('dev-open-patient-${patient.id}'),
        onTap: () => _openPatient(patient),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          child: Row(children: [
            Container(
              height: 40, width: 40,
              decoration: BoxDecoration(
                color: p.tealSoft, borderRadius: BorderRadius.circular(13)),
              child: Icon(Icons.folder_shared_outlined,
                color: p.forest, size: 20),
            ),
            const SizedBox(width: 13),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(patient.displayName,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: p.ink,
                    fontSize: 13.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text('${patient.age} ans · Dossier clinique',
                  style: TextStyle(color: p.muted, fontSize: 12)),
              ],
            )),
            Icon(Icons.chevron_right_rounded, color: p.muted, size: 21),
          ]),
        ),
      ),
    ),
  );

  Widget _quickAction({
    required String title,
    required IconData icon,
    required VoidCallback action,
    required PaletteData palette,
    Key? key,
  }) => Expanded(
    child: Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: key,
        borderRadius: BorderRadius.circular(16),
        onTap: action,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(color: palette.border),
            borderRadius: BorderRadius.circular(16)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: palette.forest, size: 23),
            const SizedBox(height: 10),
            Text(title, textAlign: TextAlign.center,
              style: TextStyle(color: palette.ink,
                fontSize: 12.5, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    ),
  );

  Widget _patientsContent(PaletteData p, {
    required bool overview,
  }) => FutureBuilder<List<DevPatient>>(
    key: Key(overview ? 'dev-patients-home' : 'dev-patients-loader'),
    future: _patients,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 42),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (snapshot.hasError) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Impossible de charger les dossiers de ce compte.',
              key: const Key('dev-patients-error'),
              style: TextStyle(color: p.danger, fontSize: 13)),
            TextButton.icon(
              key: const Key('dev-patients-retry'),
              onPressed: _reload,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
            ),
          ],
        );
      }
      final source = snapshot.data ?? const <DevPatient>[];
      final term = overview ? '' : _search.text.trim().toLowerCase();
      final patients = source.where((patient) =>
        patient.displayName.toLowerCase().contains(term)).toList();
      if (patients.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 17),
          child: Text(source.isEmpty
              ? 'Aucun patient fictif dans ce compte.'
              : 'Aucun dossier fictif ne correspond à cette recherche.',
            key: const Key('dev-patients-empty'),
            style: TextStyle(color: p.muted, fontSize: 13.5)),
        );
      }
      final visible = overview ? patients.take(3).toList() : patients;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!overview) ...[
            Text('${patients.length} dossier(s) fictif(s)',
              style: TextStyle(color: p.muted, fontSize: 12)),
            const SizedBox(height: 11),
          ],
          for (final patient in visible) _patientTile(patient, p),
        ],
      );
    },
  );

  Widget _createButton(PaletteData p) => SizedBox(
    width: double.infinity,
    child: FilledButton.icon(
      key: const Key('dev-add-synthetic-patient'),
      onPressed: _working ? null : _addSyntheticPatient,
      icon: const Icon(Icons.add_rounded, size: 19),
      label: const Text('Nouveau dossier fictif'),
    ),
  );

  Widget _home(PaletteData p) => ListView(
    key: const Key('dev-tab-home'),
    padding: const EdgeInsets.fromLTRB(23, 20, 23, 36),
    children: [
      Text('ESPACE PRATICIEN',
        style: TextStyle(color: p.forest, fontSize: 10.5,
          fontWeight: FontWeight.w700, letterSpacing: 1.35)),
      const SizedBox(height: 9),
      Text(_profile.displayName, key: const Key('dev-workspace-name'),
        style: TextStyle(color: p.ink, fontSize: 26,
          height: 1.2, fontWeight: FontWeight.w700)),
      const SizedBox(height: 5),
      Text('Vue d’ensemble de vos dossiers',
        style: TextStyle(color: p.muted, fontSize: 13)),
      const SizedBox(height: 25),
      FutureBuilder<List<DevPatient>>(
        future: _patients,
        builder: (_, snapshot) => Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(21),
            border: Border.all(color: p.border)),
          child: Row(children: [
            Container(
              height: 51, width: 51,
              decoration: BoxDecoration(
                color: p.tealSoft, borderRadius: BorderRadius.circular(15)),
              child: Icon(Icons.folder_copy_outlined,
                size: 25, color: p.forest)),
            const SizedBox(width: 16),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(snapshot.hasData
                    ? '${snapshot.data!.length}'
                    : snapshot.hasError ? '—' : '…',
                  key: const Key('dev-summary-patient-count'),
                  style: TextStyle(color: p.ink,
                    fontSize: 27, fontWeight: FontWeight.w700)),
                Text('Dossiers de votre compte',
                  style: TextStyle(color: p.muted, fontSize: 12.5)),
              ],
            )),
            IconButton(
              key: const Key('dev-workspace-refresh'),
              tooltip: 'Actualiser les dossiers',
              onPressed: _reload,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ]),
        ),
      ),
      const SizedBox(height: 25),
      Text('Accès rapide', style: TextStyle(
        color: p.ink, fontSize: 17, fontWeight: FontWeight.w700)),
      const SizedBox(height: 13),
      Row(children: [
        _quickAction(
          key: const Key('dev-quick-patients'),
          title: 'Dossiers',
          icon: Icons.folder_shared_outlined,
          action: () => _selectTab(1), palette: p),
        const SizedBox(width: 10),
        _quickAction(
          key: const Key('dev-quick-followups'),
          title: 'Suivis',
          icon: Icons.event_note_outlined,
          action: () => _selectTab(2), palette: p),
        const SizedBox(width: 10),
        _quickAction(
          key: const Key('dev-quick-profile'),
          title: 'Mon compte',
          icon: Icons.person_outline_rounded,
          action: () => _selectTab(3), palette: p),
      ]),
      const SizedBox(height: 27),
      Row(children: [
        Expanded(child: Text('Dossiers récents',
          style: TextStyle(color: p.ink,
            fontSize: 17, fontWeight: FontWeight.w700))),
        TextButton(
          onPressed: () => _selectTab(1),
          child: const Text('Voir tout')),
      ]),
      const SizedBox(height: 11),
      _patientsContent(p, overview: true),
      const SizedBox(height: 15),
      _createButton(p),
      if (_error != null) ...[
        const SizedBox(height: 12),
        Text(_error!, key: const Key('dev-workspace-error'),
          style: TextStyle(color: p.danger, fontSize: 13)),
      ],
      const SizedBox(height: 22),
      Text('Version de test · Dossiers fictifs uniquement',
        style: TextStyle(color: p.muted, fontSize: 11.5)),
    ],
  );

  Widget _registry(PaletteData p) => ListView(
    key: const Key('dev-tab-patients'),
    padding: const EdgeInsets.fromLTRB(23, 22, 23, 38),
    children: [
      Text('Dossiers patients', style: TextStyle(
        color: p.ink, fontSize: 23, fontWeight: FontWeight.w700)),
      const SizedBox(height: 7),
      Text('Retrouvez et consultez vos dossiers.',
        style: TextStyle(color: p.muted, fontSize: 13)),
      const SizedBox(height: 23),
      TextField(
        key: const Key('dev-search-patients'),
        controller: _search,
        onChanged: (_) => setState(() {}),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Rechercher un dossier',
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          suffixIcon: _search.text.isEmpty ? null : IconButton(
            tooltip: 'Effacer la recherche',
            onPressed: () {
              _search.clear();
              setState(() {});
            },
            icon: const Icon(Icons.close_rounded, size: 18),
          ),
        ),
      ),
      const SizedBox(height: 21),
      _patientsContent(p, overview: false),
      const SizedBox(height: 16),
      _createButton(p),
      if (_error != null) ...[
        const SizedBox(height: 12),
        Text(_error!, key: const Key('dev-workspace-error'),
          style: TextStyle(color: p.danger, fontSize: 13)),
      ],
    ],
  );

  Widget _followUpPage(PaletteData p) => ListView(
    key: const Key('dev-tab-followups'),
    padding: const EdgeInsets.fromLTRB(23, 22, 23, 38),
    children: [
      Row(children: [
        Expanded(child: Text('Suivis à venir',
          style: TextStyle(color: p.ink,
            fontSize: 23, fontWeight: FontWeight.w700))),
        IconButton(
          key: const Key('dev-followups-refresh'),
          tooltip: 'Actualiser les suivis',
          onPressed: _reload, icon: const Icon(Icons.refresh_rounded)),
      ]),
      const SizedBox(height: 7),
      Text('Rendez-vous enregistrés dans vos dossiers.',
        style: TextStyle(color: p.muted, fontSize: 13)),
      const SizedBox(height: 24),
      FutureBuilder<List<_PendingFollowUp>>(
        future: _followUps,
        builder: (_, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasError) {
            return Text('Impossible de charger les suivis. Réessayez.',
              key: const Key('dev-followups-error'),
              style: TextStyle(color: p.danger, fontSize: 13));
          }
          final followUps = snapshot.data ?? const <_PendingFollowUp>[];
          if (followUps.isEmpty) {
            return Text('Aucun suivi programmé pour ce compte.',
              key: const Key('dev-followups-empty'),
              style: TextStyle(color: p.muted, fontSize: 13.5));
          }
          return Column(children: [
            for (final item in followUps)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: p.surface,
                  borderRadius: BorderRadius.circular(17),
                  child: InkWell(
                    key: Key('dev-open-followup-${item.followUp.id}'),
                    borderRadius: BorderRadius.circular(17),
                    onTap: () => _openPatient(item.patient),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: p.border),
                        borderRadius: BorderRadius.circular(17)),
                      padding: const EdgeInsets.all(16),
                      child: Row(children: [
                        Icon(Icons.event_available_outlined,
                          size: 22, color: p.forest),
                        const SizedBox(width: 13),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.followUp.reason,
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: p.ink,
                                fontWeight: FontWeight.w700)),
                            const SizedBox(height: 5),
                            Text(item.patient.displayName,
                              style: TextStyle(color: p.muted, fontSize: 12)),
                            Text(_formatDate(item.followUp.scheduledAt),
                              style: TextStyle(color: p.muted, fontSize: 12)),
                          ],
                        )),
                        Icon(Icons.chevron_right_rounded,
                          color: p.muted, size: 21),
                      ]),
                    ),
                  ),
                ),
              ),
          ]);
        },
      ),
    ],
  );

  String _formatDate(DateTime date) {
    final value = date.toLocal();
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/${value.year}';
  }

  Widget _accountPage(PaletteData p) => ListView(
    key: const Key('dev-tab-account'),
    padding: const EdgeInsets.fromLTRB(23, 22, 23, 38),
    children: [
      Text('Mon compte', style: TextStyle(
        color: p.ink, fontSize: 23, fontWeight: FontWeight.w700)),
      const SizedBox(height: 21),
      Container(
        padding: const EdgeInsets.all(19),
        decoration: BoxDecoration(
          color: p.surface,
          border: Border.all(color: p.border),
          borderRadius: BorderRadius.circular(19)),
        child: Row(children: [
          CircleAvatar(
            radius: 27, backgroundColor: p.tealSoft,
            foregroundImage: _avatar == null ? null : MemoryImage(_avatar!),
            child: _avatar == null
              ? Icon(Icons.person_outline_rounded,
                  size: 26, color: p.forest) : null),
          const SizedBox(width: 15),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_profile.displayName,
                style: TextStyle(color: p.ink,
                  fontWeight: FontWeight.w700, fontSize: 17)),
              const SizedBox(height: 4),
              Text(_profile.email,
                maxLines: 2, style: TextStyle(
                  color: p.muted, fontSize: 12.5)),
            ],
          )),
        ]),
      ),
      const SizedBox(height: 23),
      OutlinedButton.icon(
        key: const Key('dev-account-edit'),
        onPressed: _working ? null : _openProfile,
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Modifier mon profil'),
      ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        key: const Key('dev-account-switch'),
        onPressed: _working ? null : () => _signOut(),
        icon: const Icon(Icons.switch_account_rounded),
        label: const Text('Changer de praticien'),
      ),
      const SizedBox(height: 12),
      TextButton.icon(
        key: const Key('dev-account-signout-all'),
        onPressed: _working ? null : _confirmSignOutEverywhere,
        icon: const Icon(Icons.phonelink_erase_outlined),
        label: const Text('Déconnecter tous les appareils'),
      ),
      const SizedBox(height: 20),
      Text('Vos dossiers sont accessibles uniquement '
          'avec votre session authentifiée.',
        style: TextStyle(color: p.muted, fontSize: 12.5)),
    ],
  );

  @override
  Widget build(BuildContext context) {
    if (!widget.session.isActive) {
      return const Scaffold(
        body: Center(child: Text('Session terminée.')),
      );
    }
    final p = Palette.of(context);
    final compact = MediaQuery.sizeOf(context).width < 640;
    final content = switch (_selectedTab) {
      1 => _registry(p),
      2 => _followUpPage(p),
      3 => _accountPage(p),
      _ => _home(p),
    };
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 18,
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 31, height: 31,
            decoration: BoxDecoration(
              color: p.tealSoft,
              borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.health_and_safety_outlined,
              size: 18, color: p.forest),
          ),
          const SizedBox(width: 10),
          const Text('MediSuivi'),
        ]),
        actions: [
          IconButton(
            key: const Key('dev-workspace-profile'),
            tooltip: 'Mon profil',
            onPressed: _working ? null : _openProfile,
            icon: CircleAvatar(
              radius: 16, backgroundColor: p.tealSoft,
              foregroundImage: _avatar == null ? null : MemoryImage(_avatar!),
              child: _avatar == null
                ? Icon(Icons.person_outline_rounded,
                    color: p.forest, size: 19) : null,
            ),
          ),
          PopupMenuButton<String>(
            key: const Key('dev-session-actions'),
            enabled: !_working,
            tooltip: 'Comptes et sessions',
            onSelected: _onSessionAction,
            itemBuilder: (_) => const [
              PopupMenuItem<String>(
                value: 'switch',
                child: Text('Changer de praticien')),
              PopupMenuItem<String>(
                value: 'all',
                child: Text('Déconnecter tous les appareils')),
            ],
            icon: const Icon(Icons.more_vert_rounded),
          ),
          IconButton(
            key: const Key('dev-workspace-logout'),
            onPressed: _working ? null : () => _signOut(),
            tooltip: 'Se déconnecter',
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: Center(child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: AnimatedSwitcher(
            duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero : const Duration(milliseconds: 210),
            child: content,
          ),
        )),
      ),
      bottomNavigationBar: SafeArea(top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            compact ? 10 : 28, 5, compact ? 10 : 28, 7),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 740),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: NavigationBar(
                  key: const Key('dev-connected-navigation'),
                  selectedIndex: _selectedTab,
                  height: 69,
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  onDestinationSelected: _selectTab,
                  destinations: const [
                    NavigationDestination(
                      key: Key('dev-nav-home'),
                      icon: Icon(Icons.space_dashboard_outlined),
                      selectedIcon: Icon(Icons.space_dashboard_rounded),
                      label: 'Accueil'),
                    NavigationDestination(
                      key: Key('dev-nav-patients'),
                      icon: Icon(Icons.folder_open_outlined),
                      selectedIcon: Icon(Icons.folder_rounded),
                      label: 'Dossiers'),
                    NavigationDestination(
                      key: Key('dev-nav-followups'),
                      icon: Icon(Icons.event_note_outlined),
                      selectedIcon: Icon(Icons.event_note_rounded),
                      label: 'Suivis'),
                    NavigationDestination(
                      key: Key('dev-nav-account'),
                      icon: Icon(Icons.person_outline_rounded),
                      selectedIcon: Icon(Icons.person_rounded),
                      label: 'Compte'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PendingFollowUp {
  const _PendingFollowUp(this.patient, this.followUp);
  final DevPatient patient;
  final DevFollowUp followUp;
}
