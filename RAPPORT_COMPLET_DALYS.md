## Rapport Technique & Stratégique Master (Version 3.1)

---

## 1. 📝 Présentation du Projet
**DALYS** est une solution intégrée de e-santé dédiée aux patients souffrant de pathologies respiratoires chroniques (Asthme, BPCO). Le projet combine du matériel IoT (ESP32), des algorithmes d'intelligence artificielle hybrides et une interface mobile Flutter pour offrir un suivi prédictif, sécurisé et hautement personnalisé.

---

## 2. 🎯 Objectifs Stratégiques & Cibles
- **Prévention Précoce** : Anticiper les crises jusqu'à 7 jours à l'avance.
- **Sécurisation du Patient** : Protocole SOS 2.0 avec anti-spam et mise à jour automatique.
- **Optimisation Clinique** : Rapports PDF structurés pour faciliter le diagnostic médical.
- **Éducation Thérapeutique** : Réhabilitation respiratoire et suivi d'observance.

---

## 3. 🚀 Parcours Utilisateur & Fonctionnalités (Exhaustif)

### 🔐 Phase 1 : Onboarding & Profilage Médical
- **Triple Sécurité** : Configuration de contacts pour le Proche, le Médecin et l'Hôpital.
- **Identité Médicale** : Avatar personnalisé et hachage local des mots de passe.
- **Éthique** : **Medical Disclaimer** permanent rappelant que DALYS est un outil de prévention.

### 📊 Phase 2 : Monitoring IoT & Contexte Environnemental
- **Flux Hybride** : Connexion BLE (Bluetooth) et WiFi (Polling HTTP) à l'ESP32.
- **AQI (Air Quality Index)** : Corrélation en temps réel avec la pollution extérieure.
- **Dashboard "Zen"** : 3 onglets (Aujourd'hui, Prévisions, Outils) pour une clarté maximale.
- **Mode Simulation Expert** : Générateur de scénarios (Normal, Critique, Récupération).

### 🧠 Phase 3 : Intelligence Artificielle Multi-Horizon
- **Algorithme de Fragilité (6 axes)** : Valeurs critiques (40%), Tendance (20%), Variabilité (15%), Fréquence (15%), Écart personnel (10%), Environnement (10%).
- **Prédictions Temporelles** : Analyses à 6h, 24h et 7 jours.
- **Analyse de Tendances** : Patterns saisonniers (30+ jours) et corrélations multi-paramètres.

### 💊 Phase 4 : Gestion Thérapeutique & Réhabilitation
- **Suivi Médicamenteux** : Notifications interactives (Pris/Reporter) et canal "doux".
- **IA Prescription Helper** : Mise en évidence des médicaments de secours en cas de risque.
- **Réhabilitation** : Exercices guidés (4-7-8, Cohérence Cardiaque) avec biofeedback visuel.

### 🚨 Phase 5 : SOS & Feedback Vocal Adaptatif
- **SOS Intelligent** : Stratégie anti-spam et mises à jour silencieuses aux proches.
- **Vocal Adaptatif** : Synthèse vocale (TTS) changeant de ton selon l'urgence.
- **Annulation Vocale** : Reconnaissance de "Je vais bien" pour stopper une alerte.

---

## 4. 🏗️ Spécifications Techniques & Hardware

### 📡 Couche Matérielle (IoT)
| Capteur | Donnée | Rôle Clinique |
| :--- | :--- | :--- |
| **MAX30100** | **SpO₂ / BPM** | Détection de l'hypoxie et de la tachycardie. |
| **DS18B20** | **Temp. Corporelle** | Détection des infections (précision médicale). |
| **DHT22** | **Air (T°/H%)** | Analyse des facteurs environnementaux locaux. |
| **ESP32 DevKit**| **Gateway** | Serveur Web JSON & AP WiFi sécurisé. |

### 💻 Stack Logicielle
- **Frontend** : Flutter (Dart) avec Provider.
- **Backend IA** : FastAPI (Python) + Scikit-Learn.
- **Services** : Geolocator (avec fallback Desktop), STT/TTS, Local Notifications.

---

## 5. 🛡️ Audit de l'Assistant IA (Expertise UX)
- **NLP Robuste** : Algorithme de Levenshtein pour la tolérance aux fautes de frappe.
- **Clarté Visuelle** : Bulles contrastées et indicateurs de frappe pour une interaction humaine.
- **Accessibilité** : Support vocal complet pour les situations de détresse.

---

## 6. 💰 Estimation des Coûts (en Francs CFA - XOF)
- **Matériel IoT (Par Unité)** : ~21 500 F CFA.
- **Développement & RH (MVP)** : ~3 400 000 F CFA.
- **Infrastructure (Annuel)** : ~205 000 F CFA.
- **Coût Total Estimé (MVP)** : **~3 626 500 F CFA**.

---

## 7. 🛡️ Confidentialité & Éthique (RGPD)
- **Local-First** : Données de santé stockées uniquement sur le smartphone (SQLite).
- **Anonymisation** : Seules les données physiologiques brutes transitent vers l'IA.
- **Transparence** : Explication systématique des scores ("Pourquoi ce score ?").

---
*Rapport d'expertise Master mis à jour le 19 Janvier 2026 - Équipe Technique DALYS.*
