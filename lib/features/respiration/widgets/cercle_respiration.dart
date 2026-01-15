import 'package:flutter/material.dart';
import '../services/service_respiration.dart';

class CercleRespiration extends StatefulWidget {
  final PhaseRespiration phase;
  final int dureeTotalePhase;
  final Color couleur;

  const CercleRespiration({
    super.key,
    required this.phase,
    required this.dureeTotalePhase,
    required this.couleur,
  });

  @override
  State<CercleRespiration> createState() => _CercleRespirationState();
}

class _CercleRespirationState extends State<CercleRespiration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.dureeTotalePhase),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _gererAnimation();
  }

  @override
  void didUpdateWidget(CercleRespiration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.phase != widget.phase) {
      _controller.duration = Duration(seconds: widget.dureeTotalePhase);
      _gererAnimation();
    }
  }

  void _gererAnimation() {
    switch (widget.phase) {
      case PhaseRespiration.inspiration:
        _controller.forward(from: 0.0);
        break;
      case PhaseRespiration.expiration:
        _controller.reverse(from: 1.0);
        break;
      case PhaseRespiration.retentionPleine:
      case PhaseRespiration.retentionVide:
        // On garde l'état actuel (bloqué)
        break;
      case PhaseRespiration.repos:
        _controller.stop();
        break;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Container(
          width: 150 * _scaleAnimation.value,
          height: 150 * _scaleAnimation.value,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.couleur.withOpacity(0.3),
            border: Border.all(color: widget.couleur, width: 4),
            boxShadow: [
              BoxShadow(
                color: widget.couleur.withOpacity(0.5),
                blurRadius: 20 * _scaleAnimation.value,
                spreadRadius: 5 * _scaleAnimation.value,
              ),
            ],
          ),
          child: Center(
            child: Text(
              _obtenirTextePhase(),
              style: TextStyle(
                color: widget.couleur,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  String _obtenirTextePhase() {
    switch (widget.phase) {
      case PhaseRespiration.inspiration:
        return "INSPIREZ";
      case PhaseRespiration.retentionPleine:
        return "BLOQUEZ";
      case PhaseRespiration.expiration:
        return "EXPIREZ";
      case PhaseRespiration.retentionVide:
        return "BLOQUEZ";
      default:
        return "";
    }
  }
}
