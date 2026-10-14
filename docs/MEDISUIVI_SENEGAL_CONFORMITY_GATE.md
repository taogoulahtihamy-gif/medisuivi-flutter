# MediSuivi Sénégal : verrou juridique et sécurité (P0)

Date de référence : 14 octobre 2026. **Document de cadrage, pas un avis juridique ni une autorisation de la CDP.**

## Textes vérifiés

- Loi sénégalaise n° 2008-12 du 25 janvier 2008 relative à la protection des données personnelles :
  https://www.cdp.sn/legislation/textes-legislatifs
  https://senlii.org/en/akn/sn/act/2008/12/fra%402008-05-03
- Décret d'application n° 2008-721 du 30 juin 2008 :
  https://www.cdp.sn/legislation/textes-reglementaires

### Points pertinents à confirmer dans le cadre du projet

- Article 4 : les données relatives à la santé sont des **données personnelles sensibles**.
- Articles 40, 41 et 43 : encadrement du traitement des données sensibles et conditions de légitimité des traitements de santé ; l'article 43 énumère plusieurs situations, dont les soins sous surveillance professionnelle et le consentement. **Ne pas supposer que le consentement est toujours la seule base possible**.
- Articles 18 à 22 : formalités préalables à qualifier selon l'activité exacte. L'article 20 mentionne notamment les données génétiques et la recherche en santé ; **ne pas affirmer que tout dossier médical exige automatiquement une autorisation au titre de cet article**. La CDP doit déterminer régime et formalités applicables.
- Articles 49 à 51 : conditions et formalités de transferts de données vers un pays tiers. **Ne pas affirmer sans examen une obligation générale de stockage exclusivement au Sénégal**.
- Articles 58 et suivants : information des personnes concernées et exercice de leurs droits.

## Décisions de conception avant lancement

1. Marché principal : **Sénégal**. Interface initialement en français ; supports adaptés au pays (dates, téléphone +221).
2. Compte individuel V1 : un praticien par compte ; les dossiers cliniques sont strictement privés. Partage éventuel entre cabinets **hors périmètre**, futur mécanisme explicite de permissions.
3. Définir responsable de traitement, sous-traitants, modalités d'information patients, finalités, données indispensables et rétention.
4. Contacter la CDP pour qualifier la formalité requise, fournir identité responsable, finalité, sécurité, catégories, stockage et transferts.
5. Choisir ensuite l'hébergeur, la **région effective des données**, les sauvegardes, les accès administrateur et les garanties contractuelles ; ne déployer aucune donnée réelle avant validation.
6. Séparer dev/staging/prod et données fictives/réelles, journaux sans données cliniques, accès restreint, chiffrement et procédures d'incident.
7. Prévoir contrôles techniques de non-accès croisé A/B et pentest, preuves des restaurations, document de risque et décision Go/No-Go signée.

## État du code après le premier socle P1

- `backend/` est un **service de développement dédié** dans le dépôt Flutter. Pas encore un dépôt GitHub distinct et pas encore déployé.
- Endpoint d'inscription de développement **désactivé par défaut** ; l'API refuse `APP_ENV=production`.
- Login, jwt court, logout et listes/patients filtrés par `owner_user_id`, testés avec deux comptes fictifs.
- Aucune connexion Flutter réelle, aucun système d'email vérifié, aucun renouvellement de jeton, aucune politique de sécurité consolidée, pas de migration production ou de RLS PostgreSQL, et pas de modèle complet des bilans/suivis côté API.
- Les données du prototype ne doivent **jamais** être interprétées comme des dossiers patients réels ni comme l'établissement de conformité.

## Go / No-Go avant données de santé réelles

**No-Go** tant que : régime CDP non clarifié, hébergement/contrats/transferts non approuvés, comptes et récupération non sécurisés, migration des données hors ligne non validée, absence de tests d'isolation exhaustive, sauvegarde non restaurée, audit de sécurité non effectué.

Des arbitrages supplémentaires peuvent être nécessaires selon que l'application cible un cabinet individuel, un établissement de santé ou des patients eux-mêmes.
