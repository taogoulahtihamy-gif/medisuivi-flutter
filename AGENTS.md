# AGENTS.md · Instructions de travail pour OpenCode

Ce document définit les règles permanentes applicables aux agents IA travaillant
dans le dépôt **MediSuivi**. Lire également `docs/OPEN_CODE_TASK.md` avant toute
nouvelle mission et demander confirmation si la mission est ambiguë.

## 1. Produit et périmètre

- MediSuivi est une application Flutter **personnelle pour une professionnelle
  de santé**, et non un ERP hospitalier.
- Cibles : Android et iOS. Le navigateur reste un environnement **de
  démonstration avec données intégralement fictives** tant que ses garanties de
  sécurité n'ont pas été évaluées.
- Version actuelle : prototype V0.5, modèles et formulaires fonctionnels,
  données fictives stockées dans `DemoStore` en mémoire. **Aucune exploitation
  clinique réelle n'est autorisée.**
- Architecture et contraintes de référence : `README.md`,
  `docs/ARCHITECTURE.md`, `docs/OFFLINE_SYNC.md`,
  `docs/SECURITY.md`, `docs/BACKEND_V1.md`,
  `docs/DESIGN_SYSTEM.md` et `docs/ROADMAP.md`.
- En cas de divergence entre un document historique et les composants actuels,
  examiner d'abord `lib/app/theme.dart` et les écrans existants, puis signaler
  la divergence ; ne pas changer le design de sa propre initiative.

## 2. Méthode de travail et autorisations

1. Lire la mission active, vérifier `git status -sb`, la branche et les
   modifications non commitées **avant** toute intervention.
2. Pour toute demande d'analyse : ne changer aucun fichier, ne supprimer aucun
   fichier, ne créer ni commit ni push.
3. Pour toute demande d'implémentation : expliquer la portée, les dépendances,
   les risques et les critères d'acceptation ; attendre l'autorisation explicite
   de l'utilisateur pour la phase concernée.
4. Travailler sur une branche dédiée. **Ne jamais modifier directement
   `main`** ; ne pas utiliser `git reset --hard`, `git clean -fd`,
   `git push --force`, ni écraser une modification locale.
5. **Ne jamais faire `git push`, fusionner une branche, publier une release,
   ni changer la visibilité du dépôt sans accord explicite.**
6. Une modification de `pubspec.lock` était déjà présente lors du diagnostic
   du 12/10/2026 : vérifier son état réel, la conserver, expliquer son origine
   si possible et ne pas la restaurer/supprimer automatiquement.
7. Procéder par étapes réduites et vérifiables. En fin d'étape : indiquer les
   fichiers changés, les tests réellement exécutés, leurs résultats, les
   limitations et les points en attente de validation. Ne pas inventer de
   résultats ni de garanties de sécurité.

## 3. Architecture et qualité

- Préserver les parcours existants : accueil, patients, dossier patient,
  consultations, constantes vitales, examens/résultats, suivi et rendez-vous.
- Préserver la navigation, les animations, l'accessibilité, les textes,
  typographies et couleurs actuels sauf demande visuelle explicite.
- Garder le découpage `lib/app`, `lib/core`, `lib/features` ; privilégier
  les évolutions compatibles plutôt qu'une refonte.
- Séparer UI, état, règles métier et accès aux données. Prévoir les migrations
  de schéma et les tests de non-régression.
- Les identifiants métier nouveaux doivent être non prédictibles (UUID).
  Normaliser les instants de stockage en UTC, en conservant l'information de
  fuseau nécessaire pour les rendez-vous.
- Les corrections de faits cliniques validés doivent être traçables : ne jamais
  écraser silencieusement un historique clinique.
- Préparer une architecture offline-first ; **pas de synchronisation distante
  ni de backend supposé opérationnel tant qu'ils ne le sont pas**.
- Pour les conflits de données cliniques, ne pas employer un
  « last-write-wins » silencieux.

## 4. Confidentialité et sécurité : règles impératives

- **Aucune donnée patient réelle** dans ce prototype, le dépôt public, les
  fichiers de test, les traces, les outils IA, les tickets ou les commits.
  N'utiliser que des cas synthétiques et anonymes.
- Ne jamais lire, afficher, transmettre ou versionner de secrets si ce n'est
  pas indispensable à la tâche. Ne jamais publier `.env`, clés, bases locales
  ou documents cliniques. Vérifier `.gitignore` et les fichiers indexés.
- Les données médicales persistantes sur mobile exigent une base chiffrée et
  une gestion sûre des clés ; le simple ajout d'une bibliothèque ne prouve pas
  que le chiffrement fonctionne.
- Les garanties de Keystore/Keychain, d'accès biométrique et de protection
  matérielle varient selon les appareils et configurations. Les qualifier par
  plateforme et tester sur appareil lorsque possible.
- **Interdiction d'effacer automatiquement la base ou la clé** après des
  échecs de PIN/biométrie. Prévoir verrouillage/récupération sécurisés, ainsi
  qu'une stratégie de sauvegarde/restauration à définir avant usage réel.
- Ne pas sauvegarder de données médicales non chiffrées sur le Web ; mode Web
  limité à la démonstration avec données fictives.
- Aucune affirmation de conformité légale, de certification ou de
  « prêt pour les vrais patients » sans audit et validation externe.

## 5. Validation et livraison

Quand Flutter est disponible, privilégier :
```bash
flutter pub get
flutter analyze
flutter test
```

Ajouter les tests appropriés à chaque fonctionnalité. Pour la persistance :
tests de redémarrage, migrations, clé incorrecte, preuve vérifiable que les
données sensibles ne sont pas lisibles en clair, et scénarios de restauration.
Compléter les vérifications sur Android physique et iOS quand leur
environnement est disponible. Si un test est impossible, le signaler.

**Instruction d'entrée :** lire `docs/OPEN_CODE_TASK.md`, reformuler la mission,
indiquer la branche et l'état Git ; ne démarrer l'implémentation qu'après
l'autorisation explicite de l'utilisateur.
