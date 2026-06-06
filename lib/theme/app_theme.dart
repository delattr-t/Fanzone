import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FanZoneColors {
  // Palette principale
  static const primary    = Color(0xFFFF8C00); // Orange FanZone
  static const dark       = Color(0xFF1A1A1A); // Noir
  static const background = Color(0xFFFFFDF9); // Blanc chaud
  static const surface    = Color(0xFFFFFFFF); // Blanc pur (cartes)
  static const cream      = Color(0xFFF2EDE4); // Crème (surfaces secondaires)
  static const border     = Color(0xFFE0E0E0); // Bordure légère
  static const textPrimary   = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF888888);
  static const textLight     = Color(0xFFAAAAAA);

  // Couleurs clubs
  static const red    = Color(0xFFFF4D4D);
  static const orange = Color(0xFFFF8C00);
  static const blue   = Color(0xFF0096FF);
  static const purple = Color(0xFF9B27AF);
  static const green  = Color(0xFF00A86B);
  static const teal   = Color(0xFF2A9D8F);

  // States
  static const success = Color(0xFF2E7D32);
  static const successBg = Color(0xFFE8F5E9);
  static const warning = Color(0xFFB8860B);
  static const warningBg = Color(0xFFFFF9E6);
  static const error = Color(0xFFC62828);
  static const errorBg = Color(0xFFFFEBEE);

  // Yellow accent (sticker)
  static const yellow = Color(0xFFFFD166);
}

class AppTheme {
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: FanZoneColors.background,
    colorScheme: ColorScheme.light(
      primary: FanZoneColors.primary,
      onPrimary: Colors.white,
      secondary: FanZoneColors.dark,
      surface: FanZoneColors.surface,
      onSurface: FanZoneColors.textPrimary,
    ),
    textTheme: GoogleFonts.nunitoTextTheme().copyWith(
      displayLarge: GoogleFonts.nunito(
        fontWeight: FontWeight.w900,
        fontSize: 28,
        color: FanZoneColors.textPrimary,
      ),
      headlineMedium: GoogleFonts.nunito(
        fontWeight: FontWeight.w900,
        fontSize: 22,
        color: FanZoneColors.textPrimary,
      ),
      titleLarge: GoogleFonts.nunito(
        fontWeight: FontWeight.w900,
        fontSize: 18,
        color: FanZoneColors.textPrimary,
      ),
      titleMedium: GoogleFonts.nunito(
        fontWeight: FontWeight.w800,
        fontSize: 15,
        color: FanZoneColors.textPrimary,
      ),
      bodyMedium: GoogleFonts.nunito(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: FanZoneColors.textSecondary,
      ),
      bodySmall: GoogleFonts.nunito(
        fontWeight: FontWeight.w600,
        fontSize: 12,
        color: FanZoneColors.textLight,
      ),
      labelSmall: GoogleFonts.nunito(
        fontWeight: FontWeight.w700,
        fontSize: 10,
        letterSpacing: 0.8,
        color: FanZoneColors.textLight,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: FanZoneColors.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: GoogleFonts.nunito(
        fontWeight: FontWeight.w900,
        fontSize: 20,
        color: FanZoneColors.textPrimary,
      ),
      iconTheme: const IconThemeData(color: FanZoneColors.textPrimary),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: FanZoneColors.surface,
      selectedItemColor: FanZoneColors.primary,
      unselectedItemColor: FanZoneColors.textLight,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: FanZoneColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: FanZoneColors.border, width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: FanZoneColors.dark,
        foregroundColor: Colors.white,
        textStyle: GoogleFonts.nunito(fontWeight: FontWeight.w900, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        elevation: 0,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: FanZoneColors.cream,
      labelStyle: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 11),
      side: const BorderSide(color: FanZoneColors.border, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    ),
    dividerTheme: const DividerThemeData(
      color: FanZoneColors.border,
      thickness: 1,
    ),
  );
}
