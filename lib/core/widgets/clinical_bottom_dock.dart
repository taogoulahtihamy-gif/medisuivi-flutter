import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Dock flottant translucide. Cinq destinations, sans bouton de création.
/// Sélection en pastille verte ; l'animation respecte Reduce Motion.
class ClinicalBottomDock extends StatelessWidget {
  const ClinicalBottomDock({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 9),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              key: const Key('clinical-dock-glass'),
              filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
              child: Container(
                key: const Key('clinical-bottom-dock'),
                height: 64 +
                    (MediaQuery.textScalerOf(context).scale(11) - 11)
                        .clamp(0, double.infinity),
                padding: const EdgeInsets.fromLTRB(6, 5, 6, 5),
                decoration: BoxDecoration(
                  color:
                      p.raisedSurface.withValues(alpha: p.isDark ? .79 : .97),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: p.border.withValues(alpha: p.isDark ? .78 : .48)),
                  boxShadow: [
                    BoxShadow(
                      color: p.ink.withValues(alpha: p.isDark ? .18 : .10),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _DockItem(
                      index: 0,
                      selectedIndex: selectedIndex,
                      label: 'Accueil',
                      onSelected: onSelected,
                      icon: Icons.home_outlined,
                      selectedIcon: Icons.home_rounded,
                    ),
                    _DockItem(
                      index: 1,
                      selectedIndex: selectedIndex,
                      label: 'Patients',
                      onSelected: onSelected,
                      icon: Icons.people_outline_rounded,
                      selectedIcon: Icons.people_rounded,
                    ),
                    _DockItem(
                      index: 2,
                      selectedIndex: selectedIndex,
                      label: 'Bilans',
                      onSelected: onSelected,
                      icon: Icons.biotech_outlined,
                      selectedIcon: Icons.biotech_rounded,
                    ),
                    _DockItem(
                      index: 3,
                      selectedIndex: selectedIndex,
                      label: 'Suivi',
                      onSelected: onSelected,
                      icon: Icons.event_note_outlined,
                      selectedIcon: Icons.event_note_rounded,
                    ),
                    _DockItem(
                      index: 4,
                      selectedIndex: selectedIndex,
                      label: 'Réglages',
                      onSelected: onSelected,
                      icon: Icons.settings_outlined,
                      selectedIcon: Icons.settings_rounded,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  const _DockItem({
    required this.index,
    required this.selectedIndex,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.onSelected,
  });

  final int index;
  final int selectedIndex;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final active = index == selectedIndex;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 200);

    return Expanded(
      child: Semantics(
        selected: active,
        button: true,
        label: label,
        child: Tooltip(
          message: label,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: Key('dock-${label.toLowerCase()}'),
              borderRadius: BorderRadius.circular(18),
              onTap: () => onSelected(index),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedSlide(
                    key: Key('dock-lift-${label.toLowerCase()}'),
                    offset: active ? const Offset(0, -.035) : Offset.zero,
                    duration: duration,
                    curve: Curves.easeOutCubic,
                    child: AnimatedScale(
                      scale: active ? 1.04 : 1,
                      duration: duration,
                      curve: Curves.easeOutCubic,
                      child: AnimatedContainer(
                        duration: duration,
                        curve: Curves.easeOutCubic,
                        width: 48,
                        height: 30,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: active
                              ? p.tealSoft.withValues(alpha: .94)
                              : Colors.transparent,
                          boxShadow: active
                              ? [
                                  BoxShadow(
                                      color: p.ink.withValues(
                                          alpha: p.isDark ? .12 : .06),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3)),
                                ]
                              : null,
                        ),
                        child: Icon(
                          active ? selectedIcon : icon,
                          size: 22,
                          color: active ? p.forest : p.muted,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: active ? p.forest : p.muted,
                      fontSize: 11,
                      height: 1.15,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
