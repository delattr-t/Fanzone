import 'package:flutter/material.dart';

import '../models/event.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/event_card.dart';
import '../widgets/sticker.dart';
import 'alerts_screen.dart';
import 'clubs_screen.dart';
import 'create_event_screen.dart';
import 'event_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final List<FanZoneEvent> events;
  final Function(int) onToggleJoin;

  const HomeScreen({
    super.key,
    required this.events,
    required this.onToggleJoin,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String _sportFilter = 'Tous';
  bool _freeOnly = false;

  static const _sportFilters = ['Tous', 'Football', 'Basketball', 'Volleyball', 'Judo', 'Course à pied', 'Cyclisme'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FanZoneEvent> get _filtered {
    final q = _query.toLowerCase();
    return [...widget.events]
      ..sort((a, b) => DateTime.parse(a.date).compareTo(DateTime.parse(b.date)))
      ..retainWhere((e) {
        if (e.isPast && q.isEmpty) return false;
        final matchesQuery = q.isEmpty ||
            e.match.toLowerCase().contains(q) ||
            e.club.toLowerCase().contains(q) ||
            e.venue.toLowerCase().contains(q) ||
            e.address.toLowerCase().contains(q);
        final matchesSport = _sportFilter == 'Tous' || e.sport == _sportFilter;
        final matchesFree = !_freeOnly || e.free;
        return matchesQuery && matchesSport && matchesFree;
      });
  }

  void _openDetail(FanZoneEvent event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventDetailScreen(event: event, onToggleJoin: () => widget.onToggleJoin(event.id)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final upcoming = widget.events.where((e) => !e.isPast).toList()
      ..sort((a, b) => DateTime.parse(a.date).compareTo(DateTime.parse(b.date)));
    final mine = upcoming.where((e) => e.joined).toList();
    final poster = mine.isNotEmpty ? mine.first : (upcoming.isNotEmpty ? upcoming.first : null);
    final filtered = _filtered;
    final isFiltering = _query.isNotEmpty || _sportFilter != 'Tous' || _freeOnly;
    final followedUpcoming = filtered.where((e) => state.isFollowing(e.clubId) && !e.joined).toList();
    final listed = isFiltering ? filtered : filtered.where((e) => !followedUpcoming.contains(e)).toList();

    return Scaffold(
      backgroundColor: FanZoneColors.paper,
      floatingActionButton: _PublishButton(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateEventScreen())),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _Masthead(
              userName: state.userName,
              unread: state.unreadAlerts,
              onBell: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AlertsScreen())),
            ),
          ),

          if (poster != null && !isFiltering)
            SliverToBoxAdapter(
              child: _Poster(
                event: poster,
                mine: poster.joined,
                onTap: () => _openDetail(poster),
                onJoin: () => widget.onToggleJoin(poster.id),
              ),
            ),

          SliverToBoxAdapter(
            child: _SearchBar(controller: _searchController, onChanged: (v) => setState(() => _query = v)),
          ),
          SliverToBoxAdapter(
            child: _Filters(
              sports: _sportFilters,
              active: _sportFilter,
              freeOnly: _freeOnly,
              onSport: (s) => setState(() => _sportFilter = s),
              onFree: () => setState(() => _freeOnly = !_freeOnly),
            ),
          ),

          if (!isFiltering) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 22, 16, 10),
                child: SectionTitle(
                  'Les clubs du coin',
                  trailing: 'Tous les clubs',
                  onTrailing: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClubsScreen())),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: _ClubsStrip()),
          ],

          if (followedUpcoming.isNotEmpty && !isFiltering) ...[
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 22, 16, 12),
                child: SectionTitle('Tes clubs jouent'),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => EventCard(
                  event: followedUpcoming[i],
                  onTap: () => _openDetail(followedUpcoming[i]),
                  onJoin: () => widget.onToggleJoin(followedUpcoming[i].id),
                ),
                childCount: followedUpcoming.length,
              ),
            ),
          ],

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 12),
              child: SectionTitle(
                isFiltering
                    ? '${filtered.length} résultat${filtered.length > 1 ? 's' : ''}'
                    : 'À venir près de chez toi',
              ),
            ),
          ),
          if (listed.isEmpty)
            SliverToBoxAdapter(
              child: EmptyHint(
                text: isFiltering
                    ? 'Rien avec ces filtres. Essaie un autre sport, ou publie toi-même le match.'
                    : 'Aucun match annoncé pour l\'instant. Publie le premier.',
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => EventCard(
                  event: listed[i],
                  onTap: () => _openDetail(listed[i]),
                  onJoin: () => widget.onToggleJoin(listed[i].id),
                ),
                childCount: listed.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 96)),
        ],
      ),
    );
  }
}

// ── En-tête : nom de l'app en lettres d'affiche + cloche ────────
class _Masthead extends StatelessWidget {
  final String userName;
  final int unread;
  final VoidCallback onBell;
  const _Masthead({required this.userName, required this.unread, required this.onBell});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('FanZone', style: fzDisplay(fontSize: 38, fontWeight: FontWeight.w800, letterSpacing: -1)),
                  Text('Salut $userName. On va faire du bruit où, ce week-end\u00A0?',
                      style: fz(fontSize: 14, color: FanZoneColors.cement)),
                ],
              ),
            ),
            GestureDetector(
              onTap: onBell,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: unread > 0 ? FanZoneColors.hiVis : FanZoneColors.paper,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: FanZoneColors.ink, width: 1.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_none, size: 18),
                    if (unread > 0) ...[
                      const SizedBox(width: 4),
                      Text('$unread', style: fzDisplay(fontSize: 18)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── L'affiche : le prochain match (le tien, sinon le plus proche) ──
class _Poster extends StatelessWidget {
  final FanZoneEvent event;
  final bool mine;
  final VoidCallback onTap;
  final VoidCallback onJoin;
  const _Poster({required this.event, required this.mine, required this.onTap, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    final e = event;
    final parts = e.match.split(RegExp(r'\s+vs\s+', caseSensitive: false));
    final home = parts.first;
    final away = parts.length > 1 ? parts[1] : null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 10, 16, 6),
        decoration: BoxDecoration(
          color: FanZoneColors.ink,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(height: 8, color: e.color),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mine ? 'Ton prochain match' : 'Le prochain match près de chez toi',
                    style: fz(fontSize: 14, fontWeight: FontWeight.w600, color: FanZoneColors.hiVis),
                  ),
                  const SizedBox(height: 10),
                  Text(home, style: fzDisplay(fontSize: 40, color: Colors.white, fontWeight: FontWeight.w800)),
                  if (away != null)
                    Text('contre $away', style: fzDisplay(fontSize: 28, color: Colors.white, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 14),
                  Text(
                    '${_longDate(e.date)}, ${_hour(e.time)}',
                    style: fz(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  Text(e.venue, style: fz(fontSize: 15, color: Colors.white70)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${e.supporters} supporter${e.supporters > 1 ? 's' : ''} annoncé${e.supporters > 1 ? 's' : ''}',
                          style: fz(fontSize: 14, color: Colors.white70),
                        ),
                      ),
                      GestureDetector(
                        onTap: onJoin,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: mine ? FanZoneColors.hiVis : FanZoneColors.flare,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            mine ? 'J\'y suis' : 'J\'y vais',
                            style: fz(fontSize: 15, fontWeight: FontWeight.w600, color: mine ? FanZoneColors.ink : Colors.white),
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

  static String _hour(String t) {
    final p = t.split(':');
    if (p.length < 2) return t;
    return p[1] == '00' ? '${p[0]} h' : '${p[0]} h ${p[1]}';
  }

  static String _longDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      const days = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
      const months = ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'];
      return '${days[d.weekday - 1]} ${d.day} ${months[d.month - 1]}';
    } catch (_) {
      return iso;
    }
  }
}

// ── Recherche ───────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: FanZoneColors.ink, width: 1.5),
          borderRadius: BorderRadius.circular(3),
        ),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          style: fz(fontSize: 15),
          decoration: InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            prefixIcon: const Icon(Icons.search, size: 20, color: FanZoneColors.ink),
            hintText: 'Un club, un lieu, une ville',
            hintStyle: fz(fontSize: 15, color: FanZoneColors.cement),
            suffixIcon: controller.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                  ),
          ),
        ),
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  final List<String> sports;
  final String active;
  final bool freeOnly;
  final ValueChanged<String> onSport;
  final VoidCallback onFree;
  const _Filters({required this.sports, required this.active, required this.freeOnly, required this.onSport, required this.onFree});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        children: [
          ...sports.map((s) => _Chip(label: s, active: active == s, onTap: () => onSport(s))),
          _Chip(label: 'Entrée libre', active: freeOnly, onTap: onFree),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? FanZoneColors.ink : FanZoneColors.paper,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: FanZoneColors.ink, width: 1.5),
        ),
        child: Text(
          label,
          style: fz(fontSize: 14, fontWeight: FontWeight.w600, color: active ? Colors.white : FanZoneColors.ink),
        ),
      ),
    );
  }
}

// ── Clubs : monogrammes ─────────────────────────────────────────
class _ClubsStrip extends StatelessWidget {
  const _ClubsStrip();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return SizedBox(
      height: 92,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: state.clubs.length,
        itemBuilder: (_, i) {
          final c = state.clubs[i];
          final following = state.isFollowing(c.id);
          return GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClubDetailScreen(clubId: c.id))),
            child: Container(
              width: 84,
              margin: const EdgeInsets.only(right: 10),
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Monogram(name: c.name, color: c.color, size: 52),
                      if (following)
                        Positioned(
                          right: -5,
                          top: -5,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: FanZoneColors.hiVis,
                              shape: BoxShape.circle,
                              border: Border.all(color: FanZoneColors.ink, width: 1.5),
                            ),
                            child: const Icon(Icons.check, size: 11, color: FanZoneColors.ink),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    c.shortName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: fz(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PublishButton extends StatelessWidget {
  final VoidCallback onTap;
  const _PublishButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: FanZoneColors.flare,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: FanZoneColors.ink, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, size: 18, color: Colors.white),
            const SizedBox(width: 6),
            Text('Publier un match', style: fz(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
