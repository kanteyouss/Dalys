import 'package:flutter/material.dart';

enum TypeTechniqueRespiration {
  coherenceCardiaque,
  respirationAbdominale,
  technique478,
}

class ModeleTechniqueRespiration {
  final String nom;
  final String description;
  final TypeTechniqueRespiration type;

  // Durées en secondes
  final int dureeInspiration;
  final int dureeRetentionPleine;
  final int dureeExpiration;
  final int dureeRetentionVide;

  final Color couleurTheme;
  final IconData icone;

  const ModeleTechniqueRespiration({
    required this.nom,
    required this.description,
    required this.type,
    required this.dureeInspiration,
    this.dureeRetentionPleine = 0,
    required this.dureeExpiration,
    this.dureeRetentionVide = 0,
    this.couleurTheme = Colors.blue,
    this.icone = Icons.air,
  });

  static List<ModeleTechniqueRespiration> get techniques => [
        const ModeleTechniqueRespiration(
          nom: 'Cohérence Cardiaque',
          description:
              'Équilibre le système nerveux et réduit le stress. 5s inspire, 5s expire.',
          type: TypeTechniqueRespiration.coherenceCardiaque,
          dureeInspiration: 5,
          dureeExpiration: 5,
          couleurTheme: Colors.blue,
          icone: Icons.favorite,
        ),
        const ModeleTechniqueRespiration(
          nom: 'Respiration Abdominale',
          description: 'Respiration profonde pour une meilleure oxygénation.',
          type: TypeTechniqueRespiration.respirationAbdominale,
          dureeInspiration: 4,
          dureeRetentionPleine: 2,
          dureeExpiration: 6,
          couleurTheme: Colors.green,
          icone: Icons.spa,
        ),
        const ModeleTechniqueRespiration(
          nom: 'Technique 4-7-8',
          description: 'Idéal pour s\'endormir ou calmer une anxiété forte.',
          type: TypeTechniqueRespiration.technique478,
          dureeInspiration: 4,
          dureeRetentionPleine: 7,
          dureeExpiration: 8,
          couleurTheme: Colors.purple,
          icone: Icons.nightlight_round,
        ),
      ];
}
