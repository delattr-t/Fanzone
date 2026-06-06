import 'package:flutter/material.dart';
import '../models/event.dart';
import '../theme/app_theme.dart';

class EventDetailScreen extends StatefulWidget {
  final FanZoneEvent event;
  final VoidCallback onToggleJoin;

  const EventDetailScreen({
    super.key,
    required this.event,
    required this.onToggleJoin,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final ev = widget.event;
    return Scaffold(
      backgroundColor: FanZoneColors.background,
      appBar: AppBar(
        title: Text(ev.emoji + ' ' + ev.club),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Container(height: 4, color: ev.color),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Titre + level ──
            Text(
              ev.match,
              style: const TextStyle(
                fontFamily: 'Nunito', fontSize: 26,
                fontWeight: FontWeight.w900,
                color: FanZoneColors.dark,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  ev.level,
                  style: const TextStyle(
                    fontFamily: 'Nunito', fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: FanZoneColors.textLight,
                  ),
                ),
                const SizedBox(width: 8),
                _PricePill(free: ev.free, price: ev.price),
              ],
            ),
            const SizedBox(height: 16),

            // ── Pourquoi venir ──
            _Block(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Label('Pourquoi venir ?'),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: FanZoneColors.cream,
                      borderRadius: BorderRadius.circular(10),
                      border: Border(left: BorderSide(color: ev.color, width: 4)),
                    ),
                    child: Text(
                      '"${ev.description}"',
                      style: const TextStyle(
                        fontFamily: 'Nunito', fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                        color: FanZoneColors.textSecondary,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Date & lieu ──
            _Block(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Label('Date & lieu'),
                  _InfoRow('📅', '${ev.dateFormatted} · ${ev.time}'),
                  const SizedBox(height: 4),
                  _InfoRow('📍', '${ev.venue}, ${ev.address}'),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Mobilisation ──
            _Block(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: ev.vibeBgColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: ev.vibeColor, width: 2),
                              ),
                              child: Text(
                                ev.vibeLabel,
                                style: TextStyle(
                                  fontFamily: 'Nunito', fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: ev.vibeColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${ev.supporters} / ${ev.capacity} 👥',
                        style: const TextStyle(
                          fontFamily: 'Nunito', fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: FanZoneColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: LinearProgressIndicator(
                      value: ev.fillPct,
                      backgroundColor: FanZoneColors.cream,
                      color: ev.color,
                      minHeight: 10,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Jauge à ${(ev.fillPct * 100).round()}%',
                        style: TextStyle(
                          fontFamily: 'Nunito', fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: ev.color,
                        ),
                      ),
                      Text(
                        'Objectif : ${ev.capacity}',
                        style: const TextStyle(
                          fontFamily: 'Nunito', fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: FanZoneColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── CTA ──
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    widget.onToggleJoin();
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: ev.joined ? FanZoneColors.successBg : FanZoneColors.dark,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: ev.joined ? FanZoneColors.success : FanZoneColors.dark,
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (ev.joined ? FanZoneColors.success : FanZoneColors.dark)
                            .withOpacity(0.25),
                        offset: const Offset(4, 4),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      ev.joined
                          ? '✓ Tu fais partie du collectif 🎉'
                          : 'Je viens soutenir ce club 👋',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: ev.joined ? FanZoneColors.success : Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _Block extends StatelessWidget {
  final Widget child;
  const _Block({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FanZoneColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FanZoneColors.dark, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: FanZoneColors.dark.withOpacity(0.08),
            offset: const Offset(3, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

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

class _InfoRow extends StatelessWidget {
  final String icon;
  final String text;
  const _InfoRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: FanZoneColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _PricePill extends StatelessWidget {
  final bool free;
  final double? price;
  const _PricePill({required this.free, this.price});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: free ? FanZoneColors.successBg : FanZoneColors.warningBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: free ? FanZoneColors.success : FanZoneColors.warning,
          width: 2,
        ),
      ),
      child: Text(
        free ? '🎟️ Entrée gratuite' : '🎟️ ${price?.toStringAsFixed(0)}€ / personne',
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: free ? FanZoneColors.success : FanZoneColors.warning,
        ),
      ),
    );
  }
}
