import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../models/event.dart';
import '../screens/story_screen.dart';
import '../theme/app_theme.dart';
import 'scarf.dart';
import 'sticker.dart';

/// Lien direct vers la fiche d'un match dans l'app web.
String matchLink(FanZoneEvent e) => '${AppConfig.shareBaseUrl}#/match/${e.id}';

/// Lien à partager : passe par le service d'aperçu quand il est en ligne, pour que les
/// réseaux affichent la carte du match, sinon pointe directement vers l'app.
String shareUrl(FanZoneEvent e, {String service = AppConfig.shareServiceUrl}) {
  if (service.isEmpty) return matchLink(e);
  final base = service.endsWith('/') ? service : '$service/';
  return '${base}m/${e.id}';
}

/// Le lien tel qu'on l'imprime sur une image (sans « https:// »).
String shareLinkLabel(FanZoneEvent e) => shareUrl(e).replaceFirst(RegExp(r'^https?://'), '');

/// Le message envoyé aux potes : quoi, quand, où, et le lien.
String matchInvite(FanZoneEvent e) {
  return '${e.match}, ${matchWhen(e)}, ${e.venue}. '
      '${e.supporters > 0 ? '${e.supporters} supporters déjà annoncés. ' : ''}'
      'On y va ensemble ?\n${shareUrl(e)}';
}

/// Lit `#/match/<id>` dans une adresse ; `null` si ce n'est pas un lien de match.
int? matchIdFromUri(Uri uri) {
  final m = RegExp(r'^/?match/(\d+)').firstMatch(uri.fragment);
  return m == null ? null : int.tryParse(m.group(1)!);
}

/// « jeudi 26 novembre à 19 h 30 ».
String matchWhen(FanZoneEvent e) {
  try {
    final d = DateTime.parse(e.date);
    const days = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'];
    const months = ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'];
    final p = e.time.split(':');
    final hour = p.length < 2 ? e.time : (p[1] == '00' ? '${int.parse(p[0])} h' : '${int.parse(p[0])} h ${p[1]}');
    return '${days[d.weekday - 1]} ${d.day} ${months[d.month - 1]} à $hour';
  } catch (_) {
    return '${e.date} à ${e.time}';
  }
}

/// Le menu de partage natif n'existe vraiment que sur téléphone (appli ou navigateur mobile).
bool get nativeShareAvailable =>
    defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;

/// Panneau « Ramène tes potes » : aperçu du message, puis les réseaux.
Future<void> showShareSheet(BuildContext context, FanZoneEvent e) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: FanZoneColors.wool,
    builder: (_) => _ShareSheet(event: e),
  );
}

class _ShareSheet extends StatelessWidget {
  final FanZoneEvent event;
  const _ShareSheet({required this.event});

  Future<void> _open(BuildContext context, Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!context.mounted) return;
    if (!ok) return _copy(context);
    Navigator.pop(context);
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: matchInvite(event)));
    if (!context.mounted) return;
    Navigator.pop(context);
    showFanToast(context, 'Message copié. Colle-le où tu veux.');
  }

  Future<void> _native(BuildContext context) async {
    Navigator.pop(context);
    await SharePlus.instance.share(ShareParams(text: matchInvite(event), subject: event.match));
  }

  void _story(BuildContext context) {
    final nav = Navigator.of(context);
    nav.pop();
    nav.push(MaterialPageRoute(builder: (_) => StoryScreen(event: event)));
  }

  @override
  Widget build(BuildContext context) {
    final text = matchInvite(event);
    final enc = Uri.encodeComponent(text);
    final link = Uri.encodeComponent(shareUrl(event));
    final teaser = Uri.encodeComponent('${event.match}, ${matchWhen(event)}. On y va ensemble ?');
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(color: FanZoneColors.wallDeep, borderRadius: BorderRadius.circular(9)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Ramène tes potes', style: fzDisplay(fontSize: 30)),
            const SizedBox(height: 4),
            Text(
              'Le lien ouvre directement la fiche du match.',
              style: fz(fontSize: 14, color: FanZoneColors.cement, height: 1.4),
            ),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: FanZoneColors.paper,
                borderRadius: BorderRadius.circular(20),
                boxShadow: FanZoneColors.lift,
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Scarf.club(event.color, height: 10, fringe: false),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: SelectableText(text, style: fz(fontSize: 14, height: 1.45)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _Option(
                  label: 'WhatsApp',
                  color: FanZoneColors.green,
                  icon: Icons.chat_rounded,
                  onTap: () => _open(context, Uri.parse('https://wa.me/?text=$enc')),
                ),
                const SizedBox(width: 10),
                _Option(
                  label: 'Story',
                  color: FanZoneColors.purple,
                  icon: Icons.amp_stories_rounded,
                  onTap: () => _story(context),
                ),
                const SizedBox(width: 10),
                _Option(
                  label: 'Facebook',
                  color: FanZoneColors.blue,
                  icon: Icons.facebook_rounded,
                  onTap: () => _open(context, Uri.parse('https://www.facebook.com/sharer/sharer.php?u=$link')),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _Option(
                  label: 'SMS',
                  color: FanZoneColors.flare,
                  icon: Icons.sms_rounded,
                  onTap: () => _open(context, Uri.parse('sms:?&body=$enc')),
                ),
                const SizedBox(width: 10),
                _Option(
                  label: 'X',
                  color: FanZoneColors.ink,
                  glyph: 'X',
                  onTap: () => _open(context, Uri.parse('https://x.com/intent/post?text=$teaser&url=$link')),
                ),
                const SizedBox(width: 10),
                _Option(
                  label: 'Copier',
                  color: FanZoneColors.cement,
                  icon: Icons.link_rounded,
                  onTap: () => _copy(context),
                ),
              ],
            ),
            if (nativeShareAvailable) ...[
              const SizedBox(height: 6),
              TextButton.icon(
                onPressed: () => _native(context),
                icon: const Icon(Icons.ios_share_rounded, size: 18, color: FanZoneColors.ink),
                label: Text('Autres applis', style: fz(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  final IconData? icon;
  final String? glyph;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _Option({required this.label, required this.color, required this.onTap, this.icon, this.glyph});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Pressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: FanZoneColors.paper,
            borderRadius: BorderRadius.circular(18),
            boxShadow: FanZoneColors.lift,
          ),
          child: Column(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: icon != null
                    ? Icon(icon, color: Colors.white, size: 22)
                    : Text(glyph ?? '', style: fz(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
              const SizedBox(height: 6),
              Text(label, style: fz(fontSize: 13, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}
