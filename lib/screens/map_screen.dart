import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:geolocator/geolocator.dart';
import '../models/event.dart';
import '../theme/app_theme.dart';
import '../widgets/sticker.dart';
import 'event_detail_screen.dart';

class MapScreen extends StatefulWidget {
  final List<FanZoneEvent> events;
  final Function(int) onToggleJoin;

  const MapScreen({
    super.key,
    required this.events,
    required this.onToggleJoin,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  LatLng _center = const LatLng(48.8566, 2.3522); // Paris par défaut
  LatLng? _userPos;
  bool _locating = false;
  FanZoneEvent? _selectedEvent;

  // ── Géolocalisation ──────────────────────────────────────────
  Future<void> _locateUser() async {
    setState(() => _locating = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        _showSnack('Permission refusée, Paris par défaut');
        setState(() => _locating = false);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );

      setState(() {
        _userPos = LatLng(pos.latitude, pos.longitude);
        _center  = _userPos!;
        _locating = false;
      });

      _mapController.move(_userPos!, 13);
      _showSnack('Position trouvée!');
    } catch (_) {
      setState(() => _locating = false);
      _showSnack('Impossible de te localiser');
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: fz(fontWeight: FontWeight.w600)),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      backgroundColor: FanZoneColors.dark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FanZoneColors.background,
      body: Stack(
        children: [
          // ── CARTE ──
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 12,
              onTap: (_, __) => setState(() => _selectedEvent = null),
            ),
            children: [
              // Tuiles OpenStreetMap, thème sombre Carto
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.fanzone.app',
              ),

              // ── Pins des events ──
              MarkerLayer(
                markers: [
                  // Pin position utilisateur
                  if (_userPos != null)
                    Marker(
                      point: _userPos!,
                      width: 24,
                      height: 24,
                      child: _UserPin(),
                    ),

                  // Pins des events
                  ...widget.events.map((ev) => Marker(
                    point: LatLng(ev.lat, ev.lng),
                    width: 120,
                    height: 50,
                    alignment: Alignment.topCenter,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedEvent = ev),
                      child: _EventPin(event: ev),
                    ),
                  )),
                ],
              ),
            ],
          ),

          // ── OVERLAY HAUT : titre + compteur ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 12,
            child: _MapBadge(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${widget.events.length}',
                    style: fzDisplay(fontSize: 23,
                      color: FanZoneColors.primary,
                      height: 1),
                  ),
                  Text(
                    'events\nnear de toi',
                    style: fz(fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: FanZoneColors.textSecondary,
                      height: 1.2),
                  ),
                ],
              ),
            ),
          ),

          // ── BOUTON GÉOLOCALISATION ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 12,
            child: GestureDetector(
              onTap: _locating ? null : _locateUser,
              child: _MapBadge(
                child: _locating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: FanZoneColors.primary,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.my_location,
                            size: 18,
                            color: _userPos != null
                                ? FanZoneColors.primary
                                : FanZoneColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _userPos != null ? 'Localisé' : 'Me localiser',
                            style: fz(fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _userPos != null
                                  ? FanZoneColors.primary
                                  : FanZoneColors.textPrimary),
                          ),
                        ],
                      ),
              ),
            ),
          ),

          // ── POPUP EVENT SÉLECTIONNÉ ──
          if (_selectedEvent != null)
            Positioned(
              bottom: 170,
              left: 12,
              right: 12,
              child: _EventPopup(
                event: _selectedEvent!,
                onClose: () => setState(() => _selectedEvent = null),
                onDetail: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EventDetailScreen(
                        event: _selectedEvent!,
                        onToggleJoin: () =>
                            widget.onToggleJoin(_selectedEvent!.id),
                      ),
                    ),
                  );
                },
                onJoin: () {
                  widget.onToggleJoin(_selectedEvent!.id);
                  setState(() {});
                },
              ),
            ),

          // ── STRIP BAS : events défilants ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _BottomStrip(
              events: widget.events,
              onTap: (ev) {
                setState(() => _selectedEvent = ev);
                _mapController.move(LatLng(ev.lat, ev.lng), 14);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── USER PIN ─────────────────────────────────────────────────────
class _UserPin extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: FanZoneColors.primary.withValues(alpha:0.2),
        border: Border.all(color: FanZoneColors.primary, width: 1.5),
      ),
      child: Center(
        child: Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: FanZoneColors.primary,
          ),
        ),
      ),
    );
  }
}

// ── EVENT PIN ─────────────────────────────────────────────────────
class _EventPin extends StatelessWidget {
  final FanZoneEvent event;
  const _EventPin({required this.event});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: event.color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: event.joined ? Colors.white : Colors.white.withValues(alpha:0.3),
              width: event.joined ? 2.5 : 1.5,
            )
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(Monogram.initials(event.club), style: fzDisplay(fontSize: 12, color: Colors.white)),
              const SizedBox(width: 4),
              Text(
                event.club.split('').last,
                style: fz(fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
              ),
              if (event.joined) ...[
                const SizedBox(width: 4),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF4ADE80),
                  ),
                ),
              ],
            ],
          ),
        ),
        // Queue du pin
        CustomPaint(
          size: const Size(10, 6),
          painter: _PinTailPainter(color: event.color),
        ),
      ],
    );
  }
}

class _PinTailPainter extends CustomPainter {
  final Color color;
  const _PinTailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── MAP BADGE (fond blanc arrondi) ───────────────────────────────
class _MapBadge extends StatelessWidget {
  final Widget child;
  const _MapBadge({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: FanZoneColors.dark, width: 1.5)
      ),
      child: child,
    );
  }
}

// ── EVENT POPUP ──────────────────────────────────────────────────
class _EventPopup extends StatelessWidget {
  final FanZoneEvent event;
  final VoidCallback onClose;
  final VoidCallback onDetail;
  final VoidCallback onJoin;

  const _EventPopup({
    required this.event,
    required this.onClose,
    required this.onDetail,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: FanZoneColors.dark, width: 1.5)
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bande couleur
          Container(
            height: 5,
            decoration: BoxDecoration(
              color: event.color,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      event.club,
                      style: fz(fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: FanZoneColors.textLight),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: onClose,
                      child: const Icon(Icons.close, size: 18, color: FanZoneColors.textLight),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  event.match,
                  style: fzDisplay(fontSize: 19,
                    color: FanZoneColors.dark),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Text('', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(
                      '${event.dateFormatted}, ${event.time}',
                      style: fz(fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: FanZoneColors.textSecondary),
                    ),
                    const SizedBox(width: 8),
                    const Text('', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event.address,
                        style: fz(fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: FanZoneColors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Voir la fiche
                    Expanded(
                      child: GestureDetector(
                        onTap: onDetail,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: FanZoneColors.cream,
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(color: FanZoneColors.border, width: 1.5),
                          ),
                          child: Center(
                            child: Text(
                              'Voir la fiche →',
                              style: fz(fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: FanZoneColors.dark),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Rejoindre
                    Expanded(
                      child: GestureDetector(
                        onTap: onJoin,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: event.joined
                                ? FanZoneColors.successBg
                                : FanZoneColors.dark,
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(
                              color: event.joined
                                  ? FanZoneColors.success
                                  : FanZoneColors.dark,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              event.joined ? 'Je viens!' : 'Je viens',
                              style: fz(fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: event.joined
                                    ? FanZoneColors.success
                                    : Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── BOTTOM STRIP ─────────────────────────────────────────────────
class _BottomStrip extends StatelessWidget {
  final List<FanZoneEvent> events;
  final Function(FanZoneEvent) onTap;

  const _BottomStrip({required this.events, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sorted = [...events]..sort((a, b) => a.date.compareTo(b.date));
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, FanZoneColors.background.withValues(alpha:0.95)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 12),
      child: SizedBox(
        height: 120,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: sorted.length,
          itemBuilder: (_, i) {
            final ev = sorted[i];
            return GestureDetector(
              onTap: () => onTap(ev),
              child: Container(
                width: 150,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: FanZoneColors.dark, width: 1.5)
                ),
                child: Column(
                  children: [
                    Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: ev.color,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(3)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(9),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ev.club,
                            style: fz(fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: FanZoneColors.textLight),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            ev.match,
                            style: fz(fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: FanZoneColors.dark,
                              height: 1.15),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                ev.dateFormatted,
                                style: fz(fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: FanZoneColors.textLight),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: ev.vibeBgColor,
                                  borderRadius: BorderRadius.circular(3),
                                  border: Border.all(
                                      color: ev.vibeColor, width: 1.5),
                                ),
                                child: Text(
                                  ev.daysUntil,
                                  style: fz(fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: ev.vibeColor),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}