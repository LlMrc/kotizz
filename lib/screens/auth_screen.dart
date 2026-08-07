import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_colors.dart';

/// Garde d'authentification.
///
/// Écoute les changements de session Supabase et affiche :
///   • [AuthScreen]  si aucune session n'est active
///   • [child]       si l'utilisateur est connecté
class AuthGate extends StatelessWidget {
  final Widget child;
  const AuthGate({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // En attente d'initialisation
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.paper,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.marigold),
            ),
          );
        }

        final session = snapshot.data?.session;
        if (session != null) return child;

        // Pas de session → écran d'auth
        return const AuthScreen();
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AuthScreen — Apple Sign-In (iOS) & Magic Link (Non-iOS)
// ─────────────────────────────────────────────────────────────────────────────

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _magicLinkSent = false;
  String? _errorMsg;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  /// Authentification Apple (sur iOS)
  Future<void> _signInWithApple() async {
    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      final supabase = Supabase.instance.client;
      await supabase.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: kIsWeb ? null : 'io.supabase.kotizz://login-callback',
      );
    } on AuthException catch (e) {
      setState(() => _errorMsg = _mapAuthError(e.message));
    } catch (e) {
      setState(() => _errorMsg = 'Impossible de se connecter avec Apple.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Envoi d'un Magic Link (Email sans mot de passe)
  Future<void> _sendMagicLink() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errorMsg = null;
      _magicLinkSent = false;
    });

    try {
      final supabase = Supabase.instance.client;
      await supabase.auth.signInWithOtp(
        email: _emailCtrl.text.trim(),
        emailRedirectTo: kIsWeb ? null : 'io.supabase.kotizz://login-callback',
      );
      setState(() => _magicLinkSent = true);
    } on AuthException catch (e) {
      setState(() => _errorMsg = _mapAuthError(e.message));
    } catch (e) {
      setState(() => _errorMsg = 'Une erreur est survenue lors de l\'envoi du lien.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Traduit les messages d'erreur Supabase en français.
  String _mapAuthError(String msg) {
    if (msg.contains('Rate limit exceeded') || msg.contains('too many requests')) {
      return 'Trop de tentatives. Veuillez patienter un instant.';
    }
    if (msg.contains('Invalid email')) {
      return 'Adresse email invalide.';
    }
    return msg;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Logo / En-tête ─────────────────────────────
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.ink.withValues(alpha: 0.18),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'K',
                        style: GoogleFonts.bricolageGrotesque(
                          fontSize: 38,
                          fontWeight: FontWeight.w700,
                          color: AppColors.marigold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      'Kotizz',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      'L\'épargne collective, simplifiée.',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 14,
                        color: AppColors.ash,
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // ── iOS Mode : Bouton Apple prioritaire ────────
                  if (_isIOS) ...[
                    Text(
                      'Bienvenue !',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Connectez-vous en un instant avec votre compte Apple.',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 13.5,
                        color: AppColors.ash,
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : _signInWithApple,
                        icon: const Icon(Icons.apple, size: 24, color: AppColors.white),
                        label: Text(
                          'Continuer avec Apple',
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    Row(
                      children: [
                        const Expanded(child: Divider(color: AppColors.paperDim)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'OU PAR EMAIL',
                            style: GoogleFonts.ibmPlexMono(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ash,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider(color: AppColors.paperDim)),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Non-iOS (ou secours iOS) : Magic Link Email ─
                  if (!_isIOS) ...[
                    Text(
                      'Connexion rapide',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Entrez votre email. Aucun mot de passe requis !',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 13.5,
                        color: AppColors.ash,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  if (_magicLinkSent) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.palm.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.palm.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.mark_email_read_rounded, size: 44, color: AppColors.palm),
                          const SizedBox(height: 12),
                          Text(
                            'Lien de connexion envoyé ! ✉️',
                            style: GoogleFonts.bricolageGrotesque(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Consultez la boîte de réception de ${_emailCtrl.text.trim()} et cliquez sur le lien pour vous connecter.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 13.5,
                              color: AppColors.ash,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () => setState(() => _magicLinkSent = false),
                            child: Text(
                              'Renvoyer un lien',
                              style: GoogleFonts.ibmPlexSans(
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Form(
                      key: _formKey,
                      child: _AuthField(
                        controller: _emailCtrl,
                        label: 'Votre adresse email',
                        hint: 'vous@exemple.com',
                        icon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'L\'email est requis';
                          }
                          if (!v.contains('@')) {
                            return 'Email invalide';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 14),

                    if (_errorMsg != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 11),
                        decoration: BoxDecoration(
                          color: AppColors.coral.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.coral.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                color: AppColors.coral, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMsg!,
                                style: GoogleFonts.ibmPlexSans(
                                  fontSize: 13,
                                  color: AppColors.coral,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _sendMagicLink,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.ink,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: AppColors.white,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.auto_awesome_rounded, size: 18, color: AppColors.marigold),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Recevoir mon lien de connexion',
                                    style: GoogleFonts.ibmPlexSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // ── Note d'information plan FREE / PRO ─────────
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.marigold.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.marigold.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            color: AppColors.marigold, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.ibmPlexSans(
                                fontSize: 12.5,
                                color: AppColors.ink,
                              ),
                              children: const [
                                TextSpan(
                                  text: 'Plan Gratuit : ',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                TextSpan(
                                  text: '1 groupe SOL max, 5 membres max. Passez au ',
                                ),
                                TextSpan(
                                  text: 'PRO (9,99\$/mois)',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                TextSpan(text: ' pour des groupes illimités.'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget réutilisable : champ de formulaire Auth
// ─────────────────────────────────────────────────────────────────────────────
class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _AuthField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.ibmPlexSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.ibmPlexSans(fontSize: 14.5, color: AppColors.ink),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.ibmPlexSans(fontSize: 14, color: AppColors.ash),
            prefixIcon: Icon(icon, size: 20, color: AppColors.ash),
            filled: true,
            fillColor: AppColors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.paperDim),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.paperDim),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.marigold, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.coral),
            ),
          ),
        ),
      ],
    );
  }
}
