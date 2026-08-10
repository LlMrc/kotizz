import 'package:firebase_core/firebase_core.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'theme/app_colors.dart';
import 'widgets/responsive_shell.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/groups_screen.dart';
import 'screens/alerts_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/create_sol_screen.dart';
import 'services/notification_service.dart';

/// Clés d'accès au backend Supabase
const _supabaseUrl = 'https://nwdgnbzpvoypzduzreec.supabase.co';
const _supabaseAnonKey = 'sb_publishable_W2m9cj3XcDzNVJVIr9zd0g_r0aB0NMg';

// Clé API RevenueCat
const _revenueCatApiKey = 'appl_ndKqPUhQfqBsVRtPAAuzoaRsEAY';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization warning: $e');
  }

  // Initialisation Supabase
  await Supabase.initialize(
    url: _supabaseUrl,
    publishableKey: _supabaseAnonKey,
  );

  // Initialisation RevenueCat
  await Purchases.setLogLevel(LogLevel.info);
  final PurchasesConfiguration configuration = PurchasesConfiguration(
    _revenueCatApiKey,
  );
  try {
    await Purchases.configure(configuration);
  } catch (e) {
    debugPrint('RevenueCat initialization warning: $e');
  }

  // Initialisation Firebase Notifications
  await NotificationService.initialize();

  runApp(const SolApp());
}

// Fournit un getter `locale` pour AppLanguage si l'enum est défini ailleurs
// (évite l'erreur "The getter 'locale' isn't defined for the type 'AppLanguage'.")
extension _AppLanguageLocale on AppLanguage {
  Locale get locale {
    switch (this) {
      case AppLanguage.french:
        return const Locale('fr');
      case AppLanguage.english:
        return const Locale('en');
      case AppLanguage.creole:
        return const Locale('ht');
    }
  }
}

class _HtMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _HtMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ht';

  @override
  Future<MaterialLocalizations> load(Locale locale) async {
    return await GlobalMaterialLocalizations.delegate.load(const Locale('fr'));
  }

  @override
  bool shouldReload(_HtMaterialLocalizationsDelegate old) => false;
}

class _HtCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const _HtCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ht';

  @override
  Future<CupertinoLocalizations> load(Locale locale) async {
    return await GlobalCupertinoLocalizations.delegate.load(const Locale('fr'));
  }

  @override
  bool shouldReload(_HtCupertinoLocalizationsDelegate old) => false;
}

class SolApp extends StatefulWidget {
  const SolApp({super.key});

  @override
  State<SolApp> createState() => _SolAppState();
}

class _SolAppState extends State<SolApp> {
  // Langue par défaut : français, ajustable via l'écran Profil.
  AppLanguage _language = AppLanguage.french;

  void _setLanguage(AppLanguage lang) => setState(() => _language = lang);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kotizz',
      locale: _language.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        _HtMaterialLocalizationsDelegate(),
        _HtCupertinoLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.paper,
        fontFamily: GoogleFonts.ibmPlexSans().fontFamily,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.marigold,
          surface: AppColors.paper,
        ),
      ),
      // AuthGate écoute la session Supabase :
      //   • Pas de session  → AuthScreen (connexion / inscription)
      //   • Session active  → shell principal de l'app
      home: AuthGate(
        child: _RootShell(language: _language, onLanguageChanged: _setLanguage),
      ),
    );
  }
}

/// Assemble les 4 écrans principaux dans le shell de navigation
/// responsive (bottomNav sur mobile, NavigationRail sur écran large).
class _RootShell extends StatefulWidget {
  final AppLanguage language;
  final ValueChanged<AppLanguage> onLanguageChanged;

  const _RootShell({required this.language, required this.onLanguageChanged});

  @override
  State<_RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<_RootShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.setupForegroundListener(context);
      NotificationService.syncFcmToken();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveShell(
      screens: [
        const HomeScreen(),
        const GroupsScreen(),
        const AlertsScreen(),
        ProfileScreen(
          currentLanguage: widget.language,
          onLanguageChanged: widget.onLanguageChanged,
        ),
      ],
      onCreateSol: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const CreateSolScreen()));
      },
    );
  }
}
