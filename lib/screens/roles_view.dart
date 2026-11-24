import 'package:flutter/material.dart';

import '../models/collectif.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/sticker.dart';

/// Choix d'un rôle dans la tribune (1 rôle max par membre et par collectif).
class RolesView extends StatelessWidget {
  final Collectif col;
  const RolesView({super.key, required this.col});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final mine = state.myRoleIn(col.id);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        StickerBlock(
          borderColor: col.color,
          color: col.bgColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                mine == null ? '🥁 Choisis ton rôle' : '${roleById(mine).emoji} Tu es ${roleById(mine).label}',
                style: TextStyle(fontFamily: 'Nunito', fontSize: 17, fontWeight: FontWeight.w900, color: col.color),
              ),
              const SizedBox(height: 4),
              Text(
                col.joined
                    ? 'Un seul rôle par personne dans ce collectif. Tu peux en changer à tout moment.'
                    : 'Rejoins le collectif pour prendre un rôle.',
                style: const TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w600, color: FanZoneColors.textSecondary, height: 1.4),
              ),
              if (mine != null) ...[
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => state.setRole(col.id, null),
                  child: const Text('Libérer mon rôle ✕', style: TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w900, color: FanZoneColors.error)),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...roleCatalog.map((r) {
          final taken = state.roleTaken(col, r.id);
          final isMine = mine == r.id;
          final full = state.roleIsFull(col, r.id);
          final enabled = col.joined && !full;
          return Opacity(
            opacity: enabled || isMine ? 1 : 0.55,
            child: GestureDetector(
              onTap: enabled ? () => state.setRole(col.id, isMine ? null : r.id) : null,
              child: StickerBlock(
                margin: const EdgeInsets.only(bottom: 10),
                borderColor: isMine ? col.color : FanZoneColors.dark,
                color: isMine ? col.bgColor : FanZoneColors.surface,
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 46, height: 46,
                      decoration: BoxDecoration(
                        color: FanZoneColors.cream,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: FanZoneColors.dark, width: 2),
                      ),
                      child: Center(child: Text(r.emoji, style: const TextStyle(fontSize: 24))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.label, style: TextStyle(fontFamily: 'Nunito', fontSize: 15, fontWeight: FontWeight.w900, color: isMine ? col.color : FanZoneColors.dark)),
                          Text(r.hint, style: const TextStyle(fontFamily: 'Nunito', fontSize: 11, fontWeight: FontWeight.w600, color: FanZoneColors.textSecondary)),
                          const SizedBox(height: 6),
                          Row(
                            children: List.generate(r.max, (i) => Container(
                              width: 10, height: 10,
                              margin: const EdgeInsets.only(right: 4),
                              decoration: BoxDecoration(
                                color: i < taken ? col.color : FanZoneColors.border,
                                shape: BoxShape.circle,
                              ),
                            )),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    StickerPill(
                      isMine ? 'Moi ✓' : full ? 'Complet' : '$taken/${r.max}',
                      color: isMine ? col.color : full ? FanZoneColors.textLight : FanZoneColors.dark,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
