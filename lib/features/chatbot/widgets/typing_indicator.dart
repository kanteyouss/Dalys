import 'package:flutter/material.dart';

/// Widget affichant un indicateur de frappe animé
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Icon(
              Icons.medical_services,
              size: 18,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.grey.shade800 
                  : Colors.grey.shade200,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _AnimatedDot(controller: _controller, delay: 0),
                const SizedBox(width: 4),
                _AnimatedDot(controller: _controller, delay: 0.2),
                const SizedBox(width: 4),
                _AnimatedDot(controller: _controller, delay: 0.4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Point animé pour l'indicateur de frappe
class _AnimatedDot extends StatelessWidget {
  final AnimationController controller;
  final double delay;

  const _AnimatedDot({
    required this.controller,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final value = (controller.value + delay) % 1.0;
        final opacity = value < 0.5 ? value * 2 : (1 - value) * 2;
        final bounce = value < 0.5 ? -3.0 * (value * 2) : -3.0 * ((1 - value) * 2);
        
        return Transform.translate(
          offset: Offset(0, bounce),
          child: Opacity(
            opacity: 0.3 + (opacity * 0.7),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.grey.shade400 
                    : Colors.grey.shade600,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}
