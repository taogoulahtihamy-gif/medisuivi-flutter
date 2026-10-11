import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../models/medical_models.dart';

String shortDate(DateTime d) {
  const months = ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

class ScreenWidth extends StatelessWidget {
  const ScreenWidth({super.key, required this.child, this.padding = const EdgeInsets.fromLTRB(20, 22, 20, 36)});
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Center(child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 720),
    child: Padding(padding: padding, child: child),
  ));
}

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({super.key, required this.child, this.onTap, this.padding = const EdgeInsets.all(18)});
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Material(
    color: Palette.white,
    elevation: 0,
    shadowColor: Palette.night,
    shape: RoundedRectangleBorder(
      side: const BorderSide(color: Palette.border),
      borderRadius: BorderRadius.circular(20),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(19),
      onTap: onTap,
      child: Padding(padding: padding, child: child),
    ),
  );
}

class SectionHeading extends StatelessWidget {
  const SectionHeading({super.key, required this.title, this.trailing, this.onTap});
  final String title;
  final String? trailing;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3))),
    if (trailing != null) TextButton(onPressed: onTap, child: Text(trailing!)),
  ]);
}

class DemoNotice extends StatelessWidget {
  const DemoNotice({super.key, this.compact = false});
  final bool compact;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
    decoration: BoxDecoration(color: Palette.amberSoft, borderRadius: BorderRadius.circular(12)),
    child: Row(children: [
      const Icon(Icons.info_outline_rounded, color: Palette.laser, size: 18),
      const SizedBox(width: 9),
      Expanded(child: Text(compact ? 'Démonstration · données fictives' :
        'Prototype de démonstration · ne pas saisir de données médicales réelles.',
        style: const TextStyle(fontSize: 12, color: Palette.laser, fontWeight: FontWeight.w600))),
    ]),
  );
}

class PatientAvatar extends StatelessWidget {
  const PatientAvatar({super.key, required this.patient, this.size = 44, this.hero = false});
  final Patient patient;
  final double size;
  final bool hero;
  @override
  Widget build(BuildContext context) {
    final box = Container(
      width: size, height: size, alignment: Alignment.center,
      decoration: BoxDecoration(color: Palette.tealSoft, borderRadius: BorderRadius.circular(size * 0.42)),
      child: Text(patient.initials, style: TextStyle(color: Palette.laser, fontWeight: FontWeight.w800, fontSize: size * .29)),
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
  Widget build(BuildContext context) => SurfaceCard(
    onTap: onTap,
    padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
    child: Row(children: [
      PatientAvatar(patient: patient, hero: true),
      const SizedBox(width: 13),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(patient.name, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(subtitle ?? '${patient.id} · ${patient.age} ans',
          maxLines: 1, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: Palette.muted)),
      ])),
      if (patient.followUp) const Icon(Icons.event_repeat_rounded, size: 19, color: Palette.teal),
      const SizedBox(width: 4),
      const Icon(Icons.chevron_right_rounded, color: Palette.muted),
    ]),
  );
}

class PageTitle extends StatelessWidget {
  const PageTitle({super.key, required this.title, required this.subtitle, this.action});
  final String title;
  final String subtitle;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 28, letterSpacing: -1, fontWeight: FontWeight.w800)),
      const SizedBox(height: 7),
      Text(subtitle, style: const TextStyle(fontSize: 13, color: Palette.muted)),
    ])),
    if (action != null) action!,
  ]);
}

class SoftIcon extends StatelessWidget {
  const SoftIcon({super.key, required this.icon, this.color = Palette.teal, this.background = Palette.tealSoft});
  final IconData icon;
  final Color color;
  final Color background;
  @override
  Widget build(BuildContext context) => Container(
    width: 44, height: 44,
    decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(14)),
    child: Icon(icon, color: color, size: 21),
  );
}

class EmptyResults extends StatelessWidget {
  const EmptyResults({super.key, required this.title, required this.detail, this.icon = Icons.folder_open_outlined});
  final String title;
  final String detail;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 18),
    child: Column(children: [
      Icon(icon, color: Palette.muted, size: 44),
      const SizedBox(height: 14),
      Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Text(detail, textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 13, color: Palette.muted)),
    ]),
  );
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
