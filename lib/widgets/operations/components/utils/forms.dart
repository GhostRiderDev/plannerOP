//  WIDGETS HELPER
import 'package:flutter/material.dart';

Widget buildFormSection({
  required String title,
  required List<Widget> children,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF718096),
        ),
      ),
      const SizedBox(height: 8),
      ...children,
    ],
  );
}

Widget buildValidationMessage() {
  return Padding(
    padding: const EdgeInsets.only(top: 12.0),
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              color: Colors.red.shade700, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Los campos marcados con * son obligatorios',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red.shade700,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
