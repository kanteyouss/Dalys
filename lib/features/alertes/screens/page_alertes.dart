import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dalys/features/alertes/controllers/controleur_alertes.dart';
import 'package:dalys/features/alertes/widgets/carte_alerte.dart';
import 'package:dalys/data/models/modele_alerte.dart';
import 'package:dalys/features/alertes/screens/page_detail_alerte.dart';


/// Écran principal d'affichage et de gestion des alertes médicales
/// Permet de consulter, filtrer et rechercher dans l'historique des alertes
class PageAlertes extends StatefulWidget {
  const PageAlertes({super.key});

  @override
  State<PageAlertes> createState() => _EtatPageAlertes();
}

class _EtatPageAlertes extends State<PageAlertes> with SingleTickerProviderStateMixin {
  // Contrôleur pour la barre de recherche
  final TextEditingController _controleurRecherche = TextEditingController();
  
  // Contrôleur d'animation pour la liste
  late AnimationController _controleurAnimation;
  
  // Indique si le panneau de filtres est ouvert
  bool _panneauFiltresOuvert = false;

  @override
  void initState() {
    super.initState();
    
    _controleurAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    // Initialiser le contrôleur d'alertes au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ControleurAlertes>().initialiser().then((_) {
        if (mounted) _controleurAnimation.forward();
      });
    });
  }

  @override
  void dispose() {
    _controleurRecherche.dispose();
    _controleurAnimation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Barre d'application avec titre et actions
      appBar: _construireBarreApplication(context),
      
      // Corps principal de l'écran
      body: Consumer<ControleurAlertes>(
        builder: (context, controleurAlertes, child) {
          return Column(
            children: [
              // Barre de recherche et filtres
              _construireBarreRecherche(controleurAlertes),
              
              // Panneau de filtres (affiché conditionnellement)
              if (_panneauFiltresOuvert) 
                _construirePanneauFiltres(controleurAlertes),
              
              // Badges d'information (nombre d'alertes, filtres actifs)
              _construireBadgesInformation(controleurAlertes),
              
              // Liste des alertes ou état de chargement/erreur
              Expanded(
                child: _construireContenuPrincipal(controleurAlertes),
              ),
            ],
          );
        },
      ),
      
      // Bouton d'action flottant pour actualiser
      floatingActionButton: _construireBoutonActualiser(),
    );
  }

  /// Construit la barre d'application avec le titre et les actions
  PreferredSizeWidget _construireBarreApplication(BuildContext context) {
    return AppBar(
      title: const Text(
        '🚨 Alertes & Notifications',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
      elevation: 0,
      actions: [
        // Bouton pour afficher/masquer les filtres
        IconButton(
          icon: Icon(
            _panneauFiltresOuvert ? Icons.filter_list_off : Icons.filter_list,
            color: _panneauFiltresOuvert ? Theme.of(context).colorScheme.primary : null,
          ),
          tooltip: _panneauFiltresOuvert ? 'Masquer filtres' : 'Afficher filtres',
          onPressed: () {
            setState(() {
              _panneauFiltresOuvert = !_panneauFiltresOuvert;
            });
          },
        ),
        
        // Menu avec actions supplémentaires
        PopupMenuButton<String>(
          tooltip: 'Options',
          onSelected: (valeur) => _gererActionMenu(valeur, context),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'marquer_toutes_lues',
              child: ListTile(
                leading: Icon(Icons.done_all),
                title: Text('Marquer toutes comme lues'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'effacer_filtres',
              child: ListTile(
                leading: Icon(Icons.clear_all),
                title: Text('Effacer tous les filtres'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'exporter',
              child: ListTile(
                leading: Icon(Icons.file_download),
                title: Text('Exporter en PDF'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Construit la barre de recherche avec le champ de saisie
  Widget _construireBarreRecherche(ControleurAlertes controleur) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Theme.of(context).colorScheme.surface,
      child: TextField(
        controller: _controleurRecherche,
        decoration: InputDecoration(
          hintText: 'Rechercher dans les alertes...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _controleurRecherche.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _controleurRecherche.clear();
                    controleur.definirTermeRecherche('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25.0),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
        ),
        onChanged: (valeur) {
          controleur.definirTermeRecherche(valeur);
        },
      ),
    );
  }

  /// Construit le panneau de filtres avec les options de tri et filtrage
  Widget _construirePanneauFiltres(ControleurAlertes controleur) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre du panneau
          Row(
            children: [
              const Icon(Icons.tune, size: 20),
              const SizedBox(width: 8),
              Text(
                'Filtres et options',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Filtre par type d'alerte
          _construireSectionFiltreType(controleur),
          
          const SizedBox(height: 16),
          
          // Filtre par sévérité
          _construireSectionFiltreSeverite(controleur),
          
          const SizedBox(height: 16),
          
          // Option alertes non lues uniquement
          _construireOptionNonLues(controleur),
          
          const Divider(height: 24),
          
          // Mode Simulation (Dev/Demo)
          SwitchListTile(
            title: const Text('Mode Simulation'),
            subtitle: const Text('Générer des données de test'),
            value: controleur.estEnModeSimulation,
            onChanged: (valeur) {
              controleur.basculerModeSimulation(valeur);
            },
            secondary: Icon(
              Icons.science,
              color: controleur.estEnModeSimulation ? Colors.purple : Colors.grey,
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  /// Construit la section de filtrage par type d'alerte
  Widget _construireSectionFiltreType(ControleurAlertes controleur) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Types d\'alerte',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          children: TypeAlerte.values.map((type) {
            final estSelectionne = controleur.filtresTypeActifs.contains(type);
            return FilterChip(
              label: Text(_obtenirNomTypeAlerte(type)),
              selected: estSelectionne,
              onSelected: (selectionne) {
                final nouveauxFiltres = Set<TypeAlerte>.from(controleur.filtresTypeActifs);
                if (selectionne) {
                  nouveauxFiltres.add(type);
                } else {
                  nouveauxFiltres.remove(type);
                }
                controleur.definirFiltresType(nouveauxFiltres);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Construit la section de filtrage par niveau de sévérité
  Widget _construireFiltreSeverite(ControleurAlertes controleur) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Niveaux de sévérité',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          children: NiveauSeverite.values.map((severite) {
            final estSelectionne = controleur.filtresSeveriteActifs.contains(severite);
            return FilterChip(
              label: Text(_obtenirNomSeverite(severite)),
              selected: estSelectionne,
              avatar: estSelectionne 
                  ? const Icon(Icons.check_circle, size: 18)
                  : _obtenirIconeSeverite(severite),
              onSelected: (selectionne) {
                final nouveauxFiltres = Set<NiveauSeverite>.from(controleur.filtresSeveriteActifs);
                if (selectionne) {
                  nouveauxFiltres.add(severite);
                } else {
                  nouveauxFiltres.remove(severite);
                }
                controleur.definirFiltresSeverite(nouveauxFiltres);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Construit l'option pour afficher seulement les alertes non lues
  Widget _construireOptionNonLues(ControleurAlertes controleur) {
    return SwitchListTile(
      title: const Text('Alertes non lues uniquement'),
      subtitle: const Text('Masquer les alertes déjà consultées'),
      value: controleur.afficherSeulementNonLues,
      onChanged: (valeur) {
        controleur.definirAfficherSeulementNonLues(valeur);
      },
      secondary: const Icon(Icons.mark_email_unread),
      contentPadding: EdgeInsets.zero,
    );
  }

  /// Construit les badges d'information (compteurs, filtres actifs)
  Widget _construireBadgesInformation(ControleurAlertes controleur) {
    final alertesFiltrees = controleur.alertesFiltrees;
    final totalAlertes = controleur.toutesLesAlertes.length;
    final alertesNonLues = controleur.nombreAlertesNonLues;
    final alertesCritiques = controleur.nombreAlertesCritiques;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          // Badge nombre d'alertes affichées
          _construireBadge(
            icone: Icons.list_alt,
            texte: '${alertesFiltrees.length}/$totalAlertes alertes',
            couleur: Theme.of(context).colorScheme.primary,
          ),
          
          const SizedBox(width: 8),
          
          // Badge alertes non lues
          if (alertesNonLues > 0)
            _construireBadge(
              icone: Icons.mark_email_unread,
              texte: '$alertesNonLues non lues',
              couleur: Colors.orange,
            ),
          
          const SizedBox(width: 8),
          
          // Badge alertes critiques
          if (alertesCritiques > 0)
            _construireBadge(
              icone: Icons.warning,
              texte: '$alertesCritiques critiques',
              couleur: Colors.red,
            ),
          
          const Spacer(),
          
          // Indicateur de filtres actifs
          if (_aDesFiltresActifs(controleur))
            const Chip(
              label: Text('Filtres actifs'),
              avatar: Icon(Icons.filter_alt, size: 16),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
        ],
      ),
    );
  }

  /// Construit un badge d'information avec icône et texte
  Widget _construireBadge({
    required IconData icone,
    required String texte,
    required Color couleur,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: couleur.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 16, color: couleur),
          const SizedBox(width: 4),
          Text(
            texte,
            style: TextStyle(
              fontSize: 12,
              color: couleur,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Construit le contenu principal selon l'état du contrôleur
  Widget _construireContenuPrincipal(ControleurAlertes controleur) {
    // État de chargement
    if (controleur.estEnChargement) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Chargement des alertes...',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }
    
    // État d'erreur
    if (controleur.messageErreur != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                controleur.messageErreur!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => controleur.actualiser(),
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }
    
    // Liste des alertes
    final alertesFiltrees = controleur.alertesFiltrees;
    
    if (alertesFiltrees.isEmpty) {
      return _construireEtatVide();
    }
    
    return RefreshIndicator(
      onRefresh: () => controleur.actualiser(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: alertesFiltrees.length,
        itemBuilder: (context, index) {
          final alerte = alertesFiltrees[index];
          
          // Animation décalée pour chaque élément
          final animation = Tween<Offset>(
            begin: const Offset(0, 0.1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _controleurAnimation,
            curve: Interval(
              (index * 0.05).clamp(0.0, 0.8),
              1.0,
              curve: Curves.easeOutQuad,
            ),
          ));

          final fadeAnimation = CurvedAnimation(
            parent: _controleurAnimation,
            curve: Interval(
              (index * 0.05).clamp(0.0, 0.8),
              1.0,
              curve: Curves.easeOut,
            ),
          );

          return FadeTransition(
            opacity: fadeAnimation,
            child: SlideTransition(
              position: animation,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: CarteAlerte(
                  alerte: alerte,
                  surTap: () => _gererTapAlerte(alerte, controleur),
                  surMarquerCommeLu: () => controleur.marquerCommeLu(alerte.id),
                  surSupprimer: () => _confirmerSuppressionAlerte(alerte, controleur),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Construit l'état vide quand aucune alerte n'est trouvée
  Widget _construireEtatVide() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.notifications_none,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune alerte trouvée',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Aucune alerte ne correspond aux critères actuels.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// Construit le bouton d'actualisation flottant
  Widget? _construireBoutonActualiser() {
    return Consumer<ControleurAlertes>(
      builder: (context, controleur, child) {
        if (controleur.estEnChargement) {
          return const SizedBox.shrink(); // Widget invisible au lieu de null
        }
        
        return FloatingActionButton(
          onPressed: () => controleur.actualiser(),
          tooltip: 'Actualiser les alertes',
          child: const Icon(Icons.refresh),
        );
      },
    );
  }

  /// Méthodes utilitaires pour l'affichage et la logique
  
  /// Retourne le nom d'affichage pour un type d'alerte
  String _obtenirNomTypeAlerte(TypeAlerte type) {
    switch (type) {
      case TypeAlerte.ia:
        return 'IA Prédictive';
      case TypeAlerte.environnementale:
        return 'Environnement';
      case TypeAlerte.medicale:
        return 'Médicale';
      case TypeAlerte.manuelle:
      case TypeAlerte.critique:
      case TypeAlerte.medicament:
      case TypeAlerte.rendezvous:
      case TypeAlerte.haute:
      case TypeAlerte.basse:
      case TypeAlerte.moyenne:
      case TypeAlerte.rappel:
      case TypeAlerte.systeme:
        return 'Manuelle';
      case TypeAlerte.critique:
        return 'Critique';
      case TypeAlerte.medicament:
        return 'Médicament';
      case TypeAlerte.rendezvous:
        return 'Rendez-vous';
      case TypeAlerte.haute:
        return 'Haute Priorité';
      case TypeAlerte.moyenne:
        return 'Moyenne Priorité';
      case TypeAlerte.basse:
        return 'Basse Priorité';
      case TypeAlerte.rappel:
        return 'Rappel';
      case TypeAlerte.systeme:
        return 'Système';
    }
  }

  /// Retourne le nom d'affichage pour un niveau de sévérité
  String _obtenirNomSeverite(NiveauSeverite severite) {
    switch (severite) {
      case NiveauSeverite.faible:
        return 'Faible';
      case NiveauSeverite.modere:
        return 'Modérée';
      case NiveauSeverite.eleve:
        return 'Élevée';
      case NiveauSeverite.critique:
        return 'Critique';
    }
  }

  /// Retourne l'icône appropriée pour un niveau de sévérité
  Widget _obtenirIconeSeverite(NiveauSeverite severite) {
    switch (severite) {
      case NiveauSeverite.faible:
        return const Icon(Icons.info, size: 18, color: Colors.green);
      case NiveauSeverite.modere:
        return const Icon(Icons.warning, size: 18, color: Colors.orange);
      case NiveauSeverite.eleve:
        return const Icon(Icons.error, size: 18, color: Colors.red);
      case NiveauSeverite.critique:
        return const Icon(Icons.dangerous, size: 18, color: Colors.purple);
    }
  }

  /// Vérifie si des filtres sont actuellement actifs
  bool _aDesFiltresActifs(ControleurAlertes controleur) {
    return controleur.filtresTypeActifs.isNotEmpty ||
           controleur.filtresSeveriteActifs.isNotEmpty ||
           controleur.afficherSeulementNonLues ||
           controleur.termeRecherche.isNotEmpty;
  }

  /// Gère les actions du menu principal
  void _gererActionMenu(String action, BuildContext context) {
    final controleur = context.read<ControleurAlertes>();
    
    switch (action) {
      case 'marquer_toutes_lues':
        controleur.marquerToutCommeLu();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Toutes les alertes ont été marquées comme lues'),
            duration: Duration(seconds: 2),
          ),
        );
        break;
        
      case 'effacer_filtres':
        controleur.effacerTousLesFiltres();
        _controleurRecherche.clear();
        setState(() {
          _panneauFiltresOuvert = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tous les filtres ont été effacés'),
            duration: Duration(seconds: 2),
          ),
        );
        break;
        
      case 'exporter':
        // TODO: Implémenter l'export PDF
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Export PDF - Fonctionnalité à venir'),
            duration: Duration(seconds: 2),
          ),
        );
        break;
    }
  }

  /// Gère le tap sur une carte d'alerte
  void _gererTapAlerte(ModeleAlerte alerte, ControleurAlertes controleur) {
    // Marquer comme lue si ce n'est pas déjà fait
    if (!alerte.estLu) {
      controleur.marquerCommeLu(alerte.id);
    }
    
    // Naviguer vers la page de détail de l'alerte
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PageDetailAlerte(alerte: alerte),
      ),
    );
  }

  /// Confirme la suppression d'une alerte
  void _confirmerSuppressionAlerte(ModeleAlerte alerte, ControleurAlertes controleur) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'alerte'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${alerte.titre}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              controleur.supprimerAlerte(alerte.id);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Alerte supprimée'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  /// Construction de la section filtre sévérité (correction du nom de méthode)
  Widget _construireSectionFiltreSeverite(ControleurAlertes controleur) {
    return _construireFiltreSeverite(controleur);
  }
}