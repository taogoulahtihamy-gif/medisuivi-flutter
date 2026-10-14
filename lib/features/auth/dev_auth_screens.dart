import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'dev_auth_api.dart';

/// These screens never use DemoScope/PersistentScope. Remote patients
/// originate only from the signed-in API session.
class DevAuthScreen extends StatefulWidget {
  const DevAuthScreen({
    super.key, required this.api, required this.isRegister,
    required this.onAuthenticated, required this.onBack,
    required this.onToggle,
  });

  final DevAuthApi api;
  final bool isRegister;
  final ValueChanged<DevSession> onAuthenticated;
  final VoidCallback onBack;
  final VoidCallback onToggle;

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
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Retour',
          onPressed: _busy ? null : widget.onBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('MediSuivi'),
      ),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
          child: Form(
            key: _key,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.medical_information_outlined,
                  size: 39, color: p.forest),
                const SizedBox(height: 22),
                Text(widget.isRegister
                    ? 'Créer mon compte' : 'Bienvenue sur MediSuivi',
                  style: TextStyle(color: p.ink, fontSize: 25,
                    height: 1.2, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(widget.isRegister
                    ? 'Inscription au serveur local de développement.'
                    : 'Connectez-vous à votre espace de test privé.',
                  style: TextStyle(color: p.muted, fontSize: 14,
                    height: 1.45)),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: p.tealSoft.withValues(alpha: .55),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'ENVIRONNEMENT DE DÉVELOPPEMENT. '
                    'Comptes et patients fictifs uniquement. '
                    'N’entrez aucune donnée médicale réelle.',
                    key: const Key('dev-auth-warning'),
                    style: TextStyle(color: p.ink, fontSize: 12.5,
                      height: 1.4, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 20),
                if (widget.isRegister) ...[
                  TextFormField(
                    key: const Key('dev-register-first-name'),
                    controller: _first,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Prénom'),
                    validator: (value) =>
                      (value?.trim().isEmpty ?? true)
                        ? 'Prénom obligatoire' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('dev-register-last-name'),
                    controller: _last,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Nom'),
                    validator: (value) =>
                      (value?.trim().isEmpty ?? true)
                        ? 'Nom obligatoire' : null,
                  ),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  key: const Key('dev-auth-email'),
                  controller: _email,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Adresse e-mail'),
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    return email.contains('@') && email.contains('.')
                      ? null : 'Adresse e-mail invalide';
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('dev-auth-password'),
                  controller: _password,
                  obscureText: !_showPassword,
                  autofillHints: [
                    widget.isRegister
                      ? AutofillHints.newPassword : AutofillHints.password,
                  ],
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    suffixIcon: IconButton(
                      tooltip: _showPassword
                          ? 'Masquer le mot de passe' : 'Afficher le mot de passe',
                      onPressed: () =>
                          setState(() => _showPassword = !_showPassword),
                      icon: Icon(_showPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                    ),
                  ),
                  validator: (value) => (value?.length ?? 0) <
                          (widget.isRegister ? 12 : 1)
                    ? widget.isRegister
                      ? '12 caractères minimum' : 'Mot de passe obligatoire'
                    : null,
                  onFieldSubmitted: (_) => _submit(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 15),
                  Text(_error!, key: const Key('dev-auth-error'),
                    style: TextStyle(color: p.danger, fontSize: 13)),
                ],
                const SizedBox(height: 23),
                FilledButton(
                  key: const Key('dev-auth-submit'),
                  onPressed: _busy ? null : _submit,
                  child: _busy
                    ? const SizedBox(height: 19, width: 19,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(widget.isRegister
                        ? 'Créer un compte de test' : 'Se connecter'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  key: const Key('dev-auth-toggle'),
                  onPressed: _busy ? null : widget.onToggle,
                  child: Text(widget.isRegister
                    ? 'Déjà inscrit ? Se connecter'
                    : 'Pas encore de compte ? Inscription de test'),
                ),
              ],
            ),
          ),
        ),
      ))),
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
  bool _working = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _patients = widget.api.listPatients(widget.session);
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

  Future<void> _signOut() async {
    if (_working) return;
    setState(() { _working = true; _error = null; });
    try {
      await widget.api.signOut(widget.session);
      if (mounted) widget.onSignedOut();
    } on DevApiException catch (error) {
      if (mounted) setState(() => _error =
          '${error.message} La déconnexion n’a pas été confirmée.');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace de test privé'),
        actions: [
          IconButton(
            key: const Key('dev-workspace-logout'),
            onPressed: _working ? null : _signOut,
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
            CircleAvatar(
              radius: 35, backgroundColor: p.tealSoft,
              child: Icon(Icons.person_outline_rounded,
                color: p.forest, size: 34)),
            const SizedBox(height: 13),
            Text(widget.session.practitioner.displayName,
              key: const Key('dev-workspace-name'),
              textAlign: TextAlign.center,
              style: TextStyle(color: p.ink,
                fontWeight: FontWeight.w700, fontSize: 22)),
            const SizedBox(height: 4),
            Text(widget.session.practitioner.email,
              textAlign: TextAlign.center,
              style: TextStyle(color: p.muted, fontSize: 13)),
            const SizedBox(height: 18),
            Text('Espace de développement authentifié. Les dossiers de '
              'démonstration ne sont jamais mélangés avec ce compte. '
              'N’utilisez aucun patient réel.',
              textAlign: TextAlign.center,
              style: TextStyle(color: p.muted,
                fontSize: 13, height: 1.5)),
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
            const SizedBox(height: 12),
            FutureBuilder<List<DevPatient>>(
              key: const Key('dev-patients-loader'),
              future: _patients,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text('Impossible de charger les dossiers de ce compte.',
                    key: const Key('dev-patients-error'),
                    style: TextStyle(color: p.danger, fontSize: 13));
                }
                final patients = snapshot.data ?? const <DevPatient>[];
                if (patients.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    child: Text('Aucun patient fictif dans ce compte.',
                      key: const Key('dev-patients-empty'),
                      style: TextStyle(color: p.muted, fontSize: 14)),
                  );
                }
                return Column(children: [
                  for (final patient in patients)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: p.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: p.border),
                        ),
                        child: Row(children: [
                          Icon(Icons.folder_shared_outlined, color: p.forest),
                          const SizedBox(width: 12),
                          Expanded(child: Text(patient.displayName,
                            maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: p.ink, fontSize: 14))),
                          Text('${patient.age} ans',
                            style: TextStyle(color: p.muted, fontSize: 12)),
                        ]),
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
            Text('Photo de profil et accès clinique complet : à intégrer '
              'après les migrations et la validation de sécurité.',
              style: TextStyle(color: p.muted, fontSize: 12.5,
                height: 1.5)),
          ],
        ),
      ))),
    );
  }
}
