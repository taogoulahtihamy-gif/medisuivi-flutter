# MediSuivi · Sprint 4A — Persistance locale et préparation offline-first

## État du produit

MediSuivi est une application **personnelle** de suivi clinique. Le Web
fonctionne encore avec `DemoStore` en mémoire et uniquement des dossiers fictifs.
Android/iOS disposent d'une base Drift/SQLite3MultipleCiphers et de mécanismes
de clés du système, qui nécessitent une validation sur téléphones physiques.

**Ce sprint ne crée ni backend, ni synchronisation réseau, ni accès clinique
autorisé à des données réelles.**

## Livré : file d'attente atomique

Les opérations métier courantes suivantes écrivent, dans **la même transaction**,
la donnée locale et une ligne `PendingOperations` :

| Entité | Action | Opération outbox |
|---|---|---|
| Patient | Création | `patient:create` |
| Patient | Mise à jour médicale | `patient:update` |
| Patient | Activer/désactiver le suivi | `patient:update` |
| Consultation | Création | `visit:create` |
| Examen | Prescription | `exam:create` |
| Examen | Premier compte rendu | `exam:update` |
| Suivi | Programmation | `followup:create` |
| Suivi | Report | `followup:update` |
| Suivi | Clôture | `followup:update` |

Les opérations reçoivent un UUID et un JSON local conservé **dans la base
chiffrée**. Le champ `baseRevision` est temporairement à `0` : ne jamais
l'utiliser tel quel pour résoudre des conflits avec un serveur. Le backend et
le protocole de révision restent à concevoir avant d'activer un push.

Un résultat d'examen déjà enregistré ne peut plus être écrasé silencieusement
par la méthode de saisie initiale ; une fonction de rectification avec piste
d'audit devra être définie séparément.

## Tests de non-régression ajoutés

1. Création patient → visite → bilan et résultat → suivi et clôture, puis
   **fermeture/réouverture** : les sept opérations attendues restent dans la
   file et les données patient sont toujours présentes.
2. Injection d'une erreur SQLite sur `pending_operations` : la création du
   patient doit être **annulée** et aucun dossier partiel ne subsiste.
3. Les tests existants couvrent le chiffrement, l'ouverture avec une mauvaise
   clé, les flux réactifs et le CRUD local.

## Fonctionnalités non terminées

- **Toutes les mutations** ne sont pas encore connectées à l'outbox :
  `updateVisit`, `updateExam` et les suppressions directes nécessitent une
  stratégie explicite (audit, tombstones, corrections métier) avant activation.
- Aucun `SyncEngine`, aucune API distante et aucune récupération de curseur :
  les opérations restent en attente, même quand le téléphone retrouve Internet.
- Aucune règle de conflit validée : jamais de `last write wins` automatique
  pour les données cliniques.
- La clé mobile, le comportement biométrique et la sauvegarde chiffrée doivent
  être testés sur Android et iOS réels ; les tests CI ne valent pas certification.
- Le choix de thème et le téléchargement éventuel des Google Fonts doivent être
  rendus réellement hors connexion séparément.
- L'autorisation/identité du professionnel, les consentements, la politique de
  conservation, l'export, la sauvegarde et la restauration restent à concevoir
  avant utilisation de dossiers patients réels.

## Prochain incrément proposé : Sprint 4B

1. Fermer les chemins de mutation non journalisés (audit explicite des
   modifications, pas de suppression silencieuse).
2. Implémenter `SyncStatus` purement local : `Hors ligne`,
   `À envoyer`, `Conflit` (uniquement pour états réellement connus).
3. Fiabiliser le chargement réactif des caches et la gestion des erreurs
   d'écriture en UI ; ne jamais afficher `enregistré` avant confirmation DB.
4. Ajouter tests d'interruption/reprise, redémarrage et non-régression
   médicaments/examens sur données fictives.
5. Préparer contrat API versionné et stratégie de conflits, **sans connecter
   un serveur tant que l'authentification et l'autorisation ne sont pas prêtes**.

## Critères de validation

- Analyse statique sans erreur ni avertissement bloquant.
- Tous les tests réussis, y compris la persistance après redémarrage et
  le rollback transactionnel.
- Compilation Flutter Web release réussie.
- Contrôle de la branche GitHub ; aucune fusion avec `main`.
- Tests sur Android et iOS physiques requis avant usage hors ligne opérationnel.
