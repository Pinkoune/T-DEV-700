# McTime 🍔

Application de gestion des temps de travail développée avec SwiftUI et Vapor.

## 👥 Collaborateurs

- **Mathieu Exposito**
- **Timoty Viola**
- **David Vaucheret**
- **Jérémy Barcelo**

## 📋 Description

McTime est une application complète permettant aux employés et managers de gérer les temps de travail avec le thème McDonald's. Elle offre des fonctionnalités de pointage, de suivi des heures et d'analyse de performance via des KPIs.

### Fonctionnalités principales

**Pour tous les utilisateurs :**
- Pointage des heures d'arrivée et de départ
- Visualisation du tableau de bord personnel
- Gestion du compte utilisateur

**Pour les managers :**
- Gestion des équipes
- Visualisation des heures des employés
- Analyse des performances (KPIs)
- Rapports hebdomadaires et mensuels

## 🛠️ Technologies

### Backend
- **Framework** : Vapor 4.115+ (Swift)
- **Base de données** : PostgreSQL 16
- **Authentification** : JWT
- **ORM** : Fluent

### Frontend
- **Framework** : SwiftUI (iOS)
- **Langage** : Swift 6.2

### Infrastructure
- **Conteneurisation** : Docker & Docker Compose
- **Reverse Proxy** : Traefik v3.0
- **Admin DB** : pgweb

## 🚀 Installation

### Prérequis

- Docker et Docker Compose installés
- Port 80, 443, 5432 et 8081 disponibles

### Démarrage rapide

1. **Cloner le repository**
```bash
git clone git@github.com:EpitechMscProPromo2027/T-DEV-700-project-TLS_6.git
cd T-DEV-700-project-TLS_6
```

2. **Configurer les variables d'environnement**
```bash
cp .env.example .env
# Éditer le fichier .env avec vos valeurs
```

3. **Lancer l'application**
```bash
docker-compose up -d
```

4. **Accéder aux services**
- **API Backend** : http://localhost/api
- **Client Mobile** : Via simulateur iOS ou appareil
- **Traefik Dashboard** : http://localhost:8081
- **pgAdmin** : http://localhost:8082

## 📁 Structure du projet

```
.
├── backend/              # API Vapor (Swift)
│   ├── Sources/
│   ├── Dockerfile
│   └── Package.swift
├── frontend/             # Application SwiftUI
│   ├── Sources/
│   └── Dockerfile.mobile
├── traefik/              # Configuration reverse proxy
├── docker-compose.yml    # Orchestration des services
└── README.md
```

## 🔧 Configuration

### Variables d'environnement

Créer un fichier `.env` à la racine avec les variables demandées aux collaborateurs.

## 🔐 Authentification

L'application utilise JWT pour sécuriser les endpoints. Chaque requête nécessite un token d'authentification valide.

**Deux rôles disponibles :**
- `employee` : Accès aux fonctionnalités de base
- `manager` : Accès aux fonctionnalités de gestion d'équipe

## 🧪 Tests

```bash
# Backend
docker-compose exec backend swift test

# Frontend (via Xcode)
xcodebuild test -scheme frontend
```

## 📊 CI/CD

Le projet inclut des workflows GitHub Actions pour :
- Tests automatisés (backend & frontend)
- Analyse de couverture de code
- Build Docker automatisé

## 🏗️ Architecture

L'application suit une architecture RESTful avec :
- Backend API stateless
- Authentification JWT
- Base de données relationnelle
- Reverse proxy pour le routing
- Conteneurisation complète

## 📝 API Endpoints

### Authentification
- `POST /auth/login` - Connexion
- `POST /auth/register` - Inscription

### Utilisateurs
- `GET /users` - Liste des utilisateurs
- `GET /users/:id` - Détails utilisateur
- `PUT /users/:id` - Mise à jour
- `DELETE /users/:id` - Suppression

### Time Entries
- `POST /timeentries` - Créer un pointage
- `GET /timeentries/:userId` - Pointages par utilisateur

### Teams
- `GET /teams` - Liste des équipes
- `POST /teams` - Créer une équipe
- `PUT /teams/:id` - Mettre à jour

### Dashboard
- `GET /dashboard/:userId` - Statistiques utilisateur
- `GET /dashboard/manager/:managerId` - Vue manager

## 🛡️ Sécurité

- Authentification JWT obligatoire
- Hashage des mots de passe (Bcrypt)
- Middleware de gestion des rôles
- Headers de sécurité configurés via Traefik

---

**Dernière mise à jour** : Octobre 2025