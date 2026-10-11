import 'package:flutter/material.dart';
import '../../app/theme.dart';

class PremiumCard extends StatelessWidget {
  const PremiumCard(
      {super.key,
      required this.child,
      this.onTap,
      this.padding = const EdgeInsets.all(18)});
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            boxShadow: AppShadows.soft),
        child: Material(
            color: Colors.white,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.card),
                side: const BorderSide(color: Palette.border)),
            child: InkWell(
                onTap: onTap, child: Padding(padding: padding, child: child))),
      );
}

class MedicalHeader extends StatelessWidget {
  const MedicalHeader(
      {super.key,
      required this.eyebrow,
      required this.title,
      required this.description,
      this.icon = Icons.medical_services_outlined});
  final String eyebrow, title, description;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: Palette.forest,
            borderRadius: BorderRadius.circular(AppRadius.hero)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: Palette.mintFog, size: 28),
          const SizedBox(height: 20),
          Text(eyebrow.toUpperCase(),
              style: const TextStyle(
                  color: Palette.mintFog, fontSize: 12, letterSpacing: 1)),
          const SizedBox(height: 8),
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(description,
              style: const TextStyle(
                  color: Palette.mintFog, fontSize: 14, height: 1.5)),
        ]),
      );
}

class MedicalMetricCard extends StatelessWidget {
  const MedicalMetricCard(
      {super.key,
      required this.label,
      required this.value,
      required this.icon,
      this.onTap});
  final String label, value;
  final IconData icon;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => PremiumCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: Palette.forest, size: 22),
        const SizedBox(height: 14),
        Text(value,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Palette.muted)),
      ]));
}

class AdaptiveColumns extends StatelessWidget {
  const AdaptiveColumns(
      {super.key,
      required this.children,
      this.minWidth = 155,
      this.spacing = 12});
  final List<Widget> children;
  final double minWidth, spacing;
  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final scaledMin =
            minWidth * MediaQuery.textScalerOf(context).scale(14) / 14;
        final columns =
            ((constraints.maxWidth + spacing) / (scaledMin + spacing))
                .floor()
                .clamp(1, children.length);
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(spacing: spacing, runSpacing: spacing, children: [
          for (final child in children) SizedBox(width: width, child: child)
        ]);
      });
}

class StatusIndicator extends StatelessWidget {
  const StatusIndicator(
      {super.key,
      required this.label,
      this.icon = Icons.schedule_outlined,
      this.pending = false});
  final String label;
  final IconData icon;
  final bool pending;
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon,
            size: 17,
            color: pending ? const Color(0xFF8D5A20) : Palette.forest),
        const SizedBox(width: 6),
        Flexible(
            child: Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color:
                        pending ? const Color(0xFF8D5A20) : Palette.forest))),
      ]);
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton(
      {super.key,
      required this.label,
      required this.onPressed,
      this.icon = Icons.add_rounded});
  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  @override
  Widget build(BuildContext context) => ElevatedButton(
      onPressed: onPressed,
      child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Flexible(child: Text(label, textAlign: TextAlign.center)),
          ])));
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton(
      {super.key, required this.label, required this.onPressed});
  final String label;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) =>
      OutlinedButton(onPressed: onPressed, child: Text(label));
}

class CustomTextField extends StatelessWidget {
  const CustomTextField(
      {super.key,
      required this.label,
      required this.controller,
      this.keyboardType,
      this.validator,
      this.maxLines = 1,
      this.hint});
  final String label;
  final String? hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;
  @override
  Widget build(BuildContext context) => TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      textCapitalization: keyboardType == null
          ? TextCapitalization.sentences
          : TextCapitalization.none,
      decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          errorMaxLines: 3));
}

class MedicalSearchBar extends StatelessWidget {
  const MedicalSearchBar({super.key, required this.onChanged});
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => TextField(
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: const InputDecoration(
          labelText: 'Rechercher un patient',
          hintText: 'Nom ou numéro de dossier',
          prefixIcon: Icon(Icons.search_rounded)));
}

class MedicalTimeline extends StatelessWidget {
  const MedicalTimeline({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Column(children: [
        for (var i = 0; i < children.length; i++)
          IntrinsicHeight(
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                SizedBox(
                    width: 24,
                    child: Column(children: [
                      Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                              color: Palette.forest, shape: BoxShape.circle)),
                      if (i < children.length - 1)
                        Expanded(
                            child: Container(width: 1, color: Palette.border)),
                    ])),
                Expanded(
                    child: Padding(
                        padding: EdgeInsets.only(
                            bottom: i == children.length - 1 ? 0 : 24),
                        child: children[i])),
              ])),
      ]);
}

/// Static skeleton reserved for genuine asynchronous loading, never a fake delay.
class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({super.key});
  @override
  Widget build(BuildContext context) => Semantics(
      label: 'Chargement en cours',
      child: const PremiumCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        ColoredBox(color: Palette.border, child: SizedBox(height: 18)),
        SizedBox(height: 12),
        ColoredBox(color: Palette.canvas, child: SizedBox(height: 48)),
      ])));
}
