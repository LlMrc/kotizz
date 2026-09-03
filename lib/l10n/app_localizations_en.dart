// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Kotizz';

  @override
  String get homeNavLabel => 'Home';

  @override
  String greeting(String name) {
    return 'Hey, $name';
  }

  @override
  String get welcomeSubtitle => 'Welcome to Kotizz';

  @override
  String get trustScoreSuffix => 'trust';

  @override
  String get globalSavingsTitle => 'GLOBAL SAVINGS';

  @override
  String activeTontinesCount(int count) {
    return '$count active groups';
  }

  @override
  String get nextPotTitle => 'NEXT POT';

  @override
  String nextPotReceivedSub(String date, String recipient) {
    return 'Received on $date ($recipient)';
  }

  @override
  String get trustScoreTitle => 'TRUST SCORE';

  @override
  String get verifiedStatus => 'Verified Status ✓';

  @override
  String get featuredTontine => 'FEATURED GROUP';

  @override
  String turnIndicator(int current, int total) {
    return 'TURN $current/$total';
  }

  @override
  String get alertsTitle => 'Alerts';

  @override
  String get alertsEmpty => 'No alerts at the moment';

  @override
  String unreadAlertsCount(int count) {
    return '$count unread notifications';
  }

  @override
  String get markAllRead => 'Read all';

  @override
  String get filterAll => 'All';

  @override
  String get filterActive => 'Active';

  @override
  String get filterCompleted => 'Completed';

  @override
  String get filterUnread => 'Unread';

  @override
  String get filterContributions => 'Contributions';

  @override
  String get timeJustNow => 'Just now';

  @override
  String timeMinutesAgo(int minutes) {
    return '$minutes min ago';
  }

  @override
  String timeHoursAgo(int hours) {
    return '$hours h ago';
  }

  @override
  String get timeYesterday => 'Yesterday';

  @override
  String timeDaysAgo(int days) {
    return '$days days ago';
  }

  @override
  String timeWeeksAgo(int weeks) {
    return '$weeks w. ago';
  }

  @override
  String timeMonthsAgo(int months) {
    return '$months mo. ago';
  }

  @override
  String timeYearsAgo(int years) {
    return '$years yr. ago';
  }

  @override
  String get dateToday => 'Today';

  @override
  String get dateThisWeek => 'This week';

  @override
  String get dateThisMonth => 'This month';

  @override
  String get dateOlder => 'Older';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileTrustScore => 'Trust Score';

  @override
  String get profileCompletedCycles => 'Completed';

  @override
  String get profileDisputes => 'Disputes';

  @override
  String get sectionSecurity => 'VERIFICATIONS & SECURITY';

  @override
  String get sectionSettings => 'ACCOUNT SETTINGS';

  @override
  String get phoneVerified => 'Phone verified';

  @override
  String get identityVerified => 'ID Card / Passport';

  @override
  String get bankAccount => 'Bank Account / MonCash';

  @override
  String get appLanguage => 'App Language';

  @override
  String get pushNotifications => 'Push notifications';

  @override
  String get privacySecurity => 'Privacy and security';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get cyclesUnit => 'cycles';

  @override
  String get badgeFree => 'Free';

  @override
  String get profileVerifyPhone => 'Verify Phone';

  @override
  String get profileVerifyId => 'Verify ID';

  @override
  String get profileLanguage => 'Language';

  @override
  String get logOut => 'Log Out';

  @override
  String get wheelGroupExample => 'Example Group';

  @override
  String get wheelSectionLabel => 'Your next contribution';

  @override
  String get yourTurn => 'It\'s your turn!';

  @override
  String confirmedCount(int confirmed, int total) {
    return '$confirmed/$total confirmed';
  }

  @override
  String get createSolTitle => 'Create a Group';

  @override
  String get fieldName => 'Group Name';

  @override
  String get fieldNameHint => 'e.g. Monthly Savings Club';

  @override
  String get validationNameRequired => 'Group name is required';

  @override
  String get fieldDescription => 'Description';

  @override
  String get fieldDescriptionHint => 'What is this group for?';

  @override
  String get fieldAmount => 'Contribution Amount';

  @override
  String get fieldAmountHint => '0.00';

  @override
  String get validationAmountRequired => 'Amount is required';

  @override
  String get validationAmountInvalid => 'Please enter a valid amount';

  @override
  String get fieldFrequency => 'Contribution Frequency';

  @override
  String get freqWeekly => 'Weekly';

  @override
  String get freqBiweekly => 'Bi-weekly';

  @override
  String get freqMonthly => 'Monthly';

  @override
  String get fieldMembers => 'Number of Members';

  @override
  String get fieldMembersHint => 'e.g. 8';

  @override
  String get validationMembersRequired => 'Number of members is required';

  @override
  String get validationMembersInvalid => 'Please enter a valid number';

  @override
  String get fieldStartDate => 'Start Date';

  @override
  String get optional => 'Optional';

  @override
  String get whatsappGroupLink => 'WhatsApp group link';

  @override
  String get submitCreate => 'Create Group';

  @override
  String get paywallTitle => 'Upgrade to Premium';

  @override
  String get paywallBody =>
      'You can only create one group with a free account. Upgrade to Premium to create unlimited groups.';

  @override
  String get paywallPlanName => 'Premium Plan';

  @override
  String get paywallCta => 'Upgrade Now';

  @override
  String get inviteMessageIntro => 'Join my group';

  @override
  String get inviteMessageAmountLabel => 'Contribution Amount';

  @override
  String get inviteMessageFrequencyLabel => 'Frequency';

  @override
  String get inviteMessageStartLabel => 'Start Date';

  @override
  String get inviteMessageJoinLabel => 'Join the group here';

  @override
  String get inviteSheetTitle => 'Invite Members';

  @override
  String get inviteSheetSubtitle =>
      'Share this message with your group members';

  @override
  String get shareInvite => 'Share Invite';

  @override
  String get later => 'Later';

  @override
  String get groupsTitle => 'Groups';

  @override
  String get groupsEmpty => 'You haven\'t joined any groups yet';

  @override
  String registeredGroupsCount(int count) {
    return '$count registered groups';
  }

  @override
  String get noGroupsFound => 'No groups found';

  @override
  String get createFirstGroupPrompt => 'Create your first group to get started';

  @override
  String get openWhatsAppGroup => 'Open WhatsApp group';

  @override
  String turnCounter(int current, int total) {
    return '$current/$total';
  }

  @override
  String get currentTurnLabel => 'CURRENT TURN';

  @override
  String get activeGroups => 'Active Groups';

  @override
  String get seeAll => 'See all';

  @override
  String get statusPending => 'Pending';

  @override
  String get statusUpToDate => 'Up to date';

  @override
  String get statusDispute => 'Dispute';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get createSol => 'Create Sol';

  @override
  String get iPaid => 'I Paid';

  @override
  String get authTagline => 'Collective savings, simplified.';

  @override
  String get authWelcome => 'Welcome!';

  @override
  String get authApplePrompt => 'Sign in instantly with your Apple account.';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get orEmail => 'OR BY EMAIL';

  @override
  String get emailAddressLabel => 'Your email address';

  @override
  String get emailHint => 'name@example.com';

  @override
  String get sendLoginCode => 'Send login code';

  @override
  String get enterEmailCodePrompt => 'Enter the code received by email:';

  @override
  String get validateMyCode => 'Verify my code';

  @override
  String get resendCode => 'Resend';

  @override
  String get changeEmail => 'Change email';
}
