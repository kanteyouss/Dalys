# Instructions pour lancer et tester le système E-Santé 4.0

## Prérequis
- Python 3.x installé
- Arduino IDE avec ESP32 support
- Librairies Arduino : WiFi, HTTPClient, DHT, OneWire, DallasTemperature, MAX30100_PulseOximeter

## 1. Installation des dépendances Python
```bash
pip install -r requirements.txt
```

## 2. Lancement du serveur IA
```bash
python flask_server.py
```
Le serveur démarre sur http://0.0.0.0:5000

## 3. Configuration ESP32
- Ouvrez `esp32_code.ino` dans Arduino IDE
- Modifiez les constantes WiFi :
  ```cpp
  const char* ssid = "VOTRE_WIFI_SSID";
  const char* password = "VOTRE_WIFI_PASSWORD";
  const char* serverUrl = "http://IP_DU_SERVEUR:5000/predict";
  ```
- Téléversez le code sur ESP32

## 4. Test du système
- Le serveur affiche les logs des prédictions
- L'ESP32 envoie les données toutes les 5 secondes
- Exemple de requête JSON envoyée :
  ```json
  {
    "HR": 75,
    "RR": 20,
    "Temperature": 25.5,
    "Humidity": 55.0,
    "Asthmatic": 1,
    "Sensitive_Humidity": 1,
    "Sensitive_Dust": 0
  }
  ```
- Réponse attendue :
  ```json
  {
    "diagnostic": "Normal",
    "confidence": 0.85
  }
  ```

## Notes importantes
- RR est simulé (MAX30100 ne mesure pas directement la fréquence respiratoire)
- Dust est fixé à 100 dans le serveur (ajouter capteur poussière si nécessaire)
- Antécédents sont fixes dans le code ESP32 (adapter selon utilisateur)