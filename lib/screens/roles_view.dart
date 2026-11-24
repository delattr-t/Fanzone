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
        Text(
          mine == null ? 'Choisis ton rôle' : 'Tu es ${roleById(mine).label.toLowerCase()}',
          style: fzDisplay(fontSize: 28),
        ),
        const SizedBox(height: 4),
        Text(
          col.joined
              ? 'Un seul rôle par personne dans ce collectif. Tu peux en changer à tout moment.'
              : 'Rejoins le collectif pour prendre un rôle.',
          style: fz(fontSize: 14, color: FanZoneColors.cement, height: 1.4),
        ),
        if (mine != null) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => state.setRole(col.id, null),
            child: Text(
              'Libérer mon rôle',
              style: fz(fontSize: 14, fontWeight: FontWeight.w600, color: FanZoneColors.flare, decoration: TextDecoration.underline),
            ),
          ),
        ],
        const SizedBox(height: 16),
        ...roleCatalog.map((r) {
          final taken = state.roleTaken(col, r.id);
          final isMine = mine == r.id;
          final full = state.roleIsFull(col, r.id);
          final enabled = col.joined && !full;
          return Opacity(
            opacity: enabled || isMine ? 1 : 0.5,
            child: Pressable(
              onTap: enabled ? () => state.setRole(col.id, isMine ? null : r.id) : null,
              child: StickerBlock(
                margin: const EdgeInsets.only(bottom: 10),
                color: isMine ? FanZoneColors.hiVis : FanZoneColors.paper,
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: isMine ? FanZoneColors.ink : FanZoneColors.wall,
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: FanZoneColors.ink, width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          Monogram.initials(r.label),
                          style: fzDisplay(fontSize: 18, color: isMine ? Colors.white : FanZoneColors.ink),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.label, style: fzDisplay(fontSize: 20)),
                          Text(r.hint, style: fz(fontSize: 13, color: FanZoneColors.cement)),
                          const SizedBox(height: 6),
                          Row(
                            children: List.generate(
                              r.max,
                              (i) => Container(
                                width: 14,
                                height: 6,
                                margin: const EdgeInsets.only(right: 3),
                                color: i < taken ? FanZoneColors.ink : FanZoneColors.wallDeep,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    StickerPill(
                      isMine
                          ? 'Toi'
                          : full
                              ? 'Complet'
                              : '$taken sur ${r.max}',
                      color: full && !isMine ? FanZoneColors.cement : FanZoneColors.ink,
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
