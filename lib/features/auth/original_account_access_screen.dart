import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'dev_auth_api.dart';

/// Original MediSuivi auth surface, rebuilt for the existing Nocturne Clinique
/// design system. Does NOT import or mount DevConnectedWorkspace.
class OriginalAccountAccessScreen extends StatefulWidget {
  const OriginalAccountAccessScreen({
    super.key,
    required this.api,
    required this.isRegister,
    required this.onBack,
    required this.onToggle,
    required this.onAuthenticated,
    this.onVerificationRequired,
    this.onForgotPassword,
  });

  final DevAuthApi api;
  final bool isRegister;
  final VoidCallback onBack;
  final VoidCallback onToggle;
  final ValueChanged<DevSession> onAuthenticated;
  final ValueChanged<String>? onVerificationRequired;
  final VoidCallback? onForgotPassword;

  @override
  State<OriginalAccountAccessScreen> createState() =>
      _OriginalAccountAccessScreenState();
}

class _OriginalAccountAccessScreenState
    extends State<OriginalAccountAccessScreen> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController();
  final password = TextEditingController();
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final invitation = TextEditingController();
  static const remoteSandbox =
      bool.fromEnvironment('MEDISUIVI_REMOTE_SANDBOX', defaultValue: false);
  bool busy = false;
  bool showPassword = false;
  String? error;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    firstName.dispose();
    lastName.dispose();
    invitation.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (busy || !(form.currentState?.validate() ?? false)) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final session = widget.isRegister
          ? await widget.api.createAccount(
              email: email.text,
              password: password.text,
              firstName: firstName.text,
              lastName: lastName.text,
              inviteCode: remoteSandbox ? invitation.text : '')
          : await widget.api.signIn(email.text, password.text);
      if (mounted) widget.onAuthenticated(session);
    } on DevVerificationRequired catch (exception) {
      if (!mounted) return;
      if (widget.onVerificationRequired != null) {
        widget.onVerificationRequired!(exception.email);
      } else {
        setState(() => error = 'Confirmez votre adresse e-mail.');
      }
    } on DevApiException catch (exception) {
      if (mounted) setState(() => error = exception.message);
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Connexion indisponible. Réessayez.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final registering = widget.isRegister;
    return Scaffold(
      backgroundColor: p.canvas,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 470),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: busy ? null : widget.onBack,
                        icon: const Icon(Icons.arrow_back_rounded, size: 20),
                        label: const Text('Retour'),
                      )),
                  const SizedBox(height: 25),
                  Row(children: [
                    Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                            color: p.tealSoft,
                            borderRadius: BorderRadius.circular(15)),
                        child: Icon(Icons.health_and_safety_outlined,
                            size: 23, color: p.forest)),
                    const SizedBox(width: 13),
                    Expanded(
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('MediSuivi',
                            style: TextStyle(
                                color: p.ink,
                                fontSize: 20,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text('ESPACE PRATICIEN',
                            style: TextStyle(
                                color: p.muted,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2)),
                      ],
                    )),
                  ]),
                  const SizedBox(height: 32),
                  Text(registering ? 'Créer votre compte' : 'Se connecter',
                      style: TextStyle(
                          color: p.ink,
                          fontSize: 27,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -.55)),
                  const SizedBox(height: 8),
                  Text(
                      registering
                          ? 'Renseignez vos informations pour accéder à MediSuivi.'
                          : 'Retrouvez votre espace clinique.',
                      style: TextStyle(
                          color: p.muted, fontSize: 13.5, height: 1.5)),
                  if (remoteSandbox && registering) ...[
                    const SizedBox(height: 10),
                    Text(
                        'Compte de test : utilisez demo-…@example.com et votre invitation.',
                        style: TextStyle(color: p.muted, fontSize: 12)),
                  ],
                  const SizedBox(height: 22),
                  Form(
                    key: form,
                    child: AutofillGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (registering) ...[
                            TextFormField(
                                key: const Key('dev-register-first-name'),
                                controller: firstName,
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                    labelText: 'Prénom',
                                    prefixIcon:
                                        Icon(Icons.person_outline_rounded)),
                                validator: (value) =>
                                    (value?.trim().isEmpty ?? true)
                                        ? 'Prénom obligatoire'
                                        : null),
                            const SizedBox(height: 13),
                            TextFormField(
                                key: const Key('dev-register-last-name'),
                                controller: lastName,
                                textInputAction: TextInputAction.next,
                                textCapitalization: TextCapitalization.words,
                                decoration: const InputDecoration(
                                    labelText: 'Nom',
                                    prefixIcon: Icon(Icons.badge_outlined)),
                                validator: (value) =>
                                    (value?.trim().isEmpty ?? true)
                                        ? 'Nom obligatoire'
                                        : null),
                            const SizedBox(height: 13),
                          ],
                          TextFormField(
                            key: const Key('dev-auth-email'),
                            controller: email,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                                labelText: 'Adresse e-mail',
                                prefixIcon:
                                    Icon(Icons.alternate_email_rounded)),
                            validator: (value) {
                              final text = value?.trim() ?? '';
                              return text.contains('@') && text.contains('.')
                                  ? null
                                  : 'Adresse e-mail invalide';
                            },
                          ),
                          const SizedBox(height: 13),
                          TextFormField(
                            key: const Key('dev-auth-password'),
                            controller: password,
                            obscureText: !showPassword,
                            autocorrect: false,
                            enableSuggestions: false,
                            autofillHints: [
                              registering
                                  ? AutofillHints.newPassword
                                  : AutofillHints.password,
                            ],
                            onFieldSubmitted: (_) => submit(),
                            decoration: InputDecoration(
                              labelText: 'Mot de passe',
                              prefixIcon:
                                  const Icon(Icons.lock_outline_rounded),
                              suffixIcon: IconButton(
                                tooltip: showPassword
                                    ? 'Masquer le mot de passe'
                                    : 'Afficher le mot de passe',
                                icon: Icon(showPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined),
                                onPressed: () => setState(
                                    () => showPassword = !showPassword),
                              ),
                            ),
                            validator: (value) =>
                                (value?.length ?? 0) < (registering ? 12 : 1)
                                    ? registering
                                        ? '12 caractères minimum'
                                        : 'Mot de passe obligatoire'
                                    : null,
                          ),
                          if (registering && remoteSandbox) ...[
                            const SizedBox(height: 13),
                            TextFormField(
                              key: const Key('sandbox-invite-code'),
                              controller: invitation,
                              obscureText: true,
                              enableSuggestions: false,
                              autocorrect: false,
                              decoration: const InputDecoration(
                                  labelText: 'Code d’invitation',
                                  prefixIcon: Icon(Icons.key_outlined)),
                              validator: (value) =>
                                  (value?.trim().length ?? 0) < 32
                                      ? 'Code d’invitation requis'
                                      : null,
                            ),
                          ],
                          if (!registering &&
                              widget.onForgotPassword != null &&
                              !remoteSandbox)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                  key: const Key('dev-auth-forgot-password'),
                                  onPressed:
                                      busy ? null : widget.onForgotPassword,
                                  child: const Text('Mot de passe oublié ?')),
                            ),
                          if (error != null) ...[
                            const SizedBox(height: 13),
                            Semantics(
                                liveRegion: true,
                                child: Text(error!,
                                    key: const Key('dev-auth-error'),
                                    style: TextStyle(
                                        color: p.danger, fontSize: 13))),
                          ],
                          const SizedBox(height: 20),
                          ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 48),
                            child: FilledButton(
                              key: const Key('dev-auth-submit'),
                              onPressed: busy ? null : submit,
                              child: busy
                                  ? const SizedBox(
                                      width: 19,
                                      height: 19,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))
                                  : Text(registering
                                      ? 'Créer mon compte'
                                      : 'Se connecter'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 13),
                  TextButton(
                    key: const Key('dev-auth-toggle'),
                    onPressed: busy ? null : widget.onToggle,
                    child: Text(registering
                        ? 'Déjà inscrit ? Se connecter'
                        : 'Créer un compte'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
