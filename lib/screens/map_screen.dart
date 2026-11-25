import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../models/event.dart';
import '../theme/app_theme.dart';
import '../widgets/scarf.dart';
import '../widgets/sticker.dart';
import 'event_detail_screen.dart';

/// Teinte « laine » appliquée aux tuiles OpenStreetMap : on garde 30 % des
/// couleurs d'origine et on réchauffe le reste vers le fond de l'app.
const _woolTint = ColorFilter.matrix(<double>[
  0.5027, 0.3986, 0.0743, 0, 0,
  0.1953, 0.6841, 0.0716, 0, 0,
  0.1848, 0.3634, 0.3678, 0, 0,
  0, 0, 0, 1, 0,
]);

class MapScreen extends StatefulWidget {
  final List<FanZoneEvent> events;
  final Function(int) onToggleJoin;

  const MapScreen({super.key, required this.events, required this.onToggleJoin});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _map = MapController();
  final _cards = ScrollController();
  static const _paris = LatLng(48.8666, 2.4000);
  static const _cardWidth = 284.0;
  LatLng? _userPos;
  bool _locating = false;
  int? _selectedId;

  List<FanZoneEvent> get _upcoming {
    final list = widget.events.where((e) => !e.isPast).toList()
      ..sort((a, b) => DateTime.parse(a.date).compareTo(DateTime.parse(b.date)));
    return list;
  }

  @override
  void dispose() {
    _cards.dispose();
    super.dispose();
  }

  void _select(FanZoneEvent ev, {bool scrollCards = true}) {
    setState(() => _selectedId = ev.id);
    _map.move(LatLng(ev.lat, ev.lng), 13.5);
    if (scrollCards) {
      final i = _upcoming.indexWhere((e) => e.id == ev.id);
      if (i >= 0 && _cards.hasClients) {
        _cards.animateTo(
          (i * (_cardWidth + 12)).clamp(0, _cards.position.maxScrollExtent),
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  void _open(FanZoneEvent ev) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventDetailScreen(event: ev, onToggleJoin: () => widget.onToggleJoin(ev.id)),
      ),
    );
  }

  Future<void> _locate() async {
    setState(() => _locating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (mounted) showFanToast(context, 'Localisation refusée. La carte reste centrée sur Paris.');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 8)),
      );
      final here = LatLng(pos.latitude, pos.longitude);
      setState(() => _userPos = here);
      _map.move(here, 13);
    } catch (_) {
      if (mounted) showFanToast(context, 'Impossible de te localiser pour le moment.');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final events = _upcoming;
    final top = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: FanZoneColors.wool,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: _paris,
              initialZoom: 11.6,
              minZoom: 9,
              maxZoom: 18,
              backgroundColor: FanZoneColors.wool,
              onTap: (_, __) => setState(() => _selectedId = null),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'fr.fanzone.app',
                maxNativeZoom: 19,
                tileBuilder: (context, tile, _) => ColorFiltered(colorFilter: _woolTint, child: tile),
              ),
              MarkerLayer(
                markers: [
                  if (_userPos != null)
                    Marker(point: _userPos!, width: 26, height: 26, child: const _UserDot()),
                  ...events.map((ev) {
                    final selected = ev.id == _selectedId;
                    return Marker(
                      point: LatLng(ev.lat, ev.lng),
                      width: 92,
                      height: 92,
                      alignment: Alignment.topCenter,
                      child: GestureDetector(
                        onTap: () => _select(ev),
                        child: _ClubPin(event: ev, selected: selected),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
          Positioned(
            top: top + 12,
            left: 16,
            right: 16,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      color: FanZoneColors.paper,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: FanZoneColors.lift,
                    ),
                    child: Text.rich(
                      TextSpan(children: [
                        TextSpan(text: '${events.length} matchs', style: fz(fontSize: 15, fontWeight: FontWeight.w800)),
                        TextSpan(text: ' autour de toi', style: fz(fontSize: 15, color: FanZoneColors.cement)),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Pressable(
                  onTap: _locating ? null : _locate,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: FanZoneColors.paper,
                      shape: BoxShape.circle,
                      boxShadow: FanZoneColors.lift,
                    ),
                    child: _locating
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : const Icon(Icons.my_location_rounded, color: FanZoneColors.ink, size: 22),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 12,
            bottom: 194,
            child: Text(
              '© les contributeurs OpenStreetMap',
              style: fz(fontSize: 11, color: FanZoneColors.cement),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 16,
            height: 172,
            child: events.isEmpty
                ? const EmptyHint(text: 'Aucun match à venir pour le moment.')
                : ListView.separated(
                    controller: _cards,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    itemCount: events.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) {
                      final ev = events[i];
                      return _MapCard(
                        event: ev,
                        width: _cardWidth,
                        selected: ev.id == _selectedId,
                        onTap: () => ev.id == _selectedId ? _open(ev) : _select(ev, scrollCards: false),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Épingle : l'écusson du club, et le nombre de supporters annoncés dessous.
class _ClubPin extends StatelessWidget {
  final FanZoneEvent event;
  final bool selected;
  const _ClubPin({required this.event, required this.selected});

  @override
  Widget build(BuildContext context) {
    final size = selected ? 56.0 : 44.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0x335A3418),
                blurRadius: selected ? 16 : 8,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: selected ? FanZoneColors.hiVis : FanZoneColors.paper, width: 3),
          ),
          child: Monogram(name: event.club, color: event.color, size: size - 6),
        ),
        Transform.translate(
          offset: const Offset(0, -8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: selected ? FanZoneColors.hiVis : FanZoneColors.paper,
              borderRadius: BorderRadius.circular(99),
              boxShadow: const [BoxShadow(color: Color(0x225A3418), blurRadius: 4, offset: Offset(0, 1))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.groups_rounded, size: 13, color: FanZoneColors.ink),
                const SizedBox(width: 3),
                Text('${event.supporters}', style: fz(fontSize: 12, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _UserDot extends StatelessWidget {
  const _UserDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: FanZoneColors.flare,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: const [BoxShadow(color: Color(0x40E2462B), blurRadius: 12, spreadRadius: 4)],
      ),
    );
  }
}

class _MapCard extends StatelessWidget {
  final FanZoneEvent event;
  final double width;
  final bool selected;
  final VoidCallback onTap;
  const _MapCard({required this.event, required this.width, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final e = event;
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        decoration: BoxDecoration(
          color: FanZoneColors.paper,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: selected ? FanZoneColors.hiVis : Colors.transparent, width: 3),
          boxShadow: FanZoneColors.lift,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Scarf.club(e.color, height: 10, fringe: false),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${e.dateFormatted}, ${e.time}, ${e.daysUntil}',
                      style: fz(fontSize: 13, fontWeight: FontWeight.w700, color: FanZoneColors.flare),
                    ),
                    const SizedBox(height: 4),
                    Text(e.match, maxLines: 2, overflow: TextOverflow.ellipsis, style: fzDisplay(fontSize: 22, height: 1.1)),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(Icons.place_rounded, size: 16, color: FanZoneColors.cement),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            e.venue,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: fz(fontSize: 13, color: FanZoneColors.cement),
                          ),
                        ),
                        Text(
                          selected ? 'Voir la fiche' : '',
                          style: fz(fontSize: 13, fontWeight: FontWeight.w700, color: FanZoneColors.flare),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
