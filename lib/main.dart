import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'theme/app_colors.dart';
import 'widgets/responsive_shell.dart';
import 'screens/home_screen.dart';
import 'screens/groups_screen.dart';
import 'screens/alerts_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/create_sol_screen.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// Si l'app utilise Supabase (comme le suppose create_sol_screen.dart),
// initialise-le ici avant runApp() :
//
// import 'package:supabase_flutter/supabase_flutter.dart';
// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Supabase.initialize(url: '...', anonKey: '...');
//   runApp(const SolApp());
// }

void main() async {
  //   WidgetsFlutterBinding.ensureInitialized();
  //   await Supabase.initialize(url: '...', anonKey: '...');
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
      home: _RootShell(language: _language, onLanguageChanged: _setLanguage),
    );
  }
}

/// Assemble les 4 écrans principaux dans le shell de navigation
/// responsive (bottomNav sur mobile, NavigationRail sur écran large).
class _RootShell extends StatelessWidget {
  final AppLanguage language;
  final ValueChanged<AppLanguage> onLanguageChanged;

  const _RootShell({required this.language, required this.onLanguageChanged});

  @override
  Widget build(BuildContext context) {
    return ResponsiveShell(
      screens: [
        const HomeScreen(),
        const GroupsScreen(),
        const AlertsScreen(),
        ProfileScreen(
          currentLanguage: language,
          onLanguageChanged: onLanguageChanged,
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
