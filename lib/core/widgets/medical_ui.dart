import 'package:flutter/material.dart';
import '../../app/theme.dart';
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
  const SurfaceCard({super.key, required this.child, this.onTap, this.padding = const EdgeInsets.all(16)});
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
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(19),
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

class PatientRow extends StatelessWidget {
  const PatientRow({super.key, required this.patient, required this.onTap, this.subtitle});
  final Patient patient;
  final VoidCallback onTap;
  final String? subtitle;
  @override
  Widget build(BuildContext context) {
    final p = _p(context);
    return SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
      child: Row(children: [
        PatientAvatar(patient: patient, hero: true),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(patient.name, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, color: p.ink)),
          const SizedBox(height: 4),
          Text(subtitle ?? '${patient.id} · ${patient.age} ans',
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 14, color: p.muted)),
        ])),
        if (patient.followUp) Icon(Icons.event_repeat_rounded, size: 19, color: p.teal),
        const SizedBox(width: 4),
        Icon(Icons.chevron_right_rounded, color: p.muted),
      ]),
    );
  }
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
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
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