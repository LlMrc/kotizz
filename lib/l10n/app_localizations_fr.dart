// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Kotizz';

  @override
  String get homeNavLabel => 'Accueil';

  @override
  String greeting(String name) {
    return 'Bonjour, $name';
  }

  @override
  String get welcomeSubtitle => 'Bienvenue sur Kotizz';

  @override
  String get trustScoreSuffix => 'confiance';

  @override
  String get globalSavingsTitle => 'ÉPARGNE GLOBALE';

  @override
  String activeTontinesCount(int count) {
    return '$count tontines actives';
  }

  @override
  String get nextPotTitle => 'PROCHAIN POT';

  @override
  String nextPotReceivedSub(String date, String recipient) {
    return 'Reçu le $date ($recipient)';
  }

  @override
  String get trustScoreTitle => 'SCORE CONFIANCE';

  @override
  String get verifiedStatus => 'Statut Vérifié ✓';

  @override
  String get featuredTontine => 'TONTINE VEDETTE';

  @override
  String turnIndicator(int current, int total) {
    return 'TOUR $current/$total';
  }

  @override
  String get alertsTitle => 'Alertes';

  @override
  String get alertsEmpty => 'Aucune alerte pour le moment';

  @override
  String unreadAlertsCount(int count) {
    return '$count notifications non lues';
  }

  @override
  String get markAllRead => 'Tout lire';

  @override
  String get filterAll => 'Toutes';

  @override
  String get filterActive => 'Actives';

  @override
  String get filterCompleted => 'Terminées';

  @override
  String get filterUnread => 'Non lues';

  @override
  String get filterContributions => 'Cotisations';

  @override
  String get timeJustNow => 'À l\'instant';

  @override
  String timeMinutesAgo(int minutes) {
    return 'Il y a $minutes min';
  }

  @override
  String timeHoursAgo(int hours) {
    return 'Il y a $hours h';
  }

  @override
  String get timeYesterday => 'Hier';

  @override
  String timeDaysAgo(int days) {
    return 'Il y a $days jours';
  }

  @override
  String timeWeeksAgo(int weeks) {
    return 'Il y a $weeks sem.';
  }

  @override
  String timeMonthsAgo(int months) {
    return 'Il y a $months mois';
  }

  @override
  String timeYearsAgo(int years) {
    return 'Il y a $years an(s)';
  }

  @override
  String get dateToday => 'Aujourd\'hui';

  @override
  String get dateThisWeek => 'Cette semaine';

  @override
  String get dateThisMonth => 'Ce mois-ci';

  @override
  String get dateOlder => 'Plus ancien';

  @override
  String get profileTitle => 'Profil';

  @override
  String get profileTrustScore => 'Score de confiance';

  @override
  String get profileCompletedCycles => 'Complétés';

  @override
  String get profileDisputes => 'Litiges';

  @override
  String get sectionSecurity => 'VÉRIFICATIONS ET SÉCURITÉ';

  @override
  String get sectionSettings => 'PARAMÈTRES DU COMPTE';

  @override
  String get phoneVerified => 'Téléphone vérifié';

  @override
  String get identityVerified => 'Pièce d\'identité';

  @override
  String get bankAccount => 'Compte bancaire / MonCash';

  @override
  String get appLanguage => 'Langue de l\'application';

  @override
  String get pushNotifications => 'Notifications push';

  @override
  String get privacySecurity => 'Confidentialité et sécurité';

  @override
  String get termsOfService => 'Conditions d\'utilisation';

  @override
  String get cyclesUnit => 'cycles';

  @override
  String get badgeFree => 'Gratuit';

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
  String get optional => 'Optionnel';

  @override
  String get whatsappGroupLink => 'Lien du groupe WhatsApp';

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
  String registeredGroupsCount(int count) {
    return '$count tontines enregistrées';
  }

  @override
  String get noGroupsFound => 'Aucune tontine trouvée';

  @override
  String get createFirstGroupPrompt =>
      'Créez votre première tontine pour commencer';

  @override
  String get openWhatsAppGroup => 'Ouvrir le groupe WhatsApp';

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

  @override
  String get authTagline => 'L\'épargne collective, simplifiée.';

  @override
  String get authWelcome => 'Bienvenue !';

  @override
  String get authApplePrompt =>
      'Connectez-vous en un instant avec votre compte Apple.';

  @override
  String get continueWithApple => 'Continuer avec Apple';

  @override
  String get orEmail => 'OU PAR EMAIL';

  @override
  String get emailAddressLabel => 'Votre adresse email';

  @override
  String get emailHint => 'nom@exemple.com';

  @override
  String get sendLoginCode => 'Envoyer le code de connexion';

  @override
  String get enterEmailCodePrompt => 'Entrez le code reçu par email :';

  @override
  String get validateMyCode => 'Valider mon code';

  @override
  String get resendCode => 'Renvoyer';

  @override
  String get changeEmail => 'Changer d\'email';

  @override
  String get joinSol => 'Rejoindre une Sòl';

  @override
  String get joinWithCode => 'Rejoindre avec un code';

  @override
  String get inviteCode => 'Code d\'invitation';

  @override
  String get enterInviteCodePrompt =>
      'Entrez le code à 6 caractères pour rejoindre la tontine';

  @override
  String get joinGroupAction => 'Rejoindre la tontine';

  @override
  String get groupJoinedSuccess => 'Vous avez rejoint la tontine avec succès !';

  @override
  String get invalidInviteCode => 'Code d\'invitation invalide ou introuvable';

  @override
  String get alreadyMember => 'Vous êtes déjà membre de ce groupe';

  @override
  String get groupFull => 'Cette tontine est déjà complète';

  @override
  String get inviteMembers => 'Inviter des membres';

  @override
  String get copyCode => 'Copier le code';

  @override
  String get codeCopied => 'Code copié dans le presse-papiers !';

  @override
  String get freeSlot => 'Place libre';

  @override
  String get payoutSchedule => 'CALENDRIER ET ORDRE DES TOURS';

  @override
  String get youBadge => 'VOUS';

  @override
  String get potReceived => 'Pot perçu ✓';

  @override
  String get currentTurnBeneficiary => 'Bénéficiaire du tour actuel';

  @override
  String get waitingTurn => 'En attente';
}
