import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Direction « Écharpe » : la laine du supporter. Fond laine chaude, encre brun
/// profond, braise pour l'action, soleil pour la mobilisation. Chaque club est
/// représenté par son écharpe tricotée (voir `Scarf` dans widgets/scarf.dart).
class FanZoneColors {
  static const wool     = Color(0xFFF6EDE0); // fond d'écran
  static const paper    = Color(0xFFFFFBF5); // surfaces (cartes, champs)
  static const ink      = Color(0xFF2B1A12); // texte, icônes
  static const flare    = Color(0xFFE2462B); // braise : action principale
  static const hiVis    = Color(0xFFFFB420); // soleil : jauge, état « membre », sélection
  static const wall     = Color(0xFFEFE3D2); // sable : surfaces secondaires
  static const wallDeep = Color(0xFFE3D3BD); // filets
  static const cement   = Color(0xFF7A6253); // texte secondaire
  static const night    = Color(0xFF2B1A12); // fond des blocs « soir de match »
  static const cream    = Color(0xFFFFF3E0); // rayure claire des écharpes

  static const primary    = flare;
  static const dark       = ink;
  static const background = wool;
  static const surface    = paper;
  static const border     = wallDeep;
  static const textPrimary   = ink;
  static const textSecondary = cement;
  static const textLight     = cement;
  static const yellow = hiVis;

  static const red    = Color(0xFFD7263D);
  static const orange = Color(0xFFE2462B);
  static const blue   = Color(0xFF1F5FBF);
  static const purple = Color(0xFF6B3FA0);
  static const green  = Color(0xFF1F7A4D);
  static const teal   = Color(0xFF167A74);

  static const success   = Color(0xFF1F7A4D);
  static const successBg = Color(0xFFE5F2E8);
  static const warning   = Color(0xFF8A5A00);
  static const warningBg = Color(0xFFFFF1D1);
  static const error     = Color(0xFFB8261A);
  static const errorBg   = Color(0xFFFBE4DF);

  static List<BoxShadow> get lift => const [
        BoxShadow(color: Color(0x1A5A3418), offset: Offset(0, 6), blurRadius: 18),
        BoxShadow(color: Color(0x0F5A3418), offset: Offset(0, 1), blurRadius: 3),
      ];
}

TextStyle fz({
  double? fontSize,
  FontWeight? fontWeight,
  Color? color,
  double? height,
  double? letterSpacing,
  FontStyle? fontStyle,
  TextDecoration? decoration,
}) =>
    GoogleFonts.bricolageGrotesque(
      fontSize: fontSize,
      fontWeight: fontWeight ?? FontWeight.w400,
      color: color ?? FanZoneColors.ink,
      height: height,
      letterSpacing: letterSpacing,
      fontStyle: fontStyle,
      decoration: decoration,
      decorationColor: color ?? FanZoneColors.ink,
    );

/// Les tailles des écrans ont été posées pour un caractère condensé ; Bricolage
/// est plus large, d'où le facteur 0.86 qui garde les mêmes encombrements.
TextStyle fzDisplay({
  double? fontSize,
  FontWeight? fontWeight,
  Color? color,
  double? height,
  double? letterSpacing,
}) =>
    GoogleFonts.bricolageGrotesque(
      fontSize: fontSize == null ? null : fontSize * 0.86,
      fontWeight: fontWeight ?? FontWeight.w800,
      color: color ?? FanZoneColors.ink,
      height: height ?? 1.05,
      letterSpacing: letterSpacing ?? -0.4,
    );

class AppTheme {
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: FanZoneColors.wool,
        colorScheme: const ColorScheme.light(
          primary: FanZoneColors.flare,
          onPrimary: Colors.white,
          secondary: FanZoneColors.ink,
          surface: FanZoneColors.paper,
          onSurface: FanZoneColors.ink,
        ),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: FanZoneColors.flare,
          selectionColor: FanZoneColors.hiVis.withValues(alpha: 0.45),
          selectionHandleColor: FanZoneColors.flare,
        ),
        textTheme: GoogleFonts.bricolageGrotesqueTextTheme().copyWith(
          displayLarge: fzDisplay(fontSize: 44),
          headlineMedium: fzDisplay(fontSize: 30),
          titleLarge: fzDisplay(fontSize: 24),
          titleMedium: fz(fontSize: 16, fontWeight: FontWeight.w600),
          bodyMedium: fz(fontSize: 15),
          bodySmall: fz(fontSize: 13, color: FanZoneColors.cement),
          labelSmall: fz(fontSize: 12, fontWeight: FontWeight.w600, color: FanZoneColors.cement),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: FanZoneColors.wool,
          foregroundColor: FanZoneColors.ink,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: fzDisplay(fontSize: 28),
          iconTheme: const IconThemeData(color: FanZoneColors.ink),
        ),
        cardTheme: const CardThemeData(
          color: FanZoneColors.paper,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(18))),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: FanZoneColors.flare,
            foregroundColor: Colors.white,
            textStyle: fz(fontSize: 15, fontWeight: FontWeight.w700),
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            elevation: 0,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: FanZoneColors.ink,
            textStyle: fz(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: FanZoneColors.paper,
          hintStyle: fz(fontSize: 15, color: FanZoneColors.cement),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: FanZoneColors.wallDeep),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: FanZoneColors.wallDeep),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: FanZoneColors.flare, width: 2),
          ),
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: FanZoneColors.paper,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(22))),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: FanZoneColors.paper,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected) ? Colors.white : FanZoneColors.cement),
          trackColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected) ? FanZoneColors.flare : FanZoneColors.wall),
          trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
        ),
        dividerTheme: const DividerThemeData(color: FanZoneColors.wallDeep, thickness: 1, space: 1),
        progressIndicatorTheme: const ProgressIndicatorThemeData(color: FanZoneColors.flare),
      );
}
