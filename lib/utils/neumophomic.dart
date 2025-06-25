import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter/material.dart';

NeumorphicStyle neumorphicButtonStyle({Color? color, double depth = 2}) {
  return NeumorphicStyle(
    depth: depth,
    intensity: 0.6,
    color: color ?? const Color(0xFFF7FAFC),
    boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(8)),
  );
}

TextStyle titleTextStyle({Color color = const Color(0xFF2D3748)}) {
  return TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: color,
  );
}

BoxDecoration boxDecoration({Color color = const Color(0xFFF9FAFB)}) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: const Color(0xFFE2E8F0)),
  );
}
