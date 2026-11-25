import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/scarf.dart';
import '../widgets/sticker.dart';
import 'chants_view.dart';
import 'chat_view.dart';
import 'roles_view.dart';

/// Fiche d'un collectif: chat, chants, rôles.
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
      showFanToast(context, willJoin ? 'Bienvenue chez ${col.name}.' : 'Tu as quitté ${col.name}.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final col = state.collectifById(widget.collectifId);
    if (col == null) {
      return const Scaffold(body: Center(child: Text('Collectif introuvable')));
    }
    final upcoming =
        state.upcomingEvents.where((e) => e.clubId == col.clubId || e.collectifIds.contains(col.id)).toList();

    return Scaffold(
      backgroundColor: FanZoneColors.wool,
      appBar: AppBar(
        title: Text(col.name),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(178),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 14),
                child: Scarf.club(col.color, label: col.name, height: 40),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    Monogram(name: col.name, color: col.color, size: 44),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(col.club, style: fz(fontSize: 14, fontWeight: FontWeight.w600)),
                          Text(
                            '${col.members} membres${upcoming.isNotEmpty ? ', prochain match le ${upcoming.first.dateFormatted}' : ''}',
                            style: fz(fontSize: 13, color: FanZoneColors.cement),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Pressable(
                      onTap: _toggle,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: col.joined ? FanZoneColors.hiVis : FanZoneColors.flare,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: FanZoneColors.wallDeep, width: 1.5),
                        ),
                        child: Text(
                          col.joined ? 'Membre' : 'Rejoindre',
                          style: fz(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: col.joined ? FanZoneColors.ink : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: FanZoneColors.wallDeep, width: 1.5)),
                ),
                child: TabBar(
                  controller: _tabs,
                  labelColor: FanZoneColors.ink,
                  unselectedLabelColor: FanZoneColors.cement,
                  indicatorColor: col.color,
                  indicatorWeight: 4,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelStyle: fzDisplay(fontSize: 20),
                  unselectedLabelStyle: fzDisplay(fontSize: 20, fontWeight: FontWeight.w600),
                  tabs: const [
                    Tab(text: 'Chat'),
                    Tab(text: 'Chants'),
                    Tab(text: 'Rôles'),
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
