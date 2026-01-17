/// Glossaire simplifié pour convertir le jargon médical en termes accessibles
class MedicalTermsGlossary {
  /// Convertit les termes techniques en langage simple
  static String simplify(String technicalTerm) {
    final glossary = {
      // Indicateurs vitaux
      'SpO₂': 'Oxygène',
      'SpO2': 'Oxygène',
      'Saturation': 'Niveau d\'oxygène',
      'Saturation en oxygène': 'Oxygène dans le sang',
      
      // Respiration
      'Fréquence respiratoire': 'Vitesse de respiration',
      'FR': 'Respiration',
      'Respiration/min': 'Respirations par minute',
      'bpm': 'par minute',
      
      // Souffle
      'PEF': 'Souffle',
      'Débit de pointe': 'Force du souffle',
      'L/min': 'Litres/minute',
      
      // Pathologies
      'Hypoxémie': 'Manque d\'oxygène',
      'Dyspnée': 'Essoufflement',
      'Tachypnée': 'Respiration rapide',
      'Bradypnée': 'Respiration lente',
      
      // Environnement
      'AQI': 'Qualité de l\'air',
      'PM2.5': 'Particules fines',
      'PM10': 'Poussières',
    };
    
    return glossary[technicalTerm] ?? technicalTerm;
  }
  
  /// Retourne une explication contextuelle pour un terme
  static String? getExplanation(String term) {
    final explanations = {
      'Oxygène': 'L\'oxygène dans votre sang (comme la batterie de votre téléphone)',
      'Respiration': 'Le nombre de fois que vous respirez par minute',
      'Souffle': 'La puissance de votre expiration',
      'Qualité de l\'air': '0-50 = Bon, 50-100 = Moyen, >100 = Mauvais',
      'Manque d\'oxygène': 'Quand vos poumons ont du mal à capter l\'oxygène',
      'Essoufflement': 'Difficulté à respirer normalement',
    };
    
    return explanations[term];
  }
  
  /// Retourne un message simple pour une plage normale
  static String getNormalRangeMessage(String indicator, String technicalRange) {
    final messages = {
      'Oxygène': 'Normal : au-dessus de 95%',
      'Respiration': 'Normal : 12 à 20 par minute',
      'Souffle': 'Normal : au-dessus de 350 L/min',
      'Température': 'Normal : 36-37°C',
    };
    
    return messages[indicator] ?? 'Plage normale : $technicalRange';
  }
}
