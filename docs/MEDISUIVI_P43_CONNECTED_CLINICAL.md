# Sprint P4.3 : parcours clinique connecté au backend FastAPI

## État et portée

Cette PR complète **le parcours de test avec données strictement synthétiques**.
La connexion côté Flutter et l'API clinique FastAPI existaient depuis P3.3,
mais elles ne suffisaient pas à démontrer la persistance et les transferts
entre sessions/appareils. **Ne pas utiliser de vrais dossiers.**

### Fonctionnement connecté

1. Inscrire ou connecter un praticien fictif avec une API de développement.
2. Charger depuis `GET /api/v1/patients` la liste appartenant au JWT.
3. Rechercher un dossier dans les résultats de ce compte (sans cache partagé).
4. Créer un patient fictif à identité générée, sans formulaire de vrai nom.
5. Ouvrir ce dossier et récupérer trois ensembles depuis PostgreSQL :
   `visits`, `exams` et `followups`, tous sous `/patients/{id}`.
6. Saisir des **exemples préremplis** : consultation, constantes standard
   **fictives**, bilan, résultat fictif, suivi à J+7.
7. Reporter un suivi à J+7, l'annuler ou le clôturer via les routes PUT
   authentifiées, puis recharger les réponses serveur.
8. Se déconnecter, rouvrir l'application et vérifier que les dossiers
   n'apparaissent qu'après un nouveau contrôle de session par FastAPI.
9. Se connecter avec le praticien B : il ne peut accéder ni aux dossiers
   ni aux actes appartenant au praticien A.

### Validation automatisée

- Flutter : sérialisation des constantes, interprétation des réponses API
  (dates, statuts, bilans), actions PUT sur suivi.
- Flutter : registre authentifié avec recherche locale des résultats API,
  sans appel aux patients de la démonstration.
- PostgreSQL 17 : test **sur base réelle** (migration Alembic), création
  de dossiers et actes par A, tentatives cross-account par B, fermeture
  des clients HTTP, reconnexion, lecture identique des valeurs persistées,
  report et annulation des suivis.

### Séparation stricte

Les nouveaux écrans ne doivent pas réutiliser `DemoStore` ou l'ancien
`PersistentStore` de données locales. Dans un build mobile avec URL de
développement configurée, P4.2 évite déjà l'ouverture automatique de
`medisuivi.db`, et l'accès aux dossiers reste lié à un jeton serveur signé.
Les exemples cliniques utilisent seulement des valeurs constantes fictives.

### Ce qui reste avant les essais Android réels

- Consolidation technique des PR empilées #22 à #35 puis de cette PR ;
  **aucune fusion dans main sans revue**.
- Intégration des véritables formulaires de santé et validation clinique /
  exigences de conformité. Le serveur actuel refuse `APP_ENV=production`.
- Hébergement de test HTTPS avec identités fictives, provider e-mail réel
  pour les codes, secrets séparés, configuration protectrice et observabilité.
- Test physique Android de la session KeyStore, du réseau, des temps de
  réponse et des ouvertures/fermetures de l'app.
- Stockage hors ligne chiffré par compte, migration des anciens fichiers,
  sauvegardes, tests d'intrusion, revue RGPD/CDP sénégalaise.

**Pas de données de santé réelles, pas de déploiement, pas de fusion main.**
