# P4.8 : interface professionnelle connectée

## Constat Firefox

La connexion à FastAPI fonctionnait, mais les comptes authentifiés aboutissaient à la liste technique `DevConnectedWorkspace`, indépendante de la navigation principale en mode démo. Les formulaires d'inscription/connexion avaient un bandeau photographique disproportionné.

**Ne jamais connecter directement `MainShell` et `DemoStore` à un compte serveur.** Ces modules historiques utilisent le stockage clinique de démonstration et risqueraient de montrer des dossiers n'appartenant pas au JWT courant.

## Parcours mis à jour

- Écran d'accès sans photo : identité MediSuivi discrète et actions principales.
- Connexion et inscription dans une carte sobre, sans photographie, avec validation e-mail/mot de passe et signalement d'erreurs conservés.
- Après authentification : vrai **tableau de bord rattaché au compte serveur** avec compteur de dossiers provenant de `GET /api/v1/patients`, accès rapides et dossiers récents.
- **Dossiers** : recherche en mémoire dans la liste du compte, consultation du détail via `DevPatientDetail`, création strictement synthétique.
- **Suivis** : échéances `planned` récupérées via `GET /api/v1/patients/{id}/followups` pour chaque dossier autorisé et triées par date. Cette version de démonstration n'est pas conçue pour des centaines de dossiers ; remplacer l'agrégation par un endpoint serveur paginé avant production.
- **Compte** : consultation du profil, modification, changement de praticien et révocation des sessions.
- Retour d'un détail patient : rechargement des données serveur du praticien authentifié.
- `didUpdateWidget` rejette les anciennes listes/avatar et réinitialise l'interface en cas de changement de session ; les réponses tardives ne doivent pas réapparaître.
- Le mode démonstration sans API conserve son espace local et son onboarding initial.

## Vérification en local Firefox

Le backend existe déjà en Docker : `medisuivi-api-1` sur `127.0.0.1:8027`. **Ne pas reconstruire ou réinitialiser PostgreSQL** pour voir ce changement d'interface.

Préserver le dépôt de travail principal avec un worktree séparé :

```bash
cd /mnt/chak/medisuivi-flutter
git fetch origin feat/medisuivi-p48-clinical-connected-ui
git worktree add --detach /mnt/chak/medisuivi-p48-ui \
  origin/feat/medisuivi-p48-clinical-connected-ui
cd /mnt/chak/medisuivi-p48-ui
flutter pub get
```

Ne pas recréer le worktree s'il existe déjà. Le backend de développement autorise seulement l'origine `http://127.0.0.1:8080` (CORS à liste fermée). Arrêter l'ancien `flutter run` du port 8080 avec `Ctrl+C` dans **son propre terminal** avant le lancement, sans fermer VS Code :

```bash
flutter run -d web-server \
  --web-hostname 127.0.0.1 \
  --web-port 8080 \
  --dart-define=MEDISUIVI_DEV_API_BASE_URL=http://127.0.0.1:8027
```

Ouvrir `http://127.0.0.1:8080` dans Firefox. Garder le terminal Flutter ouvert ; il sert le Web jusqu'à `Ctrl+C`.

## Recette avec données fictives uniquement

1. Vérifier les écrans Accès → Se connecter → Créer un compte en thèmes clair et sombre et sur 320/390 px ; aucune photo ne doit couvrir le formulaire.
2. Se connecter avec un compte de **test** déjà existant. La première page doit être « Accueil », avec un compteur de dossiers serveur et le nom du compte.
3. Naviguer dans `Dossiers` et vérifier recherche, ouverture d'un dossier, consultations, examens et suivi ; revenir sur le tableau de bord.
4. Ouvrir `Suivis` et vérifier uniquement les rendez-vous programmés appartenant à ce compte.
5. Ouvrir `Compte`, puis changer de praticien. Vérifier qu'aucun dossier/avatar de la session précédente n'est conservé.
6. Revenir se connecter : les dossiers appartiennent au même compte API après reconnexion.
7. En cas d'erreur réseau, l'écran doit afficher un échec, jamais les dossiers de démonstration partagés.

**Ne jamais partager de mots de passe, jetons de session ou dossiers médicaux dans les captures et les journaux.** Ce parcours est un staging de tests, pas une application médicale prête pour la production.
