import 'package:flutter/material.dart';

import '../models/collectif.dart';
import '../models/social.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/sticker.dart';

/// Liste des chants d'un collectif: podium, vote, proposition.
class ChantsView extends StatelessWidget {
 final Collectif col;
 const ChantsView({super.key, required this.col});

 Future<void> _propose(BuildContext context) async {
 final title = TextEditingController();
 final lyrics = TextEditingController();
 final rhythm = TextEditingController();
 final ok = await showModalBottomSheet<bool>(
 context: context,
 isScrollControlled: true,
 backgroundColor: Colors.transparent,
 builder: (ctx) => Padding(
 padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
 child: Container(
 padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
 decoration: const BoxDecoration(
 color: FanZoneColors.background,
 borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
 border: Border(top: BorderSide(color: FanZoneColors.dark, width: 1.5)),
 ),
 child: SingleChildScrollView(
 child: Column(
 mainAxisSize: MainAxisSize.min,
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: FanZoneColors.border, borderRadius: BorderRadius.circular(2)))),
 const SizedBox(height: 14),
 Text('Proposer un chant', style: fzDisplay(fontSize: 23, color: col.color)),
 const SizedBox(height: 4),
 Text('Les membres votent, le podium décide de ce qu\'on chante samedi.',
                    style: fz(fontSize: 12, fontWeight: FontWeight.w500, color: FanZoneColors.textSecondary)),
                const SizedBox(height: 16),
                StickerField(controller: title, label: 'Titre', hint: 'Ex: Allez Ménil!'),
                StickerField(controller: lyrics, label: 'Paroles', hint: 'Une ligne par vers', maxLines: 4),
                StickerField(controller: rhythm, label: 'Rythme / air', hint: 'Ex: clap-clap-clap • clap-clap, ou « sur l\'air de… »'),
                StickerButton(
                  label: 'Envoyer au vote',
                  color: col.color,
                  onTap: () => Navigator.pop(ctx, true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (ok == true && title.text.trim().isNotEmpty && context.mounted) {
      await AppScope.read(context).proposeChant(
        collectifId: col.id,
        title: title.text,
        lyrics: lyrics.text,
        rhythm: rhythm.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final chants = state.chantsFor(col.id);
    final podium = chants.take(3).toList();

    return Scaffold(
      backgroundColor: FanZoneColors.background,
      floatingActionButton: col.joined
          ? FloatingActionButton.extended(
              onPressed: () => _propose(context),
              backgroundColor: col.color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: FanZoneColors.dark, width: 1.5),
              ),
              label: Text('Proposer un chant', style: fz(fontWeight: FontWeight.w700)),
              icon: const Text('', style: TextStyle(fontSize: 18)),
            )
          : null,
      body: chants.isEmpty
          ? const EmptyHint(emoji: '', text: 'Aucun chant pour l\'instant. Propose le premier!')
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                if (podium.isNotEmpty) ...[
                  const StickerLabel('Podium du collectif'),
                  _Podium(podium: podium, color: col.color),
                  const SizedBox(height: 18),
                  const StickerLabel('Tous les chants'),
                ],
                ...chants.asMap().entries.map((e) => _ChantCard(
                      rank: e.key + 1,
                      chant: e.value,
                      color: col.color,
                      voted: state.hasVoted(e.value.id),
                      canVote: col.joined,
                      onVote: () => state.toggleVote(e.value.id),
                    )),
                if (!col.joined)
                  Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('Rejoins le collectif pour voter et proposer des chants.',
                        textAlign: TextAlign.center,
                        style: fz(fontSize: 12, fontWeight: FontWeight.w600, color: FanZoneColors.textLight)),
                  ),
              ],
            ),
    );
  }
}

class _Podium extends StatelessWidget {
  final List<Chant> podium;
  final Color color;
  const _Podium({required this.podium, required this.color});

  @override
  Widget build(BuildContext context) {
    const medals = ['', '', ''];
    const heights = [92.0, 72.0, 58.0];
    final order = podium.length == 3 ? [1, 0, 2] : List.generate(podium.length, (i) => i);
    return SizedBox(
      height: 150,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: order.map((i) {
          final c = podium[i];
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(c.title, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                      style: fz(fontSize: 11, fontWeight: FontWeight.w700, color: FanZoneColors.dark)),
                  const SizedBox(height: 4),
                  Container(
                    height: heights[i],
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: i == 0 ? color : color.withValues(alpha: 0.5 - i * 0.12),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                      border: Border.all(color: FanZoneColors.dark, width: 1.5)
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(medals[i], style: const TextStyle(fontSize: 22)),
                        Text('${c.votes}', style: fz(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ChantCard extends StatefulWidget {
  final int rank;
  final Chant chant;
  final Color color;
  final bool voted;
  final bool canVote;
  final VoidCallback onVote;
  const _ChantCard({
    required this.rank,
    required this.chant,
    required this.color,
    required this.voted,
    required this.canVote,
    required this.onVote,
  });

  @override
  State<_ChantCard> createState() => _ChantCardState();
}

class _ChantCardState extends State<_ChantCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.chant;
    return StickerBlock(
      margin: const EdgeInsets.only(bottom: 10),
      borderColor: widget.voted ? widget.color : FanZoneColors.dark,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                  color: widget.rank <= 3 ? FanZoneColors.yellow : FanZoneColors.cream,
                  shape: BoxShape.circle,
                  border: Border.all(color: FanZoneColors.dark, width: 1.5),
                ),
                child: Center(child: Text('${widget.rank}', style: fz(fontSize: 13, fontWeight: FontWeight.w700, color: FanZoneColors.dark))),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _open = !_open),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.title, style: fzDisplay(fontSize: 18, color: FanZoneColors.dark)),
                      Text('par ${c.authorName}, ${_open ? 'replier' : 'voir les paroles'}',
                          style: fz(fontSize: 11, fontWeight: FontWeight.w600, color: FanZoneColors.textLight)),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: widget.canVote ? widget.onVote : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: widget.voted ? widget.color : FanZoneColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: widget.voted ? widget.color : FanZoneColors.dark, width: 1.5),
                  ),
                  child: Text(
                    '${c.votes}',
                    style: fz(fontSize: 13, fontWeight: FontWeight.w700, color: widget.voted ? Colors.white : FanZoneColors.dark),
                  ),
                ),
              ),
            ],
          ),
          if (_open) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: FanZoneColors.cream,
                borderRadius: BorderRadius.circular(14),
                border: Border(left: BorderSide(color: widget.color, width: 1.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.lyrics.isEmpty ? '(pas de paroles)' : c.lyrics,
                      style: fz(fontSize: 14, fontWeight: FontWeight.w600, color: FanZoneColors.dark, height: 1.5)),
                  if (c.rhythm.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('${c.rhythm}', style: fz(fontSize: 12, fontWeight: FontWeight.w600, color: FanZoneColors.textSecondary)),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
