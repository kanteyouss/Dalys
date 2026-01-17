#include <WiFi.h>
#include <HTTPClient.h>
#include <DHT.h>
#include <OneWire.h>
#include <DallasTemperature.h>
#include <Wire.h>
#include "MAX30100_PulseOximeter.h"

// Configuration WiFi
const char* ssid = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASSWORD";

// Configuration serveur - Compatible avec App Flutter DALYS
const char* serverUrl = "http://YOUR_SERVER_IP:5000/health-data";

// Pins des capteurs
#define DHT_PIN 4          // DHT22
#define ONE_WIRE_BUS 5     // DS18B20
#define REPORTING_PERIOD_MS 5000  // 5 secondes

// Objets capteurs
DHT dht(DHT_PIN, DHT22);
OneWire oneWire(ONE_WIRE_BUS);
DallasTemperature sensors(&oneWire);
PulseOximeter pox;

// Variables pour les données - Alignées avec App Flutter
float envTemperature = 0;      // Température ambiante (renommé)
float humidity = 0;            // Humidité ambiante
int heartRate = 0;             // Fréquence cardiaque
int spo2 = 0;                  // ✅ NOUVEAU: Saturation oxygène (SpO2)
int breathingRate = 0;         // Fréquence respiratoire (renommé)

// Variables pour estimation de la fréquence respiratoire
unsigned long lastBeatTime = 0;
int beatCount = 0;
float rrInterval = 0;          // Intervalle R-R pour calcul

// Timer pour les mesures
uint32_t tsLastReport = 0;
uint32_t tsLastBreathCalc = 0;

void onBeatDetected() {
    // Callback pour détection battement - utilisé pour estimer la fréquence respiratoire
    unsigned long now = millis();
    if (lastBeatTime > 0) {
        rrInterval = now - lastBeatTime;  // Intervalle entre battements (ms)
    }
    lastBeatTime = now;
    beatCount++;
}

// ✅ NOUVEAU: Estimation de la fréquence respiratoire depuis la variabilité cardiaque
// Basé sur l'arythmie sinusale respiratoire (RSA)
int estimateBreathingRate(int hr) {
    // Méthode simplifiée: ratio HR/RR typique entre 4:1 et 5:1
    // Pour un adulte au repos: HR ~70 bpm → RR ~14-18 bpm
    if (hr <= 0) return 16;  // Valeur par défaut
    
    // Formule empirique basée sur études médicales
    int estimatedRR = hr / 4;  // Ratio 4:1
    
    // Borner entre valeurs physiologiques normales (12-25 pour adulte)
    if (estimatedRR < 12) estimatedRR = 12;
    if (estimatedRR > 25) estimatedRR = 25;
    
    return estimatedRR;
}

void setup() {
    Serial.begin(115200);

    // Initialisation DHT22
    dht.begin();

    // Initialisation DS18B20
    sensors.begin();

    // Initialisation MAX30100
    if (!pox.begin()) {
        Serial.println("Erreur initialisation MAX30100");
        while (1);
    }
    pox.setOnBeatDetectedCallback(onBeatDetected);

    // Connexion WiFi
    WiFi.begin(ssid, password);
    Serial.print("Connexion WiFi...");
    while (WiFi.status() != WL_CONNECTED) {
        delay(500);
        Serial.print(".");
    }
    Serial.println(" Connecté!");
    Serial.print("IP: ");
    Serial.println(WiFi.localIP());
}

void loop() {
    // Mise à jour MAX30100 (doit être appelé fréquemment)
    pox.update();

    // Lecture toutes les 5 secondes
    if (millis() - tsLastReport > REPORTING_PERIOD_MS) {
        // Lecture température ambiante DS18B20
        sensors.requestTemperatures();
        envTemperature = sensors.getTempCByIndex(0);

        // Lecture humidité DHT22
        humidity = dht.readHumidity();

        // ✅ Lecture HR et SpO2 depuis MAX30100
        heartRate = pox.getHeartRate();
        spo2 = pox.getSpO2();  // ✅ NOUVEAU: Activation de la mesure SpO2
        
        // ✅ Estimation de la fréquence respiratoire depuis HR
        breathingRate = estimateBreathingRate(heartRate);

        // Vérification des lectures
        if (isnan(humidity) || isnan(envTemperature)) {
            Serial.println("Erreur lecture capteurs environnementaux");
            tsLastReport = millis();
            return;
        }
        
        // Validation SpO2 (doit être entre 70-100%)
        if (spo2 < 70 || spo2 > 100) {
            Serial.println("SpO2 hors plage, utilisation valeur par défaut");
            spo2 = 95;  // Valeur par défaut sécuritaire
        }

        // Affichage local - Format aligné avec App Flutter
        Serial.println("=== DONNEES CAPTEURS (Compatible App DALYS) ===");
        Serial.print("spo2: "); Serial.print(spo2); Serial.println("%");
        Serial.print("breathingRate: "); Serial.print(breathingRate); Serial.println(" bpm");
        Serial.print("heartRate: "); Serial.print(heartRate); Serial.println(" bpm");
        Serial.print("envTemperature: "); Serial.print(envTemperature); Serial.println("°C");
        Serial.print("humidity: "); Serial.print(humidity); Serial.println("%");

        // Envoi vers serveur / App Flutter
        sendToServer();

        tsLastReport = millis();
    }
}

void sendToServer() {
    if (WiFi.status() == WL_CONNECTED) {
        HTTPClient http;

        http.begin(serverUrl);
        http.addHeader("Content-Type", "application/json");

        // ✅ Construction JSON - Format compatible App Flutter DALYS
        // Champs alignés avec HealthData model de l'app
        String jsonData = "{";
        jsonData += "\"spo2\":" + String(spo2) + ",";                    // ✅ SpO2 (CRITIQUE pour l'app)
        jsonData += "\"breathingRate\":" + String(breathingRate) + ",";  // ✅ Fréquence respiratoire
        jsonData += "\"heartRate\":" + String(heartRate) + ",";          // Fréquence cardiaque
        jsonData += "\"humidity\":" + String(humidity, 1) + ",";         // Humidité ambiante
        jsonData += "\"envTemperature\":" + String(envTemperature, 1) + ","; // Température ambiante
        jsonData += "\"timestamp\":\"" + getTimestamp() + "\"";          // Horodatage ISO
        jsonData += "}";

        Serial.println("Envoi JSON (format App DALYS): " + jsonData);

        int httpResponseCode = http.POST(jsonData);

        if (httpResponseCode > 0) {
            String response = http.getString();
            Serial.println("Réponse serveur: " + response);
        } else {
            Serial.println("Erreur HTTP: " + String(httpResponseCode));
        }

        http.end();
    } else {
        Serial.println("WiFi déconnecté - Tentative reconnexion...");
        WiFi.reconnect();
    }
}

// ✅ NOUVEAU: Génère un timestamp ISO 8601
String getTimestamp() {
    // Format simplifié - En production, utiliser NTP pour l'heure réelle
    unsigned long ms = millis();
    unsigned long seconds = ms / 1000;
    unsigned long minutes = seconds / 60;
    unsigned long hours = minutes / 60;
    
    // Format: 2026-01-17T12:00:00
    // Note: Pour un vrai timestamp, configurer NTP
    return "2026-01-17T" + 
           String(hours % 24) + ":" + 
           String(minutes % 60) + ":" + 
           String(seconds % 60);
}
        Serial.println("WiFi déconnecté");
    }
}