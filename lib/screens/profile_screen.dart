import 'package:flutter/material.dart';
import '../models/event.dart';
import '../theme/app_theme.dart';
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
          _SectionHeader(title: '📌 Mes events', badge: '${joinedEvents.length}'),
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
          _SectionHeader(title: '🎊 Mes collectifs', badge: '${joinedCollectifs.length}'),
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
          _SectionHeader(title: '🏅 Clubs suivis', badge: '${followedClubs.length}'),
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
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: c.color, width: 2.5),
                      ),
                      child: Text('${c.emoji} ${c.name}', style: TextStyle(fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w900, color: c.color)),
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
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: FanZoneColors.border, width: 2),
                  ),
                  child: const Center(
                    child: Text('Changer de profil / tout effacer', style: TextStyle(fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w800, color: FanZoneColors.textSecondary)),
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
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: FanZoneColors.dark, width: 2.5),
        ),
        title: const Text('Repartir de zéro ?', style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w900, fontSize: 18)),
        content: const Text(
          'Tes events, collectifs, rôles et messages seront effacés de ce téléphone.',
          style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w600, fontSize: 13, color: FanZoneColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler', style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, color: FanZoneColors.textSecondary)),
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
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: FanZoneColors.dark, width: 2.5),
        ),
        title: const Text(
          '✏️ Ton prénom',
          style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w900, fontSize: 18),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: 'Ton prénom…',
            hintStyle: const TextStyle(fontFamily: 'Nunito', color: FanZoneColors.textLight),
            filled: true,
            fillColor: FanZoneColors.cream,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: FanZoneColors.dark, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: FanZoneColors.primary, width: 2.5),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler', style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, color: FanZoneColors.textSecondary)),
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
    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : 'F';
    return Container(
      decoration: const BoxDecoration(
        color: FanZoneColors.dark,
      ),
      padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 24, 24, 28),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: FanZoneColors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: FanZoneColors.yellow, width: 3),
              boxShadow: const [
                BoxShadow(color: Color(0xFFFFD166), offset: Offset(3, 3), blurRadius: 0),
              ],
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '👋 Salut,',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: FanZoneColors.textLight,
                  ),
                ),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        userName,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: onEditName,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: FanZoneColors.yellow,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: FanZoneColors.yellow, width: 1.5),
                        ),
                        child: const Text(
                          '✏️',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: FanZoneColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: FanZoneColors.primary, width: 1.5),
                  ),
                  child: const Text(
                    '🏟️ Fan de sport local',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: FanZoneColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FanZoneColors.dark, width: 2.5),
        boxShadow: const [
          BoxShadow(color: Color(0x261A1A1A), offset: Offset(3, 3), blurRadius: 0),
        ],
      ),
      child: Row(
        children: [
          _StatCell(value: '$eventsCount', label: 'Events\nrejoints', emoji: '🎟️'),
          _Divider(),
          _StatCell(value: '$collectifsCount', label: 'Collectifs\nrejoints', emoji: '🎊'),
          _Divider(),
          _StatCell(value: '$upcomingCount', label: 'À venir\nbientôt', emoji: '📅'),
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
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: FanZoneColors.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: FanZoneColors.textLight,
                height: 1.3,
              ),
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
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: event.color, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: event.color.withValues(alpha: 0.2),
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
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
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: FanZoneColors.textPrimary,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${event.dateFormatted} · ${event.time}',
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: FanZoneColors.textLight,
                          ),
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
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: FanZoneColors.error, width: 1.5),
                        ),
                        child: const Center(
                          child: Text(
                            'Quitter',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: FanZoneColors.error,
                            ),
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: col.color, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: col.color.withValues(alpha: 0.2),
            offset: const Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(col.emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                col.name,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: col.color,
                ),
              ),
              Text(
                role == null ? '👥 ${col.members} membres' : '${roleById(role!).emoji} ${roleById(role!).label}',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: FanZoneColors.textLight,
                ),
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
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
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
          ],
        ),
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
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: FanZoneColors.border, width: 1.5),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: FanZoneColors.textSecondary,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}
