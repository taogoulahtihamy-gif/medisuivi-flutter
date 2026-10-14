import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/state/connected_clinical_store.dart';
import 'dev_auth_api.dart';

/// Thin authenticated data boundary around the UNCHANGED original MainShell.
/// This is not a second dashboard: the child is the original MediSuivi UI.
class OriginalConnectedClinicalGate extends StatefulWidget {
  const OriginalConnectedClinicalGate({
    super.key,
    required this.api,
    required this.session,
    required this.onSignedOut,
    required this.child,
  });

  final DevAuthApi api;
  final DevSession session;
  final VoidCallback onSignedOut;
  final Widget child;

  @override
  State<OriginalConnectedClinicalGate> createState() =>
      _OriginalConnectedClinicalGateState();
}

class _OriginalConnectedClinicalGateState
    extends State<OriginalConnectedClinicalGate> {
  late ConnectedClinicalStore _store;
  late Future<void> _ready;
  bool _signingOut = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  void _initialize() {
    _store = ConnectedClinicalStore(widget.api, widget.session);
    _ready = _store.refresh();
  }

  @override
  void didUpdateWidget(covariant OriginalConnectedClinicalGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.session, widget.session) ||
        oldWidget.api != widget.api) {
      _store.lock();
      _store.dispose();
      _signingOut = false;
      _initialize();
    }
  }

  @override
  void dispose() {
    _store.lock();
    _store.dispose();
    super.dispose();
  }

  Future<void> _signOut() async {
    if (_signingOut) return;
    setState(() => _signingOut = true);
    // Fail closed immediately: previous records must vanish before the
    // network attempt to revoke the JWT, even if network is unavailable.
    _store.lock();
    try {
      await widget.api.signOut(widget.session);
    } catch (_) {
      widget.session.clear();
    } finally {
      if (mounted) widget.onSignedOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _ready,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            key: Key('original-connected-loading'),
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || !_store.active) {
          return Scaffold(
            key: const Key('original-connected-error'),
            body: SafeArea(child: Center(child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_outlined, size: 38),
                  const SizedBox(height: 17),
                  const Text('Dossiers indisponibles pour ce compte.'),
                  const SizedBox(height: 15),
                  FilledButton(
                    key: const Key('original-connected-retry'),
                    onPressed: _signingOut ? null : () {
                      setState(() => _ready = _store.refresh());
                    },
                    child: const Text('Réessayer'),
                  ),
                  TextButton(
                    key: const Key('original-connected-signout-error'),
                    onPressed: _signingOut ? null : _signOut,
                    child: const Text('Changer de praticien'),
                  ),
                ],
              ),
            ))),
          );
        }
        // ConnectedClinicalScope takes precedence over the outer DemoScope.
        // The original widgets continue to use context.store as before.
        return ConnectedClinicalScope(
          store: _store,
          child: Stack(children: [
            widget.child,
            Positioned(
              top: MediaQuery.paddingOf(context).top + 6,
              right: 3,
              child: Material(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(26),
                child: IconButton(
                  key: const Key('original-connected-signout'),
                  tooltip: 'Changer de praticien',
                  onPressed: _signingOut ? null : _signOut,
                  icon: const Icon(Icons.logout_rounded, size: 18),
                ),
              ),
            ),
          ]),
        );
      },
    );
  }
}
