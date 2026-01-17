#include <WiFi.h>
#include <WebServer.h>
#include <DHT.h>
#include <OneWire.h>
#include <DallasTemperature.h>
#include <Wire.h>
#include "MAX30100_PulseOximeter.h"

// Configuration WiFi - Mode Point d'Accès (AP) pour connexion directe
const char* ssid = "DALYS_SENSOR_WIFI";
const char* password = "dalys-password";

// Serveur Web sur le port 80
WebServer server(80);

// Pins des capteurs
#define DHT_PIN 4          // DHT22
#define ONE_WIRE_BUS 5     // DS18B20
#define REPORTING_PERIOD_MS 1000

// Objets capteurs
DHT dht(DHT_PIN, DHT22);
OneWire oneWire(ONE_WIRE_BUS);
DallasTemperature sensors(&oneWire);
PulseOximeter pox;

// Variables pour les données
float envTemperature = 0;
float humidity = 0;
int heartRate = 0;
int spo2 = 0;
int breathingRate = 0;

// Variables pour estimation de la fréquence respiratoire
unsigned long lastBeatTime = 0;

void onBeatDetected() {
    unsigned long now = millis();
    lastBeatTime = now;
}

int estimateBreathingRate(int hr) {
    if (hr <= 0) return 16;
    int estimatedRR = hr / 4;
    if (estimatedRR < 12) estimatedRR = 12;
    if (estimatedRR > 25) estimatedRR = 25;
    return estimatedRR;
}

// Route pour servir les données à l'App Flutter
void handleData() {
    String json = "{";
    json += "\"spo2\":" + String(spo2) + ",";
    json += "\"bpm\":" + String(heartRate) + ",";
    json += "\"temp\":" + String(sensors.getTempCByIndex(0)) + ",";
    json += "\"hum\":" + String(humidity) + ",";
    json += "\"env_temp\":" + String(envTemperature) + ",";
    json += "\"breathingRate\":" + String(breathingRate);
    json += "}";
    server.send(200, "application/json", json);
}

void setup() {
    Serial.begin(115200);

    dht.begin();
    sensors.begin();

    if (!pox.begin()) {
        Serial.println("Erreur MAX30100");
        while (1);
    }
    pox.setOnBeatDetectedCallback(onBeatDetected);

    // Configuration en mode Point d'Accès
    WiFi.softAP(ssid, password);
    Serial.println("WiFi AP : " + String(ssid));
    Serial.print("IP ESP32 : ");
    Serial.println(WiFi.softAPIP());

    // Routes du serveur
    server.on("/data", handleData);
    server.begin();
}

void loop() {
    server.handleClient();
    pox.update();

    static uint32_t tsLastReport = 0;
    if (millis() - tsLastReport > REPORTING_PERIOD_MS) {
        sensors.requestTemperatures();
        envTemperature = dht.readTemperature();
        humidity = dht.readHumidity();
        heartRate = pox.getHeartRate();
        spo2 = pox.getSpO2();
        breathingRate = estimateBreathingRate(heartRate);

        // Affichage console pour debug
        Serial.print("SpO2: "); Serial.print(spo2);
        Serial.print("% | HR: "); Serial.print(heartRate);
        Serial.println(" bpm");

        tsLastReport = millis();
    }
}