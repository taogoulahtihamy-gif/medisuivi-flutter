import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../auth/dev_auth_api.dart';

/// Account inputs rendered with MediSuivi's original welcome-page visual
/// language. No widget or layout from the discarded connected dashboard.
class OriginalAccountForm extends StatefulWidget {
  const OriginalAccountForm({
    super.key,
    required this.api,
    required this.isRegister,
    required this.onBack,
    required this.onToggle,
    required this.onAuthenticated,
    required this.onVerificationRequired,
    this.onForgotPassword,
  });

  final DevAuthApi api;
  final bool isRegister;
  final VoidCallback onBack;
  final VoidCallback onToggle;
  final ValueChanged<DevSession> onAuthenticated;
  final ValueChanged<String> onVerificationRequired;
  final VoidCallback? onForgotPassword;

  @override
  State<OriginalAccountForm> createState() => _OriginalAccountFormState();
}

class _OriginalAccountFormState extends State<OriginalAccountForm> {
  final _form = GlobalKey<FormState>();
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _visible = false;
  String? _error;

  @override
  void dispose() {
    for (final controller in [_first, _last, _email, _password]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final account = widget.isRegister
          ? await widget.api.createAccount(
              firstName: _first.text, lastName: _last.text,
              email: _email.text, password: _password.text)
          : await widget.api.signIn(_email.text, _password.text);
      if (mounted) widget.onAuthenticated(account);
    } on DevVerificationRequired catch (error) {
      if (mounted) widget.onVerificationRequired(error.email);
    } on DevApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Connexion indisponible. Réessayez.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final register = widget.isRegister;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: _busy ? null : widget.onBack,
          tooltip: 'Retour',
          icon: const Icon(Icons.arrow_back_rounded)),
        title: const Text('MediSuivi'),
      ),
      body: SafeArea(child: Center(child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 30),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: Form(key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.medical_services_outlined,
                  size: 39, color: p.forest),
                const SizedBox(height: 21),
                Text(register ? 'Créer votre compte' : 'Se connecter',
                  style: TextStyle(color: p.ink,
                    fontSize: 28, height: 1.16,
                    fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Text(register
                  ? 'Vos informations de praticien.'
                  : 'Retrouvez votre espace personnel.',
                  style: TextStyle(color: p.muted,
                    fontSize: 14, height: 1.45)),
                const SizedBox(height: 27),
                if (register) ...[
                  TextFormField(
                    key: const Key('dev-register-first-name'),
                    controller: _first,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Prénom'),
                    validator: (value) => (value?.trim().isEmpty ?? true)
                      ? 'Prénom obligatoire' : null,
                  ),
                  const SizedBox(height: 13),
                  TextFormField(
                    key: const Key('dev-register-last-name'),
                    controller: _last,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Nom'),
                    validator: (value) => (value?.trim().isEmpty ?? true)
                      ? 'Nom obligatoire' : null,
                  ),
                  const SizedBox(height: 13),
                ],
                TextFormField(
                  key: const Key('dev-auth-email'),
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(labelText: 'Adresse e-mail'),
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
                  obscureText: !_visible,
                  autofillHints: [
                    register ? AutofillHints.newPassword
                        : AutofillHints.password,
                  ],
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    suffixIcon: IconButton(
                      tooltip: _visible
                        ? 'Masquer le mot de passe'
                        : 'Afficher le mot de passe',
                      onPressed: () =>
                        setState(() => _visible = !_visible),
                      icon: Icon(_visible
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
                      onPressed: _busy ? null : widget.onForgotPassword,
                      child: const Text('Mot de passe oublié ?'),
                    ),
                  ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Text(_error!, key: const Key('dev-auth-error'),
                    style: TextStyle(color: p.danger, fontSize: 13)),
                ],
                const SizedBox(height: 22),
                SizedBox(
                  height: 49,
                  child: FilledButton(
                    key: const Key('dev-auth-submit'),
                    onPressed: _busy ? null : _submit,
                    child: _busy
                      ? const SizedBox(height: 19, width: 19,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(register
                          ? 'Créer mon compte' : 'Se connecter'),
                  ),
                ),
                const SizedBox(height: 13),
                TextButton(
                  key: const Key('dev-auth-toggle'),
                  onPressed: _busy ? null : widget.onToggle,
                  child: Text(register
                    ? 'Déjà inscrit ? Se connecter'
                    : 'Pas de compte ? Créer un compte'),
                ),
                const SizedBox(height: 25),
                Text('Version de test · Données fictives uniquement.',
                  key: const Key('original-account-test-warning'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: p.muted, fontSize: 12)),
              ],
            ),
          ),
        ),
      ))),
    );
  }
}
