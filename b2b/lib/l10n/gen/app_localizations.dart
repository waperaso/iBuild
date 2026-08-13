import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_uz.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('ru'),
    Locale('uz'),
  ];

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get commonAdd;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get commonSignOut;

  /// No description provided for @commonExit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get commonExit;

  /// No description provided for @logoutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get logoutConfirmTitle;

  /// No description provided for @logoutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'ll need to sign in again to access your account.'**
  String get logoutConfirmMessage;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin sign in'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Platform and residence administration'**
  String get loginSubtitle;

  /// No description provided for @loginPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get loginPhoneHint;

  /// No description provided for @loginSendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get loginSendCode;

  /// No description provided for @loginSendCodeError.
  ///
  /// In en, this message translates to:
  /// **'Could not send code. Try again.'**
  String get loginSendCodeError;

  /// No description provided for @loginRateLimitedError.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Wait {seconds}s and try again.'**
  String loginRateLimitedError(int seconds);

  /// No description provided for @signInDemo.
  ///
  /// In en, this message translates to:
  /// **'Sign in (demo)'**
  String get signInDemo;

  /// No description provided for @demoButton.
  ///
  /// In en, this message translates to:
  /// **'Demo'**
  String get demoButton;

  /// No description provided for @demoModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Demo mode'**
  String get demoModeTitle;

  /// No description provided for @demoModeMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'re in read-only demo mode. Open every project and screen and fetch live data — edits, publishes, and other changes are blocked and will not be saved.'**
  String get demoModeMessage;

  /// No description provided for @demoModeGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get demoModeGotIt;

  /// No description provided for @demoModeBanner.
  ///
  /// In en, this message translates to:
  /// **'Demo mode — view only, changes are not saved'**
  String get demoModeBanner;

  /// No description provided for @demoWriteBlocked.
  ///
  /// In en, this message translates to:
  /// **'Demo mode is view-only — this action was not saved.'**
  String get demoWriteBlocked;

  /// No description provided for @phoneHidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get phoneHidden;

  /// No description provided for @otpTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter code'**
  String get otpTitle;

  /// No description provided for @otpSentTo.
  ///
  /// In en, this message translates to:
  /// **'Sent to {phone}'**
  String otpSentTo(String phone);

  /// No description provided for @otpHint.
  ///
  /// In en, this message translates to:
  /// **'000000'**
  String get otpHint;

  /// No description provided for @otpDevHelper.
  ///
  /// In en, this message translates to:
  /// **'Test mode'**
  String get otpDevHelper;

  /// No description provided for @otpVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get otpVerify;

  /// No description provided for @otpInvalidError.
  ///
  /// In en, this message translates to:
  /// **'Invalid or expired code'**
  String get otpInvalidError;

  /// No description provided for @otpResendPrompt.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t get the code?'**
  String get otpResendPrompt;

  /// No description provided for @otpResendAction.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get otpResendAction;

  /// No description provided for @otpResendCountdown.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String otpResendCountdown(int seconds);

  /// No description provided for @otpResendSuccess.
  ///
  /// In en, this message translates to:
  /// **'New code sent'**
  String get otpResendSuccess;

  /// No description provided for @otpResendError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t resend the code: {error}'**
  String otpResendError(String error);

  /// No description provided for @applyStepWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get applyStepWelcome;

  /// No description provided for @applyStepRole.
  ///
  /// In en, this message translates to:
  /// **'Your role'**
  String get applyStepRole;

  /// No description provided for @applyStepDetails.
  ///
  /// In en, this message translates to:
  /// **'Company details'**
  String get applyStepDetails;

  /// No description provided for @applyOnboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up residence access'**
  String get applyOnboardingTitle;

  /// No description provided for @applyOnboardingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A short setup so your team can manage complexes, units, and leads. Platform review usually takes one business day.'**
  String get applyOnboardingSubtitle;

  /// No description provided for @applyOnboardingPointWorkspace.
  ///
  /// In en, this message translates to:
  /// **'One workspace per company for your residences'**
  String get applyOnboardingPointWorkspace;

  /// No description provided for @applyOnboardingPointAccess.
  ///
  /// In en, this message translates to:
  /// **'Access opens after a quick platform check'**
  String get applyOnboardingPointAccess;

  /// No description provided for @applyGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get applyGetStarted;

  /// No description provided for @applyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'I have an account'**
  String get applyHaveAccount;

  /// No description provided for @authHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Built for property developers'**
  String get authHeroTitle;

  /// No description provided for @authHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage residential complexes, units, and buyer leads in one iBuild workspace — built for teams, not just admins.'**
  String get authHeroSubtitle;

  /// No description provided for @authHeroPointVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified developers and projects earn buyer trust'**
  String get authHeroPointVerified;

  /// No description provided for @authHeroPointLeads.
  ///
  /// In en, this message translates to:
  /// **'Buyer and tenant leads land straight in your CRM'**
  String get authHeroPointLeads;

  /// No description provided for @applyRoleTitle.
  ///
  /// In en, this message translates to:
  /// **'Developer registration'**
  String get applyRoleTitle;

  /// No description provided for @applyRoleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You are registering as a property developer. Check the option below if you also combine the contractor role.'**
  String get applyRoleSubtitle;

  /// No description provided for @applyContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get applyContinue;

  /// No description provided for @applyKindDeveloperLabel.
  ///
  /// In en, this message translates to:
  /// **'Property developer'**
  String get applyKindDeveloperLabel;

  /// No description provided for @applyKindDeveloperSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You publish residential complexes, units, and buyer leads.'**
  String get applyKindDeveloperSubtitle;

  /// No description provided for @applyKindConstructionLabel.
  ///
  /// In en, this message translates to:
  /// **'Construction company'**
  String get applyKindConstructionLabel;

  /// No description provided for @applyKindConstructionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You build for other developers (contractor) — coordinate on-site work, inventory, and residence access.'**
  String get applyKindConstructionSubtitle;

  /// No description provided for @applyAlsoContractorLabel.
  ///
  /// In en, this message translates to:
  /// **'I also act as a contractor'**
  String get applyAlsoContractorLabel;

  /// No description provided for @applyAlsoContractorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You carry out construction on your own projects — a construction license number will be required.'**
  String get applyAlsoContractorSubtitle;

  /// No description provided for @applyDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Legal entity details'**
  String get applyDetailsTitle;

  /// No description provided for @applyDetailsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Uzbekistan registration data (STIR/INN, director PINFL, UBO). Required for platform review as {kind}.'**
  String applyDetailsSubtitle(String kind);

  /// No description provided for @applyBrandName.
  ///
  /// In en, this message translates to:
  /// **'Brand / trade name *'**
  String get applyBrandName;

  /// No description provided for @applyLegalName.
  ///
  /// In en, this message translates to:
  /// **'Full legal name *'**
  String get applyLegalName;

  /// No description provided for @applyInn.
  ///
  /// In en, this message translates to:
  /// **'ИНН / STIR (9 digits) *'**
  String get applyInn;

  /// No description provided for @applyLegalForm.
  ///
  /// In en, this message translates to:
  /// **'Legal form (LLC / ИП / JSC) *'**
  String get applyLegalForm;

  /// No description provided for @applyRegistrationNumber.
  ///
  /// In en, this message translates to:
  /// **'State registration number'**
  String get applyRegistrationNumber;

  /// No description provided for @applyLegalAddress.
  ///
  /// In en, this message translates to:
  /// **'Legal address *'**
  String get applyLegalAddress;

  /// No description provided for @applyOfficeAddress.
  ///
  /// In en, this message translates to:
  /// **'Office / sales office address'**
  String get applyOfficeAddress;

  /// No description provided for @applyRegion.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get applyRegion;

  /// No description provided for @applyRegionTashkent.
  ///
  /// In en, this message translates to:
  /// **'Tashkent'**
  String get applyRegionTashkent;

  /// No description provided for @applyRegionNewTashkent.
  ///
  /// In en, this message translates to:
  /// **'New Tashkent'**
  String get applyRegionNewTashkent;

  /// No description provided for @applyEmail.
  ///
  /// In en, this message translates to:
  /// **'Company email'**
  String get applyEmail;

  /// No description provided for @applyDirectorSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Director (holder)'**
  String get applyDirectorSectionTitle;

  /// No description provided for @applyDirectorFullName.
  ///
  /// In en, this message translates to:
  /// **'Director full name *'**
  String get applyDirectorFullName;

  /// No description provided for @applyDirectorPinfl.
  ///
  /// In en, this message translates to:
  /// **'Director PINFL (14 digits) *'**
  String get applyDirectorPinfl;

  /// No description provided for @applyDirectorPassport.
  ///
  /// In en, this message translates to:
  /// **'Passport series & number'**
  String get applyDirectorPassport;

  /// No description provided for @applyDirectorPhone.
  ///
  /// In en, this message translates to:
  /// **'Director phone'**
  String get applyDirectorPhone;

  /// No description provided for @applyUboName.
  ///
  /// In en, this message translates to:
  /// **'Ultimate beneficial owner (if different)'**
  String get applyUboName;

  /// No description provided for @applyLicense.
  ///
  /// In en, this message translates to:
  /// **'Construction license number'**
  String get applyLicense;

  /// No description provided for @applyUboConfirm.
  ///
  /// In en, this message translates to:
  /// **'I confirm beneficial-owner (UBO) details are accurate (AML / UZ registration rules). *'**
  String get applyUboConfirm;

  /// No description provided for @applyUboHelper.
  ///
  /// In en, this message translates to:
  /// **'A UBO (ultimate beneficial owner) is the individual who ultimately owns or controls the company — usually anyone holding 25% or more. Uzbek AML rules require this to be declared.'**
  String get applyUboHelper;

  /// No description provided for @applySubmit.
  ///
  /// In en, this message translates to:
  /// **'Save draft'**
  String get applySubmit;

  /// No description provided for @applySaveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save draft'**
  String get applySaveDraft;

  /// No description provided for @applySaveDraftSuccess.
  ///
  /// In en, this message translates to:
  /// **'Draft saved — review your details, then submit for approval when ready.'**
  String get applySaveDraftSuccess;

  /// No description provided for @applySubmitSuccess.
  ///
  /// In en, this message translates to:
  /// **'Application submitted — awaiting platform approval.'**
  String get applySubmitSuccess;

  /// No description provided for @applyDraftTitle.
  ///
  /// In en, this message translates to:
  /// **'Draft saved'**
  String get applyDraftTitle;

  /// No description provided for @applyDraftSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review your details and submit the application for platform review when you are ready.'**
  String get applyDraftSubtitle;

  /// No description provided for @applySubmitForReview.
  ///
  /// In en, this message translates to:
  /// **'Submit for review'**
  String get applySubmitForReview;

  /// No description provided for @applySubmitForReviewSuccess.
  ///
  /// In en, this message translates to:
  /// **'Application submitted — awaiting platform review.'**
  String get applySubmitForReviewSuccess;

  /// No description provided for @applyDocumentsRequiredHint.
  ///
  /// In en, this message translates to:
  /// **'Upload all 4 verification documents above before submitting your application for review.'**
  String get applyDocumentsRequiredHint;

  /// No description provided for @applyDocumentsMissingHint.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t added: {names}. Upload them above before submitting your application for review.'**
  String applyDocumentsMissingHint(String names);

  /// No description provided for @applyReviewDecisionLabel.
  ///
  /// In en, this message translates to:
  /// **'Decision'**
  String get applyReviewDecisionLabel;

  /// No description provided for @applyPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Application submitted'**
  String get applyPendingTitle;

  /// No description provided for @applyPendingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll review your application and notify you here. This usually takes one business day.'**
  String get applyPendingSubtitle;

  /// No description provided for @applyPendingRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh status'**
  String get applyPendingRefresh;

  /// No description provided for @applyRejectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Application declined'**
  String get applyRejectedTitle;

  /// No description provided for @applyRejectedReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason for decline'**
  String get applyRejectedReasonLabel;

  /// No description provided for @applyRejectedResendAction.
  ///
  /// In en, this message translates to:
  /// **'Edit & resubmit'**
  String get applyRejectedResendAction;

  /// No description provided for @applyApprovedTitle.
  ///
  /// In en, this message translates to:
  /// **'Application approved'**
  String get applyApprovedTitle;

  /// No description provided for @applyApprovedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Redirecting to your workspace…'**
  String get applyApprovedSubtitle;

  /// No description provided for @applyRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'Request failed ({code}). Try again.'**
  String applyRequestFailed(String code);

  /// No description provided for @applyNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the server. Check your connection.'**
  String get applyNetworkError;

  /// No description provided for @navPlatform.
  ///
  /// In en, this message translates to:
  /// **'Platform'**
  String get navPlatform;

  /// No description provided for @navResidence.
  ///
  /// In en, this message translates to:
  /// **'Residence'**
  String get navResidence;

  /// No description provided for @navOrganization.
  ///
  /// In en, this message translates to:
  /// **'Organization'**
  String get navOrganization;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @shellAdminFallback.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get shellAdminFallback;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsLightMode.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsLightMode;

  /// No description provided for @settingsDarkShort.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsDarkShort;

  /// No description provided for @settingsDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get settingsDarkMode;

  /// No description provided for @settingsPalette.
  ///
  /// In en, this message translates to:
  /// **'Color theme'**
  String get settingsPalette;

  /// No description provided for @settingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// No description provided for @platformTitle.
  ///
  /// In en, this message translates to:
  /// **'Platform administration'**
  String get platformTitle;

  /// No description provided for @platformSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Administer the platform.'**
  String get platformSubtitle;

  /// No description provided for @platformAnalyticsError.
  ///
  /// In en, this message translates to:
  /// **'Analytics error: {error}'**
  String platformAnalyticsError(String error);

  /// No description provided for @statUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get statUsers;

  /// No description provided for @statProjects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get statProjects;

  /// No description provided for @statPublished.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get statPublished;

  /// No description provided for @statLeads.
  ///
  /// In en, this message translates to:
  /// **'Leads'**
  String get statLeads;

  /// No description provided for @statAppsPending.
  ///
  /// In en, this message translates to:
  /// **'Apps pending'**
  String get statAppsPending;

  /// No description provided for @statProjectsPending.
  ///
  /// In en, this message translates to:
  /// **'Projects pending'**
  String get statProjectsPending;

  /// No description provided for @statPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get statPaid;

  /// No description provided for @statUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get statUnpaid;

  /// No description provided for @platformBusinessesSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Registered businesses · payment'**
  String get platformBusinessesSectionTitle;

  /// No description provided for @platformNoBusinesses.
  ///
  /// In en, this message translates to:
  /// **'No registered businesses yet'**
  String get platformNoBusinesses;

  /// No description provided for @platformBusinessesError.
  ///
  /// In en, this message translates to:
  /// **'Businesses error: {error}'**
  String platformBusinessesError(String error);

  /// No description provided for @platformPendingAppsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Pending applications'**
  String get platformPendingAppsSectionTitle;

  /// No description provided for @platformNoPendingApps.
  ///
  /// In en, this message translates to:
  /// **'No pending applications'**
  String get platformNoPendingApps;

  /// No description provided for @platformViewKyc.
  ///
  /// In en, this message translates to:
  /// **'View KYC'**
  String get platformViewKyc;

  /// No description provided for @platformApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get platformApprove;

  /// No description provided for @platformReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get platformReject;

  /// No description provided for @platformRejectReasonDefault.
  ///
  /// In en, this message translates to:
  /// **'Does not meet requirements'**
  String get platformRejectReasonDefault;

  /// No description provided for @devStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Waiting for review'**
  String get devStatusPending;

  /// No description provided for @devStatusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get devStatusDraft;

  /// No description provided for @devStatusInReview.
  ///
  /// In en, this message translates to:
  /// **'On review'**
  String get devStatusInReview;

  /// No description provided for @devStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get devStatusApproved;

  /// No description provided for @devStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get devStatusRejected;

  /// No description provided for @platformChangeStatusTooltip.
  ///
  /// In en, this message translates to:
  /// **'Change status'**
  String get platformChangeStatusTooltip;

  /// No description provided for @platformStatusMenuAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get platformStatusMenuAccept;

  /// No description provided for @platformStatusMenuDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline…'**
  String get platformStatusMenuDecline;

  /// No description provided for @platformStatusUpdated.
  ///
  /// In en, this message translates to:
  /// **'Application status updated'**
  String get platformStatusUpdated;

  /// No description provided for @platformDeclineDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Decline application'**
  String get platformDeclineDialogTitle;

  /// No description provided for @platformDeclineReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get platformDeclineReasonLabel;

  /// No description provided for @platformDeclineReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Why is this application being declined?'**
  String get platformDeclineReasonHint;

  /// No description provided for @platformDeclineConfirm.
  ///
  /// In en, this message translates to:
  /// **'Decline application'**
  String get platformDeclineConfirm;

  /// No description provided for @platformPendingProjectsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Projects pending moderation'**
  String get platformPendingProjectsSectionTitle;

  /// No description provided for @platformNoPendingProjects.
  ///
  /// In en, this message translates to:
  /// **'No projects awaiting moderation'**
  String get platformNoPendingProjects;

  /// No description provided for @platformPublish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get platformPublish;

  /// No description provided for @platformProjectDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get platformProjectDetails;

  /// No description provided for @platformProjectDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get platformProjectDescriptionLabel;

  /// No description provided for @platformProjectPricingLabel.
  ///
  /// In en, this message translates to:
  /// **'Pricing'**
  String get platformProjectPricingLabel;

  /// No description provided for @platformProjectPriceRange.
  ///
  /// In en, this message translates to:
  /// **'{min} – {max} UZS'**
  String platformProjectPriceRange(String min, String max);

  /// No description provided for @platformProjectRentRange.
  ///
  /// In en, this message translates to:
  /// **'Rent: {min} – {max} UZS / mo'**
  String platformProjectRentRange(String min, String max);

  /// No description provided for @platformProjectCompletionLabel.
  ///
  /// In en, this message translates to:
  /// **'Completion: {date}'**
  String platformProjectCompletionLabel(String date);

  /// No description provided for @platformProjectGalleryLabel.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get platformProjectGalleryLabel;

  /// No description provided for @platformProjectUnitsLabel.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get platformProjectUnitsLabel;

  /// No description provided for @platformProjectUnitsSummary.
  ///
  /// In en, this message translates to:
  /// **'{buildings} buildings · {total} units'**
  String platformProjectUnitsSummary(int buildings, int total);

  /// No description provided for @platformProjectUnitsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No units added yet'**
  String get platformProjectUnitsEmpty;

  /// No description provided for @platformProjectLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load project details: {error}'**
  String platformProjectLoadError(String error);

  /// No description provided for @platformPublishedProjectsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Published projects'**
  String get platformPublishedProjectsSectionTitle;

  /// No description provided for @platformNoPublishedProjects.
  ///
  /// In en, this message translates to:
  /// **'No published projects'**
  String get platformNoPublishedProjects;

  /// No description provided for @platformUnpublish.
  ///
  /// In en, this message translates to:
  /// **'Unpublish'**
  String get platformUnpublish;

  /// No description provided for @platformWarn.
  ///
  /// In en, this message translates to:
  /// **'Warn'**
  String get platformWarn;

  /// No description provided for @platformWarnDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Warning for \"{name}\"'**
  String platformWarnDialogTitle(String name);

  /// No description provided for @platformWarnReasonHint.
  ///
  /// In en, this message translates to:
  /// **'What should the developer fix?'**
  String get platformWarnReasonHint;

  /// No description provided for @platformUnpublishConfirm.
  ///
  /// In en, this message translates to:
  /// **'Unpublish'**
  String get platformUnpublishConfirm;

  /// No description provided for @platformActionSuccess.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get platformActionSuccess;

  /// No description provided for @platformActionError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String platformActionError(String error);

  /// No description provided for @platformPendingReviewsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Reviews pending moderation'**
  String get platformPendingReviewsSectionTitle;

  /// No description provided for @platformNoPendingReviews.
  ///
  /// In en, this message translates to:
  /// **'No reviews awaiting moderation'**
  String get platformNoPendingReviews;

  /// No description provided for @platformReviewRatingLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get platformReviewRatingLocation;

  /// No description provided for @platformReviewRatingQuality.
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get platformReviewRatingQuality;

  /// No description provided for @platformReviewRatingValue.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get platformReviewRatingValue;

  /// No description provided for @platformReviewProjectLabel.
  ///
  /// In en, this message translates to:
  /// **'Project: {name}'**
  String platformReviewProjectLabel(String name);

  /// No description provided for @platformAnonymous.
  ///
  /// In en, this message translates to:
  /// **'Anonymous'**
  String get platformAnonymous;

  /// No description provided for @platformKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get platformKeep;

  /// No description provided for @platformRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get platformRemove;

  /// No description provided for @platformPendingRentalsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Owner rental listings pending moderation'**
  String get platformPendingRentalsSectionTitle;

  /// No description provided for @platformNoPendingRentals.
  ///
  /// In en, this message translates to:
  /// **'No rental listings awaiting moderation'**
  String get platformNoPendingRentals;

  /// No description provided for @platformRentalRejectNoteDefault.
  ///
  /// In en, this message translates to:
  /// **'Does not meet listing requirements'**
  String get platformRentalRejectNoteDefault;

  /// No description provided for @platformRentalMonthlyRent.
  ///
  /// In en, this message translates to:
  /// **'{amount} UZS / mo'**
  String platformRentalMonthlyRent(String amount);

  /// No description provided for @platformRentalContactLabel.
  ///
  /// In en, this message translates to:
  /// **'Contact: {phone}'**
  String platformRentalContactLabel(String phone);

  /// No description provided for @platformAuditLogSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Audit log'**
  String get platformAuditLogSectionTitle;

  /// No description provided for @platformNoAuditEvents.
  ///
  /// In en, this message translates to:
  /// **'No audit events yet'**
  String get platformNoAuditEvents;

  /// No description provided for @platformAuditError.
  ///
  /// In en, this message translates to:
  /// **'Audit log error: {error}'**
  String platformAuditError(String error);

  /// No description provided for @platformAuditLogActorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Changed by'**
  String get platformAuditLogActorPrefix;

  /// No description provided for @platformAuditLogActorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown user'**
  String get platformAuditLogActorUnknown;

  /// No description provided for @platformAuditLogPageInfo.
  ///
  /// In en, this message translates to:
  /// **'Page {page} of {total}'**
  String platformAuditLogPageInfo(int page, int total);

  /// No description provided for @platformAuditLogPrevPage.
  ///
  /// In en, this message translates to:
  /// **'Previous page'**
  String get platformAuditLogPrevPage;

  /// No description provided for @platformAuditLogNextPage.
  ///
  /// In en, this message translates to:
  /// **'Next page'**
  String get platformAuditLogNextPage;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Every project change and submitted document that needs your review.'**
  String get notificationsSubtitle;

  /// No description provided for @notificationsMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get notificationsMarkAllRead;

  /// No description provided for @notificationsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'All notifications'**
  String get notificationsSectionTitle;

  /// No description provided for @notificationsUnreadSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'{count} unread'**
  String notificationsUnreadSectionTitle(int count);

  /// No description provided for @notificationsError.
  ///
  /// In en, this message translates to:
  /// **'Notifications error: {error}'**
  String notificationsError(String error);

  /// No description provided for @notificationsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get notificationsEmptyTitle;

  /// No description provided for @notificationsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'New projects, edits, and submitted documents will show up here.'**
  String get notificationsEmptySubtitle;

  /// No description provided for @notificationsCriticalBadge.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get notificationsCriticalBadge;

  /// No description provided for @notificationsJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get notificationsJustNow;

  /// No description provided for @notificationsMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String notificationsMinutesAgo(int minutes);

  /// No description provided for @notificationsHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String notificationsHoursAgo(int hours);

  /// No description provided for @notificationsDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String notificationsDaysAgo(int days);

  /// No description provided for @notifDeveloperSubmittedTitle.
  ///
  /// In en, this message translates to:
  /// **'Developer application: {name}'**
  String notifDeveloperSubmittedTitle(String name);

  /// No description provided for @notifDeveloperSubmittedBody.
  ///
  /// In en, this message translates to:
  /// **'{name} submitted their KYC application for review.'**
  String notifDeveloperSubmittedBody(String name);

  /// No description provided for @notifDocumentUploadedTitle.
  ///
  /// In en, this message translates to:
  /// **'Document submitted: {documentType}'**
  String notifDocumentUploadedTitle(String documentType);

  /// No description provided for @notifDocumentUploadedBody.
  ///
  /// In en, this message translates to:
  /// **'{name} uploaded “{documentType}” for review.'**
  String notifDocumentUploadedBody(String name, String documentType);

  /// No description provided for @notifProjectCreatedTitle.
  ///
  /// In en, this message translates to:
  /// **'New project: {name}'**
  String notifProjectCreatedTitle(String name);

  /// No description provided for @notifProjectCreatedBody.
  ///
  /// In en, this message translates to:
  /// **'{name} created a new project draft.'**
  String notifProjectCreatedBody(String name);

  /// No description provided for @notifProjectCreatedBodyAnonymous.
  ///
  /// In en, this message translates to:
  /// **'A new project draft was created.'**
  String get notifProjectCreatedBodyAnonymous;

  /// No description provided for @notifProjectSubmittedTitle.
  ///
  /// In en, this message translates to:
  /// **'Project submitted for review: {name}'**
  String notifProjectSubmittedTitle(String name);

  /// No description provided for @notifProjectSubmittedBody.
  ///
  /// In en, this message translates to:
  /// **'{name} submitted this project for moderation.'**
  String notifProjectSubmittedBody(String name);

  /// No description provided for @notifProjectSubmittedBodyAnonymous.
  ///
  /// In en, this message translates to:
  /// **'A project was submitted for moderation.'**
  String get notifProjectSubmittedBodyAnonymous;

  /// No description provided for @notifProjectUpdatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Project updated: {name}'**
  String notifProjectUpdatedTitle(String name);

  /// No description provided for @notifProjectUpdatedBody.
  ///
  /// In en, this message translates to:
  /// **'Changed fields: {fields}'**
  String notifProjectUpdatedBody(String fields);

  /// No description provided for @notifProgressDeviationTitle.
  ///
  /// In en, this message translates to:
  /// **'Construction behind schedule: {name}'**
  String notifProgressDeviationTitle(String name);

  /// No description provided for @notifProgressDeviationBody.
  ///
  /// In en, this message translates to:
  /// **'Confirmed {actual}% vs promised {planned}% — gap {gap}%. Needs on-site inspection.'**
  String notifProgressDeviationBody(int actual, int planned, int gap);

  /// No description provided for @platformUsersSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Users & roles'**
  String get platformUsersSectionTitle;

  /// No description provided for @platformColPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get platformColPhone;

  /// No description provided for @platformColRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get platformColRole;

  /// No description provided for @platformColStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get platformColStatus;

  /// No description provided for @platformColActions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get platformColActions;

  /// No description provided for @platformBannedTooltip.
  ///
  /// In en, this message translates to:
  /// **'Banned by {by}: {reason}'**
  String platformBannedTooltip(String by, String reason);

  /// No description provided for @platformBannedLabel.
  ///
  /// In en, this message translates to:
  /// **'Banned'**
  String get platformBannedLabel;

  /// No description provided for @platformSetRoleTooltip.
  ///
  /// In en, this message translates to:
  /// **'Set role'**
  String get platformSetRoleTooltip;

  /// No description provided for @platformSetRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Set role'**
  String get platformSetRoleLabel;

  /// No description provided for @platformUnban.
  ///
  /// In en, this message translates to:
  /// **'Unban'**
  String get platformUnban;

  /// No description provided for @platformBan.
  ///
  /// In en, this message translates to:
  /// **'Ban'**
  String get platformBan;

  /// No description provided for @platformDeleteAdminTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete platform admin account'**
  String get platformDeleteAdminTooltip;

  /// No description provided for @platformDeleteAdminConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {phone}?'**
  String platformDeleteAdminConfirmTitle(String phone);

  /// No description provided for @platformDeleteAdminConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently removes their platform-admin account and signs them out everywhere. This can\'t be undone.'**
  String get platformDeleteAdminConfirmBody;

  /// No description provided for @platformDeleteAdminConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get platformDeleteAdminConfirm;

  /// No description provided for @platformDeleteAdminSelfHint.
  ///
  /// In en, this message translates to:
  /// **'This is your own account — sign in as another admin to remove it.'**
  String get platformDeleteAdminSelfHint;

  /// No description provided for @platformBanDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Ban {phone}'**
  String platformBanDialogTitle(String phone);

  /// No description provided for @platformBanDialogUserFallback.
  ///
  /// In en, this message translates to:
  /// **'user'**
  String get platformBanDialogUserFallback;

  /// No description provided for @platformBanDialogBody.
  ///
  /// In en, this message translates to:
  /// **'This freezes the account everywhere except its own profile and signing out.'**
  String get platformBanDialogBody;

  /// No description provided for @platformBanReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get platformBanReasonLabel;

  /// No description provided for @platformBanReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Why is this account being banned?'**
  String get platformBanReasonHint;

  /// No description provided for @platformBanByLabel.
  ///
  /// In en, this message translates to:
  /// **'Banned by (name)'**
  String get platformBanByLabel;

  /// No description provided for @platformBanByHint.
  ///
  /// In en, this message translates to:
  /// **'Shown to the user on their account'**
  String get platformBanByHint;

  /// No description provided for @platformBanConfirm.
  ///
  /// In en, this message translates to:
  /// **'Ban account'**
  String get platformBanConfirm;

  /// No description provided for @accountBannedTitle.
  ///
  /// In en, this message translates to:
  /// **'Your account has been banned'**
  String get accountBannedTitle;

  /// No description provided for @accountBannedBody.
  ///
  /// In en, this message translates to:
  /// **'This account is frozen. You can only view this notice and sign out until a platform admin lifts the ban.'**
  String get accountBannedBody;

  /// No description provided for @accountBannedReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get accountBannedReasonLabel;

  /// No description provided for @accountBannedByLabel.
  ///
  /// In en, this message translates to:
  /// **'Banned by {name}'**
  String accountBannedByLabel(String name);

  /// No description provided for @platformKycTitle.
  ///
  /// In en, this message translates to:
  /// **'KYC · {name}'**
  String platformKycTitle(String name);

  /// No description provided for @kycCompanyName.
  ///
  /// In en, this message translates to:
  /// **'Company name'**
  String get kycCompanyName;

  /// No description provided for @kycLegalName.
  ///
  /// In en, this message translates to:
  /// **'Legal name'**
  String get kycLegalName;

  /// No description provided for @kycAccountKind.
  ///
  /// In en, this message translates to:
  /// **'Account kind'**
  String get kycAccountKind;

  /// No description provided for @kycLegalForm.
  ///
  /// In en, this message translates to:
  /// **'Legal form'**
  String get kycLegalForm;

  /// No description provided for @kycInn.
  ///
  /// In en, this message translates to:
  /// **'INN'**
  String get kycInn;

  /// No description provided for @kycRegistrationNumber.
  ///
  /// In en, this message translates to:
  /// **'Registration number'**
  String get kycRegistrationNumber;

  /// No description provided for @kycOkedCode.
  ///
  /// In en, this message translates to:
  /// **'OKED code'**
  String get kycOkedCode;

  /// No description provided for @kycLegalAddress.
  ///
  /// In en, this message translates to:
  /// **'Legal address'**
  String get kycLegalAddress;

  /// No description provided for @kycOfficeAddress.
  ///
  /// In en, this message translates to:
  /// **'Office address'**
  String get kycOfficeAddress;

  /// No description provided for @kycRegion.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get kycRegion;

  /// No description provided for @kycEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get kycEmail;

  /// No description provided for @kycWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get kycWebsite;

  /// No description provided for @kycDirectorFullName.
  ///
  /// In en, this message translates to:
  /// **'Director full name'**
  String get kycDirectorFullName;

  /// No description provided for @kycDirectorPinfl.
  ///
  /// In en, this message translates to:
  /// **'Director PINFL'**
  String get kycDirectorPinfl;

  /// No description provided for @kycDirectorPassport.
  ///
  /// In en, this message translates to:
  /// **'Director passport'**
  String get kycDirectorPassport;

  /// No description provided for @kycDirectorPhone.
  ///
  /// In en, this message translates to:
  /// **'Director phone'**
  String get kycDirectorPhone;

  /// No description provided for @kycDirectorEmail.
  ///
  /// In en, this message translates to:
  /// **'Director email'**
  String get kycDirectorEmail;

  /// No description provided for @kycUboDeclared.
  ///
  /// In en, this message translates to:
  /// **'UBO declared'**
  String get kycUboDeclared;

  /// No description provided for @kycUboFullName.
  ///
  /// In en, this message translates to:
  /// **'UBO full name'**
  String get kycUboFullName;

  /// No description provided for @kycUboHelper.
  ///
  /// In en, this message translates to:
  /// **'Ultimate beneficial owner — the individual who ultimately owns or controls the company (typically ≥25%).'**
  String get kycUboHelper;

  /// No description provided for @kycConstructionLicense.
  ///
  /// In en, this message translates to:
  /// **'Construction license'**
  String get kycConstructionLicense;

  /// No description provided for @platformKycDocumentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get platformKycDocumentsTitle;

  /// No description provided for @platformKycDocumentsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No documents uploaded yet'**
  String get platformKycDocumentsEmpty;

  /// No description provided for @platformKycDocumentsError.
  ///
  /// In en, this message translates to:
  /// **'Documents error: {error}'**
  String platformKycDocumentsError(String error);

  /// No description provided for @platformKycDocumentView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get platformKycDocumentView;

  /// No description provided for @platformKycDocumentAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get platformKycDocumentAccept;

  /// No description provided for @platformKycDocumentReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get platformKycDocumentReject;

  /// No description provided for @platformKycDocumentRejectDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject document'**
  String get platformKycDocumentRejectDialogTitle;

  /// No description provided for @platformKycDocumentRejectReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Why is this document being rejected?'**
  String get platformKycDocumentRejectReasonHint;

  /// No description provided for @residenceNewProjectDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'New project'**
  String get residenceNewProjectDialogTitle;

  /// No description provided for @residenceNameHint.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get residenceNameHint;

  /// No description provided for @residenceTypeHint.
  ///
  /// In en, this message translates to:
  /// **'Property type'**
  String get residenceTypeHint;

  /// No description provided for @projectTypeResidentialComplex.
  ///
  /// In en, this message translates to:
  /// **'Residential complex'**
  String get projectTypeResidentialComplex;

  /// No description provided for @projectTypeBusinessCentre.
  ///
  /// In en, this message translates to:
  /// **'Business centre'**
  String get projectTypeBusinessCentre;

  /// No description provided for @projectTypeStreetRetail.
  ///
  /// In en, this message translates to:
  /// **'Street retail'**
  String get projectTypeStreetRetail;

  /// No description provided for @projectTypeOffice.
  ///
  /// In en, this message translates to:
  /// **'Office'**
  String get projectTypeOffice;

  /// No description provided for @projectTypeCottage.
  ///
  /// In en, this message translates to:
  /// **'Cottage'**
  String get projectTypeCottage;

  /// No description provided for @residenceDistrictHint.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get residenceDistrictHint;

  /// No description provided for @residenceDistrictOther.
  ///
  /// In en, this message translates to:
  /// **'Other (specify)'**
  String get residenceDistrictOther;

  /// No description provided for @residenceDistrictOtherHint.
  ///
  /// In en, this message translates to:
  /// **'District / area name'**
  String get residenceDistrictOtherHint;

  /// No description provided for @residenceAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Address (street, building)'**
  String get residenceAddressHint;

  /// No description provided for @mapLocationTapHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the map to set the property location'**
  String get mapLocationTapHint;

  /// No description provided for @mapLocationManualHint.
  ///
  /// In en, this message translates to:
  /// **'Or type exact coordinates'**
  String get mapLocationManualHint;

  /// No description provided for @mapLocationLatitudeLabel.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get mapLocationLatitudeLabel;

  /// No description provided for @mapLocationLongitudeLabel.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get mapLocationLongitudeLabel;

  /// No description provided for @mapLocationApplyCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get mapLocationApplyCoordinates;

  /// No description provided for @mapLocationInvalidCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid latitude (-90 to 90) and longitude (-180 to 180)'**
  String get mapLocationInvalidCoordinates;

  /// No description provided for @mapLocationCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Coordinates: {lat}, {lng}'**
  String mapLocationCoordinates(String lat, String lng);

  /// No description provided for @mapLocationZoomIn.
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get mapLocationZoomIn;

  /// No description provided for @mapLocationZoomOut.
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get mapLocationZoomOut;

  /// No description provided for @residenceCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get residenceCreate;

  /// No description provided for @residenceCreatedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Project saved as draft — submit for moderation when ready'**
  String get residenceCreatedSnackbar;

  /// No description provided for @residencePublishingLocked.
  ///
  /// In en, this message translates to:
  /// **'Publishing is locked until you subscribe (\${price}/mo). You can still configure your organization profile.'**
  String residencePublishingLocked(String price);

  /// No description provided for @residenceTitle.
  ///
  /// In en, this message translates to:
  /// **'Residence admin'**
  String get residenceTitle;

  /// No description provided for @residenceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage inventory, unit status, media URLs, and lead CRM.'**
  String get residenceSubtitle;

  /// No description provided for @residenceNewProject.
  ///
  /// In en, this message translates to:
  /// **'New project'**
  String get residenceNewProject;

  /// No description provided for @residenceProjectsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Your projects'**
  String get residenceProjectsSectionTitle;

  /// No description provided for @residenceNoProjects.
  ///
  /// In en, this message translates to:
  /// **'No projects yet'**
  String get residenceNoProjects;

  /// No description provided for @residenceNoProjectsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create one, then wait for platform approval.'**
  String get residenceNoProjectsSubtitle;

  /// No description provided for @residenceLoadError.
  ///
  /// In en, this message translates to:
  /// **'Load error (need approved developer + residence_admin role): {error}'**
  String residenceLoadError(String error);

  /// No description provided for @residenceProjectMeta.
  ///
  /// In en, this message translates to:
  /// **'{district} · moderation: {moderation} · published: {published}'**
  String residenceProjectMeta(
    String district,
    String moderation,
    String published,
  );

  /// No description provided for @orgPlanUnlimited.
  ///
  /// In en, this message translates to:
  /// **'unlimited'**
  String get orgPlanUnlimited;

  /// No description provided for @orgPlanActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get orgPlanActive;

  /// No description provided for @orgPlanCurrentPlan.
  ///
  /// In en, this message translates to:
  /// **'Current plan'**
  String get orgPlanCurrentPlan;

  /// No description provided for @orgPlanSubscribe.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get orgPlanSubscribe;

  /// No description provided for @orgPlanSummary.
  ///
  /// In en, this message translates to:
  /// **'\${price}/mo · {maxProjects} projects · {maxUnits} units · {leads} leads incl. · \${payPerLead}/lead after'**
  String orgPlanSummary(
    String price,
    String maxProjects,
    String maxUnits,
    String leads,
    String payPerLead,
  );

  /// No description provided for @orgTitle.
  ///
  /// In en, this message translates to:
  /// **'Organization profile'**
  String get orgTitle;

  /// No description provided for @orgSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure how your company and residences appear. Publishing to buyers requires an active \$299/mo subscription.'**
  String get orgSubtitle;

  /// No description provided for @orgNoProfile.
  ///
  /// In en, this message translates to:
  /// **'No organization profile yet.'**
  String get orgNoProfile;

  /// No description provided for @orgError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String orgError(String error);

  /// No description provided for @orgLegalLine.
  ///
  /// In en, this message translates to:
  /// **'{legalName} · ИНН {inn}'**
  String orgLegalLine(String legalName, String inn);

  /// No description provided for @orgPaymentLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment: {status}'**
  String orgPaymentLabel(String status);

  /// No description provided for @orgPublishingUnlocked.
  ///
  /// In en, this message translates to:
  /// **' · publishing unlocked'**
  String get orgPublishingUnlocked;

  /// No description provided for @orgPublishingLocked.
  ///
  /// In en, this message translates to:
  /// **' · publishing locked'**
  String get orgPublishingLocked;

  /// No description provided for @orgSubscriptionPlansTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscription plans'**
  String get orgSubscriptionPlansTitle;

  /// No description provided for @orgSubscriptionPlansSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a tier for how many projects/units you publish and how many leads are included before pay-per-lead applies.'**
  String get orgSubscriptionPlansSubtitle;

  /// No description provided for @orgPlansError.
  ///
  /// In en, this message translates to:
  /// **'Plans error: {error}'**
  String orgPlansError(String error);

  /// No description provided for @orgDocumentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification documents'**
  String get orgDocumentsTitle;

  /// No description provided for @orgDocumentsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Upload all 4 required documents and get each accepted by the platform team before your Verified badge appears to buyers.'**
  String get orgDocumentsSubtitle;

  /// No description provided for @orgDocumentsError.
  ///
  /// In en, this message translates to:
  /// **'Documents error: {error}'**
  String orgDocumentsError(String error);

  /// No description provided for @orgDocumentNotUploaded.
  ///
  /// In en, this message translates to:
  /// **'Not uploaded'**
  String get orgDocumentNotUploaded;

  /// No description provided for @orgDocumentUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get orgDocumentUpload;

  /// No description provided for @orgDocumentReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get orgDocumentReplace;

  /// No description provided for @orgDocumentUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading… {percent}%'**
  String orgDocumentUploading(int percent);

  /// No description provided for @orgDocumentUploaded.
  ///
  /// In en, this message translates to:
  /// **'Document uploaded — pending platform review.'**
  String get orgDocumentUploaded;

  /// No description provided for @orgDocumentUploadError.
  ///
  /// In en, this message translates to:
  /// **'Upload failed: {error}'**
  String orgDocumentUploadError(String error);

  /// No description provided for @orgDocumentRejectReason.
  ///
  /// In en, this message translates to:
  /// **'Rejected: {reason}'**
  String orgDocumentRejectReason(String reason);

  /// No description provided for @orgDocumentView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get orgDocumentView;

  /// No description provided for @orgDocumentConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm before sending'**
  String get orgDocumentConfirmTitle;

  /// No description provided for @orgDocumentConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Review this {type} carefully — once you send it, the platform team will see it for review.'**
  String orgDocumentConfirmMessage(String type);

  /// No description provided for @orgDocumentConfirmSend.
  ///
  /// In en, this message translates to:
  /// **'Send for review'**
  String get orgDocumentConfirmSend;

  /// No description provided for @orgDocumentOptionalSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Optional documents'**
  String get orgDocumentOptionalSectionTitle;

  /// No description provided for @orgDocumentOptionalBadge.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get orgDocumentOptionalBadge;

  /// No description provided for @orgPublicPresenceTitle.
  ///
  /// In en, this message translates to:
  /// **'Public presence'**
  String get orgPublicPresenceTitle;

  /// No description provided for @orgAboutHint.
  ///
  /// In en, this message translates to:
  /// **'About your organization / residences'**
  String get orgAboutHint;

  /// No description provided for @orgOfficeHint.
  ///
  /// In en, this message translates to:
  /// **'Sales office address'**
  String get orgOfficeHint;

  /// No description provided for @orgWebsiteHint.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get orgWebsiteHint;

  /// No description provided for @orgLogoHint.
  ///
  /// In en, this message translates to:
  /// **'Logo image URL'**
  String get orgLogoHint;

  /// No description provided for @orgCoverHint.
  ///
  /// In en, this message translates to:
  /// **'Cover image URL'**
  String get orgCoverHint;

  /// No description provided for @orgBrandColorHint.
  ///
  /// In en, this message translates to:
  /// **'Brand color (e.g. #1A1A1A)'**
  String get orgBrandColorHint;

  /// No description provided for @orgSaveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save profile'**
  String get orgSaveProfile;

  /// No description provided for @orgSavedMessage.
  ///
  /// In en, this message translates to:
  /// **'Profile saved.'**
  String get orgSavedMessage;

  /// No description provided for @orgPlanDetailsShow.
  ///
  /// In en, this message translates to:
  /// **'Show visibility details'**
  String get orgPlanDetailsShow;

  /// No description provided for @orgPlanDetailsHide.
  ///
  /// In en, this message translates to:
  /// **'Hide visibility details'**
  String get orgPlanDetailsHide;

  /// No description provided for @orgPlanAlwaysOnTopTitle.
  ///
  /// In en, this message translates to:
  /// **'\"Always on Top\" visibility'**
  String get orgPlanAlwaysOnTopTitle;

  /// No description provided for @orgPlanAlwaysOnTopSubtitle.
  ///
  /// In en, this message translates to:
  /// **'While your subscription is active, listings rank with a boost coefficient of 0.4. When it lapses, the boost decays to 0.04 over the two weeks after expiry.'**
  String get orgPlanAlwaysOnTopSubtitle;

  /// No description provided for @orgPlanDecayActiveLegend.
  ///
  /// In en, this message translates to:
  /// **'Active (0.4)'**
  String get orgPlanDecayActiveLegend;

  /// No description provided for @orgPlanDecayExpiredLegend.
  ///
  /// In en, this message translates to:
  /// **'After expiry (→0.04)'**
  String get orgPlanDecayExpiredLegend;

  /// No description provided for @orgPlanDecayWeeksAxis.
  ///
  /// In en, this message translates to:
  /// **'Weeks from expiry'**
  String get orgPlanDecayWeeksAxis;

  /// No description provided for @orgPlanDecayCoefficientAxis.
  ///
  /// In en, this message translates to:
  /// **'Boost'**
  String get orgPlanDecayCoefficientAxis;

  /// No description provided for @orgAiSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Draft description template'**
  String get orgAiSectionTitle;

  /// No description provided for @orgAiSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add your links and an optional company deck to compose a starter draft from a template — this is not AI-written — then edit it to fit your business before saving.'**
  String get orgAiSectionSubtitle;

  /// No description provided for @orgAiWebsiteHint.
  ///
  /// In en, this message translates to:
  /// **'Website URL'**
  String get orgAiWebsiteHint;

  /// No description provided for @orgAiInstagramHint.
  ///
  /// In en, this message translates to:
  /// **'Instagram URL'**
  String get orgAiInstagramHint;

  /// No description provided for @orgAiPickPdf.
  ///
  /// In en, this message translates to:
  /// **'Attach company PDF'**
  String get orgAiPickPdf;

  /// No description provided for @orgAiPdfSelected.
  ///
  /// In en, this message translates to:
  /// **'Attached: {name}'**
  String orgAiPdfSelected(String name);

  /// No description provided for @orgAiGenerate.
  ///
  /// In en, this message translates to:
  /// **'Compose draft template'**
  String get orgAiGenerate;

  /// No description provided for @orgAiGenerating.
  ///
  /// In en, this message translates to:
  /// **'Composing…'**
  String get orgAiGenerating;

  /// No description provided for @orgAiApply.
  ///
  /// In en, this message translates to:
  /// **'Use this draft'**
  String get orgAiApply;

  /// No description provided for @orgAiResultHint.
  ///
  /// In en, this message translates to:
  /// **'Draft template (editable)'**
  String get orgAiResultHint;

  /// No description provided for @orgAiNoInputs.
  ///
  /// In en, this message translates to:
  /// **'Add a website, Instagram, or PDF first.'**
  String get orgAiNoInputs;

  /// No description provided for @orgAiApplied.
  ///
  /// In en, this message translates to:
  /// **'Draft applied — review and save.'**
  String get orgAiApplied;

  /// No description provided for @projectLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load project'**
  String get projectLoadError;

  /// No description provided for @projectBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get projectBack;

  /// No description provided for @projectModerationLabel.
  ///
  /// In en, this message translates to:
  /// **'Moderation: {status}'**
  String projectModerationLabel(String status);

  /// No description provided for @projectModerationStatusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get projectModerationStatusDraft;

  /// No description provided for @projectModerationStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending review'**
  String get projectModerationStatusPending;

  /// No description provided for @projectModerationStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get projectModerationStatusRejected;

  /// No description provided for @projectSubmitForReview.
  ///
  /// In en, this message translates to:
  /// **'Submit for review'**
  String get projectSubmitForReview;

  /// No description provided for @projectDraftBanner.
  ///
  /// In en, this message translates to:
  /// **'This residence is saved as a draft. Fill in the details and submit for platform moderation when ready.'**
  String get projectDraftBanner;

  /// No description provided for @projectRejectedBanner.
  ///
  /// In en, this message translates to:
  /// **'This residence was declined. Fix the issues noted by the platform and submit again.'**
  String get projectRejectedBanner;

  /// No description provided for @projectWarningBanner.
  ///
  /// In en, this message translates to:
  /// **'Platform warning'**
  String get projectWarningBanner;

  /// No description provided for @projectWarningBannerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Address the notes below. The listing stays published until the platform unpublishes it.'**
  String get projectWarningBannerSubtitle;

  /// No description provided for @residenceProjectWarned.
  ///
  /// In en, this message translates to:
  /// **'Platform warning'**
  String get residenceProjectWarned;

  /// No description provided for @projectUnpublish.
  ///
  /// In en, this message translates to:
  /// **'Unpublish'**
  String get projectUnpublish;

  /// No description provided for @projectPublish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get projectPublish;

  /// No description provided for @projectRepublish.
  ///
  /// In en, this message translates to:
  /// **'Republish'**
  String get projectRepublish;

  /// No description provided for @projectUnpublishConfirm.
  ///
  /// In en, this message translates to:
  /// **'This residence will disappear from the B2C catalogue. Continue?'**
  String get projectUnpublishConfirm;

  /// No description provided for @projectPublishSuccess.
  ///
  /// In en, this message translates to:
  /// **'Residence is live in the catalogue again'**
  String get projectPublishSuccess;

  /// No description provided for @projectUnpublishSuccess.
  ///
  /// In en, this message translates to:
  /// **'Residence unpublished'**
  String get projectUnpublishSuccess;

  /// No description provided for @projectDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete residence'**
  String get projectDelete;

  /// No description provided for @projectDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String projectDeleteConfirmTitle(String name);

  /// No description provided for @projectDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone: buildings, units, offers, and leads for this residence will be removed.'**
  String get projectDeleteConfirmBody;

  /// No description provided for @projectDeleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Residence deleted'**
  String get projectDeleteSuccess;

  /// No description provided for @projectPublishNeedsReview.
  ///
  /// In en, this message translates to:
  /// **'Submit this residence for platform review first'**
  String get projectPublishNeedsReview;

  /// No description provided for @projectPublishNeedsSubscription.
  ///
  /// In en, this message translates to:
  /// **'An active subscription is required to publish'**
  String get projectPublishNeedsSubscription;

  /// No description provided for @navActiveProjects.
  ///
  /// In en, this message translates to:
  /// **'Active residences'**
  String get navActiveProjects;

  /// No description provided for @activeProjectsTitle.
  ///
  /// In en, this message translates to:
  /// **'Active residences'**
  String get activeProjectsTitle;

  /// No description provided for @activeProjectsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Live catalogue listings — warnings and unpublish actions.'**
  String get activeProjectsSubtitle;

  /// No description provided for @projectSubmitForReviewSuccess.
  ///
  /// In en, this message translates to:
  /// **'Submitted for moderation — awaiting platform review.'**
  String get projectSubmitForReviewSuccess;

  /// No description provided for @projectLocationSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Map location'**
  String get projectLocationSectionTitle;

  /// No description provided for @projectLocationSave.
  ///
  /// In en, this message translates to:
  /// **'Save location'**
  String get projectLocationSave;

  /// No description provided for @projectLocationSaved.
  ///
  /// In en, this message translates to:
  /// **'Location saved'**
  String get projectLocationSaved;

  /// No description provided for @projectPublishedLabel.
  ///
  /// In en, this message translates to:
  /// **'Published: {value}'**
  String projectPublishedLabel(String value);

  /// No description provided for @publishedYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get publishedYes;

  /// No description provided for @publishedNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get publishedNo;

  /// No description provided for @platformProjectDeveloper.
  ///
  /// In en, this message translates to:
  /// **'Developer: {name}'**
  String platformProjectDeveloper(String name);

  /// No description provided for @projectAnalyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get projectAnalyticsTitle;

  /// No description provided for @projectOffersTitle.
  ///
  /// In en, this message translates to:
  /// **'Offers'**
  String get projectOffersTitle;

  /// No description provided for @projectAddOffer.
  ///
  /// In en, this message translates to:
  /// **'Add offer'**
  String get projectAddOffer;

  /// No description provided for @projectNoOffers.
  ///
  /// In en, this message translates to:
  /// **'No active offers'**
  String get projectNoOffers;

  /// No description provided for @projectNoOffersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add a discount, installment plan, or rent promo.'**
  String get projectNoOffersSubtitle;

  /// No description provided for @projectRemoveOfferTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove offer'**
  String get projectRemoveOfferTooltip;

  /// No description provided for @projectUnitsTitle.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get projectUnitsTitle;

  /// No description provided for @projectAddBuilding.
  ///
  /// In en, this message translates to:
  /// **'Add building'**
  String get projectAddBuilding;

  /// No description provided for @projectBulkAddUnits.
  ///
  /// In en, this message translates to:
  /// **'Bulk add units'**
  String get projectBulkAddUnits;

  /// No description provided for @projectViewToggleList.
  ///
  /// In en, this message translates to:
  /// **'List view'**
  String get projectViewToggleList;

  /// No description provided for @projectViewToggleChessboard.
  ///
  /// In en, this message translates to:
  /// **'Chessboard view'**
  String get projectViewToggleChessboard;

  /// No description provided for @projectBuildingFallback.
  ///
  /// In en, this message translates to:
  /// **'Building'**
  String get projectBuildingFallback;

  /// No description provided for @projectUnitLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit {number}'**
  String projectUnitLabel(String number);

  /// No description provided for @projectUnitLabelWithStatus.
  ///
  /// In en, this message translates to:
  /// **'Unit {number} · {status}'**
  String projectUnitLabelWithStatus(String number, String status);

  /// No description provided for @projectUnitMetaLine.
  ///
  /// In en, this message translates to:
  /// **'{kind} · {dealType} · {status} · media: {mediaCount}'**
  String projectUnitMetaLine(
    String kind,
    String dealType,
    String status,
    String mediaCount,
  );

  /// No description provided for @projectUnitMetaLineNoStatus.
  ///
  /// In en, this message translates to:
  /// **'{kind} · {dealType} · media: {mediaCount}'**
  String projectUnitMetaLineNoStatus(
    String kind,
    String dealType,
    String mediaCount,
  );

  /// No description provided for @projectAddMediaUrl.
  ///
  /// In en, this message translates to:
  /// **'Add media URL'**
  String get projectAddMediaUrl;

  /// No description provided for @projectStatusButton.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get projectStatusButton;

  /// No description provided for @projectChangeStatusButton.
  ///
  /// In en, this message translates to:
  /// **'Change status'**
  String get projectChangeStatusButton;

  /// No description provided for @projectLeadCrmTitle.
  ///
  /// In en, this message translates to:
  /// **'Lead CRM'**
  String get projectLeadCrmTitle;

  /// No description provided for @projectKanbanHint.
  ///
  /// In en, this message translates to:
  /// **'Drag a card into another column to update its status.'**
  String get projectKanbanHint;

  /// No description provided for @projectNoLeads.
  ///
  /// In en, this message translates to:
  /// **'No leads yet'**
  String get projectNoLeads;

  /// No description provided for @projectLeadSummary.
  ///
  /// In en, this message translates to:
  /// **'{number} · {intent} · {status}'**
  String projectLeadSummary(String number, String intent, String status);

  /// No description provided for @projectLeadContactLine.
  ///
  /// In en, this message translates to:
  /// **'{phone} · {message}'**
  String projectLeadContactLine(String phone, String message);

  /// No description provided for @projectUpdateLeadStatus.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get projectUpdateLeadStatus;

  /// No description provided for @projectTagsScoreTooltip.
  ///
  /// In en, this message translates to:
  /// **'Tags & score'**
  String get projectTagsScoreTooltip;

  /// No description provided for @projectNewBuildingDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Add building'**
  String get projectNewBuildingDialogTitle;

  /// No description provided for @projectBuildingNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get projectBuildingNameLabel;

  /// No description provided for @projectFloorsLabel.
  ///
  /// In en, this message translates to:
  /// **'Floors'**
  String get projectFloorsLabel;

  /// No description provided for @projectMediaUrlHint.
  ///
  /// In en, this message translates to:
  /// **'https://...'**
  String get projectMediaUrlHint;

  /// No description provided for @projectAddBuildingFirstSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Add a building first'**
  String get projectAddBuildingFirstSnackbar;

  /// No description provided for @projectUnitsAddedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Added {count} units'**
  String projectUnitsAddedSnackbar(String count);

  /// No description provided for @projectUnitsPartiallyAddedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Stopped after adding {count} units: {error}'**
  String projectUnitsPartiallyAddedSnackbar(String count, String error);

  /// No description provided for @projectOfferEditorTitle.
  ///
  /// In en, this message translates to:
  /// **'Add offer'**
  String get projectOfferEditorTitle;

  /// No description provided for @projectOfferTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get projectOfferTypeLabel;

  /// No description provided for @projectOfferTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get projectOfferTitleLabel;

  /// No description provided for @projectOfferDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get projectOfferDescriptionLabel;

  /// No description provided for @projectDownPaymentLabel.
  ///
  /// In en, this message translates to:
  /// **'Down payment %'**
  String get projectDownPaymentLabel;

  /// No description provided for @projectTermMonthsLabel.
  ///
  /// In en, this message translates to:
  /// **'Term (months)'**
  String get projectTermMonthsLabel;

  /// No description provided for @projectInterestRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Interest rate %'**
  String get projectInterestRateLabel;

  /// No description provided for @projectBulkUnitsDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Bulk add units'**
  String get projectBulkUnitsDialogTitle;

  /// No description provided for @projectBuildingLabel.
  ///
  /// In en, this message translates to:
  /// **'Building'**
  String get projectBuildingLabel;

  /// No description provided for @projectFloorFromLabel.
  ///
  /// In en, this message translates to:
  /// **'Floor from'**
  String get projectFloorFromLabel;

  /// No description provided for @projectFloorToLabel.
  ///
  /// In en, this message translates to:
  /// **'Floor to'**
  String get projectFloorToLabel;

  /// No description provided for @projectUnitsPerFloorLabel.
  ///
  /// In en, this message translates to:
  /// **'Units per floor'**
  String get projectUnitsPerFloorLabel;

  /// No description provided for @projectStartingNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Starting number'**
  String get projectStartingNumberLabel;

  /// No description provided for @projectKindLabel.
  ///
  /// In en, this message translates to:
  /// **'Kind'**
  String get projectKindLabel;

  /// No description provided for @projectDealLabel.
  ///
  /// In en, this message translates to:
  /// **'Deal'**
  String get projectDealLabel;

  /// No description provided for @projectAreaLabel.
  ///
  /// In en, this message translates to:
  /// **'Area (m²)'**
  String get projectAreaLabel;

  /// No description provided for @projectRoomsLabel.
  ///
  /// In en, this message translates to:
  /// **'Rooms'**
  String get projectRoomsLabel;

  /// No description provided for @projectPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price (\$)'**
  String get projectPriceLabel;

  /// No description provided for @projectPriceM2Label.
  ///
  /// In en, this message translates to:
  /// **'Price/m²'**
  String get projectPriceM2Label;

  /// No description provided for @chessboardFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All types'**
  String get chessboardFilterAll;

  /// No description provided for @chessboardRoomsLegendTitle.
  ///
  /// In en, this message translates to:
  /// **'Rooms:'**
  String get chessboardRoomsLegendTitle;

  /// No description provided for @chessboardRooms4Plus.
  ///
  /// In en, this message translates to:
  /// **'4+'**
  String get chessboardRooms4Plus;

  /// No description provided for @projectRentLabel.
  ///
  /// In en, this message translates to:
  /// **'Rent/mo (\$)'**
  String get projectRentLabel;

  /// No description provided for @projectGenerate.
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get projectGenerate;

  /// No description provided for @projectLegendSoldRented.
  ///
  /// In en, this message translates to:
  /// **'sold / rented'**
  String get projectLegendSoldRented;

  /// No description provided for @projectLeadsStat.
  ///
  /// In en, this message translates to:
  /// **'Leads (30d)'**
  String get projectLeadsStat;

  /// No description provided for @projectLeadsTotalStat.
  ///
  /// In en, this message translates to:
  /// **'Leads total'**
  String get projectLeadsTotalStat;

  /// No description provided for @projectSellThroughStat.
  ///
  /// In en, this message translates to:
  /// **'Sell-through'**
  String get projectSellThroughStat;

  /// No description provided for @projectMonthsToSellOutStat.
  ///
  /// In en, this message translates to:
  /// **'Est. months to sell out'**
  String get projectMonthsToSellOutStat;

  /// No description provided for @projectUnitsStat.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get projectUnitsStat;

  /// No description provided for @projectLeadFunnelTitle.
  ///
  /// In en, this message translates to:
  /// **'Lead funnel'**
  String get projectLeadFunnelTitle;

  /// No description provided for @projectUnitsByStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Units by status'**
  String get projectUnitsByStatusTitle;

  /// No description provided for @projectScheduleSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Construction schedule'**
  String get projectScheduleSectionTitle;

  /// No description provided for @projectScheduleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The progress your published schedule promises for today. Buyers see it next to the confirmed figure from your photo reports, so keep it in sync with the real plan.'**
  String get projectScheduleSubtitle;

  /// No description provided for @projectPlannedProgressLabel.
  ///
  /// In en, this message translates to:
  /// **'Planned progress, %'**
  String get projectPlannedProgressLabel;

  /// No description provided for @projectScheduleSave.
  ///
  /// In en, this message translates to:
  /// **'Save schedule'**
  String get projectScheduleSave;

  /// No description provided for @projectScheduleSaved.
  ///
  /// In en, this message translates to:
  /// **'Schedule saved'**
  String get projectScheduleSaved;

  /// No description provided for @projectScheduleInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a whole number from 0 to 100'**
  String get projectScheduleInvalid;

  /// No description provided for @projectActualProgressHint.
  ///
  /// In en, this message translates to:
  /// **'Confirmed progress: {percent}%'**
  String projectActualProgressHint(int percent);

  /// No description provided for @projectScheduleGapOk.
  ///
  /// In en, this message translates to:
  /// **'Gap {percent}% — within the accepted range'**
  String projectScheduleGapOk(int percent);

  /// No description provided for @projectScheduleGapAlert.
  ///
  /// In en, this message translates to:
  /// **'Gap {percent}% — above 15%, the platform flags the project for inspection'**
  String projectScheduleGapAlert(int percent);

  /// No description provided for @projectPhotoReportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Construction photo reports'**
  String get projectPhotoReportsTitle;

  /// No description provided for @projectPhotoReportsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Dated site photos grouped by month, optionally tagged with a construction-progress percentage.'**
  String get projectPhotoReportsSubtitle;

  /// No description provided for @projectAddPhotoReport.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get projectAddPhotoReport;

  /// No description provided for @projectPhotoReportsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No photo reports yet'**
  String get projectPhotoReportsEmpty;

  /// No description provided for @projectPhotoReportUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading… {percent}%'**
  String projectPhotoReportUploading(int percent);

  /// No description provided for @projectPhotoReportUploadError.
  ///
  /// In en, this message translates to:
  /// **'Upload failed: {error}'**
  String projectPhotoReportUploadError(String error);

  /// No description provided for @projectPhotoReportDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Add photo report'**
  String get projectPhotoReportDialogTitle;

  /// No description provided for @projectPhotoReportDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date taken'**
  String get projectPhotoReportDateLabel;

  /// No description provided for @projectPhotoReportDeclaredStageLabel.
  ///
  /// In en, this message translates to:
  /// **'Declared construction stage'**
  String get projectPhotoReportDeclaredStageLabel;

  /// No description provided for @projectPhotoReportProgressLabel.
  ///
  /// In en, this message translates to:
  /// **'Construction progress % (optional)'**
  String get projectPhotoReportProgressLabel;

  /// No description provided for @projectPhotoReportDeleteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove photo report'**
  String get projectPhotoReportDeleteTooltip;

  /// No description provided for @projectPhotoReportProgressBadge.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String projectPhotoReportProgressBadge(int percent);

  /// No description provided for @statusAvailable.
  ///
  /// In en, this message translates to:
  /// **'available'**
  String get statusAvailable;

  /// No description provided for @statusReserved.
  ///
  /// In en, this message translates to:
  /// **'reserved'**
  String get statusReserved;

  /// No description provided for @statusSold.
  ///
  /// In en, this message translates to:
  /// **'sold'**
  String get statusSold;

  /// No description provided for @statusRented.
  ///
  /// In en, this message translates to:
  /// **'rented'**
  String get statusRented;

  /// No description provided for @statusBlocked.
  ///
  /// In en, this message translates to:
  /// **'blocked'**
  String get statusBlocked;

  /// No description provided for @offerTypeDiscount.
  ///
  /// In en, this message translates to:
  /// **'discount'**
  String get offerTypeDiscount;

  /// No description provided for @offerTypeInstallment.
  ///
  /// In en, this message translates to:
  /// **'installment'**
  String get offerTypeInstallment;

  /// No description provided for @offerTypeRentPromo.
  ///
  /// In en, this message translates to:
  /// **'rent promo'**
  String get offerTypeRentPromo;

  /// No description provided for @unitKindApartment.
  ///
  /// In en, this message translates to:
  /// **'apartment'**
  String get unitKindApartment;

  /// No description provided for @unitKindOffice.
  ///
  /// In en, this message translates to:
  /// **'office'**
  String get unitKindOffice;

  /// No description provided for @unitKindRetail.
  ///
  /// In en, this message translates to:
  /// **'retail'**
  String get unitKindRetail;

  /// No description provided for @dealTypeSale.
  ///
  /// In en, this message translates to:
  /// **'sale'**
  String get dealTypeSale;

  /// No description provided for @dealTypeRent.
  ///
  /// In en, this message translates to:
  /// **'rent'**
  String get dealTypeRent;

  /// No description provided for @leadScoreHot.
  ///
  /// In en, this message translates to:
  /// **'hot'**
  String get leadScoreHot;

  /// No description provided for @leadScoreWarm.
  ///
  /// In en, this message translates to:
  /// **'warm'**
  String get leadScoreWarm;

  /// No description provided for @leadScoreCold.
  ///
  /// In en, this message translates to:
  /// **'cold'**
  String get leadScoreCold;

  /// No description provided for @leadStatusNew.
  ///
  /// In en, this message translates to:
  /// **'new'**
  String get leadStatusNew;

  /// No description provided for @leadStatusContacted.
  ///
  /// In en, this message translates to:
  /// **'contacted'**
  String get leadStatusContacted;

  /// No description provided for @leadStatusScheduled.
  ///
  /// In en, this message translates to:
  /// **'scheduled'**
  String get leadStatusScheduled;

  /// No description provided for @leadStatusVisited.
  ///
  /// In en, this message translates to:
  /// **'visited'**
  String get leadStatusVisited;

  /// No description provided for @leadStatusWon.
  ///
  /// In en, this message translates to:
  /// **'won'**
  String get leadStatusWon;

  /// No description provided for @leadStatusLost.
  ///
  /// In en, this message translates to:
  /// **'lost'**
  String get leadStatusLost;

  /// No description provided for @roleOrdinaryUser.
  ///
  /// In en, this message translates to:
  /// **'ordinary user'**
  String get roleOrdinaryUser;

  /// No description provided for @roleResidenceAdmin.
  ///
  /// In en, this message translates to:
  /// **'residence admin'**
  String get roleResidenceAdmin;

  /// No description provided for @roleSystemAdmin.
  ///
  /// In en, this message translates to:
  /// **'system admin'**
  String get roleSystemAdmin;

  /// No description provided for @leadStatusQualified.
  ///
  /// In en, this message translates to:
  /// **'qualified'**
  String get leadStatusQualified;

  /// No description provided for @documentTypeLicense.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get documentTypeLicense;

  /// No description provided for @documentTypeLicenseHint.
  ///
  /// In en, this message translates to:
  /// **'Construction business license proving the company is legally allowed to act as a developer.'**
  String get documentTypeLicenseHint;

  /// No description provided for @documentTypeConstructionPermit.
  ///
  /// In en, this message translates to:
  /// **'Construction permit'**
  String get documentTypeConstructionPermit;

  /// No description provided for @documentTypeConstructionPermitHint.
  ///
  /// In en, this message translates to:
  /// **'Official local-authority permit to build this specific project.'**
  String get documentTypeConstructionPermitHint;

  /// No description provided for @documentTypeLandRights.
  ///
  /// In en, this message translates to:
  /// **'Land rights'**
  String get documentTypeLandRights;

  /// No description provided for @documentTypeLandRightsHint.
  ///
  /// In en, this message translates to:
  /// **'Document proving ownership or long-term lease rights to the land the project is built on.'**
  String get documentTypeLandRightsHint;

  /// No description provided for @documentTypeProjectDeclaration.
  ///
  /// In en, this message translates to:
  /// **'Project declaration'**
  String get documentTypeProjectDeclaration;

  /// No description provided for @documentTypeProjectDeclarationHint.
  ///
  /// In en, this message translates to:
  /// **'Declaration describing the project — timeline, specifications and the developer — typically required for off-plan sales.'**
  String get documentTypeProjectDeclarationHint;

  /// No description provided for @documentTypeCadastre.
  ///
  /// In en, this message translates to:
  /// **'Cadastre'**
  String get documentTypeCadastre;

  /// No description provided for @documentTypeCadastreHint.
  ///
  /// In en, this message translates to:
  /// **'Cadastral passport for the plot, with its exact boundaries and registry data.'**
  String get documentTypeCadastreHint;

  /// No description provided for @documentStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending review'**
  String get documentStatusPending;

  /// No description provided for @documentStatusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get documentStatusAccepted;

  /// No description provided for @documentStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get documentStatusRejected;

  /// No description provided for @navModeration.
  ///
  /// In en, this message translates to:
  /// **'Moderation'**
  String get navModeration;

  /// No description provided for @navCrm.
  ///
  /// In en, this message translates to:
  /// **'CRM'**
  String get navCrm;

  /// No description provided for @navTickets.
  ///
  /// In en, this message translates to:
  /// **'Tickets'**
  String get navTickets;

  /// No description provided for @moderationTitle.
  ///
  /// In en, this message translates to:
  /// **'Moderation'**
  String get moderationTitle;

  /// No description provided for @moderationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'New residence submissions awaiting review, and flagged reviews.'**
  String get moderationSubtitle;

  /// No description provided for @adminProjectsTitle.
  ///
  /// In en, this message translates to:
  /// **'Residence administration'**
  String get adminProjectsTitle;

  /// No description provided for @adminProjectsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Every residential complex / business centre on the platform — browse how each one is furnished and attached. A system admin never owns a project.'**
  String get adminProjectsSubtitle;

  /// No description provided for @adminProjectsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get adminProjectsFilterAll;

  /// No description provided for @adminProjectsFilterPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get adminProjectsFilterPending;

  /// No description provided for @adminProjectsFilterApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get adminProjectsFilterApproved;

  /// No description provided for @adminProjectsFilterRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get adminProjectsFilterRejected;

  /// No description provided for @adminProjectsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No projects match this filter'**
  String get adminProjectsEmpty;

  /// No description provided for @adminProjectsMeta.
  ///
  /// In en, this message translates to:
  /// **'{count} photos · {units} units'**
  String adminProjectsMeta(int count, String units);

  /// No description provided for @adminProjectsUnpublished.
  ///
  /// In en, this message translates to:
  /// **'Unpublished'**
  String get adminProjectsUnpublished;

  /// No description provided for @crmTitle.
  ///
  /// In en, this message translates to:
  /// **'CRM'**
  String get crmTitle;

  /// No description provided for @crmSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Every lead across every residence — platform-wide demand, not just one project\'s pipeline.'**
  String get crmSubtitle;

  /// No description provided for @crmKanbanHint.
  ///
  /// In en, this message translates to:
  /// **'Drag a card into another column to update its status.'**
  String get crmKanbanHint;

  /// No description provided for @crmSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by phone, project, or manager'**
  String get crmSearchHint;

  /// No description provided for @crmEmpty.
  ///
  /// In en, this message translates to:
  /// **'No leads match this filter'**
  String get crmEmpty;

  /// No description provided for @crmEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get crmEdit;

  /// No description provided for @crmAiAssistant.
  ///
  /// In en, this message translates to:
  /// **'AI assistant'**
  String get crmAiAssistant;

  /// No description provided for @crmAiInsightsTitle.
  ///
  /// In en, this message translates to:
  /// **'AI insights'**
  String get crmAiInsightsTitle;

  /// No description provided for @crmAiInsightsExpand.
  ///
  /// In en, this message translates to:
  /// **'Show AI insights'**
  String get crmAiInsightsExpand;

  /// No description provided for @crmAiInsightsCollapse.
  ///
  /// In en, this message translates to:
  /// **'Hide AI insights'**
  String get crmAiInsightsCollapse;

  /// No description provided for @crmBandFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'AI score'**
  String get crmBandFilterLabel;

  /// No description provided for @crmBandFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get crmBandFilterAll;

  /// No description provided for @crmBandFilterHot.
  ///
  /// In en, this message translates to:
  /// **'Hot'**
  String get crmBandFilterHot;

  /// No description provided for @crmBandFilterWarm.
  ///
  /// In en, this message translates to:
  /// **'Warm'**
  String get crmBandFilterWarm;

  /// No description provided for @crmBandFilterCold.
  ///
  /// In en, this message translates to:
  /// **'Cold'**
  String get crmBandFilterCold;

  /// No description provided for @crmAssignedTo.
  ///
  /// In en, this message translates to:
  /// **'Assigned to {name}'**
  String crmAssignedTo(String name);

  /// No description provided for @crmStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get crmStatusLabel;

  /// No description provided for @crmScoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get crmScoreLabel;

  /// No description provided for @crmAssignedManagerLabel.
  ///
  /// In en, this message translates to:
  /// **'Assigned manager'**
  String get crmAssignedManagerLabel;

  /// No description provided for @crmNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get crmNotesLabel;

  /// No description provided for @crmOwnerLabel.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get crmOwnerLabel;

  /// No description provided for @crmOwnerUnassigned.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get crmOwnerUnassigned;

  /// No description provided for @crmOwnerFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All leads'**
  String get crmOwnerFilterAll;

  /// No description provided for @crmOwnerFilterMine.
  ///
  /// In en, this message translates to:
  /// **'My leads'**
  String get crmOwnerFilterMine;

  /// No description provided for @crmOwnerFilterUnassigned.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get crmOwnerFilterUnassigned;

  /// No description provided for @crmAssignToMe.
  ///
  /// In en, this message translates to:
  /// **'Assign to me'**
  String get crmAssignToMe;

  /// No description provided for @crmAssigneesLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load managers'**
  String get crmAssigneesLoadError;

  /// No description provided for @crmTransferLabel.
  ///
  /// In en, this message translates to:
  /// **'Transfer to'**
  String get crmTransferLabel;

  /// No description provided for @crmTransferHint.
  ///
  /// In en, this message translates to:
  /// **'Hand off to another manager'**
  String get crmTransferHint;

  /// No description provided for @crmTransferNone.
  ///
  /// In en, this message translates to:
  /// **'No transfer'**
  String get crmTransferNone;

  /// No description provided for @crmTransferNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Transfer note'**
  String get crmTransferNoteLabel;

  /// No description provided for @crmLeadEditorTitle.
  ///
  /// In en, this message translates to:
  /// **'Lead CRM'**
  String get crmLeadEditorTitle;

  /// No description provided for @crmTagsLabel.
  ///
  /// In en, this message translates to:
  /// **'Tags (comma-separated)'**
  String get crmTagsLabel;

  /// No description provided for @crmEventHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get crmEventHistoryTitle;

  /// No description provided for @crmEventHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No activity yet'**
  String get crmEventHistoryEmpty;

  /// No description provided for @crmEventAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get crmEventAssigned;

  /// No description provided for @crmEventTransferred.
  ///
  /// In en, this message translates to:
  /// **'Transferred'**
  String get crmEventTransferred;

  /// No description provided for @crmEventUnassigned.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get crmEventUnassigned;

  /// No description provided for @crmEventStatusChanged.
  ///
  /// In en, this message translates to:
  /// **'Status: {detail}'**
  String crmEventStatusChanged(String detail);

  /// No description provided for @crmEventNote.
  ///
  /// In en, this message translates to:
  /// **'Note added'**
  String get crmEventNote;

  /// No description provided for @ticketsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tickets'**
  String get ticketsTitle;

  /// No description provided for @ticketsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Support requests from buyers, renters, developers, and residence admins.'**
  String get ticketsSubtitle;

  /// No description provided for @ticketsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No tickets here'**
  String get ticketsEmpty;

  /// No description provided for @ticketStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get ticketStatusOpen;

  /// No description provided for @ticketStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get ticketStatusInProgress;

  /// No description provided for @ticketStatusResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get ticketStatusResolved;

  /// No description provided for @ticketStatusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get ticketStatusClosed;

  /// No description provided for @ticketCategoryBilling.
  ///
  /// In en, this message translates to:
  /// **'Billing'**
  String get ticketCategoryBilling;

  /// No description provided for @ticketCategoryModeration.
  ///
  /// In en, this message translates to:
  /// **'Moderation'**
  String get ticketCategoryModeration;

  /// No description provided for @ticketCategoryTechnical.
  ///
  /// In en, this message translates to:
  /// **'Technical'**
  String get ticketCategoryTechnical;

  /// No description provided for @ticketCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get ticketCategoryOther;

  /// No description provided for @ticketReplyHint.
  ///
  /// In en, this message translates to:
  /// **'Write a reply…'**
  String get ticketReplyHint;

  /// No description provided for @ticketSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get ticketSend;

  /// No description provided for @ticketNew.
  ///
  /// In en, this message translates to:
  /// **'New ticket'**
  String get ticketNew;

  /// No description provided for @ticketSubjectHint.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get ticketSubjectHint;

  /// No description provided for @ticketMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Describe your question or issue'**
  String get ticketMessageHint;

  /// No description provided for @supportTicketsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reach the platform team — billing, moderation, or a technical issue.'**
  String get supportTicketsSubtitle;

  /// No description provided for @aiCrmPanelTitle.
  ///
  /// In en, this message translates to:
  /// **'Needs attention today'**
  String get aiCrmPanelTitle;

  /// No description provided for @aiCrmPanelSubtitle.
  ///
  /// In en, this message translates to:
  /// **'AI-ranked leads by urgency, with the reasons behind each score.'**
  String get aiCrmPanelSubtitle;

  /// No description provided for @aiCrmOpenBot.
  ///
  /// In en, this message translates to:
  /// **'Open assistant'**
  String get aiCrmOpenBot;

  /// No description provided for @aiCrmEmpty.
  ///
  /// In en, this message translates to:
  /// **'No hot leads right now'**
  String get aiCrmEmpty;

  /// No description provided for @aiCrmUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The AI assistant isn\'t available right now. Try again later.'**
  String get aiCrmUnavailable;

  /// No description provided for @aiMetricLeadVolume.
  ///
  /// In en, this message translates to:
  /// **'Leads today / plan'**
  String get aiMetricLeadVolume;

  /// No description provided for @aiMetricHotLeads.
  ///
  /// In en, this message translates to:
  /// **'Hot leads'**
  String get aiMetricHotLeads;

  /// No description provided for @aiMetricPerManagerAvg.
  ///
  /// In en, this message translates to:
  /// **'Avg. per manager'**
  String get aiMetricPerManagerAvg;

  /// No description provided for @aiMetricResponseSla.
  ///
  /// In en, this message translates to:
  /// **'Median response, min'**
  String get aiMetricResponseSla;

  /// No description provided for @aiMetricSlaBreaches.
  ///
  /// In en, this message translates to:
  /// **'SLA breaches'**
  String get aiMetricSlaBreaches;

  /// No description provided for @aiMetricFunnelWon.
  ///
  /// In en, this message translates to:
  /// **'Won'**
  String get aiMetricFunnelWon;

  /// No description provided for @aiMetricConversion.
  ///
  /// In en, this message translates to:
  /// **'Conversion'**
  String get aiMetricConversion;

  /// No description provided for @aiMetricMinutesSuffix.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get aiMetricMinutesSuffix;

  /// No description provided for @aiReasonHighIntent.
  ///
  /// In en, this message translates to:
  /// **'High intent'**
  String get aiReasonHighIntent;

  /// No description provided for @aiReasonViewingRequested.
  ///
  /// In en, this message translates to:
  /// **'Viewing requested'**
  String get aiReasonViewingRequested;

  /// No description provided for @aiReasonSpecificUnit.
  ///
  /// In en, this message translates to:
  /// **'Asked about a specific unit'**
  String get aiReasonSpecificUnit;

  /// No description provided for @aiReasonPreferredTimeSet.
  ///
  /// In en, this message translates to:
  /// **'Preferred contact time set'**
  String get aiReasonPreferredTimeSet;

  /// No description provided for @aiReasonLongMessage.
  ///
  /// In en, this message translates to:
  /// **'Detailed message'**
  String get aiReasonLongMessage;

  /// No description provided for @aiReasonMortgageInterest.
  ///
  /// In en, this message translates to:
  /// **'Mortgage interest'**
  String get aiReasonMortgageInterest;

  /// No description provided for @aiReasonCashBuyer.
  ///
  /// In en, this message translates to:
  /// **'Cash buyer'**
  String get aiReasonCashBuyer;

  /// No description provided for @aiReasonUrgentKeyword.
  ///
  /// In en, this message translates to:
  /// **'Urgent wording'**
  String get aiReasonUrgentKeyword;

  /// No description provided for @aiReasonRepeatContact.
  ///
  /// In en, this message translates to:
  /// **'Repeat contact'**
  String get aiReasonRepeatContact;

  /// No description provided for @aiReasonRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get aiReasonRecentActivity;

  /// No description provided for @aiReasonNoResponse24h.
  ///
  /// In en, this message translates to:
  /// **'No response in 24h'**
  String get aiReasonNoResponse24h;

  /// No description provided for @aiReasonNoResponse3d.
  ///
  /// In en, this message translates to:
  /// **'No response in 3 days'**
  String get aiReasonNoResponse3d;

  /// No description provided for @aiReasonSlaBreach.
  ///
  /// In en, this message translates to:
  /// **'SLA breached'**
  String get aiReasonSlaBreach;

  /// No description provided for @aiReasonFunnelAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced in funnel'**
  String get aiReasonFunnelAdvanced;

  /// No description provided for @aiReasonStalled.
  ///
  /// In en, this message translates to:
  /// **'Stalled'**
  String get aiReasonStalled;

  /// No description provided for @aiReasonHotProject.
  ///
  /// In en, this message translates to:
  /// **'In-demand project'**
  String get aiReasonHotProject;

  /// No description provided for @aiReasonUnitScarcity.
  ///
  /// In en, this message translates to:
  /// **'Few units left'**
  String get aiReasonUnitScarcity;

  /// No description provided for @aiReasonOffplanInterest.
  ///
  /// In en, this message translates to:
  /// **'Off-plan interest'**
  String get aiReasonOffplanInterest;

  /// No description provided for @aiReasonRentIntent.
  ///
  /// In en, this message translates to:
  /// **'Looking to rent'**
  String get aiReasonRentIntent;

  /// No description provided for @aiReasonLowSpecificity.
  ///
  /// In en, this message translates to:
  /// **'Low specificity'**
  String get aiReasonLowSpecificity;

  /// No description provided for @crmBotTitle.
  ///
  /// In en, this message translates to:
  /// **'AI assistant'**
  String get crmBotTitle;

  /// No description provided for @crmBotBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get crmBotBack;

  /// No description provided for @crmBotActionOpenLead.
  ///
  /// In en, this message translates to:
  /// **'Open lead'**
  String get crmBotActionOpenLead;

  /// No description provided for @crmBotActionAssignToMe.
  ///
  /// In en, this message translates to:
  /// **'Assign to me'**
  String get crmBotActionAssignToMe;

  /// No description provided for @crmBotActionMarkContacted.
  ///
  /// In en, this message translates to:
  /// **'Mark contacted'**
  String get crmBotActionMarkContacted;

  /// No description provided for @crmBotProjectMeta.
  ///
  /// In en, this message translates to:
  /// **'{hot} hot · {open} open · {units} units available'**
  String crmBotProjectMeta(int hot, int open, int units);

  /// No description provided for @crmBotMessageRoot.
  ///
  /// In en, this message translates to:
  /// **'What would you like to see?'**
  String get crmBotMessageRoot;

  /// No description provided for @crmBotMessageHotLeads.
  ///
  /// In en, this message translates to:
  /// **'{count} hot leads need attention today.'**
  String crmBotMessageHotLeads(int count);

  /// No description provided for @crmBotMessageByProject.
  ///
  /// In en, this message translates to:
  /// **'Pick a residence to drill into its leads.'**
  String get crmBotMessageByProject;

  /// No description provided for @crmBotMessageByImportance.
  ///
  /// In en, this message translates to:
  /// **'Leads ranked by importance.'**
  String get crmBotMessageByImportance;

  /// No description provided for @crmBotMessageTodaySummary.
  ///
  /// In en, this message translates to:
  /// **'Here\'s today\'s summary.'**
  String get crmBotMessageTodaySummary;

  /// No description provided for @crmBotMessageWhatNext.
  ///
  /// In en, this message translates to:
  /// **'Here\'s what to do next.'**
  String get crmBotMessageWhatNext;

  /// No description provided for @crmBotMessageProjectMenu.
  ///
  /// In en, this message translates to:
  /// **'Choose what to check for this project.'**
  String get crmBotMessageProjectMenu;

  /// No description provided for @crmBotMessageProjectHot.
  ///
  /// In en, this message translates to:
  /// **'{count} hot leads on this project.'**
  String crmBotMessageProjectHot(int count);

  /// No description provided for @crmBotMessageProjectNoResponse48h.
  ///
  /// In en, this message translates to:
  /// **'{count} leads with no response in 48h.'**
  String crmBotMessageProjectNoResponse48h(int count);

  /// No description provided for @crmBotMessageProjectNewToday.
  ///
  /// In en, this message translates to:
  /// **'{count} new leads today.'**
  String crmBotMessageProjectNewToday(int count);

  /// No description provided for @crmBotMessageProjectFunnel.
  ///
  /// In en, this message translates to:
  /// **'Here\'s the funnel for this project.'**
  String get crmBotMessageProjectFunnel;

  /// No description provided for @crmBotMessageGeneric.
  ///
  /// In en, this message translates to:
  /// **'Here\'s what I found.'**
  String get crmBotMessageGeneric;

  /// No description provided for @crmBotMessageNeedsResponse.
  ///
  /// In en, this message translates to:
  /// **'{count} leads are still waiting for a first reply.'**
  String crmBotMessageNeedsResponse(int count);

  /// No description provided for @crmBotMessageUnassigned.
  ///
  /// In en, this message translates to:
  /// **'{count} open leads have no owner yet.'**
  String crmBotMessageUnassigned(int count);

  /// No description provided for @crmBotMessageByManager.
  ///
  /// In en, this message translates to:
  /// **'Workload across {count} managers.'**
  String crmBotMessageByManager(int count);

  /// No description provided for @crmBotMessageManagerLeads.
  ///
  /// In en, this message translates to:
  /// **'{name} has {count} open leads.'**
  String crmBotMessageManagerLeads(String name, int count);

  /// No description provided for @crmBotMessageAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Which report should I pull?'**
  String get crmBotMessageAnalytics;

  /// No description provided for @crmBotMessageWeekSummary.
  ///
  /// In en, this message translates to:
  /// **'{count} leads came in over the last 7 days.'**
  String crmBotMessageWeekSummary(int count);

  /// No description provided for @crmBotMessageConversion.
  ///
  /// In en, this message translates to:
  /// **'Stage-to-stage conversion across the funnel.'**
  String get crmBotMessageConversion;

  /// No description provided for @crmBotMessageDemand.
  ///
  /// In en, this message translates to:
  /// **'Room mix behind {count} leads that named a home.'**
  String crmBotMessageDemand(int count);

  /// No description provided for @crmBotMessageProjectDemand.
  ///
  /// In en, this message translates to:
  /// **'Demand and availability in {name}.'**
  String crmBotMessageProjectDemand(String name);

  /// No description provided for @crmBotMessageExample.
  ///
  /// In en, this message translates to:
  /// **'No live leads here yet — this is how the answer looks once they start coming in.'**
  String get crmBotMessageExample;

  /// No description provided for @crmBotOptionHotLeads.
  ///
  /// In en, this message translates to:
  /// **'Hot leads'**
  String get crmBotOptionHotLeads;

  /// No description provided for @crmBotOptionByProject.
  ///
  /// In en, this message translates to:
  /// **'By project'**
  String get crmBotOptionByProject;

  /// No description provided for @crmBotOptionByImportance.
  ///
  /// In en, this message translates to:
  /// **'By importance'**
  String get crmBotOptionByImportance;

  /// No description provided for @crmBotOptionTodaySummary.
  ///
  /// In en, this message translates to:
  /// **'Today\'s summary'**
  String get crmBotOptionTodaySummary;

  /// No description provided for @crmBotOptionWhatNext.
  ///
  /// In en, this message translates to:
  /// **'What to do next'**
  String get crmBotOptionWhatNext;

  /// No description provided for @crmBotOptionProjectHot.
  ///
  /// In en, this message translates to:
  /// **'Hot leads'**
  String get crmBotOptionProjectHot;

  /// No description provided for @crmBotOptionProjectNoResponse48h.
  ///
  /// In en, this message translates to:
  /// **'No response in 48h'**
  String get crmBotOptionProjectNoResponse48h;

  /// No description provided for @crmBotOptionProjectNewToday.
  ///
  /// In en, this message translates to:
  /// **'New today'**
  String get crmBotOptionProjectNewToday;

  /// No description provided for @crmBotOptionProjectFunnel.
  ///
  /// In en, this message translates to:
  /// **'Funnel'**
  String get crmBotOptionProjectFunnel;

  /// No description provided for @crmBotOptionBackToRoot.
  ///
  /// In en, this message translates to:
  /// **'Back to start'**
  String get crmBotOptionBackToRoot;

  /// No description provided for @crmBotOptionBackToProjects.
  ///
  /// In en, this message translates to:
  /// **'Back to residences'**
  String get crmBotOptionBackToProjects;

  /// No description provided for @crmBotOptionBackToProjectMenu.
  ///
  /// In en, this message translates to:
  /// **'Back to residence menu'**
  String get crmBotOptionBackToProjectMenu;

  /// No description provided for @crmBotOptionNeedsResponse.
  ///
  /// In en, this message translates to:
  /// **'Waiting for a reply'**
  String get crmBotOptionNeedsResponse;

  /// No description provided for @crmBotOptionUnassigned.
  ///
  /// In en, this message translates to:
  /// **'Without an owner'**
  String get crmBotOptionUnassigned;

  /// No description provided for @crmBotOptionByManager.
  ///
  /// In en, this message translates to:
  /// **'By manager'**
  String get crmBotOptionByManager;

  /// No description provided for @crmBotOptionAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get crmBotOptionAnalytics;

  /// No description provided for @crmBotOptionWeekSummary.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get crmBotOptionWeekSummary;

  /// No description provided for @crmBotOptionConversion.
  ///
  /// In en, this message translates to:
  /// **'Conversion'**
  String get crmBotOptionConversion;

  /// No description provided for @crmBotOptionDemand.
  ///
  /// In en, this message translates to:
  /// **'What buyers ask for'**
  String get crmBotOptionDemand;

  /// No description provided for @crmBotOptionProjectDemand.
  ///
  /// In en, this message translates to:
  /// **'Demand vs availability'**
  String get crmBotOptionProjectDemand;

  /// No description provided for @crmBotOptionBackToAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Back to analytics'**
  String get crmBotOptionBackToAnalytics;

  /// No description provided for @crmBotOptionBackToManagers.
  ///
  /// In en, this message translates to:
  /// **'Back to managers'**
  String get crmBotOptionBackToManagers;

  /// No description provided for @crmBotNodeRoot.
  ///
  /// In en, this message translates to:
  /// **'Assistant'**
  String get crmBotNodeRoot;

  /// No description provided for @crmBotNodeHotLeads.
  ///
  /// In en, this message translates to:
  /// **'Hot leads'**
  String get crmBotNodeHotLeads;

  /// No description provided for @crmBotNodeByProject.
  ///
  /// In en, this message translates to:
  /// **'By project'**
  String get crmBotNodeByProject;

  /// No description provided for @crmBotNodeByImportance.
  ///
  /// In en, this message translates to:
  /// **'By importance'**
  String get crmBotNodeByImportance;

  /// No description provided for @crmBotNodeTodaySummary.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get crmBotNodeTodaySummary;

  /// No description provided for @crmBotNodeWhatNext.
  ///
  /// In en, this message translates to:
  /// **'Next steps'**
  String get crmBotNodeWhatNext;

  /// No description provided for @crmBotNodeProjectMenu.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get crmBotNodeProjectMenu;

  /// No description provided for @crmBotNodeProjectHot.
  ///
  /// In en, this message translates to:
  /// **'Hot'**
  String get crmBotNodeProjectHot;

  /// No description provided for @crmBotNodeProjectNoResponse48h.
  ///
  /// In en, this message translates to:
  /// **'No response 48h'**
  String get crmBotNodeProjectNoResponse48h;

  /// No description provided for @crmBotNodeProjectNewToday.
  ///
  /// In en, this message translates to:
  /// **'New today'**
  String get crmBotNodeProjectNewToday;

  /// No description provided for @crmBotNodeProjectFunnel.
  ///
  /// In en, this message translates to:
  /// **'Funnel'**
  String get crmBotNodeProjectFunnel;

  /// No description provided for @crmBotNodeNeedsResponse.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get crmBotNodeNeedsResponse;

  /// No description provided for @crmBotNodeUnassigned.
  ///
  /// In en, this message translates to:
  /// **'Without an owner'**
  String get crmBotNodeUnassigned;

  /// No description provided for @crmBotNodeByManager.
  ///
  /// In en, this message translates to:
  /// **'Managers'**
  String get crmBotNodeByManager;

  /// No description provided for @crmBotNodeManagerLeads.
  ///
  /// In en, this message translates to:
  /// **'Manager'**
  String get crmBotNodeManagerLeads;

  /// No description provided for @crmBotNodeAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get crmBotNodeAnalytics;

  /// No description provided for @crmBotNodeWeekSummary.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get crmBotNodeWeekSummary;

  /// No description provided for @crmBotNodeConversion.
  ///
  /// In en, this message translates to:
  /// **'Conversion'**
  String get crmBotNodeConversion;

  /// No description provided for @crmBotNodeDemand.
  ///
  /// In en, this message translates to:
  /// **'Demand'**
  String get crmBotNodeDemand;

  /// No description provided for @crmBotNodeProjectDemand.
  ///
  /// In en, this message translates to:
  /// **'Demand'**
  String get crmBotNodeProjectDemand;

  /// No description provided for @crmBotMetricLeadsToday.
  ///
  /// In en, this message translates to:
  /// **'Leads today'**
  String get crmBotMetricLeadsToday;

  /// No description provided for @crmBotMetricHotLeads.
  ///
  /// In en, this message translates to:
  /// **'Hot leads'**
  String get crmBotMetricHotLeads;

  /// No description provided for @crmBotMetricLeadVolume.
  ///
  /// In en, this message translates to:
  /// **'Lead volume'**
  String get crmBotMetricLeadVolume;

  /// No description provided for @crmBotMetricByBand.
  ///
  /// In en, this message translates to:
  /// **'By score band'**
  String get crmBotMetricByBand;

  /// No description provided for @crmBotMetricResponseSla.
  ///
  /// In en, this message translates to:
  /// **'Response SLA'**
  String get crmBotMetricResponseSla;

  /// No description provided for @crmBotMetricFunnel.
  ///
  /// In en, this message translates to:
  /// **'Funnel'**
  String get crmBotMetricFunnel;

  /// No description provided for @crmBotMetricConversion.
  ///
  /// In en, this message translates to:
  /// **'Conversion'**
  String get crmBotMetricConversion;

  /// No description provided for @crmBotMetricGeneric.
  ///
  /// In en, this message translates to:
  /// **'Metric'**
  String get crmBotMetricGeneric;

  /// No description provided for @crmBotMetricLeadsWeek.
  ///
  /// In en, this message translates to:
  /// **'Leads this week'**
  String get crmBotMetricLeadsWeek;

  /// No description provided for @crmBotMetricLeadsPrevWeek.
  ///
  /// In en, this message translates to:
  /// **'Week before'**
  String get crmBotMetricLeadsPrevWeek;

  /// No description provided for @crmBotMetricWonWeek.
  ///
  /// In en, this message translates to:
  /// **'Won this week'**
  String get crmBotMetricWonWeek;

  /// No description provided for @crmBotMetricSlaBreached.
  ///
  /// In en, this message translates to:
  /// **'SLA breaches'**
  String get crmBotMetricSlaBreached;

  /// No description provided for @crmBotMetricConversionStep.
  ///
  /// In en, this message translates to:
  /// **'{from} → {to}'**
  String crmBotMetricConversionStep(String from, String to);

  /// No description provided for @crmBotMetricDemandRooms.
  ///
  /// In en, this message translates to:
  /// **'{rooms}-room requests'**
  String crmBotMetricDemandRooms(int rooms);

  /// No description provided for @crmBotMetricAvailableRooms.
  ///
  /// In en, this message translates to:
  /// **'{rooms}-room available'**
  String crmBotMetricAvailableRooms(int rooms);

  /// No description provided for @crmBotSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Leads, projects and team workload'**
  String get crmBotSubtitle;

  /// No description provided for @crmBotExampleBadge.
  ///
  /// In en, this message translates to:
  /// **'Example'**
  String get crmBotExampleBadge;

  /// No description provided for @crmBotRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get crmBotRetry;

  /// No description provided for @crmBotEmptyCards.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches this question right now.'**
  String get crmBotEmptyCards;

  /// No description provided for @crmBotManagerMeta.
  ///
  /// In en, this message translates to:
  /// **'{open} open · {hot} hot'**
  String crmBotManagerMeta(int open, int hot);

  /// No description provided for @crmBotManagerAvgResponse.
  ///
  /// In en, this message translates to:
  /// **'Avg reply {minutes} min'**
  String crmBotManagerAvgResponse(String minutes);

  /// No description provided for @b2bAiChatFabTooltip.
  ///
  /// In en, this message translates to:
  /// **'Ask iBuild AI'**
  String get b2bAiChatFabTooltip;

  /// No description provided for @b2bAiChatFabLabel.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get b2bAiChatFabLabel;

  /// No description provided for @b2bAiChatTitle.
  ///
  /// In en, this message translates to:
  /// **'iBuild AI'**
  String get b2bAiChatTitle;

  /// No description provided for @b2bAiChatSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ask about projects, leads and analytics'**
  String get b2bAiChatSubtitle;

  /// No description provided for @b2bAiChatQuotaRemaining.
  ///
  /// In en, this message translates to:
  /// **'{remaining} of {limit} left today'**
  String b2bAiChatQuotaRemaining(int remaining, int limit);

  /// No description provided for @b2bAiChatQuotaResetLabel.
  ///
  /// In en, this message translates to:
  /// **'Resets {time}'**
  String b2bAiChatQuotaResetLabel(String time);

  /// No description provided for @b2bAiChatErrorSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t get a reply. Please try again.'**
  String get b2bAiChatErrorSnackbar;

  /// No description provided for @b2bAiChatQuotaExhaustedTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily limit reached'**
  String get b2bAiChatQuotaExhaustedTitle;

  /// No description provided for @b2bAiChatQuotaExhaustedBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used today\'s AI chat messages. Please come back tomorrow.'**
  String get b2bAiChatQuotaExhaustedBody;

  /// No description provided for @b2bAiChatUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'AI assistant is taking a break'**
  String get b2bAiChatUnavailableTitle;

  /// No description provided for @b2bAiChatUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'The assistant is temporarily unavailable. Please try again later.'**
  String get b2bAiChatUnavailableBody;

  /// No description provided for @b2bAiChatForbiddenTitle.
  ///
  /// In en, this message translates to:
  /// **'Not available for this account'**
  String get b2bAiChatForbiddenTitle;

  /// No description provided for @b2bAiChatForbiddenBody.
  ///
  /// In en, this message translates to:
  /// **'AI chat is available to admin accounts only.'**
  String get b2bAiChatForbiddenBody;

  /// No description provided for @b2bAiChatEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Ask the AI assistant anything'**
  String get b2bAiChatEmptyTitle;

  /// No description provided for @b2bAiChatEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Free-form questions about your projects, leads and analytics — try one of the prompts below.'**
  String get b2bAiChatEmptyBody;

  /// No description provided for @b2bAiChatInputHint.
  ///
  /// In en, this message translates to:
  /// **'Message the AI assistant...'**
  String get b2bAiChatInputHint;

  /// No description provided for @b2bAiChatSendTooltip.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get b2bAiChatSendTooltip;

  /// No description provided for @b2bAiChatQuickPromptsLabel.
  ///
  /// In en, this message translates to:
  /// **'Quick prompts'**
  String get b2bAiChatQuickPromptsLabel;

  /// No description provided for @b2bAiChatQuickSystemSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary across all projects'**
  String get b2bAiChatQuickSystemSummary;

  /// No description provided for @b2bAiChatQuickSystemOverdue.
  ///
  /// In en, this message translates to:
  /// **'Where are lead responses overdue?'**
  String get b2bAiChatQuickSystemOverdue;

  /// No description provided for @b2bAiChatQuickSystemAttention.
  ///
  /// In en, this message translates to:
  /// **'Which projects need attention?'**
  String get b2bAiChatQuickSystemAttention;

  /// No description provided for @b2bAiChatQuickResidenceSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary of my project'**
  String get b2bAiChatQuickResidenceSummary;

  /// No description provided for @b2bAiChatQuickResidenceHotLeads.
  ///
  /// In en, this message translates to:
  /// **'Show me hot leads'**
  String get b2bAiChatQuickResidenceHotLeads;

  /// No description provided for @b2bAiChatQuickResidenceWeekChanges.
  ///
  /// In en, this message translates to:
  /// **'What changed this week?'**
  String get b2bAiChatQuickResidenceWeekChanges;

  /// No description provided for @readinessStageEarthworks.
  ///
  /// In en, this message translates to:
  /// **'Earthworks'**
  String get readinessStageEarthworks;

  /// No description provided for @readinessStageFoundation.
  ///
  /// In en, this message translates to:
  /// **'Foundation'**
  String get readinessStageFoundation;

  /// No description provided for @readinessStageFrameFloors.
  ///
  /// In en, this message translates to:
  /// **'Frame & floors'**
  String get readinessStageFrameFloors;

  /// No description provided for @readinessStageRoofing.
  ///
  /// In en, this message translates to:
  /// **'Roofing'**
  String get readinessStageRoofing;

  /// No description provided for @readinessStageFacade.
  ///
  /// In en, this message translates to:
  /// **'Facade'**
  String get readinessStageFacade;

  /// No description provided for @readinessStageUtilities.
  ///
  /// In en, this message translates to:
  /// **'Utilities'**
  String get readinessStageUtilities;

  /// No description provided for @readinessStageInteriorFinishing.
  ///
  /// In en, this message translates to:
  /// **'Interior finishing'**
  String get readinessStageInteriorFinishing;

  /// No description provided for @readinessStageLandscaping.
  ///
  /// In en, this message translates to:
  /// **'Landscaping'**
  String get readinessStageLandscaping;

  /// No description provided for @readinessStatusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get readinessStatusConfirmed;

  /// No description provided for @readinessStatusRequiresManualReview.
  ///
  /// In en, this message translates to:
  /// **'Needs manual review'**
  String get readinessStatusRequiresManualReview;

  /// No description provided for @readinessStatusDiscrepancyFound.
  ///
  /// In en, this message translates to:
  /// **'Discrepancy found'**
  String get readinessStatusDiscrepancyFound;

  /// No description provided for @readinessStatusViolationFound.
  ///
  /// In en, this message translates to:
  /// **'Violation found'**
  String get readinessStatusViolationFound;

  /// No description provided for @readinessCheckDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'AI construction readiness check'**
  String get readinessCheckDialogTitle;

  /// No description provided for @readinessAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'Checking the photo with AI…'**
  String get readinessAnalyzing;

  /// No description provided for @readinessConfidenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Confidence: {percent}%'**
  String readinessConfidenceLabel(int percent);

  /// No description provided for @readinessUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'AI check unavailable'**
  String get readinessUnavailableTitle;

  /// No description provided for @readinessUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'The readiness check couldn\'t run right now. You can proceed without it — the report will upload as usual.'**
  String get readinessUnavailableMessage;

  /// No description provided for @readinessProceedWithoutCheck.
  ///
  /// In en, this message translates to:
  /// **'Proceed without check'**
  String get readinessProceedWithoutCheck;

  /// No description provided for @readinessAckAndUpload.
  ///
  /// In en, this message translates to:
  /// **'Understood, upload'**
  String get readinessAckAndUpload;

  /// No description provided for @readinessConfirmedProceeding.
  ///
  /// In en, this message translates to:
  /// **'Confirmed — uploading…'**
  String get readinessConfirmedProceeding;

  /// No description provided for @readinessReshoot.
  ///
  /// In en, this message translates to:
  /// **'Retake photo'**
  String get readinessReshoot;

  /// No description provided for @readinessOverrideUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload anyway'**
  String get readinessOverrideUpload;

  /// No description provided for @readinessOverrideCommentLabel.
  ///
  /// In en, this message translates to:
  /// **'Explain why you\'re uploading anyway'**
  String get readinessOverrideCommentLabel;

  /// No description provided for @readinessOverrideCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Required — describe the discrepancy the AI flagged'**
  String get readinessOverrideCommentHint;

  /// No description provided for @readinessDigestTitle.
  ///
  /// In en, this message translates to:
  /// **'AI consultant on objects'**
  String get readinessDigestTitle;

  /// No description provided for @readinessDigestEmpty.
  ///
  /// In en, this message translates to:
  /// **'No AI-verified reports yet.'**
  String get readinessDigestEmpty;

  /// No description provided for @readinessDigestTrend.
  ///
  /// In en, this message translates to:
  /// **'{confirmed} of the last {total} reports confirmed'**
  String readinessDigestTrend(int confirmed, int total);

  /// No description provided for @readinessDigestOutstandingTitle.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get readinessDigestOutstandingTitle;

  /// No description provided for @verifStage1Ok.
  ///
  /// In en, this message translates to:
  /// **'Image passed validity checks.'**
  String get verifStage1Ok;

  /// No description provided for @verifStage1ImageUnreadable.
  ///
  /// In en, this message translates to:
  /// **'The image couldn\'t be read or decoded.'**
  String get verifStage1ImageUnreadable;

  /// No description provided for @verifStage1LowQuality.
  ///
  /// In en, this message translates to:
  /// **'Image quality too low (blur {blur}, exposure {exposure}).'**
  String verifStage1LowQuality(Object blur, Object exposure);

  /// No description provided for @verifStage1MetadataMissing.
  ///
  /// In en, this message translates to:
  /// **'Photo metadata is missing.'**
  String get verifStage1MetadataMissing;

  /// No description provided for @verifStage1GeotagMissing.
  ///
  /// In en, this message translates to:
  /// **'Photo has no location tag.'**
  String get verifStage1GeotagMissing;

  /// No description provided for @verifStage1GeotagFarFromObject.
  ///
  /// In en, this message translates to:
  /// **'Photo location is {distanceKm} km from the site (allowed radius {radiusKm} km).'**
  String verifStage1GeotagFarFromObject(Object distanceKm, Object radiusKm);

  /// No description provided for @verifStage1DateInFuture.
  ///
  /// In en, this message translates to:
  /// **'Photo date ({takenAt}) is in the future.'**
  String verifStage1DateInFuture(String takenAt);

  /// No description provided for @verifStage1DateOutsideWindow.
  ///
  /// In en, this message translates to:
  /// **'Photo date ({takenAt}) is outside the {windowDays}-day window.'**
  String verifStage1DateOutsideWindow(String takenAt, int windowDays);

  /// No description provided for @verifInsufficientData.
  ///
  /// In en, this message translates to:
  /// **'Not enough data to complete this check.'**
  String get verifInsufficientData;

  /// No description provided for @verifStage1EvidenceDecoded.
  ///
  /// In en, this message translates to:
  /// **'Decoded {width}×{height}px, {bytes} bytes.'**
  String verifStage1EvidenceDecoded(int width, int height, int bytes);

  /// No description provided for @verifStage1EvidenceExifDate.
  ///
  /// In en, this message translates to:
  /// **'EXIF date: {takenAt}.'**
  String verifStage1EvidenceExifDate(String takenAt);

  /// No description provided for @verifStage1EvidenceNoExif.
  ///
  /// In en, this message translates to:
  /// **'No EXIF data found.'**
  String get verifStage1EvidenceNoExif;

  /// No description provided for @verifStage1EvidenceGeoDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance to site: {distanceKm} km (radius {radiusKm} km).'**
  String verifStage1EvidenceGeoDistance(Object distanceKm, Object radiusKm);

  /// No description provided for @verifStage1EvidenceSharpness.
  ///
  /// In en, this message translates to:
  /// **'Sharpness score {blur} (threshold {threshold}).'**
  String verifStage1EvidenceSharpness(Object blur, Object threshold);

  /// No description provided for @verifStage2Ok.
  ///
  /// In en, this message translates to:
  /// **'No duplicate of a previous report found.'**
  String get verifStage2Ok;

  /// No description provided for @verifStage2NoPriorReports.
  ///
  /// In en, this message translates to:
  /// **'No previous reports to compare against.'**
  String get verifStage2NoPriorReports;

  /// No description provided for @verifStage2NearDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Very similar to report {reportId} from {takenAt} (distance {distance}).'**
  String verifStage2NearDuplicate(
    Object distance,
    String reportId,
    String takenAt,
  );

  /// No description provided for @verifStage2DuplicateFound.
  ///
  /// In en, this message translates to:
  /// **'Duplicate of report {reportId} from {takenAt} (distance {distance}).'**
  String verifStage2DuplicateFound(
    Object distance,
    String reportId,
    String takenAt,
  );

  /// No description provided for @verifStage2EvidenceComparedCount.
  ///
  /// In en, this message translates to:
  /// **'Compared against {count} previous photos.'**
  String verifStage2EvidenceComparedCount(int count);

  /// No description provided for @verifStage2EvidenceHammingDistance.
  ///
  /// In en, this message translates to:
  /// **'Hamming distance {distance} vs threshold {threshold} (report {reportId}).'**
  String verifStage2EvidenceHammingDistance(
    Object distance,
    Object threshold,
    String reportId,
  );

  /// No description provided for @verifStage3Ok.
  ///
  /// In en, this message translates to:
  /// **'Classified as {stage} ({confidence} confidence).'**
  String verifStage3Ok(String stage, Object confidence);

  /// No description provided for @verifStage3NotConstructionSite.
  ///
  /// In en, this message translates to:
  /// **'Doesn\'t look like a construction site ({confidence} confidence).'**
  String verifStage3NotConstructionSite(Object confidence);

  /// No description provided for @verifStage3StageUnclear.
  ///
  /// In en, this message translates to:
  /// **'Construction stage unclear ({confidence} confidence).'**
  String verifStage3StageUnclear(Object confidence);

  /// No description provided for @verifStage3EvidenceClassified.
  ///
  /// In en, this message translates to:
  /// **'Detected stage: {stage} ({confidence}).'**
  String verifStage3EvidenceClassified(String stage, Object confidence);

  /// No description provided for @verifStage3EvidenceFeatures.
  ///
  /// In en, this message translates to:
  /// **'Sky {skyRatio}, soil {soilRatio}, concrete {concreteRatio}, vegetation {vegetationRatio}, edges {verticalEdgeDensity}, openings {openingPeriodicity}.'**
  String verifStage3EvidenceFeatures(
    Object skyRatio,
    Object soilRatio,
    Object concreteRatio,
    Object vegetationRatio,
    Object verticalEdgeDensity,
    Object openingPeriodicity,
  );

  /// No description provided for @verifStage4Ok.
  ///
  /// In en, this message translates to:
  /// **'Matches the declared stage ({declaredStage}).'**
  String verifStage4Ok(String declaredStage);

  /// No description provided for @verifStage4NoDeclaredStage.
  ///
  /// In en, this message translates to:
  /// **'No declared stage was provided.'**
  String get verifStage4NoDeclaredStage;

  /// No description provided for @verifStage4AdjacentStageMismatch.
  ///
  /// In en, this message translates to:
  /// **'Declared {declaredStage}, but looks like the adjacent stage {detectedStage}.'**
  String verifStage4AdjacentStageMismatch(
    String declaredStage,
    String detectedStage,
  );

  /// No description provided for @verifStage4StageMismatch.
  ///
  /// In en, this message translates to:
  /// **'Declared {declaredStage}, but detected {detectedStage} (distance {distance}).'**
  String verifStage4StageMismatch(
    String declaredStage,
    String detectedStage,
    Object distance,
  );

  /// No description provided for @verifStage4EvidenceComparison.
  ///
  /// In en, this message translates to:
  /// **'Declared {declaredStage} vs detected {detectedStage} ({ordinalDistance} stages apart).'**
  String verifStage4EvidenceComparison(
    String declaredStage,
    String detectedStage,
    int ordinalDistance,
  );

  /// No description provided for @verifStage5Ok.
  ///
  /// In en, this message translates to:
  /// **'Progress since the previous report ({previousTakenAt}) looks consistent.'**
  String verifStage5Ok(String previousTakenAt);

  /// No description provided for @verifStage5NoPreviousReport.
  ///
  /// In en, this message translates to:
  /// **'No previous report to compare progress against.'**
  String get verifStage5NoPreviousReport;

  /// No description provided for @verifStage5NoVisibleProgress.
  ///
  /// In en, this message translates to:
  /// **'No visible progress since {previousTakenAt} (distance {distance}).'**
  String verifStage5NoVisibleProgress(Object distance, String previousTakenAt);

  /// No description provided for @verifStage5RegressionDetected.
  ///
  /// In en, this message translates to:
  /// **'Looks like a regression: was {previousStage}, now {detectedStage}.'**
  String verifStage5RegressionDetected(
    String previousStage,
    String detectedStage,
  );

  /// No description provided for @verifStage5ProgressNotDeclared.
  ///
  /// In en, this message translates to:
  /// **'Progress changed but wasn\'t declared.'**
  String get verifStage5ProgressNotDeclared;

  /// No description provided for @verifStage5EvidenceSimilarity.
  ///
  /// In en, this message translates to:
  /// **'Similarity {distance} vs threshold {threshold} (report {previousReportId}, {previousTakenAt}).'**
  String verifStage5EvidenceSimilarity(
    Object distance,
    Object threshold,
    String previousReportId,
    String previousTakenAt,
  );

  /// No description provided for @verifStage5EvidenceProgressDelta.
  ///
  /// In en, this message translates to:
  /// **'Progress {previousPercent}% → {currentPercent}%.'**
  String verifStage5EvidenceProgressDelta(
    Object previousPercent,
    Object currentPercent,
  );

  /// No description provided for @verifStage5EvidenceDeveloperComment.
  ///
  /// In en, this message translates to:
  /// **'Developer comment attached.'**
  String get verifStage5EvidenceDeveloperComment;

  /// No description provided for @verifStage6Ok.
  ///
  /// In en, this message translates to:
  /// **'No safety or violation indicators found.'**
  String get verifStage6Ok;

  /// No description provided for @verifStage6SafetyGearAbsent.
  ///
  /// In en, this message translates to:
  /// **'No safety gear visible on site.'**
  String get verifStage6SafetyGearAbsent;

  /// No description provided for @verifStage6StructuralDamage.
  ///
  /// In en, this message translates to:
  /// **'Possible structural damage detected ({ratio}).'**
  String verifStage6StructuralDamage(Object ratio);

  /// No description provided for @verifStage6WorkStoppage.
  ///
  /// In en, this message translates to:
  /// **'Signs of a work stoppage.'**
  String get verifStage6WorkStoppage;

  /// No description provided for @verifStage6DebrisAccumulation.
  ///
  /// In en, this message translates to:
  /// **'Debris accumulation detected (score {score}).'**
  String verifStage6DebrisAccumulation(Object score);

  /// No description provided for @verifStage6AmbiguousIndicator.
  ///
  /// In en, this message translates to:
  /// **'Ambiguous indicator: {indicator}.'**
  String verifStage6AmbiguousIndicator(String indicator);

  /// No description provided for @verifStage6EvidenceHiVisRatio.
  ///
  /// In en, this message translates to:
  /// **'Hi-vis gear ratio {ratio} (threshold {threshold}).'**
  String verifStage6EvidenceHiVisRatio(Object ratio, Object threshold);

  /// No description provided for @verifStage6EvidenceCrackPixels.
  ///
  /// In en, this message translates to:
  /// **'Crack pixel ratio {ratio} (threshold {threshold}).'**
  String verifStage6EvidenceCrackPixels(Object ratio, Object threshold);

  /// No description provided for @verifStage6EvidenceNoEquipment.
  ///
  /// In en, this message translates to:
  /// **'No equipment detected in frame.'**
  String get verifStage6EvidenceNoEquipment;

  /// No description provided for @verifStage6EvidenceDebrisTexture.
  ///
  /// In en, this message translates to:
  /// **'Debris texture score {score}.'**
  String verifStage6EvidenceDebrisTexture(Object score);

  /// No description provided for @verifStage7Confirmed.
  ///
  /// In en, this message translates to:
  /// **'All checks passed — confirmed.'**
  String get verifStage7Confirmed;

  /// No description provided for @verifStage7ManualReview.
  ///
  /// In en, this message translates to:
  /// **'{warnings} warning(s) — needs manual review.'**
  String verifStage7ManualReview(int warnings);

  /// No description provided for @verifStage7NotReached.
  ///
  /// In en, this message translates to:
  /// **'Checks stopped at {stoppedAt}.'**
  String verifStage7NotReached(String stoppedAt);

  /// No description provided for @verifStage7EvidenceStageSummary.
  ///
  /// In en, this message translates to:
  /// **'{passed} passed, {warnings} warnings, {failed} failed.'**
  String verifStage7EvidenceStageSummary(int passed, int warnings, int failed);

  /// No description provided for @verifSummaryConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed: {detectedStage} stage, {progressPercent}% progress.'**
  String verifSummaryConfirmed(String detectedStage, Object progressPercent);

  /// No description provided for @verifSummaryManualReview.
  ///
  /// In en, this message translates to:
  /// **'This {stage} photo needs a quick manual review.'**
  String verifSummaryManualReview(String stage);

  /// No description provided for @verifSummaryDiscrepancy.
  ///
  /// In en, this message translates to:
  /// **'At the {stage} check, declared {declaredStage} doesn\'t match detected {detectedStage}.'**
  String verifSummaryDiscrepancy(
    String stage,
    String declaredStage,
    String detectedStage,
  );

  /// No description provided for @verifSummaryViolation.
  ///
  /// In en, this message translates to:
  /// **'At the {stage} check, a violation indicator was found: {indicator}.'**
  String verifSummaryViolation(String stage, String indicator);
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
      <String>['en', 'ru', 'uz'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
    case 'uz':
      return AppLocalizationsUz();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
