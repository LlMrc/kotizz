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

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Kotizz'**
  String get appTitle;

  /// Greeting message with user name
  ///
  /// In en, this message translates to:
  /// **'Hey, {name}'**
  String greeting(String name);

  /// Suffix for trust score display
  ///
  /// In en, this message translates to:
  /// **'trust'**
  String get trustScoreSuffix;

  /// Title for alerts screen
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get alertsTitle;

  /// Message when there are no alerts
  ///
  /// In en, this message translates to:
  /// **'No alerts at the moment'**
  String get alertsEmpty;

  /// Title for profile screen
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// Label for trust score stat
  ///
  /// In en, this message translates to:
  /// **'Trust Score'**
  String get profileTrustScore;

  /// Label for completed cycles stat
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get profileCompletedCycles;

  /// Label for disputes stat
  ///
  /// In en, this message translates to:
  /// **'Disputes'**
  String get profileDisputes;

  /// Action to verify phone number
  ///
  /// In en, this message translates to:
  /// **'Verify Phone'**
  String get profileVerifyPhone;

  /// Action to verify ID
  ///
  /// In en, this message translates to:
  /// **'Verify ID'**
  String get profileVerifyId;

  /// Language selection label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profileLanguage;

  /// Button label to log out
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOut;

  /// Example group name on wheel card
  ///
  /// In en, this message translates to:
  /// **'Example Group'**
  String get wheelGroupExample;

  /// Label for wheel section
  ///
  /// In en, this message translates to:
  /// **'Your next contribution'**
  String get wheelSectionLabel;

  /// Message indicating it's the user's turn
  ///
  /// In en, this message translates to:
  /// **'It\'s your turn!'**
  String get yourTurn;

  /// Count of confirmed members
  ///
  /// In en, this message translates to:
  /// **'{confirmed}/{total} confirmed'**
  String confirmedCount(int confirmed, int total);

  /// Title for create group screen
  ///
  /// In en, this message translates to:
  /// **'Create a Group'**
  String get createSolTitle;

  /// Label for group name field
  ///
  /// In en, this message translates to:
  /// **'Group Name'**
  String get fieldName;

  /// Hint for group name field
  ///
  /// In en, this message translates to:
  /// **'e.g. Monthly Savings Club'**
  String get fieldNameHint;

  /// Validation error for missing group name
  ///
  /// In en, this message translates to:
  /// **'Group name is required'**
  String get validationNameRequired;

  /// Label for description field
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get fieldDescription;

  /// Hint for description field
  ///
  /// In en, this message translates to:
  /// **'What is this group for?'**
  String get fieldDescriptionHint;

  /// Label for contribution amount field
  ///
  /// In en, this message translates to:
  /// **'Contribution Amount'**
  String get fieldAmount;

  /// Hint for amount field
  ///
  /// In en, this message translates to:
  /// **'0.00'**
  String get fieldAmountHint;

  /// Validation error for missing amount
  ///
  /// In en, this message translates to:
  /// **'Amount is required'**
  String get validationAmountRequired;

  /// Validation error for invalid amount
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount'**
  String get validationAmountInvalid;

  /// Label for frequency field
  ///
  /// In en, this message translates to:
  /// **'Contribution Frequency'**
  String get fieldFrequency;

  /// Weekly frequency option
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get freqWeekly;

  /// Bi-weekly frequency option
  ///
  /// In en, this message translates to:
  /// **'Bi-weekly'**
  String get freqBiweekly;

  /// Monthly frequency option
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get freqMonthly;

  /// Label for members field
  ///
  /// In en, this message translates to:
  /// **'Number of Members'**
  String get fieldMembers;

  /// Hint for members field
  ///
  /// In en, this message translates to:
  /// **'e.g. 8'**
  String get fieldMembersHint;

  /// Validation error for missing members count
  ///
  /// In en, this message translates to:
  /// **'Number of members is required'**
  String get validationMembersRequired;

  /// Validation error for invalid members count
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get validationMembersInvalid;

  /// Label for start date field
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get fieldStartDate;

  /// Button label to create group
  ///
  /// In en, this message translates to:
  /// **'Create Group'**
  String get submitCreate;

  /// Title for paywall modal
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Premium'**
  String get paywallTitle;

  /// Body text for paywall modal
  ///
  /// In en, this message translates to:
  /// **'You can only create one group with a free account. Upgrade to Premium to create unlimited groups.'**
  String get paywallBody;

  /// Premium plan name
  ///
  /// In en, this message translates to:
  /// **'Premium Plan'**
  String get paywallPlanName;

  /// Call-to-action button for paywall
  ///
  /// In en, this message translates to:
  /// **'Upgrade Now'**
  String get paywallCta;

  /// Introduction to invite message
  ///
  /// In en, this message translates to:
  /// **'Join my group'**
  String get inviteMessageIntro;

  /// Label in invite message for amount
  ///
  /// In en, this message translates to:
  /// **'Contribution Amount'**
  String get inviteMessageAmountLabel;

  /// Label in invite message for frequency
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get inviteMessageFrequencyLabel;

  /// Label in invite message for start date
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get inviteMessageStartLabel;

  /// Label in invite message for joining
  ///
  /// In en, this message translates to:
  /// **'Join the group here'**
  String get inviteMessageJoinLabel;

  /// Title for invite sheet
  ///
  /// In en, this message translates to:
  /// **'Invite Members'**
  String get inviteSheetTitle;

  /// Subtitle for invite sheet
  ///
  /// In en, this message translates to:
  /// **'Share this message with your group members'**
  String get inviteSheetSubtitle;

  /// Button label to share invite
  ///
  /// In en, this message translates to:
  /// **'Share Invite'**
  String get shareInvite;

  /// Button label for later/dismiss action
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// Title for groups screen
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get groupsTitle;

  /// Message when there are no groups
  ///
  /// In en, this message translates to:
  /// **'You haven\'t joined any groups yet'**
  String get groupsEmpty;

  /// Counter showing current turn and total
  ///
  /// In en, this message translates to:
  /// **'{current}/{total}'**
  String turnCounter(int current, int total);

  /// Label indicating current turn
  ///
  /// In en, this message translates to:
  /// **'CURRENT TURN'**
  String get currentTurnLabel;

  /// Label for active groups section
  ///
  /// In en, this message translates to:
  /// **'Active Groups'**
  String get activeGroups;

  /// Link to see all items
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// Status badge for pending
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// Status badge for up to date
  ///
  /// In en, this message translates to:
  /// **'Up to date'**
  String get statusUpToDate;

  /// Status badge for dispute
  ///
  /// In en, this message translates to:
  /// **'Dispute'**
  String get statusDispute;

  /// Label for quick actions section
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// Action button to create a new Sol group
  ///
  /// In en, this message translates to:
  /// **'Create Sol'**
  String get createSol;

  /// Action button to mark payment
  ///
  /// In en, this message translates to:
  /// **'I Paid'**
  String get iPaid;
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
