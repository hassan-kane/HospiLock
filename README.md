# 🛡️ Projet Sécurité des Ressources – Hôpital

Ce projet vise à mettre en place une **politique de sécurité des ressources** sur un poste Windows partagé au sein d’un environnement hospitalier. L’objectif est de **restreindre l’accès aux fichiers et outils système** en fonction du rôle métier de chaque utilisateur.

## 🎯 Objectifs

- Sécuriser les ressources sensibles selon les fonctions (NTFS).
- Créer une hiérarchie de groupes et utilisateurs.
- Appliquer des permissions granulaires sur les dossiers et fichiers.
- Gérer des cas d’accès croisés complexes (ex. médecin accédant à un fichier communication).
- Implémenter des scripts PowerShell automatisés.
- Vérifier la robustesse de la configuration via des tests de sécurité.
- Fournir un script de nettoyage de l’environnement.

## 👥 Profils Métiers & Accès

| Rôle         | Accès à...                                   |
|--------------|-----------------------------------------------|
| Médecin      | Dossiers patients, soins, comptes rendus      |
| Infirmier    | Soins                                         |
| Comptable    | Finance                                       |
| RH           | Dossiers du personnel                         |
| Directeur    | Tout sauf outils informatiques                |
| Communication| Supports de communication                    |
| Informaticien| Outils système (PowerShell, CMD, etc.)        |

## 📂 Ressources à sécuriser (D:\...)

| Dossier                 | Groupes autorisés                  |
|-------------------------|-----------------------------------|
| Dossiers_Patients       | G_Medecins                        |
| Soins                   | G_Medecins, G_Infirmiers         |
| Finance                 | G_Comptables                     |
| RH                      | G_RH                             |
| Direction               | G_Direction                      |
| Comptes_Rendus          | G_Medecins, G_Direction          |
| Communication           | G_Communication                  |
| Outils_Systeme          | G_IT                             |
| Public                  | Tous (G_Hopital)                 |

## 🏗️ Architecture du projet

Un diagramme de sécurité PlantUML a été généré pour visualiser :

- La hiérarchie des groupes (G_Hopital)
- L’association des utilisateurs à leurs rôles
- Les liens entre les groupes et les ressources sécurisées
- Les cas de droits croisés

📎 Voir le fichier `architecture.puml`

## ⚙️ Fonctionnalités des scripts PowerShell

- 🔄 Création des groupes depuis un JSON hiérarchique
- 👤 Création des utilisateurs (nom, prénom, mot de passe)
- 🗂️ Création de l’arborescence des ressources
- 🔐 Application des ACL NTFS (lecture, écriture, interdiction)
- 🧼 Nettoyage complet ou partiel de l’environnement (`-clear_*`)
- ✅ Tests de sécurité : validation de l’accès et des restrictions

## 🧪 Cas de croisement complexes

- 👨‍⚕️ Un médecin souhaite accéder à un dossier de la communication
- 👩‍💼 Un RH a besoin d’accéder à un fichier de la direction

## 🚀 Pour démarrer

```powershell
.\security_script.ps1 -structure "structure.json" -groupes "groupes.json" -utilisateurs "utilisateurs.json"
```

### Nettoyage
```powershell
.\cleanup_script.ps1 -clear_all
```

## 📄 Licence

Ce projet est à usage pédagogique uniquement. Reproduction ou distribution non autorisée sans accord explicite.
