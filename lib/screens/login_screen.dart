import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loading = false;

  Future<void> _signInGoogle() async {
    setState(() => _loading = true);
    final result = await AuthService.signInWithGoogle();
    if (mounted && result == null) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Connexion annulée.', style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700)),
          backgroundColor: FanZoneColors.dark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<void> _signInAnonymous() async {
    setState(() => _loading = true);
    await AuthService.signInAnonymously();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FanZoneColors.dark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Logo / Hero
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

              const Spacer(flex: 2),

              // Features bullets
              ...[
                ('📍', 'Trouve les events sportifs près de chez toi'),
                ('🎊', 'Rejoins des collectifs de supporters'),
                ('🥁', 'Fais du bruit pour les équipes locales'),
              ].map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Text(item.$1, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 12),
                      Text(
                        item.$2,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(flex: 1),

              // Bouton Google
              _loading
                  ? const CircularProgressIndicator(color: FanZoneColors.primary)
                  : Column(
                      children: [
                        // Connexion Google
                        GestureDetector(
                          onTap: _signInGoogle,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: FanZoneColors.yellow, width: 2.5),
                              boxShadow: const [
                                BoxShadow(
                                  color: FanZoneColors.yellow,
                                  offset: Offset(4, 4),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('G', style: TextStyle(fontFamily: 'Nunito', fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF4285F4))),
                                SizedBox(width: 10),
                                Text(
                                  'Continuer avec Google',
                                  style: TextStyle(fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.w900, color: FanZoneColors.dark),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Continuer sans compte
                        GestureDetector(
                          onTap: _signInAnonymous,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white24, width: 1.5),
                            ),
                            child: const Center(
                              child: Text(
                                'Continuer sans compte →',
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white60,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
