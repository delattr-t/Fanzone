import 'package:flutter/material.dart';

import '../models/collectif.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/sticker.dart';
import 'collectif_detail_screen.dart';

class CollectifsScreen extends StatelessWidget {
  final List<Collectif> collectifs;
  final Function(String) onToggle;

  const CollectifsScreen({
    super.key,
    required this.collectifs,
    required this.onToggle,
  });

  void _open(BuildContext context, Collectif col) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => CollectifDetailScreen(collectifId: col.id)));
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final mine = collectifs.where((c) => c.joined).toList();
    final others = collectifs.where((c) => !c.joined).toList();

    return Scaffold(
      backgroundColor: FanZoneColors.paper,
      appBar: AppBar(title: const Text('Collectifs'), automaticallyImplyLeading: false),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
        children: [
          Text(
            'Un collectif, c\'est la bande qui chante ensemble. Rejoins-en un pour accéder au chat, aux chants et prendre un rôle dans la tribune.',
            style: fz(fontSize: 14, color: FanZoneColors.cement, height: 1.45),
          ),
          if (mine.isNotEmpty) ...[
            const SizedBox(height: 20),
            const SectionTitle('Tes collectifs'),
            const SizedBox(height: 12),
            ...mine.map((c) => _CollectifCard(
                  col: c,
                  role: state.myRoleIn(c.id),
                  chantCount: state.chantsFor(c.id).length,
                  onToggle: () => onToggle(c.id),
                  onTap: () => _open(context, c),
                )),
          ],
          const SizedBox(height: 20),
          SectionTitle(mine.isEmpty ? 'Les collectifs du coin' : 'Les autres collectifs'),
          const SizedBox(height: 12),
          ...others.map((c) => _CollectifCard(
                col: c,
                role: null,
                chantCount: state.chantsFor(c.id).length,
                onToggle: () => onToggle(c.id),
                onTap: () => _open(context, c),
              )),
        ],
      ),
    );
  }
}

class _CollectifCard extends StatelessWidget {
  final Collectif col;
  final String? role;
  final int chantCount;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  const _CollectifCard({required this.col, required this.role, required this.chantCount, required this.onToggle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: StickerBlock(
        margin: const EdgeInsets.only(bottom: 12),
        stripe: col.color,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Monogram(name: col.name, color: col.color, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(col.name, style: fzDisplay(fontSize: 24)),
                      const SizedBox(height: 2),
                      Text(col.club, style: fz(fontSize: 13, color: FanZoneColors.cement)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onToggle,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: col.joined ? FanZoneColors.hiVis : FanZoneColors.ink,
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: FanZoneColors.ink, width: 1.5),
                    ),
                    child: Text(
                      col.joined ? 'Membre' : 'Rejoindre',
                      style: fz(fontSize: 14, fontWeight: FontWeight.w600, color: col.joined ? FanZoneColors.ink : Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(col.description, style: fz(fontSize: 14, height: 1.4)),
            const SizedBox(height: 8),
            Text(
              '${col.members} membre${col.members > 1 ? 's' : ''}, $chantCount chant${chantCount > 1 ? 's' : ''}'
              '${role != null ? '. Ton rôle : ${roleById(role!).label.toLowerCase()}' : ''}',
              style: fz(fontSize: 13, color: FanZoneColors.cement),
            ),
          ],
        ),
      ),
    );
  }
}
