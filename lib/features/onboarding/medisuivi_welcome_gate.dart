import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/theme.dart';
import '../../app/design_tokens.dart';
import '../auth/dev_auth_api.dart';
import '../auth/dev_auth_screens.dart';
import '../auth/dev_email_flows.dart';

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
    this.developmentAuthApi,
  });

  final Widget child;
  final bool isWebDemo;
  /// Optional injectable test API; otherwise enabled only by dart-define.
  final DevAuthApi? developmentAuthApi;

  @override
  State<MediSuiviWelcomeGate> createState() => _MediSuiviWelcomeGateState();
}

enum _EntryStep {
  splash, restoring, introduction, access, signIn, register, verifyEmail,
  recoverPassword, profile, workspace, authenticated
}

class _MediSuiviWelcomeGateState extends State<MediSuiviWelcomeGate> {
  final PractitionerPreview _practitioner = PractitionerPreview();
  late final DevAuthApi? _authApi;
  DevSession? _authenticatedSession;
  String? _emailPendingVerification;
  _EntryStep _step = _EntryStep.splash;
  Timer? _splashTimer;
  bool _splashElapsed = false;
  bool _resumeDone = false;
  DevSession? _resumeSession;
  String? _resumeError;
  int _resumeAttempt = 0;

  void _finishSplash() {
    if (!mounted || !_splashElapsed || !_resumeDone) return;
    setState(() {
      if (_resumeSession != null) {
        _authenticatedSession = _resumeSession;
        _resumeSession = null;
        _step = _EntryStep.authenticated;
      } else if (_resumeError != null) {
        _step = _EntryStep.restoring;
      } else {
        _step = _EntryStep.introduction;
      }
    });
  }

  Future<void> _restoreAccount() async {
    final token = ++_resumeAttempt;
    _resumeDone = false;
    _resumeError = null;
    try {
      final session = await _authApi?.restoreSavedSession();
      if (!mounted || token != _resumeAttempt) {
        session?.clear();
        return;
      }
      _resumeSession = session;
    } on DevApiException catch (error) {
      if (!mounted || token != _resumeAttempt) return;
      _resumeError = error.message;
    } catch (_) {
      if (!mounted || token != _resumeAttempt) return;
      _resumeError = 'Restauration indisponible. Réessayez.';
    } finally {
      if (mounted && token == _resumeAttempt) {
        _resumeDone = true;
        _finishSplash();
      }
    }
  }

  Future<void> _chooseAnotherAccount() async {
    ++_resumeAttempt;
    try {
      await _authApi?.forgetSavedSession();
      if (mounted) setState(() {
        _resumeSession?.clear();
        _resumeSession = null;
        _resumeError = null;
        _step = _EntryStep.signIn;
      });
    } on DevApiException catch (error) {
      if (mounted) setState(() => _resumeError = error.message);
    }
  }

  @override
  void initState() {
    super.initState();
    _authApi = widget.developmentAuthApi ?? DevAuthApi.fromEnvironment();
    if (_authApi?.canRestoreSession == true) {
      unawaited(_restoreAccount());
    } else {
      _resumeDone = true;
    }
    _splashTimer = Timer(const Duration(milliseconds: 2800), () {
      if (!mounted || _step != _EntryStep.splash) return;
      _splashElapsed = true;
      if (_resumeDone) {
        _finishSplash();
      } else {
        setState(() => _step = _EntryStep.restoring);
      }
    });
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    ++_resumeAttempt;
    _resumeSession?.clear();
    _practitioner.dispose();
    // The API owns no persisted token; close only client created by this gate.
    if (widget.developmentAuthApi == null) _authApi?.close();
    _authenticatedSession = null;
    super.dispose();
  }

  void _go(_EntryStep step) => setState(() => _step = step);

  void _verifyEmail(String email) => setState(() {
    _emailPendingVerification = email;
    _step = _EntryStep.verifyEmail;
  });

  void _onAuthenticated(DevSession session) => setState(() {
    _resumeAttempt++;
    _authenticatedSession?.clear();
    _authenticatedSession = session;
    _step = _EntryStep.authenticated;
  });

  void _onSignedOut() => setState(() {
    _authenticatedSession?.clear();
    _authenticatedSession = null;
    _step = _EntryStep.access;
  });

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
        _EntryStep.restoring => Scaffold(
          key: const ValueKey('dev-session-restoring'),
          body: SafeArea(child: Center(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_clock_outlined, size: 41),
                const SizedBox(height: 22),
                Text(_resumeError == null
                    ? 'Vérification de votre session…'
                    : 'Session indisponible',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 21, fontWeight: FontWeight.w700)),
                const SizedBox(height: 13),
                Text(_resumeError ??
                  'Connexion sécurisée au serveur en cours.',
                  textAlign: TextAlign.center),
                const SizedBox(height: 26),
                if (_resumeError == null)
                  const CircularProgressIndicator()
                else ...[
                  FilledButton(
                    key: const Key('dev-resume-retry'),
                    onPressed: () {
                      setState(() => _resumeError = null);
                      unawaited(_restoreAccount());
                    },
                    child: const Text('Réessayer'),
                  ),
                  TextButton(
                    key: const Key('dev-resume-other-account'),
                    onPressed: _chooseAnotherAccount,
                    child: const Text('Utiliser un autre compte'),
                  ),
                ],
              ],
            ),
          ))),
        ),
        _EntryStep.introduction => _Introduction(
          key: const ValueKey('welcome-introduction'),
          onFinished: () => _go(_EntryStep.access),
        ),
        _EntryStep.access => _AccessChoice(
          key: const ValueKey('welcome-access'),
          isWebDemo: widget.isWebDemo,
          onCreate: () => _go(
            _authApi == null ? _EntryStep.profile : _EntryStep.register),
          onSignIn: () => _go(_EntryStep.signIn),
          onLocalAccess: () => _go(_EntryStep.workspace),
        ),
        _EntryStep.signIn => _authApi == null
          ? _SignInPending(
              key: const ValueKey('welcome-signin'),
              isWebDemo: widget.isWebDemo,
              onBack: () => _go(_EntryStep.access),
              onLocalAccess: () => _go(_EntryStep.workspace),
            )
          : DevAuthScreen(
              key: const ValueKey('dev-signin'),
              api: _authApi, isRegister: false,
              onBack: () => _go(_EntryStep.access),
              onToggle: () => _go(_EntryStep.register),
              onVerificationRequired: _verifyEmail,
              onForgotPassword: () => _go(_EntryStep.recoverPassword),
              onAuthenticated: _onAuthenticated,
            ),
        _EntryStep.register => DevAuthScreen(
          key: const ValueKey('dev-register'),
          api: _authApi!, isRegister: true,
          onBack: () => _go(_EntryStep.access),
          onToggle: () => _go(_EntryStep.signIn),
          onVerificationRequired: _verifyEmail,
          onAuthenticated: _onAuthenticated,
        ),
        _EntryStep.verifyEmail => DevEmailVerificationScreen(
          key: const ValueKey('dev-email-verification'),
          api: _authApi!,
          email: _emailPendingVerification!,
          onVerified: () => _go(_EntryStep.signIn),
          onBack: () => _go(_EntryStep.signIn),
        ),
        _EntryStep.recoverPassword => DevPasswordRecoveryScreen(
          key: const ValueKey('dev-password-recovery'),
          api: _authApi!,
          onFinished: () => _go(_EntryStep.signIn),
          onBack: () => _go(_EntryStep.signIn),
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
        _EntryStep.authenticated => DevConnectedWorkspace(
          key: const ValueKey('dev-authenticated-workspace'),
          api: _authApi!,
          session: _authenticatedSession!,
          onSignedOut: _onSignedOut,
        ),
      },
    ),
  );
}

// Portrait clinique déjà embarqué dans MediSuivi : aucun appel réseau.
/// Photographies cliniques haute résolution embarquées.
abstract final class _WelcomePhotos {
  // Images intégrées en WebP HD : aucun accès réseau pendant l'onboarding.
  static const splash = 'assets/images/onboarding/splash.webp';
  static const records = 'assets/images/onboarding/records.webp';
  static const followup = 'assets/images/onboarding/followup.webp';
  static const privacy = 'assets/images/onboarding/privacy.webp';
  static const access = 'assets/images/onboarding/access.webp';
}

class _WelcomePhoto extends StatelessWidget {
  const _WelcomePhoto({
    required this.imageUrl,
    required this.imageKey,
    this.alignment = Alignment.topCenter,
  });
  final String imageUrl;
  final Key imageKey;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) => Image.asset(
    imageUrl,
    key: imageKey,
    fit: BoxFit.cover,
    alignment: alignment,
    filterQuality: FilterQuality.high,
    excludeFromSemantics: true,
    errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF12271F)),
  );
}

class _WelcomePhotoShade extends StatelessWidget {
  const _WelcomePhotoShade();

  @override
  Widget build(BuildContext context) => const IgnorePointer(
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0, .15, .40, .63, .78, 1],
          colors: [
            Color(0x8A07130E),
            Color(0x2407130E),
            Color(0x6007130E),
            Color(0xBD07120E),
            Color(0xF107100D),
            Color(0xFF070F0D),
          ],
        ),
      ),
    ),
  );
}

class _WelcomeBrand extends StatelessWidget {
  const _WelcomeBrand();

  @override
  Widget build(BuildContext context) => const Row(children: [
    Icon(Icons.medical_services_outlined, size: 22, color: Color(0xFF9CE5C4)),
    SizedBox(width: 9),
    Flexible(child: Text('MediSuivi', key: Key('welcome-brand'),
      maxLines: 1, overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: Colors.white, fontSize: 17, letterSpacing: -.4,
        fontWeight: FontWeight.w700))),
  ]);
}


/// Écran d'ouverture : portrait lisible, rédaction à mi-hauteur, barre
/// de préparation séparée et alignée avec la largeur des textes.
class _IntroSplash extends StatelessWidget {
  const _IntroSplash({super.key});

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      backgroundColor: const Color(0xFF070F0D),
      body: Stack(fit: StackFit.expand, children: [
        const _WelcomePhoto(
          imageUrl: _WelcomePhotos.splash,
          imageKey: Key('welcome-splash-photo'),
          alignment: Alignment(0, -.35),
        ),
        const IgnorePointer(child: DecoratedBox(
          decoration: BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0, .16, .38, .56, .79, 1],
            colors: [
              Color(0x6B07110F),
              Color(0x0807110F),
              Color(0x6007110F),
              Color(0xDD07110F),
              Color(0xF807100D),
              Color(0xFF070F0D),
            ],
          )),
        )),
        SafeArea(child: Padding(
          padding: const EdgeInsets.fromLTRB(25, 21, 25, 33),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _WelcomeBrand(),
              const Spacer(flex: 5),
              const Text('VOTRE ESPACE CLINIQUE',
                style: TextStyle(
                  color: Color(0xFFB5E6CF),
                  fontSize: ClinicalTypeScale.caption,
                  letterSpacing: 1.05, fontWeight: FontWeight.w700,
                )),
              const SizedBox(height: 12),
              const Text('Le suivi médical,\\nà portée de main.',
                key: Key('welcome-splash-title'),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: ClinicalTypeScale.hero,
                  height: 1.16, letterSpacing: -.65,
                  fontWeight: FontWeight.w700,
                )),
              const SizedBox(height: 12),
              const Text('Une pratique plus claire.\\nDes dossiers mieux organisés.',
                style: TextStyle(
                  color: Color(0xFFE6F1EA),
                  fontSize: ClinicalTypeScale.body,
                  height: 1.48,
                )),
              const Spacer(flex: 2),
              Row(children: [
                const Expanded(child: Text('Préparation de votre espace',
                  style: TextStyle(color: Color(0xFFE1EDE5),
                    fontSize: ClinicalTypeScale.body,
                    fontWeight: FontWeight.w600))),
                const SizedBox(width: 12),
                const Icon(Icons.shield_outlined, color: Color(0xFFABD9C2),
                  size: 17),
              ]),
              const SizedBox(height: 12),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: reduced ? Duration.zero
                  : const Duration(milliseconds: 2580),
                curve: Curves.easeInOutCubic,
                builder: (context, value, _) => ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LinearProgressIndicator(
                    key: const Key('welcome-progress'),
                    value: value,
                    minHeight: 4,
                    color: const Color(0xFF9CE5C4),
                    backgroundColor: const Color(0x668BADA0),
                  ),
                ),
              ),
            ],
          ),
        )),
      ]),
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

  static const _slides = <_OnboardSlide>[
    _OnboardSlide(
      label: 'DOSSIERS PATIENTS',
      image: _WelcomePhotos.records,
      alignment: Alignment(0, -.40),
      title: 'Vos dossiers, en un regard.',
      description: 'Retrouvez les informations essentielles et l’historique de chaque patient, sans vous disperser.',
    ),
    _OnboardSlide(
      label: 'CONTINUITÉ DES SOINS',
      image: _WelcomePhotos.followup,
      alignment: Alignment(0, -.45),
      title: 'Chaque étape compte.',
      description: 'Consultations, résultats et prochaines visites restent organisés autour du suivi du patient.',
    ),
    _OnboardSlide(
      label: 'ESPACE PERSONNEL',
      image: _WelcomePhotos.privacy,
      alignment: Alignment(0, -.20),
      title: 'Un espace à vous.',
      description: 'Vos dossiers restent locaux tant que la synchronisation sécurisée n’est pas disponible.',
    ),
  ];

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      backgroundColor: const Color(0xFF070F0D),
      body: Stack(fit: StackFit.expand, children: [
        PageView.builder(
          key: const Key('onboarding-pages'),
          controller: _pages,
          itemCount: _slides.length,
          onPageChanged: (index) => setState(() => _index = index),
          itemBuilder: (context, index) =>
              _OnboardPage(slide: _slides[index], index: index),
        ),
        Positioned(
          left: 0, right: 0, top: 0,
          child: SafeArea(bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(25, 18, 23, 0),
              child: Row(children: [
                const Expanded(child: _WelcomeBrand()),
                TextButton(
                  key: const Key('onboarding-skip'),
                  onPressed: widget.onFinished,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  child: const Text('Passer'),
                ),
              ]),
            ),
          ),
        ),
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: SafeArea(top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(25, 0, 25, 19),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Row(children: [
                  for (var i = 0; i < _slides.length; i++) ...[
                    AnimatedContainer(
                      key: Key('onboarding-dot-$i'),
                      duration: reduced ? Duration.zero :
                          const Duration(milliseconds: 260),
                      curve: Curves.easeInOutCubic,
                      width: i == _index ? 35 : 16,
                      height: 3,
                      decoration: BoxDecoration(
                        color: i == _index
                          ? const Color(0xFF99E9BE)
                          : const Color(0x67FFFFFF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  const Spacer(),
                  Text((_index + 1).toString().padLeft(2, '0') + ' / 03',
                    style: const TextStyle(
                      color: Color(0xFFD5E0D9),
                      fontSize: 11, letterSpacing: .9,
                      fontWeight: FontWeight.w600,
                    )),
                ]),
                const SizedBox(height: 23),
                _OnboardPrimaryButton(
                  key: const Key('onboarding-next'),
                  label: _index == _slides.length - 1 ? 'Continuer' : 'Suivant',
                  onTap: () {
                    if (_index == _slides.length - 1) {
                      widget.onFinished();
                    } else {
                      _pages.nextPage(
                        duration: reduced ? Duration.zero :
                          const Duration(milliseconds: 410),
                        curve: Curves.easeInOutCubic,
                      );
                    }
                  },
                ),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

class _OnboardSlide {
  const _OnboardSlide({
    required this.label,
    required this.image,
    required this.alignment,
    required this.title,
    required this.description,
  });
  final String label;
  final String image;
  final Alignment alignment;
  final String title;
  final String description;
}

class _OnboardPage extends StatelessWidget {
  const _OnboardPage({required this.slide, required this.index});
  final _OnboardSlide slide;
  final int index;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width <= 350;
    return Stack(fit: StackFit.expand, children: [
      _WelcomePhoto(
        imageUrl: slide.image,
        imageKey: Key('onboarding-clinical-image-$index'),
        alignment: slide.alignment,
      ),
      const _WelcomePhotoShade(),
      SafeArea(child: Padding(
        padding: const EdgeInsets.fromLTRB(25, 88, 25, 175),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(),
            Text(slide.label,
              style: const TextStyle(
                color: Color(0xFFACDEC3), fontSize: 10.5,
                letterSpacing: 1.25, fontWeight: FontWeight.w700,
              )),
            const SizedBox(height: 11),
            Text(slide.title,
              key: Key('onboarding-title-$index'),
              style: TextStyle(
                color: Colors.white,
                fontSize: narrow ? 29 : 33,
                height: 1.13, letterSpacing: -.9,
                fontWeight: FontWeight.w700,
              )),
            const SizedBox(height: 11),
            Text(slide.description,
              key: Key('onboarding-description-$index'),
              style: const TextStyle(
                color: Color(0xFFDBE4DD),
                fontSize: 14.3, height: 1.44,
                fontWeight: FontWeight.w400,
              )),
          ],
        ),
      )),
    ]);
  }
}

/// CTA compact à forme pilule, dégradé discret et flèche latérale.
class _OnboardPrimaryButton extends StatelessWidget {
  const _OnboardPrimaryButton({
    super.key, required this.label, required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final base = p.isDark
        ? ClinicalColors.darkActionFill : ClinicalColors.lightActionFill;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 345),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(60),
          elevation: 3,
          shadowColor: base.withValues(alpha: .24),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(60),
              gradient: LinearGradient(colors: [
                base,
                Color.lerp(base, const Color(0xFF091D17), .19)!,
              ]),
            ),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(60),
              child: SizedBox(
                width: double.infinity, height: 54,
                child: Padding(
                  padding: const EdgeInsets.only(left: 48, right: 13),
                  child: Row(children: [
                    Expanded(child: Text(label,
                      textAlign: TextAlign.center,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ClinicalColors.actionOnDarkFill,
                        fontWeight: FontWeight.w700, fontSize: 14))),
                    const SizedBox(width: 8),
                    Container(
                      width: 31, height: 31,
                      decoration: const BoxDecoration(
                        color: Color(0x20FFFFFF), shape: BoxShape.circle),
                      child: const Icon(Icons.arrow_forward_rounded,
                        size: 17, color: ClinicalColors.actionOnDarkFill),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardSecondaryButton extends StatelessWidget {
  const _OnboardSecondaryButton({
    super.key, required this.label, required this.onTap,
    this.onPhoto = false,
  });
  final String label;
  final VoidCallback onTap;
  final bool onPhoto;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 345),
        child: Material(
          color: onPhoto ? Colors.white.withValues(alpha: .10) : p.surface,
          borderRadius: BorderRadius.circular(60),
          child: InkWell(
            onTap: onTap, borderRadius: BorderRadius.circular(60),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(60),
                border: Border.all(
                  color: onPhoto ? Colors.white.withValues(alpha: .47) : p.border,
                  width: 1.15),
              ),
              alignment: Alignment.center,
              child: Text(label, style: TextStyle(
                color: onPhoto ? Colors.white : p.ink,
                fontSize: 13.5,
                fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ),
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
    return Scaffold(
      backgroundColor: const Color(0xFF070F0D),
      body: Stack(fit: StackFit.expand, children: [
        const _WelcomePhoto(
          imageUrl: _WelcomePhotos.access,
          imageKey: Key('welcome-access-photo'),
          alignment: Alignment(0, -.6),
        ),
        const _WelcomePhotoShade(),
        SafeArea(child: Center(child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 510),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(25, 19, 25, 21),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _WelcomeBrand(),
                const Spacer(),
                const Text('Votre espace de soin.\nRien qu’à vous.',
                  style: TextStyle(
                    color: Colors.white, fontSize: 29,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -.7, height: 1.15,
                  )),
                const SizedBox(height: 12),
                const Text(
                  'Un praticien, un espace personnel pour organiser ses dossiers.',
                  style: TextStyle(color: Color(0xFFDCE7E0),
                    fontSize: 13, height: 1.45),
                ),
                const SizedBox(height: 25),
                _OnboardPrimaryButton(
                  key: const Key('welcome-create'),
                  label: 'Créer un compte',
                  onTap: onCreate,
                ),
                const SizedBox(height: 12),
                _OnboardSecondaryButton(
                  key: const Key('welcome-login'),
                  label: 'Se connecter',
                  onTap: onSignIn,
                  onPhoto: true,
                ),
                const SizedBox(height: 13),
                Center(child: TextButton(
                  key: const Key('welcome-demo'),
                  onPressed: onLocalAccess,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFE3EDE8),
                    padding: const EdgeInsets.symmetric(horizontal: 8)),
                  child: Text(isWebDemo
                    ? 'Explorer la démonstration'
                    : 'Accéder aux dossiers locaux'),
                )),
                const SizedBox(height: 5),
                Text(isWebDemo
                  ? 'Démonstration avec patients fictifs. Aucun compte réel créé.'
                  : 'Dossiers locaux uniquement. Aucun compte distant connecté.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFC3CEC8), fontSize: 10.5,
                    height: 1.35),
                ),
              ],
            ),
          ),
        ))),
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
        _OnboardSecondaryButton(
          key: const Key('login-local-access'),
          onTap: onLocalAccess,
          label: isWebDemo
            ? 'Explorer la démonstration' : 'Accéder aux dossiers locaux',
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
              _OnboardPrimaryButton(
                key: const Key('practitioner-save-preview'),
                onTap: _save,
                label: widget.isWebDemo
                  ? 'Voir mon espace de démonstration'
                  : 'Continuer vers mon espace local'),
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
