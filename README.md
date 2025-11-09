# TestOps Cluster CI/CD for FM Compta Consulting Application

This project provides a complete TestOps setup for deploying a full-stack accounting consulting application using Kubernetes and CI/CD pipelines with GitHub Actions, ArgoCD, and comprehensive testing tools.

## Quick Start

1. **Set up GitHub secrets** (see [CI/CD Setup](#cicd-setup) section)
2. **Run the cluster setup**: `cd devops && ./setup-all.sh`
3. **Deploy your application** via ArgoCD or push changes to trigger CI/CD

## Project Structure

```
devops-cluster-gitops/
├── application/                    # Full-stack application components
│   ├── fm-compta-consulting-backend/    # Node.js backend service
│   ├── fm-compta-consulting-database/   # MongoDB database setup
│   ├── fm-compta-consulting-frontend/   # Next.js frontend application
│   └── docker-compose.yml              # Local development setup
├── devops/                        # Kubernetes infrastructure
│   ├── setup-all.sh              # Complete cluster setup script
│   ├── delete-all.sh              # Cluster teardown script
│   └── */                        # Individual service configurations
└── .github/workflows/             # CI/CD pipeline definitions
```

## Application Overview

The FM Compta Consulting application is a modern web-based accounting platform:

- **Frontend**: Next.js (React) - Port 3000
- **Backend**: Node.js REST API - Port 3001
- **Database**: MongoDB with authentication
- **Containerization**: Docker with multi-stage builds
- **Orchestration**: Kubernetes with Helm charts

## Local Development

### Prerequisites
- Docker and Docker Compose
- Node.js 18+ (for local development)

### Running Locally

1. **Navigate to application directory**:
   ```bash
   cd application
   ```

2. **Start all services**:
   ```bash
   docker-compose up --build
   ```

3. **Access the application**:
   - Frontend: http://localhost:3000
   - Backend API: http://localhost:3001/api
   - MongoDB: localhost:27017

### Development Workflow
- Frontend hot-reload enabled
- Backend nodemon for auto-restart
- MongoDB data persisted in Docker volume

## Kubernetes Cluster Setup

### Prerequisites
- **Multipass**: VM management
- **kubectl**: Kubernetes CLI
- **Git**: Version control

### Infrastructure Components

The TestOps cluster includes:

| Component | Purpose | Access URL |
|-----------|---------|------------|
| **Kubernetes Dashboard** | Cluster management UI | https://dashboard.local |
| **NGINX Ingress** | Load balancer & routing | - |
| **Cert-Manager** | SSL certificate management | - |
| **Longhorn** | Distributed storage | https://longhorn.local |
| **Grafana** | Monitoring dashboards | https://grafana.local |
| **Prometheus** | Metrics collection | https://prometheus.local |
| **ArgoCD** | GitOps CD platform | https://argocd.local |
| **Playwright** | End-to-end testing framework | Integrated in CI/CD |
| **SonarQube** | Code quality & security analysis | https://sonarqube.local |
| **Allure Dashboard** | Test reporting & visualization | https://allure.local |
| **OWASP ZAP** | Security vulnerability scanning | https://zap.local |

### Setup Instructions

1. **Navigate to devops directory**:
   ```bash
   cd devops
   ```

2. **Run the setup script**:
   ```bash
   ./setup-all.sh
   ```

3. **Follow the prompts** for GitHub PAT configuration

### Default Credentials
- **Grafana**: admin / admin123
- **ArgoCD**: admin / (check ArgoCD docs for initial password)
- **SonarQube**: admin / admin (default credentials, change after first login)

## CI/CD Setup {#cicd-setup}

### GitHub Secrets Configuration

1. **Navigate to repository settings**:
   `Settings > Secrets and variables > Actions`

2. **Create repository secrets**:

   | Secret Name | Description | Example Value |
   |-------------|-------------|---------------|
   | `GH_PAT` | GitHub Personal Access Token | `ghp_xxxxxxxxxxxx` |
   | `CR_PAT` | Container Registry Personal Access Token | `ghp_xxxxxxxxxxxx` |

### Creating GitHub Personal Access Token

1. **Go to GitHub Settings**: Profile > Settings > Developer settings
2. **Generate token**: Personal access tokens > Tokens (classic) > Generate new token
3. **Configure permissions**:
   - repo (Full repository access)
   - workflow (Update GitHub Action workflows)
4. **Copy token** and store as `GH_PAT` secret

### Pipeline Features

- **Automated builds** on push to main branch
- **Multi-architecture** Docker images (amd64/arm64)
- **Security scanning** with Trivy
- **Automatic deployment** via ArgoCD sync
- **Rollback capabilities** through GitOps

### Workflow Triggers
- Push to `main` branch
- Pull request creation/update
- Manual workflow dispatch

## Monitoring & Observability

### Grafana Dashboards

Import these dashboard IDs:
- **15757**: Kubernetes cluster overview
- **13502**: NGINX Ingress monitoring
- **12006**: Longhorn storage metrics

### Accessing Monitoring

1. **Grafana**: https://grafana.local (admin/admin123)
2. **Prometheus**: https://prometheus.local
3. **Kubernetes Dashboard**: https://dashboard.local

## Deployment Workflow

### Automatic Deployment (Recommended)

1. **Push changes** to `main` branch
2. **CI pipeline builds** and pushes images
3. **ArgoCD detects** manifest changes
4. **Application deployed** automatically

### Manual Deployment

1. **Access ArgoCD**: https://argocd.local
2. **Navigate to application**
3. **Click "Sync"** to deploy latest changes

## Cleanup

To remove the entire cluster:

```bash
cd devops
./delete-all.sh
```

## Accessing Services

Once deployed, access your application at:
- **Main Application**: https://fm-compta-consulting.local

## Troubleshooting

### Common Issues

1. **Services not accessible**:
   - Check `/etc/hosts` file for local domain mappings
   - Verify ingress controller status: `kubectl get ingress -A`

2. **CI/CD pipeline failures**:
   - Verify GitHub secrets are correctly set
   - Check runner pod logs: `kubectl logs -n actions-runner-system -l app=runner`

3. **ArgoCD sync issues**:
   - Verify repository access permissions
   - Check ArgoCD application health in UI

### Debug Commands

```bash
# Check cluster status
kubectl get nodes

# Check all pods
kubectl get pods -A

# Check ingress
kubectl get ingress -A

# Check ArgoCD applications
kubectl get applications -n argocd
```

---

# Cluster TestOps CI/CD pour l'Application FM Compta Consulting

Ce projet fournit une configuration complète TestOps pour déployer une application de conseil comptable full-stack en utilisant Kubernetes et des pipelines CI/CD avec GitHub Actions, ArgoCD et des outils complets de test.

## Démarrage Rapide

1. **Configurer les secrets GitHub** (voir section [Configuration CI/CD](#configuration-cicd))
2. **Exécuter la configuration du cluster**: `cd devops && ./setup-all.sh`
3. **Déployer votre application** via ArgoCD ou pousser des changements pour déclencher CI/CD
4. **Accéder aux outils TestOps** (voir section URLs ci-dessous)

## Structure du Projet

```
devops-cluster-gitops/
├── application/                    # Composants de l'application full-stack
│   ├── fm-compta-consulting-backend/    # Service backend Node.js
│   ├── fm-compta-consulting-database/   # Configuration base de données MongoDB
│   ├── fm-compta-consulting-frontend/   # Application frontend Next.js
│   ├── docker-compose.yml              # Configuration développement local
│   └── tests/                        # Suites de tests Playwright
├── devops/                        # Infrastructure Kubernetes
│   ├── setup-all.sh              # Script de configuration complète du cluster TestOps
│   ├── delete-all.sh              # Script de suppression du cluster
│   └── */                        # Configurations des services individuels
├── devops/sonarqube/             # SonarQube pour l'analyse de qualité du code
├── devops/allure/                # Allure Dashboard pour les rapports de test
├── devops/owasp/                 # OWASP ZAP pour les tests de sécurité
└── .github/workflows/             # Définitions des pipelines CI/CD
```

## Aperçu de l'Application

L'application FM Compta Consulting est une plateforme comptable web moderne :

- **Frontend**: Next.js (React) - Port 3000
- **Backend**: API REST Node.js - Port 3001
- **Base de données**: MongoDB avec authentification
- **Conteneurisation**: Docker avec builds multi-étapes
- **Orchestration**: Kubernetes avec charts Helm

## Développement Local

### Prérequis
- Docker et Docker Compose
- Node.js 18+ (pour le développement local)

### Exécution Locale

1. **Naviguer vers le répertoire application** :
   ```bash
   cd application
   ```

2. **Démarrer tous les services** :
   ```bash
   docker-compose up --build
   ```

3. **Accéder à l'application** :
   - Frontend : http://localhost:3000
   - API Backend : http://localhost:3001/api
   - MongoDB : localhost:27017

### Workflow de Développement
- Hot-reload activé pour le frontend
- Backend avec nodemon pour redémarrage automatique
- Données MongoDB persistées dans volume Docker

## Configuration du Cluster Kubernetes

### Prérequis
- **Multipass** : Gestion de VMs
- **kubectl** : CLI Kubernetes
- **Git** : Contrôle de version

### Composants d'Infrastructure

Le cluster TestOps inclut :

| Composant | Objectif | URL d'Accès |
|-----------|----------|-------------|
| **Kubernetes Dashboard** | Interface de gestion du cluster | https://dashboard.local |
| **NGINX Ingress** | Équilibreur de charge et routage | - |
| **Cert-Manager** | Gestion des certificats SSL | - |
| **Longhorn** | Stockage distribué | https://longhorn.local |
| **Grafana** | Tableaux de bord de monitoring | https://grafana.local |
| **Prometheus** | Collecte de métriques | https://prometheus.local |
| **ArgoCD** | Plateforme CD GitOps | https://argocd.local |
| **Playwright** | Framework de test end-to-end | Intégré au CI/CD |
| **SonarQube** | Analyse de qualité et sécurité du code | https://sonarqube.local |
| **Allure Dashboard** | Reporting et visualisation des tests | https://allure.local |
| **OWASP ZAP** | Analyse de vulnérabilités de sécurité | https://zap.local |

### Instructions de Configuration

1. **Naviguer vers le répertoire devops** :
   ```bash
   cd devops
   ```

2. **Exécuter le script de configuration** :
   ```bash
   ./setup-all.sh
   ```

3. **Suivre les invites** pour la configuration du PAT GitHub

### Identifiants par Défaut
- **Grafana** : admin / admin123
- **ArgoCD** : admin / (vérifier la documentation ArgoCD pour le mot de passe initial)
- **SonarQube** : admin / admin (identifiants par défaut, à changer après la première connexion)

## Configuration CI/CD {#configuration-cicd}

### Configuration des Secrets GitHub

1. **Naviguer vers les paramètres du dépôt** :
   `Settings > Secrets and variables > Actions`

2. **Créer les secrets du dépôt** :

   | Nom du Secret | Description | Valeur Exemple |
   |---------------|-------------|----------------|
   | `GH_PAT` | GitHub Personal Access Token | `ghp_xxxxxxxxxxxx` |
   | `CR_PAT` | Personal Access Token pour Container Registry | `ghp_xxxxxxxxxxxx` |

### Création du GitHub Personal Access Token

1. **Aller aux paramètres GitHub** : Profil > Settings > Developer settings
2. **Générer le token** : Personal access tokens > Tokens (classic) > Generate new token
3. **Configurer les permissions** :
   - `repo` (Accès complet au dépôt)
   - `workflow` (Mise à jour des workflows GitHub Action)
4. **Copier le token** et le stocker comme secret `GH_PAT`

### Fonctionnalités du Pipeline

- **Builds automatisés** lors du push vers la branche main
- **Images Docker multi-architecture** (amd64/arm64)
- **Scan de sécurité** avec Trivy
- **Déploiement automatique** via synchronisation ArgoCD
- **Capacités de rollback** grâce à GitOps

### Déclencheurs de Workflow
- Push vers la branche `main`
- Création/mise à jour de pull request
- Dispatch manuel de workflow

## Monitoring & Observabilité

### Tableaux de Bord Grafana

Importer ces IDs de tableau de bord :
- **15757** : Aperçu du cluster Kubernetes
- **13502** : Monitoring NGINX Ingress
- **12006** : Métriques de stockage Longhorn

### Accès au Monitoring

1. **Grafana** : https://grafana.local (admin/admin123)
2. **Prometheus** : https://prometheus.local
3. **Kubernetes Dashboard** : https://dashboard.local

## Workflow de Déploiement

### Déploiement Automatique (Recommandé)

1. **Pousser les changements** vers la branche `main`
2. **Le pipeline CI construit** et pousse les images
3. **ArgoCD détecte** les changements de manifest
4. **Application déployée** automatiquement

### Déploiement Manuel

1. **Accéder à ArgoCD** : https://argocd.local
2. **Naviguer vers l'application**
3. **Cliquer "Sync"** pour déployer les derniers changements

## Nettoyage

Pour supprimer l'ensemble du cluster :

```bash
cd devops
./delete-all.sh
```

## Accès aux Services

Une fois déployé, accéder à votre application sur :
- **Application Principale** : https://fm-compta-consulting.local

## Dépannage

### Problèmes Courants

1. **Services non accessibles** :
   - Vérifier le fichier `/etc/hosts` pour les mappages de domaines locaux
   - Vérifier le statut du contrôleur ingress : `kubectl get ingress -A`

2. **Échecs du pipeline CI/CD** :
   - Vérifier que les secrets GitHub sont correctement configurés
   - Vérifier les logs des pods runner : `kubectl logs -n actions-runner-system -l app=runner`

3. **Problèmes de synchronisation ArgoCD** :
   - Vérifier les permissions d'accès au dépôt
   - Vérifier la santé de l'application ArgoCD dans l'interface

4. **Problèmes avec les outils TestOps** :
   - Vérifier l'état des pods SonarQube/Allure/OWASP ZAP : `kubectl get pods -n sonarqube allure owasp`
   - Vérifier les PVC pour le stockage persistant : `kubectl get pvc -n sonarqube allure owasp`

### Commandes de Debug

```bash
# Vérifier le statut du cluster
kubectl get nodes

# Vérifier tous les pods
kubectl get pods -A

# Vérifier les ingress
kubectl get ingress -A

# Vérifier les applications ArgoCD
kubectl get applications -n argocd

# Vérifier les composants TestOps
kubectl get pods -n sonarqube
kubectl get pods -n allure
kubectl get pods -n owasp
```

### Accès aux outils TestOps

Une fois le cluster déployé, vous pouvez accéder aux outils TestOps :

- **SonarQube** : https://sonarqube.local (identifiants par défaut admin/admin)
- **Allure Dashboard** : https://allure.local 
- **OWASP ZAP** : https://zap.local (port 8080)
