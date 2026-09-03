import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ht.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
    Locale('ht'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Kotizz'**
  String get appTitle;

  /// No description provided for @homeNavLabel.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeNavLabel;

  /// Greeting message with user name
  ///
  /// In en, this message translates to:
  /// **'Hey, {name}'**
  String greeting(String name);

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Kotizz'**
  String get welcomeSubtitle;

  /// No description provided for @trustScoreSuffix.
  ///
  /// In en, this message translates to:
  /// **'trust'**
  String get trustScoreSuffix;

  /// No description provided for @globalSavingsTitle.
  ///
  /// In en, this message translates to:
  /// **'GLOBAL SAVINGS'**
  String get globalSavingsTitle;

  /// No description provided for @activeTontinesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} active groups'**
  String activeTontinesCount(int count);

  /// No description provided for @nextPotTitle.
  ///
  /// In en, this message translates to:
  /// **'NEXT POT'**
  String get nextPotTitle;

  /// No description provided for @nextPotReceivedSub.
  ///
  /// In en, this message translates to:
  /// **'Received on {date} ({recipient})'**
  String nextPotReceivedSub(String date, String recipient);

  /// No description provided for @trustScoreTitle.
  ///
  /// In en, this message translates to:
  /// **'TRUST SCORE'**
  String get trustScoreTitle;

  /// No description provided for @verifiedStatus.
  ///
  /// In en, this message translates to:
  /// **'Verified Status ✓'**
  String get verifiedStatus;

  /// No description provided for @featuredTontine.
  ///
  /// In en, this message translates to:
  /// **'FEATURED GROUP'**
  String get featuredTontine;

  /// No description provided for @turnIndicator.
  ///
  /// In en, this message translates to:
  /// **'TURN {current}/{total}'**
  String turnIndicator(int current, int total);

  /// No description provided for @alertsTitle.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get alertsTitle;

  /// No description provided for @alertsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No alerts at the moment'**
  String get alertsEmpty;

  /// No description provided for @unreadAlertsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} unread notifications'**
  String unreadAlertsCount(int count);

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Read all'**
  String get markAllRead;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get filterActive;

  /// No description provided for @filterCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get filterCompleted;

  /// No description provided for @filterUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get filterUnread;

  /// No description provided for @filterContributions.
  ///
  /// In en, this message translates to:
  /// **'Contributions'**
  String get filterContributions;

  /// No description provided for @timeJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min ago'**
  String timeMinutesAgo(int minutes);

  /// No description provided for @timeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours} h ago'**
  String timeHoursAgo(int hours);

  /// No description provided for @timeYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get timeYesterday;

  /// No description provided for @timeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days} days ago'**
  String timeDaysAgo(int days);

  /// No description provided for @timeWeeksAgo.
  ///
  /// In en, this message translates to:
  /// **'{weeks} w. ago'**
  String timeWeeksAgo(int weeks);

  /// No description provided for @timeMonthsAgo.
  ///
  /// In en, this message translates to:
  /// **'{months} mo. ago'**
  String timeMonthsAgo(int months);

  /// No description provided for @timeYearsAgo.
  ///
  /// In en, this message translates to:
  /// **'{years} yr. ago'**
  String timeYearsAgo(int years);

  /// No description provided for @dateToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dateToday;

  /// No description provided for @dateThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get dateThisWeek;

  /// No description provided for @dateThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get dateThisMonth;

  /// No description provided for @dateOlder.
  ///
  /// In en, this message translates to:
  /// **'Older'**
  String get dateOlder;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileTrustScore.
  ///
  /// In en, this message translates to:
  /// **'Trust Score'**
  String get profileTrustScore;

  /// No description provided for @profileCompletedCycles.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get profileCompletedCycles;

  /// No description provided for @profileDisputes.
  ///
  /// In en, this message translates to:
  /// **'Disputes'**
  String get profileDisputes;

  /// No description provided for @sectionSecurity.
  ///
  /// In en, this message translates to:
  /// **'VERIFICATIONS & SECURITY'**
  String get sectionSecurity;

  /// No description provided for @sectionSettings.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT SETTINGS'**
  String get sectionSettings;

  /// No description provided for @phoneVerified.
  ///
  /// In en, this message translates to:
  /// **'Phone verified'**
  String get phoneVerified;

  /// No description provided for @identityVerified.
  ///
  /// In en, this message translates to:
  /// **'ID Card / Passport'**
  String get identityVerified;

  /// No description provided for @bankAccount.
  ///
  /// In en, this message translates to:
  /// **'Bank Account / MonCash'**
  String get bankAccount;

  /// No description provided for @appLanguage.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get appLanguage;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push notifications'**
  String get pushNotifications;

  /// No description provided for @privacySecurity.
  ///
  /// In en, this message translates to:
  /// **'Privacy and security'**
  String get privacySecurity;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @cyclesUnit.
  ///
  /// In en, this message translates to:
  /// **'cycles'**
  String get cyclesUnit;

  /// No description provided for @badgeFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get badgeFree;

  /// No description provided for @profileVerifyPhone.
  ///
  /// In en, this message translates to:
  /// **'Verify Phone'**
  String get profileVerifyPhone;

  /// No description provided for @profileVerifyId.
  ///
  /// In en, this message translates to:
  /// **'Verify ID'**
  String get profileVerifyId;

  /// No description provided for @profileLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profileLanguage;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOut;

  /// No description provided for @wheelGroupExample.
  ///
  /// In en, this message translates to:
  /// **'Example Group'**
  String get wheelGroupExample;

  /// No description provided for @wheelSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Your next contribution'**
  String get wheelSectionLabel;

  /// No description provided for @yourTurn.
  ///
  /// In en, this message translates to:
  /// **'It\'s your turn!'**
  String get yourTurn;

  /// No description provided for @confirmedCount.
  ///
  /// In en, this message translates to:
  /// **'{confirmed}/{total} confirmed'**
  String confirmedCount(int confirmed, int total);

  /// No description provided for @createSolTitle.
  ///
  /// In en, this message translates to:
  /// **'Create a Group'**
  String get createSolTitle;

  /// No description provided for @fieldName.
  ///
  /// In en, this message translates to:
  /// **'Group Name'**
  String get fieldName;

  /// No description provided for @fieldNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Monthly Savings Club'**
  String get fieldNameHint;

  /// No description provided for @validationNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Group name is required'**
  String get validationNameRequired;

  /// No description provided for @fieldDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get fieldDescription;

  /// No description provided for @fieldDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'What is this group for?'**
  String get fieldDescriptionHint;

  /// No description provided for @fieldAmount.
  ///
  /// In en, this message translates to:
  /// **'Contribution Amount'**
  String get fieldAmount;

  /// No description provided for @fieldAmountHint.
  ///
  /// In en, this message translates to:
  /// **'0.00'**
  String get fieldAmountHint;

  /// No description provided for @validationAmountRequired.
  ///
  /// In en, this message translates to:
  /// **'Amount is required'**
  String get validationAmountRequired;

  /// No description provided for @validationAmountInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount'**
  String get validationAmountInvalid;

  /// No description provided for @fieldFrequency.
  ///
  /// In en, this message translates to:
  /// **'Contribution Frequency'**
  String get fieldFrequency;

  /// No description provided for @freqWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get freqWeekly;

  /// No description provided for @freqBiweekly.
  ///
  /// In en, this message translates to:
  /// **'Bi-weekly'**
  String get freqBiweekly;

  /// No description provided for @freqMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get freqMonthly;

  /// No description provided for @fieldMembers.
  ///
  /// In en, this message translates to:
  /// **'Number of Members'**
  String get fieldMembers;

  /// No description provided for @fieldMembersHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 8'**
  String get fieldMembersHint;

  /// No description provided for @validationMembersRequired.
  ///
  /// In en, this message translates to:
  /// **'Number of members is required'**
  String get validationMembersRequired;

  /// No description provided for @validationMembersInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get validationMembersInvalid;

  /// No description provided for @fieldStartDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get fieldStartDate;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @whatsappGroupLink.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp group link'**
  String get whatsappGroupLink;

  /// No description provided for @submitCreate.
  ///
  /// In en, this message translates to:
  /// **'Create Group'**
  String get submitCreate;

  /// No description provided for @paywallTitle.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Premium'**
  String get paywallTitle;

  /// No description provided for @paywallBody.
  ///
  /// In en, this message translates to:
  /// **'You can only create one group with a free account. Upgrade to Premium to create unlimited groups.'**
  String get paywallBody;

  /// No description provided for @paywallPlanName.
  ///
  /// In en, this message translates to:
  /// **'Premium Plan'**
  String get paywallPlanName;

  /// No description provided for @paywallCta.
  ///
  /// In en, this message translates to:
  /// **'Upgrade Now'**
  String get paywallCta;

  /// No description provided for @inviteMessageIntro.
  ///
  /// In en, this message translates to:
  /// **'Join my group'**
  String get inviteMessageIntro;

  /// No description provided for @inviteMessageAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Contribution Amount'**
  String get inviteMessageAmountLabel;

  /// No description provided for @inviteMessageFrequencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get inviteMessageFrequencyLabel;

  /// No description provided for @inviteMessageStartLabel.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get inviteMessageStartLabel;

  /// No description provided for @inviteMessageJoinLabel.
  ///
  /// In en, this message translates to:
  /// **'Join the group here'**
  String get inviteMessageJoinLabel;

  /// No description provided for @inviteSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite Members'**
  String get inviteSheetTitle;

  /// No description provided for @inviteSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share this message with your group members'**
  String get inviteSheetSubtitle;

  /// No description provided for @shareInvite.
  ///
  /// In en, this message translates to:
  /// **'Share Invite'**
  String get shareInvite;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @groupsTitle.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get groupsTitle;

  /// No description provided for @groupsEmpty.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t joined any groups yet'**
  String get groupsEmpty;

  /// No description provided for @registeredGroupsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} registered groups'**
  String registeredGroupsCount(int count);

  /// No description provided for @noGroupsFound.
  ///
  /// In en, this message translates to:
  /// **'No groups found'**
  String get noGroupsFound;

  /// No description provided for @createFirstGroupPrompt.
  ///
  /// In en, this message translates to:
  /// **'Create your first group to get started'**
  String get createFirstGroupPrompt;

  /// No description provided for @openWhatsAppGroup.
  ///
  /// In en, this message translates to:
  /// **'Open WhatsApp group'**
  String get openWhatsAppGroup;

  /// No description provided for @turnCounter.
  ///
  /// In en, this message translates to:
  /// **'{current}/{total}'**
  String turnCounter(int current, int total);

  /// No description provided for @currentTurnLabel.
  ///
  /// In en, this message translates to:
  /// **'CURRENT TURN'**
  String get currentTurnLabel;

  /// No description provided for @activeGroups.
  ///
  /// In en, this message translates to:
  /// **'Active Groups'**
  String get activeGroups;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Up to date'**
  String get statusUpToDate;

  /// No description provided for @statusDispute.
  ///
  /// In en, this message translates to:
  /// **'Dispute'**
  String get statusDispute;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @createSol.
  ///
  /// In en, this message translates to:
  /// **'Create Sol'**
  String get createSol;

  /// No description provided for @iPaid.
  ///
  /// In en, this message translates to:
  /// **'I Paid'**
  String get iPaid;

  /// No description provided for @authTagline.
  ///
  /// In en, this message translates to:
  /// **'Collective savings, simplified.'**
  String get authTagline;

  /// No description provided for @authWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome!'**
  String get authWelcome;

  /// No description provided for @authApplePrompt.
  ///
  /// In en, this message translates to:
  /// **'Sign in instantly with your Apple account.'**
  String get authApplePrompt;

  /// No description provided for @continueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// No description provided for @orEmail.
  ///
  /// In en, this message translates to:
  /// **'OR BY EMAIL'**
  String get orEmail;

  /// No description provided for @emailAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Your email address'**
  String get emailAddressLabel;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'name@example.com'**
  String get emailHint;

  /// No description provided for @sendLoginCode.
  ///
  /// In en, this message translates to:
  /// **'Send login code'**
  String get sendLoginCode;

  /// No description provided for @enterEmailCodePrompt.
  ///
  /// In en, this message translates to:
  /// **'Enter the code received by email:'**
  String get enterEmailCodePrompt;

  /// No description provided for @validateMyCode.
  ///
  /// In en, this message translates to:
  /// **'Verify my code'**
  String get validateMyCode;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get resendCode;

  /// No description provided for @changeEmail.
  ///
  /// In en, this message translates to:
  /// **'Change email'**
  String get changeEmail;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr', 'ht'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
    case 'ht':
      return AppLocalizationsHt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
