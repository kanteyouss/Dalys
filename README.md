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
- **Hardware / IoT** :
  - **Microcontrôleur** : ESP32 (Collecte et transmission)
  - **Température/Humidité** : DHT22
  - **Cardio/SpO₂** : MAX30100
  - **Température Précise** : DS18B20 (soudé)

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
1. **Mode Bluetooth** : L'app scanne automatiquement les appareils nommés `DALYS_ESP32`.
2. **Mode WiFi (Direct)** : 
   - Connectez votre téléphone au WiFi de l'ESP32 (`DALYS_SENSOR_WIFI`).
   - L'app communiquera directement avec l'IP `192.168.4.1`.
3. Adapter les modèles de données si nécessaire.

## 📡 Configuration ESP32 (WiFi AP)
Pour utiliser le mode WiFi direct, téléversez le code situé dans `DALYS-main/esp32_code.ino`.
- **SSID** : `DALYS_SENSOR_WIFI`
- **Password** : `dalys-password`
- **IP** : `192.168.4.1` (automatique)
- **Route** : `/data` (JSON)

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


D’accord, voici une **version plus simple, claire et accessible**, tout en restant propre et bien rédigée — comme un guide utilisateur grand public.

---

# 📊 Guide Utilisateur – Suivi de votre santé respiratoire

**Application E-Santé 4.0 – DALYS**

## 🏥 À quoi sert cette fonctionnalité ?

Elle vous permet de **surveiller facilement votre respiration** grâce à trois indicateurs importants :

* la saturation en oxygène (SpO₂)
* la fréquence respiratoire
* le débit de pointe (PEF)

Ces informations vous aident à comprendre rapidement si tout va bien ou si vous devez faire attention.

---

## 💾 Comment les données sont-elles affichées ?

### 🔄 Données de démonstration

Pour le moment, l’application utilise **des données simulées**. Cela vous permet :

* de découvrir toutes les fonctionnalités
* de tester le tableau de bord
* de voir comment évoluent les indicateurs
* d’apprendre à utiliser l’application **sans capteur médical**

Les valeurs changent automatiquement toutes les **10 secondes**, comme si elles venaient d’un vrai appareil.

### 🌐 Plus tard : connexion à de vrais capteurs

Les futures versions permettront de connecter :

* un **oxymètre Bluetooth** pour la SpO₂
* un **capteur respiratoire Wi-Fi**
* un **débitmètre connecté** pour le PEF

L’affichage ne changera pas : seules les données deviendront réelles.

---

## 📱 Ce que vous voyez à l’écran

1. **Des cartes colorées** affichant chaque mesure

   * Valeur actuelle
   * Unité (% / bpm / L/min)
   * Couleur d’alerte (vert, orange, rouge)
   * Une petite icône

2. **Des graphiques simples** pour voir comment les valeurs évoluent dans le temps

3. **Un indicateur global** qui vous dit rapidement si votre état est normal, à surveiller ou en alerte.

---

## 🔍 Les trois mesures expliquées simplement

### 1. 💓 SpO₂ (saturation en oxygène)

* Mesure le taux d’oxygène dans votre sang
* Normal : **95 % à 100 %**
* Si la valeur descend, cela peut indiquer une gêne respiratoire

### 2. 🫁 Fréquence respiratoire

* Nombre de respirations par minute
* Normal : **12 à 20 respirations/minute**

### 3. 🌪️ Débit de pointe (PEF)

* Mesure la force de votre expiration
* Normal : **350 à 500 L/min**
* Utile surtout pour l’asthme ou les problèmes pulmonaires

---

## 🎨 Que signifient les couleurs ?

* 🟢 **Vert** : Tout va bien
* 🟡 **Orange** : À surveiller
* 🔴 **Rouge** : Attention, valeur anormale

---

## 📱 Comment utiliser la fonctionnalité ?

### 1. Ouvrez l’application

Le tableau de bord apparaît automatiquement.

### 2. Lisez vos indicateurs

Regardez les trois cartes :

* la valeur
* la couleur
* l’icône
* l’indicateur global

### 3. Ajouter une mesure manuelle

* Appuyez sur **“Nouvelle mesure”**
* Entrez vos valeurs si vous utilisez votre propre appareil

---

## 🎯 Scénarios simples

### 🟢 Scénario 1 : Tout est normal

Exemple :

* SpO₂ 98 %
* Respiration 16 bpm
* Débit 420 L/min
  → **Continuez vos activités normalement.**

### 🟡 Scénario 2 : Une valeur en alerte

Exemple :

* SpO₂ 91 % (Rouge)
  → Reposez-vous et surveillez votre état. Si ça persiste, contactez un médecin.

### 🔴 Scénario 3 : Plusieurs valeurs anormales

Exemple :

* SpO₂ 89 %
* Respiration 26 bpm
  → **Contactez immédiatement un professionnel de santé.**

---

## 📊 Suivi dans le temps

L’application affiche :

* la tendance de vos valeurs sur 7 jours
* la moyenne, le minimum et le maximum
  → Cela vous permet d’observer facilement votre évolution.

---

## 💡 Conseils d’utilisation

* Prenez vos mesures **au calme**
* Idéalement **le matin** ou en cas de gêne
* Notez vos symptômes (toux, fatigue, essoufflement)
* Regardez les tendances plutôt qu’une seule valeur

---

Si tu veux :
✓ une version encore plus courte
✓ une version avec emoji uniquement
✓ une version adaptée pour une **présentation PowerPoint**
✓ ou une version “fiche rapide”,
je peux te la produire aussi.



> 💡 **Note** : Cette application est un prototype de recherche. Elle ne remplace pas un avis médical professionnel.


flutter run -d linux# Dalys
flutter analyze
# Dalys
# Dalys
pour ios flutter build ipa (pour une version de production) après avoir restauré les packages (flutter pub get) 
pour android flutter build apk (pour une version de production) après avoir restauré les packages (flutter pub get)
