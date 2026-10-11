import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../app/theme.dart';

class FloatingBottomNavigation extends StatelessWidget {
  const FloatingBottomNavigation(
      {super.key, required this.selected, required this.onSelected});
  final int selected;
  final ValueChanged<int> onSelected;
  @override
  Widget build(BuildContext context) {
    final isIos = Theme.of(context).platform == TargetPlatform.iOS;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: Container(
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Palette.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14072B39),
                  blurRadius: 24,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: IntrinsicHeight(
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                  _NavItem(
                    label: 'Accueil',
                    icon: isIos ? CupertinoIcons.house : Icons.home_outlined,
                    selectedIcon:
                        isIos ? CupertinoIcons.house_fill : Icons.home_rounded,
                    selected: selected == 0,
                    onTap: () => onSelected(0),
                  ),
                  _NavItem(
                    label: 'Patients',
                    icon: isIos
                        ? CupertinoIcons.person_2
                        : Icons.people_outline_rounded,
                    selectedIcon: isIos
                        ? CupertinoIcons.person_2_fill
                        : Icons.people_rounded,
                    selected: selected == 1,
                    onTap: () => onSelected(1),
                  ),
                  _NavItem(
                    label: 'Bilans',
                    icon: isIos
                        ? CupertinoIcons.doc_text
                        : Icons.biotech_outlined,
                    selectedIcon: isIos
                        ? CupertinoIcons.doc_text_fill
                        : Icons.biotech_rounded,
                    selected: selected == 2,
                    onTap: () => onSelected(2),
                  ),
                  _NavItem(
                    label: 'Suivi',
                    icon: isIos
                        ? CupertinoIcons.chart_bar
                        : Icons.insights_outlined,
                    selectedIcon: isIos
                        ? CupertinoIcons.chart_bar_fill
                        : Icons.insights_rounded,
                    selected: selected == 3,
                    onTap: () => onSelected(3),
                  ),
                ])),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        AppMotion.duration(context, AppMotion.micro) == Duration.zero;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: reduceMotion ? Duration.zero : AppMotion.micro,
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color: selected ? Palette.tealSoft : Colors.transparent,
                borderRadius: BorderRadius.circular(19),
              ),
              child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(selected ? selectedIcon : icon,
                          size: 22,
                          color: selected ? Palette.teal : Palette.muted),
                      const SizedBox(height: 4),
                      Text(label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected ? Palette.tealDark : Palette.muted,
                          )),
                    ],
                  )),
            ),
          ),
        ),
      ),
    );
  }
}
