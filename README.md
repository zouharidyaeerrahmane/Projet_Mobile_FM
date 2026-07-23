# UniClaim — Gestion des réclamations universitaires

> Application mobile multi-plateforme permettant aux résidents d'une cité universitaire de déclarer un incident technique ou une nuisance sonore, et aux différents services de l'établissement (techniciens, sécurité, direction, administration) de traiter ces demandes depuis un espace dédié à leur rôle.

<p align="left"> <img alt="Flutter" src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white"> <img alt="Dart" src="https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white"> <img alt="Node.js" src="https://img.shields.io/badge/Node.js-18%2B-339933?logo=node.js&logoColor=white"> <img alt="Express" src="https://img.shields.io/badge/Express-5-000000?logo=express&logoColor=white"> <img alt="Prisma" src="https://img.shields.io/badge/Prisma-6-2D3748?logo=prisma&logoColor=white"> <img alt="MySQL" src="https://img.shields.io/badge/MySQL-8-4479A1?logo=mysql&logoColor=white"> </p>

---

## Sommaire

- [À propos](#%C3%A0-propos)
- [Fonctionnalités par rôle](#fonctionnalit%C3%A9s-par-r%C3%B4le)
- [Architecture](#architecture)
- [Stack technique](#stack-technique)
- [Modèle de données](#mod%C3%A8le-de-donn%C3%A9es)
- [API](#api)
- [Démarrage](#d%C3%A9marrage)
- [Comptes de démonstration](#comptes-de-d%C3%A9monstration)
- [Structure du dépôt](#structure-du-d%C3%A9p%C3%B4t)

---

## À propos

Dans une résidence universitaire, les réclamations circulent souvent par des canaux informels : cahier à l'accueil, messages, bouche-à-oreille. Le suivi est difficile, les responsabilités floues et les délais impossibles à mesurer.

**UniClaim** centralise ce flux dans une application unique. Un étudiant déclare un problème depuis son téléphone ; la demande est automatiquement orientée vers le bon interlocuteur ; chaque acteur suit l'avancement en temps réel depuis son propre tableau de bord.

L'application couvre deux types de signalements :

|Type|Description|Destinataire|
|---|---|---|
|**Réclamation technique**|Panne électrique, plomberie, menuiserie, climatisation, connexion internet… avec photo optionnelle|Technicien de la spécialité concernée|
|**Nuisance sonore**|Signalement d'un voisinage bruyant (chambre, étage, bloc)|Agent de sécurité|

Le cœur du système est l'**affectation automatique** : lorsqu'une réclamation est créée, le serveur identifie la catégorie déclarée et l'assigne directement au technicien dont la spécialité correspond, sans intervention manuelle.

---

## Fonctionnalités par rôle

L'application expose cinq espaces distincts. L'interface affichée après connexion dépend entièrement du rôle du compte.

### Étudiant

- Déclaration d'une réclamation technique (titre, description, catégorie, photo)
- Signalement d'une nuisance sonore (chambre, chambre voisine, étage, bloc)
- Suivi de l'historique et de l'état de ses demandes
- Annulation d'une demande tant qu'elle n'a pas été prise en charge
- Clôture et évaluation d'une intervention terminée
- Configuration de son numéro de chambre

### Technicien

- Liste des tâches assignées, filtrées par sa spécialité
- Consultation du détail d'une réclamation, photo incluse
- Mise à jour du statut d'intervention (en cours, en attente, résolu)

### Agent de sécurité

- Tableau de bord des signalements de nuisance sonore
- Consultation du détail d'un signalement
- Traitement du dossier (examiné, résolu, rejeté) avec ajout d'une note d'agent
- Statistiques de suivi

### Direction

- Vue consolidée de toutes les réclamations, avec recherche, filtres et pagination
- Statistiques globales par statut, présentées sous forme de graphiques
- Modification du statut d'une réclamation

### Administrateur

- Création de comptes utilisateurs pour l'ensemble des rôles
- Consultation et filtrage de l'annuaire des comptes

---

## Architecture

Le projet suit une architecture **client / serveur découplée**, organisée en monorepo.

```
┌──────────────────────────────┐         ┌──────────────────────────────┐
│      uniclaim_frontend       │  HTTP   │      uniclaim-backend        │
│                              │  REST   │                              │
│  Flutter (Android/iOS/Web)   │ ◄─────► │   Node.js + Express          │
│                              │ cookie  │                              │
│  • Écrans par feature        │ session │  • Routes                    │
│  • Providers (état global)   │         │  • Contrôleurs               │
│  • Service API centralisé    │         │  • Middlewares (auth/rôles)  │
└──────────────────────────────┘         └──────────────┬───────────────┘
                                                        │ Prisma ORM
                                                        ▼
                                              ┌───────────────────┐
                                              │      MySQL        │
                                              └───────────────────┘
```

### Frontend — organisation par fonctionnalité

Le code Dart est découpé verticalement : chaque rôle métier possède son propre dossier d'écrans, et les éléments transverses sont isolés dans `core/` et `shared/`.

```
lib/
├── main.dart              # Point d'entrée, initialisation du service API
├── app.dart               # Routeur et redirection par rôle
├── core/
│   ├── services/          # Client HTTP unique, gestion des cookies de session
│   ├── providers/         # État d'authentification global
│   └── constants/         # Thème et design system
├── shared/
│   ├── models/            # Modèles de données et sérialisation
│   └── widgets/           # Composants d'interface réutilisables
└── features/
    ├── auth/              # Connexion
    ├── etudiant/          # Tableau de bord, création et détail des demandes
    ├── technicien/        # Tâches assignées et détail d'intervention
    ├── securite/          # Traitement des nuisances sonores
    ├── direction/         # Vue consolidée et statistiques
    └── admin/             # Gestion des comptes
```

Le routeur applique une **redirection centralisée** : un utilisateur non authentifié est renvoyé vers l'écran de connexion, et un utilisateur authentifié est dirigé vers l'espace correspondant à son rôle.

### Backend — architecture en couches

```
src/
├── server.js              # Démarrage du serveur
├── app.js                 # Configuration Express, middlewares, montage des routes
├── routes/                # Définition des endpoints et contrôle d'accès
├── controllers/           # Logique métier
├── middleware/            # Authentification, contrôle de rôle, upload de fichiers
└── services/              # Règles transverses (affectation, notifications)
prisma/
├── schema.prisma          # Schéma de la base de données
├── migrations/            # Historique des migrations
└── seed.js                # Jeu de données initial
```

L'autorisation repose sur un middleware appliqué route par route : chaque endpoint déclare explicitement le ou les rôles autorisés à l'appeler.

### Authentification

L'authentification est **basée sur une session serveur**. À la connexion, le mot de passe est vérifié contre son empreinte stockée en base, puis l'identifiant et le rôle de l'utilisateur sont placés dans une session ; un cookie `httpOnly` est renvoyé au client. Côté Flutter, ce cookie est conservé de façon persistante, ce qui maintient la session entre deux lancements de l'application.

---

## Stack technique

### Application mobile

|Domaine|Technologie|
|---|---|
|Framework|Flutter / Dart|
|Navigation|`go_router`|
|Gestion d'état|`flutter_riverpod`|
|Client HTTP|`dio` avec gestion persistante des cookies|
|Graphiques|`fl_chart`|
|Médias|`image_picker`, `cached_network_image`|
|Interface|Material Design, `shimmer`, `flutter_rating_bar`|
|Formatage|`intl`, `timeago`|

Cibles supportées : **Android**, **iOS**, **Web**, ainsi que les runners desktop générés par Flutter.

### Serveur

|Domaine|Technologie|
|---|---|
|Runtime|Node.js|
|Framework|Express|
|ORM|Prisma|
|Base de données|MySQL|
|Sessions|`express-session`|
|Sécurité|`helmet`, `bcryptjs`, `cors`|
|Upload de fichiers|`multer`|
|Validation|`express-validator`|
|Journalisation|`morgan`|

---

## Modèle de données

Trois entités principales structurent la base.

|Entité|Rôle|Champs clés|
|---|---|---|
|**User**|Compte utilisateur, tous rôles confondus|nom complet, email unique, mot de passe haché, rôle, numéro de chambre, spécialité|
|**Complaint**|Réclamation technique|titre, description, catégorie, statut, image, auteur, technicien assigné|
|**NoiseReport**|Signalement de nuisance sonore|chambre, chambre voisine, étage, bloc, description, statut, note de l'agent, auteur|

**Rôles disponibles** : `student`, `technician`, `agent`, `admin`, `security`

**Catégories de réclamation** : `electricite`, `plomberie`, `menuiserie`, `climatisation`, `internet`, `autre`

**Cycle de vie d'une réclamation** : `pending` → `in_progress` → `waiting` → `resolved` → `closed`, avec sortie possible en `cancelled`

**Cycle de vie d'un signalement sonore** : `pending` → `reviewed` → `resolved` / `rejected`

---

## API

L'API est exposée sous le préfixe `/api`. Les images téléversées sont servies statiquement depuis `/uploads`.

|Groupe|Préfixe|Objet|
|---|---|---|
|Authentification|`/api/auth`|Connexion, déconnexion, profil, vérification de session|
|Réclamations|`/api/complaints`|Création, suivi, affectation, statuts, statistiques|
|Nuisances sonores|`/api/noise-reports`|Création, suivi, traitement par la sécurité, statistiques|
|Utilisateurs|`/api/users`|Gestion des comptes et du profil|

Chaque endpoint est protégé par un contrôle de rôle : par exemple, la création d'une réclamation est réservée au rôle `student`, la mise à jour d'un statut d'intervention au rôle `technician`, et la vue consolidée aux rôles `agent` et `admin`.

---

## Démarrage

### Prérequis

|Outil|Version recommandée|
|---|---|
|Node.js|18 ou supérieure|
|MySQL|8 ou supérieure|
|Flutter SDK|3.x (Dart ≥ 3.0)|
|Android Studio / Xcode|Selon la plateforme cible|

Vérifiez que votre environnement Flutter est correctement configuré :

```bash
flutter doctor
```

### 1. Cloner le dépôt

```bash
git clone https://github.com/zouharidyaeerrahmane/Projet_Mobile_FM.git
cd Projet_Mobile_FM
```

### 2. Base de données

Créez la base de données destinée à l'application :

```sql
CREATE DATABASE uniclaim CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

### 3. Backend

```bash
cd uniclaim-backend
npm install
```

Créez un fichier `.env` à la racine de `uniclaim-backend` :

```env
DATABASE_URL="mysql://UTILISATEUR:MOT_DE_PASSE@localhost:3306/uniclaim"
SESSION_SECRET="remplacez-par-une-chaine-aleatoire-longue"
PORT=3000
```

Appliquez les migrations, générez le client Prisma et injectez le jeu de données initial :

```bash
npx prisma migrate deploy
npx prisma generate
node prisma/seed.js
```

Lancez le serveur :

```bash
npm run dev     # mode développement, rechargement automatique
# ou
npm start       # mode production
```

Le serveur écoute sur `http://localhost:3000`. Un appel à la racine renvoie un message de confirmation, ce qui permet de vérifier rapidement que l'API est opérationnelle.

### 4. Frontend

Dans un second terminal :

```bash
cd uniclaim_frontend
flutter pub get
flutter run
```

> **Configuration de l'adresse du serveur**
> 
> Le client pointe par défaut vers `http://localhost:3000/api`. Selon la cible d'exécution, une adaptation est nécessaire :
> 
> |Cible|Action|
> |---|---|
> |Appareil Android en USB|Exécuter `adb reverse tcp:3000 tcp:3000` avant le lancement — `localhost` fonctionne alors tel quel|
> |Émulateur Android|Remplacer `localhost` par `10.0.2.2` dans `lib/core/services/api_service.dart`|
> |Appareil physique en Wi-Fi|Remplacer `localhost` par l'adresse IP locale de la machine hôte|
> |Web / desktop|Aucune modification requise|

### 5. Compilation d'un APK

```bash
cd uniclaim_frontend
flutter build apk --release
```

---

## Comptes de démonstration

Le script de seed crée les comptes suivants, ainsi qu'un ensemble de réclamations et de signalements de test permettant d'explorer immédiatement chaque espace.

|Rôle|Email|Mot de passe|
|---|---|---|
|Administrateur|`admin@uniclaim.dz`|`Admin1234!`|
|Direction|`direction@uniclaim.dz`|`Agent1234!`|
|Sécurité|`securite@uniclaim.dz`|`Secu1234!`|
|Technicien — électricité|`elec@uniclaim.dz`|`Tech1234!`|
|Technicien — plomberie|`plomb@uniclaim.dz`|`Tech1234!`|
|Étudiant|`etudiant1@uniclaim.dz`|`Etud1234!`|
|Étudiant|`etudiant2@uniclaim.dz`|`Etud1234!`|

> Ces identifiants sont destinés au développement et à la démonstration uniquement. Ils doivent être supprimés avant tout déploiement réel.

---

## Structure du dépôt

```
Projet_Mobile_FM/
├── uniclaim-backend/          # API REST Node.js / Express / Prisma
│   ├── prisma/                # Schéma, migrations et données initiales
│   └── src/                   # Routes, contrôleurs, middlewares, services
├── uniclaim_frontend/         # Application Flutter multi-plateforme
│   ├── lib/                   # Code source Dart
│   ├── android/ ios/ web/     # Configurations spécifiques aux plateformes
│   └── pubspec.yaml           # Dépendances Flutter
└── README.md
```

---

## Notes de développement

- Le fichier `.env` est exclu du versionnement ; il doit être recréé localement à partir des variables listées plus haut.
- Les images téléversées sont stockées sur le système de fichiers du serveur, dans un dossier `uploads/` créé automatiquement au premier envoi.
- Le dépôt conserve quelques modules hérités d'une itération antérieure de l'API, non montés dans l'application courante. Ils peuvent être supprimés sans impact fonctionnel.

---

## Réaliser par : ZOUHARI Dyae errahmane
