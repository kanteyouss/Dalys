import 'package:flutter/material.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/report_service.dart';
import '../../../data/repositories/health_repository.dart';

class ShareCenter extends StatefulWidget {
  const ShareCenter({super.key});

  @override
  State<ShareCenter> createState() => _ShareCenterState();
}

class _ShareCenterState extends State<ShareCenter> {
  final _authService = AuthService();
  final _reportService = ReportService();
  final _healthRepo = HealthRepository();
  bool _isGenerating = false;

  Future<void> _generateReport() async {
    final user = _authService.currentUser;
    if (user == null) return;

    setState(() => _isGenerating = true);

    try {
      final data =
          await _healthRepo.getHealthData(userId: user.id!, limit: 100);
      await _reportService.generateAndShareReport(user: user, data: data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erreur lors de la génération du rapport : $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<void> _downloadReport() async {
    final user = _authService.currentUser;
    if (user == null) return;

    setState(() => _isGenerating = true);

    try {
      final data =
          await _healthRepo.getHealthData(userId: user.id!, limit: 100);
      await _reportService.generateAndPrintReport(user: user, data: data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erreur lors de l\'impression du rapport : $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Partage des Données'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.picture_as_pdf_outlined,
              size: 80,
              color: Color(0xFF2E7D8A),
            ),
            const SizedBox(height: 24),
            const Text(
              'Rapport Médical',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Générez un rapport PDF complet de vos données de santé des 30 derniers jours pour votre médecin.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _isGenerating ? null : _downloadReport,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                backgroundColor: const Color(0xFF2E7D8A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.download),
              label: const Text(
                'Télécharger / Imprimer le PDF',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _isGenerating ? null : _generateReport,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                side: const BorderSide(color: Color(0xFF2E7D8A), width: 2),
                foregroundColor: const Color(0xFF2E7D8A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.share),
              label: const Text(
                'Partager via WhatsApp / Autre',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
