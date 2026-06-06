import 'package:flutter/material.dart';
import '../models/event.dart';
import '../theme/app_theme.dart';
import '../widgets/event_card.dart';
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

  static const _sportFilters = [
    {'label': 'Tous',       'emoji': '🎯'},
    {'label': 'Football',   'emoji': '⚽'},
    {'label': 'Basketball', 'emoji': '🏀'},
    {'label': 'Volleyball', 'emoji': '🏐'},
    {'label': 'Course à pied', 'emoji': '🏃'},
    {'label': 'Cyclisme',   'emoji': '🚴'},
  ];

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

  @override
  Widget build(BuildContext context) {
    final myEvents = widget.events.where((e) => e.joined).toList();
    final filtered = _filtered;
    final isFiltering = _query.isNotEmpty || _sportFilter != 'Tous' || _freeOnly;

    return Scaffold(
      backgroundColor: FanZoneColors.background,
      body: CustomScrollView(
        slivers: [
          // ── HERO ──────────────────────────────────────────────
          SliverToBoxAdapter(child: const _HeroBanner()),

          // ── RECHERCHE ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: _SearchBar(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
            ),
          ),

          // ── FILTRES SPORT ─────────────────────────────────────
          SliverToBoxAdapter(
            child: _FilterChips(
              sports: _sportFilters,
              activeSport: _sportFilter,
              freeOnly: _freeOnly,
              onSportTap: (s) => setState(() => _sportFilter = s),
              onFreeToggle: () => setState(() => _freeOnly = !_freeOnly),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 4)),

          // ── MES ÉQUIPES (masqué si recherche active) ──────────
          if (myEvents.isNotEmpty && !isFiltering) ...[
            _SectionHeader(
              title: '📌 Mes équipes',
              badge: '${myEvents.length} suivi${myEvents.length > 1 ? 's' : ''}',
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 140,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: myEvents.length,
                  itemBuilder: (_, i) => _FavCard(
                    event: myEvents[i],
                    onTap: () => _openDetail(context, myEvents[i]),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
          ],

          // ── CLUBS (masqué si recherche active) ────────────────
          if (!isFiltering) ...[
            _SectionHeader(title: '🏅 Clubs locaux', linkLabel: 'Voir tout →'),
            SliverToBoxAdapter(child: const _ClubsStrip()),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
          ],

          // ── ÉVÉNEMENTS ────────────────────────────────────────
          _SectionHeader(
            title: isFiltering ? '🔍 Résultats' : '🗓️ Prochains events',
            badge: '${filtered.length} event${filtered.length > 1 ? 's' : ''}',
          ),

          if (filtered.isEmpty)
            SliverToBoxAdapter(child: _EmptyState(isFiltering: isFiltering))
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => EventCard(
                  event: filtered[i],
                  onTap: () => _openDetail(context, filtered[i]),
                  onJoin: () => widget.onToggleJoin(filtered[i].id),
                ),
                childCount: filtered.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  void _openDetail(BuildContext context, FanZoneEvent event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventDetailScreen(
          event: event,
          onToggleJoin: () => widget.onToggleJoin(event.id),
        ),
      ),
    );
  }
}

// ── SEARCH BAR ───────────────────────────────────────────────────
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
          color: FanZoneColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: FanZoneColors.dark, width: 2.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x261A1A1A),
              offset: Offset(3, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: FanZoneColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Rechercher un event, club, lieu…',
            hintStyle: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: FanZoneColors.textLight,
            ),
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: 14, right: 8),
              child: Text('🔍', style: TextStyle(fontSize: 18)),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            suffixIcon: ValueListenableBuilder(
              valueListenable: controller,
              builder: (_, value, __) => value.text.isEmpty
                  ? const SizedBox.shrink()
                  : GestureDetector(
                      onTap: () {
                        controller.clear();
                        onChanged('');
                      },
                      child: const Padding(
                        padding: EdgeInsets.only(right: 14),
                        child: Text('✕', style: TextStyle(fontSize: 16, color: FanZoneColors.textLight)),
                      ),
                    ),
            ),
            suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          ),
        ),
      ),
    );
  }
}

// ── FILTER CHIPS ─────────────────────────────────────────────────
class _FilterChips extends StatelessWidget {
  final List<Map<String, String>> sports;
  final String activeSport;
  final bool freeOnly;
  final ValueChanged<String> onSportTap;
  final VoidCallback onFreeToggle;

  const _FilterChips({
    required this.sports,
    required this.activeSport,
    required this.freeOnly,
    required this.onSportTap,
    required this.onFreeToggle,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        children: [
          ...sports.map((s) {
            final active = s['label'] == activeSport;
            return _FilterChip(
              label: '${s['emoji']} ${s['label']}',
              active: active,
              onTap: () => onSportTap(s['label']!),
            );
          }),
          _FilterChip(
            label: '🎟️ Gratuit',
            active: freeOnly,
            activeColor: FanZoneColors.success,
            activeBg: FanZoneColors.successBg,
            onTap: onFreeToggle,
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final Color activeColor;
  final Color activeBg;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
    this.activeColor = FanZoneColors.primary,
    this.activeBg = const Color(0xFFFFF5E0),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: active ? activeBg : FanZoneColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? activeColor : FanZoneColors.border,
            width: active ? 2 : 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: active ? activeColor : FanZoneColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ── EMPTY STATE ──────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool isFiltering;
  const _EmptyState({required this.isFiltering});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Center(
        child: Column(
          children: [
            const Text('🔍', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              isFiltering ? 'Aucun event ne correspond\nà ta recherche.' : 'Aucun event disponible.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: FanZoneColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── HERO BANNER ──────────────────────────────────────────────────
class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 210,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
      ),
      child: Stack(
        children: [
          // Image de fond
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1431324155629-1a6deb1dec8d?w=800&q=80',
              fit: BoxFit.cover,
              color: Colors.black.withValues(alpha: 0.6),
              colorBlendMode: BlendMode.darken,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFF1A1A1A),
              ),
            ),
          ),
          // Emojis flottants déco
          const Positioned(top: 16, left: 20,  child: Text('⚽', style: TextStyle(fontSize: 22, color: Colors.white24))),
          const Positioned(top: 12, right: 40, child: Text('🏀', style: TextStyle(fontSize: 18, color: Colors.white24))),
          const Positioned(top: 50, left: 80,  child: Text('🥁', style: TextStyle(fontSize: 16, color: Colors.white24))),
          const Positioned(top: 40, right: 90, child: Text('🎊', style: TextStyle(fontSize: 20, color: Colors.white24))),
          const Positioned(top: 80, left: 160, child: Text('🏉', style: TextStyle(fontSize: 14, color: Colors.white24))),
          // Contenu
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, FanZoneColors.background],
                  stops: const [0.0, 1.0],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sticker
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: FanZoneColors.yellow,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: FanZoneColors.dark, width: 2),
                    ),
                    child: const Text(
                      '🥁 Venez faire du bruit !',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: FanZoneColors.dark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: FanZoneColors.background,
                        height: 1.1,
                      ),
                      children: [
                        TextSpan(text: 'Bienvenue dans\nla '),
                        TextSpan(
                          text: 'FanZone',
                          style: TextStyle(color: FanZoneColors.yellow),
                        ),
                        TextSpan(text: ' !'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── CLUBS STRIP ──────────────────────────────────────────────────
class _ClubsStrip extends StatelessWidget {
  final _clubs = const [
    {'emoji': '⚽', 'name': 'Ménil', 'color': 0xFFFF4D4D},
    {'emoji': '🏀', 'name': 'BC SDenis', 'color': 0xFFFF8C00},
    {'emoji': '🏐', 'name': 'Vincennes', 'color': 0xFF0096FF},
    {'emoji': '🥋', 'name': 'Aubervilliers', 'color': 0xFF9B27AF},
    {'emoji': '🏃', 'name': 'Pantin', 'color': 0xFF00A86B},
    {'emoji': '🚴', 'name': 'VéloVinc', 'color': 0xFFE65C00},
  ];

  const _ClubsStrip();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _clubs.length,
        itemBuilder: (_, i) {
          final c = _clubs[i];
          final color = Color(c['color'] as int);
          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: FanZoneColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: FanZoneColors.dark, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: FanZoneColors.dark.withValues(alpha: 0.15),
                  offset: const Offset(2, 2),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Row(
              children: [
                Text(c['emoji'] as String, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text(
                  c['name'] as String,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: FanZoneColors.dark,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      '+',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: color,
                      ),
                    ),
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

// ── FAV CARD ─────────────────────────────────────────────────────
class _FavCard extends StatelessWidget {
  final FanZoneEvent event;
  final VoidCallback onTap;

  const _FavCard({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: FanZoneColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: FanZoneColors.dark, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: FanZoneColors.dark.withValues(alpha: 0.12),
              offset: const Offset(3, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 5,
              decoration: BoxDecoration(
                color: event.color,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${event.emoji} ${event.club}',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: FanZoneColors.textLight,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.match,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: FanZoneColors.textPrimary,
                      height: 1.15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        event.dateFormatted,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: FanZoneColors.textLight,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: event.vibeBgColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: event.vibeColor, width: 1.5),
                        ),
                        child: Text(
                          event.daysUntil,
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: event.vibeColor,
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

// ── SECTION HEADER ───────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? badge;
  final String? linkLabel;

  const _SectionHeader({required this.title, this.badge, this.linkLabel});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
        child: Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: FanZoneColors.dark,
              ),
            ),
            const Spacer(),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: FanZoneColors.yellow,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: FanZoneColors.dark, width: 2),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: FanZoneColors.dark,
                  ),
                ),
              ),
            if (linkLabel != null)
              Text(
                linkLabel!,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: FanZoneColors.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
