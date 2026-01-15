import 'package:flutter/material.dart';
import 'package:dalys/data/models/modele_alerte.dart';


/// Widget réutilisable pour afficher une alerte dans une liste
/// Présente les informations principales avec un design adapté au niveau de sévérité
class CarteAlerte extends StatelessWidget {
  // L'alerte à afficher
  final ModeleAlerte alerte;
  
  // Callback appelé lors du tap sur la carte
  final VoidCallback? surTap;
  
  // Callback pour marquer l'alerte comme lue
  final VoidCallback? surMarquerCommeLu;
  
  // Callback pour supprimer l'alerte
  final VoidCallback? surSupprimer;
  
  // Indique si la carte doit être compacte (moins de détails)
  final bool modeCompact;

  /// Constructeur du widget CarteAlerte
  const CarteAlerte({
    super.key,
    required this.alerte,
    this.surTap,
    this.surMarquerCommeLu,
    this.surSupprimer,
    this.modeCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      // Élévation plus importante pour les alertes critiques
      elevation: alerte.estCritique() ? 8.0 : 2.0,
      
      // Bordure colorée selon la sévérité pour les alertes critiques
      shape: alerte.estCritique() 
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
              side: BorderSide(
                color: _obtenirCouleurSeverite(),
                width: 2.0,
              ),
            )
          : RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
      
      // Couleur de fond selon l'état de lecture et la sévérité
      color: _obtenirCouleurFond(context),
      
      child: InkWell(
        // Callback de tap sur toute la carte
        onTap: surTap,
        borderRadius: BorderRadius.circular(12.0),
        
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec type, sévérité et actions
              _construireEnTete(context),
              
              const SizedBox(height: 12),
              
              // Titre principal de l'alerte
              _construireTitre(context),
              
              const SizedBox(height: 8),
              
              // Message de l'alerte (tronqué en mode compact)
              _construireMessage(context),
              
              // Recommandations (seulement en mode détaillé pour les alertes importantes)
              if (!modeCompact && (alerte.estCritique() || alerte.recommandations.length > 20))
                ...[
                  const SizedBox(height: 12),
                  _construireRecommandations(context),
                ],
              
              const SizedBox(height: 12),
              
              // Pied avec horodatage, source et actions
              _construirePied(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Construit l'en-tête avec le type d'alerte, la sévérité et les actions rapides
  Widget _construireEnTete(BuildContext context) {
    return Row(
      children: [
        // Badge du type d'alerte avec icône
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          decoration: BoxDecoration(
            color: _obtenirCouleurType().withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: _obtenirCouleurType().withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                alerte.obtenirIconeType(),
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(width: 4),
              Text(
                _obtenirNomTypeAlerte(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _obtenirCouleurType(),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(width: 8),
        
        // Badge de sévérité
        _construireBadgeSeverite(),
        
        const Spacer(),
        
        // Indicateur "non lu" si l'alerte n'est pas lue
        if (!alerte.estLu)
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
        
        const SizedBox(width: 8),
        
        // Menu d'actions
        _construireMenuActions(context),
      ],
    );
  }

  /// Construit le badge de sévérité avec couleur appropriée
  Widget _construireBadgeSeverite() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: _obtenirCouleurSeverite(),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Text(
        _obtenirNomSeverite().toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  /// Construit le menu d'actions (marquer lu, supprimer)
  Widget _construireMenuActions(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 20),
      tooltip: 'Actions',
      onSelected: (valeur) => _gererActionMenu(valeur),
      itemBuilder: (context) => [
        // Action marquer comme lu (seulement si non lu)
        if (!alerte.estLu)
          const PopupMenuItem(
            value: 'marquer_lu',
            child: ListTile(
              leading: Icon(Icons.done, size: 20),
              title: Text('Marquer comme lu'),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
        
        // Action copier le contenu
        const PopupMenuItem(
          value: 'copier',
          child: ListTile(
            leading: Icon(Icons.copy, size: 20),
            title: Text('Copier le contenu'),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
        
        // Action partager
        const PopupMenuItem(
          value: 'partager',
          child: ListTile(
            leading: Icon(Icons.share, size: 20),
            title: Text('Partager'),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
        
        // Séparateur
        const PopupMenuDivider(),
        
        // Action supprimer
        const PopupMenuItem(
          value: 'supprimer',
          child: ListTile(
            leading: Icon(Icons.delete, size: 20, color: Colors.red),
            title: Text('Supprimer', style: TextStyle(color: Colors.red)),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
      ],
    );
  }

  /// Construit le titre de l'alerte avec mise en forme appropriée
  Widget _construireTitre(BuildContext context) {
    return Text(
      alerte.titre,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: alerte.estLu ? FontWeight.normal : FontWeight.bold,
        color: alerte.estCritique() 
            ? _obtenirCouleurSeverite()
            : Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  /// Construit le message de l'alerte avec troncature si nécessaire
  Widget _construireMessage(BuildContext context) {
    String messageAffiche = alerte.message;
    
    // Tronquer le message en mode compact ou s'il est très long
    if (modeCompact || messageAffiche.length > 150) {
      messageAffiche = messageAffiche.length > 150 
          ? '${messageAffiche.substring(0, 147)}...'
          : messageAffiche;
    }
    
    return Text(
      messageAffiche,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: alerte.estLu 
            ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)
            : Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  /// Construit la section des recommandations pour les alertes importantes
  Widget _construireRecommandations(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: _obtenirCouleurSeverite().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: _obtenirCouleurSeverite().withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 16,
            color: _obtenirCouleurSeverite(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recommandations',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _obtenirCouleurSeverite(),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  alerte.recommandations.isNotEmpty 
                      ? alerte.recommandations.first 
                      : 'Aucune recommandation',
                  style: TextStyle(
                    fontSize: 12,
                    color: _obtenirCouleurSeverite().withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Construit le pied avec horodatage, source et actions secondaires
  Widget _construirePied(BuildContext context) {
    return Row(
      children: [
        // Horodatage de l'alerte
        Icon(
          Icons.access_time,
          size: 14,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 4),
        Text(
          _formaterHorodatage(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Source de l'alerte
        Icon(
          Icons.source,
          size: 14,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            alerte.source,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        
        // Bouton d'action rapide pour les alertes critiques
        if (alerte.estCritique() && !alerte.estLu)
          TextButton.icon(
            onPressed: surMarquerCommeLu,
            icon: const Icon(Icons.done, size: 16),
            label: const Text('Lu'),
            style: TextButton.styleFrom(
              minimumSize: const Size(60, 30),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
      ],
    );
  }

  /// Méthodes utilitaires pour l'affichage et les couleurs
  
  /// Retourne la couleur associée au type d'alerte
  Color _obtenirCouleurType() {
    switch (alerte.type) {
      case TypeAlerte.ia:
        return Colors.purple;
      case TypeAlerte.environnementale:
        return Colors.green;
      case TypeAlerte.medicale:
        return Colors.blue;
      case TypeAlerte.manuelle:
      case TypeAlerte.critique:
      case TypeAlerte.medicament:
      case TypeAlerte.rendezvous:
      case TypeAlerte.haute:
      case TypeAlerte.basse:
      case TypeAlerte.moyenne:
      case TypeAlerte.rappel:
      case TypeAlerte.systeme:
        return Colors.grey;
    }
  }

  /// Retourne la couleur associée au niveau de sévérité
  Color _obtenirCouleurSeverite() {
    switch (alerte.severite) {
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

  /// Retourne la couleur de fond de la carte selon l'état et la sévérité
  Color? _obtenirCouleurFond(BuildContext context) {
    if (alerte.estCritique() && !alerte.estLu) {
      return _obtenirCouleurSeverite().withValues(alpha: 0.05);
    }
    if (!alerte.estLu) {
      return Theme.of(context).colorScheme.primary.withValues(alpha: 0.02);
    }
    return null; // Couleur par défaut de la carte
  }

  /// Retourne le nom d'affichage du type d'alerte
  String _obtenirNomTypeAlerte() {
    switch (alerte.type) {
      case TypeAlerte.ia:
        return 'IA';
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
    }
  }

  /// Retourne le nom d'affichage du niveau de sévérité
  String _obtenirNomSeverite() {
    switch (alerte.severite) {
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

  /// Formate l'horodatage de l'alerte de manière lisible
  String _formaterHorodatage() {
    final maintenant = DateTime.now();
    final difference = maintenant.difference(alerte.horodatage);
    
    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes}min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays}j';
    } else {
      // Format date complète pour les alertes plus anciennes
      return '${alerte.horodatage.day}/${alerte.horodatage.month}/${alerte.horodatage.year}';
    }
  }

  /// Gère les actions du menu contextuel
  void _gererActionMenu(String action) {
    switch (action) {
      case 'marquer_lu':
        surMarquerCommeLu?.call();
        break;
        
      case 'copier':
        // TODO: Implémenter la copie vers le presse-papiers
        break;
        
      case 'partager':
        // TODO: Implémenter le partage système
        break;
        
      case 'supprimer':
        surSupprimer?.call();
        break;
    }
  }
}