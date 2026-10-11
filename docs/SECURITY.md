# Sécurité et données de santé

**Interdit dans cette V0 : toute donnée patient réelle.** Cette interface sert à valider l'ergonomie et les besoins.

Avant exploitation clinique :

- Validation du rôle de la soignante et autorisation de l'établissement pour créer et traiter ces dossiers.
- Analyse des obligations locales applicables (santé, secret professionnel, conservation, hébergement, droits d'accès, consentements/notice si requis).
- Authentification forte, sessions courtes, verrouillage automatique, biométrie uniquement comme mécanisme local complémentaire.
- Chiffrement au repos sur mobile, SQLCipher évalué, clés générées aléatoirement et stockées dans Keychain/Android Keystore ; aucun secret codé en dur dans le dépôt.
- API TLS exclusivement, vérification des jetons côté serveur, contrôle d'accès par propriétaire/autorisation, journaux d'audit sans données cliniques en clair.
- Protection contre captures ou aperçu de notifications sensibles lorsque pertinent ; pas de noms de patients dans les notifications.
- Historique append-only des faits cliniques validés, corrections traçables, horodatage fiable et auteur.
- Sauvegardes chiffrées avec exercices de restauration, politique de rétention, révocation d'appareil perdu.
- Tests unitaires, tests de synchronisation, de permissions et de résilience ; audit externe avant la mise en production.
- Ne jamais déposer de fichiers patients ou de clés dans GitHub, même dans un dépôt privé.

Le code initial n'applique pas ces exigences : c'est une **feuille de route obligatoire**, pas une certification.
