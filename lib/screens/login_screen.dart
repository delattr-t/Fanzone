import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/sticker.dart';

/// Écran d'entrée : un prénom suffit. Mise en page d'affiche : fond encre,
/// nom en très gros, une seule couleur d'accent.
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
      backgroundColor: FanZoneColors.ink,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height - 48 - bottomInset),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(height: 8, width: 72, color: FanZoneColors.flare),
                const SizedBox(height: 22),
                Text(
                  'FanZone',
                  style: fzDisplay(fontSize: 72, color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: -2),
                ),
                const SizedBox(height: 6),
                Text(
                  'Les matchs amateurs près de chez toi,\net les gens qui viennent les soutenir.',
                  style: fz(fontSize: 17, color: Colors.white70, height: 1.35),
                ),
                const SizedBox(height: 40),
                Text('Ton prénom', style: fz(fontSize: 14, fontWeight: FontWeight.w600, color: FanZoneColors.hiVis)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: TextField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _start(),
                    style: fzDisplay(fontSize: 28, height: 1.1),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      hintText: 'ou ton surnom de tribune',
                      hintStyle: fzDisplay(fontSize: 24, color: FanZoneColors.cement, fontWeight: FontWeight.w500, height: 1.1),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _start,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: FanZoneColors.flare,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Center(
                      child: _loading
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text('Entrer dans la tribune', style: fz(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Pas de mot de passe, pas d\'e-mail. Ton prénom suffit pour commencer.',
                  style: fz(fontSize: 13, color: Colors.white54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
