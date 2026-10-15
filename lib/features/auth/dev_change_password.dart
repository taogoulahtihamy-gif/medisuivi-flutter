import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'dev_auth_api.dart';

/// Authenticated password update for the synthetic development environment.
/// A successful update revokes all device sessions on the backend.
class DevChangePasswordScreen extends StatefulWidget {
  const DevChangePasswordScreen({
    super.key,
    required this.api,
    required this.session,
    required this.onPasswordChanged,
  });

  final DevAuthApi api;
  final DevSession session;
  final VoidCallback onPasswordChanged;

  @override
  State<DevChangePasswordScreen> createState() =>
      _DevChangePasswordScreenState();
}

class _DevChangePasswordScreenState extends State<DevChangePasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  bool _visible = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.api.changePassword(widget.session,
          currentPassword: _current.text, newPassword: _next.text);
      if (mounted) widget.onPasswordChanged();
    } on DevApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() =>
            _error = 'Impossible de modifier le mot de passe. Réessayez.');
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
        title: const Text('Sécurité du compte'),
        leading: IconButton(
          tooltip: 'Retour',
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
          child: Center(
              child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 38),
          child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.lock_reset_rounded, color: p.forest, size: 35),
                  const SizedBox(height: 14),
                  Text('Modifier le mot de passe',
                      style: TextStyle(
                          color: p.ink,
                          fontSize: 23,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 9),
                  Text(
                      'Le nouveau mot de passe doit comporter au moins '
                      '12 caractères. Tous vos appareils seront déconnectés.',
                      style: TextStyle(
                          color: p.muted, fontSize: 13.5, height: 1.45)),
                  const SizedBox(height: 26),
                  TextFormField(
                    key: const Key('dev-password-current'),
                    controller: _current,
                    obscureText: !_visible,
                    autofillHints: const [AutofillHints.password],
                    decoration:
                        const InputDecoration(labelText: 'Mot de passe actuel'),
                    validator: (text) => (text?.isEmpty ?? true)
                        ? 'Mot de passe actuel obligatoire'
                        : null,
                  ),
                  const SizedBox(height: 13),
                  TextFormField(
                    key: const Key('dev-password-new'),
                    controller: _next,
                    obscureText: !_visible,
                    autofillHints: const [AutofillHints.newPassword],
                    decoration: const InputDecoration(
                        labelText: 'Nouveau mot de passe'),
                    validator: (text) {
                      if ((text?.length ?? 0) < 12) {
                        return '12 caractères minimum';
                      }
                      if (text == _current.text) {
                        return 'Choisissez un mot de passe différent';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 13),
                  TextFormField(
                    key: const Key('dev-password-confirm'),
                    controller: _confirm,
                    obscureText: !_visible,
                    autofillHints: const [AutofillHints.newPassword],
                    decoration: const InputDecoration(
                        labelText: 'Confirmer le nouveau mot de passe'),
                    validator: (text) => text == _next.text
                        ? null
                        : 'Les deux mots de passe sont différents',
                  ),
                  const SizedBox(height: 10),
                  CheckboxListTile(
                    key: const Key('dev-password-visibility'),
                    contentPadding: EdgeInsets.zero,
                    title: Text('Afficher les mots de passe',
                        style: TextStyle(color: p.muted, fontSize: 13)),
                    value: _visible,
                    onChanged: (value) =>
                        setState(() => _visible = value ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(_error!,
                        key: const Key('dev-password-error'),
                        style: TextStyle(color: p.danger, fontSize: 13)),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const Key('dev-password-submit'),
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox(
                            width: 19,
                            height: 19,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Modifier et déconnecter mes appareils'),
                  ),
                ],
              )),
        ),
      ))),
    );
  }
}
