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

  @override
  void initState() {
    super.initState();
    _profile = widget.session.practitioner;
    _patients = widget.api.listPatients(widget.session);
    if (_profile.hasAvatar) unawaited(_loadAvatar());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadAvatar() async {
    try {
      final bytes = await widget.api.loadAvatar(widget.session);
      if (mounted) setState(() => _avatar = bytes);
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

  void _reload() => setState(() {
    _patients = widget.api.listPatients(widget.session);
  });

  Future<void> _addSyntheticPatient() async {
    if (_working) return;
    setState(() { _working = true; _error = null; });
    try {
      await widget.api.createSyntheticPatient(widget.session);
      if (mounted) _reload();
    } on DevApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _signOut({bool allDevices = false}) async {
    if (_working) return;
    setState(() { _working = true; _error = null; });
    String? failure;
    try {
      if (allDevices) {
        await widget.api.signOutEverywhere(widget.session);
      } else {
        await widget.api.signOut(widget.session);
      }
    } catch (_) {
      failure = 'La session locale est effacée. La révocation serveur '
          'n’a pas pu être confirmée. Réessayez lorsque le réseau revient.';
    } finally {
      // Never retain previous practitioner data, even if server is unreachable.
      widget.session.clear();
      _avatar = null;
      if (mounted) {
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

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('MediSuivi'),
        actions: [
          IconButton(
            key: const Key('dev-workspace-profile'),
            tooltip: 'Mon profil',
            onPressed: _openProfile,
            icon: CircleAvatar(
              radius: 17,
              backgroundColor: p.tealSoft,
              foregroundImage: _avatar == null ? null : MemoryImage(_avatar!),
              child: _avatar == null
                ? Icon(Icons.person_outline_rounded, color: p.forest, size: 20)
                : null,
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
                child: Row(children: [
                  Icon(Icons.switch_account_outlined, size: 20),
                  SizedBox(width: 10),
                  Expanded(child: Text('Changer de praticien',
                    softWrap: true, maxLines: 2)),
                ]),
              ),
              PopupMenuItem<String>(
                value: 'all',
                child: Row(children: [
                  Icon(Icons.phonelink_erase_rounded, size: 20),
                  SizedBox(width: 10),
                  Expanded(child: Text('Déconnecter tous les appareils',
                    softWrap: true, maxLines: 2)),
                ]),
              ),
            ],
            icon: const Icon(Icons.more_vert_rounded),
          ),
          IconButton(
            key: const Key('dev-workspace-logout'),
            onPressed: _working ? null : () => _signOut(),
            tooltip: 'Se déconnecter',
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 38),
          children: [
            Text('ESPACE PERSONNEL',
              style: TextStyle(color: p.forest,
                letterSpacing: 1.2, fontWeight: FontWeight.w700, fontSize: 11)),
            const SizedBox(height: 10),
            Text(_profile.displayName,
              key: const Key('dev-workspace-name'),
              style: TextStyle(color: p.ink,
                height: 1.18, fontWeight: FontWeight.w700, fontSize: 25)),
            const SizedBox(height: 5),
            Text(_profile.specialty.isNotEmpty
                ? _profile.specialty
                : _profile.email,
              style: TextStyle(color: p.muted, fontSize: 13)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: Text('Dossiers du compte',
                style: TextStyle(color: p.ink, fontSize: 18,
                  fontWeight: FontWeight.w700))),
              IconButton(
                tooltip: 'Actualiser les dossiers',
                onPressed: _reload,
                icon: const Icon(Icons.refresh_rounded)),
            ]),
            const SizedBox(height: 6),
            Text('Les dossiers affichés appartiennent uniquement à ce compte.',
              style: TextStyle(color: p.muted, fontSize: 12.5)),
            const SizedBox(height: 16),
            TextField(
              key: const Key('dev-search-patients'),
              controller: _search,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Rechercher un dossier fictif',
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
            const SizedBox(height: 16),
            FutureBuilder<List<DevPatient>>(
              key: const Key('dev-patients-loader'),
              future: _patients,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
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
                final term = _search.text.trim().toLowerCase();
                final patients = source.where((p) =>
                  p.displayName.toLowerCase().contains(term)).toList();
                if (patients.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    child: Text(source.isEmpty
                        ? 'Aucun patient fictif dans ce compte.'
                        : 'Aucun dossier fictif ne correspond à cette recherche.',
                      key: const Key('dev-patients-empty'),
                      style: TextStyle(color: p.muted, fontSize: 14)),
                  );
                }
                return Column(children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text('${patients.length} dossier(s) fictif(s)',
                        style: TextStyle(color: p.muted, fontSize: 12)),
                    ),
                  ),
                  for (final patient in patients)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: Material(
                        color: p.surface.withValues(alpha: .70),
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: BorderSide(color: p.border, width: .8),
                        ),
                        child: InkWell(
                          key: Key('dev-open-patient-${patient.id}'),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(builder: (_) =>
                              DevPatientDetail(
                                api: widget.api,
                                session: widget.session,
                                patient: patient,
                              ))),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 13, vertical: 16),
                            child: Row(children: [
                              Icon(Icons.folder_shared_outlined,
                                color: p.forest, size: 19),
                              const SizedBox(width: 12),
                              Expanded(child: Text(patient.displayName,
                                maxLines: 2, overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: p.ink,
                                  fontSize: 14.5, fontWeight: FontWeight.w600))),
                              Text('${patient.age} ans',
                                style: TextStyle(color: p.muted, fontSize: 12.5)),
                              const SizedBox(width: 5),
                              Icon(Icons.chevron_right_rounded,
                                color: p.muted, size: 19),
                            ]),
                          ),
                        ),
                      ),
                    ),
                ]);
              },
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              key: const Key('dev-add-synthetic-patient'),
              onPressed: _working ? null : _addSyntheticPatient,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Créer un dossier FICTIF'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(_error!, key: const Key('dev-workspace-error'),
                style: TextStyle(color: p.danger, fontSize: 13)),
            ],
            const SizedBox(height: 21),
            Text('Environnement de développement · patients fictifs uniquement. '
              'Les fonctionnalités cliniques complètes restent en validation.',
              style: TextStyle(color: p.muted, fontSize: 12.5,
                height: 1.5)),
          ],
        ),
      ))),
    );
  }
}
