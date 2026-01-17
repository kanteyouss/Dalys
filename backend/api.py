from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import joblib
import pandas as pd
import uvicorn
import os

# --- Configuration et Chargement du Modèle ---
MODEL_FILE = 'health_risk_model.pkl'

if not os.path.exists(MODEL_FILE):
    raise FileNotFoundError(f"Le fichier de modèle {MODEL_FILE} est manquant. Exécutez d'abord 02_train_model.py.")

try:
    model = joblib.load(MODEL_FILE)
except Exception as e:
    raise RuntimeError(f"Erreur lors du chargement du modèle: {e}")

app = FastAPI(title="E-Santé 4.0 IoT+IA API", version="1.0.0")

# --- Modèle de Données pour la Requête (Validation Pydantic) ---
class HealthData(BaseModel):
    # Données du Capteur
    HR: int 
    RR: int 
    Temperature: float 
    Humidity: float 
    Dust: int 
    
    # Antécédents de l'Utilisateur
    Asthmatic: int # 0 ou 1
    Sensitive_Humidity: int # 0 ou 1
    Sensitive_Dust: int # 0 ou 1

# --- Mapping des Labels pour la Réponse ---
LABEL_MAP = {
    0: {"state": "Normal", "message": "État stable. Continuez la surveillance.", "severity": "low"},
    1: {"state": "Risque", "message": "Facteurs de risque détectés. Veuillez faire attention.", "severity": "medium"},
    2: {"state": "Crise", "message": "Crise potentielle détectée! Alerte immédiate nécessaire.", "severity": "high"},
}

# --- Endpoint pour la Prédiction ---
@app.post("/predict_risk/")
def predict_risk(data: HealthData):
    """
    Reçoit les données des capteurs et les antécédents pour prédire l'état de risque.
    """
    try:
        # 1. Préparer les données pour la prédiction
        input_data = data.model_dump() # Utilisation de model_dump() pour Pydantic V2
        features = pd.DataFrame([input_data])
        
        # 2. Faire la prédiction
        prediction_int = model.predict(features)[0]
        prediction_proba = model.predict_proba(features)[0].tolist() 

        # 3. Construire la réponse
        result = LABEL_MAP.get(prediction_int, LABEL_MAP[0])
        
        # 4. Ajout de la logique d'action requise pour le mobile/backend
        result['action_required'] = (result['severity'] == 'high')
            
        return {
            "status": "success",
            "prediction": result,
            "probabilities": {
                "Normal": prediction_proba[0],
                "Risque": prediction_proba[1],
                "Crise": prediction_proba[2],
            }
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur interne lors de la prédiction: {e}")

# Lancement de l'API (à exécuter avec la commande uvicorn)
if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)