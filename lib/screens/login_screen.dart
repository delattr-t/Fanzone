import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';

/// Écran d'entrée : un prénom suffit pour démarrer (profil local).
/// Quand un backend sera branché, ce même écran accueillera la connexion
/// Google / email sans changer le reste de l'app.
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
    await AppScope.read(context).signIn(_nameCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Scaffold(
      backgroundColor: FanZoneColors.dark,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(28, 24, 28, 24 + bottomInset),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 48 - bottomInset,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                const Text('🏟️', style: TextStyle(fontSize: 72)),
                const SizedBox(height: 16),
                RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.1,
                    ),
                    children: [
                      TextSpan(text: 'Fan'),
                      TextSpan(text: 'Zone', style: TextStyle(color: FanZoneColors.yellow)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: FanZoneColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: FanZoneColors.primary, width: 1.5),
                  ),
                  child: const Text(
                    '🥁 Viens faire du bruit pour le sport local !',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: FanZoneColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                ...[
                  ('📍', 'Trouve les events sportifs près de chez toi'),
                  ('🎊', 'Rejoins des collectifs de supporters'),
                  ('🥁', 'Chants, rôles, after : organisez-vous'),
                ].map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Text(item.$1, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.$2,
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: FanZoneColors.yellow, width: 2.5),
                    boxShadow: const [
                      BoxShadow(color: FanZoneColors.yellow, offset: Offset(4, 4), blurRadius: 0),
                    ],
                  ),
                  child: TextField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _start(),
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: FanZoneColors.dark,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                      hintText: 'Ton prénom (ou ton surnom de tribune)',
                      hintStyle: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: FanZoneColors.textLight,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: _start,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: FanZoneColors.primary,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: const [
                        BoxShadow(color: Colors.white24, offset: Offset(4, 4), blurRadius: 0),
                      ],
                    ),
                    child: Center(
                      child: _loading
                          ? const SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                            )
                          : const Text(
                              "C'est parti ! 🎊",
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Pas de compte, pas de mot de passe : tes données restent sur ton téléphone.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white38,
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
