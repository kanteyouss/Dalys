import numpy as np
import pandas as pd
from sklearn.utils import shuffle

# Nombre de lignes
N_SAMPLES = 1500

# Initialiser le DataFrame
data = pd.DataFrame()

# 1. Génération des variables de capteur
np.random.seed(42)

# HR (Fréquence Cardiaque)
data['HR'] = np.random.normal(loc=75, scale=10, size=N_SAMPLES).clip(min=50, max=120).astype(int)
# RR (Fréquence Respiratoire)
data['RR'] = np.random.normal(loc=16, scale=4, size=N_SAMPLES).clip(min=10, max=30).astype(int)
# Température (DS18B20)
data['Temperature'] = np.random.normal(loc=25, scale=3, size=N_SAMPLES).clip(min=18, max=35).round(1)
# Humidité (DHT22)
data['Humidity'] = np.random.normal(loc=50, scale=10, size=N_SAMPLES).clip(min=30, max=75).round(1)
# Poussière (Dust)
data['Dust'] = np.random.lognormal(mean=2, sigma=0.8, size=N_SAMPLES).clip(min=10, max=500).astype(int)

# 2. Génération des antécédents de l'utilisateur (variables binaires)
data['Asthmatic'] = np.random.choice([0, 1], size=N_SAMPLES, p=[0.8, 0.2]) # 20% sont Asthmatiques
data['Sensitive_Humidity'] = np.random.choice([0, 1], size=N_SAMPLES, p=[0.7, 0.3])
data['Sensitive_Dust'] = np.random.choice([0, 1], size=N_SAMPLES, p=[0.75, 0.25])

# 3. Génération du Label (0=Normal, 1=Risque, 2=Crise)
data['Label'] = 0

# Définition des conditions pour les états "Crise" (Label=2)
data.loc[
    (data['HR'] > 100) | (data['RR'] > 25) | 
    (
        ((data['Asthmatic'] == 1) & (data['Humidity'] > 65)) | 
        ((data['Sensitive_Dust'] == 1) & (data['Dust'] > 300))
    ),
    'Label'
] = 2

# Définition des conditions pour les états "Risque" (Label=1)
data.loc[
    (data['Label'] == 0) & # Ne pas écraser l'état de Crise
    (
        (data['HR'] > 90) | (data['RR'] > 20) | 
        (data['Humidity'] > 60) | (data['Dust'] > 200) | 
        (data['Temperature'] > 30)
    ), 
    'Label'
] = 1

# S'assurer d'avoir un bon mélange et sauvegarder
data = shuffle(data, random_state=42).reset_index(drop=True)
DATASET_FILE = 'e_health_dataset.csv'
data.to_csv(DATASET_FILE, index=False)
print(f"Dataset sauvegardé dans {DATASET_FILE}. Exécutez le script d'entraînement maintenant.")