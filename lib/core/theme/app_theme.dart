import 'package:flutter/material.dart';

class AppTheme {
  // Couleurs de l'E-Santé 4.0
  static const Color primaryColor = Color(0xFF2E7D8A); // Bleu médical
  static const Color secondaryColor = Color(0xFF4CAF50); // Vert santé
  static const Color accentColor = Color(0xFF00BCD4); // Cyan

  // Couleurs de risque
  static const Color riskLow = Color(0xFF4CAF50); // Vert - Sain
  static const Color riskMedium = Color(0xFFFF9800); // Orange - Attention
  static const Color riskHigh = Color(0xFFF44336); // Rouge - Danger

  // Couleurs neutres
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        surface: surfaceLight,
        background: backgroundLight,
        error: riskHigh,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.bold,
          color: primaryColor,
        ),
        headlineMedium: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w600,
          color: primaryColor,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          fontSize: 18, // Augmenté pour l'accessibilité
          fontWeight: FontWeight.normal,
        ),
        bodyMedium: TextStyle(
          fontSize: 16, // Augmenté pour l'accessibilité
          fontWeight: FontWeight.normal,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // Plus arrondi
        ),
        color: surfaceLight,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // Plus arrondi
          ),
          padding: const EdgeInsets.symmetric(
              horizontal: 24, vertical: 16), // Plus grand
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: secondaryColor,
        foregroundColor: Colors.white,
        extendedPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: secondaryColor.withOpacity(0.1),
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(8),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        surface: surfaceDark,
        background: backgroundDark,
        error: riskHigh,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: surfaceDark,
      ),
    );
  }

  // Méthodes utilitaires pour les couleurs de risque
  static Color getRiskColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'low':
      case 'faible':
        return riskLow;
      case 'medium':
      case 'moyen':
        return riskMedium;
      case 'high':
      case 'élevé':
        return riskHigh;
      default:
        return riskLow;
    }
  }

  static IconData getRiskIcon(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'low':
      case 'faible':
        return Icons.check_circle;
      case 'medium':
      case 'moyen':
        return Icons.warning;
      case 'high':
      case 'élevé':
        return Icons.error;
      default:
        return Icons.help;
    }
  }
}
