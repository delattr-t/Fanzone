import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../models/event.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/match_story.dart';
import '../widgets/share_sheet.dart';
import '../widgets/sticker.dart';

/// Aperçu de la story du match, puis partage de l'image (Instagram, Snapchat…) ou
/// téléchargement sur ordinateur.
class StoryScreen extends StatefulWidget {
  final FanZoneEvent event;
  const StoryScreen({super.key, required this.event});

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen> {
  final _story = GlobalKey();
  bool _busy = false;

  Future<Uint8List> _render() async {
    final boundary = _story.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  Future<void> _share() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final bytes = await _render();
      final file = XFile.fromData(bytes, mimeType: 'image/png', name: 'fanzone-match-${widget.event.id}.png');
      final result = await SharePlus.instance.share(ShareParams(files: [file], text: shareUrl(widget.event)));
      if (!mounted) return;
      if (result.status == ShareResultStatus.unavailable) {
        showFanToast(context, 'Image enregistrée dans tes téléchargements.');
      }
    } catch (_) {
      if (mounted) showFanToast(context, 'Impossible de préparer l\'image, réessaie.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: shareUrl(widget.event)));
    if (mounted) showFanToast(context, 'Lien copié, colle-le dans l\'autocollant « Lien ».');
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    final club = AppScope.of(context).clubById(e.clubId);

    return Scaffold(
      backgroundColor: FanZoneColors.night,
      appBar: AppBar(
        backgroundColor: FanZoneColors.night,
        foregroundColor: FanZoneColors.cream,
        iconTheme: const IconThemeData(color: FanZoneColors.cream),
        surfaceTintColor: Colors.transparent,
        title: Text('Ta story', style: fzDisplay(fontSize: 24, color: FanZoneColors.cream)),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 9 / 16,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 30, offset: const Offset(0, 12))],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: FittedBox(
                          child: RepaintBoundary(
                            key: _story,
                            child: MatchStory(event: e, clubLabel: club?.shortName ?? e.club),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                children: [
                  Text(
                    'Publie-la en story, puis ajoute l\'autocollant « Lien » avec l\'adresse du match.',
                    textAlign: TextAlign.center,
                    style: fz(fontSize: 14, color: FanZoneColors.wallDeep, height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  StickerButton(
                    label: _busy ? 'Préparation…' : 'Partager l\'image',
                    color: FanZoneColors.flare,
                    fontSize: 16,
                    onTap: _busy ? null : _share,
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: _copyLink,
                    icon: const Icon(Icons.link_rounded, color: FanZoneColors.hiVis),
                    label: Text('Copier le lien du match', style: fz(fontSize: 15, fontWeight: FontWeight.w700, color: FanZoneColors.cream)),
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
