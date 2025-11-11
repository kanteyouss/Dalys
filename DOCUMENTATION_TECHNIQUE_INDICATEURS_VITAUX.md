# 🔧 Documentation Technique - Surveillance des Indicateurs Vitaux

## 📋 Vue d'ensemble

Cette documentation décrit le fonctionnement interne de la première fonctionnalité majeure de l'application E-Santé 4.0 - DALYS : **la surveillance en temps réel des indicateurs vitaux respiratoires**. 

La fonctionnalité permet d'afficher, de suivre et d'analyser trois paramètres critiques :
- **SpO₂** (Saturation en oxygène) - en pourcentage
- **Fréquence respiratoire** - en respirations par minute (bpm)
- **Débit de pointe expiratoire (PEF)** - en litres par minute (L/min)

## 🏗️ Architecture générale

### Modèle de conception
L'application suit une architecture **MVC (Model-View-Controller)** adaptée à Flutter avec les principes suivants :
- **Séparation des préoccupations** : données, logique métier et interface utilisateur
- **Gestion d'état réactive** avec le pattern Provider
- **Flux de données unidirectionnel** pour la cohérence des états
- **Modularité** par fonctionnalités (feature-based structure)

### Flux de données global
```
[Source de données] → [Provider de données] → [Modèle de données] → [Contrôleur] → [Interface utilisateur]
```

## 📁 Fichiers principaux et leurs rôles

### 🎯 Couche de données (Data Layer)

#### `lib/data/models/health_data.dart`
- **Rôle** : Modèle de données principal pour les indicateurs vitaux
- **Responsabilités** :
  - Définition de la structure des données de santé
  - Méthodes de validation des valeurs (seuils normaux/anormaux)
  - Calcul automatique du niveau de risque global
  - Sérialisation/désérialisation JSON
  - Méthodes utilitaires (getRiskColor(), isNormalRange())

#### `lib/data/providers/mock_health_provider.dart`
- **Rôle** : Fournisseur de données simulées pour les tests et démonstrations
- **Responsabilités** :
  - Génération de valeurs réalistes pour les trois paramètres
  - Simulation de variations temporelles naturelles
  - Création de scénarios de test (valeurs normales, alertes, urgences)
  - Émission de flux de données continues (Stream)

#### `lib/core/enums/app_enums.dart`
- **Rôle** : Énumérations globales de l'application
- **Responsabilités** :
  - Définition des niveaux de risque (RiskLevel : Faible, Modéré, Élevé)
  - Types de symptômes possibles
  - Constantes et seuils critiques

### 🎮 Couche logique métier (Business Logic Layer)

#### `lib/features/health_monitoring/controllers/health_controller.dart`
- **Rôle** : Contrôleur principal de la fonctionnalité de surveillance
- **Responsabilités** :
  - Orchestration des flux de données
  - Gestion de l'état de l'application (loading, error, success)
  - Intégration avec le fournisseur de données
  - Gestion des mesures manuelles utilisateur
  - Notification automatique des changements d'état (ChangeNotifier)
  - Calcul des statistiques et tendances

### 🎨 Couche présentation (Presentation Layer)

#### `lib/features/health_monitoring/screens/health_dashboard.dart`
- **Rôle** : Écran principal de surveillance (page d'accueil)
- **Responsabilités** :
  - Assemblage de tous les widgets de monitoring
  - Gestion de la mise en page responsive
  - Intégration avec le contrôleur via Consumer<HealthController>
  - Gestion des interactions utilisateur (boutons, navigation)

#### `lib/features/health_monitoring/widgets/health_indicator_card.dart`
- **Rôle** : Widget de carte individuelle pour chaque paramètre vital
- **Responsabilités** :
  - Affichage stylisé d'une valeur de santé
  - Application des couleurs d'alerte selon les seuils
  - Animation des transitions de valeurs
  - Gestion des icônes et unités de mesure

#### `lib/features/health_monitoring/widgets/health_chart.dart`
- **Rôle** : Composant de visualisation graphique avancée
- **Responsabilités** :
  - Rendu des courbes d'évolution temporelle
  - Calcul et affichage des statistiques (min, max, moyenne)
  - Adaptation automatique des échelles Y selon les données
  - Intégration avec la librairie FL Chart
  - Gestion des interactions tactiles (zoom, scroll)

#### `lib/features/health_monitoring/widgets/risk_level_indicator.dart`
- **Rôle** : Indicateur visuel du niveau de risque global
- **Responsabilités** :
  - Affichage circulaire du statut de santé général
  - Calcul synthétique basé sur tous les paramètres
  - Animation des changements de statut
  - Codage couleur intuitif (vert, orange, rouge)

#### `lib/features/health_monitoring/widgets/add_measurement_dialog.dart`
- **Rôle** : Interface de saisie manuelle des mesures
- **Responsabilités** :
  - Formulaire de saisie avec validation
  - Sélection des symptômes associés
  - Intégration avec le contrôleur pour l'ajout de données
  - Gestion des erreurs de saisie

### 🚀 Couche application (Application Layer)

#### `lib/main.dart`
- **Rôle** : Point d'entrée de l'application
- **Responsabilités** :
  - Configuration du Provider principal (MultiProvider)
  - Initialisation du thème et des routes
  - Injection des dépendances globales

#### `lib/routes/app_routes.dart`
- **Rôle** : Gestionnaire de navigation
- **Responsabilités** :
  - Définition des routes nommées
  - Navigation entre les écrans
  - Gestion des paramètres de navigation

#### `lib/core/theme/app_theme.dart`
- **Rôle** : Configuration du design system
- **Responsabilités** :
  - Palette de couleurs cohérente
  - Styles de typographie
  - Thèmes Material Design 3

## 🔄 Flux de données détaillé

### 1. Initialisation de l'application
1. **Démarrage** : `main.dart` lance l'application
2. **Configuration Provider** : Injection du `HealthController` dans l'arbre de widgets
3. **Initialisation du contrôleur** : Le `HealthController` démarre le flux de données
4. **Connexion au provider** : Abonnement au stream du `MockHealthProvider`

### 2. Cycle de mise à jour des données
1. **Génération de données** : `MockHealthProvider` émet de nouvelles valeurs toutes les 10 secondes
2. **Réception dans le contrôleur** : `HealthController` reçoit les nouvelles données via Stream
3. **Traitement et validation** : Vérification des seuils et calcul du niveau de risque
4. **Notification des widgets** : `notifyListeners()` déclenche la reconstruction de l'UI
5. **Mise à jour visuelle** : Tous les widgets Consumer se reconstruisent avec les nouvelles données

### 3. Gestion des interactions utilisateur
1. **Saisie manuelle** : L'utilisateur ouvre le dialog de mesure
2. **Validation des données** : Contrôle de cohérence des valeurs saisies
3. **Intégration** : Ajout des nouvelles mesures à l'historique existant
4. **Mise à jour UI** : Rafraîchissement immédiat de tous les indicateurs

## 📦 Dépendances techniques

### `provider: ^6.1.1`
- **Usage** : Gestion d'état réactive
- **Avantages** : Performance optimisée, API simple, intégration native Flutter
- **Implémentation** : ChangeNotifier pattern pour les mises à jour automatiques

### `fl_chart: ^0.69.0`
- **Usage** : Bibliothèque de graphiques interactifs
- **Fonctionnalités utilisées** : LineChart pour les courbes d'évolution temporelle
- **Avantages** : Personnalisation avancée, animations fluides, performance native

### Flutter SDK natif
- **Material Design 3** : Composants UI modernes et accessibles
- **Animation framework** : Transitions fluides entre les états
- **Stream API** : Gestion native des flux de données asynchrones

## ⚡ Mécanisme de rafraîchissement dynamique

### Système de streaming
- **Fréquence** : Nouvelles données toutes les 10 secondes
- **Type** : Stream<HealthData> continu et asynchrone
- **Gestion mémoire** : Historique limité aux 50 dernières mesures pour optimiser les performances

### Algorithme de variation
- **SpO₂** : Oscillation autour de valeurs de base (95-100%) avec variations aléatoires contrôlées
- **Fréquence respiratoire** : Simulation de rythmes naturels (12-20 bpm) avec pics occasionnels
- **Débit de pointe** : Variations cycliques représentant l'effort respiratoire

### Gestion de l'état UI
- **Pattern Observer** : Les widgets s'abonnent automatiquement aux changements
- **Reconstruction optimisée** : Seuls les widgets affectés se reconstruisent
- **Loading states** : Indicateurs de chargement pendant les transitions

## 🚨 Système d'alertes visuelles

### Logique des seuils
- **Calcul dynamique** : Évaluation en temps réel de chaque paramètre
- **Règles combinées** : Le risque global considère tous les paramètres simultanément
- **Priorité aux urgences** : Une seule valeur critique déclenche une alerte générale

### Codage couleur
- **Vert (Normal)** : Toutes les valeurs dans les plages de sécurité
- **Orange (Surveillance)** : Au moins une valeur en zone de vigilance
- **Rouge (Alerte)** : Au moins une valeur en zone critique

### Mécanisme d'affichage
- **Couleurs d'arrière-plan** : Application immédiate sur les cartes d'indicateurs
- **Animations** : Transitions douces entre les états pour éviter les effets de clignotement
- **Cohérence visuelle** : Synchronisation de toutes les interfaces (cartes, graphiques, indicateur global)

## 🔮 Évolution prévue : Intégration de capteurs réels

### État actuel : Données simulées
- **Objectif** : Validation du fonctionnement complet de l'interface utilisateur
- **Avantages** : Tests reproductibles, scénarios contrôlés, développement sans matériel
- **Limitations** : Aucune mesure physiologique réelle

### Transition vers capteurs physiques

#### Capteurs Bluetooth Low Energy (BLE)
- **SpO₂** : Oxymètres de pouls compatibles (ex: protocole BLE Health Thermometer)
- **Fréquence respiratoire** : Ceintures thoraciques ou capteurs de mouvement
- **Débit de pointe** : Débitmètres électroniques avec connectivité sans fil

#### Architecture technique future
- **Remplacement transparent** : Le `MockHealthProvider` sera remplacé par un `BluetoothHealthProvider`
- **Interface identique** : Même API Stream<HealthData>, aucun changement dans l'UI
- **Gestion des erreurs** : Ajout de la gestion des déconnexions et erreurs de capteurs
- **Calibration** : Intégration de routines d'étalonnage et de validation des mesures

#### Connectivité Wi-Fi et Arduino
- **Stations de mesure** : Capteurs fixes connectés au réseau domestique
- **Protocole HTTP/MQTT** : Communication avec l'application via API REST ou messaging
- **Synchronisation** : Historique automatique même en cas de déconnexion temporaire

### Migration technique
1. **Abstraction des sources** : Interface commune pour toutes les sources de données
2. **Configuration dynamique** : Sélection automatique ou manuelle du type de capteur
3. **Mode hybride** : Combinaison possible de données réelles et simulées
4. **Validation croisée** : Comparaison avec les données manuelles utilisateur

---

## 🎯 Conclusion technique

Cette architecture modulaire garantit :
- **Maintenabilité** : Chaque composant a une responsabilité claire
- **Extensibilité** : Ajout facile de nouveaux paramètres vitaux
- **Performance** : Optimisations natives Flutter et gestion mémoire efficace
- **Évolutivité** : Migration transparente vers des capteurs physiques
- **Testabilité** : Isolation des composants pour les tests unitaires

Le système actuel de données simulées offre une base solide pour valider l'expérience utilisateur avant l'intégration de matériel médical certifié.