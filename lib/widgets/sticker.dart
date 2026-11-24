import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Composants de l'affiche : encre noire, règles, aucune ombre.

/// Cadre à l'encre. `stripe` = rayure d'écharpe (couleur du club) à gauche.
class StickerBlock extends StatelessWidget {
  final Widget child;
  final Color? borderColor;
  final Color? color;
  final Color? stripe;
  final EdgeInsets padding;
  final EdgeInsets margin;
  const StickerBlock({
    super.key,
    required this.child,
    this.borderColor,
    this.color,
    this.stripe,
    this.padding = const EdgeInsets.all(14),
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final bc = borderColor ?? FanZoneColors.ink;
    return Container(
      width: double.infinity,
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? FanZoneColors.paper,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: bc, width: 1.5),
      ),
      child: stripe == null
          ? Padding(padding: padding, child: child)
          : Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 6, color: stripe),
                Expanded(child: Padding(padding: padding, child: child)),
              ],
            ),
    );
  }
}

/// Petit intitulé au-dessus d'un bloc (phrase en minuscules, pas de capitales).
class StickerLabel extends StatelessWidget {
  final String text;
  const StickerLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: fz(fontSize: 13, fontWeight: FontWeight.w600, color: FanZoneColors.cement)),
    );
  }
}

/// Titre de section : condensé, souligné d'une règle épaisse.
class SectionTitle extends StatelessWidget {
  final String text;
  final String? trailing;
  final VoidCallback? onTrailing;
  const SectionTitle(this.text, {super.key, this.trailing, this.onTrailing});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: Text(text, style: fzDisplay(fontSize: 26))),
            if (trailing != null)
              GestureDetector(
                onTap: onTrailing,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    trailing!,
                    style: fz(fontSize: 14, fontWeight: FontWeight.w600, decoration: TextDecoration.underline),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Container(height: 3, color: FanZoneColors.ink),
      ],
    );
  }
}

/// Monogramme de club : deux lettres dans la couleur du club.
class Monogram extends StatelessWidget {
  final String name;
  final Color color;
  final double size;
  const Monogram({super.key, required this.name, required this.color, this.size = 40});

  static String initials(String name) {
    final words = name.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) return words.first.substring(0, words.first.length >= 2 ? 2 : 1).toUpperCase();
    return (words[0][0] + words[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: FanZoneColors.ink, width: 1.5),
      ),
      child: Center(
        child: Text(
          initials(name),
          style: fzDisplay(fontSize: size * 0.48, color: Colors.white, letterSpacing: 0.5),
        ),
      ),
    );
  }
}

/// Date comme sur un tableau d'affichage : jour en gros, mois dessous.
class DateBlock extends StatelessWidget {
  final String isoDate;
  final double size;
  const DateBlock({super.key, required this.isoDate, this.size = 56});

  @override
  Widget build(BuildContext context) {
    DateTime? d;
    try {
      d = DateTime.parse(isoDate);
    } catch (_) {}
    const months = ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];
    const days = ['lun.', 'mar.', 'mer.', 'jeu.', 'ven.', 'sam.', 'dim.'];
    return Container(
      width: size,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: FanZoneColors.ink,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(d == null ? '' : days[d.weekday - 1], style: fz(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600)),
          Text(d == null ? '?' : '${d.day}', style: fzDisplay(fontSize: size * 0.5, color: Colors.white, height: 1)),
          Text(d == null ? '' : months[d.month - 1], style: fz(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Jauge de mobilisation : barre encadrée, remplissage gilet fluo.
class Gauge extends StatelessWidget {
  final int value;
  final int capacity;
  final double height;
  const Gauge({super.key, required this.value, required this.capacity, this.height = 12});

  @override
  Widget build(BuildContext context) {
    final pct = capacity == 0 ? 0.0 : (value / capacity).clamp(0.0, 1.0);
    return Container(
      height: height,
      decoration: BoxDecoration(
        border: Border.all(color: FanZoneColors.ink, width: 1.5),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: pct,
          child: Container(color: FanZoneColors.hiVis),
        ),
      ),
    );
  }
}

/// Bouton plein largeur. `color` = fond (encre par défaut) ; `outlined` = cadre seul.
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
    this.color = FanZoneColors.ink,
    this.textColor = Colors.white,
    this.outlined = false,
    this.fontSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Opacity(
      opacity: disabled ? 0.4 : 1,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: outlined ? FanZoneColors.paper : color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: outlined ? color : FanZoneColors.ink, width: 1.5),
          ),
          child: Center(
            child: Text(
              label,
              style: fz(fontSize: fontSize, fontWeight: FontWeight.w600, color: outlined ? color : textColor),
            ),
          ),
        ),
      ),
    );
  }
}

/// Étiquette : trait fin, texte compact. `bg` fond optionnel.
class StickerPill extends StatelessWidget {
  final String text;
  final Color color;
  final Color? bg;
  final double fontSize;
  const StickerPill(this.text, {super.key, required this.color, this.bg, this.fontSize = 12});

  @override
  Widget build(BuildContext context) {
    final filled = bg != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg ?? FanZoneColors.paper,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: filled ? bg! : color, width: 1.5),
      ),
      child: Text(text, style: fz(fontSize: fontSize, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

/// Champ de saisie : trait d'encre, pas de fond.
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
            color: FanZoneColors.paper,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: FanZoneColors.ink, width: 1.5),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            onChanged: onChanged,
            style: fz(fontSize: 15, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              hintText: hint,
              hintStyle: fz(fontSize: 14, color: FanZoneColors.cement),
            ),
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }
}

/// Toast : bandeau noir, texte blanc.
void showFanToast(BuildContext context, String text) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(text, style: fz(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      backgroundColor: FanZoneColors.ink,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(3))),
      margin: const EdgeInsets.all(16),
    ),
  );
}

/// État vide : une phrase qui dit quoi faire.
class EmptyHint extends StatelessWidget {
  final String emoji; // conservé pour compatibilité, non affiché
  final String text;
  const EmptyHint({super.key, this.emoji = '', required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FanZoneColors.wall,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(text, style: fz(fontSize: 14, color: FanZoneColors.cement, height: 1.4)),
    );
  }
}
