import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Un tronçon d'écharpe : la couleur d'un club et, éventuellement, son nom tricoté.
class ScarfSegment {
  final Color color;
  final String? label;
  const ScarfSegment(this.color, [this.label]);
}

/// L'écharpe de supporter, tricotée en code : rayures aux couleurs du club,
/// mailles jersey, lettrage jacquard et franges. C'est le geste signature de
/// FanZone ; un club, un collectif ou un profil se reconnaît à son écharpe.
class Scarf extends StatelessWidget {
  final List<ScarfSegment> segments;
  final double height;
  final bool fringe;
  final Color stripe;

  const Scarf({
    super.key,
    required this.segments,
    this.height = 44,
    this.fringe = true,
    this.stripe = FanZoneColors.cream,
  });

  factory Scarf.club(Color color, {Key? key, String? label, double height = 44, bool fringe = true}) =>
      Scarf(key: key, segments: [ScarfSegment(color, label)], height: height, fringe: fringe);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _ScarfPainter(
          segments: segments.isEmpty ? const [ScarfSegment(FanZoneColors.flare)] : segments,
          fringe: fringe,
          stripe: stripe,
          labelStyle: fzDisplay(fontSize: 10, color: stripe),
        ),
      ),
    );
  }
}

class _ScarfPainter extends CustomPainter {
  final List<ScarfSegment> segments;
  final bool fringe;
  final Color stripe;
  final TextStyle labelStyle;

  _ScarfPainter({required this.segments, required this.fringe, required this.stripe, required this.labelStyle});

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final stitch = (h / 6).clamp(2.5, 7.0);
    final fringeLen = fringe ? h * 0.34 : 0.0;
    final body = Rect.fromLTWH(fringeLen, 0, math.max(0, size.width - 2 * fringeLen), h);
    if (body.width <= 0) return;

    if (fringe) {
      _drawFringe(canvas, body.left, -1, segments.first.color, h, stitch, fringeLen);
      _drawFringe(canvas, body.right, 1, segments.last.color, h, stitch, fringeLen);
    }

    final radius = Radius.circular(math.min(6, h * 0.14));
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(body, radius));

    final segW = body.width / segments.length;
    for (var i = 0; i < segments.length; i++) {
      final seg = segments[i];
      final r = Rect.fromLTWH(body.left + i * segW, 0, segW, h);
      canvas.drawRect(r, Paint()..color = seg.color);

      final band1 = h * 0.16, band2 = h * 0.08, gap = h * 0.12, inset = h * 0.22;
      final stripePaint = Paint()..color = stripe;
      final showStripes = segW > h * 1.6;
      if (showStripes) {
        canvas.drawRect(Rect.fromLTWH(r.left + inset, 0, band1, h), stripePaint);
        canvas.drawRect(Rect.fromLTWH(r.left + inset + band1 + gap, 0, band2, h), stripePaint);
        canvas.drawRect(Rect.fromLTWH(r.right - inset - band1, 0, band1, h), stripePaint);
        canvas.drawRect(Rect.fromLTWH(r.right - inset - band1 - gap - band2, 0, band2, h), stripePaint);
      }

      final label = seg.label;
      if (label != null && label.isNotEmpty && h >= 24) {
        final reserved = showStripes ? inset + band1 + gap + band2 + h * 0.2 : h * 0.3;
        final maxW = segW - 2 * reserved;
        if (maxW > h) {
          TextPainter lay(double scale) => TextPainter(
                text: TextSpan(
                  text: label.toUpperCase(),
                  style: labelStyle.copyWith(fontSize: h * 0.36 * scale, letterSpacing: h * 0.05 * scale, height: 1),
                ),
                textDirection: TextDirection.ltr,
                maxLines: 1,
                ellipsis: '…',
              );
          var tp = lay(1)..layout();
          if (tp.width > maxW) {
            tp = lay(math.max(0.7, maxW / tp.width))..layout(maxWidth: maxW);
          }
          tp.paint(canvas, Offset(r.center.dx - tp.width / 2, r.center.dy - tp.height / 2));
        }
      }

      if (i > 0) {
        canvas.drawRect(Rect.fromLTWH(r.left - h * 0.05, 0, h * 0.1, h), stripePaint);
      }
    }

    _drawStitches(canvas, body, stitch);
    canvas.restore();
  }

  void _drawStitches(Canvas canvas, Rect body, double s) {
    final shade = Path();
    final light = Path();
    for (var y = s * 0.25; y < body.height; y += s * 0.92) {
      final rowShift = ((y / s).floor().isEven) ? 0.0 : s * 0.5;
      for (var x = body.left - s + rowShift; x < body.right + s; x += s) {
        shade
          ..moveTo(x + s * 0.1, y)
          ..lineTo(x + s * 0.5, y + s * 0.6)
          ..lineTo(x + s * 0.9, y);
        light
          ..moveTo(x + s * 0.18, y - s * 0.12)
          ..lineTo(x + s * 0.5, y + s * 0.36);
      }
    }
    canvas.drawPath(
      shade,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.2
        ..strokeCap = StrokeCap.round
        ..color = const Color(0x24000000),
    );
    canvas.drawPath(
      light,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.16
        ..strokeCap = StrokeCap.round
        ..color = const Color(0x18FFFFFF),
    );
  }

  void _drawFringe(Canvas canvas, double edge, int dir, Color color, double h, double s, double len) {
    final paint = Paint()
      ..color = Color.lerp(color, const Color(0xFF000000), 0.08)!
      ..strokeWidth = math.max(1.5, s * 0.5)
      ..strokeCap = StrokeCap.round;
    final count = math.max(3, (h / (s * 1.25)).floor());
    final step = (h - s) / (count - 1);
    for (var i = 0; i < count; i++) {
      final y = s / 2 + i * step;
      final l = len * (0.78 + 0.22 * ((i * 7) % 5) / 4);
      canvas.drawLine(Offset(edge, y), Offset(edge + dir * l, y), paint);
    }
  }

  @override
  bool shouldRepaint(_ScarfPainter old) =>
      old.segments != segments || old.fringe != fringe || old.stripe != stripe;
}
