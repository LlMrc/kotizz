// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Haitian Haitian Creole (`ht`).
class AppLocalizationsHt extends AppLocalizations {
  AppLocalizationsHt([String locale = 'ht']) : super(locale);

  @override
  String get appTitle => 'Wonn';

  @override
  String greeting(String name) {
    return 'Bonjou, $name';
  }

  @override
  String get trustScoreSuffix => 'kofyans';

  @override
  String get alertsTitle => 'Avètisman';

  @override
  String get alertsEmpty => 'Pa gen avètisman nan moman sa';

  @override
  String get profileTitle => 'Pwofil';

  @override
  String get profileTrustScore => 'Nòt kofyans';

  @override
  String get profileCompletedCycles => 'Finalize';

  @override
  String get profileDisputes => 'Dispit';

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
  String get createSolTitle => 'Kreye yon gwoup';

  @override
  String get fieldName => 'Non gwoup';

  @override
  String get fieldNameHint => 'egz. Klib ekonomi chak mwa';

  @override
  String get validationNameRequired => 'Non gwoup la oblije';

  @override
  String get fieldDescription => 'Deskripsyon';

  @override
  String get fieldDescriptionHint => 'Kisa gwoup sa ye?';

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
  String get fieldMembers => 'Nimewo manm';

  @override
  String get fieldMembersHint => 'egz. 8';

  @override
  String get validationMembersRequired => 'Nimewo manm la obligatwa';

  @override
  String get validationMembersInvalid => 'Tanpri antre yon nimewo valid';

  @override
  String get fieldStartDate => 'Dat kòmansman';

  @override
  String get submitCreate => 'Kreye gwoup';

  @override
  String get paywallTitle => 'Pase a Premium';

  @override
  String get paywallBody =>
      'Ou ka kreye se yon gwoup ak yon kont gratis. Pase a Premium pou kreye gwoup san limit.';

  @override
  String get paywallPlanName => 'Plan Premium';

  @override
  String get paywallCta => 'Pase a Premium';

  @override
  String get inviteMessageIntro => 'Rantre nan gwoup mwen';

  @override
  String get inviteMessageAmountLabel => 'Montan kontribisyon';

  @override
  String get inviteMessageFrequencyLabel => 'Frekans';

  @override
  String get inviteMessageStartLabel => 'Dat kòmansman';

  @override
  String get inviteMessageJoinLabel => 'Rantre nan gwoup la isit';

  @override
  String get inviteSheetTitle => 'Envite manm';

  @override
  String get inviteSheetSubtitle => 'Pataje mesaj sa a ak manm gwoup ou';

  @override
  String get shareInvite => 'Pataje envitasyon';

  @override
  String get later => 'Pita';

  @override
  String get groupsTitle => 'Gwoup';

  @override
  String get groupsEmpty => 'Ou pa rantre nan okenn gwoup';

  @override
  String turnCounter(int current, int total) {
    return '$current/$total';
  }

  @override
  String get currentTurnLabel => 'VIRE AKTYÈL';

  @override
  String get activeGroups => 'Gwoup aktif';

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
  String get createSol => 'Kreye Sol';

  @override
  String get iPaid => 'M peye';
}
