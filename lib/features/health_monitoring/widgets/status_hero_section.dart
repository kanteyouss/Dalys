import 'package:flutter/material.dart';
import '../../../core/enums/app_enums.dart';

class StatusHeroSection extends StatelessWidget {
  final RiskLevel riskLevel;

  const StatusHeroSection({
    super.key,
    required this.riskLevel,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = _getColor();
    final String statusText = _getStatusText();
    final String subText = _getSubText();
    final IconData icon = _getIcon();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.8), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 48),
          ),
          const SizedBox(height: 16),
          Text(
            statusText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subText,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getColor() {
    switch (riskLevel) {
      case RiskLevel.low:
        return const Color(0xFF4CAF50); // Vert rassurant
      case RiskLevel.medium:
        return const Color(0xFFFFA000); // Orange attention
      case RiskLevel.high:
        return const Color(0xFFE53935); // Rouge urgence
    }
  }

  String _getStatusText() {
    switch (riskLevel) {
      case RiskLevel.low:
        return "Tout va bien";
      case RiskLevel.medium:
        return "Vigilance requise";
      case RiskLevel.high:
        return "Alerte Critique";
    }
  }

  String _getSubText() {
    switch (riskLevel) {
      case RiskLevel.low:
        return "Votre respiration est stable.";
      case RiskLevel.medium:
        return "Suivez les conseils de prévention.";
      case RiskLevel.high:
        return "Suivez le protocole d'urgence.";
    }
  }

  IconData _getIcon() {
    switch (riskLevel) {
      case RiskLevel.low:
        return Icons.check_circle_outline;
      case RiskLevel.medium:
        return Icons.info_outline;
      case RiskLevel.high:
        return Icons.warning_amber_rounded;
    }
  }
}
