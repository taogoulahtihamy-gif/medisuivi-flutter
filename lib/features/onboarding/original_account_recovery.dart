import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../auth/dev_auth_api.dart';

/// Recovery pages using the existing original Nocturne Clinique form language.
/// They are not taken from the discarded connected dashboard.
class OriginalEmailVerificationForm extends StatefulWidget {
  const OriginalEmailVerificationForm({
    super.key, required this.api, required this.email,
    required this.onVerified, required this.onBack,
  });
  final DevAuthApi api;
  final String email;
  final VoidCallback onVerified;
  final VoidCallback onBack;

  @override
  State<OriginalEmailVerificationForm> createState() =>
      _OriginalEmailVerificationFormState();
}

class _OriginalEmailVerificationFormState
    extends State<OriginalEmailVerificationForm> {
  final _code = TextEditingController();
  bool _working = false;
  String? _message;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_working) return;
    if (!RegExp(r'^[0-9]{12}$').hasMatch(_code.text.trim())) {
      setState(() => _message = 'Le code comporte 12 chiffres.');
      return;
    }
    setState(() { _working = true; _message = null; });
    try {
      await widget.api.verifyEmail(widget.email, _code.text.trim());
      if (mounted) widget.onVerified();
    } on DevApiException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } catch (_) {
      if (mounted) setState(() => _message = 'Vérification indisponible.');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _resend() async {
    if (_working) return;
    setState(() { _working = true; _message = null; });
    try {
      await widget.api.resendEmailCode(widget.email);
      if (mounted) setState(() =>
          _message = 'Un code sera envoyé si nécessaire.');
    } on DevApiException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return _OriginalSecurityPage(
      title: 'Confirmer votre adresse',
      subtitle: 'Saisissez le code de 12 chiffres reçu par e-mail.',
      onBack: _working ? null : widget.onBack,
      children: [
        Text(widget.email, style: TextStyle(
          color: p.muted, fontSize: 13)),
        const SizedBox(height: 20),
        TextField(
          key: const Key('dev-email-code'),
          controller: _code, maxLength: 12,
          keyboardType: TextInputType.number,
          autofillHints: const [AutofillHints.oneTimeCode],
          decoration: const InputDecoration(
            labelText: 'Code de vérification', counterText: ''),
          onSubmitted: (_) => _verify(),
        ),
        if (_message != null) ...[
          const SizedBox(height: 12),
          Text(_message!, key: const Key('dev-email-feedback'),
            style: TextStyle(color: p.muted, fontSize: 13)),
        ],
        const SizedBox(height: 24),
        FilledButton(
          key: const Key('dev-email-verify'),
          onPressed: _working ? null : _verify,
          child: const Text('Confirmer mon adresse'),
        ),
        TextButton(
          key: const Key('dev-email-resend'),
          onPressed: _working ? null : _resend,
          child: const Text('Renvoyer le code')),
      ],
    );
  }
}

class OriginalPasswordRecoveryForm extends StatefulWidget {
  const OriginalPasswordRecoveryForm({
    super.key, required this.api,
    required this.onFinished, required this.onBack,
  });
  final DevAuthApi api;
  final VoidCallback onFinished;
  final VoidCallback onBack;

  @override
  State<OriginalPasswordRecoveryForm> createState() =>
      _OriginalPasswordRecoveryFormState();
}

class _OriginalPasswordRecoveryFormState
    extends State<OriginalPasswordRecoveryForm> {
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

  Future<void> _submit() async {
    if (_busy) return;
    if (!_requested &&
        (!_email.text.contains('@') || !_email.text.contains('.'))) {
      setState(() => _message = 'Adresse e-mail invalide.');
      return;
    }
    if (_requested &&
        (!RegExp(r'^[0-9]{12}$').hasMatch(_code.text.trim()) ||
         _password.text.length < 12 || _password.text != _confirm.text)) {
      setState(() => _message =
          'Vérifiez le code et la confirmation du mot de passe.');
      return;
    }
    setState(() { _busy = true; _message = null; });
    try {
      if (_requested) {
        await widget.api.resetForgottenPassword(
          email: _email.text.trim(), code: _code.text.trim(),
          newPassword: _password.text,
        );
        if (mounted) widget.onFinished();
      } else {
        await widget.api.requestPasswordReset(_email.text.trim());
        if (mounted) setState(() => _requested = true);
      }
    } on DevApiException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } catch (_) {
      if (mounted) setState(() => _message = 'Connexion indisponible.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return _OriginalSecurityPage(
      title: _requested ? 'Nouveau mot de passe' : 'Récupérer mon compte',
      subtitle: _requested
        ? 'Si votre adresse est reconnue, saisissez le code reçu.'
        : 'Recevez un code de récupération sur votre adresse e-mail.',
      onBack: _busy ? null : widget.onBack,
      children: [
        TextField(
          key: const Key('dev-reset-email'),
          controller: _email,
          enabled: !_busy && !_requested,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Adresse e-mail')),
        if (_requested) ...[
          const SizedBox(height: 13),
          TextField(
            key: const Key('dev-reset-code'),
            controller: _code, maxLength: 12,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Code de récupération', counterText: '')),
          const SizedBox(height: 13),
          TextField(
            key: const Key('dev-reset-password'),
            controller: _password,
            obscureText: true,
            autofillHints: const [AutofillHints.newPassword],
            decoration: const InputDecoration(
              labelText: 'Nouveau mot de passe')),
          const SizedBox(height: 13),
          TextField(
            key: const Key('dev-reset-confirm'),
            controller: _confirm, obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Confirmer le mot de passe')),
        ],
        if (_message != null) ...[
          const SizedBox(height: 13),
          Text(_message!, key: const Key('dev-reset-feedback'),
            style: TextStyle(color: p.muted, fontSize: 13)),
        ],
        const SizedBox(height: 22),
        FilledButton(
          key: const Key('dev-reset-submit'),
          onPressed: _busy ? null : _submit,
          child: Text(_requested
            ? 'Réinitialiser le mot de passe' : 'Recevoir mon code')),
        if (_requested)
          TextButton(
            key: const Key('dev-reset-resend'),
            onPressed: _busy ? null : () async {
              setState(() => _requested = false);
              await _submit();
            },
            child: const Text('Demander un nouveau code')),
      ],
    );
  }
}

class _OriginalSecurityPage extends StatelessWidget {
  const _OriginalSecurityPage({
    required this.title, required this.subtitle,
    required this.children, required this.onBack,
  });
  final String title;
  final String subtitle;
  final VoidCallback? onBack;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('MediSuivi'),
        leading: IconButton(
          tooltip: 'Retour', onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded))),
      body: SafeArea(child: Center(child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(23, 30, 23, 34),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.shield_outlined, size: 40, color: p.forest),
              const SizedBox(height: 22),
              Text(title, style: TextStyle(color: p.ink,
                fontSize: 27, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Text(subtitle, style: TextStyle(
                color: p.muted, fontSize: 14, height: 1.45)),
              const SizedBox(height: 26),
              ...children,
              const SizedBox(height: 22),
              Text('Environnement de test · Données fictives.',
                style: TextStyle(color: p.muted, fontSize: 12)),
            ],
          ),
        ),
      ))),
    );
  }
}
