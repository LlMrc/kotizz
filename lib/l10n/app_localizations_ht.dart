// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Haitian Haitian Creole (`ht`).
class AppLocalizationsHt extends AppLocalizations {
  AppLocalizationsHt([String locale = 'ht']) : super(locale);

  @override
  String get appTitle => 'Kotizz';

  @override
  String get homeNavLabel => 'Akèy';

  @override
  String greeting(String name) {
    return 'Bonjou, $name';
  }

  @override
  String get welcomeSubtitle => 'Byenveni sou Kotizz';

  @override
  String get trustScoreSuffix => 'kofyans';

  @override
  String get globalSavingsTitle => 'EKONOMI TOTAL';

  @override
  String activeTontinesCount(int count) {
    return '$count sòl aktif';
  }

  @override
  String get nextPotTitle => 'PWOCHÈN KÒB LA';

  @override
  String nextPotReceivedSub(String date, String recipient) {
    return 'Resevwa $date ($recipient)';
  }

  @override
  String get trustScoreTitle => 'NÒT KOFYANS';

  @override
  String get verifiedStatus => 'Estati Verifye ✓';

  @override
  String get featuredTontine => 'SÒL VEDÈT';

  @override
  String turnIndicator(int current, int total) {
    return 'VIRE $current/$total';
  }

  @override
  String get alertsTitle => 'Notifikasyon';

  @override
  String get alertsEmpty => 'Pa gen avètisman nan moman sa';

  @override
  String unreadAlertsCount(int count) {
    return '$count notifikasyon ki pa li';
  }

  @override
  String get markAllRead => 'Li tout';

  @override
  String get filterAll => 'Tout';

  @override
  String get filterActive => 'Aktif';

  @override
  String get filterCompleted => 'Fini';

  @override
  String get filterUnread => 'Pa li';

  @override
  String get filterContributions => 'Kotizasyon';

  @override
  String get timeJustNow => 'Kounye a';

  @override
  String timeMinutesAgo(int minutes) {
    return 'Sa gen $minutes min';
  }

  @override
  String timeHoursAgo(int hours) {
    return 'Sa gen $hours èdtan';
  }

  @override
  String get timeYesterday => 'Yè';

  @override
  String timeDaysAgo(int days) {
    return 'Sa gen $days jou';
  }

  @override
  String timeWeeksAgo(int weeks) {
    return 'Sa gen $weeks semèn';
  }

  @override
  String timeMonthsAgo(int months) {
    return 'Sa gen $months mwa';
  }

  @override
  String timeYearsAgo(int years) {
    return 'Sa gen $years lane';
  }

  @override
  String get dateToday => 'Jodi a';

  @override
  String get dateThisWeek => 'Semèn sa a';

  @override
  String get dateThisMonth => 'Mwa sa a';

  @override
  String get dateOlder => 'Pi ansyen';

  @override
  String get profileTitle => 'Pwofil';

  @override
  String get profileTrustScore => 'Nòt kofyans';

  @override
  String get profileCompletedCycles => 'Finalize';

  @override
  String get profileDisputes => 'Dispit';

  @override
  String get sectionSecurity => 'VERIFIKASYON AK SEKIRITE';

  @override
  String get sectionSettings => 'PARAMÈT KONT LA';

  @override
  String get phoneVerified => 'Telefòn verifye';

  @override
  String get identityVerified => 'Pyès idantite';

  @override
  String get bankAccount => 'Kont labank / MonCash';

  @override
  String get appLanguage => 'Lang aplikasyon an';

  @override
  String get pushNotifications => 'Notifikasyon push';

  @override
  String get privacySecurity => 'Konfidansyalite ak sekirite';

  @override
  String get termsOfService => 'Kondisyon itilizasyon';

  @override
  String get cyclesUnit => 'sik';

  @override
  String get badgeFree => 'Gratis';

  @override
  String get profileVerifyPhone => 'Verifye telefòn';

  @override
  String get profileVerifyId => 'Verifye idantite';

  @override
  String get profileLanguage => 'Lang';

  @override
  String get logOut => 'Dekonekte';

  @override
  String get wheelGroupExample => 'Gwoup egzanp';

  @override
  String get wheelSectionLabel => 'Pwochèn kontribisyon ou';

  @override
  String get yourTurn => 'Se vire ou !';

  @override
  String confirmedCount(int confirmed, int total) {
    return '$confirmed/$total konfime';
  }

  @override
  String get createSolTitle => 'Kreye yon sòl';

  @override
  String get fieldName => 'Non sòl la';

  @override
  String get fieldNameHint => 'egz. Klib ekonomi chak mwa';

  @override
  String get validationNameRequired => 'Non sòl la obligatwa';

  @override
  String get fieldDescription => 'Deskripsyon';

  @override
  String get fieldDescriptionHint => 'Kisa sòl sa a ye?';

  @override
  String get fieldAmount => 'Montan kontribisyon';

  @override
  String get fieldAmountHint => '0.00';

  @override
  String get validationAmountRequired => 'Montan an obligatwa';

  @override
  String get validationAmountInvalid => 'Tanpri antre yon montan valid';

  @override
  String get fieldFrequency => 'Frekans kontribisyon';

  @override
  String get freqWeekly => 'Chak semèn';

  @override
  String get freqBiweekly => 'Chak de semèn';

  @override
  String get freqMonthly => 'Chak mwa';

  @override
  String get fieldMembers => 'Kantite manm';

  @override
  String get fieldMembersHint => 'egz. 8';

  @override
  String get validationMembersRequired => 'Kantite manm obligatwa';

  @override
  String get validationMembersInvalid => 'Tanpri antre yon nimewo valid';

  @override
  String get fieldStartDate => 'Dat kòmansman';

  @override
  String get optional => 'Opsyonèl';

  @override
  String get whatsappGroupLink => 'Lyen gwoup WhatsApp la';

  @override
  String get submitCreate => 'Kreye sòl la';

  @override
  String get paywallTitle => 'Pase a Premium';

  @override
  String get paywallBody =>
      'Ou ka sèlman kreye yon sèl gwoup ak yon kont gratis. Pase a Premium pou kreye gwoup san limit.';

  @override
  String get paywallPlanName => 'Plan Premium';

  @override
  String get paywallCta => 'Pase a Premium';

  @override
  String get inviteMessageIntro => 'Rantre nan sòl mwen an';

  @override
  String get inviteMessageAmountLabel => 'Montan kontribisyon';

  @override
  String get inviteMessageFrequencyLabel => 'Frekans';

  @override
  String get inviteMessageStartLabel => 'Dat kòmansman';

  @override
  String get inviteMessageJoinLabel => 'Rantre nan sòl la isit';

  @override
  String get inviteSheetTitle => 'Envite manm';

  @override
  String get inviteSheetSubtitle => 'Pataje mesaj sa a ak lòt manm yo';

  @override
  String get shareInvite => 'Pataje envitasyon';

  @override
  String get later => 'Pita';

  @override
  String get groupsTitle => 'Sòl yo';

  @override
  String get groupsEmpty => 'Ou pa rantre nan okenn sòl pou kounye a';

  @override
  String registeredGroupsCount(int count) {
    return '$count sòl anrejistre';
  }

  @override
  String get noGroupsFound => 'Nou pa jwenn okenn sòl';

  @override
  String get createFirstGroupPrompt => 'Kreye premye sòl ou pou w kòmanse';

  @override
  String get openWhatsAppGroup => 'Louvri gwoup WhatsApp la';

  @override
  String turnCounter(int current, int total) {
    return '$current/$total';
  }

  @override
  String get currentTurnLabel => 'VIRE AKTYÈL';

  @override
  String get activeGroups => 'Sòl aktif';

  @override
  String get seeAll => 'Gade tout';

  @override
  String get statusPending => 'Tann';

  @override
  String get statusUpToDate => 'A jou';

  @override
  String get statusDispute => 'Dispit';

  @override
  String get quickActions => 'Aksyon rapid';

  @override
  String get createSol => 'Kreye Sòl';

  @override
  String get iPaid => 'Mwen peye';

  @override
  String get authTagline => 'Ekonomi an gwoup, san tèt chaje.';

  @override
  String get authWelcome => 'Byenveni !';

  @override
  String get authApplePrompt => 'Konekte rapidman ak kont Apple ou.';

  @override
  String get continueWithApple => 'Kontinye ak Apple';

  @override
  String get orEmail => 'OSWA PA IMÈL';

  @override
  String get emailAddressLabel => 'Adrès imèl ou';

  @override
  String get emailHint => 'non@egzanp.com';

  @override
  String get sendLoginCode => 'Voye kòd koneksyon an';

  @override
  String get enterEmailCodePrompt => 'Antre kòd ou resevwa pa imèl la :';

  @override
  String get validateMyCode => 'Valide kòd mwen';

  @override
  String get resendCode => 'Voye ankò';

  @override
  String get changeEmail => 'Chanje imèl';
}
