import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../health_monitoring/controllers/health_controller.dart';
import '../../../data/services/service_ia.dart';
import '../../../data/models/modele_suggestion.dart';
import '../widgets/carte_suggestion.dart';

class EcranSuggestions extends StatefulWidget {
  const EcranSuggestions({super.key});

  @override
  State<EcranSuggestions> createState() => _EcranSuggestionsState();
}

class _EcranSuggestionsState extends State<EcranSuggestions> {
  final ServiceIA _serviceIA = ServiceIA();
  List<Suggestion> _suggestions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    setState(() => _isLoading = true);
    
    final healthController = context.read<HealthController>();
    final currentData = healthController.currentHealthData;
    
    if (currentData != null) {
      final suggestions = await _serviceIA.getSuggestions(currentData);
      if (mounted) {
        setState(() {
          _suggestions = suggestions;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conseils IA & Prévention'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSuggestions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _suggestions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 80, color: Colors.green.shade200),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune suggestion pour le moment',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text('Tout semble normal !'),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadSuggestions,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _suggestions.length,
                    itemBuilder: (context, index) {
                      return CarteSuggestion(
                        suggestion: _suggestions[index],
                        onTap: () {
                          // Afficher détails si nécessaire
                        },
                      );
                    },
                  ),
                ),
    );
  }
}
