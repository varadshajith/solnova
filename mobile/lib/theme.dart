import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData buildSolnovaDarkTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  final color = const Color(0xFF0E1217);
  final surface = const Color(0xFF1B222B);
  final teal = const Color(0xFF21C2A1);
  return base.copyWith(
    scaffoldBackgroundColor: color,
    colorScheme: base.colorScheme.copyWith(
      primary: teal,
      secondary: Colors.tealAccent,
      surface: surface,
      onSurface: Colors.white,
    ),
    textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(bodyColor: Colors.white, displayColor: Colors.white),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0),
  );
}

class Spacing {
  static const small = 8.0;
  static const med = 12.0;
  static const large = 16.0;
  static const xlarge = 24.0;
}