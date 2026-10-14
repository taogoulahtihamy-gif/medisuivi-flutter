import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/medisuivi_app.dart';
import '../../features/auth/dev_auth_api.dart';
import 'remote_clinical_store.dart';

/// The original MainShell stays intact and is fed by a practitioner-owned
/// ClinicalStore. No DemoScope / DemoStore is mounted in connected mode.
class RemoteClinicalScope extends InheritedNotifier<RemoteClinicalStore> {
  const RemoteClinicalScope({
    super.key,
    required RemoteClinicalStore store,
    required this.practitioner,
    required this.signOut,
    required super.child,
  }) : super(notifier: store);

  final DevPractitioner practitioner;
  final Future<void> Function() signOut;

  static RemoteClinicalScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RemoteClinicalScope>();

  static RemoteClinicalStore of(BuildContext context) {
    final scope = maybeOf(context);
    if (scope?.notifier == null) {
      throw StateError('Coffre clinique authentifié indisponible.');
    }
    return scope!.notifier!;
  }
}

class RemoteClinicalGateway extends StatefulWidget {
  const RemoteClinicalGateway({
    super.key,
    required this.api,
    required this.session,
    required this.onSignedOut,
  });

  final DevAuthApi api;
  final DevSession session;
  final VoidCallback onSignedOut;

  @override
  State<RemoteClinicalGateway> createState() => _RemoteClinicalGatewayState();
}

class _RemoteClinicalGatewayState extends State<RemoteClinicalGateway> {
  late final RemoteClinicalStore _store;
  bool _ready = false;
  bool _loading = true;
  bool _signingOut = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _store = RemoteClinicalStore(api: widget.api, session: widget.session);
    unawaited(_load());
  }

  Future<void> _load() async {
    if (!widget.session.isActive) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _store.reload();
      if (mounted && widget.session.isActive) {
        setState(() => _ready = true);
      }
    } catch (_) {
      // No fallback to DemoStore and no stale data from a previous account.
      if (mounted) {
        setState(() {
          _ready = false;
          _error = 'Impossible de charger vos dossiers. Vérifiez la connexion.';
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    if (_signingOut) return;
    setState(() => _signingOut = true);
    // Lock the in-memory clinical store BEFORE the first network request.
    _store.lock();
    try {
      await widget.api.signOut(widget.session);
    } catch (_) {
      // The client clears its tokens even if the API is unreachable.
    } finally {
      widget.session.clear();
      if (mounted) widget.onSignedOut();
    }
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.session.isActive) {
      return const Scaffold(body: Center(
        child: Text('Session expirée. Reconnectez-vous.'),
      ));
    }
    if (!_ready) {
      return Scaffold(
        key: const Key('remote-clinical-loading'),
        body: SafeArea(child: Center(
          child: Padding(
            padding: const EdgeInsets.all(26),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (_loading) const CircularProgressIndicator(),
              if (_error != null) ...[
                const Icon(Icons.wifi_off_outlined, size: 36),
                const SizedBox(height: 15),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 18),
                FilledButton.icon(
                  key: const Key('remote-clinical-retry'),
                  onPressed: _load,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Réessayer'),
                ),
                TextButton(
                  key: const Key('remote-clinical-change-user'),
                  onPressed: _signOut,
                  child: const Text('Changer de praticien'),
                ),
              ],
            ]),
          ),
        )),
      );
    }

    return RemoteClinicalScope(
      store: _store,
      practitioner: widget.session.practitioner,
      signOut: _signOut,
      child: const MainShell(key: Key('original-connected-shell')),
    );
  }
}
