import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'scarf.dart';

/// Carte en laine claire, coins ronds, ombre douce. `stripe` = lisière tricotée
/// aux couleurs du club en haut de la carte.
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
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? FanZoneColors.paper,
        borderRadius: BorderRadius.circular(20),
        border: borderColor == null ? null : Border.all(color: borderColor!, width: 2),
        boxShadow: FanZoneColors.lift,
      ),
      clipBehavior: Clip.antiAlias,
      child: stripe == null
          ? Padding(padding: padding, child: child)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Scarf.club(stripe!, height: 12, fringe: false),
                Padding(padding: padding, child: child),
              ],
            ),
    );
  }
}

/// Retour au toucher : léger retrait (0.97) pendant l'appui, retour rapide.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final HitTestBehavior behavior;
  const Pressable({super.key, required this.child, required this.onTap, this.behavior = HitTestBehavior.opaque});

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      behavior: widget.behavior,
      onTap: widget.onTap,
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapUp: enabled ? (_) => setState(() => _down = false) : null,
      onTapCancel: enabled ? () => setState(() => _down = false) : null,
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: Duration(milliseconds: _down ? 90 : 160),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

class StickerLabel extends StatelessWidget {
  final String text;
  const StickerLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: fz(fontSize: 14, fontWeight: FontWeight.w600, color: FanZoneColors.cement)),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  final String? trailing;
  final VoidCallback? onTrailing;
  const SectionTitle(this.text, {super.key, this.trailing, this.onTrailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: Text(text, style: fzDisplay(fontSize: 28))),
        if (trailing != null)
          Pressable(
            onTap: onTrailing,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                trailing!,
                style: fz(fontSize: 14, fontWeight: FontWeight.w700, color: FanZoneColors.flare),
              ),
            ),
          ),
      ],
    );
  }
}

/// Écusson de club : pastille à la couleur du club, liseré crème comme une
/// rayure d'écharpe, initiales tricotées.
class Monogram extends StatelessWidget {
  final String name;
  final Color color;
  final double size;
  final bool onInk;
  const Monogram({super.key, required this.name, required this.color, this.size = 40, this.onInk = false});

  static String initials(String name) {
    final words = name.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) return words.first.substring(0, words.first.length >= 2 ? 2 : 1).toUpperCase();
    return (words[0][0] + words[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final ring = (size * 0.07).clamp(1.5, 4.0);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      padding: EdgeInsets.all(ring * 1.4),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: FanZoneColors.cream, width: ring),
        ),
        child: Center(
          child: Text(
            initials(name),
            style: fzDisplay(fontSize: size * 0.42, color: FanZoneColors.cream, letterSpacing: 0.2, height: 1),
          ),
        ),
      ),
    );
  }
}

/// Date en éphéméride : bandeau braise avec le jour de la semaine, gros chiffre.
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
      decoration: BoxDecoration(
        color: FanZoneColors.paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FanZoneColors.wallDeep),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            color: FanZoneColors.flare,
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              d == null ? '' : days[d.weekday - 1],
              textAlign: TextAlign.center,
              style: fz(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(d == null ? '?' : '${d.day}', style: fzDisplay(fontSize: size * 0.52, height: 1.05)),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Text(
              d == null ? '' : months[d.month - 1],
              style: fz(fontSize: 12, color: FanZoneColors.cement, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Jauge de mobilisation : piste sable, remplissage soleil.
class Gauge extends StatelessWidget {
  final int value;
  final int capacity;
  final double height;
  const Gauge({super.key, required this.value, required this.capacity, this.height = 10});

  @override
  Widget build(BuildContext context) {
    final pct = capacity == 0 ? 0.0 : (value / capacity).clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Container(
        height: height,
        color: FanZoneColors.wall,
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: pct == 0 ? 0.02 : pct,
            child: Container(
              decoration: BoxDecoration(
                color: FanZoneColors.hiVis,
                borderRadius: BorderRadius.circular(height),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
    this.color = FanZoneColors.flare,
    this.textColor = Colors.white,
    this.outlined = false,
    this.fontSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final bg = color == FanZoneColors.ink ? FanZoneColors.flare : color;
    return Opacity(
      opacity: disabled ? 0.45 : 1,
      child: Pressable(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: outlined ? FanZoneColors.paper : bg,
            borderRadius: BorderRadius.circular(999),
            border: outlined ? Border.all(color: FanZoneColors.wallDeep, width: 1.5) : null,
          ),
          child: Center(
            child: Text(
              label,
              style: fz(
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                color: outlined ? (color == FanZoneColors.ink ? FanZoneColors.ink : color) : textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class StickerPill extends StatelessWidget {
  final String text;
  final Color color;
  final Color? bg;
  final double fontSize;
  const StickerPill(this.text, {super.key, required this.color, this.bg, this.fontSize = 12});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg ?? color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: fz(fontSize: fontSize, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

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
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: fz(fontSize: 15, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            hintText: hint,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

void showFanToast(BuildContext context, String text) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(text, style: fz(fontSize: 15, fontWeight: FontWeight.w600, color: FanZoneColors.cream)),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      backgroundColor: FanZoneColors.night,
      shape: const StadiumBorder(),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    ),
  );
}

class EmptyHint extends StatelessWidget {
  final String emoji;
  final String text;
  const EmptyHint({super.key, this.emoji = '', required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: FanZoneColors.wall,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(text, style: fz(fontSize: 15, color: FanZoneColors.cement, height: 1.45)),
    );
  }
}
