# 📋 Récapitulatif des Fonctionnalités - E-Santé 4.0 DALYS

Ce document résume l'ensemble des fonctionnalités implémentées dans l'application mobile DALYS.

## 1. 📊 Surveillance des Indicateurs Vitaux (Feature 1)
**Objectif** : Suivre en temps réel les paramètres de santé respiratoire.

### Fonctionnalités :
- **Affichage en temps réel** :
  - SpO₂ (Saturation en oxygène)
  - Fréquence respiratoire
  - Débit de pointe (PEF)
  - Température corporelle (Nouveau)
- **Visualisation graphique** : Historique sur 7 jours pour chaque paramètre.
- **Indicateurs de risque** : Code couleur (Vert/Orange/Rouge) selon les seuils médicaux.
- **Mode Simulation** : Interrupteur pour basculer entre données simulées et capteurs réels.

### Matériel supporté :
- Capteurs : MAX30100 (SpO₂/Cœur), DS18B20 (Température), DHT22 (Ambiance).
- Microcontrôleur : ESP32.

---

## 2. 🚨 Alertes et Historique (Feature 2)
**Objectif** : Prévenir l'utilisateur en cas d'anomalie et garder une trace des événements.

### Fonctionnalités :
- **Liste des alertes** : Affichage chronologique des alertes (Critique, Action, Info).
- **Filtrage** : Par type (Santé, Environnement, Système) ou statut (Lu/Non lu).
- **Détails** : Page dédiée pour chaque alerte avec recommandations spécifiques.
- **Gestion** : Possibilité de marquer comme lu ou supprimer.

---

## 3. 🧠 Intelligence et Personnalisation (Feature 3)
**Objectif** : Fournir des conseils proactifs basés sur l'analyse des données.

### Fonctionnalités :
- **Moteur de suggestions (ServiceIA)** : Analyse les données vitales et environnementales.
- **Types de conseils** :
  - 🟢 **Prévention** : Conseils quotidiens, rappels (ex: "Aérez votre logement").
  - 🟠 **Action** : Recommandations suite à une mesure limite (ex: "Reposez-vous").
  - 🔴 **Alerte** : Avertissement en cas de risque élevé.
- **Intégration Dashboard** : Section "Conseils IA" visible directement sur l'écran principal.
- **Page dédiée** : Historique complet des suggestions reçues.

---

## 🛠 Architecture Technique
- **Langage** : Dart / Flutter.
- **Architecture** : Clean Architecture (Data / Domain / Presentation).
- **Gestion d'état** : Provider.
- **Services** :
  - `SensorService` : Gestion de la connexion ESP32.
  - `ServiceIA` : Moteur de règles et simulation d'IA.
  - `ControleurAlertes` : Gestion centralisée des notifications.

## 📂 Structure des Fichiers Clés (Français)
- `lib/data/models/modele_suggestion.dart` : Modèle de données pour les conseils.
- `lib/data/services/service_ia.dart` : Logique métier de l'IA.
- `lib/features/ai_suggestions/screens/ecran_suggestions.dart` : Interface liste des conseils.
- `lib/features/ai_suggestions/widgets/carte_suggestion.dart` : Composant visuel d'un conseil.
