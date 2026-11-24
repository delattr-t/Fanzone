import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Direction : « l'affiche de match collée sur le mur du gymnase ».
/// Blanc franc, encre noire, un seul accent (flare), gilet fluo pour la jauge.
/// Pas d'ombres, coins quasi droits, règles épaisses. Les couleurs de club
/// servent de rayure d'écharpe, jamais de fond.
class FanZoneColors {
  static const paper    = Color(0xFFFFFFFF);
  static const ink      = Color(0xFF000000);
  static const flare    = Color(0xFFF0471F); // fumigène
  static const hiVis    = Color(0xFFE4FF2E); // gilet fluo : jauge de mobilisation
  static const wall     = Color(0xFFE8E8E3); // béton du gymnase
  static const wallDeep = Color(0xFFD6D6D0);
  static const cement   = Color(0xFF6B6B66);

  // Alias conservés pour les écrans existants
  static const primary    = flare;
  static const dark       = ink;
  static const background = paper;
  static const surface    = paper;
  static const cream      = wall;
  static const border     = wallDeep;
  static const textPrimary   = ink;
  static const textSecondary = cement;
  static const textLight     = cement;
  static const yellow = hiVis;

  // Couleurs clubs (rayures)
  static const red    = Color(0xFFE0251B);
  static const orange = Color(0xFFF0471F);
  static const blue   = Color(0xFF1F4FD8);
  static const purple = Color(0xFF6A2FB5);
  static const green  = Color(0xFF1F8A4C);
  static const teal   = Color(0xFF1B7F79);

  // États
  static const success   = Color(0xFF1F8A4C);
  static const successBg = Color(0xFFE6F4EB);
  static const warning   = Color(0xFF8A6400);
  static const warningBg = Color(0xFFFBF3D6);
  static const error     = Color(0xFFC81E1E);
  static const errorBg   = Color(0xFFFBE7E7);
}

/// Texte courant (Barlow).
TextStyle fz({
  double? fontSize,
  FontWeight? fontWeight,
  Color? color,
  double? height,
  double? letterSpacing,
  FontStyle? fontStyle,
  TextDecoration? decoration,
}) =>
    GoogleFonts.barlow(
      fontSize: fontSize,
      fontWeight: fontWeight ?? FontWeight.w500,
      color: color ?? FanZoneColors.ink,
      height: height,
      letterSpacing: letterSpacing,
      fontStyle: fontStyle,
      decoration: decoration,
    );

/// Titres et chiffres (Barlow Condensed) : les lettres de l'affiche.
TextStyle fzDisplay({
  double? fontSize,
  FontWeight? fontWeight,
  Color? color,
  double? height,
  double? letterSpacing,
}) =>
    GoogleFonts.barlowCondensed(
      fontSize: fontSize,
      fontWeight: fontWeight ?? FontWeight.w700,
      color: color ?? FanZoneColors.ink,
      height: height ?? 0.95,
      letterSpacing: letterSpacing ?? -0.2,
    );

class AppTheme {
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: FanZoneColors.paper,
    colorScheme: const ColorScheme.light(
      primary: FanZoneColors.flare,
      onPrimary: Colors.white,
      secondary: FanZoneColors.ink,
      surface: FanZoneColors.paper,
      onSurface: FanZoneColors.ink,
    ),
    textTheme: GoogleFonts.barlowTextTheme().copyWith(
      displayLarge: fzDisplay(fontSize: 44),
      headlineMedium: fzDisplay(fontSize: 30),
      titleLarge: fzDisplay(fontSize: 24),
      titleMedium: fz(fontSize: 16, fontWeight: FontWeight.w600),
      bodyMedium: fz(fontSize: 15, color: FanZoneColors.ink),
      bodySmall: fz(fontSize: 13, color: FanZoneColors.cement),
      labelSmall: fz(fontSize: 12, fontWeight: FontWeight.w600, color: FanZoneColors.cement),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: FanZoneColors.paper,
      foregroundColor: FanZoneColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: fzDisplay(fontSize: 26),
      iconTheme: const IconThemeData(color: FanZoneColors.ink),
    ),
    cardTheme: const CardThemeData(
      color: FanZoneColors.paper,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(3)),
        side: BorderSide(color: FanZoneColors.ink, width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: FanZoneColors.ink,
        foregroundColor: Colors.white,
        textStyle: fz(fontSize: 15, fontWeight: FontWeight.w600),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(3))),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        elevation: 0,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: FanZoneColors.ink,
        textStyle: fz(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: FanZoneColors.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(3)),
        side: BorderSide(color: FanZoneColors.ink, width: 1.5),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? FanZoneColors.ink : FanZoneColors.cement),
      trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? FanZoneColors.hiVis : FanZoneColors.wall),
      trackOutlineColor: const WidgetStatePropertyAll(FanZoneColors.ink),
    ),
    dividerTheme: const DividerThemeData(color: FanZoneColors.ink, thickness: 1.5, space: 1.5),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: FanZoneColors.ink),
  );
}
