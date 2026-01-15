import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dalys/data/models/modele_alerte.dart';

/// Service pour la gestion de l'historique des alertes
/// Stockage local persistant avec filtrage et recherche
class ServiceHistoriqueAlertes {
  /// Instance singleton
  static final ServiceHistoriqueAlertes _instance = ServiceHistoriqueAlertes._internal();
  factory ServiceHistoriqueAlertes() => _instance;
  ServiceHistoriqueAlertes._internal();

  /// Clé pour le stockage des alertes
  static const String _cleHistorique = 'historique_alertes';
  static const String _cleStatistiques = 'statistiques_alertes';
  
  /// Cache en mémoire
  List<ModeleAlerte>? _cacheHistorique;
  
  /// Limite maximale d'alertes stockées
  static const int _limiteMaxAlertes = 1000;

  /// Sauvegarde une alerte dans l'historique
  Future<bool> sauvegarderAlerte(ModeleAlerte alerte) async {
    try {
      final historique = await obtenirHistorique();
      
      // Vérifier si l'alerte existe déjà
      final index = historique.indexWhere((a) => a.id == alerte.id);
      if (index != -1) {
        // Mettre à jour l'alerte existante
        historique[index] = alerte;
        debugPrint('🔄 Alerte mise à jour: ${alerte.id}');
      } else {
        // Ajouter la nouvelle alerte au début
        historique.insert(0, alerte);
        debugPrint('💾 Nouvelle alerte sauvegardée: ${alerte.id}');
      }
      
      // Limiter le nombre d'alertes stockées
      if (historique.length > _limiteMaxAlertes) {
        historique.removeRange(_limiteMaxAlertes, historique.length);
        debugPrint('🗑️ Historique nettoyé: ${historique.length} alertes conservées');
      }
      
      // Sauvegarder
      final success = await _sauvegarderHistorique(historique);
      if (success) {
        _cacheHistorique = historique;
        await _mettreAJourStatistiques(alerte);
      }
      
      return success;
      
    } catch (erreur) {
      debugPrint('❌ Erreur sauvegarde alerte: $erreur');
      return false;
    }
  }

  /// Sauvegarde plusieurs alertes en batch
  Future<bool> sauvegarderAlertes(List<ModeleAlerte> alertes) async {
    try {
      final historique = await obtenirHistorique();
      
      for (final alerte in alertes) {
        final index = historique.indexWhere((a) => a.id == alerte.id);
        if (index != -1) {
          historique[index] = alerte;
        } else {
          historique.insert(0, alerte);
        }
      }
      
      // Trier par date (plus récent en premier)
      historique.sort((a, b) => b.dateCreation.compareTo(a.dateCreation));
      
      // Limiter
      if (historique.length > _limiteMaxAlertes) {
        historique.removeRange(_limiteMaxAlertes, historique.length);
      }
      
      final success = await _sauvegarderHistorique(historique);
      if (success) {
        _cacheHistorique = historique;
        for (final alerte in alertes) {
          await _mettreAJourStatistiques(alerte);
        }
      }
      
      debugPrint('💾 ${alertes.length} alertes sauvegardées en batch');
      return success;
      
    } catch (erreur) {
      debugPrint('❌ Erreur sauvegarde batch: $erreur');
      return false;
    }
  }

  /// Récupère l'historique complet des alertes
  Future<List<ModeleAlerte>> obtenirHistorique() async {
    if (_cacheHistorique != null) {
      return List.from(_cacheHistorique!);
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_cleHistorique);
      
      if (jsonString == null || jsonString.isEmpty) {
        _cacheHistorique = [];
        return [];
      }
      
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final alertes = jsonList.map((json) => ModeleAlerte.fromJson(json)).toList();
      
      // Trier par date (plus récent en premier)
      alertes.sort((a, b) => b.dateCreation.compareTo(a.dateCreation));
      
      _cacheHistorique = alertes;
      debugPrint('📖 ${alertes.length} alertes chargées depuis l\'historique');
      
      return alertes;
      
    } catch (erreur) {
      debugPrint('❌ Erreur chargement historique: $erreur');
      _cacheHistorique = [];
      return [];
    }
  }

  /// Filtre l'historique selon les critères
  Future<List<ModeleAlerte>> filtrerHistorique({
    List<TypeAlerte>? types,
    int? niveauPrioriteMin,
    DateTime? dateDebut,
    DateTime? dateFin,
    List<String>? tags,
    String? recherche,
    int? limite,
  }) async {
    final historique = await obtenirHistorique();
    var alertesFiltrees = List<ModeleAlerte>.from(historique);
    
    // Filtrer par type d'alerte
    if (types != null && types.isNotEmpty) {
      alertesFiltrees = alertesFiltrees.where((alerte) => types.contains(alerte.type)).toList();
    }
    
    // Filtrer par niveau de priorité
    if (niveauPrioriteMin != null) {
      alertesFiltrees = alertesFiltrees.where((alerte) => alerte.niveauPriorite >= niveauPrioriteMin).toList();
    }
    
    // Filtrer par période
    if (dateDebut != null) {
      alertesFiltrees = alertesFiltrees.where((alerte) => alerte.dateCreation.isAfter(dateDebut)).toList();
    }
    if (dateFin != null) {
      alertesFiltrees = alertesFiltrees.where((alerte) => alerte.dateCreation.isBefore(dateFin)).toList();
    }
    
    // Filtrer par tags
    if (tags != null && tags.isNotEmpty) {
      alertesFiltrees = alertesFiltrees.where((alerte) {
        return tags.any((tag) => alerte.tags.contains(tag));
      }).toList();
    }
    
    // Recherche textuelle
    if (recherche != null && recherche.isNotEmpty) {
      final motsCles = recherche.toLowerCase().split(' ');
      alertesFiltrees = alertesFiltrees.where((alerte) {
        final texteAlerte = '${alerte.titre} ${alerte.description} ${alerte.source}'.toLowerCase();
        return motsCles.every((mot) => texteAlerte.contains(mot));
      }).toList();
    }
    
    // Limiter les résultats
    if (limite != null && limite > 0) {
      alertesFiltrees = alertesFiltrees.take(limite).toList();
    }
    
    debugPrint('🔍 ${alertesFiltrees.length} alertes après filtrage');
    return alertesFiltrees;
  }

  /// Obtient les statistiques de l'historique
  Future<Map<String, dynamic>> obtenirStatistiques() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_cleStatistiques);
      
      if (jsonString != null) {
        return Map<String, dynamic>.from(jsonDecode(jsonString));
      }
      
      // Générer les statistiques si elles n'existent pas
      return await _genererStatistiques();
      
    } catch (erreur) {
      debugPrint('❌ Erreur chargement statistiques: $erreur');
      return {};
    }
  }

  /// Génère les statistiques complètes
  Future<Map<String, dynamic>> _genererStatistiques() async {
    final historique = await obtenirHistorique();
    final maintenant = DateTime.now();
    
    final stats = <String, dynamic>{
      'total_alertes': historique.length,
      'par_type': <String, int>{},
      'par_priorite': <String, int>{
        'critique': 0,
        'elevee': 0,
        'moyenne': 0,
        'faible': 0,
      },
      'par_periode': <String, int>{
        'aujourd_hui': 0,
        'cette_semaine': 0,
        'ce_mois': 0,
        'cette_annee': 0,
      },
      'evolution_7_jours': <String, int>{},
      'sources_principales': <String, int>{},
      'tags_frequents': <String, int>{},
      'derniere_maj': maintenant.toIso8601String(),
    };
    
    // Calculer les périodes
    final aujourdhui = DateTime(maintenant.year, maintenant.month, maintenant.day);
    final debutSemaine = aujourdhui.subtract(Duration(days: maintenant.weekday - 1));
    final debutMois = DateTime(maintenant.year, maintenant.month, 1);
    final debutAnnee = DateTime(maintenant.year, 1, 1);
    
    for (final alerte in historique) {
      // Statistiques par type
      final typeKey = alerte.type.toString().split('.').last;
      stats['par_type'][typeKey] = (stats['par_type'][typeKey] ?? 0) + 1;
      
      // Statistiques par priorité
      if (alerte.niveauPriorite >= 90) {
        stats['par_priorite']['critique']++;
      } else if (alerte.niveauPriorite >= 70) {
        stats['par_priorite']['elevee']++;
      } else if (alerte.niveauPriorite >= 50) {
        stats['par_priorite']['moyenne']++;
      } else {
        stats['par_priorite']['faible']++;
      }
      
      // Statistiques par période
      if (alerte.dateCreation.isAfter(aujourdhui)) {
        stats['par_periode']['aujourd_hui']++;
      }
      if (alerte.dateCreation.isAfter(debutSemaine)) {
        stats['par_periode']['cette_semaine']++;
      }
      if (alerte.dateCreation.isAfter(debutMois)) {
        stats['par_periode']['ce_mois']++;
      }
      if (alerte.dateCreation.isAfter(debutAnnee)) {
        stats['par_periode']['cette_annee']++;
      }
      
      // Évolution sur 7 jours
      final jour = DateUtils.dateOnly(alerte.dateCreation);
      final jourKey = jour.toIso8601String().substring(0, 10);
      if (jour.isAfter(maintenant.subtract(const Duration(days: 7)))) {
        stats['evolution_7_jours'][jourKey] = (stats['evolution_7_jours'][jourKey] ?? 0) + 1;
      }
      
      // Sources principales
      if (alerte.source.isNotEmpty) {
        stats['sources_principales'][alerte.source] = (stats['sources_principales'][alerte.source] ?? 0) + 1;
      }
      
      // Tags fréquents
      for (final tag in alerte.tags) {
        stats['tags_frequents'][tag] = (stats['tags_frequents'][tag] ?? 0) + 1;
      }
    }
    
    // Sauvegarder les statistiques
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cleStatistiques, jsonEncode(stats));
    
    debugPrint('📊 Statistiques générées: ${stats['total_alertes']} alertes analysées');
    return stats;
  }

  /// Met à jour les statistiques pour une nouvelle alerte
  Future<void> _mettreAJourStatistiques(ModeleAlerte alerte) async {
    try {
      final stats = await obtenirStatistiques();
      
      // Incrémenter le total
      stats['total_alertes'] = (stats['total_alertes'] ?? 0) + 1;
      
      // Mettre à jour par type
      final typeKey = alerte.type.toString().split('.').last;
      stats['par_type'] ??= <String, int>{};
      stats['par_type'][typeKey] = (stats['par_type'][typeKey] ?? 0) + 1;
      
      // Autres mises à jour...
      stats['derniere_maj'] = DateTime.now().toIso8601String();
      
      // Sauvegarder
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cleStatistiques, jsonEncode(stats));
      
    } catch (erreur) {
      debugPrint('❌ Erreur MAJ statistiques: $erreur');
    }
  }

  /// Sauvegarde l'historique dans SharedPreferences
  Future<bool> _sauvegarderHistorique(List<ModeleAlerte> alertes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = alertes.map((alerte) => alerte.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      
      return await prefs.setString(_cleHistorique, jsonString);
      
    } catch (erreur) {
      debugPrint('❌ Erreur sauvegarde historique: $erreur');
      return false;
    }
  }

  /// Supprime une alerte de l'historique
  Future<bool> supprimerAlerte(String alerteId) async {
    try {
      final historique = await obtenirHistorique();
      final index = historique.indexWhere((alerte) => alerte.id == alerteId);
      
      if (index == -1) {
        debugPrint('⚠️ Alerte non trouvée: $alerteId');
        return false;
      }
      
      historique.removeAt(index);
      final success = await _sauvegarderHistorique(historique);
      
      if (success) {
        _cacheHistorique = historique;
        debugPrint('🗑️ Alerte supprimée: $alerteId');
      }
      
      return success;
      
    } catch (erreur) {
      debugPrint('❌ Erreur suppression alerte: $erreur');
      return false;
    }
  }

  /// Vide complètement l'historique
  Future<bool> viderHistorique() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cleHistorique);
      await prefs.remove(_cleStatistiques);
      
      _cacheHistorique = [];
      debugPrint('🗑️ Historique vidé complètement');
      
      return true;
      
    } catch (erreur) {
      debugPrint('❌ Erreur vidage historique: $erreur');
      return false;
    }
  }

  /// Exporte l'historique au format JSON
  Future<String?> exporterHistorique() async {
    try {
      final historique = await obtenirHistorique();
      final stats = await obtenirStatistiques();
      
      final export = {
        'version': '1.0',
        'date_export': DateTime.now().toIso8601String(),
        'statistiques': stats,
        'alertes': historique.map((alerte) => alerte.toJson()).toList(),
      };
      
      final jsonString = const JsonEncoder.withIndent('  ').convert(export);
      debugPrint('📤 Historique exporté: ${historique.length} alertes');
      
      return jsonString;
      
    } catch (erreur) {
      debugPrint('❌ Erreur export historique: $erreur');
      return null;
    }
  }

  /// Importe un historique depuis JSON
  Future<bool> importerHistorique(String jsonString) async {
    try {
      final Map<String, dynamic> import = jsonDecode(jsonString);
      final List<dynamic> alertesJson = import['alertes'] ?? [];
      
      final alertes = alertesJson.map((json) => ModeleAlerte.fromJson(json)).toList();
      
      final success = await sauvegarderAlertes(alertes);
      debugPrint('📥 Historique importé: ${alertes.length} alertes');
      
      return success;
      
    } catch (erreur) {
      debugPrint('❌ Erreur import historique: $erreur');
      return false;
    }
  }

  /// Invalide le cache (force le rechargement)
  void invaliderCache() {
    _cacheHistorique = null;
    debugPrint('🔄 Cache historique invalidé');
  }

  /// Obtient la taille du cache en mémoire
  int get tailleCache => _cacheHistorique?.length ?? 0;
}

/// Utilitaires pour les dates
class DateUtils {
  static DateTime dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}