import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dalys/data/models/modele_alerte.dart';
import 'package:dalys/features/alertes/providers/alertes_provider.dart';

/// Écran de test pour validation du système d'alertes
class EcranTestAlertes extends StatefulWidget {
  const EcranTestAlertes({Key? key}) : super(key: key);

  @override
  State<EcranTestAlertes> createState() => _EcranTestAlertesState();
}

class _EcranTestAlertesState extends State<EcranTestAlertes> {
  int _ongletActuel = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test du Système d\'Alertes'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<AlertesProvider>().forcerMiseAJour();
            },
            tooltip: 'Actualiser',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _afficherParametres(context),
            tooltip: 'Paramètres',
          ),
        ],
      ),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            TabBar(
              onTap: (index) => setState(() => _ongletActuel = index),
              tabs: const [
                Tab(icon: Icon(Icons.warning), text: 'Actives'),
                Tab(icon: Icon(Icons.history), text: 'Historique'),
                Tab(icon: Icon(Icons.analytics), text: 'Statistiques'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _construireOngletActives(),
                  _construireOngletHistorique(),
                  _construireOngletStatistiques(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _testerSysteme(context),
        backgroundColor: Colors.green,
        child: const Icon(Icons.play_arrow),
        tooltip: 'Lancer test complet',
      ),
    );
  }

  /// Onglet des alertes actives
  Widget _construireOngletActives() {
    return Consumer<AlertesProvider>(
      builder: (context, provider, child) {
        if (provider.chargementEnCours) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Chargement des alertes...'),
              ],
            ),
          );
        }

        if (provider.erreurChargement != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red.shade400),
                const SizedBox(height: 16),
                Text(
                  provider.erreurChargement!,
                  style: TextStyle(color: Colors.red.shade600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.forcerMiseAJour(),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }

        final alertes = provider.alertesActives;
        if (alertes.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 64, color: Colors.green),
                SizedBox(height: 16),
                Text(
                  'Aucune alerte active',
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 8),
                Text(
                  'Tout va bien !',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: alertes.length,
          itemBuilder: (context, index) {
            final alerte = alertes[index];
            return _construireCarteAlerte(alerte, provider);
          },
        );
      },
    );
  }

  /// Onglet de l'historique
  Widget _construireOngletHistorique() {
    return Consumer<AlertesProvider>(
      builder: (context, provider, child) {
        final historique = provider.historiqueFiltre;
        
        return Column(
          children: [
            // Barre de recherche et filtres
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Rechercher...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (valeur) {
                        provider.appliquerFiltres(recherche: valeur);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed: () => _afficherFiltres(context, provider),
                    tooltip: 'Filtres',
                  ),
                ],
              ),
            ),
            // Liste de l'historique
            Expanded(
              child: historique.isEmpty
                  ? const Center(
                      child: Text('Aucune alerte dans l\'historique'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: historique.length,
                      itemBuilder: (context, index) {
                        final alerte = historique[index];
                        return _construireCarteHistorique(alerte, provider);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  /// Onglet des statistiques
  Widget _construireOngletStatistiques() {
    return Consumer<AlertesProvider>(
      builder: (context, provider, child) {
        final stats = provider.obtenirStatistiquesGenerales();
        final statsHistorique = provider.statistiquesHistorique;
        
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _construireCarteStatistique(
              'Alertes Actives',
              stats['alertes_actives'].toString(),
              Icons.warning,
              Colors.orange,
            ),
            const SizedBox(height: 16),
            _construireCarteStatistique(
              'Total Historique',
              stats['historique_total'].toString(),
              Icons.history,
              Colors.blue,
            ),
            const SizedBox(height: 16),
            _construireRepartitionPriorite(stats['par_priorite']),
            const SizedBox(height: 16),
            _construireRepartitionType(stats['par_type']),
            const SizedBox(height: 16),
            _construireEtatServices(stats['services_actifs']),
            const SizedBox(height: 16),
            _construireConfiguration(stats['configuration']),
          ],
        );
      },
    );
  }

  /// Construit une carte d'alerte active
  Widget _construireCarteAlerte(ModeleAlerte alerte, AlertesProvider provider) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _obtenirCouleurPriorite(alerte.niveauPriorite),
          child: Icon(
            alerte.type.icone,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          alerte.titre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              alerte.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  _formaterDuree(alerte.dateCreation),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _obtenirCouleurPriorite(alerte.niveauPriorite).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Priorité ${alerte.niveauPriorite}',
                    style: TextStyle(
                      fontSize: 10,
                      color: _obtenirCouleurPriorite(alerte.niveauPriorite),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'acquitter',
              child: Row(
                children: [
                  Icon(Icons.check),
                  SizedBox(width: 8),
                  Text('Acquitter'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'details',
              child: Row(
                children: [
                  Icon(Icons.info),
                  SizedBox(width: 8),
                  Text('Détails'),
                ],
              ),
            ),
          ],
          onSelected: (valeur) {
            switch (valeur) {
              case 'acquitter':
                provider.acquitterAlerte(alerte.id);
                break;
              case 'details':
                _afficherDetailsAlerte(context, alerte);
                break;
            }
          },
        ),
      ),
    );
  }

  /// Construit une carte d'historique
  Widget _construireCarteHistorique(ModeleAlerte alerte, AlertesProvider provider) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2),
      elevation: 1,
      child: ListTile(
        dense: true,
        leading: Icon(
          alerte.statut.icone,
          color: alerte.statut.couleur,
          size: 20,
        ),
        title: Text(
          alerte.titre,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: alerte.statut == StatutAlerte.resolue 
                ? Colors.grey.shade600 
                : null,
          ),
        ),
        subtitle: Text(
          _formaterDuree(alerte.dateCreation),
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _obtenirCouleurPriorite(alerte.niveauPriorite),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              alerte.type.libelle,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        onTap: () => _afficherDetailsAlerte(context, alerte),
      ),
    );
  }

  /// Construit une carte de statistique
  Widget _construireCarteStatistique(String titre, String valeur, IconData icone, Color couleur) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: couleur.withOpacity(0.2),
              child: Icon(icone, color: couleur),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titre,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  valeur,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Construit la répartition par priorité
  Widget _construireRepartitionPriorite(Map<String, int> repartition) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Répartition par Priorité',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...repartition.entries.map((entry) {
              final couleur = _obtenirCouleurNomPriorite(entry.key);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: couleur,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(entry.key.replaceAll('_', ' ').toUpperCase()),
                    ),
                    Text(
                      entry.value.toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  /// Construit la répartition par type
  Widget _construireRepartitionType(Map<String, int> repartition) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Répartition par Type',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...repartition.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(entry.key.replaceAll('_', ' ').toUpperCase()),
                    ),
                    Text(
                      entry.value.toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  /// Construit l'état des services
  Widget _construireEtatServices(Map<String, bool> services) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'État des Services',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...services.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      entry.value ? Icons.check_circle : Icons.cancel,
                      color: entry.value ? Colors.green : Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(entry.key.toUpperCase()),
                    ),
                    Text(
                      entry.value ? 'ACTIF' : 'INACTIF',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: entry.value ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  /// Construit la configuration
  Widget _construireConfiguration(Map<String, dynamic> config) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configuration',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _construireLigneConfig('Mode Simulation', config['mode_simulation'].toString()),
            _construireLigneConfig('Intervalle MAJ', '${config['intervalle_maj']} min'),
            _construireLigneConfig('MAJ Automatique', config['maj_automatique'].toString()),
          ],
        ),
      ),
    );
  }

  /// Construit une ligne de configuration
  Widget _construireLigneConfig(String label, String valeur) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            valeur,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// Affiche les paramètres
  void _afficherParametres(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Paramètres'),
        content: Consumer<AlertesProvider>(
          builder: (context, provider, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('Alertes IA'),
                  value: provider.alertesIAActivees,
                  onChanged: provider.configurerAlertesIA,
                ),
                SwitchListTile(
                  title: const Text('Alertes Environnementales'),
                  value: provider.alertesEnvironnementalesActivees,
                  onChanged: provider.configurerAlertesEnvironnementales,
                ),
                SwitchListTile(
                  title: const Text('Notifications'),
                  value: provider.notificationsActivees,
                  onChanged: provider.configurerNotifications,
                ),
                SwitchListTile(
                  title: const Text('Mode Simulation'),
                  value: provider.modeSimulation,
                  onChanged: provider.configurerModeSimulation,
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  /// Affiche les filtres
  void _afficherFiltres(BuildContext context, AlertesProvider provider) {
    // Interface de filtres simplifiée pour le test
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtres'),
        content: const Text('Filtres avancés à implémenter'),
        actions: [
          TextButton(
            onPressed: () {
              provider.effacerFiltres();
              Navigator.of(context).pop();
            },
            child: const Text('Effacer'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  /// Affiche les détails d'une alerte
  void _afficherDetailsAlerte(BuildContext context, ModeleAlerte alerte) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(alerte.titre),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Type: ${alerte.type.libelle}'),
              Text('Priorité: ${alerte.niveauPriorite}'),
              Text('Statut: ${alerte.statut.libelle}'),
              Text('Date: ${_formaterDate(alerte.dateCreation)}'),
              const SizedBox(height: 12),
              const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(alerte.description),
              if (alerte.recommandations.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Recommandations:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...alerte.recommandations.map((rec) => Text('• $rec')),
              ],
              if (alerte.source.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Source: ${alerte.source}'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  /// Lance un test complet du système
  void _testerSysteme(BuildContext context) async {
    final provider = context.read<AlertesProvider>();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Text('Test en cours...'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Test du système d\'alertes'),
          ],
        ),
      ),
    );
    
    try {
      // Test de connectivité
      final connectivite = await provider.testerConnectiviteServices();
      
      // Force une mise à jour
      await provider.forcerMiseAJour();
      
      Navigator.of(context).pop(); // Fermer le dialog de chargement
      
      // Afficher les résultats
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Résultats du Test'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('IA: ${connectivite['ia']! ? '✅' : '❌'}'),
              Text('Environnemental: ${connectivite['environnemental']! ? '✅' : '❌'}'),
              Text('Notifications: ${connectivite['notifications']! ? '✅' : '❌'}'),
              const SizedBox(height: 12),
              Text('Alertes générées: ${provider.alertesActives.length}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      
    } catch (erreur) {
      Navigator.of(context).pop(); // Fermer le dialog de chargement
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Erreur de Test'),
          content: Text('Erreur: $erreur'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  /// Utilitaires

  Color _obtenirCouleurPriorite(int priorite) {
    if (priorite >= 90) return Colors.red;
    if (priorite >= 70) return Colors.orange;
    if (priorite >= 50) return Colors.yellow.shade700;
    return Colors.green;
  }

  Color _obtenirCouleurNomPriorite(String nom) {
    switch (nom) {
      case 'critique': return Colors.red;
      case 'elevee': return Colors.orange;
      case 'moyenne': return Colors.yellow.shade700;
      case 'faible': return Colors.green;
      default: return Colors.grey;
    }
  }

  String _formaterDuree(DateTime date) {
    final maintenant = DateTime.now();
    final difference = maintenant.difference(date);
    
    if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes}min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else {
      return 'Il y a ${difference.inDays}j';
    }
  }

  String _formaterDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
           '${date.month.toString().padLeft(2, '0')}/'
           '${date.year} à '
           '${date.hour.toString().padLeft(2, '0')}:'
           '${date.minute.toString().padLeft(2, '0')}';
  }
}