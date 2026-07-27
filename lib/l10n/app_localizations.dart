import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// Langues supportées par l'application.
enum AppLanguage { en, fr, ht }

extension AppLanguageX on AppLanguage {
  Locale get locale {
    switch (this) {
      case AppLanguage.en:
        return const Locale('en');
      case AppLanguage.fr:
        return const Locale('fr');
      case AppLanguage.ht:
        return const Locale('ht');
    }
  }

  /// Nom affiché dans le sélecteur de langue (dans sa propre langue).
  String get nativeLabel {
    switch (this) {
      case AppLanguage.en:
        return 'English';
      case AppLanguage.fr:
        return 'Français';
      case AppLanguage.ht:
        return 'Kreyòl Ayisyen';
    }
  }
}

/// Fournit les chaînes traduites pour l'écran courant.
/// Implémentation légère (sans génération de code) : un simple
/// dictionnaire clé -> {en, fr, ht}. Pratique pour un MVP ; peut être
/// remplacé plus tard par flutter gen-l10n si l'app grossit.
class AppLocalizations {
  final Locale locale;
  const AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const supportedLocales = [Locale('en'), Locale('fr'), Locale('ht')];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  String get _code => locale.languageCode;

  String _t(String key) =>
      _values[key]?[_code] ?? _values[key]?['en'] ?? key;

  // ---------- Navigation ----------
  String get navHome => _t('navHome');
  String get navGroups => _t('navGroups');
  String get navAlerts => _t('navAlerts');
  String get navProfile => _t('navProfile');

  // ---------- Accueil ----------
  String greeting(String name) => _t('greeting').replaceAll('{name}', name);
  String get trustScoreSuffix => _t('trustScoreSuffix');
  String get wheelGroupExample => _t('wheelGroupExample');
  String get wheelSectionLabel => _t('wheelSectionLabel');
  String turnCounter(int current, int total) => _t('turnCounter')
      .replaceAll('{current}', '$current')
      .replaceAll('{total}', '$total');
  String get currentTurnLabel => _t('currentTurnLabel');
  String get yourTurn => _t('yourTurn');
  String confirmedCount(int confirmed, int total) => _t('confirmedCount')
      .replaceAll('{confirmed}', '$confirmed')
      .replaceAll('{total}', '$total');
  String get activeGroups => _t('activeGroups');
  String get seeAll => _t('seeAll');
  String get statusUpToDate => _t('statusUpToDate');
  String get statusPending => _t('statusPending');
  String get statusDispute => _t('statusDispute');
  String get quickActions => _t('quickActions');
  String get createSol => _t('createSol');
  String get iPaid => _t('iPaid');

  // ---------- Création d'un sòl ----------
  String get createSolTitle => _t('createSolTitle');
  String get fieldName => _t('fieldName');
  String get fieldNameHint => _t('fieldNameHint');
  String get fieldDescription => _t('fieldDescription');
  String get fieldDescriptionHint => _t('fieldDescriptionHint');
  String get fieldAmount => _t('fieldAmount');
  String get fieldAmountHint => _t('fieldAmountHint');
  String get fieldFrequency => _t('fieldFrequency');
  String get freqWeekly => _t('freqWeekly');
  String get freqBiweekly => _t('freqBiweekly');
  String get freqMonthly => _t('freqMonthly');
  String get fieldMembers => _t('fieldMembers');
  String get fieldMembersHint => _t('fieldMembersHint');
  String get fieldStartDate => _t('fieldStartDate');
  String get submitCreate => _t('submitCreate');
  String get validationNameRequired => _t('validationNameRequired');
  String get validationAmountRequired => _t('validationAmountRequired');
  String get validationAmountInvalid => _t('validationAmountInvalid');
  String get validationMembersRequired => _t('validationMembersRequired');
  String get validationMembersInvalid => _t('validationMembersInvalid');

  // ---------- Paywall ----------
  String get paywallTitle => _t('paywallTitle');
  String get paywallBody => _t('paywallBody');
  String get paywallPlanName => _t('paywallPlanName');
  String get paywallCta => _t('paywallCta');

  // ---------- Invitation ----------
  String get inviteSheetTitle => _t('inviteSheetTitle');
  String get inviteSheetSubtitle => _t('inviteSheetSubtitle');
  String get shareInvite => _t('shareInvite');
  String get later => _t('later');
  String get inviteMessageIntro => _t('inviteMessageIntro');
  String get inviteMessageAmountLabel => _t('inviteMessageAmountLabel');
  String get inviteMessageFrequencyLabel => _t('inviteMessageFrequencyLabel');
  String get inviteMessageStartLabel => _t('inviteMessageStartLabel');
  String get inviteMessageJoinLabel => _t('inviteMessageJoinLabel');

  // ---------- Groupes / Alertes / Profil ----------
  String get groupsTitle => _t('groupsTitle');
  String get groupsEmpty => _t('groupsEmpty');
  String get alertsTitle => _t('alertsTitle');
  String get alertsEmpty => _t('alertsEmpty');
  String get profileTitle => _t('profileTitle');
  String get profileTrustScore => _t('profileTrustScore');
  String get profileCompletedCycles => _t('profileCompletedCycles');
  String get profileDisputes => _t('profileDisputes');
  String get profileVerifyPhone => _t('profileVerifyPhone');
  String get profileVerifyId => _t('profileVerifyId');
  String get profileLanguage => _t('profileLanguage');
  String get logOut => _t('logOut');

  static final Map<String, Map<String, String>> _values = {
    'navHome': {'en': 'Home', 'fr': 'Accueil', 'ht': 'Akèy'},
    'navGroups': {'en': 'Groups', 'fr': 'Groupes', 'ht': 'Gwoup'},
    'navAlerts': {'en': 'Alerts', 'fr': 'Alertes', 'ht': 'Alèt'},
    'navProfile': {'en': 'Profile', 'fr': 'Profil', 'ht': 'Pwofil'},

    'greeting': {
      'en': 'Hello, {name}',
      'fr': 'Bonjour, {name}',
      'ht': 'Bonjou, {name}',
    },
    'trustScoreSuffix': {'en': 'pts', 'fr': 'pts', 'ht': 'pwen'},
    'wheelGroupExample': {
      'en': 'Miami-PAP Family Sòl',
      'fr': 'Sòl Fanmi Miami-PAP',
      'ht': 'Sòl Fanmi Miami-PAP',
    },
    'wheelSectionLabel': {
      'en': 'Contribution wheel',
      'fr': 'Wonn kotizasyon an',
      'ht': 'Wonn kotizasyon an',
    },
    'turnCounter': {'en': '{current}/{total}', 'fr': '{current}/{total}', 'ht': '{current}/{total}'},
    'currentTurnLabel': {
      'en': 'CURRENT TURN',
      'fr': 'TOU AKTYÈL',
      'ht': 'TOU AKTYÈL',
    },
    'yourTurn': {'en': 'Your turn', 'fr': 'Ton tour', 'ht': 'Tou pa w'},
    'confirmedCount': {
      'en': '{confirmed} of {total} confirmed',
      'fr': '{confirmed} sur {total} ont confirmé',
      'ht': '{confirmed} sou {total} konfime',
    },
    'activeGroups': {
      'en': 'Your active sòl',
      'fr': 'Tes sòl actifs',
      'ht': 'Sòl aktif ou yo',
    },
    'seeAll': {'en': 'See all', 'fr': 'Voir tout', 'ht': 'Wè tout'},
    'statusUpToDate': {'en': 'UP TO DATE', 'fr': 'À JOUR', 'ht': 'AJOU'},
    'statusPending': {'en': 'PENDING', 'fr': 'EN ATTENTE', 'ht': 'AN ATANN'},
    'statusDispute': {'en': 'DISPUTE', 'fr': 'LITIGE', 'ht': 'LITIJ'},
    'quickActions': {
      'en': 'Quick actions',
      'fr': 'Actions rapides',
      'ht': 'Aksyon rapid',
    },
    'createSol': {
      'en': 'Create a sòl',
      'fr': 'Créer un sòl',
      'ht': 'Kreye yon sòl',
    },
    'iPaid': {'en': 'I paid', 'fr': "J'ai payé", 'ht': 'Mwen peye'},

    'createSolTitle': {
      'en': 'Create a sòl',
      'fr': 'Créer un sòl',
      'ht': 'Kreye yon sòl',
    },
    'fieldName': {
      'en': 'Sòl name',
      'fr': 'Nom du sòl',
      'ht': 'Non sòl la',
    },
    'fieldNameHint': {
      'en': 'e.g. Miami-PAP Family Sòl',
      'fr': 'Ex : Sòl Fanmi Miami-PAP',
      'ht': 'Egz. Sòl Fanmi Miami-PAP',
    },
    'fieldDescription': {
      'en': 'Description (optional)',
      'fr': 'Description (optionnel)',
      'ht': 'Deskripsyon (opsyonèl)',
    },
    'fieldDescriptionHint': {
      'en': 'A few words about this group...',
      'fr': 'Quelques mots sur ce groupe...',
      'ht': 'Kèk mo sou gwoup sa a...',
    },
    'fieldAmount': {
      'en': 'Contribution amount',
      'fr': 'Montant de la cotisation',
      'ht': 'Montan kotizasyon an',
    },
    'fieldAmountHint': {'en': 'e.g. 15000', 'fr': 'Ex : 15000', 'ht': 'Egz. 15000'},
    'fieldFrequency': {'en': 'Frequency', 'fr': 'Fréquence', 'ht': 'Frekans'},
    'freqWeekly': {'en': 'Weekly', 'fr': 'Hebdomadaire', 'ht': 'Chak semenn'},
    'freqBiweekly': {
      'en': 'Every 2 weeks',
      'fr': 'Toutes les 2 semaines',
      'ht': 'Chak de semenn',
    },
    'freqMonthly': {'en': 'Monthly', 'fr': 'Mensuel', 'ht': 'Chak mwa'},
    'fieldMembers': {
      'en': 'Expected number of participants',
      'fr': 'Nombre de participants prévu',
      'ht': 'Kantite manm ou prevwa',
    },
    'fieldMembersHint': {'en': 'e.g. 8', 'fr': 'Ex : 8', 'ht': 'Egz. 8'},
    'fieldStartDate': {
      'en': 'Start date',
      'fr': 'Date de début',
      'ht': 'Dat kòmansman',
    },
    'submitCreate': {
      'en': 'Create the sòl',
      'fr': 'Créer le sòl',
      'ht': 'Kreye sòl la',
    },
    'validationNameRequired': {
      'en': 'Name required',
      'fr': 'Nom requis',
      'ht': 'Non obligatwa',
    },
    'validationAmountRequired': {
      'en': 'Amount required',
      'fr': 'Montant requis',
      'ht': 'Montan obligatwa',
    },
    'validationAmountInvalid': {
      'en': 'Invalid amount',
      'fr': 'Montant invalide',
      'ht': 'Montan pa valid',
    },
    'validationMembersRequired': {
      'en': 'Number required',
      'fr': 'Nombre requis',
      'ht': 'Kantite obligatwa',
    },
    'validationMembersInvalid': {
      'en': 'Invalid number',
      'fr': 'Nombre invalide',
      'ht': 'Kantite pa valid',
    },

    'paywallTitle': {
      'en': 'Time to level up 🚀',
      'fr': 'Il est temps de passer premium 🚀',
      'ht': 'Li lè pou w pase premium 🚀',
    },
    'paywallBody': {
      'en': "Your free trial has ended and you already organize 1 active sòl. Subscribe to create more at the same time.",
      'fr': "Ton essai gratuit est terminé et tu organises déjà 1 sòl actif. Abonne-toi pour en créer d'autres en parallèle.",
      'ht': "Peryòd gratis ou fini e ou deja ap òganize 1 sòl aktif. Abòne w pou w ka kreye plis an menm tan.",
    },
    'paywallPlanName': {
      'en': 'Organizer Premium',
      'fr': 'Organisateur Premium',
      'ht': 'Òganizatè Premium',
    },
    'paywallCta': {
      'en': 'Subscribe now',
      'fr': "S'abonner maintenant",
      'ht': 'Abòne kounye a',
    },

    'inviteSheetTitle': {
      'en': 'Sòl created 🎉',
      'fr': 'Sòl créé 🎉',
      'ht': 'Sòl kreye 🎉',
    },
    'inviteSheetSubtitle': {
      'en': "You're now the organizer. Invite your participants:",
      'fr': "Tu es maintenant l'organisateur. Invite tes participants :",
      'ht': 'Ou se òganizatè kounye a. Envite manm yo :',
    },
    'shareInvite': {
      'en': 'Share invitation',
      'fr': "Partager l'invitation",
      'ht': 'Pataje envitasyon an',
    },
    'later': {'en': 'Later', 'fr': 'Plus tard', 'ht': 'Pita'},
    'inviteMessageIntro': {
      'en': "🤝 You're invited to join",
      'fr': '🤝 Tu es invité(e) à rejoindre',
      'ht': '🤝 Ou envite pou w antre nan',
    },
    'inviteMessageAmountLabel': {
      'en': '💰 Contribution',
      'fr': '💰 Cotisation',
      'ht': '💰 Kotizasyon',
    },
    'inviteMessageFrequencyLabel': {
      'en': '🔁 Frequency',
      'fr': '🔁 Fréquence',
      'ht': '🔁 Frekans',
    },
    'inviteMessageStartLabel': {
      'en': '📅 Starts',
      'fr': '📅 Début',
      'ht': '📅 Kòmanse',
    },
    'inviteMessageJoinLabel': {
      'en': 'Join the group here:',
      'fr': 'Rejoins le groupe ici :',
      'ht': 'Antre nan gwoup la isit la :',
    },

    'groupsTitle': {'en': 'Groups', 'fr': 'Groupes', 'ht': 'Gwoup'},
    'groupsEmpty': {
      'en': "You haven't joined any sòl yet.",
      'fr': "Tu n'as encore rejoint aucun sòl.",
      'ht': "Ou poko antre nan okenn sòl.",
    },
    'alertsTitle': {'en': 'Alerts', 'fr': 'Alertes', 'ht': 'Alèt'},
    'alertsEmpty': {
      'en': "You're all caught up.",
      'fr': 'Tu es à jour.',
      'ht': 'Ou ajou.',
    },
    'profileTitle': {'en': 'Profile', 'fr': 'Profil', 'ht': 'Pwofil'},
    'profileTrustScore': {
      'en': 'Trust score',
      'fr': 'Score de confiance',
      'ht': 'Nòt konfyans',
    },
    'profileCompletedCycles': {
      'en': 'Completed sòl',
      'fr': 'Sòl terminés',
      'ht': 'Sòl fini',
    },
    'profileDisputes': {'en': 'Disputes', 'fr': 'Litiges', 'ht': 'Litij'},
    'profileVerifyPhone': {
      'en': 'Verify phone number',
      'fr': 'Vérifier le numéro de téléphone',
      'ht': 'Verifye nimewo telefòn',
    },
    'profileVerifyId': {
      'en': 'Verify ID',
      'fr': "Vérifier la pièce d'identité",
      'ht': 'Verifye kat idantite',
    },
    'profileLanguage': {'en': 'Language', 'fr': 'Langue', 'ht': 'Lang'},
    'logOut': {'en': 'Log out', 'fr': 'Se déconnecter', 'ht': 'Dekonekte'},
  };
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'fr', 'ht'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
