import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/sticker.dart';
import 'chants_view.dart';
import 'chat_view.dart';
import 'roles_view.dart';

/// Fiche d'un collectif : chat, chants, rôles.
class CollectifDetailScreen extends StatefulWidget {
  final String collectifId;
  final int initialTab;
  const CollectifDetailScreen({super.key, required this.collectifId, this.initialTab = 0});

  @override
  State<CollectifDetailScreen> createState() => _CollectifDetailScreenState();
}

class _CollectifDetailScreenState extends State<CollectifDetailScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this, initialIndex: widget.initialTab);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    final state = AppScope.read(context);
    final col = state.collectifById(widget.collectifId);
    if (col == null) return;
    final willJoin = !col.joined;
    await state.toggleJoinCollectif(col.id);
    if (mounted) {
      showFanToast(context, willJoin ? '🎊 Bienvenue chez ${col.name} !' : 'Tu as quitté le collectif');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final col = state.collectifById(widget.collectifId);
    if (col == null) {
      return const Scaffold(body: Center(child: Text('Collectif introuvable')));
    }
    final upcoming = state.upcomingEvents.where((e) => e.clubId == col.clubId || e.collectifIds.contains(col.id)).toList();

    return Scaffold(
      backgroundColor: FanZoneColors.background,
      appBar: AppBar(
        title: Text('${col.emoji} ${col.name}'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(118),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(col.club, style: const TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w800, color: FanZoneColors.textLight)),
                          Text(
                            '👥 ${col.members} membres${upcoming.isNotEmpty ? ' · 📅 prochain : ${upcoming.first.dateFormatted}' : ''}',
                            style: const TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w700, color: FanZoneColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: _toggle,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: col.joined ? FanZoneColors.successBg : col.color,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: col.joined ? FanZoneColors.success : col.color, width: 2),
                          boxShadow: [BoxShadow(color: (col.joined ? FanZoneColors.success : col.color).withValues(alpha: 0.25), offset: const Offset(2, 2), blurRadius: 0)],
                        ),
                        child: Text(
                          col.joined ? '✓ Membre' : 'Rejoindre',
                          style: TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w900, color: col.joined ? FanZoneColors.success : Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: col.color, width: 4)),
                ),
                child: TabBar(
                  controller: _tabs,
                  labelColor: col.color,
                  unselectedLabelColor: FanZoneColors.textLight,
                  indicatorColor: col.color,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w900),
                  unselectedLabelStyle: const TextStyle(fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w800),
                  tabs: const [
                    Tab(text: '💬 Chat'),
                    Tab(text: '🎵 Chants'),
                    Tab(text: '🥁 Rôles'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          ChatView(
            channel: 'col:${col.id}',
            accent: col.color,
            locked: !col.joined,
            lockedHint: 'Le chat est réservé aux membres du collectif.',
            onUnlock: _toggle,
          ),
          ChantsView(col: col),
          RolesView(col: col),
        ],
      ),
    );
  }
}
