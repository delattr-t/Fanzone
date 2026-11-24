import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';
import 'data/local_repository.dart';
import 'data/local_store.dart';
import 'data/repository.dart';
import 'data/supabase_repository.dart';
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
  FanZoneRepository repo;
  if (AppConfig.useSupabase) {
    await Supabase.initialize(url: AppConfig.supabaseUrl, anonKey: AppConfig.supabaseKey);
    repo = SupabaseRepository();
  } else {
    repo = LocalRepository(LocalStore());
  }
  final state = AppState(repo);
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
      backgroundColor: FanZoneColors.ink,
      body: Center(child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(color: FanZoneColors.hiVis, strokeWidth: 2))),
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
  String? _shownError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final err = AppScope.of(context).lastError;
    if (err != null && err != _shownError) {
      _shownError = err;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showFanToast(context, err);
      });
    }
  }

  Future<void> _toggleJoin(int eventId) async {
    final state = AppScope.read(context);
    final ev = state.eventById(eventId);
    if (ev == null) return;
    final willJoin = !ev.joined;
    await state.toggleJoinEvent(eventId);
    if (mounted) {
      showFanToast(context, willJoin ? 'Tu es annoncé. On compte sur toi.' : 'Tu n\'es plus annoncé.');
    }
  }

  Future<void> _toggleCollectif(String collectifId) async {
    final state = AppScope.read(context);
    final col = state.collectifById(collectifId);
    if (col == null) return;
    final willJoin = !col.joined;
    await state.toggleJoinCollectif(collectifId);
    if (mounted) {
      showFanToast(context, willJoin ? 'Bienvenue chez ${col.name}.' : 'Tu as quitté ${col.name}.');
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

// ── BOTTOM NAV : libellés en lettres d'affiche, trait fluo sous l'actif ──
class _FanZoneBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const _FanZoneBottomNav({required this.currentIndex, required this.onTap});

  static const _items = [
    (Icons.home_outlined, Icons.home, 'Accueil'),
    (Icons.map_outlined, Icons.map, 'Carte'),
    (Icons.calendar_today_outlined, Icons.calendar_today, 'Agenda'),
    (Icons.groups_outlined, Icons.groups, 'Collectifs'),
    (Icons.person_outline, Icons.person, 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: FanZoneColors.paper,
        border: Border(top: BorderSide(color: FanZoneColors.ink, width: 2)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final active = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(active ? item.$2 : item.$1, size: 22, color: FanZoneColors.ink),
                      const SizedBox(height: 3),
                      Text(
                        item.$3,
                        style: fzDisplay(fontSize: 14, fontWeight: active ? FontWeight.w700 : FontWeight.w500),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        width: 26,
                        height: 3,
                        color: active ? FanZoneColors.hiVis : Colors.transparent,
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
