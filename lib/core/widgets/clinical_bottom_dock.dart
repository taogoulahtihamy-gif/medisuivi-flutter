import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../../app/theme.dart';

/// Navigation clinique compacte : cinq destinations conservées et une
/// création rapide accessible. Animations réduites si demandé par le système.
class ClinicalBottomDock extends StatelessWidget {
  const ClinicalBottomDock({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.onCreate,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final isIos = Theme.of(context).platform == TargetPlatform.iOS;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(10, 0, 10, 9),
      child: Center(heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 550),
          child: Container(
            key: const Key('clinical-bottom-dock'),
            height: 71,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
            decoration: BoxDecoration(
              color: p.raisedSurface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: p.border),
              boxShadow: [
                BoxShadow(
                  color: p.ink.withValues(alpha: p.isDark ? .22 : .10),
                  blurRadius: 20, offset: const Offset(0, 5)),
              ],
            ),
            child: Row(children: [
              _DockItem(
                index: 0, selectedIndex: selectedIndex,
                label: 'Accueil', onSelected: onSelected,
                icon: isIos ? CupertinoIcons.house : Icons.home_outlined,
                selectedIcon: Icons.home_rounded),
              _DockItem(
                index: 1, selectedIndex: selectedIndex,
                label: 'Patients', onSelected: onSelected,
                icon: Icons.people_outline_rounded,
                selectedIcon: Icons.people_rounded),
              _DockCreate(onPressed: onCreate),
              _DockItem(
                index: 2, selectedIndex: selectedIndex,
                label: 'Bilans', onSelected: onSelected,
                icon: Icons.biotech_outlined,
                selectedIcon: Icons.biotech_rounded),
              _DockItem(
                index: 3, selectedIndex: selectedIndex,
                label: 'Suivi', onSelected: onSelected,
                icon: Icons.event_note_outlined,
                selectedIcon: Icons.event_note_rounded),
              _DockItem(
                index: 4, selectedIndex: selectedIndex,
                label: 'Réglages', onSelected: onSelected,
                icon: Icons.tune_rounded,
                selectedIcon: Icons.settings_rounded),
            ]),
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
        ? Duration.zero : const Duration(milliseconds: 260);
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
              borderRadius: BorderRadius.circular(20),
              onTap: () => onSelected(index),
              child: AnimatedContainer(
                duration: duration,
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: active ? p.tealSoft : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedScale(
                      scale: active ? 1.12 : .95,
                      duration: duration,
                      curve: Curves.easeOutBack,
                      child: Icon(
                        active ? selectedIcon : icon,
                        size: 21, color: active ? p.forest : p.muted,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(label,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: active ? p.forest : p.muted,
                        fontSize: 9.5,
                        height: 1.1,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      ),
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

class _DockCreate extends StatefulWidget {
  const _DockCreate({required this.onPressed});
  final VoidCallback onPressed;

  @override
  State<_DockCreate> createState() => _DockCreateState();
}

class _DockCreateState extends State<_DockCreate> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero : ClinicalMotion.micro;
    return Expanded(
      child: Center(
        child: Semantics(
          button: true,
          label: 'Créer un patient',
          child: Tooltip(
            message: 'Nouveau patient',
            child: AnimatedScale(
              duration: duration,
              curve: Curves.easeOutBack,
              scale: _pressed ? .87 : 1,
              child: Material(
                color: p.isDark
                    ? ClinicalColors.darkActionFill
                    : ClinicalColors.lightActionFill,
                shape: const CircleBorder(),
                child: InkWell(
                  key: const Key('dock-create-patient'),
                  customBorder: const CircleBorder(),
                  onTapDown: (_) => setState(() => _pressed = true),
                  onTapCancel: () => setState(() => _pressed = false),
                  onTapUp: (_) => setState(() => _pressed = false),
                  onTap: widget.onPressed,
                  child: const SizedBox(
                    width: 49, height: 49,
                    child: Icon(Icons.add_rounded,
                      size: 27, color: ClinicalColors.actionOnDarkFill),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
