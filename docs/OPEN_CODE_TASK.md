# MediSuivi · Mission OpenCode

**Identifiant :** MS-V1-PERSIST-01  
**Statut :** À préparer, **implémentation uniquement sur validation explicite**  
**Périmètre :** Persistance locale sécurisée Android/iOS, phase 1  
**Branche de code envisagée :** `feat/v1-secure-persistence` (à créer depuis
`main` lorsqu'elle est à jour, sans perdre les modifications locales).

> Ce fichier est un cahier de mission, pas une commande d'exécution autonome.
> L'agent doit appliquer `AGENTS.md` et attendre le feu vert de l'utilisateur.

## Contexte vérifié

- L'interface Flutter existe : accueil, patients, consultations, examens,
  rendez-vous/suivis et formulaires.
- `lib/core/state/demo_store.dart` est une source de données **en mémoire**,
  appuyée par `lib/core/data/demo_data.dart` (données fictives).
- `lib/core/offline/contracts.dart` ne décrit que des interfaces futures.
- Un diagnostic précédent signalait `pubspec.lock` comme modifié localement :
  vérifier avant d'agir. Le dépôt distant ne permet pas de connaître l'état
  de la copie Ubuntu.
- Le dépôt GitHub est public ; **ne jamais y envoyer d'informations médicales
  réelles**.

## Résultat métier recherché

Sur Android et iOS, créer un patient **fictif**, saisir une consultation et un
examen, fermer complètement l'application puis la rouvrir : les enregistrements
doivent être retrouvés, avec leurs relations, sans régression visuelle.

## Phase 1 : objectifs techniques

1. Effectuer un pré-diagnostic de l'état Git, du SDK Flutter et des modèles
   utilisés. Proposer une branche isolée et préserver les modifications.
2. Vérifier les bibliothèques et versions réellement compatibles avec le SDK,
   Android et iOS. Évaluer **Drift + SQLite chiffré** (notamment l'intégration
   moderne SQLite3MultipleCiphers), `flutter_secure_storage` et leurs limites.
   **Ne pas installer par réflexe des dépendances obsolètes.**
3. Mettre en œuvre, **après validation**, une base locale effectivement chiffrée,
   des tables et repositories/DAO pour patients, consultations, constantes,
   examens, résultats et suivis ; documenter les migrations.
4. Remplacer la source de données mémoire par un store persistant aux contrats
   compatibles avec l'interface, en conservant navigation et écrans existants.
5. Conserver les jeux de démonstration fictifs séparés des nouvelles données
   utilisateur ; éviter toute duplication de données au redémarrage.
6. Préparer les identifiants UUID, une politique explicite UTC/fuseaux et une
   structure pouvant accueillir ultérieurement une outbox transactionnelle,
   **sans activer de réseau ni supposer la synchronisation disponible**.
7. Maintenir sur Web un mode de démonstration fictif et non persistant ; aucune
   donnée de santé réelle dans le navigateur.

## Hors périmètre de cette phase

- Écran de connexion et biométrie (phase 2, à définir séparément).
- Sync FastAPI / PostgreSQL, résolution de conflits et stockage distant.
- Effacement d'urgence automatique.
- Refonte graphique, nouveaux écrans, nouveaux contenus médicaux.
- Déploiement public, certification ou exploitation avec de vrais patients.

## Contraintes bloquantes

- Ne pas toucher directement à `main` ni supprimer les changements en cours.
- Aucun `git push` ni merge sans autorisation distincte.
- Aucune clé cryptographique codée en dur, divulguée dans les logs ou Git.
- Ne pas prétendre qu'une bibliothèque garantit le chiffrement : vérifier
  l'ouverture avec la bonne clé, l'échec avec une clé incorrecte et l'absence
  de données fictives lisibles en clair dans le fichier SQLite.
- Ne jamais effacer automatiquement des dossiers ou clés après échec d'accès.
- Sur iOS, distinguer ce qui a été effectivement testé de ce qui reste à
  valider sur macOS/Xcode.
- Aucune donnée réelle dans les fixtures ou messages envoyés aux modèles IA.

## Critères d'acceptation et preuves attendues

- [ ] Branche dédiée créée avec état Git initial communiqué.
- [ ] Dépendances choisies et justifiées avec versions/compatibilité vérifiées.
- [ ] CRUD persistant pour tous les modules existants sans changement visuel.
- [ ] Test de redémarrage et de liens entre entités réussi.
- [ ] Test de migration de schéma et de restauration documenté.
- [ ] Chiffrement testé, erreur sur mauvaise clé contrôlée.
- [ ] `flutter analyze` et `flutter test` : résultats exacts transmis.
- [ ] Fonctionnement mobile Android vérifié sur appareil ou limite signalée.
- [ ] État du support iOS documenté, sans prétendre l'avoir exécuté sur Ubuntu.
- [ ] Inventaire précis des fichiers modifiés et risques résiduels.

## Rapport à fournir après exécution autorisée

Présenter un résumé des changements, le diff/liste de fichiers, les commandes
lancées, les tests (succès/échec/non exécutés), la preuve de persistance et
de chiffrement, les limites de la plateforme, et les prochaines étapes.
**S'arrêter à la fin de la phase 1 et attendre validation.**

## Première instruction à l'agent

« Lis `AGENTS.md` et `docs/OPEN_CODE_TASK.md` en entier. Vérifie la branche,
les changements locaux et l'environnement Flutter. Résume ton plan et les
risques **sans modifier de fichiers ni lancer de migration**. Attends ma
validation avant de commencer la phase 1. »
