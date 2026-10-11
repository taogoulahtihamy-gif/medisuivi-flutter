# Architecture Offline First : conception (non implémentée dans V0)

## Principe

La base de données locale chiffrée est la source des écrans. Toute modification validée est inscrite **atomiquement** dans la table métier et dans une **outbox**. L'absence de réseau n'interrompt pas la consultation d'un dossier déjà présent sur l'appareil.

```text
Formulaire Flutter
      │
      ▼
Repository (unique point d'écriture)
      │ transaction locale
      ├── tables patients / consultations / constantes / examens
      └── outbox {operation_id, entity_id, base_revision, payload, action, created_at}
                        │
                        ▼
               Sync Engine (file FIFO)
                        │ HTTPS authentifié
                        ▼
           API FastAPI + PostgreSQL
                        │
              delta / since_cursor
                        ▼
            transaction locale de pull
```

## Règles imposées

1. Identifiants UUID uniques créés sur l'appareil pour éviter les collisions.
2. Push idempotent par `operation_id`; pas de perte après redémarrage.
3. Accusé de réception transactionnel, gestion des tentatives et temporisation exponentielle.
4. Téléchargement des changements distants avec curseur et pagination.
5. Pas de politique naïve *last-write-wins* sur données cliniques. Les observations signées et examens validés sont non destructifs (correction tracée) ; une modification concurrente incompatible exige une résolution explicite.
6. Affichage précis : `Hors ligne`, `À envoyer`, `En cours`, `À jour`, `Échec`, `Conflit`.
7. Pièces jointes chiffrées, dédupliquées, téléchargées séparément avec confirmation d'intégrité.
8. Authentification initiale en ligne ; sessions locales à durée limitée ; possibilité de verrouiller l'app en situation hors ligne.
9. Expiration et révocation des clés avec procédure de récupération documentée ; restauration sans écrasement de l'historique.
10. Synchronisation au premier plan, au retour en réseau et lors des tâches de fond autorisées par iOS/Android. Les systèmes peuvent différer l'exécution : ne jamais promettre une sync immédiate en arrière-plan.

## Tables futures

`patients`, `consultations`, `observations`, `prescriptions`, `lab_orders`, `lab_results`, `attachments`, `audit_events`, `outbox`, `sync_cursors`, `device_state`.

## Critères d'acceptation

- Après 24 h sans réseau, les consultations fictives restent accessibles même après redémarrage.
- Envois répétés sans création de doublons.
- Interruption réseau pendant la synchronisation puis reprise sans perte.
- Modifications concurrentes détectées et traitées sans suppression silencieuse.
- Aucune donnée de patient lisible sur un appareil verrouillé, sauvegarde non chiffrée ou journal de debug.

Cette V0 ne satisfait pas encore ces critères.
