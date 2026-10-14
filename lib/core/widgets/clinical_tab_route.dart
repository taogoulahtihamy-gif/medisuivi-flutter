import 'package:flutter/material.dart';

/// Adapts one of the ORIGINAL navigation-tab bodies to a full route.
///
/// PatientsScreen, ExamsScreen and FollowupScreen are intentionally
/// scaffold-free because MainShell embeds them under its own Scaffold.
/// Detail/settings shortcuts must NOT push those bodies naked: TextField,
/// InkWell, chips, and dialogs need a Material ancestor on a new route.
///
/// This wrapper changes no layout inside the original tab content.
class ClinicalTabRoute extends StatelessWidget {
  const ClinicalTabRoute({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
        key: const Key('clinical-tab-route-scaffold'),
        appBar: AppBar(title: Text(title)),
        body: SafeArea(child: child),
      );
}
