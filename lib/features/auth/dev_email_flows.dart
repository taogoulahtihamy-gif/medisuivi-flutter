import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'dev_auth_api.dart';

/// Code-only verification, without browser links or unauthenticated data access.
class DevEmailVerificationScreen extends StatefulWidget {
  const DevEmailVerificationScreen({
    super.key,
    required this.api,
    required this.email,
    required this.onVerified,
    required this.onBack,
  });

  final DevAuthApi api;
  final String email;
  final VoidCallback onVerified;
  final VoidCallback onBack;

  @override
  State<DevEmailVerificationScreen> createState() =>
      _DevEmailVerificationScreenState();
}

class _DevEmailVerificationScreenState
    extends State<DevEmailVerificationScreen> {
  final _code = TextEditingController();
  bool _busy = false;
  String? _message;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !RegExp(r'^[0-9]{12}$').hasMatch(_code.text.trim())) {
      setState(() => _message = 'Saisissez les 12 chiffres du code.');
      return;
    }
    setState(() { _busy = true; _message = null; });
    try {
      await widget.api.verifyEmail(widget.email, _code.text);
      if (mounted) widget.onVerified();
    } on DevApiException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _message = 'Connexion au serveur impossible.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    if (_busy) return;
    setState(() { _busy = true; _message = null; });
    try {
      await widget.api.resendEmailCode(widget.email);
      if (mounted) setState(() => _message =
        'Si nécessaire, un nouveau code sera envoyé.');
    } on DevApiException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmer mon adresse'),
        leading: IconButton(
          onPressed: _busy ? null : widget.onBack,
          tooltip: 'Retour',
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 46, 24, 36),
          children: [
            Icon(Icons.mark_email_read_outlined,
              color: p.forest, size: 45),
            const SizedBox(height: 22),
            Text('Vérification de l’e-mail',
              style: TextStyle(color: p.ink,
                fontWeight: FontWeight.w700, fontSize: 25)),
            const SizedBox(height: 12),
            Text('Saisissez le code de 12 chiffres envoyé à '
              '${widget.email}. Il expire après 30 minutes.',
              style: TextStyle(color: p.muted, fontSize: 14, height: 1.45)),
            const SizedBox(height: 28),
            TextField(
              key: const Key('dev-email-code'),
              controller: _code,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.oneTimeCode],
              maxLength: 12,
              decoration: const InputDecoration(
                labelText: 'Code de vérification',
                counterText: '',
              ),
              onSubmitted: (_) => _submit(),
            ),
            if (_message != null) ...[
              const SizedBox(height: 12),
              Text(_message!, key: const Key('dev-email-feedback'),
                style: TextStyle(color: p.muted, fontSize: 13)),
            ],
            const SizedBox(height: 25),
            FilledButton(
              key: const Key('dev-email-verify'),
              onPressed: _busy ? null : _submit,
              child: const Text('Confirmer mon adresse'),
            ),
            TextButton(
              key: const Key('dev-email-resend'),
              onPressed: _busy ? null : _resend,
              child: const Text('Renvoyer le code'),
            ),
            const SizedBox(height: 15),
            Text('Espace de développement : comptes fictifs uniquement.',
              style: TextStyle(color: p.muted, fontSize: 12)),
          ],
        ),
      ))),
    );
  }
}

/// Two-step recovery without assuming the email belongs to an account.
class DevPasswordRecoveryScreen extends StatefulWidget {
  const DevPasswordRecoveryScreen({
    super.key,
    required this.api,
    required this.onFinished,
    required this.onBack,
  });

  final DevAuthApi api;
  final VoidCallback onFinished;
  final VoidCallback onBack;

  @override
  State<DevPasswordRecoveryScreen> createState() =>
      _DevPasswordRecoveryScreenState();
}

class _DevPasswordRecoveryScreenState
    extends State<DevPasswordRecoveryScreen> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _requested = false;
  bool _busy = false;
  String? _message;

  @override
  void dispose() {
    for (final controller in [_email, _code, _password, _confirm]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _requestCode() async {
    if (_busy || !_email.text.contains('@') ||
        !_email.text.contains('.')) {
      setState(() => _message = 'Adresse e-mail invalide.');
      return;
    }
    setState(() { _busy = true; _message = null; });
    try {
      await widget.api.requestPasswordReset(_email.text);
      if (mounted) setState(() => _requested = true);
    } on DevApiException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reset() async {
    if (_busy) return;
    if (!RegExp(r'^[0-9]{12}$').hasMatch(_code.text.trim()) ||
        _password.text.length < 12 || _password.text != _confirm.text) {
      setState(() => _message =
        'Vérifiez le code, le nouveau mot de passe et sa confirmation.');
      return;
    }
    setState(() { _busy = true; _message = null; });
    try {
      await widget.api.resetForgottenPassword(
        email: _email.text,
        code: _code.text,
        newPassword: _password.text,
      );
      if (mounted) widget.onFinished();
    } on DevApiException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } catch (_) {
      if (mounted) setState(() =>
        _message = 'Impossible de joindre le serveur.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Récupérer mon compte'),
        leading: IconButton(
          onPressed: _busy ? null : widget.onBack,
          tooltip: 'Retour',
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 44, 24, 36),
          children: [
            Icon(Icons.lock_reset_outlined,
              size: 46, color: p.forest),
            const SizedBox(height: 20),
            Text(_requested ? 'Choisir un nouveau mot de passe'
                            : 'Mot de passe oublié',
              style: TextStyle(color: p.ink,
                fontSize: 24, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Text(_requested
                ? 'Si votre compte existe, utilisez le code reçu '
                  'par e-mail. Il reste valable 15 minutes.'
                : 'Un code de récupération sera envoyé si cette '
                  'adresse est associée à un compte.',
              style: TextStyle(color: p.muted, fontSize: 14, height: 1.5)),
            const SizedBox(height: 26),
            TextField(
              key: const Key('dev-reset-email'),
              controller: _email,
              enabled: !_requested && !_busy,
              autofillHints: const [AutofillHints.email],
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Adresse e-mail'),
            ),
            if (_requested) ...[
              const SizedBox(height: 13),
              TextField(
                key: const Key('dev-reset-code'),
                controller: _code,
                maxLength: 12,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Code de récupération', counterText: ''),
              ),
              const SizedBox(height: 13),
              TextField(
                key: const Key('dev-reset-password'),
                controller: _password,
                obscureText: true,
                autofillHints: const [AutofillHints.newPassword],
                decoration: const InputDecoration(
                  labelText: 'Nouveau mot de passe (12 caractères minimum)'),
              ),
              const SizedBox(height: 13),
              TextField(
                key: const Key('dev-reset-confirm'),
                controller: _confirm,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirmer le mot de passe'),
              ),
            ],
            if (_message != null) ...[
              const SizedBox(height: 14),
              Text(_message!, key: const Key('dev-reset-feedback'),
                style: TextStyle(color: p.muted, fontSize: 13)),
            ],
            const SizedBox(height: 23),
            FilledButton(
              key: const Key('dev-reset-submit'),
              onPressed: _busy ? null : (_requested ? _reset : _requestCode),
              child: Text(_requested
                  ? 'Réinitialiser le mot de passe' : 'Recevoir mon code'),
            ),
            if (_requested)
              TextButton(
                key: const Key('dev-reset-resend'),
                onPressed: _busy ? null : () async {
                  setState(() => _requested = false);
                  await _requestCode();
                },
                child: const Text('Demander un nouveau code')),
            const SizedBox(height: 17),
            Text('Environnement de développement. '
              'Ne saisissez aucune donnée de santé réelle.',
              style: TextStyle(color: p.muted, fontSize: 12)),
          ],
        ),
      ))),
    );
  }
}
