import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/sticker.dart';
import 'event_detail_screen.dart';

/// Centre d'alertes in-app : nouveaux events des clubs suivis, rappels J-1.
/// (Les notifications push viendront avec le backend.)
class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppScope.read(context).markAllAlertsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final alerts = [...state.alerts]..sort((a, b) => b.date.compareTo(a.date));
    final followed = state.clubs.where((c) => state.isFollowing(c.id)).toList();

    return Scaffold(
      backgroundColor: FanZoneColors.background,
      appBar: AppBar(title: const Text('🔔 Alertes')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          StickerBlock(
            color: FanZoneColors.warningBg,
            borderColor: FanZoneColors.yellow,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tu es alerté pour :', style: TextStyle(fontFamily: 'Nunito', fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFFB8860B), letterSpacing: 1)),
                const SizedBox(height: 6),
                Text(
                  followed.isEmpty
                      ? 'Aucun club suivi pour l\'instant. Suis un club depuis l\'accueil pour recevoir ses nouveaux events.'
                      : followed.map((c) => '${c.emoji} ${c.name}').join(' · '),
                  style: const TextStyle(fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w800, color: FanZoneColors.dark, height: 1.5),
                ),
                const SizedBox(height: 4),
                const Text('+ un rappel la veille de chaque event que tu as rejoint.',
                    style: TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w600, color: FanZoneColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (alerts.isEmpty)
            const EmptyHint(emoji: '📭', text: 'Rien pour l\'instant. Rejoins un event ou suis un club, et ça va vibrer ici.'),
          ...alerts.map((a) {
            final ev = a.eventId == null ? null : state.eventById(a.eventId!);
            return GestureDetector(
              onTap: ev == null
                  ? null
                  : () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => EventDetailScreen(event: ev, onToggleJoin: () => state.toggleJoinEvent(ev.id))),
                      ),
              child: StickerBlock(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                borderColor: ev?.color ?? FanZoneColors.dark,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.emoji, style: const TextStyle(fontSize: 26)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.title, style: const TextStyle(fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.w900, color: FanZoneColors.dark)),
                          const SizedBox(height: 2),
                          Text(a.body, style: const TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w600, color: FanZoneColors.textSecondary, height: 1.4)),
                          const SizedBox(height: 4),
                          Text(_ago(a.date), style: const TextStyle(fontFamily: 'Nunito', fontSize: 10, fontWeight: FontWeight.w700, color: FanZoneColors.textLight)),
                        ],
                      ),
                    ),
                    if (ev != null) const Text('→', style: TextStyle(fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.w900, color: FanZoneColors.textLight)),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _ago(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'à l\'instant';
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
    return 'il y a ${diff.inDays} j';
  }
}
