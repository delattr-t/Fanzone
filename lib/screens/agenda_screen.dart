import 'package:flutter/material.dart';

import '../models/event.dart';
import '../theme/app_theme.dart';
import '../widgets/event_card.dart';
import '../widgets/sticker.dart';
import 'event_detail_screen.dart';

class AgendaScreen extends StatefulWidget {
  final List<FanZoneEvent> events;
  final Function(int) onToggleJoin;

  const AgendaScreen({super.key, required this.events, required this.onToggleJoin});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  late DateTime _month;

  static const _months = [
    'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
  ];
  static const _days = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  String _iso(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  List<FanZoneEvent> _eventsOn(DateTime day) {
    final s = _iso(day);
    return widget.events.where((e) => e.date == s).toList();
  }

  List<FanZoneEvent> _eventsInMonth() {
    final prefix = '${_month.year}-${_month.month.toString().padLeft(2, '0')}';
    final list = widget.events.where((e) => e.date.startsWith(prefix)).toList();
    list.sort((a, b) => DateTime.parse(a.date).compareTo(DateTime.parse(b.date)));
    return list;
  }

  void _open(FanZoneEvent ev) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventDetailScreen(
          event: ev,
          onToggleJoin: () => widget.onToggleJoin(ev.id),
        ),
      ),
    );
  }

  void _shift(int delta) => setState(() => _month = DateTime(_month.year, _month.month + delta));

  @override
  Widget build(BuildContext context) {
    final monthEvents = _eventsInMonth();
    final first = DateTime(_month.year, _month.month, 1);
    final last = DateTime(_month.year, _month.month + 1, 0);
    final offset = (first.weekday - 1) % 7;
    final today = DateTime.now();

    return Scaffold(
      backgroundColor: FanZoneColors.paper,
      appBar: AppBar(title: const Text('Agenda'), automaticallyImplyLeading: false),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_months[_month.month - 1]} ${_month.year}',
                  style: fzDisplay(fontSize: 34, fontWeight: FontWeight.w800),
                ),
              ),
              _NavBtn(icon: Icons.chevron_left, onTap: () => _shift(-1)),
              const SizedBox(width: 6),
              _NavBtn(icon: Icons.chevron_right, onTap: () => _shift(1)),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1.5, color: FanZoneColors.ink),
          const SizedBox(height: 8),
          Row(
            children: _days
                .map((d) => Expanded(
                      child: Center(
                        child: Text(d, style: fz(fontSize: 12, fontWeight: FontWeight.w600, color: FanZoneColors.cement)),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 6),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: offset + last.day,
            itemBuilder: (_, i) {
              if (i < offset) return const SizedBox.shrink();
              final day = DateTime(_month.year, _month.month, i - offset + 1);
              final evs = _eventsOn(day);
              final hasEv = evs.isNotEmpty;
              final isToday = day.year == today.year && day.month == today.month && day.day == today.day;
              return GestureDetector(
                onTap: hasEv ? () => _open(evs.first) : null,
                child: Container(
                  decoration: BoxDecoration(
                    color: hasEv ? FanZoneColors.ink : (isToday ? FanZoneColors.hiVis : Colors.transparent),
                    borderRadius: BorderRadius.circular(3),
                    border: isToday && !hasEv ? Border.all(color: FanZoneColors.ink, width: 1.5) : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${day.day}',
                        style: fzDisplay(
                          fontSize: 18,
                          color: hasEv ? Colors.white : (isToday ? FanZoneColors.ink : FanZoneColors.cement),
                        ),
                      ),
                      if (hasEv)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: evs
                              .take(3)
                              .map((e) => Container(
                                    width: 5,
                                    height: 5,
                                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                    color: e.color == FanZoneColors.ink ? FanZoneColors.hiVis : e.color,
                                  ))
                              .toList(),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          SectionTitle(monthEvents.isEmpty
              ? 'Rien ce mois-ci'
              : '${monthEvents.length} match${monthEvents.length > 1 ? 's' : ''} ce mois-ci'),
          const SizedBox(height: 12),
          if (monthEvents.isEmpty)
            const EmptyHint(text: 'Aucun match annoncé ce mois-ci. Change de mois ou publie le tien depuis l\'accueil.'),
          ...monthEvents.map((ev) => EventCard(
                event: ev,
                onTap: () => _open(ev),
                onJoin: () => widget.onToggleJoin(ev.id),
              )),
        ],
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: FanZoneColors.ink, width: 1.5),
        ),
        child: Icon(icon, size: 22, color: FanZoneColors.ink),
      ),
    );
  }
}
