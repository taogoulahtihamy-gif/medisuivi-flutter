import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/theme.dart';
import 'dev_auth_api.dart';

/// Private development profile. No access to the shared demo clinical store.
class DevProfileEditor extends StatefulWidget {
  const DevProfileEditor({
    super.key,
    required this.api,
    required this.session,
    required this.initial,
    required this.avatar,
    required this.onChanged,
  });

  final DevAuthApi api;
  final DevSession session;
  final DevPractitioner initial;
  final Uint8List? avatar;
  final void Function(DevPractitioner, Uint8List?) onChanged;

  @override
  State<DevProfileEditor> createState() => _DevProfileEditorState();
}

class _DevProfileEditorState extends State<DevProfileEditor> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _first;
  late final TextEditingController _last;
  late final TextEditingController _phone;
  late final TextEditingController _specialty;
  Uint8List? _avatar;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _first = TextEditingController(text: widget.initial.firstName);
    _last = TextEditingController(text: widget.initial.lastName);
    _phone = TextEditingController(text: widget.initial.phone);
    _specialty = TextEditingController(text: widget.initial.specialty);
    _avatar = widget.avatar;
  }

  @override
  void dispose() {
    for (final controller in [_first, _last, _phone, _specialty]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _imageMime(Uint8List bytes) {
    if (bytes.lengthInBytes < 12) return null;
    if (bytes[0] == 0xFF && bytes[1] == 0xD8) return 'image/jpeg';
    if (bytes[0] == 0x89 && bytes[1] == 0x50 &&
        bytes[2] == 0x4E && bytes[3] == 0x47) return 'image/png';
    if (bytes[0] == 0x52 && bytes[1] == 0x49 &&
        bytes[8] == 0x57 && bytes[9] == 0x45) return 'image/webp';
    return null;
  }

  Future<void> _pickPhoto() async {
    if (_busy) return;
    try {
      final selected = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 512, maxHeight: 512,
        imageQuality: 82, requestFullMetadata: false,
      );
      if (selected == null || !mounted) return;
      final bytes = await selected.readAsBytes();
      final mime = _imageMime(bytes);
      if (mime == null || bytes.lengthInBytes > 2 * 1024 * 1024) {
        throw const DevApiException(
          'Photo invalide ou trop volumineuse. Maximum 2 Mo.');
      }
      setState(() { _busy = true; _error = null; });
      final updated = await widget.api.uploadAvatar(
        widget.session, bytes, mimeType: mime);
      if (!mounted) return;
      final normalized = await widget.api.loadAvatar(widget.session);
      if (!mounted) return;
      setState(() => _avatar = normalized);
      widget.onChanged(updated, normalized);
    } catch (_) {
      if (mounted) {
        setState(() => _error =
          'Photo non enregistrée. Choisissez une image JPEG, PNG ou WebP.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _removePhoto() async {
    if (_busy) return;
    setState(() { _busy = true; _error = null; });
    try {
      await widget.api.removeAvatar(widget.session);
      if (!mounted) return;
      setState(() => _avatar = null);
      widget.onChanged(DevPractitioner(
        id: widget.initial.id, email: widget.initial.email,
        firstName: _first.text.trim(), lastName: _last.text.trim(),
        phone: _phone.text.trim(), specialty: _specialty.text.trim(),
        hasAvatar: false,
      ), null);
    } on DevApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (_busy || !(_form.currentState?.validate() ?? false)) return;
    setState(() { _busy = true; _error = null; });
    try {
      final updated = await widget.api.updateProfile(widget.session,
        firstName: _first.text, lastName: _last.text,
        phone: _phone.text, specialty: _specialty.text);
      if (!mounted) return;
      widget.onChanged(updated, _avatar);
      Navigator.of(context).pop();
    } on DevApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon profil'),
        leading: IconButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Retour',
        ),
      ),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: Column(children: [
                  CircleAvatar(
                    key: const Key('dev-profile-photo'),
                    radius: 49,
                    backgroundColor: p.tealSoft,
                    foregroundImage: _avatar == null
                      ? null : MemoryImage(_avatar!),
                    child: _avatar == null
                      ? Icon(Icons.person_rounded, color: p.forest, size: 43)
                      : null,
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    key: const Key('dev-profile-upload'),
                    onPressed: _busy ? null : _pickPhoto,
                    icon: const Icon(Icons.camera_alt_outlined, size: 19),
                    label: const Text('Modifier la photo'),
                  ),
                  if (_avatar != null)
                    TextButton(
                      key: const Key('dev-profile-delete-photo'),
                      onPressed: _busy ? null : _removePhoto,
                      child: const Text('Retirer la photo'),
                    ),
                ])),
                const SizedBox(height: 15),
                Text(widget.initial.email, textAlign: TextAlign.center,
                  style: TextStyle(color: p.muted, fontSize: 13)),
                const SizedBox(height: 30),
                Text('Informations professionnelles',
                  style: TextStyle(color: p.ink, fontSize: 18,
                    fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('dev-profile-first'),
                  controller: _first,
                  decoration: const InputDecoration(labelText: 'Prénom'),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) =>
                    value == null || value.trim().isEmpty
                      ? 'Champ obligatoire' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('dev-profile-last'),
                  controller: _last,
                  decoration: const InputDecoration(labelText: 'Nom'),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) =>
                    value == null || value.trim().isEmpty
                      ? 'Champ obligatoire' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('dev-profile-phone'),
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Téléphone', hintText: '+221 ...'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('dev-profile-specialty'),
                  controller: _specialty,
                  decoration: const InputDecoration(
                    labelText: 'Spécialité', hintText: 'Ex. Médecine générale'),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 15),
                  Text(_error!, style: TextStyle(color: p.danger)),
                ],
                const SizedBox(height: 27),
                FilledButton(
                  key: const Key('dev-profile-save'),
                  onPressed: _busy ? null : _save,
                  child: Text(_busy
                    ? 'Enregistrement…' : 'Enregistrer les modifications'),
                ),
                const SizedBox(height: 18),
                Text('Profil personnel de développement. '
                  'N’utilisez pas de données médicales réelles.',
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
