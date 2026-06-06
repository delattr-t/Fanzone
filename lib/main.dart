import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'models/event.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/agenda_screen.dart';
import 'screens/collectifs_screen.dart';
import 'screens/map_screen.dart';
import 'screens/profile_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const FanZoneApp());
}

class FanZoneApp extends StatelessWidget {
  const FanZoneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FanZone',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const MainShell(),
    );
  }
}

// ── SHELL principal avec navigation ──────────────────────────────
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  String _userName = 'Fan';

  // Copies indépendantes pour ne pas muter les listes sources
  final List<FanZoneEvent> _events = List.from(sampleEvents);
  final List<Collectif> _collectifs = List.from(sampleCollectifs);

  void _toggleJoin(int eventId) {
    setState(() {
      final ev = _events.firstWhere((e) => e.id == eventId);
      ev.joined = !ev.joined;
      ev.supporters += ev.joined ? 1 : -1;
    });

    final ev = _events.firstWhere((e) => e.id == eventId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ev.joined ? '🎉 Tu rejoins l\'event !' : 'Tu as quitté l\'event',
          style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 14),
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: FanZoneColors.dark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _toggleCollectif(String collectifId) {
    setState(() {
      final col = _collectifs.firstWhere((c) => c.id == collectifId);
      col.joined = !col.joined;
      col.members += col.joined ? 1 : -1;
    });

    final col = _collectifs.firstWhere((c) => c.id == collectifId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          col.joined ? '🎊 Tu rejoins ${col.name} !' : 'Tu as quitté le collectif',
          style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 14),
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: FanZoneColors.dark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(events: _events, onToggleJoin: _toggleJoin),
      MapScreen(events: _events, onToggleJoin: _toggleJoin),
      AgendaScreen(events: _events, onToggleJoin: _toggleJoin),
      CollectifsScreen(
        collectifs: _collectifs,
        onToggle: _toggleCollectif,
      ),
      ProfileScreen(
        userName: _userName,
        events: _events,
        collectifs: _collectifs,
        onToggleJoin: _toggleJoin,
        onNameChanged: (name) => setState(() => _userName = name),
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: _FanZoneBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ── BOTTOM NAV personnalisée ─────────────────────────────────────
class _FanZoneBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const _FanZoneBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    {'icon': '🏠', 'label': 'Accueil'},
    {'icon': '🗺️', 'label': 'Carte'},
    {'icon': '📅', 'label': 'Agenda'},
    {'icon': '🎊', 'label': 'Collectifs'},
    {'icon': '👤', 'label': 'Profil'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: FanZoneColors.surface,
        border: Border(top: BorderSide(color: FanZoneColors.dark, width: 3)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(_items.length, (i) {
              final item   = _items[i];
              final active = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item['icon']!,
                        style: TextStyle(fontSize: active ? 22 : 20),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item['label']!,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: active ? FanZoneColors.primary : FanZoneColors.textLight,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: active ? 20 : 0,
                        height: active ? 3 : 0,
                        decoration: BoxDecoration(
                          color: FanZoneColors.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
