import 'package:flutter/material.dart';
import '../../../core/enums/app_enums.dart';

class StatusHeroSection extends StatelessWidget {
  final RiskLevel riskLevel;
  final Widget? action;

  const StatusHeroSection({
    super.key,
    required this.riskLevel,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = _getColor();
    final String statusText = _getStatusText();
    final String subText = _getSubText();
    final IconData icon = _getIcon();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.8), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  statusText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  subText,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (action != null) ...[
            const SizedBox(width: 8),
            action!,
          ],
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
        return "Consultez vos conseils de prévention ci-dessous.";
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
