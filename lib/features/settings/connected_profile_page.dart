import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../auth/dev_auth_api.dart';

/// Original MediSuivi Settings profile form, saving ONLY through FastAPI.
class ConnectedProfilePage extends StatefulWidget {
  const ConnectedProfilePage({
    super.key,
    required this.api,
    required this.session,
    required this.onSaved,
    required this.onPasswordChanged,
  });
  final DevAuthApi api;
  final DevSession session;
  final ValueChanged<DevPractitioner> onSaved;
  final VoidCallback onPasswordChanged;

  @override
  State<ConnectedProfilePage> createState() => _ConnectedProfilePageState();
}

class _ConnectedProfilePageState extends State<ConnectedProfilePage> {
  late final TextEditingController _first;
  late final TextEditingController _last;
  late final TextEditingController _phone;
  late final TextEditingController _specialty;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final p = widget.session.practitioner;
    _first = TextEditingController(text: p.firstName);
    _last = TextEditingController(text: p.lastName);
    _phone = TextEditingController(text: p.phone);
    _specialty = TextEditingController(text: p.specialty);
  }

  @override
  void dispose() {
    for (final controller in [_first, _last, _phone, _specialty]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy) return;
    if (_first.text.trim().isEmpty || _last.text.trim().isEmpty) {
      setState(() => _error = 'Prénom et nom obligatoires.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final updated = await widget.api.updateProfile(widget.session,
        firstName: _first.text, lastName: _last.text,
        phone: _phone.text, specialty: _specialty.text);
      if (mounted && widget.session.isActive) {
        widget.onSaved(updated);
        Navigator.of(context).pop();
      }
    } on DevApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Profil indisponible. Réessayez.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _changePassword() async {
    if (_busy) return;
    final current = TextEditingController();
    final next = TextEditingController();
    try {
      final submitted = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Modifier le mot de passe'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              key: const Key('connected-current-password'),
              controller: current, obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mot de passe actuel')),
            const SizedBox(height: 12),
            TextField(
              key: const Key('connected-new-password'),
              controller: next, obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Nouveau mot de passe (12 caractères minimum)')),
          ]),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
            FilledButton(
              key: const Key('connected-save-password'),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Enregistrer')),
          ],
        ),
      );
      if (submitted != true || !mounted) return;
      setState(() {
        _busy = true;
        _error = null;
      });
      await widget.api.changePassword(widget.session,
        currentPassword: current.text, newPassword: next.text);
      if (mounted) widget.onPasswordChanged();
    } on DevApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      // Never store password text in a stateful widget.
      current.clear();
      next.clear();
      current.dispose();
      next.dispose();
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Mon profil')),
      body: SafeArea(child: Center(child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(23, 20, 23, 30),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Identité professionnelle',
                style: TextStyle(color: p.ink, fontSize: 22,
                  fontWeight: FontWeight.w700)),
              const SizedBox(height: 9),
              Text('Les modifications sont enregistrées sur votre compte.',
                style: TextStyle(color: p.muted, fontSize: 13)),
              const SizedBox(height: 23),
              TextField(
                key: const Key('connected-profile-first'),
                controller: _first,
                decoration: const InputDecoration(labelText: 'Prénom')),
              const SizedBox(height: 12),
              TextField(
                key: const Key('connected-profile-last'),
                controller: _last,
                decoration: const InputDecoration(labelText: 'Nom')),
              const SizedBox(height: 12),
              TextField(
                key: const Key('connected-profile-phone'),
                controller: _phone,
                decoration: const InputDecoration(labelText: 'Téléphone')),
              const SizedBox(height: 12),
              TextField(
                key: const Key('connected-profile-specialty'),
                controller: _specialty,
                decoration: const InputDecoration(labelText: 'Spécialité')),
              if (_error != null) ...[
                const SizedBox(height: 13),
                Text(_error!, style: TextStyle(color: p.danger)),
              ],
              const SizedBox(height: 22),
              FilledButton(
                key: const Key('connected-profile-save'),
                onPressed: _busy ? null : _save,
                child: const Text('Enregistrer les modifications')),
              const SizedBox(height: 19),
              OutlinedButton.icon(
                key: const Key('connected-profile-password'),
                onPressed: _busy ? null : _changePassword,
                icon: const Icon(Icons.lock_outline_rounded),
                label: const Text('Modifier le mot de passe')),
            ],
          ),
        ),
      ))),
    );
  }
}
