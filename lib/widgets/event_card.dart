import 'package:flutter/material.dart';

import '../models/event.dart';
import '../theme/app_theme.dart';
import 'sticker.dart';

/// Carte d'événement : date en tableau d'affichage, rayure du club, jauge fluo.
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        decoration: BoxDecoration(
          color: FanZoneColors.paper,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: FanZoneColors.ink, width: 1.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 6, color: e.color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DateBlock(isoDate: e.date, size: 54),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e.club,
                                style: fz(fontSize: 13, fontWeight: FontWeight.w600, color: FanZoneColors.cement),
                              ),
                              const SizedBox(height: 2),
                              Text(e.match, style: fzDisplay(fontSize: 23)),
                              const SizedBox(height: 6),
                              Text(
                                '${e.time}, ${e.venue}',
                                style: fz(fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                _meta(e),
                                style: fz(fontSize: 13, color: FanZoneColors.cement),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Gauge(value: e.supporters, capacity: e.capacity, height: 10),
                              const SizedBox(height: 4),
                              Text(
                                '${e.supporters} sur ${e.capacity} annoncés, ${e.vibeLabel.toLowerCase()}',
                                style: fz(fontSize: 12, color: FanZoneColors.cement),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        _JoinButton(joined: e.joined, onTap: onJoin),
                      ],
                    ),
                  ],
                ),
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

class _JoinButton extends StatelessWidget {
  final bool joined;
  final VoidCallback onTap;
  const _JoinButton({required this.joined, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: joined ? FanZoneColors.hiVis : FanZoneColors.ink,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: FanZoneColors.ink, width: 1.5),
        ),
        child: Text(
          joined ? 'J\'y suis' : 'J\'y vais',
          style: fz(fontSize: 14, fontWeight: FontWeight.w600, color: joined ? FanZoneColors.ink : Colors.white),
        ),
      ),
    );
  }
}
