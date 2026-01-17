# DALYS
APP3 projet du groupe DALYS
🎯 Objectif du ProjetCe projet implémente un système complet de prédiction de risque de santé (Normal, Risque, Crise) en temps réel, combinant des données de capteurs IoT (ESP32) et les antécédents de l'utilisateur.La partie IA est déployée via une API Python (FastAPI) pour garantir une analyse rapide et continue des données entrantes.
⚙️ Architecture du Module IALe cœur de ce module repose sur trois étapes :Génération/Collecte des Données : Création d'un dataset structuré.Entraînement du Modèle : Utilisation d'un algorithme de classification pour apprendre à partir des données.Déploiement de l'API : Servir le modèle entraîné via un point d'accès HTTP.ComposantFichier/FormatRôleTechnologie CléDonnéese_health_dataset.csvDataset structuré (simulé pour l'instant) contenant les features et les labels.pandas, numpyModèlehealth_risk_model.pklModèle Random Forest sérialisé, prêt à être chargé pour la prédiction.scikit-learn, joblibAPIapi.pyPoint d'accès (endpoint) pour recevoir les requêtes de l'ESP32 et renvoyer la prédiction de risque.FastAPI, uvicorn📊 Structure des DonnéesLe modèle IA utilise 8 features d'entrée pour prédire le Label (0, 1, ou 2).CatégorieFeatureTypeDescriptionCapteurs IoTHRIntegerFréquence Cardiaque (BPM)RRIntegerFréquence Respiratoire (RPM)TemperatureFloatTempérature Ambiante (°C)HumidityFloatHumidité de l'Air (%)DustIntegerNiveau de Poussière (index ou $\mu g/m^3$)AntécédentsAsthmaticBinaire (0/1)Antécédents d'asthmeSensitive_HumidityBinaire (0/1)Sensibilité déclarée à l'humiditéSensitive_DustBinaire (0/1)Sensibilité déclarée à la poussièreSortie (Label)LabelCatégoriel0=Normal, 1=Risque, 2=Crise🛠️ Instructions de Lancement1. PrérequisVous devez avoir Python 3.x installé. Si vous rencontrez des problèmes avec pip ou uvicorn directement, utilisez le format python -m <commande>.Installez toutes les dépendances requises :Bashpython -m pip install pandas numpy scikit-learn joblib fastapi uvicorn
2. Étape par ÉtapeExécutez les scripts Python dans cet ordre exact. Assurez-vous d'être dans le même répertoire que les fichiers.A. Génération des DonnéesCe script crée le fichier e_health_dataset.csv.Bashpython 01_generate_data.py
B. Entraînement du ModèleCe script entraîne le RandomForestClassifier et sauvegarde le modèle dans health_risk_model.pkl.Bashpython 02_train_model.py
C. Lancement de l'API (Déploiement)Ceci lance le serveur qui exposera votre modèle IA sur le port 8000. Ce terminal doit rester ouvert.Bashpython -m uvicorn api:app --reload --host 0.0.0.0 --port 8000
🚀 Utilisation de l'APIUne fois le serveur lancé (voir Section 2.C), l'API est accessible pour les équipes IoT et Mobile.1. Endpoint de PrédictionMéthode : POSTURL : http://<IP_DU_SERVEUR>:8000/predict_risk/2. Test Rapide (Swagger UI)Vous pouvez tester l'API sans outil supplémentaire via l'interface interactive :Ouvrez votre navigateur : http://127.0.0.1:8000/docsCliquez sur POST /predict_risk/, puis sur "Try it out" pour envoyer des données de test.3. Structure de la Requête (JSON Input)La requête doit toujours être envoyée au format JSON et contenir les 8 features :JSON{
  "HR": 85,
  "RR": 18,
  "Temperature": 25.5,
  "Humidity": 55.0,
  "Dust": 120,
  "Asthmatic": 1,
  "Sensitive_Humidity": 0,
  "Sensitive_Dust": 1
}
4. Structure de la Réponse (JSON Output)La réponse fournit l'état prédit, un message et la gravité associée :JSON{
  "status": "success",
  "prediction": {
    "state": "Risque",
    "message": "Facteurs de risque détectés. Veuillez faire attention.",
    "severity": "medium",
    "action_required": true
  },
  "probabilities": {
    "Normal": 0.1,
    "Risque": 0.7,
    "Crise": 0.2
  }
}

## 🏗️ Architecture Générale du Système E-Santé 4.0

```
ESP32 (IoT) --> API FastAPI (IA) --> Application Mobile (Flutter)
     |              |                      |
   Capteurs      Prédiction              Alertes
   - MAX30100    - Random Forest         - Notifications
   - DHT22       - 3 états               - Envoi proches/médecin
   - DS18B20     - Probabilités
   - Dust Sensor
```

### Composants Principaux :
1. **ESP32** : Collecte données capteurs, envoi HTTP/MQTT à l'API
2. **API Python (FastAPI)** : Reçoit données, fait prédiction IA, retourne état
3. **Application Mobile (Flutter)** : Interface utilisateur, affiche prédictions, gère alertes

## 📱 Application Mobile Flutter

### Structure du Code :
- `main.dart` : Interface principale avec champs de saisie et affichage des résultats
- Notifications locales pour alertes
- Envoi d'alertes aux proches (à implémenter avec service externe)

### Fonctionnalités :
- Saisie des données capteurs et antécédents
- Bouton d'analyse qui appelle l'API
- Affichage de l'état prédit et probabilités
- Notifications push pour risques/crises
- Logique d'alerte aux contacts (email/SMS via service tiers)

## 🔗 Connexion ESP32 à l'API

### Option 1 : HTTP (Recommandé pour simplicité)
```cpp
#include <WiFi.h>
#include <HTTPClient.h>

// Dans loop()
HTTPClient http;
http.begin("http://YOUR_API_IP:8000/predict_risk/");
http.addHeader("Content-Type", "application/json");

String jsonData = "{\"HR\":85,\"RR\":18,\"Temperature\":25.5,\"Humidity\":55.0,\"Dust\":120,\"Asthmatic\":1,\"Sensitive_Humidity\":0,\"Sensitive_Dust\":1}";
int httpResponseCode = http.POST(jsonData);

if (httpResponseCode > 0) {
  String response = http.getString();
  // Traiter la réponse JSON
}
http.end();
```

### Option 2 : MQTT (Pour communication temps réel)
- Utiliser un broker MQTT (ex: Mosquitto)
- ESP32 publie sur topic `/health/data`
- API souscrit et traite les messages

## 🚨 Système d'Alerte

### Notifications Utilisateur :
- **Risque** : Notification locale "Facteurs de risque détectés"
- **Crise** : Notification urgente + alerte aux proches

### Envoi aux Proches/Médecin :
- Intégrer service comme Twilio (SMS) ou SendGrid (Email)
- Dans Flutter : Appeler API externe lors de crise
- Dans API : Endpoint séparé pour alertes

## 📈 Conseils pour Améliorer la Précision

1. **Collecte de Données Réelles** : Remplacer dataset simulé par données réelles d'utilisateurs
2. **Feature Engineering** : Ajouter ratios (HR/RR), moyennes glissantes
3. **Modèles Avancés** : Essayer XGBoost, LSTM pour séries temporelles
4. **Validation Croisée** : Utiliser K-fold pour évaluer stabilité
5. **Rééquilibrage** : SMOTE pour classes minoritaires (Crise)
6. **Mise à Jour Modèle** : Retraining périodique avec nouvelles données

## 🚀 Déploiement du Modèle

### Local :
- Lancer API avec `uvicorn api:app --host 0.0.0.0 --port 8000`

### Production :
- Utiliser Docker pour containerisation
- Déployer sur cloud (AWS Lambda, Heroku, etc.)
- Load balancing pour haute disponibilité

### Sécurité :
- Ajouter authentification API (JWT)
- Chiffrement des données sensibles
- Rate limiting pour éviter abus
