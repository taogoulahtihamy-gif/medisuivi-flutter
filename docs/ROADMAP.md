# Roadmap du produit

## V0 : architecture et parcours (présent)
- [x] Flutter Android/iOS : structure source
- [x] Direction artistique clinique, navigation adaptive, icônes système
- [x] Patients, consultations, constantes, examens (fictifs en mémoire)
- [x] Formulaire patient / consultation
- [x] Contrats d'une future API et synchronisation
- [x] Tests widgets de base + CI
- [ ] Vérification `flutter analyze`, `flutter test` sur poste équipé du SDK Flutter

## V1 : utilisable en conditions contrôlées après audit
- [ ] Revoir les modèles métier avec la soignante (date de naissance, allergies, antécédents, unités, bilans, consentements)
- [ ] Base SQLite **chiffrée**, migrations testées, stockage sécurisé des clés
- [ ] Connexion individuelle, verrouillage biométrique/PIN, politique de sessions
- [ ] Backend FastAPI, PostgreSQL, authentification, permissions, audit
- [ ] Synchronisation outbox, curseurs, idempotence, résolution de conflits
- [ ] Pièces jointes, prescriptions et résultats, états et corrections tracées
- [ ] Sauvegardes, restauration, export réglementaire
- [ ] Tests appareils physiques Android/iOS, accessibilité, crash monitoring sans données sensibles
- [ ] Vérification légale et validation de l'établissement

## V2 : selon besoins confirmés
- [ ] Graphiques de tendances et comparaisons cliniques
- [ ] Rappels de suivi avec notifications respectueuses de la confidentialité
- [ ] Export papier/PDF avec contrôle d'accès
- [ ] Support d'autres formats et terminologies médicales standards

Toutes les décisions cliniques restent du ressort des professionnels habilités.
