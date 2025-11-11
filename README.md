# 🏥 E-Santé 4.0 - DALYS

> Application mobile intelligente de prédiction et de prévention des maladies respiratoires

## 📋 Description du Projet

E-Santé 4.0 - DALYS est une application mobile développée en Flutter qui utilise l'intelligence artificielle pour prédire et prévenir les maladies respiratoires. L'application combine données médicales, environnementales et comportementales pour fournir des alertes précoces et des recommandations personnalisées.

## 🎯 Objectifs

- **Surveillance en temps réel** des paramètres vitaux respiratoires
- **Prédiction intelligente** des risques de crises respiratoires  
- **Alertes préventives** basées sur l'IA et les conditions environnementales
- **Interface intuitive** avec graphiques 3D et indicateurs colorés
- **Chatbot médical** pour la collecte de symptômes
- **Partage sécurisé** des données avec les professionnels de santé

## 🚀 Fonctionnalités Principales

### ✅ Actuellement Disponible
- **Dashboard de Santé** : Visualisation en temps réel des paramètres vitaux
- **Indicateurs Vitaux** : SpO₂, Fréquence respiratoire, Débit de pointe (PEF)
- **Système de Risque** : Classification automatique (Faible/Moyen/Élevé)
- **Graphiques d'Évolution** : Courbes temporelles avec données simulées
- **Interface Responsive** : Design adaptatif pour différentes tailles d'écran

### ⏳ En Développement
- **Alertes Intelligentes** : Notifications prédictives basées sur l'IA
- **Chatbot Médical** : Collecte interactive des symptômes quotidiens
- **Suggestions Personnalisées** : Recommandations adaptées au profil utilisateur
- **Partage de Données** : Export PDF et partage sécurisé avec médecins
- **Intégration IoT** : Connexion avec capteurs Arduino (SpO₂, débit respiratoire)

## 🛠 Technologies Utilisées

- **Frontend** : Flutter/Dart
- **State Management** : Provider
- **Graphiques** : FL Chart
- **Architecture** : Clean Architecture avec séparation des couches
- **Données** : Mock Data Provider (en attente des vrais capteurs/APIs)

## 📱 Installation et Configuration

### Prérequis
- Flutter SDK (≥ 3.24.4)
- Dart SDK (≥ 3.5.4)
- Android Studio / VS Code
- Emulateur Android ou appareil physique

### Installation
```bash
# Cloner le projet
git clone <url-du-repo>
cd dalys

# Rendre le script executable et l'exécuter
chmod +x setup.sh
./setup.sh

# Ou manuellement :
flutter pub get
flutter run
```

### Vérification de l'environnement
```bash
flutter doctor -v
flutter devices
```

## 🏗 Structure du Projet

```
lib/
├── main.dart                    # Point d'entrée de l'application
├── core/                        # Éléments partagés
│   ├── enums/                   # Énumérations (RiskLevel, AlertType...)
│   └── theme/                   # Thèmes et styles globaux
├── data/                        # Couche de données
│   ├── models/                  # Modèles de données (HealthData, AlertModel...)
│   └── providers/               # Fournisseurs de données (Mock, API...)
├── features/                    # Fonctionnalités par domaine
│   ├── health_monitoring/       # 📊 Surveillance santé
│   │   ├── screens/            # Écrans (Dashboard...)
│   │   ├── widgets/            # Composants UI réutilisables
│   │   └── controllers/        # Logique métier (HealthController)
│   ├── alerts/                 # 🚨 Système d'alertes
│   ├── ai_suggestions/         # 🧠 Suggestions IA
│   ├── chatbot/               # 💬 Chatbot médical
│   ├── data_sharing/          # 🔄 Partage de données
│   └── onboarding_auth/       # 👤 Authentification
└── routes/                     # Navigation de l'app
```

## 📊 Données Simulées

L'application utilise actuellement des données simulées réalistes :

### Paramètres Vitaux
- **SpO₂** : 88-99% (avec distribution réaliste)
- **Fréquence respiratoire** : 16-29 bpm
- **Débit de pointe** : 150-500 L/min
- **Symptômes** : Toux, essoufflement, fatigue, douleurs thoraciques

### Niveaux de Risque
- **🟢 Faible** : Tous les paramètres dans les normes
- **🟡 Moyen** : Un ou plusieurs paramètres en surveillance
- **🔴 Élevé** : Paramètres critiques détectés

## 🔧 Configuration pour le Développement

### Ajout de nouvelles fonctionnalités
1. Créer le dossier dans `lib/features/`
2. Ajouter les écrans, widgets et contrôleurs
3. Mettre à jour les routes dans `app_routes.dart`
4. Ajouter les providers si nécessaire dans `main.dart`

### Intégration avec de vrais capteurs
1. Remplacer `MockHealthProvider` par un provider réel
2. Configurer la connexion Bluetooth/Wi-Fi
3. Adapter les modèles de données si nécessaire

## 🎨 Design et UX

### Palette de Couleurs
- **Primaire** : Vert médical (#2E7D32)
- **Secondaire** : Bleu technologique (#1976D2) 
- **Risque Faible** : Vert (#4CAF50)
- **Risque Moyen** : Orange (#FF9800)
- **Risque Élevé** : Rouge (#F44336)

### Principes de Design
- **Accessibilité** : Contraste élevé, textes lisibles
- **Intuitivité** : Navigation claire et logique
- **Couleurs Médicales** : Codes couleurs universels pour les niveaux de risque
- **Responsive** : Adaptation automatique aux différentes tailles d'écran

## 🔮 Roadmap

### Phase 1 : Foundation (✅ Terminée)
- Structure de base Flutter
- Dashboard avec données simulées
- Système de navigation
- Thème et design system

### Phase 2 : Intelligence (🔄 En cours)
- Modèle IA de prédiction des risques
- API backend (Django/Flask)
- Système d'alertes intelligent
- Chatbot médical

### Phase 3 : Intégration IoT (📅 Prochainement)
- Connexion capteurs Arduino
- Synchronisation temps réel
- Calibration et validation des données

### Phase 4 : Déploiement (📅 À venir)
- Tests utilisateurs
- Optimisations performance
- Publication sur les stores
- Documentation médicale

## 👥 Équipe de Développement

- **Mobile** : Développement Flutter/Dart
- **IA/Backend** : Modèles ML et APIs Python
- **IoT/Hardware** : Capteurs Arduino et intégration
- **UX/Design** : Interface utilisateur et expérience

## 📄 Licence

Ce projet est développé dans le cadre d'un programme de recherche en E-Santé 4.0.

---

> 💡 **Note** : Cette application est un prototype de recherche. Elle ne remplace pas un avis médical professionnel.


flutter run -d linux# Dalys
