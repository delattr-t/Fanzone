import 'package:flutter/material.dart';

import '../models/event.dart';
import '../theme/app_theme.dart';
import 'scarf.dart';
import 'sticker.dart';

/// Carte de match : lisière tricotée aux couleurs du club, éphéméride, la petite
/// foule des supporters annoncés et la jauge de mobilisation.
class EventCard extends StatelessWidget {
  final FanZoneEvent event;
  final VoidCallback onTap;
  final VoidCallback onJoin;

  const EventCard({
    super.key,
    required this.event,
    required this.onTap,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    final e = event;
    return Pressable(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        decoration: BoxDecoration(
          color: FanZoneColors.paper,
          borderRadius: BorderRadius.circular(22),
          boxShadow: FanZoneColors.lift,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Scarf.club(e.color, height: 12, fringe: false),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DateBlock(isoDate: e.date, size: 56),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.club, style: fz(fontSize: 13, fontWeight: FontWeight.w600, color: FanZoneColors.cement)),
                            const SizedBox(height: 2),
                            Text(e.match, style: fzDisplay(fontSize: 24, height: 1.1)),
                            const SizedBox(height: 6),
                            Text(
                              '${e.time}, ${e.venue}',
                              style: fz(fontSize: 14, fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(_meta(e), style: fz(fontSize: 13, color: FanZoneColors.cement)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CrowdDots(count: e.supporters, accent: e.color),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${e.supporters} sur ${e.capacity}, ${e.vibeLabel.toLowerCase()}',
                                    style: fz(fontSize: 13, color: FanZoneColors.cement),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Gauge(value: e.supporters, capacity: e.capacity, height: 8),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      JoinPill(joined: e.joined, onTap: onJoin),
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

  String _meta(FanZoneEvent e) {
    final parts = <String>[e.level];
    parts.add(e.free ? 'entrée libre' : '${e.price?.toStringAsFixed(0) ?? '?'} €');
    if (e.isNew) parts.add('nouveau');
    return parts.where((p) => p.isNotEmpty).join(', ');
  }
}

/// « J'y vais » / « J'y suis » : braise pour l'action, soleil une fois engagé.
class JoinPill extends StatelessWidget {
  final bool joined;
  final VoidCallback onTap;
  final bool onDark;
  const JoinPill({super.key, required this.joined, required this.onTap, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        decoration: BoxDecoration(
          color: joined ? FanZoneColors.hiVis : FanZoneColors.flare,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (joined) ...[
              const Icon(Icons.check_rounded, size: 18, color: FanZoneColors.ink),
              const SizedBox(width: 4),
            ],
            Text(
              joined ? 'J\'y suis' : 'J\'y vais',
              style: fz(fontSize: 15, fontWeight: FontWeight.w700, color: joined ? FanZoneColors.ink : Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

/// La petite foule : quelques têtes en bonnet, puis le décompte.
class CrowdDots extends StatelessWidget {
  final int count;
  final Color accent;
  final double size;
  final Color ring;
  const CrowdDots({super.key, required this.count, required this.accent, this.size = 22, this.ring = FanZoneColors.paper});

  static const _tones = [Color(0xFFE2462B), Color(0xFFFFB420), Color(0xFF1F7A4D), Color(0xFF1F5FBF), Color(0xFF6B3FA0)];

  @override
  Widget build(BuildContext context) {
    final shown = count.clamp(0, 4);
    if (shown == 0) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: FanZoneColors.wallDeep, width: 1.5),
        ),
      );
    }
    final step = size * 0.62;
    return SizedBox(
      width: size + step * (shown - 1),
      height: size,
      child: Stack(
        children: [
          for (var i = 0; i < shown; i++)
            Positioned(
              left: i * step,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == 0 ? accent : _tones[(i + accent.toARGB32()) % _tones.length],
                  border: Border.all(color: ring, width: 2),
                ),
                child: Align(
                  alignment: const Alignment(0, -0.35),
                  child: Container(
                    width: size * 0.42,
                    height: size * 0.18,
                    decoration: BoxDecoration(
                      color: FanZoneColors.cream.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(size),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
