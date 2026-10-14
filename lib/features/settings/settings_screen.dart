import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../app/theme_controller.dart';
import '../../app/display_preferences.dart';
import '../../core/state/store_context.dart';
import '../notifications/clinical_alerts_screen.dart';
import 'settings_detail_screens.dart';
import '../onboarding/medisuivi_welcome_gate.dart';

/// Profil personnel et préférences : sections lisibles plutôt qu'une pile
/// de cartes techniques. Aucune fonctionnalité de compte distant simulée.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<int>? _pendingSyncCountFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!kIsWeb) {
      _pendingSyncCountFuture = context.store.pendingSyncCount;
    }
  }

  void _open(Widget page) => Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => page),
  );

  void _editProfile(PractitionerPreview? profile) {
    if (profile == null) {
      _open(const _SettingsDetailPage(
        title: 'Mon profil',
        icon: Icons.person_outline_rounded,
        heading: 'Aucun profil configuré',
        description:
            'Pour modifier votre identité, passez par le parcours de '
            'prévisualisation du praticien. Aucun compte distant n’est actif.',
      ));
      return;
    }
    _open(PractitionerPreviewForm(
      controller: profile,
      isWebDemo: kIsWeb,
      onSaved: () => Navigator.of(context).pop(),
    ));
  }

  void _openStorage() => _open(const SettingsDataPage());
  void _openSync() => _open(const SettingsSyncPage());
  void _openPrivacy() => _open(const SettingsPrivacyPage());
  void _openAbout() => _open(const SettingsAboutPage());

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final practitioner = PractitionerPreviewScope.maybeOf(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil et paramètres'),
        titleTextStyle: TextStyle(color: p.ink, fontSize: 18.5,
          fontWeight: FontWeight.w700),
        automaticallyImplyLeading: Navigator.of(context).canPop(),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              key: const Key('settings-page-list'),
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(21, 9, 21, 118),
              children: [
                _ProfileHeader(
                  controller: practitioner,
                  onEdit: () => _editProfile(practitioner),
                ),
                if (!kIsWeb) ...[
                  const SizedBox(height: 21),
                  _OfflineOperationsSummary(future: _pendingSyncCountFuture),
                ],
                const SizedBox(height: 27),
                const _GroupHeading('PERSONNALISATION'),
                const SizedBox(height: 8),
                _SettingsGroup(children: [
                  _SettingsLine(
                    key: const Key('settings-appearance'),
                    icon: Icons.palette_outlined,
                    title: 'Apparence',
                    subtitle: 'Personnalisez votre affichage',
                    onTap: () => _open(const _AppearanceDetailPage()),
                  ),
                  const _AppearanceQuickChoice(),
                ]),
                const SizedBox(height: 23),
                const _GroupHeading('MON ACTIVITÉ'),
                const SizedBox(height: 8),
                _SettingsGroup(children: [
                  _SettingsLine(
                    key: const Key('settings-notifications'),
                    icon: Icons.notifications_none_rounded,
                    title: 'Notifications',
                    subtitle: 'Vos alertes cliniques locales',
                    onTap: () => _open(const ClinicalAlertsScreen()),
                  ),
                  _SettingsLine(
                    key: const Key('settings-data'),
                    icon: Icons.folder_copy_outlined,
                    title: 'Données et stockage',
                    subtitle: kIsWeb ? 'Dossiers fictifs du navigateur'
                        : 'Dossiers sur cet appareil',
                    onTap: _openStorage,
                  ),
                  _SettingsLine(
                    key: const Key('settings-synchronization'),
                    icon: Icons.cloud_off_outlined,
                    title: 'Synchronisation',
                    subtitle: 'Non disponible pour le moment',
                    onTap: _openSync,
                    last: true,
                  ),
                ]),
                const SizedBox(height: 23),
                const _GroupHeading('APPLICATION'),
                const SizedBox(height: 8),
                _SettingsGroup(children: [
                  _SettingsLine(
                    key: const Key('settings-privacy'),
                    icon: Icons.shield_outlined,
                    title: 'Confidentialité',
                    subtitle: 'Protection et accès aux dossiers',
                    onTap: _openPrivacy,
                  ),
                  _SettingsLine(
                    key: const Key('settings-more'),
                    icon: Icons.tune_rounded,
                    title: 'Paramètres supplémentaires',
                    subtitle: 'Langue, préférences et informations',
                    onTap: () => _open(_MoreSettingsPage(
                      onStorage: _openStorage,
                      onPrivacy: _openPrivacy,
                      onAbout: _openAbout,
                    )),
                  ),
                  _SettingsLine(
                    key: const Key('settings-about'),
                    icon: Icons.info_outline_rounded,
                    title: 'À propos de MediSuivi',
                    subtitle: 'Version et informations',
                    onTap: _openAbout,
                    last: true,
                  ),
                ]),
                const SizedBox(height: 24),
                Center(child: Text(
                  kIsWeb
                    ? 'Profil de démonstration · Aucun compte distant'
                    : 'Profil local de prévisualisation · Aucun compte distant',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: p.muted, fontSize: 11.5),
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.controller, required this.onEdit});

  final PractitionerPreview? controller;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final name = controller?.displayName.isNotEmpty == true
        ? controller!.displayName : 'Votre profil';
    final specialty = controller?.specialty.trim() ?? '';
    final email = controller?.email.trim() ?? '';
    final photo = controller?.photo;

    return Column(children: [
      const SizedBox(height: 7),
      Semantics(
        label: photo == null ? 'Photo de profil non définie'
            : 'Photo du profil praticien',
        child: GestureDetector(
          key: const Key('settings-avatar-edit'),
          onTap: onEdit,
          child: Stack(clipBehavior: Clip.none, children: [
            CircleAvatar(
              key: const Key('settings-profile-avatar'),
              radius: 49,
              backgroundColor: p.tealSoft,
              foregroundImage: photo == null ? null : MemoryImage(photo),
              child: photo == null
                  ? Icon(Icons.person_outline_rounded,
                      size: 43, color: p.forest) : null,
            ),
            Positioned(
              right: -3, bottom: -1,
              child: Container(
                width: 29, height: 29,
                decoration: BoxDecoration(
                  color: p.forest,
                  shape: BoxShape.circle,
                  border: Border.all(color: p.canvas, width: 2.5),
                ),
                child: Icon(Icons.edit_outlined, size: 13,
                  color: p.isDark ? const Color(0xFF082017) : Colors.white),
              ),
            ),
          ]),
        ),
      ),
      const SizedBox(height: 14),
      Text(name,
        key: const Key('settings-profile-name'),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
          letterSpacing: -.55, color: p.ink)),
      const SizedBox(height: 4),
      Text(specialty.isNotEmpty ? specialty : 'Espace personnel MediSuivi',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13, color: p.muted)),
      if (email.isNotEmpty) ...[
        const SizedBox(height: 3),
        Text(email, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: p.muted)),
      ],
      const SizedBox(height: 13),
      OutlinedButton.icon(
        key: const Key('settings-practitioner-profile'),
        onPressed: onEdit,
        icon: const Icon(Icons.edit_outlined, size: 15),
        label: const Text('Modifier mon profil'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 39),
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 8),
          side: BorderSide(color: p.border),
          foregroundColor: p.ink,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
        ),
      ),
    ]);
  }
}

/// Statut des écritures locales toujours disponible sur Android.
class _OfflineOperationsSummary extends StatelessWidget {
  const _OfflineOperationsSummary({required this.future});
  final Future<int>? future;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return FutureBuilder<int>(
      future: future,
      builder: (context, snapshot) {
        final count = snapshot.data;
        final details = snapshot.hasError
            ? 'Impossible de vérifier les opérations locales.'
            : count == null
                ? 'Vérification des opérations locales…'
                : count == 0
                    ? 'Aucune modification en attente. Aucun serveur distant connecté.'
                    : '$count modification(s) conservée(s) sur ce téléphone, en attente d’un futur envoi.';
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
          decoration: BoxDecoration(
            color: p.surface,
            border: Border.all(color: p.border),
            borderRadius: BorderRadius.circular(17),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Modifications à envoyer',
              style: TextStyle(color: p.ink, fontSize: 12.5,
                fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(details, style: TextStyle(
              color: p.muted, fontSize: 11.5, height: 1.4)),
            const SizedBox(height: 10),
            Text('Synchronisation distante',
              style: TextStyle(color: p.ink, fontSize: 12.5,
                fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            Text('Non configurée. Aucune transmission automatique à un serveur.',
              style: TextStyle(color: p.muted, fontSize: 11.5, height: 1.4)),
          ]),
        );
      },
    );
  }
}

class _GroupHeading extends StatelessWidget {
  const _GroupHeading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 5),
      child: Text(text, style: TextStyle(
        color: p.muted, fontSize: 11.5,
        letterSpacing: 1.05, fontWeight: FontWeight.w700)),
    );
  }
}

/// Un groupe uniquement par section. Traits fins, lignes ouvertes et
/// marges homogènes : pas de cartes empilées pour chaque paramètre.
class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Container(
      decoration: BoxDecoration(
        color: p.surface.withValues(alpha: p.isDark ? .65 : .92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.border.withValues(alpha: .74)),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsLine extends StatelessWidget {
  const _SettingsLine({
    super.key,
    required this.icon, required this.title,
    required this.subtitle, required this.onTap,
    this.last = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Column(children: [
      Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(17),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(children: [
              Icon(icon, size: 20, color: p.forest),
              const SizedBox(width: 13),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: p.ink, fontSize: 14.6,
                      fontWeight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: p.muted, fontSize: 12.5,
                      height: 1.35)),
                ],
              )),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded, size: 19, color: p.muted),
            ]),
          ),
        ),
      ),
      if (!last) Padding(
        padding: const EdgeInsets.only(left: 47, right: 16),
        child: Divider(height: 1, thickness: .8, color: p.border),
      ),
    ]);
  }
}

const _themeModes = <(ThemeMode, String, IconData)>[
  (ThemeMode.light, 'Clair', Icons.light_mode_outlined),
  (ThemeMode.dark, 'Sombre', Icons.dark_mode_outlined),
  (ThemeMode.system, 'Auto', Icons.settings_suggest_outlined),
];

class _AppearanceQuickChoice extends StatelessWidget {
  const _AppearanceQuickChoice();

  @override
  Widget build(BuildContext context) {
    final controller = ClinicalThemeScope.maybeOf(context);
    final selected = controller?.value ?? ThemeMode.system;
    return Padding(
      padding: const EdgeInsets.fromLTRB(13, 8, 13, 14),
      child: Wrap(spacing: 7, runSpacing: 7, children: [
        for (final option in _themeModes)
          ChoiceChip(
            key: Key('theme-${option.$1.name}'),
            label: Text(option.$2),
            avatar: Icon(option.$3, size: 16),
            selected: selected == option.$1,
            onSelected: controller == null
                ? null : (_) => controller.choose(option.$1),
            visualDensity: VisualDensity.compact,
          ),
      ]),
    );
  }
}

class _AppearanceDetailPage extends StatelessWidget {
  const _AppearanceDetailPage();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Apparence et thème')),
    body: SafeArea(child: Center(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 540),
      child: ListView(padding: const EdgeInsets.all(23), children: [
        Text('Personnalisez votre espace',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
            color: Palette.of(context).ink)),
        const SizedBox(height: 9),
        Text('Le thème s’applique immédiatement à MediSuivi.',
          style: TextStyle(color: Palette.of(context).muted)),
        const SizedBox(height: 22),
        const _AppearanceOptions(),
      ]),
    ))),
  );
}

class _AppearanceOptions extends StatelessWidget {
  const _AppearanceOptions();

  @override
  Widget build(BuildContext context) {
    final controller = ClinicalThemeScope.maybeOf(context);
    final p = Palette.of(context);
    return Column(children: [
      for (final option in _themeModes)
        ListTile(
          key: Key('appearance-option-${option.$1.name}'),
          leading: Icon(option.$3, color: p.forest),
          title: Text(option.$2),
          trailing: (controller?.value ?? ThemeMode.system) == option.$1
              ? Icon(Icons.check_circle_rounded, color: p.forest) : null,
          onTap: controller == null ? null
              : () => controller.choose(option.$1),
        ),
    ]);
  }
}

class _SettingsDetailPage extends StatelessWidget {
  const _SettingsDetailPage({
    required this.title, required this.icon, required this.heading,
    required this.description,
  });

  final String title;
  final IconData icon;
  final String heading;
  final String description;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 23, 24, 35),
          children: [
            Icon(icon, size: 37, color: p.forest),
            const SizedBox(height: 18),
            Text(heading,
              style: TextStyle(fontSize: 22,
                fontWeight: FontWeight.w700, color: p.ink)),
            const SizedBox(height: 12),
            Text(description, style: TextStyle(
              fontSize: 14, height: 1.6, color: p.muted)),
          ],
        ),
      ))),
    );
  }
}

class _MoreSettingsPage extends StatelessWidget {
  const _MoreSettingsPage({
    required this.onStorage, required this.onPrivacy,
    required this.onAbout,
  });
  final VoidCallback onStorage;
  final VoidCallback onPrivacy;
  final VoidCallback onAbout;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final display = DisplayPreferencesScope.maybeOf(context);
    void openLanguage() => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const _LanguageSettingsPage(),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres supplémentaires')),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(21, 21, 21, 42),
          children: [
            Text('Préférences de l’application',
              style: TextStyle(color: p.ink, fontSize: 22,
                fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Retrouvez les informations et réglages complémentaires.',
              style: TextStyle(color: p.muted, fontSize: 13)),
            const SizedBox(height: 25),
            Text('AFFICHAGE', style: TextStyle(
              color: p.muted, fontSize: 11.5,
              fontWeight: FontWeight.w700, letterSpacing: .7)),
            const SizedBox(height: 10),
            _SettingsGroup(children: [
              SwitchListTile.adaptive(
                key: const Key('settings-reduce-motion'),
                title: const Text('Réduire les animations'),
                subtitle: const Text('Transitions plus discrètes dans MediSuivi'),
                value: display?.value.reduceMotion ?? false,
                onChanged: display == null
                    ? null : (enabled) => display.setReduceMotion(enabled),
              ),
              Divider(height: 1, color: p.border),
              SwitchListTile.adaptive(
                key: const Key('settings-compact-lists'),
                title: const Text('Listes compactes'),
                subtitle: const Text('Lignes resserrées ou plus espacées'),
                value: display?.value.compactLists ?? true,
                onChanged: display == null
                    ? null : (enabled) => display.setCompactLists(enabled),
              ),
            ]),
            const SizedBox(height: 24),
            Text('INFORMATIONS', style: TextStyle(
              color: p.muted, fontSize: 11.5,
              fontWeight: FontWeight.w700, letterSpacing: .7)),
            const SizedBox(height: 10),
            _SettingsGroup(children: [
              _SettingsLine(
                key: const Key('more-language'),
                icon: Icons.language_outlined,
                title: 'Langue',
                subtitle: 'Français',
                onTap: openLanguage,
              ),
              _SettingsLine(
                key: const Key('more-storage'),
                icon: Icons.storage_rounded,
                title: 'Espace de stockage',
                subtitle: 'Consulter les informations locales',
                onTap: onStorage,
              ),
              _SettingsLine(
                key: const Key('more-privacy'),
                icon: Icons.privacy_tip_outlined,
                title: 'Protection des dossiers',
                subtitle: 'Informations de sécurité',
                onTap: onPrivacy,
              ),
              _SettingsLine(
                key: const Key('more-about'),
                icon: Icons.info_outline_rounded,
                title: 'À propos',
                subtitle: 'Version et fonctionnement',
                onTap: onAbout,
                last: true,
              ),
            ]),
          ],
        ),
      ))),
    );
  }
}

class _LanguageSettingsPage extends StatelessWidget {
  const _LanguageSettingsPage();

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Langue')),
      body: SafeArea(child: ListView(
        padding: const EdgeInsets.fromLTRB(21, 24, 21, 38),
        children: [
          Text('Langue de l’interface', style: TextStyle(color: p.ink,
            fontSize: 23, fontWeight: FontWeight.w700)),
          const SizedBox(height: 9),
          Text('Langue actuellement prise en charge par MediSuivi.',
            style: TextStyle(color: p.muted, fontSize: 13.5)),
          const SizedBox(height: 20),
          Material(
            color: p.surface,
            borderRadius: BorderRadius.circular(17),
            child: ListTile(
              key: const Key('settings-language-fr'),
              title: const Text('Français'),
              subtitle: const Text('Langue actuelle'),
              trailing: Icon(Icons.check_circle_rounded, color: p.forest),
            ),
          ),
          const SizedBox(height: 18),
          Text('Les autres langues ne sont pas encore disponibles.',
            style: TextStyle(color: p.muted, fontSize: 12.5)),
        ],
      )),
    );
  }
}
