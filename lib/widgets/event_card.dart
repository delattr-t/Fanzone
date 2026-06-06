import 'package:flutter/material.dart';
import '../models/event.dart';
import '../theme/app_theme.dart';

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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: FanZoneColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: FanZoneColors.dark, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: FanZoneColors.dark.withValues(alpha: 0.15),
              offset: const Offset(3, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bande colorée en haut
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: event.color,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ligne 1 : club + badges
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${event.emoji} ${event.club}',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: FanZoneColors.textLight,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Badge J-X
                      _Chip(
                        label: event.daysUntil,
                        color: event.vibeColor,
                        bgColor: event.vibeBgColor,
                      ),
                      if (event.joined) ...[
                        const SizedBox(width: 5),
                        _Chip(
                          label: '✓ Je viens',
                          color: FanZoneColors.success,
                          bgColor: FanZoneColors.successBg,
                        ),
                      ],
                      if (event.isNew) ...[
                        const SizedBox(width: 5),
                        _Chip(
                          label: 'Nouveau ✨',
                          color: FanZoneColors.warning,
                          bgColor: FanZoneColors.yellow,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Titre match
                  Text(
                    event.match,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: FanZoneColors.textPrimary,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 3),

                  // Niveau + prix
                  Row(
                    children: [
                      Text(
                        event.level,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: FanZoneColors.textLight,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _Chip(
                        label: event.free ? '🎟️ Gratuit' : '🎟️ ${event.price?.toStringAsFixed(0)}€',
                        color: event.free ? FanZoneColors.success : FanZoneColors.warning,
                        bgColor: event.free ? FanZoneColors.successBg : FanZoneColors.warningBg,
                        small: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Barre de progression
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: event.fillPct,
                      backgroundColor: FanZoneColors.cream,
                      color: event.color,
                      minHeight: 7,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        event.vibeLabel,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: event.vibeColor,
                        ),
                      ),
                      Text(
                        '${event.supporters}/${event.capacity} 👥',
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: FanZoneColors.textLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Footer : adresse + bouton
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Text('📍', style: TextStyle(fontSize: 12)),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                event.address,
                                style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: FanZoneColors.textLight,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: onJoin,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: event.joined ? FanZoneColors.successBg : FanZoneColors.dark,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: event.joined ? FanZoneColors.success : FanZoneColors.dark,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (event.joined ? FanZoneColors.success : FanZoneColors.dark)
                                    .withValues(alpha: 0.25),
                                offset: const Offset(2, 2),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: Text(
                            event.joined ? '✓ Je viens !' : 'Je viens 👋',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: event.joined ? FanZoneColors.success : Colors.white,
                            ),
                          ),
                        ),
                      ),
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

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;
  final bool small;

  const _Chip({
    required this.label,
    required this.color,
    required this.bgColor,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 7 : 9,
        vertical: small ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 2),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: small ? 10 : 11,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}
