// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Wonn';

  @override
  String greeting(String name) {
    return 'Bonjour, $name';
  }

  @override
  String get trustScoreSuffix => 'confiance';

  @override
  String get alertsTitle => 'Alertes';

  @override
  String get alertsEmpty => 'Aucune alerte pour le moment';

  @override
  String get profileTitle => 'Profil';

  @override
  String get profileTrustScore => 'Score de confiance';

  @override
  String get profileCompletedCycles => 'Complétés';

  @override
  String get profileDisputes => 'Litiges';

  @override
  String get profileVerifyPhone => 'Vérifier téléphone';

  @override
  String get profileVerifyId => 'Vérifier identité';

  @override
  String get profileLanguage => 'Langue';

  @override
  String get logOut => 'Se déconnecter';

  @override
  String get wheelGroupExample => 'Groupe exemple';

  @override
  String get wheelSectionLabel => 'Votre prochaine contribution';

  @override
  String get yourTurn => 'C\'est votre tour !';

  @override
  String confirmedCount(int confirmed, int total) {
    return '$confirmed/$total confirmés';
  }

  @override
  String get createSolTitle => 'Créer un groupe';

  @override
  String get fieldName => 'Nom du groupe';

  @override
  String get fieldNameHint => 'ex. Club d\'épargne mensuel';

  @override
  String get validationNameRequired => 'Le nom du groupe est requis';

  @override
  String get fieldDescription => 'Description';

  @override
  String get fieldDescriptionHint => 'À quoi sert ce groupe ?';

  @override
  String get fieldAmount => 'Montant de contribution';

  @override
  String get fieldAmountHint => '0.00';

  @override
  String get validationAmountRequired => 'Le montant est requis';

  @override
  String get validationAmountInvalid => 'Veuillez entrer un montant valide';

  @override
  String get fieldFrequency => 'Fréquence de contribution';

  @override
  String get freqWeekly => 'Hebdomadaire';

  @override
  String get freqBiweekly => 'Bi-hebdomadaire';

  @override
  String get freqMonthly => 'Mensuel';

  @override
  String get fieldMembers => 'Nombre de membres';

  @override
  String get fieldMembersHint => 'ex. 8';

  @override
  String get validationMembersRequired => 'Le nombre de membres est requis';

  @override
  String get validationMembersInvalid => 'Veuillez entrer un nombre valide';

  @override
  String get fieldStartDate => 'Date de début';

  @override
  String get submitCreate => 'Créer le groupe';

  @override
  String get paywallTitle => 'Passer à Premium';

  @override
  String get paywallBody =>
      'Vous ne pouvez créer qu\'un groupe avec un compte gratuit. Passez à Premium pour créer des groupes illimités.';

  @override
  String get paywallPlanName => 'Abonnement Premium';

  @override
  String get paywallCta => 'Passer à Premium';

  @override
  String get inviteMessageIntro => 'Rejoignez mon groupe';

  @override
  String get inviteMessageAmountLabel => 'Montant de contribution';

  @override
  String get inviteMessageFrequencyLabel => 'Fréquence';

  @override
  String get inviteMessageStartLabel => 'Date de début';

  @override
  String get inviteMessageJoinLabel => 'Rejoignez le groupe ici';

  @override
  String get inviteSheetTitle => 'Inviter des membres';

  @override
  String get inviteSheetSubtitle =>
      'Partagez ce message avec les membres de votre groupe';

  @override
  String get shareInvite => 'Partager l\'invitation';

  @override
  String get later => 'Plus tard';

  @override
  String get groupsTitle => 'Groupes';

  @override
  String get groupsEmpty => 'Vous n\'avez rejoint aucun groupe';

  @override
  String turnCounter(int current, int total) {
    return '$current/$total';
  }

  @override
  String get currentTurnLabel => 'TOUR ACTUEL';

  @override
  String get activeGroups => 'Groupes actifs';

  @override
  String get seeAll => 'Voir tout';

  @override
  String get statusPending => 'En attente';

  @override
  String get statusUpToDate => 'À jour';

  @override
  String get statusDispute => 'Litige';

  @override
  String get quickActions => 'Actions rapides';

  @override
  String get createSol => 'Créer un Sol';

  @override
  String get iPaid => 'J\'ai payé';
}
