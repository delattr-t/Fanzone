import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Bloc « sticker » : bordure noire épaisse, ombre décalée sans flou.
class StickerBlock extends StatelessWidget {
  final Widget child;
  final Color? borderColor;
  final Color? color;
  final EdgeInsets padding;
  final EdgeInsets margin;
  const StickerBlock({
    super.key,
    required this.child,
    this.borderColor,
    this.color,
    this.padding = const EdgeInsets.all(14),
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final bc = borderColor ?? FanZoneColors.dark;
    return Container(
      width: double.infinity,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? FanZoneColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: bc, width: 2.5),
        boxShadow: [
          BoxShadow(color: bc.withValues(alpha: 0.12), offset: const Offset(3, 3), blurRadius: 0),
        ],
      ),
      child: child,
    );
  }
}

/// Petit libellé en capitales au-dessus d'un bloc.
class StickerLabel extends StatelessWidget {
  final String text;
  const StickerLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          color: FanZoneColors.textLight,
        ),
      ),
    );
  }
}

/// Bouton plein largeur style sticker.
class StickerButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color color;
  final Color textColor;
  final bool outlined;
  final double fontSize;
  const StickerButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color = FanZoneColors.dark,
    this.textColor = Colors.white,
    this.outlined = false,
    this.fontSize = 15,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Opacity(
      opacity: disabled ? 0.45 : 1,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: outlined ? FanZoneColors.surface : color,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color, width: 2.5),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.25), offset: const Offset(4, 4), blurRadius: 0),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                color: outlined ? color : textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pastille colorée (tag, compteur, état).
class StickerPill extends StatelessWidget {
  final String text;
  final Color color;
  final Color? bg;
  final double fontSize;
  const StickerPill(this.text, {super.key, required this.color, this.bg, this.fontSize = 11});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bg ?? color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 2),
      ),
      child: Text(
        text,
        style: TextStyle(fontFamily: 'Nunito', fontSize: fontSize, fontWeight: FontWeight.w900, color: color),
      ),
    );
  }
}

/// Champ de saisie style sticker.
class StickerField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final int maxLines;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;
  const StickerField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StickerLabel(label),
        Container(
          decoration: BoxDecoration(
            color: FanZoneColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: FanZoneColors.dark, width: 2),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            onChanged: onChanged,
            style: const TextStyle(fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.w800, color: FanZoneColors.dark),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              hintText: hint,
              hintStyle: const TextStyle(fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w600, color: FanZoneColors.textLight),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

/// Affiche un toast FanZone (sticker sombre) depuis n'importe quel écran.
void showFanToast(BuildContext context, String text) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(text, style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w800, fontSize: 14, color: Colors.white)),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      backgroundColor: FanZoneColors.dark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ),
  );
}

/// Message vide centré.
class EmptyHint extends StatelessWidget {
  final String emoji;
  final String text;
  const EmptyHint({super.key, required this.emoji, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w700, color: FanZoneColors.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }
}
