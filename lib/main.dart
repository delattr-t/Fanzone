import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  fanZoneType.value = await _initialTypography();
  await loadTypography(fanZoneType.value);
  final state = AppState(repo);
  await state.load();
  runApp(FanZoneApp(state: state));
}

Future<FanZoneType> _initialTypography() async {
  final fromUrl = Uri.base.queryParameters['typo'];
  final prefs = await SharedPreferences.getInstance();
  if (fromUrl != null) {
    final t = (fromUrl == 'gazette' || fromUrl == '2') ? FanZoneType.gazette : FanZoneType.echarpe;
    await prefs.setString(typoPrefKey, t.name);
    return t;
  }
  return prefs.getString(typoPrefKey) == FanZoneType.gazette.name ? FanZoneType.gazette : FanZoneType.echarpe;
}


class FanZoneApp extends StatelessWidget {
  final AppState state;
  const FanZoneApp({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: ValueListenableBuilder<FanZoneType>(
        valueListenable: fanZoneType,
        builder: (_, type, __) => KeyedSubtree(
          key: ValueKey(type),
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
        ),
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
    (Icons.home_outlined, Icons.home_rounded, 'Accueil'),
    (Icons.map_outlined, Icons.map_rounded, 'Carte'),
    (Icons.calendar_month_outlined, Icons.calendar_month_rounded, 'Agenda'),
    (Icons.groups_outlined, Icons.groups_rounded, 'Collectifs'),
    (Icons.person_outline_rounded, Icons.person_rounded, 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: FanZoneColors.paper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Color(0x1A5A3418), blurRadius: 20, offset: Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
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
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        width: active ? 54 : 40,
                        height: 30,
                        decoration: BoxDecoration(
                          color: active ? FanZoneColors.hiVis : Colors.transparent,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Icon(active ? item.$2 : item.$1, size: 22,
                            color: active ? FanZoneColors.ink : FanZoneColors.cement),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.$3,
                        style: fz(
                          fontSize: 12,
                          fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                          color: active ? FanZoneColors.ink : FanZoneColors.cement,
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
