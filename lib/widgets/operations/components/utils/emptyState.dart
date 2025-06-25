import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';

class EmptyState extends StatelessWidget {
  final String message;
  final bool showClearButton;
  final VoidCallback? onClear;

  const EmptyState({
    Key? key,
    required this.message,
    this.showClearButton = false,
    this.onClear,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.assignment_outlined,
              size: 80,
              color: Color(0xFFCBD5E0),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF718096),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            if (showClearButton)
              NeumorphicButton(
                style: NeumorphicStyle(
                  depth: 2,
                  intensity: 0.7,
                  color: const Color(0xFFF7FAFC),
                  boxShape:
                      NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
                ),
                onPressed: onClear,
                child: const Text(
                  'Limpiar búsqueda',
                  style: TextStyle(
                    color: Color(0xFF3182CE),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
