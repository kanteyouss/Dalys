#include <Wire.h>
#include <DHT.h>
#include <OneWire.h>
#include <DallasTemperature.h>
#include <MAX30100_PulseOximeter.h>

// Configuration des broches
#define DHTPIN 4          // Broche pour DHT22
#define DHTTYPE DHT22     // Type de capteur DHT
#define ONE_WIRE_BUS 2    // Broche pour DS18B20

// Initialisation des objets capteurs
DHT dht(DHTPIN, DHTTYPE);
OneWire oneWire(ONE_WIRE_BUS);
DallasTemperature sensors(&oneWire);
PulseOximeter pox;

// Variables pour le timing
uint32_t tsLastReport = 0;
#define REPORTING_PERIOD_MS 1000

void onBeatDetected() {
    // Callback pour la détection de battement cardiaque
    // Serial.println("Battement détecté!");
}

void setup() {
    Serial.begin(115200);
    
    // Initialisation DHT22
    dht.begin();
    
    // Initialisation DS18B20
    sensors.begin();
    
    // Initialisation MAX30100
    if (!pox.begin()) {
        Serial.println("ECHEC initialisation MAX30100");
    } else {
        Serial.println("SUCCES initialisation MAX30100");
    }
    pox.setIRLedCurrent(MAX30100_LED_CURR_7_6MA);
    pox.setOnBeatDetectedCallback(onBeatDetected);
}

void loop() {
    // Mettre à jour le MAX30100 (doit être appelé aussi souvent que possible)
    pox.update();

    // Rapport périodique (toutes les 1s)
    if (millis() - tsLastReport > REPORTING_PERIOD_MS) {
        // Lecture DHT22
        float humidity = dht.readHumidity();
        float envTemp = dht.readTemperature();
        
        // Lecture DS18B20
        sensors.requestTemperatures(); 
        float bodyTemp = sensors.getTempCByIndex(0);
        
        // Lecture MAX30100
        float bpm = pox.getHeartRate();
        float spo2 = pox.getSpO2();

        // Vérification des lectures (NaN)
        if (isnan(humidity) || isnan(envTemp)) {
            // Gestion d'erreur
        }

        // Création du JSON
        Serial.print("{");
        Serial.print("\"spo2\":"); Serial.print(spo2); Serial.print(",");
        Serial.print("\"bpm\":"); Serial.print(bpm); Serial.print(",");
        Serial.print("\"temp\":"); Serial.print(bodyTemp); Serial.print(",");
        Serial.print("\"hum\":"); Serial.print(humidity); Serial.print(",");
        Serial.print("\"env_temp\":"); Serial.print(envTemp);
        Serial.println("}");

        tsLastReport = millis();
    }
}
