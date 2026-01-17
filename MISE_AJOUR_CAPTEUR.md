# 📡 Guide de Mise à Jour du Capteur DALYS

Ce guide est destiné à la personne possédant les capteurs physiques pour mettre à jour l'ESP32 et le connecter à l'application mobile.

## 🛠 Prérequis

1.  **Arduino IDE** installé sur votre ordinateur.
2.  **Bibliothèques nécessaires** (à installer via le Gestionnaire de bibliothèques) :
    *   `WiFi` (intégré à l'ESP32)
    *   `WebServer` (intégré à l'ESP32)
    *   `DHT sensor library` (par Adafruit)
    *   `OneWire`
    *   `DallasTemperature`
    *   `MAX30100_PulseOximeter` (par Oxu2)

## 📥 Étape 1 : Téléversement du Code

1.  Ouvrez le fichier suivant dans Arduino IDE :
    `DALYS-main/esp32_code.ino`
2.  Connectez votre ESP32 à votre ordinateur via USB.
3.  Sélectionnez la carte **"DOIT ESP32 DEVKIT V1"** (ou votre modèle exact).
4.  Cliquez sur **Téléverser** (la flèche vers la droite).

## 🌐 Étape 2 : Configuration du WiFi

Une fois le code téléversé, l'ESP32 va créer son propre réseau WiFi.

*   **Nom du réseau (SSID)** : `DALYS_SENSOR_WIFI`
*   **Mot de passe** : `dalys-password`

## 📱 Étape 3 : Connexion à l'Application

1.  Sur votre téléphone, allez dans les paramètres WiFi et connectez-vous au réseau `DALYS_SENSOR_WIFI`.
2.  Lancez l'application **DALYS**.
3.  Sur le tableau de bord (onglet "Aujourd'hui"), vous verrez un indicateur de connexion :
    *   🔴 **Rouge** : Non connecté.
    *   🟢 **Vert** : Connecté (les données s'affichent en temps réel).

## 📊 Ce qui a été mis à jour

*   **Mode Point d'Accès** : Plus besoin de routeur externe, le téléphone se connecte directement au capteur.
*   **Support du Pouls (BPM)** : Le rythme cardiaque est maintenant transmis et affiché sur une nouvelle carte dédiée.
*   **Optimisation JSON** : Les données sont envoyées dans un format ultra-rapide compatible avec l'IA de l'application.

---
*Note : Si les données ne s'affichent pas, vérifiez que vous êtes bien connecté au WiFi du capteur et que l'ESP32 est alimenté.*
