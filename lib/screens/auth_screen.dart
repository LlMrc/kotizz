import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_colors.dart';
import '../l10n/app_localizations.dart';

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

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _loading = false;
  bool _magicLinkSent = false;
  String? _errorMsg;

  // ── Reviewer demo access (hidden: tap logo 5 times) ──────────────────────
  static const _demoEmail = 'reviewer@kotizz-demo.app';
  static const _demoPassword = 'K0t1zz#Rev!ew2026';
  int _logoTapCount = 0;
  DateTime? _firstLogoTap;
  bool _showReviewerButton = false;

  // ── Souscription auth : ferme la bottom sheet avant AuthGate bascule ─────
  late final StreamSubscription<AuthState> _authSub;

  bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    // Fermer la bottom sheet DÈS qu'une session active arrive,
    // pour éviter l'assertion _dependents.isEmpty lors du rebuild d'AuthGate.
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.session != null && mounted) {
        // Fermer tous les dialogs/sheets empilés sur le navigator courant
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });
  }

  @override
  void dispose() {
    _authSub.cancel();
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  /// Authentification Apple native (iOS/iPadOS) via ASAuthorizationAppleIDProvider.
  /// Utilise signInWithIdToken avec un nonce brut haché en SHA-256 pour Supabase.
  Future<void> _signInWithApple() async {
    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      final supabase = Supabase.instance.client;
      final rawNonce = supabase.auth.generateRawNonce();
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final idToken = appleCredential.identityToken;
      if (idToken == null) {
        setState(() => _errorMsg = 'Apple n\'a pas retourné de jeton. Veuillez réessayer.');
        return;
      }

      await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        // L'utilisateur a annulé → pas d'erreur à afficher
        return;
      }
      setState(() => _errorMsg = 'Connexion Apple échouée : ${e.message}');
    } on AuthException catch (e) {
      setState(() => _errorMsg = _mapAuthError(e.message));
    } catch (e) {
      setState(() => _errorMsg = 'Impossible de se connecter avec Apple.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Gère les tapotements sur le logo (5 taps en moins de 6 secondes
  /// → révèle le bouton de démonstration pour les évaluateurs App Store).
  void _onLogoTap() {
    final now = DateTime.now();
    if (_firstLogoTap == null ||
        now.difference(_firstLogoTap!) > const Duration(seconds: 6)) {
      _firstLogoTap = now;
      _logoTapCount = 1;
    } else {
      _logoTapCount++;
    }
    if (_logoTapCount >= 5 && !_showReviewerButton) {
      setState(() => _showReviewerButton = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mode Démo activé (App Review)'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Connexion silencieuse avec le compte de démonstration pour les évaluateurs.
  Future<void> _signInAsReviewer() async {
    setState(() {
      _loading = true;
      _errorMsg = null;
    });
    try {
      final supabase = Supabase.instance.client;
      await supabase.auth.signInWithPassword(
        email: _demoEmail,
        password: _demoPassword,
      );
    } on AuthException catch (e) {
      setState(() => _errorMsg = 'Demo login failed: ${e.message}');
    } catch (e) {
      setState(() => _errorMsg = 'Demo login unavailable. Please try again.');
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
        emailRedirectTo: kIsWeb ? null : 'kotizz://login-callback',
      );
      setState(() {
        _magicLinkSent = true;
        _otpCtrl.clear();
      });
    } on AuthException catch (e) {
      setState(() => _errorMsg = _mapAuthError(e.message));
    } catch (e) {
      setState(() => _errorMsg = 'Une erreur est survenue lors de l\'envoi du lien.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Vérification du code OTP (6 à 8 chiffres selon la configuration Supabase)
  Future<void> _verifyOtp() async {
    final code = _otpCtrl.text.trim();
    if (code.length < 6 || code.length > 8) {
      setState(() => _errorMsg = 'Veuillez entrer le code complet reçu par email.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      final supabase = Supabase.instance.client;
      await supabase.auth.verifyOTP(
        email: _emailCtrl.text.trim(),
        token: code,
        type: OtpType.email,
      );
    } on AuthException catch (e) {
      setState(() => _errorMsg = _mapAuthError(e.message));
    } catch (e) {
      setState(() => _errorMsg = 'Code invalide ou expiré. Veuillez réessayer.');
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
    if (msg.contains('Token has expired') || msg.contains('otp_expired') || msg.contains('expired')) {
      return 'Le code a expiré. Veuillez en redemander un nouveau.';
    }
    if (msg.contains('invalid') || msg.contains('Invalid token') || msg.contains('Token is invalid')) {
      return 'Code de confirmation incorrect.';
    }
    return msg;
  }

  /// Ouvre la bottom sheet contenant le formulaire de connexion.
  /// Le bouton "Kòmanse" est le point d'entrée de la connexion.
  void _showLoginSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LoginSheet(
        formKey: _formKey,
        emailCtrl: _emailCtrl,
        otpCtrl: _otpCtrl,
        loading: _loading,
        magicLinkSent: _magicLinkSent,
        errorMsg: _errorMsg,
        isIOS: _isIOS,
        onSendMagicLink: _sendMagicLink,
        onVerifyOtp: _verifyOtp,
        onSignInWithApple: _signInWithApple,
        onResetMagicLink: () => setState(() {
          _magicLinkSent = false;
          _otpCtrl.clear();
          _errorMsg = null;
        }),
        onResendCode: () {
          _otpCtrl.clear();
          _sendMagicLink();
        },
        onSignInAsReviewer: _showReviewerButton ? _signInAsReviewer : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1A3B),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Fond plein écran ─────────────────────────────────────────
          Image.asset(
            'assets/kotizz_background.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),

          // ── Fondu sombre haut (lisibilité logo) ──────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            height: size.height * 0.45,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xCC0B1A3B), Colors.transparent],
                ),
              ),
            ),
          ),

          // ── Fondu sombre bas (lisibilité bouton) ─────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            height: size.height * 0.32,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xEA0B1A3B), Colors.transparent],
                ),
              ),
            ),
          ),

          // ── Slogan positionné exactement comme sur le mockup ────────
          Positioned(
            top: size.height * 0.40,
            right: 24,
            child: Transform.rotate(
              angle: -0.09, // légère rotation dynamique / manuscrite
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    t.splashSlogan,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.caveat(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.15,
                      letterSpacing: 0.5,
                      shadows: const [
                        Shadow(
                          color: Color(0xBB081226),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Trait courbé doré / jaune sous le slogan
                  CustomPaint(
                    size: const Size(130, 8),
                    painter: _SloganUnderlinePainter(),
                  ),
                ],
              ),
            ),
          ),

          // ── Contenu haut & bas ───────────────────────────────────────
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 36),

                // Logo (tap 5× → démo reviewer)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _onLogoTap,
                  child: Image.asset(
                    'assets/kotizz_logo.png',
                    width: 92,
                    height: 92,
                  ),
                ),

                const SizedBox(height: 14),

                // Nom de l'application
                Text(
                  'Kotizz',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    color: AppColors.marigold,
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 4),

                // Sous-titre
                Text(
                  'Your Sòl, Simplified',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 15,
                    color: Colors.white.withValues(alpha: 0.72),
                  ),
                ),

                const Spacer(),

                // ── Bouton Kòmanse = bouton de connexion ─────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _showLoginSheet,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.marigold,
                        foregroundColor: AppColors.ink,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        elevation: 8,
                        shadowColor: AppColors.marigold.withValues(alpha: 0.55),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            t.komanseBtnLabel,
                            style: GoogleFonts.bricolageGrotesque(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 22,
                            color: AppColors.ink,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Peintre personnalisé pour la ligne jaune courbée / brush sous le slogan
class _SloganUnderlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.marigold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.1,
      size.width,
      size.height * 0.6,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom sheet — formulaire complet de connexion
// ─────────────────────────────────────────────────────────────────────────────
class _LoginSheet extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController otpCtrl;
  final bool loading;
  final bool magicLinkSent;
  final String? errorMsg;
  final bool isIOS;
  final VoidCallback onSendMagicLink;
  final VoidCallback onVerifyOtp;
  final VoidCallback onSignInWithApple;
  final VoidCallback onResetMagicLink;
  final VoidCallback onResendCode;
  final VoidCallback? onSignInAsReviewer;

  const _LoginSheet({
    required this.formKey,
    required this.emailCtrl,
    required this.otpCtrl,
    required this.loading,
    required this.magicLinkSent,
    required this.errorMsg,
    required this.isIOS,
    required this.onSendMagicLink,
    required this.onVerifyOtp,
    required this.onSignInWithApple,
    required this.onResetMagicLink,
    required this.onResendCode,
    this.onSignInAsReviewer,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24, 20, 24,
        MediaQuery.viewInsetsOf(context).bottom + 32,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Indicateur glissement
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.paperDim,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 22),

            // Mini en-tête logo + nom
            Row(
              children: [
                Image.asset('assets/kotizz_logo.png', width: 34, height: 34),
                const SizedBox(width: 10),
                Text(
                  'Kotizz',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── iOS : Bouton Apple ────────────────────────────────────
            if (isIOS) ...[
              Text(
                t.authWelcome,
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                t.authApplePrompt,
                style: GoogleFonts.ibmPlexSans(fontSize: 13.5, color: AppColors.ash),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: loading ? null : onSignInWithApple,
                  icon: const Icon(Icons.apple, size: 22, color: AppColors.white),
                  label: Text(
                    t.continueWithApple,
                    style: GoogleFonts.ibmPlexSans(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.paperDim)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      t.orEmail,
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
              const SizedBox(height: 18),
            ],

            // ── Non-iOS ───────────────────────────────────────────────
            if (!isIOS) ...[
              Text(
                'Connexion rapide',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Entrez votre email. Aucun mot de passe requis !',
                style: GoogleFonts.ibmPlexSans(fontSize: 13.5, color: AppColors.ash),
              ),
              const SizedBox(height: 18),
            ],

            // ── Code OTP envoyé ───────────────────────────────────────
            if (magicLinkSent) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.paperDim),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.palm.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.mark_email_read_rounded, size: 22, color: AppColors.palm),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Code envoyé ! ✉️',
                                style: GoogleFonts.bricolageGrotesque(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                              Text(
                                emailCtrl.text.trim(),
                                style: GoogleFonts.ibmPlexSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ash,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      t.enterEmailCodePrompt,
                      style: GoogleFonts.ibmPlexSans(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.ink),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: otpCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 8,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 4,
                        color: AppColors.ink,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: '••••••••',
                        hintStyle: GoogleFonts.ibmPlexMono(
                          fontSize: 22,
                          letterSpacing: 4,
                          color: AppColors.ash.withValues(alpha: 0.35),
                        ),
                        filled: true,
                        fillColor: AppColors.paper,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
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
                          borderSide: const BorderSide(color: AppColors.marigold, width: 2),
                        ),
                      ),
                      onChanged: (val) {
                        if (val.trim().length == 8) onVerifyOtp();
                      },
                    ),
                    const SizedBox(height: 10),
                    if (errorMsg != null) _ErrorBanner(message: errorMsg!),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: loading ? null : onVerifyOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.ink,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: loading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.white))
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check_circle_outline_rounded, size: 18, color: AppColors.marigold),
                                  const SizedBox(width: 8),
                                  Text(t.validateMyCode, style: GoogleFonts.ibmPlexSans(fontSize: 15, fontWeight: FontWeight.w600)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: loading ? null : onResendCode,
                          icon: const Icon(Icons.refresh_rounded, size: 15, color: AppColors.ink),
                          label: Text(t.resendCode, style: GoogleFonts.ibmPlexSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
                        ),
                        TextButton(
                          onPressed: loading ? null : onResetMagicLink,
                          child: Text(t.changeEmail, style: GoogleFonts.ibmPlexSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ash)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              // ── Formulaire email ──────────────────────────────────────
              Form(
                key: formKey,
                child: _AuthField(
                  controller: emailCtrl,
                  label: t.emailAddressLabel,
                  hint: t.emailHint,
                  icon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return t.validationAmountRequired;
                    if (!v.contains('@')) return 'Email invalide';
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 12),
              if (errorMsg != null) _ErrorBanner(message: errorMsg!),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: loading ? null : onSendMagicLink,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.white))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.auto_awesome_rounded, size: 18, color: AppColors.marigold),
                            const SizedBox(width: 8),
                            Text(t.sendLoginCode, style: GoogleFonts.ibmPlexSans(fontSize: 15, fontWeight: FontWeight.w600)),
                          ],
                        ),
                ),
              ),
            ],

            const SizedBox(height: 18),

            // ── Note plan FREE / PRO ──────────────────────────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.marigold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.marigold.withValues(alpha: 0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.marigold, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.ibmPlexSans(fontSize: 12, color: AppColors.ink),
                        children: const [
                          TextSpan(text: 'Plan Gratuit : ', style: TextStyle(fontWeight: FontWeight.w700)),
                          TextSpan(text: '1 groupe SOL max, 5 membres max. Passez au '),
                          TextSpan(text: 'PRO (9,99\$/mois)', style: TextStyle(fontWeight: FontWeight.w700)),
                          TextSpan(text: ' pour des groupes illimités.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Bouton démo reviewers (caché, 5 taps sur logo) ───────
            if (onSignInAsReviewer != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: loading ? null : onSignInAsReviewer,
                  icon: const Icon(Icons.preview_rounded, size: 18),
                  label: Text(
                    'App Review — Demo Access',
                    style: GoogleFonts.ibmPlexSans(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.marigold,
                    foregroundColor: AppColors.ink,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bannière d'erreur réutilisable
// ─────────────────────────────────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.coral.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.coral.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.coral, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.ibmPlexSans(fontSize: 13, color: AppColors.coral, fontWeight: FontWeight.w500),
            ),
          ),
        ],
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
