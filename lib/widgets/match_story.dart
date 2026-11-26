import 'package:flutter/material.dart';

import '../models/event.dart';
import '../theme/app_theme.dart';
import 'scarf.dart';
import 'share_sheet.dart';

/// Story 9:16 d'un match (360 x 640, exportée en 1080 x 1920) : l'écharpe du club
/// en travers, le match, la date, la jauge, et le lien à suivre.
class MatchStory extends StatelessWidget {
  final FanZoneEvent event;
  final String clubLabel;
  const MatchStory({super.key, required this.event, required this.clubLabel});

  static const size = Size(360, 640);

  @override
  Widget build(BuildContext context) {
    final e = event;
    final pct = e.capacity == 0 ? 0.0 : (e.supporters / e.capacity).clamp(0.04, 1.0);
    final titleSize = e.match.length > 40 ? 32.0 : (e.match.length > 24 ? 38.0 : 44.0);
    final supporters = e.supporters <= 0
        ? 'Les premiers supporters donnent le ton.'
        : (e.supporters == 1 ? '1 supporter déjà annoncé.' : '${e.supporters} supporters déjà annoncés.');

    return SizedBox.fromSize(
      size: size,
      child: ColoredBox(
        color: FanZoneColors.night,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              top: 162,
              left: -80,
              right: -80,
              child: Transform.rotate(
                angle: 0.09,
                child: Opacity(opacity: 0.9, child: Scarf.club(FanZoneColors.hiVis, height: 34, fringe: false)),
              ),
            ),
            Positioned(
              top: 104,
              left: -80,
              right: -80,
              child: Transform.rotate(
                angle: -0.12,
                child: Scarf.club(e.color, label: clubLabel, height: 64, fringe: false),
              ),
            ),
            Positioned(
              left: 28,
              right: 28,
              top: 262,
              bottom: 76,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('on y va ensemble ?', style: fz(fontSize: 17, fontWeight: FontWeight.w700, color: FanZoneColors.hiVis)),
                  const SizedBox(height: 10),
                  Text(
                    e.match,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: fzDisplay(fontSize: titleSize, color: FanZoneColors.cream, height: 1.02),
                  ),
                  const SizedBox(height: 18),
                  Text(matchWhen(e), style: fz(fontSize: 19, fontWeight: FontWeight.w700, color: FanZoneColors.hiVis, height: 1.25)),
                  const SizedBox(height: 4),
                  Text(e.venue, style: fz(fontSize: 16, color: FanZoneColors.wallDeep, height: 1.3)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (e.level.isNotEmpty) _Tag(e.level),
                      _Tag(e.free ? 'entrée libre' : (e.price == null ? 'entrée payante' : '${_price(e.price!)} l\'entrée')),
                    ],
                  ),
                  const Spacer(),
                  Text(supporters, style: fz(fontSize: 14, color: FanZoneColors.cream)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: SizedBox(
                      height: 9,
                      child: Stack(
                        children: [
                          Container(color: FanZoneColors.cream.withValues(alpha: 0.16)),
                          FractionallySizedBox(widthFactor: pct, child: Container(color: FanZoneColors.hiVis)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          shareLinkLabel(e),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: fz(fontSize: 12, color: FanZoneColors.cream.withValues(alpha: 0.7)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('FanZone', style: fzDisplay(fontSize: 24, color: FanZoneColors.cream)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _price(double p) => p == p.roundToDouble() ? '${p.toInt()} €' : '${p.toStringAsFixed(2).replaceAll('.', ',')} €';

class _Tag extends StatelessWidget {
  final String text;
  const _Tag(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: FanZoneColors.cream.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(text, style: fz(fontSize: 13, fontWeight: FontWeight.w700, color: FanZoneColors.cream)),
    );
  }
}
