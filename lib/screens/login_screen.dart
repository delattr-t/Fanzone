import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/scarf.dart';
import '../widgets/sticker.dart';

/// Écran d'entrée : un prénom suffit. Soir de match : fond brun nuit, trois
/// écharpes qui se déroulent.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (_loading) return;
    setState(() => _loading = true);
    final state = AppScope.read(context);
    await state.signIn(_nameCtrl.text);
    if (!mounted) return;
    if (!state.isLoggedIn) {
      setState(() => _loading = false);
      showFanToast(context, state.lastError ?? 'Connexion impossible. Vérifie le réseau et réessaie.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Scaffold(
      backgroundColor: FanZoneColors.night,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(0, 16, 0, 24 + bottomInset),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height - 48 - bottomInset),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const _ScarfBundle(),
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('FanZone', style: fzDisplay(fontSize: 64, color: FanZoneColors.cream, letterSpacing: -1.5)),
                      const SizedBox(height: 6),
                      Text(
                        'Les matchs amateurs près de chez toi, et les gens qui viennent les soutenir.',
                        style: fz(fontSize: 17, color: FanZoneColors.cream.withValues(alpha: 0.78), height: 1.4),
                      ),
                      const SizedBox(height: 32),
                      Text('Ton prénom', style: fz(fontSize: 14, fontWeight: FontWeight.w700, color: FanZoneColors.hiVis)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameCtrl,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _start(),
                        style: fzDisplay(fontSize: 28, height: 1.1),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                          hintText: 'ou ton surnom de tribune',
                          hintStyle: fz(fontSize: 18, color: FanZoneColors.cement),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: const BorderSide(color: FanZoneColors.hiVis, width: 3),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Pressable(
                        onTap: _start,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 17),
                          decoration: BoxDecoration(
                            color: FanZoneColors.flare,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Center(
                            child: _loading
                                ? const SizedBox(
                                    width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Text('Entrer dans la tribune',
                                    style: fz(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Pas de mot de passe, pas d\'e-mail. Ton prénom suffit pour commencer.',
                        style: fz(fontSize: 13, color: FanZoneColors.cream.withValues(alpha: 0.6)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Trois écharpes qui se déroulent à l'arrivée, l'une après l'autre, avec les
/// mots d'un chant. Le seul moment animé de l'écran.
class _ScarfBundle extends StatelessWidget {
  const _ScarfBundle();

  static const _scarves = [
    (Color(0xFFE2462B), 'On est là', -0.05),
    (Color(0xFF1F7A4D), 'Même à vingt', 0.035),
    (Color(0xFF1F5FBF), 'Allez les petits clubs', -0.02),
  ];

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    return Column(
      children: [
        for (var i = 0; i < _scarves.length; i++)
          Transform.rotate(
            angle: _scarves[i].$3,
            child: Padding(
              padding: EdgeInsets.fromLTRB(i.isEven ? 0 : 28, 6, i.isEven ? 28 : 0, 6),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: reduce ? 1 : 0, end: 1),
                duration: Duration(milliseconds: reduce ? 1 : 700 + i * 160),
                curve: Interval(i * 0.14, 1, curve: Curves.easeOutCubic),
                builder: (_, t, child) => ClipRect(
                  child: Align(
                    alignment: i.isEven ? Alignment.centerLeft : Alignment.centerRight,
                    widthFactor: t,
                    child: child,
                  ),
                ),
                child: Scarf.club(_scarves[i].$1, label: _scarves[i].$2, height: 50),
              ),
            ),
          ),
      ],
    );
  }
}
