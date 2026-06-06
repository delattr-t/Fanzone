import 'package:flutter/material.dart';
import '../models/event.dart';
import '../theme/app_theme.dart';
import '../widgets/event_card.dart';
import 'event_detail_screen.dart';

class AgendaScreen extends StatefulWidget {
  final List<FanZoneEvent> events;
  final Function(int) onToggleJoin;

  const AgendaScreen({super.key, required this.events, required this.onToggleJoin});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  DateTime _month = DateTime(2026, 5);

  List<DateTime> _calDays() {
    final first = DateTime(_month.year, _month.month, 1);
    final last = DateTime(_month.year, _month.month + 1, 0);
    // Mon=1 → offset so week starts Monday
    final offset = (first.weekday - 1) % 7;
    final days = <DateTime?>[];
    for (int i = 0; i < offset; i++) days.add(null);
    for (int d = 1; d <= last.day; d++) {
      days.add(DateTime(_month.year, _month.month, d));
    }
    return days.whereType<DateTime>().toList();
  }

  List<FanZoneEvent> _eventsFor(DateTime day) {
    final s = '${day.year}-${day.month.toString().padLeft(2,'0')}-${day.day.toString().padLeft(2,'0')}';
    return widget.events.where((e) => e.date == s).toList();
  }

  Map<String, List<FanZoneEvent>> _grouped() {
    final sorted = [...widget.events]..sort((a, b) => a.date.compareTo(b.date));
    final m = <String, List<FanZoneEvent>>{};
    for (final e in sorted) {
      final k = e.date.substring(0, 7);
      m.putIfAbsent(k, () => []).add(e);
    }
    return m;
  }

  static const _months = ['Jan','Fév','Mar','Avr','Mai','Jun','Jul','Aoû','Sep','Oct','Nov','Déc'];
  static const _days   = ['L','M','M','J','V','S','D'];

  @override
  Widget build(BuildContext context) {
    final calDays = _calDays();
    final groups  = _grouped();

    return Scaffold(
      backgroundColor: FanZoneColors.background,
      appBar: AppBar(
        title: const Text('📅 Agenda'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        children: [
          // ── MONTH NAV ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _NavBtn(
                  icon: '‹',
                  onTap: () => setState(() =>
                    _month = DateTime(_month.year, _month.month - 1)),
                ),
                Text(
                  '${_months[_month.month - 1]} ${_month.year}',
                  style: const TextStyle(
                    fontFamily: 'Nunito', fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: FanZoneColors.dark,
                  ),
                ),
                _NavBtn(
                  icon: '›',
                  onTap: () => setState(() =>
                    _month = DateTime(_month.year, _month.month + 1)),
                ),
              ],
            ),
          ),

          // ── CALENDRIER ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              children: [
                // Jours de la semaine
                Row(
                  children: _days.map((d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: const TextStyle(
                          fontFamily: 'Nunito', fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: FanZoneColors.textLight,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 4),
                // Grille
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 1,
                    mainAxisSpacing: 3,
                    crossAxisSpacing: 3,
                  ),
                  itemCount: (() {
                    final first = DateTime(_month.year, _month.month, 1);
                    final last  = DateTime(_month.year, _month.month + 1, 0);
                    final offset = (first.weekday - 1) % 7;
                    return offset + last.day;
                  })(),
                  itemBuilder: (_, i) {
                    final first  = DateTime(_month.year, _month.month, 1);
                    final offset = (first.weekday - 1) % 7;
                    if (i < offset) return const SizedBox.shrink();
                    final day = DateTime(_month.year, _month.month, i - offset + 1);
                    final evs = _eventsFor(day);
                    final hasEv = evs.isNotEmpty;
                    final isToday = day.year == DateTime.now().year &&
                        day.month == DateTime.now().month &&
                        day.day == DateTime.now().day;
                    return GestureDetector(
                      onTap: hasEv ? () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => EventDetailScreen(
                            event: evs.first,
                            onToggleJoin: () => widget.onToggleJoin(evs.first.id),
                          ),
                        ));
                      } : null,
                      child: Container(
                        decoration: BoxDecoration(
                          color: hasEv ? FanZoneColors.surface : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: hasEv
                              ? Border.all(color: FanZoneColors.dark, width: 2)
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${day.day}',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isToday
                                    ? FanZoneColors.primary
                                    : hasEv
                                        ? FanZoneColors.dark
                                        : FanZoneColors.textLight,
                              ),
                            ),
                            if (hasEv)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: evs.take(3).map((e) => Container(
                                  width: 4, height: 4,
                                  margin: const EdgeInsets.symmetric(horizontal: 1),
                                  decoration: BoxDecoration(
                                    color: e.color,
                                    shape: BoxShape.circle,
                                  ),
                                )).toList(),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // ── LISTE GROUPÉE ──
          ...groups.entries.map((entry) {
            final parts  = entry.key.split('-');
            final mLabel = '${_months[int.parse(parts[1]) - 1].toUpperCase()} ${parts[0]}';
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: FanZoneColors.yellow,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: FanZoneColors.dark, width: 2.5),
                    ),
                    child: Text(
                      '$mLabel 🗓️',
                      style: const TextStyle(
                        fontFamily: 'Nunito', fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: FanZoneColors.dark,
                      ),
                    ),
                  ),
                ),
                ...entry.value.map((ev) => EventCard(
                  event: ev,
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => EventDetailScreen(
                      event: ev,
                      onToggleJoin: () => widget.onToggleJoin(ev.id),
                    ),
                  )),
                  onJoin: () => widget.onToggleJoin(ev.id),
                )),
              ],
            );
          }),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final String icon;
  final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: FanZoneColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: FanZoneColors.dark, width: 2),
          boxShadow: [BoxShadow(color: FanZoneColors.dark.withValues(alpha: 0.15), offset: const Offset(2,2))],
        ),
        child: Center(
          child: Text(icon, style: const TextStyle(fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.w900)),
        ),
      ),
    );
  }
}
