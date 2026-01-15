enum RiskLevel { 
  low, 
  medium, 
  high 
}

enum AlertType { 
  aiPrediction, 
  environmental, 
  healthAnomaly 
}

enum SymptomType {
  toux,
  essoufflement,
  fatigue,
  douleurThoracique,
  fievre,
  malDeGorge,
  congestionNasale,
  malaiseGeneral
}

enum SeverityLevel {
  leger,
  moyen,
  fort
}

// Les enums TypeAlerte et NiveauSeverite ont été déplacés vers le modèle unifié
// pour éviter les conflits et centraliser la gestion des alertes.
// Voir: lib/data/models/modele_alerte.dart ou lib/features/alertes/models/modele_alerte.dart