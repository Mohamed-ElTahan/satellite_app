import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SatelliteTheme {
  static const Color backgroundSpace = Color(0xFF010409);
  static const Color panelGlass = Color(0x33000000);
  static const Color panelBorder = Color(0x5500E5FF);
  
  static const Color earthLines = Color(0xAA00E5FF);
  
  static const Color satelliteColor = Color(0xFFFFB300);
  static const Color orbitLine = Color(0x66FFB300);
  
  static const Color observerColor = Color(0xFF00FFCC);
  static const Color lineOfSight = Color(0xAAFFFFFF);
  
  static const Color footprintFill = Color(0x33FF0055);
  static const Color footprintEdge = Color(0xAAFF0055);

  static ThemeData get themeData {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundSpace,
      colorScheme: const ColorScheme.dark(
        primary: earthLines,
        secondary: satelliteColor,
        surface: backgroundSpace,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0x44000000), // Darker inputs inside frosted glass
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: earthLines),
        ),
      ),
      textTheme: GoogleFonts.rajdhaniTextTheme(
        ThemeData.dark().textTheme,
      ).copyWith(
        titleMedium: GoogleFonts.orbitron(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        bodyMedium: GoogleFonts.rajdhani(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500),
      ),
    );
  }
}
