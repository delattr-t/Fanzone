import 'package:flutter/material.dart';

import '../models/event.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/event_card.dart';
import '../widgets/scarf.dart';
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
      backgroundColor: FanZoneColors.wool,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _Masthead(
              userName: state.userName,
              unread: state.unreadAlerts,
              onBell: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AlertsScreen())),
              onPublish: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateEventScreen())),
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
                padding: const EdgeInsets.fromLTRB(16, 28, 16, 4),
                child: SectionTitle(
                  'Les écharpes du coin',
                  trailing: 'Tous les clubs',
                  onTrailing: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClubsScreen())),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text(
                  'Touche une écharpe pour suivre le club et être prévenu de ses matchs.',
                  style: fz(fontSize: 14, color: FanZoneColors.cement),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: _ScarfRack()),
          ],
          if (followedUpcoming.isNotEmpty && !isFiltering) ...[
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 28, 16, 14),
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
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 14),
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

class _Masthead extends StatelessWidget {
  final String userName;
  final int unread;
  final VoidCallback onBell;
  final VoidCallback onPublish;
  const _Masthead({required this.userName, required this.unread, required this.onBell, required this.onPublish});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Salut $userName,', style: fzDisplay(fontSize: 34)),
                  const SizedBox(height: 2),
                  Text('on fait du bruit où, ce week-end ?',
                      style: fz(fontSize: 15, color: FanZoneColors.cement)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _RoundButton(
              onTap: onBell,
              color: FanZoneColors.paper,
              tooltip: 'Alertes',
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_none_rounded, size: 24, color: FanZoneColors.ink),
                  if (unread > 0)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 18),
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: FanZoneColors.flare,
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(color: FanZoneColors.paper, width: 2),
                        ),
                        child: Text('$unread',
                            textAlign: TextAlign.center,
                            style: fz(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _RoundButton(
              onTap: onPublish,
              color: FanZoneColors.flare,
              tooltip: 'Publier un match',
              child: const Icon(Icons.add_rounded, size: 26, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final VoidCallback onTap;
  final Color color;
  final Widget child;
  final String tooltip;
  const _RoundButton({required this.onTap, required this.color, required this.child, required this.tooltip});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Pressable(
        onTap: onTap,
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: FanZoneColors.lift),
          child: Center(child: child),
        ),
      ),
    );
  }
}

/// Le prochain match, façon soir de match : fond brun nuit, écharpe du club
/// tendue en haut, comme accrochée à la rambarde.
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
    return Pressable(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
        decoration: BoxDecoration(
          color: FanZoneColors.night,
          borderRadius: BorderRadius.circular(28),
          boxShadow: FanZoneColors.lift,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 22, 6, 0),
              child: Scarf.club(e.color, label: e.club, height: 46),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mine ? 'Ton prochain match' : 'Le prochain match près de chez toi',
                    style: fz(fontSize: 14, fontWeight: FontWeight.w700, color: FanZoneColors.hiVis),
                  ),
                  const SizedBox(height: 8),
                  Text(home, style: fzDisplay(fontSize: 38, color: FanZoneColors.cream, height: 1.05)),
                  if (away != null)
                    Text('contre $away',
                        style: fzDisplay(fontSize: 26, color: FanZoneColors.cream.withValues(alpha: 0.75), fontWeight: FontWeight.w600)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(Icons.event_rounded, size: 18, color: FanZoneColors.hiVis),
                      const SizedBox(width: 8),
                      Text('${_longDate(e.date)}, ${_hour(e.time)}',
                          style: fz(fontSize: 15, fontWeight: FontWeight.w600, color: FanZoneColors.cream)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.place_rounded, size: 18, color: FanZoneColors.hiVis),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(e.venue,
                            style: fz(fontSize: 15, color: FanZoneColors.cream.withValues(alpha: 0.8))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      CrowdDots(count: e.supporters, accent: e.color, size: 26, ring: FanZoneColors.night),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${e.supporters} supporter${e.supporters > 1 ? 's' : ''}\nannoncé${e.supporters > 1 ? 's' : ''}',
                          style: fz(fontSize: 13, height: 1.25, color: FanZoneColors.cream.withValues(alpha: 0.8)),
                        ),
                      ),
                      JoinPill(joined: mine, onTap: onJoin, onDark: true),
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

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: FanZoneColors.paper,
          borderRadius: BorderRadius.circular(999),
          boxShadow: FanZoneColors.lift,
        ),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          style: fz(fontSize: 15),
          decoration: InputDecoration(
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: 6),
              child: Icon(Icons.search_rounded, size: 22, color: FanZoneColors.cement),
            ),
            hintText: 'Un club, un lieu, une ville',
            suffixIcon: controller.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
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
      height: 54,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? FanZoneColors.ink : FanZoneColors.paper,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: active ? FanZoneColors.ink : FanZoneColors.wallDeep),
        ),
        child: Text(
          label,
          style: fz(fontSize: 14, fontWeight: FontWeight.w600, color: active ? FanZoneColors.cream : FanZoneColors.ink),
        ),
      ),
    );
  }
}

/// Le porte-écharpes : une écharpe par club. Toucher l'écharpe pour suivre le
/// club, toucher la ligne du dessous pour ouvrir sa fiche.
class _ScarfRack extends StatelessWidget {
  const _ScarfRack();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return SizedBox(
      height: 132,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: state.clubs.length,
        itemBuilder: (_, i) {
          final c = state.clubs[i];
          final following = state.isFollowing(c.id);
          return Container(
            width: 232,
            margin: const EdgeInsets.only(right: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Pressable(
                  onTap: () => state.toggleFollowClub(c.id),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: following ? 1 : 0.92,
                      child: Scarf.club(c.color, label: c.shortName, height: 44),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                              context, MaterialPageRoute(builder: (_) => ClubDetailScreen(clubId: c.id))),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: fz(fontSize: 14, fontWeight: FontWeight.w700)),
                              Text('${c.sport}, ${state.followersOf(c)} fans',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: fz(fontSize: 13, color: FanZoneColors.cement)),
                            ],
                          ),
                        ),
                      ),
                      Pressable(
                        onTap: () => state.toggleFollowClub(c.id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: following ? FanZoneColors.hiVis : FanZoneColors.paper,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: following ? FanZoneColors.hiVis : FanZoneColors.wallDeep),
                          ),
                          child: Text(
                            following ? 'Suivi' : 'Suivre',
                            style: fz(fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
