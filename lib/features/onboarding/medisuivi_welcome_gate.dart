import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/theme.dart';

/// Prévisualisation mémoire du profil, PAS un compte authentifié.
/// Aucun mot de passe, jeton, document patient ou photo n'est envoyé au réseau.
class PractitionerPreview extends ChangeNotifier {
  String firstName = '';
  String lastName = '';
  String email = '';
  String phone = '';
  String specialty = '';
  Uint8List? photo;

  String get displayName =>
      [firstName.trim(), lastName.trim()].where((value) => value.isNotEmpty).join(' ');

  void update({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String specialty,
    Uint8List? photo,
  }) {
    this.firstName = firstName.trim();
    this.lastName = lastName.trim();
    this.email = email.trim();
    this.phone = phone.trim();
    this.specialty = specialty.trim();
    this.photo = photo;
    notifyListeners();
  }
}

class PractitionerPreviewScope extends InheritedNotifier<PractitionerPreview> {
  const PractitionerPreviewScope({
    super.key,
    required PractitionerPreview controller,
    required super.child,
  }) : super(notifier: controller);

  static PractitionerPreview? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PractitionerPreviewScope>()?.notifier;
}

/// Le parcours démarre seulement APRÈS l'initialisation du stockage mobile.
/// Le mode local ne remplace jamais l'authentification de compte.
class MediSuiviWelcomeGate extends StatefulWidget {
  const MediSuiviWelcomeGate({
    super.key,
    required this.child,
    required this.isWebDemo,
  });

  final Widget child;
  final bool isWebDemo;

  @override
  State<MediSuiviWelcomeGate> createState() => _MediSuiviWelcomeGateState();
}

enum _EntryStep { splash, introduction, access, signIn, profile, workspace }

class _MediSuiviWelcomeGateState extends State<MediSuiviWelcomeGate> {
  final PractitionerPreview _practitioner = PractitionerPreview();
  _EntryStep _step = _EntryStep.splash;
  Timer? _splashTimer;

  @override
  void initState() {
    super.initState();
    _splashTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted && _step == _EntryStep.splash) {
        setState(() => _step = _EntryStep.introduction);
      }
    });
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    _practitioner.dispose();
    super.dispose();
  }

  void _go(_EntryStep step) => setState(() => _step = step);

  @override
  Widget build(BuildContext context) => PractitionerPreviewScope(
    controller: _practitioner,
    child: AnimatedSwitcher(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero : const Duration(milliseconds: 330),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: switch (_step) {
        _EntryStep.splash => const _IntroSplash(key: ValueKey('welcome-splash')),
        _EntryStep.introduction => _Introduction(
          key: const ValueKey('welcome-introduction'),
          onFinished: () => _go(_EntryStep.access),
        ),
        _EntryStep.access => _AccessChoice(
          key: const ValueKey('welcome-access'),
          isWebDemo: widget.isWebDemo,
          onCreate: () => _go(_EntryStep.profile),
          onSignIn: () => _go(_EntryStep.signIn),
          onLocalAccess: () => _go(_EntryStep.workspace),
        ),
        _EntryStep.signIn => _SignInPending(
          key: const ValueKey('welcome-signin'),
          isWebDemo: widget.isWebDemo,
          onBack: () => _go(_EntryStep.access),
          onLocalAccess: () => _go(_EntryStep.workspace),
        ),
        _EntryStep.profile => PractitionerPreviewForm(
          key: const ValueKey('welcome-profile'),
          controller: _practitioner,
          isWebDemo: widget.isWebDemo,
          onBack: () => _go(_EntryStep.access),
          onSaved: () => _go(_EntryStep.workspace),
        ),
        _EntryStep.workspace => KeyedSubtree(
          key: const ValueKey('welcome-workspace'),
          child: widget.child,
        ),
      },
    ),
  );
}

class _IntroSplash extends StatelessWidget {
  const _IntroSplash({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 78, height: 78,
                  decoration: BoxDecoration(
                    color: palette.tealSoft,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Icon(Icons.medical_services_outlined,
                    size: 39, color: palette.forest),
                ),
                const SizedBox(height: 22),
                Text('MediSuivi', key: const Key('welcome-brand'),
                  style: TextStyle(color: palette.ink, fontSize: 28,
                    fontWeight: FontWeight.w700, letterSpacing: -.8)),
                const SizedBox(height: 8),
                Text('Votre espace de suivi clinique',
                  style: TextStyle(color: palette.muted, fontSize: 13)),
                const SizedBox(height: 38),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: reduced
                      ? Duration.zero : const Duration(milliseconds: 1050),
                  curve: Curves.easeInOutCubic,
                  builder: (context, progress, _) => ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: LinearProgressIndicator(
                      key: const Key('welcome-progress'),
                      value: progress,
                      minHeight: 4,
                      backgroundColor: palette.border,
                      valueColor: AlwaysStoppedAnimation<Color>(palette.forest),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _Introduction extends StatefulWidget {
  const _Introduction({super.key, required this.onFinished});
  final VoidCallback onFinished;

  @override
  State<_Introduction> createState() => _IntroductionState();
}

class _IntroductionState extends State<_Introduction> {
  final PageController _pages = PageController();
  int _index = 0;

  static const _slides = <(IconData, String, String)>[
    (Icons.folder_shared_outlined, 'Chaque dossier, à sa place.',
      'Retrouvez vos patients et leur historique clinique dans un seul espace.'),
    (Icons.monitor_heart_outlined, 'Suivre avec précision.',
      'Consultations, bilans et rendez-vous organisés autour de chaque patient.'),
    (Icons.verified_user_outlined, 'Un espace personnel.',
      'Vos dossiers restent sur cet appareil tant que la synchronisation sécurisée n’est pas disponible.'),
  ];

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 510),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 30),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Icon(Icons.medical_services_outlined, color: p.forest, size: 23),
              const SizedBox(width: 9),
              Expanded(child: Text('MediSuivi',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(color: p.ink,
                  fontSize: 17, fontWeight: FontWeight.w700))),
              TextButton(
                key: const Key('onboarding-skip'),
                onPressed: widget.onFinished,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10)),
                child: const Text('Passer')),
            ]),
            const SizedBox(height: 20),
            Expanded(child: PageView.builder(
              key: const Key('onboarding-pages'),
              controller: _pages,
              itemCount: _slides.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, index) {
                final slide = _slides[index];
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(
                      height: 205, width: 205,
                      decoration: BoxDecoration(
                        color: p.tealSoft,
                        borderRadius: BorderRadius.circular(55),
                        border: Border.all(color: p.border),
                      ),
                      child: Icon(slide.$1, size: 94, color: p.forest),
                    )),
                    const SizedBox(height: 42),
                    Text(slide.$2, style: TextStyle(
                      fontSize: 27, height: 1.15, letterSpacing: -.5,
                      fontWeight: FontWeight.w700, color: p.ink)),
                    const SizedBox(height: 13),
                    Text(slide.$3, style: TextStyle(
                      fontSize: 15, height: 1.5, color: p.muted)),
                  ],
                );
              },
            )),
            Row(children: [
              for (var i = 0; i < _slides.length; i++) ...[
                AnimatedContainer(
                  key: Key('onboarding-dot-$i'),
                  duration: reduced ? Duration.zero : const Duration(milliseconds: 260),
                  width: i == _index ? 26 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: i == _index ? p.forest : p.border,
                    borderRadius: BorderRadius.circular(6)),
                ),
                const SizedBox(width: 6),
              ],
              const Spacer(),
              Text('${_index + 1} / ${_slides.length}',
                style: TextStyle(color: p.muted, fontSize: 12)),
            ]),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('onboarding-next'),
              onPressed: () {
                if (_index == _slides.length - 1) {
                  widget.onFinished();
                } else {
                  _pages.nextPage(
                    duration: reduced ? Duration.zero : const Duration(milliseconds: 360),
                    curve: Curves.easeInOutCubic,
                  );
                }
              },
              child: Text(_index == _slides.length - 1 ? 'Continuer' : 'Suivant'),
            ),
          ]),
        ),
      ))),
    );
  }
}

class _AccessChoice extends StatelessWidget {
  const _AccessChoice({super.key, required this.isWebDemo,
    required this.onCreate, required this.onSignIn,
    required this.onLocalAccess});
  final bool isWebDemo;
  final VoidCallback onCreate;
  final VoidCallback onSignIn;
  final VoidCallback onLocalAccess;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return _WelcomePage(
      title: 'Un espace clinique personnel.',
      subtitle: 'Un compte par praticien. Vos patients ne seront pas partagés entre plusieurs comptes.',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: p.surface, borderRadius: BorderRadius.circular(22),
            border: Border.all(color: p.border)),
          child: Row(children: [
            Icon(Icons.person_outline_rounded, color: p.forest, size: 30),
            const SizedBox(width: 13),
            Expanded(child: Text(
              'Identité, coordonnées et photo du praticien.',
              style: TextStyle(color: p.ink, fontSize: 14))),
          ]),
        ),
        const SizedBox(height: 24),
        FilledButton(key: const Key('welcome-create'),
          onPressed: onCreate, child: const Text('Créer un compte')),
        const SizedBox(height: 12),
        OutlinedButton(key: const Key('welcome-login'),
          onPressed: onSignIn, child: const Text('Se connecter')),
        const SizedBox(height: 18),
        TextButton(key: const Key('welcome-demo'),
          onPressed: onLocalAccess,
          child: Text(isWebDemo ? 'Explorer la démonstration' : 'Accéder aux dossiers locaux')),
        const SizedBox(height: 13),
        Text(isWebDemo
          ? 'Démo Web : patients fictifs, aucune création de compte.'
          : 'Accès local sur cet appareil seulement. Aucun compte ni synchronisation distante.',
          textAlign: TextAlign.center, style: TextStyle(
            color: p.muted, height: 1.4, fontSize: 12)),
      ]),
    );
  }
}

class _SignInPending extends StatelessWidget {
  const _SignInPending({super.key, required this.isWebDemo,
    required this.onBack, required this.onLocalAccess});
  final bool isWebDemo;
  final VoidCallback onBack;
  final VoidCallback onLocalAccess;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return _WelcomePage(
      title: 'Se connecter',
      subtitle: 'La connexion par compte nécessite un serveur sécurisé, encore en développement.',
      onBack: onBack,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Icon(Icons.lock_outline_rounded, size: 52, color: p.forest),
        const SizedBox(height: 18),
        Text('La connexion sera disponible après activation des comptes praticiens.',
          style: TextStyle(color: p.ink, fontSize: 14, height: 1.45)),
        const SizedBox(height: 10),
        Text('Aucun mot de passe n’est demandé ni conservé dans cette version.',
          style: TextStyle(color: p.muted, fontSize: 12)),
        const SizedBox(height: 25),
        OutlinedButton(
          key: const Key('login-local-access'),
          onPressed: onLocalAccess,
          child: Text(isWebDemo
            ? 'Explorer la démonstration' : 'Accéder aux dossiers locaux'),
        ),
      ]),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.title, required this.subtitle,
    required this.child, this.onBack});
  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Scaffold(
      appBar: onBack == null ? null : AppBar(
        leading: IconButton(
          tooltip: 'Retour', onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded))),
      body: SafeArea(child: Center(child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(
              width: 52, height: 52, alignment: Alignment.centerLeft,
              child: Icon(Icons.medical_services_outlined,
                size: 40, color: p.forest)),
            const SizedBox(height: 22),
            Text(title, style: TextStyle(color: p.ink, fontSize: 28,
              height: 1.16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 13),
            Text(subtitle, style: TextStyle(color: p.muted,
              fontSize: 14, height: 1.45)),
            const SizedBox(height: 32),
            child,
          ]),
        ),
      ))),
    );
  }
}

/// Uniquement un aperçu non persistant : pas d'inscription fictive.
class PractitionerPreviewForm extends StatefulWidget {
  const PractitionerPreviewForm({
    super.key,
    required this.controller,
    required this.onSaved,
    required this.isWebDemo,
    this.onBack,
  });

  final PractitionerPreview controller;
  final VoidCallback onSaved;
  final VoidCallback? onBack;
  final bool isWebDemo;

  @override
  State<PractitionerPreviewForm> createState() => _PractitionerPreviewFormState();
}

class _PractitionerPreviewFormState extends State<PractitionerPreviewForm> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _first;
  late final TextEditingController _last;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _specialty;
  Uint8List? _photo;
  bool _picking = false;

  @override
  void initState() {
    super.initState();
    _first = TextEditingController(text: widget.controller.firstName);
    _last = TextEditingController(text: widget.controller.lastName);
    _email = TextEditingController(text: widget.controller.email);
    _phone = TextEditingController(text: widget.controller.phone);
    _specialty = TextEditingController(text: widget.controller.specialty);
    _photo = widget.controller.photo;
  }

  @override
  void dispose() {
    for (final c in [_first, _last, _email, _phone, _specialty]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 512, maxHeight: 512,
        imageQuality: 75, requestFullMetadata: false);
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (bytes.lengthInBytes > 2 * 1024 * 1024) {
        throw const FormatException('Photo trop volumineuse.');
      }
      if (mounted) setState(() => _photo = bytes);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Impossible de charger cette photo. Choisissez une autre image.')));
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _save() {
    if (!(_form.currentState?.validate() ?? false)) return;
    widget.controller.update(
      firstName: _first.text, lastName: _last.text,
      email: _email.text, phone: _phone.text,
      specialty: _specialty.text, photo: _photo,
    );
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Scaffold(
      appBar: widget.onBack == null ? AppBar(title: const Text('Profil du praticien'))
        : AppBar(leading: IconButton(
          tooltip: 'Retour', onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back_rounded)),
          title: const Text('Votre profil')),
      body: SafeArea(child: Center(child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 36),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 510),
          child: Form(
            key: _form,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('Votre identité professionnelle', style: TextStyle(
                color: p.ink, fontSize: 23, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('Prévisualisation locale uniquement. Aucun compte n’est créé.',
                style: TextStyle(color: p.muted, fontSize: 12.5, height: 1.4)),
              const SizedBox(height: 21),
              Center(child: Column(children: [
                CircleAvatar(
                  key: const Key('practitioner-photo-preview'),
                  radius: 42,
                  backgroundColor: p.tealSoft,
                  foregroundImage: _photo == null ? null : MemoryImage(_photo!),
                  child: _photo == null
                    ? Icon(Icons.person_rounded, size: 39, color: p.forest) : null,
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  key: const Key('practitioner-pick-photo'),
                  onPressed: _picking ? null : _pickPhoto,
                  icon: const Icon(Icons.add_a_photo_outlined, size: 19),
                  label: const Text('Ajouter une photo'),
                ),
                if (_photo != null) TextButton(
                  key: const Key('practitioner-remove-photo'),
                  onPressed: () => setState(() => _photo = null),
                  child: const Text('Retirer la photo')),
              ])),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('practitioner-first-name'),
                controller: _first, textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Prénom *'),
                validator: (v) => (v?.trim().length ?? 0) < 2
                  ? 'Indiquez votre prénom.' : null),
              const SizedBox(height: 13),
              TextFormField(
                key: const Key('practitioner-last-name'),
                controller: _last, textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nom *'),
                validator: (v) => (v?.trim().length ?? 0) < 2
                  ? 'Indiquez votre nom.' : null),
              const SizedBox(height: 13),
              TextFormField(
                controller: _email, keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Adresse e-mail'),
                validator: (v) => v != null && v.trim().isNotEmpty &&
                    !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())
                  ? 'Adresse e-mail invalide.' : null),
              const SizedBox(height: 13),
              TextFormField(
                controller: _phone, keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Téléphone')),
              const SizedBox(height: 13),
              TextFormField(
                controller: _specialty,
                decoration: const InputDecoration(labelText: 'Spécialité (facultatif)')),
              const SizedBox(height: 22),
              FilledButton(
                key: const Key('practitioner-save-preview'),
                onPressed: _save,
                child: Text(widget.isWebDemo
                  ? 'Voir mon espace de démonstration'
                  : 'Continuer vers mon espace local')),
              const SizedBox(height: 12),
              Text(widget.isWebDemo
                ? 'Ces informations et votre photo restent en mémoire jusqu’à la fermeture.'
                : 'Ces informations ne constituent pas un compte et ne sont pas synchronisées.',
                textAlign: TextAlign.center,
                style: TextStyle(color: p.muted, fontSize: 12, height: 1.4)),
            ]),
          ),
        ),
      ))),
    );
  }
}
