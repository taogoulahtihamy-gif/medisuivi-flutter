import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:medisuivi/core/persistence/account_scoped_vault.dart';

const alice = '1a2a3361-ed2e-4abe-8e55-661bac905148';
const bob = '5b60b4f7-3af3-49de-9d25-69d25712e1c5';

class FakeStore {
  FakeStore(this.owner);
  final String owner;
  bool closed = false;
}

class FakeBackend implements AccountVaultBackend<FakeStore> {
  final opened = <FakeStore>[];
  bool failOpen = false;
  bool failClose = false;

  @override
  Future<FakeStore> openFor(String ownerUserId) async {
    if (failOpen) throw StateError('key unavailable');
    final store = FakeStore(ownerUserId);
    opened.add(store);
    return store;
  }

  @override
  Future<void> close(FakeStore store) async {
    if (failClose) throw StateError('close failed');
    store.closed = true;
  }
}

void main() {
  test('owner UUID is validated and opaque file names differ', () {
    expect(() => AccountVaultIdentity.requireServerUuid('../legacy.db'),
        throwsArgumentError);
    expect(() => AccountVaultIdentity.requireServerUuid('demo'),
        throwsArgumentError);
    expect(AccountVaultIdentity.databaseFilename(alice),
        isNot(AccountVaultIdentity.databaseFilename(bob)));
    expect(AccountVaultIdentity.keyAlias(alice),
        isNot(AccountVaultIdentity.keyAlias(bob)));
    expect(AccountVaultIdentity.databaseFilename(alice),
        isNot('medisuivi.db'));
  });

  test('switch closes A before opening B and refuses cross-account use',
      () async {
    final backend = FakeBackend();
    final vault = AccountScopedVault<FakeStore>(backend);
    await vault.activate(alice);
    final first = await vault.use(alice, (store) async => store);
    expect(() => vault.use(bob, (store) async => store), throwsStateError);
    await vault.activate(bob);
    expect(first.closed, isTrue);
    expect(await vault.use(bob, (store) async => store.owner), bob);
    await expectLater(vault.use(alice, (store) async => store),
        throwsStateError);
    await vault.dispose();
  });

  test('failed close locks vault and never opens another account', () async {
    final backend = FakeBackend();
    final vault = AccountScopedVault<FakeStore>(backend);
    await vault.activate(alice);
    backend.failClose = true;
    await expectLater(vault.activate(bob), throwsStateError);
    expect(vault.activeOwner, isNull);
    expect(backend.opened.length, 1);
    await expectLater(vault.use(alice, (store) async => store),
        throwsStateError);
    await expectLater(vault.use(bob, (store) async => store),
        throwsStateError);
    backend.failClose = false;
    await vault.dispose();
  });

  test('missing encryption key fails closed with no legacy fallback',
      () async {
    final backend = FakeBackend()..failOpen = true;
    final vault = AccountScopedVault<FakeStore>(backend);
    await expectLater(vault.activate(alice), throwsStateError);
    expect(vault.activeOwner, isNull);
    expect(backend.opened, isEmpty);
    await vault.dispose();
  });

  test('queued switch waits for in-flight A operation', () async {
    final backend = FakeBackend();
    final vault = AccountScopedVault<FakeStore>(backend);
    await vault.activate(alice);
    final release = Completer<void>();
    final entered = Completer<void>();
    final operation = vault.use(alice, (store) async {
      entered.complete();
      await release.future;
      expect(store.closed, isFalse);
      return store.owner;
    });
    await entered.future;
    final switchFuture = vault.activate(bob);
    expect(backend.opened.length, 1);
    release.complete();
    expect(await operation, alice);
    await switchFuture;
    expect(backend.opened.first.closed, isTrue);
    expect(vault.activeOwner, bob);
    await vault.dispose();
  });

  test('lock and dispose deny subsequent access', () async {
    final backend = FakeBackend();
    final vault = AccountScopedVault<FakeStore>(backend);
    await vault.activate(alice);
    await vault.lock();
    expect(vault.activeOwner, isNull);
    await expectLater(vault.use(alice, (store) async => store),
        throwsStateError);
    await vault.dispose();
    await expectLater(vault.activate(bob), throwsStateError);
  });
}
