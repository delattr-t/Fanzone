import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../models/event.dart';
import '../theme/app_theme.dart';
import 'scarf.dart';
import 'sticker.dart';

/// Lien direct vers la fiche d'un match, ouvrable depuis n'importe quel téléphone.
String matchLink(FanZoneEvent e) => '${AppConfig.shareBaseUrl}#/match/${e.id}';

/// Le message envoyé aux potes : quoi, quand, où, et le lien.
String matchInvite(FanZoneEvent e) {
  final when = _when(e);
  return '${e.match}, $when, ${e.venue}. '
      '${e.supporters > 0 ? '${e.supporters} supporters déjà annoncés. ' : ''}'
      'On y va ensemble ?\n${matchLink(e)}';
}

/// Lit `#/match/<id>` dans une adresse ; `null` si ce n'est pas un lien de match.
int? matchIdFromUri(Uri uri) {
  final m = RegExp(r'^/?match/(\d+)').firstMatch(uri.fragment);
  return m == null ? null : int.tryParse(m.group(1)!);
}

String _when(FanZoneEvent e) {
  try {
    final d = DateTime.parse(e.date);
    const days = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'];
    const months = ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'];
    final p = e.time.split(':');
    final hour = p.length < 2 ? e.time : (p[1] == '00' ? '${p[0]} h' : '${p[0]} h ${p[1]}');
    return '${days[d.weekday - 1]} ${d.day} ${months[d.month - 1]} à $hour';
  } catch (_) {
    return '${e.date} à ${e.time}';
  }
}

/// Panneau « Inviter des potes » : aperçu du message, puis WhatsApp, SMS ou copie.
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
    if (!ok && context.mounted) await _copy(context);
    if (ok && context.mounted) Navigator.pop(context);
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: matchInvite(event)));
    if (!context.mounted) return;
    Navigator.pop(context);
    showFanToast(context, 'Message copié. Colle-le où tu veux.');
  }

  @override
  Widget build(BuildContext context) {
    final text = matchInvite(event);
    final enc = Uri.encodeComponent(text);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
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
              'Ils recevront ce message, avec un lien qui ouvre directement la fiche du match.',
              style: fz(fontSize: 14, color: FanZoneColors.cement, height: 1.4),
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 18),
            Row(
              children: [
                _Option(
                  icon: Icons.chat_rounded,
                  label: 'WhatsApp',
                  color: const Color(0xFF1F7A4D),
                  onTap: () => _open(context, Uri.parse('https://wa.me/?text=$enc')),
                ),
                const SizedBox(width: 10),
                _Option(
                  icon: Icons.sms_rounded,
                  label: 'SMS',
                  color: FanZoneColors.flare,
                  onTap: () => _open(context, Uri.parse('sms:?&body=$enc')),
                ),
                const SizedBox(width: 10),
                _Option(
                  icon: Icons.link_rounded,
                  label: 'Copier',
                  color: FanZoneColors.ink,
                  onTap: () => _copy(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _Option({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Pressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: FanZoneColors.paper,
            borderRadius: BorderRadius.circular(18),
            boxShadow: FanZoneColors.lift,
          ),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 8),
              Text(label, style: fz(fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}
