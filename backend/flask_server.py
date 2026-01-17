from flask import Flask, request, jsonify
import pandas as pd
import joblib
import os

app = Flask(__name__)

# Configuration
MODEL_FILE = 'health_risk_model.pkl'  # Utilisation du modèle existant

# Vérification du modèle
if not os.path.exists(MODEL_FILE):
    print(f"Erreur: Modèle {MODEL_FILE} introuvable")
    exit()

# Chargement du modèle
model = joblib.load(MODEL_FILE)
print("Modèle chargé avec succès")

# Mapping des diagnostics
DIAGNOSTIC_MAP = {
    0: "Normal",
    1: "Risque",
    2: "Crise"
}

@app.route('/predict', methods=['POST'])
def predict():
    try:
        # Récupération des données JSON
        data = request.get_json()

        # Validation des champs requis
        required_fields = ['HR', 'RR', 'Temperature', 'Humidity', 'Asthmatic', 'Sensitive_Humidity', 'Sensitive_Dust']
        for field in required_fields:
            if field not in data:
                return jsonify({'error': f'Champ manquant: {field}'}), 400

        # Ajout de Dust (non fourni par ESP32, valeur fixe pour simulation)
        data['Dust'] = 100  # Valeur par défaut, à adapter selon capteur

        # Conversion en DataFrame
        input_df = pd.DataFrame([data])

        # Prédiction
        prediction = model.predict(input_df)[0]
        probabilities = model.predict_proba(input_df)[0]

        # Diagnostic et confiance (probabilité de la classe prédite)
        diagnostic = DIAGNOSTIC_MAP[prediction]
        confidence = float(probabilities[prediction])

        # Réponse
        response = {
            'diagnostic': diagnostic,
            'confidence': confidence
        }

        print(f"Prédiction: {diagnostic} (confiance: {confidence:.2f})")
        return jsonify(response)

    except Exception as e:
        print(f"Erreur: {str(e)}")
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    print("Serveur IA E-Santé démarré sur http://0.0.0.0:5000")
    app.run(host='0.0.0.0', port=5000, debug=True)