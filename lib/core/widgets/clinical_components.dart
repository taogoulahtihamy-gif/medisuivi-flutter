import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../../app/theme_v2.dart';

/// Résout la palette depuis le contexte.
ClinicalPalette _palette(BuildContext context) {
  final brightness = Theme.of(context).brightness;
  return brightness == Brightness.dark
      ? ClinicalTheme.darkPalette()
      : ClinicalTheme.lightPalette();
}

/// Carte clinique unifiée — trois densités, quatre variantes.
class ClinicalCard extends StatelessWidget {
  const ClinicalCard({
    super.key,
    required this.child,
    this.density = ClinicalCardDensity.comfortable,
    this.variant = ClinicalCardVariant.default_,
    this.onTap,
    this.padding,
    this.margin,
    this.borderRadius,
  });

  final Widget child;
  final ClinicalCardDensity density;
  final ClinicalCardVariant variant;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final p = _palette(context);
    final radius = borderRadius ??
        BorderRadius.circular(variant == ClinicalCardVariant.elevated
            ? ClinicalRadius.cardElevated
            : ClinicalRadius.cardDefault);
    final pad = padding ??
        switch (density) {
          ClinicalCardDensity.compact => const EdgeInsets.symmetric(
              horizontal: ClinicalSpacing.md, vertical: ClinicalSpacing.md),
          ClinicalCardDensity.comfortable => const EdgeInsets.symmetric(
              horizontal: ClinicalSpacing.lg, vertical: ClinicalSpacing.lg),
          ClinicalCardDensity.spacious => const EdgeInsets.symmetric(
              horizontal: ClinicalSpacing.xl, vertical: ClinicalSpacing.xl),
        };

    final (bg, borderSide, shadows) = switch (variant) {
      ClinicalCardVariant.elevated => (
          p.surfaceElevated,
          BorderSide(color: p.border, width: 1),
          p.isDark ? ClinicalShadow.level2Dark : ClinicalShadow.level2,
        ),
      ClinicalCardVariant.outlined => (
          Colors.transparent,
          BorderSide(color: p.borderFocus, width: 2),
          <BoxShadow>[],
        ),
      ClinicalCardVariant.filled => (
          p.brandPrimarySoft,
          BorderSide(color: p.brandPrimarySoft),
          <BoxShadow>[],
        ),
      ClinicalCardVariant.default_ => (
          p.surface,
          BorderSide(color: p.border, width: 1),
          <BoxShadow>[],
        ),
    };

    final content = Container(
      width: double.infinity,
      padding: pad,
      margin: margin,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: radius,
        border: Border.all(
          color: variant == ClinicalCardVariant.outlined
              ? p.borderFocus
              : p.border,
          width: variant == ClinicalCardVariant.outlined ? 2 : 1,
        ),
        boxShadow: shadows,
      ),
      child: child,
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: content,
      ),
    );
  }
}

/// Groupe de champs formulaire — remplace ClinicalFormSection.
class ClinicalFieldGroup extends StatelessWidget {
  const ClinicalFieldGroup({
    super.key,
    required this.icon,
    required this.title,
    required this.children,
    this.subtitle,
    this.footer,
    this.collapsible = false,
    this.initiallyExpanded = true,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;
  final String? subtitle;
  final Widget? footer;
  final bool collapsible;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final p = _palette(context);
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: p.brandPrimarySoft,
                borderRadius: BorderRadius.circular(ClinicalRadius.sm),
              ),
              child: Icon(icon, size: 21, color: p.brandPrimary),
            ),
            const SizedBox(width: ClinicalSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                    style: ClinicalTypography.headlineSmall.copyWith(
                      color: p.ink, fontWeight: FontWeight.w500)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(subtitle!,
                      style: ClinicalTypography.bodySmall.copyWith(
                        color: p.inkMuted)),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: ClinicalSpacing.lg),
        ...children,
        if (footer != null) ...[
          const SizedBox(height: ClinicalSpacing.md),
          footer!,
        ],
      ],
    );

    if (!collapsible) {
      return ClinicalCard(
        variant: ClinicalCardVariant.default_,
        padding: const EdgeInsets.all(ClinicalSpacing.lg),
        child: body,
      );
    }
    return ClinicalCard(
      variant: ClinicalCardVariant.default_,
      padding: const EdgeInsets.all(ClinicalSpacing.lg),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        title: body,
        children: const [],
      ),
    );
  }
}

/// Champ formulaire clinique avec label, unité, aide et validation.
class ClinicalField extends StatelessWidget {
  const ClinicalField({
    super.key,
    required this.label,
    this.hint,
    this.unit,
    this.controller,
    this.validator,
    this.keyboardType,
    this.voiceInput = false,
    this.expands = false,
    this.minLines = 1,
    this.maxLines = 1,
    this.onChanged,
    this.prefixIcon,
    this.suffix,
    this.autofocus = false,
    this.readOnly = false,
    this.onFieldSubmitted,
  });

  final String label;
  final String? hint;
  final String? unit;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool voiceInput;
  final bool expands;
  final int minLines;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool autofocus;
  final bool readOnly;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    final p = _palette(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
          style: ClinicalTypography.titleMedium.copyWith(
            color: p.ink, fontWeight: FontWeight.w500)),
        if (unit != null) ...[
          const SizedBox(height: 2),
          Text(unit!,
            style: ClinicalTypography.monoSmall.copyWith(
              color: p.inkSubtle)),
        ],
        const SizedBox(height: ClinicalSpacing.xs),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          onChanged: onChanged,
          onFieldSubmitted: onFieldSubmitted,
          autofocus: autofocus,
          readOnly: readOnly,
          minLines: minLines,
          maxLines: expands ? null : maxLines,
          expands: expands,
          style: expands
              ? ClinicalTypography.bodyMedium.copyWith(color: p.ink)
              : ClinicalTypography.bodyLarge.copyWith(color: p.ink),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, size: 20, color: p.inkMuted)
                : null,
            suffixIcon: voiceInput
                ? Icon(Icons.mic_outlined, size: 20, color: p.inkMuted)
                : suffix,
            alignLabelWithHint: expands,
          ),
        ),
      ],
    );
  }
}

/// Bouton clinique — trois niveaux hiérarchiques.
enum ClinicalButtonLevel { primary, secondary, tertiary }

class ClinicalButton extends StatelessWidget {
  const ClinicalButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.level = ClinicalButtonLevel.primary,
    this.icon,
    this.minWidth,
    this.height = 48,
    this.expanded = true,
    this.loading = false,
    this.disabled = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final ClinicalButtonLevel level;
  final IconData? icon;
  final double? minWidth;
  final double height;
  final bool expanded;
  final bool loading;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final p = _palette(context);
    final isEnabled = !disabled && !loading && onPressed != null;
    final fg = switch (level) {
      ClinicalButtonLevel.primary => p.surfaceElevated,
      ClinicalButtonLevel.secondary => p.brandPrimary,
      ClinicalButtonLevel.tertiary => p.inkMuted,
    };
    final bg = switch (level) {
      ClinicalButtonLevel.primary => p.brandPrimary,
      ClinicalButtonLevel.secondary => Colors.transparent,
      ClinicalButtonLevel.tertiary => Colors.transparent,
    };
    final side = switch (level) {
      ClinicalButtonLevel.primary => null,
      ClinicalButtonLevel.secondary =>
        BorderSide(color: p.borderFocus, width: 1.5),
      ClinicalButtonLevel.tertiary => null,
    };

    final labelWidget = loading
        ? SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2, valueColor: AlwaysStoppedAnimation(fg)),
          )
        : Text(label,
            style: ClinicalTypography.labelLarge.copyWith(color: fg),
            maxLines: 1, overflow: TextOverflow.ellipsis);

    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null && !loading) ...[
          Icon(icon, size: 20, color: fg),
          const SizedBox(width: ClinicalSpacing.sm),
        ],
        Flexible(child: labelWidget),
      ],
    );

    Widget result = AnimatedContainer(
      duration: ClinicalMotion.micro,
      height: height,
      constraints: BoxConstraints(
        minWidth: minWidth ?? (expanded ? double.infinity : 0),
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(ClinicalRadius.button),
        border: side != null ? Border.all(color: side.color, width: side.width) : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(ClinicalRadius.button),
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius: BorderRadius.circular(ClinicalRadius.button),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: ClinicalSpacing.lg),
            child: Center(child: child),
          ),
        ),
      ),
    );

    if (!isEnabled && !loading) {
      result = Opacity(opacity: 0.4, child: result);
    }
    return result;
  }
}

/// Avatar patient — initiales sur fond primaire doux.
class ClinicalAvatar extends StatelessWidget {
  const ClinicalAvatar({
    super.key,
    required this.initials,
    this.size = ClinicalTouchTarget.avatarDefault,
    this.heroTag,
  });

  final String initials;
  final double size;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final p = _palette(context);
    final box = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: p.brandPrimarySoft,
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Text(
        initials,
        style: TextStyle(
          color: p.brandPrimary,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.30,
        ),
      ),
    );
    if (heroTag == null) return box;
    return Hero(tag: heroTag!, child: box);
  }
}

/// Section heading avec action optionnelle.
class ClinicalSectionHeading extends StatelessWidget {
  const ClinicalSectionHeading({
    super.key,
    required this.title,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = _palette(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: ClinicalTypography.titleLarge.copyWith(
              color: p.ink, fontWeight: FontWeight.w500),
          ),
        ),
        if (trailing != null)
          TextButton(onPressed: onTap, child: Text(trailing!)),
      ],
    );
  }
}

/// État vide — message d'accroche.
class ClinicalEmptyState extends StatelessWidget {
  const ClinicalEmptyState({
    super.key,
    required this.title,
    required this.detail,
    this.icon = Icons.folder_open_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String detail;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final p = _palette(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: ClinicalSpacing.huge, horizontal: ClinicalSpacing.xl),
      child: Column(
        children: [
          Icon(icon, color: p.inkSubtle, size: 44),
          const SizedBox(height: ClinicalSpacing.md),
          Text(title,
            style: ClinicalTypography.headlineMedium.copyWith(
              color: p.ink, fontWeight: FontWeight.w600)),
          const SizedBox(height: ClinicalSpacing.sm),
          Text(detail,
            textAlign: TextAlign.center,
            style: ClinicalTypography.bodyMedium.copyWith(
              color: p.inkMuted)),
          if (actionLabel != null) ...[
            const SizedBox(height: ClinicalSpacing.lg),
            ClinicalButton(
              label: actionLabel!,
              onPressed: onAction,
              level: ClinicalButtonLevel.secondary,
              expanded: false,
            ),
          ],
        ],
      ),
    );
  }
}

/// Layout responsive — contenu centré avec largeur max.
class ClinicalLayout extends StatelessWidget {
  const ClinicalLayout({
    super.key,
    required this.child,
    this.maxWidth = 620,
    this.padding = const EdgeInsets.symmetric(
      horizontal: ClinicalSpacing.screenPaddingHorizontal,
      vertical: ClinicalSpacing.screenPaddingVertical),
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Animation d'entrée douce, respecte reduceMotion.
class ClinicalEntrance extends StatelessWidget {
  const ClinicalEntrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.slideOffset = 16,
  });

  final Widget child;
  final Duration delay;
  final double slideOffset;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: ClinicalMotion.standard + delay,
      curve: ClinicalMotion.easeOut,
      builder: (context, progress, child) => Opacity(
        opacity: progress,
        child: Transform.translate(
          offset: Offset(0, slideOffset * (1 - progress)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// Animation en cascade pour les listes.
class ClinicalStaggered extends StatelessWidget {
  const ClinicalStaggered({
    super.key,
    required this.children,
    this.baseDelay = ClinicalMotion.staggerBase,
    this.maxDelay = ClinicalMotion.staggerMax,
  });

  final List<Widget> children;
  final Duration baseDelay;
  final Duration maxDelay;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      return Column(children: children);
    }
    return Column(
      children: [
        for (var i = 0; i < children.length; i++)
          ClinicalEntrance(
            delay: Duration(
              milliseconds: (i * baseDelay.inMilliseconds)
                  .clamp(0, maxDelay.inMilliseconds),
            ),
            child: children[i],
          ),
      ],
    );
  }
}

/// App bar clinique avec titre et actions.
class ClinicalAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ClinicalAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.transparent = false,
  });

  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool transparent;

  @override
  Widget build(BuildContext context) {
    final p = _palette(context);
    return AppBar(
      backgroundColor: transparent ? Colors.transparent : p.background,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: leading,
      title: Text(title,
        style: ClinicalTypography.headlineSmall.copyWith(
          color: p.ink, fontWeight: FontWeight.w600)),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}

/// Bandeau d'information contextuel.
class ClinicalInfoStrip extends StatelessWidget {
  const ClinicalInfoStrip({
    super.key,
    required this.icon,
    required this.text,
    this.variant = ClinicalStripVariant.info,
  });

  final IconData icon;
  final String text;
  final ClinicalStripVariant variant;

  @override
  Widget build(BuildContext context) {
    final p = _palette(context);
    final (bg, fg) = switch (variant) {
      ClinicalStripVariant.info => (p.brandPrimarySoft, p.brandPrimary),
      ClinicalStripVariant.warning => (p.accentAmberSoft, p.accentAmber),
      ClinicalStripVariant.critical => (p.criticalSoft, p.critical),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ClinicalSpacing.md, vertical: ClinicalSpacing.md),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(ClinicalRadius.sm),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: fg),
          const SizedBox(width: ClinicalSpacing.sm),
          Expanded(
            child: Text(text,
              style: ClinicalTypography.bodyMedium.copyWith(color: p.ink)),
          ),
        ],
      ),
    );
  }
}

enum ClinicalStripVariant { info, warning, critical }