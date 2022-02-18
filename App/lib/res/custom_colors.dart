import 'package:flutter/material.dart';

// Color definitions

class CustomColors {
  static final Color navy = Color(0xFF2C384A);
  static final Color orange = Color(0xFFF57C00);
  static final Color amber = Color(0xFFFFA000);
  static final Color yellow = Color(0xFFFFCA28);
  static final Color grey = Color(0xFFECEFF1);
  static final Color googleBackground = Color(0xFF4285F4);
  static const Color ledColor = Colors.deepOrange;
  static const Color sensorColor = Colors.blue;
  static const Color servoColor = Colors.amber;
}

Color darken(Color color, [double amount = .1]) {
  assert(amount >= 0 && amount <= 1);

  final hsl = HSLColor.fromColor(color);
  final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));

  return hslDark.toColor();
}

Color lighten(Color color, [double amount = .1]) {
  assert(amount >= 0 && amount <= 1);

  final hsl = HSLColor.fromColor(color);
  final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));

  return hslLight.toColor();
}