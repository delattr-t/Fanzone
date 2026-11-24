import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/local_store.dart';
import 'screens/agenda_screen.dart';
import 'screens/collectifs_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/map_screen.dart';
import 'screens/profile_screen.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'widgets/sticker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  final state = AppState(LocalStore());
  await state.load();
  runApp(FanZoneApp(state: state));
}

class FanZoneApp extends StatelessWidget {
  final AppState state;
  const FanZoneApp({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: MaterialApp(
        title: 'FanZone',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        locale: const Locale('fr', 'FR'),
        supportedLocales: const [Locale('fr', 'FR'), Locale('en', 'US')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const _AuthGate(),
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    if (!state.loaded) return const _SplashScreen();
    return state.isLoggedIn ? const MainShell() : const LoginScreen();
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: FanZoneColors.dark,
      body: Center(child: Text('🏟️', style: TextStyle(fontSize: 64))),
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

  Future<void> _toggleJoin(int eventId) async {
    final state = AppScope.read(context);
    final ev = state.eventById(eventId);
    if (ev == null) return;
    final willJoin = !ev.joined;
    await state.toggleJoinEvent(eventId);
    if (mounted) {
      showFanToast(context, willJoin ? "🎉 Tu rejoins l'event !" : "Tu as quitté l'event");
    }
  }

  Future<void> _toggleCollectif(String collectifId) async {
    final state = AppScope.read(context);
    final col = state.collectifById(collectifId);
    if (col == null) return;
    final willJoin = !col.joined;
    await state.toggleJoinCollectif(collectifId);
    if (mounted) {
      showFanToast(context, willJoin ? '🎊 Tu rejoins ${col.name} !' : 'Tu as quitté le collectif');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final events = state.events;
    final collectifs = state.collectifs;

    final screens = [
      HomeScreen(events: events, onToggleJoin: _toggleJoin),
      MapScreen(events: events, onToggleJoin: _toggleJoin),
      AgendaScreen(events: events, onToggleJoin: _toggleJoin),
      CollectifsScreen(collectifs: collectifs, onToggle: _toggleCollectif),
      ProfileScreen(
        userName: state.userName,
        events: events,
        collectifs: collectifs,
        onToggleJoin: _toggleJoin,
        onNameChanged: (name) => state.updateName(name),
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
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

  const _FanZoneBottomNav({required this.currentIndex, required this.onTap});

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
                      Text(item['icon']!, style: TextStyle(fontSize: active ? 22 : 20)),
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
