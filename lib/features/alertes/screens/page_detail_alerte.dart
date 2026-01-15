import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dalys/data/models/modele_alerte.dart';

import '../controllers/controleur_alertes.dart';

/// Page de détail d'une alerte médicale
/// Affiche toutes les informations d'une alerte avec possibilité d'actions
class PageDetailAlerte extends StatefulWidget {
  // Alerte à afficher en détail
  final ModeleAlerte alerte;

  const PageDetailAlerte({
    Key? key,
    required this.alerte,
  }) : super(key: key);

  @override
  State<PageDetailAlerte> createState() => _EtatPageDetailAlerte();
}

class _EtatPageDetailAlerte extends State<PageDetailAlerte> with TickerProviderStateMixin {
  // Contrôleur d'animation pour les actions
  late AnimationController _controleurAnimation;
  late Animation<double> _animationFadeIn;
  
  // Contrôleur pour l'expansion des recommandations
  late AnimationController _controleurExpansion;
  late Animation<double> _animationExpansion;
  
  // État d'expansion des recommandations
  bool _recommandationsEtendues = false;

  @override
  void initState() {
    super.initState();
    
    // Initialiser les animations
    _controleurAnimation = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _controleurExpansion = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _animationFadeIn = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controleurAnimation,
      curve: Curves.easeInOut,
    ));
    
    _animationExpansion = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controleurExpansion,
      curve: Curves.easeInOut,
    ));
    
    // Démarrer l'animation d'entrée
    _controleurAnimation.forward();
    
    // Marquer l'alerte comme lue au bout de 2 secondes
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && !widget.alerte.estLu) {
        context.read<ControleurAlertes>().marquerCommeLu(widget.alerte.id);
      }
    });
  }

  @override
  void dispose() {
    _controleurAnimation.dispose();
    _controleurExpansion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Barre d'application avec couleur selon la sévérité
      appBar: _construireBarreApplication(context),
      
      // Corps principal avec défilement
      body: AnimatedBuilder(
        animation: _animationFadeIn,
        builder: (context, child) {
          return Opacity(
            opacity: _animationFadeIn.value,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - _animationFadeIn.value)),
              child: _construireCorpsPage(context),
            ),
          );
        },
      ),
      
      // Barre d'actions flottante
      bottomNavigationBar: _construireBarreActions(context),
    );
  }

  /// Construit la barre d'application personnalisée
  AppBar _construireBarreApplication(BuildContext context) {
    final couleur = _obtenirCouleurSeverite(widget.alerte.severite);
    
    return AppBar(
      title: Text(
        'Détail de l\'alerte',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      backgroundColor: couleur,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        // Bouton de partage
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () => _partagerAlerte(context),
          tooltip: 'Partager l\'alerte',
        ),
        
        // Menu d'options
        PopupMenuButton<String>(
          onSelected: (action) => _gererActionMenu(context, action),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'marquer_non_lu',
              child: ListTile(
                leading: Icon(Icons.mark_email_unread),
                title: Text('Marquer comme non lu'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'programmer_rappel',
              child: ListTile(
                leading: Icon(Icons.schedule),
                title: Text('Programmer un rappel'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'supprimer',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Supprimer l\'alerte'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Construit le corps principal de la page
  Widget _construireCorpsPage(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // En-tête avec icône et titre
          _construireEnTeteAlerte(),
          
          const SizedBox(height: 24),
          
          // Message principal
          _construireCartePrincipale(),
          
          const SizedBox(height: 16),
          
          // Informations détaillées
          _construireCarteInformations(),
          
          const SizedBox(height: 16),
          
          // Recommandations
          _construireCarteRecommandations(),
          
          const SizedBox(height: 16),
          
          // Actions spécifiques selon le type d'alerte
          _construireActionsSpecifiques(),
          
          const SizedBox(height: 100), // Espace pour la barre d'actions
        ],
      ),
    );
  }

  /// Construit l'en-tête avec icône et informations principales
  Widget _construireEnTeteAlerte() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _obtenirCouleurSeverite(widget.alerte.severite),
            _obtenirCouleurSeverite(widget.alerte.severite).withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _obtenirCouleurSeverite(widget.alerte.severite).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Icône et titre
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.alerte.obtenirIconeType(),
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.alerte.titre,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _obtenirLibelleSeverite(widget.alerte.severite),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Informations temporelles
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.access_time, color: Colors.white70, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    _formaterDateHeure(widget.alerte.horodatage),
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.source, color: Colors.white70, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    widget.alerte.source,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Construit la carte avec le message principal
  Widget _construireCartePrincipale() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.message,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Message détaillé',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.alerte.message,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construit la carte avec les informations détaillées
  Widget _construireCarteInformations() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Informations détaillées',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Type d'alerte
            _construireLigneInformation(
              'Type d\'alerte',
              _obtenirLibelleType(widget.alerte.type),
              Icons.category,
            ),
            
            // Niveau de sévérité
            _construireLigneInformation(
              'Niveau de sévérité',
              _obtenirLibelleSeverite(widget.alerte.severite),
              Icons.priority_high,
            ),
            
            // Priorité
            _construireLigneInformation(
              'Priorité',
              'Niveau ${widget.alerte.priorite}',
              Icons.flag,
            ),
            
            // Statut de lecture
            _construireLigneInformation(
              'Statut',
              widget.alerte.estLu ? 'Lu' : 'Non lu',
              widget.alerte.estLu ? Icons.mark_email_read : Icons.mark_email_unread,
            ),
            
            // Date d'expiration si présente
            if (widget.alerte.dateExpiration != null)
              _construireLigneInformation(
                'Expire le',
                _formaterDateHeure(widget.alerte.dateExpiration!),
                Icons.schedule,
              ),
          ],
        ),
      ),
    );
  }

  /// Construit la carte des recommandations avec expansion
  Widget _construireCarteRecommandations() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // En-tête cliquable
          InkWell(
            onTap: _basculerExpansionRecommandations,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb,
                    color: Colors.amber[700],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Recommandations (${widget.alerte.recommandations.length})',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _recommandationsEtendues ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: const Icon(Icons.expand_more),
                  ),
                ],
              ),
            ),
          ),
          
          // Contenu extensible
          AnimatedBuilder(
            animation: _animationExpansion,
            builder: (context, child) {
              return ClipRect(
                child: Align(
                  heightFactor: _animationExpansion.value,
                  child: child,
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: widget.alerte.recommandations.asMap().entries.map((entry) {
                  final index = entry.key;
                  final recommandation = entry.value;
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            recommandation,
                            style: const TextStyle(fontSize: 15, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construit les actions spécifiques selon le type d'alerte
  Widget _construireActionsSpecifiques() {
    switch (widget.alerte.type) {
      case TypeAlerte.medicale:
        return _construireActionsMedicales();
      case TypeAlerte.environnementale:
        return _construireActionsEnvironnementales();
      case TypeAlerte.ia:
        return _construireActionsIA();
      case TypeAlerte.manuelle:
      case TypeAlerte.critique:
      case TypeAlerte.medicament:
      case TypeAlerte.rendezvous:
      case TypeAlerte.haute:
      case TypeAlerte.basse:
      case TypeAlerte.moyenne:
      case TypeAlerte.rappel:
      case TypeAlerte.systeme:
        return _construireActionsManuelles();
    }
  }

  /// Actions pour les alertes médicales
  Widget _construireActionsMedicales() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_hospital,
                  color: Colors.red[700],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Actions médicales',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Boutons d'action
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _construireBoutonAction(
                  'Appeler médecin',
                  Icons.phone,
                  Colors.red,
                  () => _appelMedecin(context),
                ),
                _construireBoutonAction(
                  'Urgences (15)',
                  Icons.emergency,
                  Colors.red[800]!,
                  () => _appelUrgences(context),
                ),
                _construireBoutonAction(
                  'Prendre mesures',
                  Icons.monitor_heart,
                  Colors.blue,
                  () => _prendreNouvellesMesures(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Actions pour les alertes environnementales
  Widget _construireActionsEnvironnementales() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.nature,
                  color: Colors.green[700],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Actions environnementales',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _construireBoutonAction(
                  'Voir qualité air',
                  Icons.air,
                  Colors.green,
                  () => _voirQualiteAir(context),
                ),
                _construireBoutonAction(
                  'Alertes pollen',
                  Icons.grass,
                  Colors.orange,
                  () => _voirAlertesPollen(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Actions pour les alertes IA
  Widget _construireActionsIA() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.psychology,
                  color: Colors.purple[700],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Actions IA',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _construireBoutonAction(
                  'Voir prédictions',
                  Icons.trending_up,
                  Colors.purple,
                  () => _voirPredictions(context),
                ),
                _construireBoutonAction(
                  'Données sources',
                  Icons.data_usage,
                  Colors.indigo,
                  () => _voirDonneesSources(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Actions pour les alertes manuelles
  Widget _construireActionsManuelles() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person,
                  color: Colors.blue[700],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Actions personnelles',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _construireBoutonAction(
                  'Modifier rappel',
                  Icons.edit,
                  Colors.blue,
                  () => _modifierRappel(context),
                ),
                _construireBoutonAction(
                  'Dupliquer',
                  Icons.copy,
                  Colors.teal,
                  () => _dupliquerAlerte(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Construit la barre d'actions en bas d'écran
  Widget _construireBarreActions(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        child: Row(
          children: [
            // Marquer comme lu/non lu
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _basculerStatutLecture(context),
                icon: Icon(
                  widget.alerte.estLu ? Icons.mark_email_unread : Icons.mark_email_read,
                ),
                label: Text(
                  widget.alerte.estLu ? 'Marquer non lu' : 'Marquer comme lu',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[100],
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Bouton d'action principal
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _executerActionPrincipale(context),
                icon: Icon(_obtenirIconeActionPrincipale()),
                label: Text(_obtenirTexteActionPrincipale()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _obtenirCouleurSeverite(widget.alerte.severite),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widgets utilitaires

  Widget _construireLigneInformation(String label, String valeur, IconData icone) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icone, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              valeur,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construireBoutonAction(
    String texte,
    IconData icone,
    Color couleur,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icone, size: 16),
      label: Text(texte),
      style: ElevatedButton.styleFrom(
        backgroundColor: couleur,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: const TextStyle(fontSize: 12),
      ),
    );
  }

  /// Méthodes d'actions et utilitaires

  void _basculerExpansionRecommandations() {
    setState(() {
      _recommandationsEtendues = !_recommandationsEtendues;
    });
    
    if (_recommandationsEtendues) {
      _controleurExpansion.forward();
    } else {
      _controleurExpansion.reverse();
    }
  }

  void _basculerStatutLecture(BuildContext context) {
    final controleur = context.read<ControleurAlertes>();
    if (widget.alerte.estLu) {
      controleur.marquerCommeNonLu(widget.alerte.id);
    } else {
      controleur.marquerCommeLu(widget.alerte.id);
    }
  }

  void _partagerAlerte(BuildContext context) {
    // TODO: Implémenter le partage d'alerte
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fonctionnalité de partage à implémenter')),
    );
  }

  void _gererActionMenu(BuildContext context, String action) {
    final controleur = context.read<ControleurAlertes>();
    
    switch (action) {
      case 'marquer_non_lu':
        controleur.marquerCommeNonLu(widget.alerte.id);
        break;
      case 'programmer_rappel':
        // TODO: Implémenter programmation de rappel
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Programmation de rappel à implémenter')),
        );
        break;
      case 'supprimer':
        _confirmerSuppressionAlerte(context);
        break;
    }
  }

  void _confirmerSuppressionAlerte(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'alerte'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette alerte ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              context.read<ControleurAlertes>().supprimerAlerte(widget.alerte.id);
              Navigator.of(context).pop(); // Fermer dialog
              Navigator.of(context).pop(); // Retourner à la liste
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _executerActionPrincipale(BuildContext context) {
    switch (widget.alerte.type) {
      case TypeAlerte.medicale:
        if (widget.alerte.estCritique()) {
          _appelUrgences(context);
        } else {
          _prendreNouvellesMesures(context);
        }
        break;
      case TypeAlerte.environnementale:
        _voirQualiteAir(context);
        break;
      case TypeAlerte.ia:
        _voirPredictions(context);
        break;
      case TypeAlerte.manuelle:
      case TypeAlerte.critique:
      case TypeAlerte.medicament:
      case TypeAlerte.rendezvous:
      case TypeAlerte.haute:
      case TypeAlerte.basse:
      case TypeAlerte.moyenne:
      case TypeAlerte.rappel:
      case TypeAlerte.systeme:
        _modifierRappel(context);
        break;
    }
  }

  // Actions spécifiques (à implémenter)
  void _appelMedecin(BuildContext context) {
    // TODO: Intégrer avec l'application téléphone
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fonction d\'appel à implémenter')),
    );
  }

  void _appelUrgences(BuildContext context) {
    // TODO: Appel direct vers le 15
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('URGENCE: Appelez le 15 immédiatement'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _prendreNouvellesMesures(BuildContext context) {
    // TODO: Naviguer vers la page de prise de mesures
    Navigator.of(context).pushNamed('/prise-mesures');
  }

  void _voirQualiteAir(BuildContext context) {
    // TODO: Naviguer vers la page qualité de l'air
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Page qualité de l\'air à implémenter')),
    );
  }

  void _voirAlertesPollen(BuildContext context) {
    // TODO: Naviguer vers les alertes pollen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Alertes pollen à implémenter')),
    );
  }

  void _voirPredictions(BuildContext context) {
    // TODO: Naviguer vers les prédictions IA
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Prédictions IA à implémenter')),
    );
  }

  void _voirDonneesSources(BuildContext context) {
    // TODO: Afficher les données sources
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Données sources à implémenter')),
    );
  }

  void _modifierRappel(BuildContext context) {
    // TODO: Modifier le rappel
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Modification de rappel à implémenter')),
    );
  }

  void _dupliquerAlerte(BuildContext context) {
    // TODO: Dupliquer l'alerte
    context.read<ControleurAlertes>().dupliquerAlerte(widget.alerte.id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Alerte dupliquée avec succès')),
    );
  }

  /// Méthodes utilitaires

  Color _obtenirCouleurSeverite(NiveauSeverite severite) {
    switch (severite) {
      case NiveauSeverite.faible:
        return Colors.green;
      case NiveauSeverite.modere:
        return Colors.orange;
      case NiveauSeverite.eleve:
        return Colors.red;
      case NiveauSeverite.critique:
        return Colors.purple;
    }
  }

  String _obtenirLibelleSeverite(NiveauSeverite severite) {
    switch (severite) {
      case NiveauSeverite.faible:
        return 'Faible';
      case NiveauSeverite.modere:
        return 'Modéré';
      case NiveauSeverite.eleve:
        return 'Élevé';
      case NiveauSeverite.critique:
        return 'Critique';
    }
  }

  String _obtenirLibelleType(TypeAlerte type) {
    switch (type) {
      case TypeAlerte.ia:
        return 'Intelligence Artificielle';
      case TypeAlerte.environnementale:
        return 'Environnementale';
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
    }
  }

  String _formaterDateHeure(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/'
        '${dateTime.month.toString().padLeft(2, '0')}/'
        '${dateTime.year} à '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  IconData _obtenirIconeActionPrincipale() {
    switch (widget.alerte.type) {
      case TypeAlerte.medicale:
        return widget.alerte.estCritique() ? Icons.emergency : Icons.monitor_heart;
      case TypeAlerte.environnementale:
        return Icons.air;
      case TypeAlerte.ia:
        return Icons.trending_up;
      case TypeAlerte.manuelle:
      case TypeAlerte.critique:
      case TypeAlerte.medicament:
      case TypeAlerte.rendezvous:
      case TypeAlerte.haute:
      case TypeAlerte.basse:
      case TypeAlerte.moyenne:
      case TypeAlerte.rappel:
      case TypeAlerte.systeme:
        return Icons.edit;
    }
  }

  String _obtenirTexteActionPrincipale() {
    switch (widget.alerte.type) {
      case TypeAlerte.medicale:
        return widget.alerte.estCritique() ? 'Urgences' : 'Mesures';
      case TypeAlerte.environnementale:
        return 'Qualité air';
      case TypeAlerte.ia:
        return 'Prédictions';
      case TypeAlerte.manuelle:
      case TypeAlerte.critique:
      case TypeAlerte.medicament:
      case TypeAlerte.rendezvous:
      case TypeAlerte.haute:
      case TypeAlerte.basse:
      case TypeAlerte.moyenne:
      case TypeAlerte.rappel:
      case TypeAlerte.systeme:
        return 'Modifier';
    }
  }
}