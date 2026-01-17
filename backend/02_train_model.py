import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import classification_report
import joblib
import os

# Nom du fichier du dataset
DATASET_FILE = 'e_health_dataset.csv'
# Nom du fichier du modèle sauvegardé
MODEL_FILE = 'health_risk_model.pkl'

# Vérifier si le dataset existe
if not os.path.exists(DATASET_FILE):
    print(f"Erreur: Le fichier {DATASET_FILE} est introuvable. Exécutez d'abord le script de génération de données (01_generate_data.py).")
    exit()

# Charger le dataset
data = pd.read_csv(DATASET_FILE)

# Définir les features (X) et la cible (y)
FEATURES = ['HR', 'RR', 'Temperature', 'Humidity', 'Dust', 'Asthmatic', 'Sensitive_Humidity', 'Sensitive_Dust']
TARGET = 'Label'

X = data[FEATURES]
y = data[TARGET]

# Séparer les données en ensembles d'entraînement et de test
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42, stratify=y)

print("--- Entraînement du Modèle Random Forest ---")
# Initialiser et Entraîner le modèle (class_weight='balanced' aide à gérer le déséquilibre des labels)
model = RandomForestClassifier(n_estimators=100, max_depth=10, random_state=42, class_weight='balanced')
model.fit(X_train, y_train)

# Évaluation du modèle
y_pred = model.predict(X_test)
print("\n--- Rapport de Classification (Test Set) ---")
print(classification_report(y_test, y_pred, target_names=['Normal', 'Risque', 'Crise']))

# Sauvegarder le modèle entraîné au format .pkl
joblib.dump(model, MODEL_FILE)
print(f"\n✅ Modèle entraîné et sauvegardé dans {MODEL_FILE}. Vous pouvez maintenant lancer l'API (api.py).")