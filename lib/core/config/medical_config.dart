class MedicalConfig {
  // Seuils SpO2 (Saturation en oxygène)
  static const int spo2Critical = 92;
  static const int spo2Warning = 95;

  // Seuils Fréquence Respiratoire (bpm)
  static const int breathingRateCriticalHigh = 25;
  static const int breathingRateWarningHigh = 20;
  static const int breathingRateCriticalLow = 8;

  // Seuils PEF (Débit de pointe - L/min)
  static const double pefCritical = 300.0;
  static const double pefWarning = 350.0;

  // Paramètres d'urgence
  static const int emergencyCountdownSeconds = 10;
}
