import 'package:flutter/material.dart';

import '../models/club.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/event_card.dart';
import '../widgets/sticker.dart';
import 'collectif_detail_screen.dart';
import 'event_detail_screen.dart';

/// Liste des clubs locaux : suivre un club = être alerté à chaque nouvel event.
class ClubsScreen extends StatelessWidget {
  const ClubsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final followed = state.clubs.where((c) => state.isFollowing(c.id)).toList();
    final others = state.clubs.where((c) => !state.isFollowing(c.id)).toList();

    return Scaffold(
      backgroundColor: FanZoneColors.background,
      appBar: AppBar(title: const Text('🏅 Clubs locaux')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          const Text(
            'Suis un club : tu reçois une alerte à chaque nouvel événement, et ses matchs remontent en haut de ton accueil.',
            style: TextStyle(fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w600, color: FanZoneColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 14),
          if (followed.isNotEmpty) ...[
            const StickerLabel('⭐ Mes clubs'),
            ...followed.map((c) => _ClubCard(club: c)),
            const SizedBox(height: 10),
            const StickerLabel('Autres clubs'),
          ],
          ...others.map((c) => _ClubCard(club: c)),
        ],
      ),
    );
  }
}

class _ClubCard extends StatelessWidget {
  final Club club;
  const _ClubCard({required this.club});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final following = state.isFollowing(club.id);
    final next = state.eventsForClub(club.id).where((e) => !e.isPast).toList();
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClubDetailScreen(clubId: club.id))),
      child: StickerBlock(
        margin: const EdgeInsets.only(bottom: 10),
        borderColor: following ? club.color : FanZoneColors.dark,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: club.bgColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: club.color, width: 2.5),
              ),
              child: Center(child: Text(club.emoji, style: const TextStyle(fontSize: 26))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(club.name, style: const TextStyle(fontFamily: 'Nunito', fontSize: 15, fontWeight: FontWeight.w900, color: FanZoneColors.dark)),
                  Text('${club.sport} · ${club.city}', style: const TextStyle(fontFamily: 'Nunito', fontSize: 11, fontWeight: FontWeight.w700, color: FanZoneColors.textLight)),
                  const SizedBox(height: 4),
                  Text(
                    next.isEmpty
                        ? '👥 ${state.followersOf(club)} fans · pas d\'event prévu'
                        : '👥 ${state.followersOf(club)} fans · 📅 ${next.first.dateFormatted} : ${next.first.match}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontFamily: 'Nunito', fontSize: 11, fontWeight: FontWeight.w700, color: FanZoneColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _FollowButton(club: club, following: following, compact: true),
          ],
        ),
      ),
    );
  }
}

class _FollowButton extends StatelessWidget {
  final Club club;
  final bool following;
  final bool compact;
  const _FollowButton({required this.club, required this.following, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return GestureDetector(
      onTap: () async {
        await state.toggleFollowClub(club.id);
        if (context.mounted) {
          showFanToast(context, following ? 'Tu ne suis plus ${club.name}' : '🔔 Tu suis ${club.name} !');
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 16, vertical: 8),
        decoration: BoxDecoration(
          color: following ? club.bgColor : club.color,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: club.color, width: 2),
          boxShadow: [BoxShadow(color: club.color.withValues(alpha: 0.25), offset: const Offset(2, 2), blurRadius: 0)],
        ),
        child: Text(
          following ? (compact ? '🔔 Suivi' : '🔔 Suivi ✓') : (compact ? '+ Suivre' : '+ Suivre le club'),
          style: TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w900, color: following ? club.color : Colors.white),
        ),
      ),
    );
  }
}

/// Fiche club : description, suivre, events à venir, collectifs du club.
class ClubDetailScreen extends StatelessWidget {
  final String clubId;
  const ClubDetailScreen({super.key, required this.clubId});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final club = state.clubById(clubId);
    if (club == null) return const Scaffold(body: Center(child: Text('Club introuvable')));
    final following = state.isFollowing(club.id);
    final events = state.eventsForClub(club.id).where((e) => !e.isPast).toList();
    final cols = state.collectifs.where((c) => c.clubId == club.id).toList();

    return Scaffold(
      backgroundColor: FanZoneColors.background,
      appBar: AppBar(
        title: Text('${club.emoji} ${club.name}'),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(4), child: Container(height: 4, color: club.color)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 32),
        children: [
          _Pad(child: StickerBlock(
            borderColor: club.color,
            color: club.bgColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${club.sport} · ${club.city}', style: const TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w800, color: FanZoneColors.textSecondary)),
                const SizedBox(height: 6),
                Text(club.description, style: const TextStyle(fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w700, color: FanZoneColors.dark, height: 1.5)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    StickerPill('👥 ${state.followersOf(club)} fans', color: club.color),
                    const SizedBox(width: 8),
                    StickerPill('🏟️ ${club.homeVenue}', color: FanZoneColors.dark),
                  ],
                ),
                const SizedBox(height: 12),
                _FollowButton(club: club, following: following),
              ],
            ),
          )),
          const SizedBox(height: 18),
          _Pad(child: StickerLabel('📅 Prochains events (${events.length})')),
          if (events.isEmpty)
            const EmptyHint(emoji: '😴', text: 'Pas d\'événement annoncé. Suis le club pour être alerté dès qu\'il en publie un.'),
          ...events.map((e) => EventCard(
                event: e,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EventDetailScreen(event: e, onToggleJoin: () => state.toggleJoinEvent(e.id))),
                ),
                onJoin: () => state.toggleJoinEvent(e.id),
              )),
          const SizedBox(height: 10),
          _Pad(child: StickerLabel('🎊 Collectifs du club (${cols.length})')),
          if (cols.isEmpty)
            const EmptyHint(emoji: '🫥', text: 'Aucun collectif pour ce club… Lance le premier avec tes potes !'),
          ...cols.map((c) => _Pad(child: GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CollectifDetailScreen(collectifId: c.id))),
                child: StickerBlock(
                  margin: const EdgeInsets.only(bottom: 10),
                  borderColor: c.joined ? c.color : FanZoneColors.dark,
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Text(c.emoji, style: const TextStyle(fontSize: 26)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.name, style: TextStyle(fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.w900, color: c.joined ? c.color : FanZoneColors.dark)),
                            Text('👥 ${c.members} membres', style: const TextStyle(fontFamily: 'Nunito', fontSize: 11, fontWeight: FontWeight.w700, color: FanZoneColors.textLight)),
                          ],
                        ),
                      ),
                      Text(c.joined ? '✓ Membre' : 'Voir →', style: TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w900, color: c.joined ? FanZoneColors.success : FanZoneColors.textLight)),
                    ],
                  ),
                ),
              ))),
        ],
      ),
    );
  }
}

class _Pad extends StatelessWidget {
  final Widget child;
  const _Pad({required this.child});

  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: child);
}
