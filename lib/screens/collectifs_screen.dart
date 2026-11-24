import 'package:flutter/material.dart';

import '../models/collectif.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
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
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CollectifDetailScreen(collectifId: col.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final myCollectifs = collectifs.where((c) => c.joined).toList();

    return Scaffold(
      backgroundColor: FanZoneColors.background,
      appBar: AppBar(title: const Text('🎊 Collectifs'), automaticallyImplyLeading: false),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 80),
        children: [
          if (myCollectifs.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: FanZoneColors.warningBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: FanZoneColors.yellow, width: 2.5),
                  boxShadow: const [BoxShadow(color: Color(0xFFFFD166), offset: Offset(2,2), blurRadius: 0)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('✨ Mes collectifs', style: TextStyle(fontFamily:'Nunito', fontSize:11, fontWeight:FontWeight.w900, color:Color(0xFFB8860B), letterSpacing:1)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6, runSpacing: 6,
                      children: myCollectifs.map((c) {
                        final role = state.myRoleIn(c.id);
                        return GestureDetector(
                          onTap: () => _open(context, c),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: FanZoneColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: c.color, width: 2.5),
                            ),
                            child: Text(
                              '${c.emoji} ${c.name}${role != null ? ' · ${roleById(role).emoji}' : ''}',
                              style: TextStyle(fontFamily:'Nunito', fontSize:13, fontWeight:FontWeight.w900, color:c.color),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: Text(
              'Rejoins un collectif pour accéder au chat, aux chants et choisir ton rôle dans la tribune !',
              style: TextStyle(fontFamily:'Nunito', fontSize:13, fontWeight:FontWeight.w600, color:FanZoneColors.textSecondary, height:1.5),
            ),
          ),

          ...collectifs.map((col) => _CollectifCard(
                col: col,
                chantCount: state.chantsFor(col.id).length,
                onToggle: () => onToggle(col.id),
                onTap: () => _open(context, col),
              )),
        ],
      ),
    );
  }
}

class _CollectifCard extends StatelessWidget {
  final Collectif col;
  final int chantCount;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  const _CollectifCard({required this.col, required this.chantCount, required this.onToggle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: FanZoneColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: col.joined ? col.color : FanZoneColors.dark, width: 2.5),
          boxShadow: [BoxShadow(
            color: (col.joined ? col.color : FanZoneColors.dark).withValues(alpha: 0.15),
            offset: const Offset(3,3), blurRadius: 0,
          )],
        ),
        child: Column(
          children: [
            Container(height: 6, decoration: BoxDecoration(
              color: col.color,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            )),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(col.emoji, style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(col.name, style: TextStyle(fontFamily:'Nunito', fontSize:17, fontWeight:FontWeight.w900, color: col.joined ? col.color : FanZoneColors.dark)),
                            Text(col.club, style: const TextStyle(fontFamily:'Nunito', fontSize:11, fontWeight:FontWeight.w700, color:FanZoneColors.textLight)),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: onToggle,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: col.joined ? FanZoneColors.successBg : col.color,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: col.joined ? FanZoneColors.success : col.color, width: 2),
                            boxShadow: [BoxShadow(
                              color: (col.joined ? FanZoneColors.success : col.color).withValues(alpha: 0.25),
                              offset: const Offset(2,2), blurRadius: 0,
                            )],
                          ),
                          child: Text(
                            col.joined ? '✓ Rejoint' : 'Rejoindre',
                            style: TextStyle(fontFamily:'Nunito', fontSize:12, fontWeight:FontWeight.w900, color: col.joined ? FanZoneColors.success : Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(col.description, style: const TextStyle(fontFamily:'Nunito', fontSize:12, fontWeight:FontWeight.w600, color:FanZoneColors.textSecondary, height:1.5)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text('👥 ${col.members} membre${col.members>1?"s":""}', style: const TextStyle(fontFamily:'Nunito', fontSize:12, fontWeight:FontWeight.w800, color:FanZoneColors.textLight)),
                      const SizedBox(width: 10),
                      Text('🎵 $chantCount chant${chantCount>1?"s":""}', style: const TextStyle(fontFamily:'Nunito', fontSize:12, fontWeight:FontWeight.w800, color:FanZoneColors.textLight)),
                      const Spacer(),
                      if (col.joined)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: FanZoneColors.successBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: FanZoneColors.success, width: 2),
                          ),
                          child: const Text('💬 Chat · Chants · Rôles →', style: TextStyle(fontFamily:'Nunito', fontSize:11, fontWeight:FontWeight.w900, color:FanZoneColors.success)),
                        )
                      else
                        const Text('Voir →', style: TextStyle(fontFamily:'Nunito', fontSize:12, fontWeight:FontWeight.w900, color:FanZoneColors.textLight)),
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
