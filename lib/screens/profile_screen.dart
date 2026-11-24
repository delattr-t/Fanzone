import 'package:flutter/material.dart';
import '../models/event.dart';
import '../theme/app_theme.dart';
import '../widgets/sticker.dart';
import '../models/collectif.dart';
import '../state/app_state.dart';
import 'clubs_screen.dart';
import 'collectif_detail_screen.dart';
import 'event_detail_screen.dart';

class ProfileScreen extends StatelessWidget {
  final String userName;
  final List<FanZoneEvent> events;
  final List<Collectif> collectifs;
  final Function(int) onToggleJoin;
  final ValueChanged<String> onNameChanged;

  const ProfileScreen({
    super.key,
    required this.userName,
    required this.events,
    required this.collectifs,
    required this.onToggleJoin,
    required this.onNameChanged,
  });

  @override
  Widget build(BuildContext context) {
    final joinedEvents = events.where((e) => e.joined).toList()
      ..sort((a, b) => DateTime.parse(a.date).compareTo(DateTime.parse(b.date)));
    final joinedCollectifs = collectifs.where((c) => c.joined).toList();
    final state = AppScope.of(context);
    final followedClubs = state.clubs.where((c) => state.isFollowing(c.id)).toList();
    final upcoming = joinedEvents.where((e) {
      try {
        return DateTime.parse(e.date).isAfter(DateTime.now().subtract(const Duration(days: 1)));
      } catch (_) {
        return false;
      }
    }).length;

    return Scaffold(
      backgroundColor: FanZoneColors.background,
      body: CustomScrollView(
        slivers: [
          // ── HEADER ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _ProfileHeader(
              userName: userName,
              onEditName: () => _editName(context),
            ),
          ),

          // ── STATS ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _StatsRow(
              eventsCount: joinedEvents.length,
              collectifsCount: joinedCollectifs.length,
              upcomingCount: upcoming,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // ── MES EVENTS ────────────────────────────────────────
          _SectionHeader(title: 'Mes matchs', badge: '${joinedEvents.length}'),
          if (joinedEvents.isEmpty)
            SliverToBoxAdapter(child: _EmptyHint(text: 'Rejoins un event depuis l\'accueil pour le retrouver ici.')),
          if (joinedEvents.isNotEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 152,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: joinedEvents.length,
                  itemBuilder: (_, i) => _EventMiniCard(
                    event: joinedEvents[i],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EventDetailScreen(
                          event: joinedEvents[i],
                          onToggleJoin: () => onToggleJoin(joinedEvents[i].id),
                        ),
                      ),
                    ),
                    onLeave: () => onToggleJoin(joinedEvents[i].id),
                  ),
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // ── MES COLLECTIFS ────────────────────────────────────
          _SectionHeader(title: 'Mes collectifs', badge: '${joinedCollectifs.length}'),
          if (joinedCollectifs.isEmpty)
            SliverToBoxAdapter(child: _EmptyHint(text: 'Rejoins un collectif pour y retrouver ta tribu.')),
          if (joinedCollectifs.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: joinedCollectifs.map((c) => GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => CollectifDetailScreen(collectifId: c.id)),
                    ),
                    child: _CollectifChip(col: c, role: AppScope.of(context).myRoleIn(c.id)),
                  )).toList(),
                ),
              ),
            ),

          // ── MES CLUBS ─────────────────────────────────────────
          _SectionHeader(title: 'Clubs suivis', badge: '${followedClubs.length}'),
          if (followedClubs.isEmpty)
            SliverToBoxAdapter(child: _EmptyHint(text: 'Suis un club pour être alerté de ses prochains matchs.')),
          if (followedClubs.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: followedClubs.map((c) => GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ClubDetailScreen(clubId: c.id)),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: c.bgColor,
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: c.color, width: 1.5),
                      ),
                      child: Text(c.name, style: fz(fontSize: 13, fontWeight: FontWeight.w600, color: c.color)),
                    ),
                  )).toList(),
                ),
              ),
            ),

          // ── DÉCONNEXION ───────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
              child: GestureDetector(
                onTap: () => _confirmSignOut(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: FanZoneColors.surface,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: FanZoneColors.border, width: 1.5),
                  ),
                  child: Center(
                    child: Text('Changer de profil / tout effacer', style: fz(fontSize: 13, fontWeight: FontWeight.w600, color: FanZoneColors.textSecondary)),
                  ),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FanZoneColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(3),
          side: const BorderSide(color: FanZoneColors.dark, width: 1.5),
        ),
        title: Text('Repartir de zéro?', style: fzDisplay(fontSize: 21)),
        content: Text(
          'Tes events, collectifs, rôles et messages seront effacés de ce téléphone.',
          style: fz(fontWeight: FontWeight.w500, fontSize: 13, color: FanZoneColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Annuler', style: fz(fontWeight: FontWeight.w600, color: FanZoneColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: FanZoneColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              AppScope.read(context).signOut();
            },
            child: const Text('Effacer'),
          ),
        ],
      ),
    );
  }

  void _editName(BuildContext context) {
    final controller = TextEditingController(text: userName);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: FanZoneColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(3),
          side: const BorderSide(color: FanZoneColors.dark, width: 1.5),
        ),
        title: Text(
          'Ton prénom',
          style: fzDisplay(fontSize: 21),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          style: fz(fontWeight: FontWeight.w600,
            fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Ton prénom…',
            hintStyle: fz(color: FanZoneColors.textLight),
            filled: true,
            fillColor: FanZoneColors.cream,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(3),
              borderSide: const BorderSide(color: FanZoneColors.dark, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(3),
              borderSide: const BorderSide(color: FanZoneColors.primary, width: 1.5),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: fz(fontWeight: FontWeight.w600, color: FanZoneColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) onNameChanged(name);
              Navigator.pop(context);
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }
}

// ── PROFILE HEADER ───────────────────────────────────────────────
class _ProfileHeader extends StatelessWidget {
  final String userName;
  final VoidCallback onEditName;

  const _ProfileHeader({required this.userName, required this.onEditName});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: FanZoneColors.ink,
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 22, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 6, width: 56, color: FanZoneColors.flare),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  userName,
                  style: fzDisplay(fontSize: 44, color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: -1),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: onEditName,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    'Modifier',
                    style: fz(fontSize: 14, fontWeight: FontWeight.w600, color: FanZoneColors.hiVis, decoration: TextDecoration.underline),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Supporter de sport local', style: fz(fontSize: 14, color: Colors.white70)),
        ],
      ),
    );
  }
}

// ── STATS ROW ────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final int eventsCount;
  final int collectifsCount;
  final int upcomingCount;

  const _StatsRow({
    required this.eventsCount,
    required this.collectifsCount,
    required this.upcomingCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: FanZoneColors.surface,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: FanZoneColors.dark, width: 1.5)
      ),
      child: Row(
        children: [
          _StatCell(value: '$eventsCount', label: 'matchs\nannoncés', emoji: ''),
          _Divider(),
          _StatCell(value: '$collectifsCount', label: 'collectifs\nrejoints', emoji: ''),
          _Divider(),
          _StatCell(value: '$upcomingCount', label: 'à venir\ncette saison', emoji: ''),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String value;
  final String label;
  final String emoji;

  const _StatCell({required this.value, required this.label, required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            const SizedBox.shrink(),
            const SizedBox(height: 4),
            Text(
              value,
              style: fzDisplay(fontSize: 34),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: fz(fontSize: 12, color: FanZoneColors.cement, height: 1.25),
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1.5, height: 60, color: FanZoneColors.border);
  }
}

// ── EVENT MINI CARD ──────────────────────────────────────────────
class _EventMiniCard extends StatelessWidget {
  final FanZoneEvent event;
  final VoidCallback onTap;
  final VoidCallback onLeave;

  const _EventMiniCard({required this.event, required this.onTap, required this.onLeave});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 170,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: FanZoneColors.surface,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: event.color, width: 1.5)
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 5,
              decoration: BoxDecoration(
                color: event.color,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.club,
                      style: fz(fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: FanZoneColors.textLight),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.match,
                      style: fz(fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: FanZoneColors.textPrimary,
                        height: 1.2),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${event.dateFormatted}, ${event.time}',
                          style: fz(fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: FanZoneColors.textLight),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: onLeave,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        decoration: BoxDecoration(
                          color: FanZoneColors.errorBg,
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: FanZoneColors.error, width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            'Quitter',
                            style: fz(fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: FanZoneColors.error),
                          ),
                        ),
                      ),
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
}

// ── COLLECTIF CHIP ───────────────────────────────────────────────
class _CollectifChip extends StatelessWidget {
  final Collectif col;
  final String? role;
  const _CollectifChip({required this.col, this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: col.bgColor,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: col.color, width: 1.5)
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Monogram(name: col.name, color: col.color, size: 28),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                col.name,
                style: fz(fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: col.color),
              ),
              Text(
                role == null ? '${col.members} membres' : roleById(role!).label,
                style: fz(fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: FanZoneColors.textLight),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── SECTION HEADER ───────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? badge;

  const _SectionHeader({required this.title, this.badge});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 12),
        child: SectionTitle(badge == null ? title : '$title ($badge)'),
      ),
    );
  }
}

// ── EMPTY HINT ───────────────────────────────────────────────────
class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: FanZoneColors.cream,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: FanZoneColors.border, width: 1.5),
        ),
        child: Text(
          text,
          style: fz(fontSize: 13,
            fontWeight: FontWeight.w500,
            color: FanZoneColors.textSecondary,
            height: 1.5),
        ),
      ),
    );
  }
}
