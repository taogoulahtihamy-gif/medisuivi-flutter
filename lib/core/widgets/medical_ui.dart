import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../app/display_preferences.dart';
import '../../core/models/medical_models.dart';

String shortDate(DateTime d) {
  const months = ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

/// Résout la palette Nocturne Clinique depuis le contexte.
PaletteData _p(BuildContext context) => Palette.of(context);

class ScreenWidth extends StatelessWidget {
  const ScreenWidth({super.key, required this.child, this.padding = const EdgeInsets.fromLTRB(20, 22, 20, 36)});
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Center(child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 620),
    child: Padding(padding: padding, child: child),
  ));
}

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({super.key, required this.child, this.onTap, this.padding = const EdgeInsets.all(14)});
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) {
    final p = _p(context);
    return Material(
      color: p.surface,
      elevation: 0,
      shadowColor: p.night,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: p.border),
        borderRadius: BorderRadius.circular(24),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class SectionHeading extends StatelessWidget {
  const SectionHeading({super.key, required this.title, this.trailing, this.onTap});
  final String title;
  final String? trailing;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final p = _p(context);
    return Row(children: [
      Expanded(child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.35, color: p.ink))),
      if (trailing != null) TextButton(onPressed: onTap, child: Text(trailing!)),
    ]);
  }
}

class PatientAvatar extends StatelessWidget {
  const PatientAvatar({super.key, required this.patient, this.size = 44, this.hero = false});
  final Patient patient;
  final double size;
  final bool hero;
  @override
  Widget build(BuildContext context) {
    final p = _p(context);
    final box = Container(
      width: size, height: size, alignment: Alignment.center,
      decoration: BoxDecoration(color: p.tealSoft, borderRadius: BorderRadius.circular(size * 0.42)),
      child: Text(patient.initials, style: TextStyle(color: p.tealDark, fontWeight: FontWeight.w700, fontSize: size * .30)),
    );
    return hero ? Hero(tag: 'patient-${patient.id}', child: box) : box;
  }
}

/// Surface commune pour les registres : un seul fond et séparateurs fins.
class ClinicalGroupedList extends StatelessWidget {
  const ClinicalGroupedList({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Material(
      color: p.surface.withValues(alpha: p.isDark ? .76 : 1.0),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(19),
        side: BorderSide(color: p.border),
      ),
      child: Column(children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) Padding(
            padding: const EdgeInsets.only(left: 60, right: 13),
            child: Divider(height: 1, thickness: .65, color: p.border),
          ),
          children[i],
        ],
      ]),
    );
  }
}

/// Ligne éditoriale compacte et tactile, partagée entre dossiers et examens.
class ClinicalListRow extends StatelessWidget {
  const ClinicalListRow({
    super.key, required this.title, required this.onTap,
    this.subtitle, this.detail, this.leading, this.trailing,
  });

  final String title;
  final String? subtitle;
  final String? detail;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final compact = DisplayPreferencesScope.maybeOf(context)
        ?.value.compactLists ?? true;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.fromLTRB(14, compact ? 12 : 18,
          13, compact ? 12 : 18),
        child: Row(children: [
          if (leading != null) ...[leading!, const SizedBox(width: 12)],
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                maxLines: 2, overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15.3, height: 1.22,
                  fontWeight: FontWeight.w600, color: p.ink)),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!,
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13.1, height: 1.3, color: p.muted)),
              ],
              if (detail != null) ...[
                const SizedBox(height: 5),
                Text(detail!,
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13.1, fontWeight: FontWeight.w600,
                    color: p.forest)),
              ],
            ],
          )),
          const SizedBox(width: 9),
          if (trailing != null) trailing!,
          Icon(Icons.chevron_right_rounded, size: 19, color: p.muted),
        ]),
      ),
    );
  }
}

class PatientRow extends StatelessWidget {
  const PatientRow({
    super.key, required this.patient, required this.onTap, this.subtitle,
  });
  final Patient patient;
  final VoidCallback onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => ClinicalListRow(
    title: patient.name,
    subtitle: subtitle ?? '${patient.id} · ${patient.age} ans',
    leading: PatientAvatar(patient: patient, size: 40, hero: true),
    trailing: patient.followUp
        ? Icon(Icons.event_repeat_rounded, size: 17,
            color: Palette.of(context).forest) : null,
    onTap: onTap,
  );
}

class PageTitle extends StatelessWidget {
  const PageTitle({super.key, required this.title, required this.subtitle, this.action});
  final String title;
  final String subtitle;
  final Widget? action;
  @override
  Widget build(BuildContext context) {
    final p = _p(context);
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontSize: 23, height: 1.18, letterSpacing: -0.75, fontWeight: FontWeight.w700, color: p.ink)),
        const SizedBox(height: 7),
        Text(subtitle, style: TextStyle(fontSize: 14, color: p.muted)),
      ])),
      if (action != null) action!,
    ]);
  }
}

class SoftIcon extends StatelessWidget {
  const SoftIcon({super.key, required this.icon, this.color, this.background});
  final IconData icon;
  final Color? color;
  final Color? background;
  @override
  Widget build(BuildContext context) {
    final p = _p(context);
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        color: background ?? p.tealSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color ?? p.teal, size: 21),
    );
  }
}

class EmptyResults extends StatelessWidget {
  const EmptyResults({super.key, required this.title, required this.detail, this.icon = Icons.folder_open_outlined});
  final String title;
  final String detail;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    final p = _p(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 18),
      child: Column(children: [
        Icon(icon, color: p.muted, size: 44),
        const SizedBox(height: 14),
        Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: p.ink)),
        const SizedBox(height: 8),
        Text(detail, textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: p.muted)),
      ]),
    );
  }
}

/// One gentle entrance; disabled when the user requests reduced motion.
class EntranceReveal extends StatelessWidget {
  const EntranceReveal({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      builder: (context, progress, child) => Opacity(
        opacity: progress,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - progress)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// Groupe de saisie réutilisable : lecture claire, sans troisième couleur.
class ClinicalFormSection extends StatelessWidget {
  const ClinicalFormSection({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.subtitle,
  });
  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = _p(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: p.tealSoft,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, size: 21, color: p.forest),
            ),
            const SizedBox(width: 11),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(
                  fontSize: 15.5, fontWeight: FontWeight.w600,
                  color: p.forest,
                )),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(subtitle!, style: TextStyle(
                    fontSize: 13.5, height: 1.4, color: p.muted)),
                ],
              ],
            )),
          ]),
          const SizedBox(height: 19),
          child,
        ],
      ),
    );
  }
}

/// Section de formulaire compacte : évite plusieurs écrans de défilement.
/// Les contrôleurs appartiennent à l'écran parent ; maintainState préserve
/// aussi les widgets enfants lorsqu'une section est repliée.
class ClinicalDisclosureSection extends StatelessWidget {
  const ClinicalDisclosureSection({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.subtitle,
    this.initiallyExpanded = false,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final String? subtitle;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final p = _p(context);
    return Material(
      color: p.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: p.border),
        borderRadius: BorderRadius.circular(17),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          key: PageStorageKey<String>('clinical-section-$title'),
          maintainState: true,
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 1),
          childrenPadding: const EdgeInsets.fromLTRB(15, 0, 15, 16),
          leading: Icon(icon, color: p.forest, size: 20),
          title: Text(title, style: TextStyle(
            fontSize: 14.5, fontWeight: FontWeight.w600, color: p.ink,
          )),
          subtitle: subtitle == null ? null : Text(subtitle!,
            style: TextStyle(fontSize: 12.5, color: p.muted)),
          children: [
            Divider(height: 14, color: p.border),
            child,
          ],
        ),
      ),
    );
  }
}
