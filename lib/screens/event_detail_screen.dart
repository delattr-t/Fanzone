import 'package:flutter/material.dart';

import '../models/event.dart';
import '../models/sound_gear.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/sticker.dart';
import 'chat_view.dart';
import 'clubs_screen.dart';
import 'collectif_detail_screen.dart';

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
  void _openChat(BuildContext context, FanZoneEvent ev) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EventChatScreen(eventId: ev.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    // On relit l'event depuis l'état pour refléter les changements (jauge, joined…).
    final ev = state.eventById(widget.event.id) ?? widget.event;
    final cols = state.collectifsForEvent(ev);
    final club = state.clubById(ev.clubId);
    final msgCount = state.messagesFor('event:${ev.id}').length;

    return Scaffold(
      backgroundColor: FanZoneColors.background,
      appBar: AppBar(
        title: GestureDetector(
          onTap: club == null
              ? null
              : () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClubDetailScreen(clubId: club.id))),
          child: Text(ev.club),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (club != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: GestureDetector(
                  onTap: () => state.toggleFollowClub(club.id),
                  child: StickerPill(
                    state.isFollowing(club.id) ? 'Suivi' : '+ Suivre',
                    color: state.isFollowing(club.id) ? ev.color : FanZoneColors.dark,
                  ),
                ),
              ),
            ),
        ],
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
              style: fzDisplay(fontSize: 29, color: FanZoneColors.dark),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(ev.level, style: fz(fontSize: 13, fontWeight: FontWeight.w500, color: FanZoneColors.textLight)),
                _PricePill(free: ev.free, price: ev.price),
                if (ev.isPast) const StickerPill('Terminé', color: FanZoneColors.textLight),
              ],
            ),
            const SizedBox(height: 16),

            // ── Pourquoi venir ──
            StickerBlock(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const StickerLabel('Pourquoi venir?'),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: FanZoneColors.cream,
                      borderRadius: BorderRadius.circular(3),
                      border: Border(left: BorderSide(color: ev.color, width: 1.5)),
                    ),
                    child: Text(
                      '"${ev.description}"',
                      style: fz(fontSize: 13, fontWeight: FontWeight.w500, fontStyle: FontStyle.italic, color: FanZoneColors.textSecondary, height: 1.6),
                    ),
                  ),
                  if (ev.tags.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(spacing: 6, runSpacing: 6, children: ev.tags.map((t) => StickerPill(t, color: ev.color)).toList()),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Date & lieu ──
            StickerBlock(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const StickerLabel('Date & lieu'),
                  _InfoRow('', '${ev.dateFormatted} à ${ev.time}, ${ev.daysUntil.toLowerCase()}'),
                  const SizedBox(height: 4),
                  _InfoRow('', ev.venue),
                  if (ev.address.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Padding(
                      padding: const EdgeInsets.only(left: 22),
                      child: Text(ev.address, style: fz(fontSize: 12, fontWeight: FontWeight.w500, color: FanZoneColors.textLight)),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Mobilisation ──
            StickerBlock(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: StickerPill(ev.vibeLabel, color: ev.vibeColor, bg: ev.vibeBgColor, fontSize: 12),
                        ),
                      ),
                      Text('${ev.supporters} / ${ev.capacity}', style: fz(fontSize: 13, fontWeight: FontWeight.w600, color: FanZoneColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: LinearProgressIndicator(value: ev.fillPct, backgroundColor: FanZoneColors.cream, color: ev.color, minHeight: 10),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Jauge à ${(ev.fillPct * 100).round()}%', style: fz(fontSize: 11, fontWeight: FontWeight.w600, color: ev.color)),
                      Text('Objectif: ${ev.capacity}', style: fz(fontSize: 11, fontWeight: FontWeight.w600, color: FanZoneColors.textLight)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Collectifs présents ──
            StickerBlock(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StickerLabel('Collectifs présents (${cols.length})'),
                  if (cols.isEmpty)
                    Text('Aucun collectif annoncé pour l\'instant. Sois le premier à mobiliser ta bande!',
                        style: fz(fontSize: 12, fontWeight: FontWeight.w500, color: FanZoneColors.textSecondary)),
                  ...cols.map((c) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CollectifDetailScreen(collectifId: c.id))),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: c.joined ? c.bgColor : FanZoneColors.cream,
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(color: c.joined ? c.color : FanZoneColors.border, width: 1.5),
                            ),
                            child: Row(
                              children: [
                                Monogram(name: c.name, color: c.color, size: 36),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(c.name, style: fz(fontSize: 14, fontWeight: FontWeight.w700, color: c.joined ? c.color : FanZoneColors.dark)),
                                      Text('${c.members} membres, ${state.chantsFor(c.id).length} chants', style: fz(fontSize: 11, fontWeight: FontWeight.w600, color: FanZoneColors.textLight)),
                                    ],
                                  ),
                                ),
                                Text(c.joined ? '' : '→', style: fzDisplay(fontSize: 19, color: c.joined ? c.color : FanZoneColors.textLight)),
                              ],
                            ),
                          ),
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Matériel sonore ──
            StickerBlock(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const StickerLabel('Matériel sonore'),
                  if (ev.soundAllowed.isEmpty && ev.soundForbidden.isEmpty)
                    Text('Non précisé par l\'organisateur, demandez au club avant de ramener la grosse caisse.',
                        style: fz(fontSize: 12, fontWeight: FontWeight.w500, color: FanZoneColors.textSecondary)),
                  if (ev.soundAllowed.isNotEmpty) ...[
                    Text('Autorisé', style: fz(fontSize: 11, fontWeight: FontWeight.w700, color: FanZoneColors.success)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6, runSpacing: 6,
                      children: ev.soundAllowed.map((id) {
                        final g = gearById(id);
                        return StickerPill(g.label, color: FanZoneColors.ink);
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (ev.soundForbidden.isNotEmpty) ...[
                    Text('Interdit', style: fz(fontSize: 11, fontWeight: FontWeight.w700, color: FanZoneColors.error)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6, runSpacing: 6,
                      children: ev.soundForbidden.map((id) {
                        final g = gearById(id);
                        return StickerPill(g.label, color: FanZoneColors.cement);
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: FanZoneColors.cream, borderRadius: BorderRadius.circular(3)),
                    child: Text('${soundNoteForVenueKind(ev.venueKind)}',
                        style: fz(fontSize: 11, fontWeight: FontWeight.w500, color: FanZoneColors.textSecondary, height: 1.4)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── After ──
            if (ev.hasAfter) ...[
              StickerBlock(
                color: FanZoneColors.warningBg,
                borderColor: FanZoneColors.yellow,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const StickerLabel('After-match'),
                    Text(ev.afterBar!, style: fzDisplay(fontSize: 18, color: FanZoneColors.dark)),
                    if ((ev.afterAddress ?? '').isNotEmpty)
                      Text(ev.afterAddress!, style: fz(fontSize: 12, fontWeight: FontWeight.w500, color: FanZoneColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text('On prolonge la soirée après le coup de sifflet final, tout le monde est le bienvenu.',
                        style: fz(fontSize: 11, fontWeight: FontWeight.w500, color: FanZoneColors.textLight)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ── Chat de l'event ──
 GestureDetector(
 onTap: () => _openChat(context, ev),
 child: StickerBlock(
 child: Row(
 children: [
 const Icon(Icons.forum_outlined, size: 26),
 const SizedBox(width: 12),
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text('Chat de l\'event', style: fzDisplay(fontSize: 18, color: FanZoneColors.dark)),
                          Text(
                            ev.joined
                                ? '$msgCount message${msgCount > 1 ? 's' : ''}. Organisez-vous avec les autres supporters.'
                                : 'Réservé à ceux qui viennent. $msgCount message${msgCount > 1 ? 's' : ''}.',
                            style: fz(fontSize: 11, fontWeight: FontWeight.w600, color: FanZoneColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Text(ev.joined ? '→' : '', style: const TextStyle(fontSize: 18)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── CTA ──
            StickerButton(
              label: ev.joined ? 'Je viens! (quitter)' : 'Je viens soutenir ce club',
              color: ev.joined ? FanZoneColors.success : FanZoneColors.dark,
              outlined: ev.joined,
              fontSize: 16,
              onTap: ev.isPast ? null : widget.onToggleJoin,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

/// Chat d'un événement (réservé aux participants).
class EventChatScreen extends StatelessWidget {
 final int eventId;
 const EventChatScreen({super.key, required this.eventId});

 @override
 Widget build(BuildContext context) {
 final state = AppScope.of(context);
 final ev = state.eventById(eventId);
 if (ev == null) return const Scaffold(body: Center(child: Text('Event introuvable')));
 return Scaffold(
 backgroundColor: FanZoneColors.background,
 appBar: AppBar(
 title: Text(ev.match, maxLines: 1, overflow: TextOverflow.ellipsis),
 bottom: PreferredSize(preferredSize: const Size.fromHeight(4), child: Container(height: 4, color: ev.color)),
 ),
 body: ChatView(
 channel:'event:${ev.id}',
 accent: ev.color,
 locked:!ev.joined,
 lockedHint:'Le chat est réservé à ceux qui viennent à l\'event.',
        unlockLabel: 'Je viens!',
        onUnlock: () async {
          await state.toggleJoinEvent(ev.id);
          if (context.mounted) showFanToast(context, "Tu rejoins l'event!");
        },
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
          child: Text(text, style: fz(fontSize: 14, fontWeight: FontWeight.w500, color: FanZoneColors.textSecondary)),
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
    return StickerPill(
      free ? 'Entrée gratuite' : '${price?.toStringAsFixed(0)??'?'}€ / personne',
      color: free ? FanZoneColors.success : FanZoneColors.warning,
      bg: free ? FanZoneColors.successBg : FanZoneColors.warningBg,
    );
  }
}
