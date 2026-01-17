import joblib
import pandas as pd
import os

# Nom du fichier du modèle
MODEL_FILE = 'health_risk_model.pkl'

# Vérifier si le modèle existe
if not os.path.exists(MODEL_FILE):
    print(f"Erreur: Le fichier {MODEL_FILE} est introuvable. Exécutez d'abord le script d'entraînement (02_train_model.py).")
    exit()

# Charger le modèle
model = joblib.load(MODEL_FILE)

# Mapping des labels
LABEL_MAP = {
    0: "Normal",
    1: "Risque",
    2: "Crise"
}

def predict_health_risk(hr, rr, temperature, humidity, dust, asthmatic, sensitive_humidity, sensitive_dust):
    """
    Fonction pour faire une prédiction basée sur les données fournies.

    Paramètres:
    - hr: Fréquence cardiaque (int)
    - rr: Fréquence respiratoire (int)
    - temperature: Température (float)
    - humidity: Humidité (float)
    - dust: Poussière (int)
    - asthmatic: Asthmatique (0 ou 1)
    - sensitive_humidity: Sensibilité à l'humidité (0 ou 1)
    - sensitive_dust: Sensibilité à la poussière (0 ou 1)

    Retourne:
    - État prédit (str)
    """
    # Préparer les données
    input_data = pd.DataFrame([{
        'HR': hr,
        'RR': rr,
        'Temperature': temperature,
        'Humidity': humidity,
        'Dust': dust,
        'Asthmatic': asthmatic,
        'Sensitive_Humidity': sensitive_humidity,
        'Sensitive_Dust': sensitive_dust
    }])

    # Faire la prédiction
    prediction = model.predict(input_data)[0]
    probabilities = model.predict_proba(input_data)[0]

    return {
        'prediction': LABEL_MAP[prediction],
        'probabilities': {
            'Normal': probabilities[0],
            'Risque': probabilities[1],
            'Crise': probabilities[2]
        }
    }

# Exemple d'utilisation
if __name__ == "__main__":
    # Exemple de données
    result = predict_health_risk(
        hr=85,
        rr=18,
        temperature=26.5,
        humidity=55.0,
        dust=150,
        asthmatic=1,
        sensitive_humidity=0,
        sensitive_dust=1
    )

    print("Prédiction:", result['prediction'])
    print("Probabilités:", result['probabilities'])