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

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// No description provided for @navFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get navFavorites;

  /// No description provided for @navInquiries.
  ///
  /// In en, this message translates to:
  /// **'Inquiries'**
  String get navInquiries;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @onboardingEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Buy from the developer. Safely. In one app.'**
  String get onboardingEyebrow;

  /// No description provided for @onboardingDescription.
  ///
  /// In en, this message translates to:
  /// **'Compare verified new builds, see live availability, and send an enquiry straight to the developer — no middlemen, no guesswork.'**
  String get onboardingDescription;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @startDemo.
  ///
  /// In en, this message translates to:
  /// **'Start (demo)'**
  String get startDemo;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

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
  /// **'You\'re exploring iBuild in read-only demo mode. Browse every screen and feature — nothing you do will be saved to the database.'**
  String get demoModeMessage;

  /// No description provided for @demoModeGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get demoModeGotIt;

  /// No description provided for @demoModeBanner.
  ///
  /// In en, this message translates to:
  /// **'Demo mode — changes are not saved'**
  String get demoModeBanner;

  /// No description provided for @demoWriteBlocked.
  ///
  /// In en, this message translates to:
  /// **'Demo mode is view-only — this action was not saved.'**
  String get demoWriteBlocked;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to iBuild'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with your phone number'**
  String get welcomeSubtitle;

  /// No description provided for @phoneHint.
  ///
  /// In en, this message translates to:
  /// **'+998 90 123 45 67'**
  String get phoneHint;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get sendCode;

  /// No description provided for @phoneRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get phoneRequiredError;

  /// No description provided for @otpTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the code'**
  String get otpTitle;

  /// No description provided for @otpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to {phone}'**
  String otpSubtitle(String phone);

  /// No description provided for @otpCodeHint.
  ///
  /// In en, this message translates to:
  /// **'6-digit code'**
  String get otpCodeHint;

  /// No description provided for @otpDevHint.
  ///
  /// In en, this message translates to:
  /// **'Test mode'**
  String get otpDevHint;

  /// No description provided for @stepOneOfTwo.
  ///
  /// In en, this message translates to:
  /// **'Step 1 of 2'**
  String get stepOneOfTwo;

  /// No description provided for @stepTwoOfTwo.
  ///
  /// In en, this message translates to:
  /// **'Step 2 of 2'**
  String get stepTwoOfTwo;

  /// No description provided for @verifyCode.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verifyCode;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resendCode;

  /// No description provided for @invalidCodeError.
  ///
  /// In en, this message translates to:
  /// **'Invalid or expired code. Please try again.'**
  String get invalidCodeError;

  /// No description provided for @signedInLabel.
  ///
  /// In en, this message translates to:
  /// **'Signed in'**
  String get signedInLabel;

  /// No description provided for @accountTypeOrdinaryUser.
  ///
  /// In en, this message translates to:
  /// **'Ordinary user'**
  String get accountTypeOrdinaryUser;

  /// No description provided for @signInPromptMessage.
  ///
  /// In en, this message translates to:
  /// **'Sign in to save favorites, track inquiries and get updates.'**
  String get signInPromptMessage;

  /// No description provided for @madeForYou.
  ///
  /// In en, this message translates to:
  /// **'Made for You'**
  String get madeForYou;

  /// No description provided for @exploreProperties.
  ///
  /// In en, this message translates to:
  /// **'Explore Properties'**
  String get exploreProperties;

  /// No description provided for @recommendForYou.
  ///
  /// In en, this message translates to:
  /// **'Recommend for You'**
  String get recommendForYou;

  /// No description provided for @statsListingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Listings'**
  String get statsListingsLabel;

  /// No description provided for @statsAvailableLabel.
  ///
  /// In en, this message translates to:
  /// **'Available units'**
  String get statsAvailableLabel;

  /// No description provided for @statsDistrictsLabel.
  ///
  /// In en, this message translates to:
  /// **'Districts'**
  String get statsDistrictsLabel;

  /// No description provided for @statsRatingLabel.
  ///
  /// In en, this message translates to:
  /// **'Avg. rating'**
  String get statsRatingLabel;

  /// No description provided for @featuredForYouTitle.
  ///
  /// In en, this message translates to:
  /// **'Featured for you'**
  String get featuredForYouTitle;

  /// No description provided for @popularDistrictsTitle.
  ///
  /// In en, this message translates to:
  /// **'Popular districts'**
  String get popularDistrictsTitle;

  /// No description provided for @developersTitle.
  ///
  /// In en, this message translates to:
  /// **'Developers'**
  String get developersTitle;

  /// No description provided for @developerProjectsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 project} other{{count} projects}}'**
  String developerProjectsCount(int count);

  /// No description provided for @developerContactsTitle.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get developerContactsTitle;

  /// No description provided for @developerResidencesTitle.
  ///
  /// In en, this message translates to:
  /// **'Residences'**
  String get developerResidencesTitle;

  /// No description provided for @developerOfficesTitle.
  ///
  /// In en, this message translates to:
  /// **'Offices'**
  String get developerOfficesTitle;

  /// No description provided for @developerNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Developer not found'**
  String get developerNotFoundTitle;

  /// No description provided for @developerNotFoundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This developer is no longer in our catalogue.'**
  String get developerNotFoundSubtitle;

  /// No description provided for @districtListingsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} listings'**
  String districtListingsCount(int count);

  /// No description provided for @promoBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'New off-plan launches'**
  String get promoBannerTitle;

  /// No description provided for @promoBannerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reserve early with flexible installments on select new builds.'**
  String get promoBannerSubtitle;

  /// No description provided for @promoBannerAction.
  ///
  /// In en, this message translates to:
  /// **'Explore new builds'**
  String get promoBannerAction;

  /// No description provided for @browseListingsAction.
  ///
  /// In en, this message translates to:
  /// **'Browse listings'**
  String get browseListingsAction;

  /// No description provided for @modeBuy.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get modeBuy;

  /// No description provided for @modeRent.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get modeRent;

  /// No description provided for @modeNewBuilds.
  ///
  /// In en, this message translates to:
  /// **'New builds'**
  String get modeNewBuilds;

  /// No description provided for @categoryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get categoryAll;

  /// No description provided for @categoryApartments.
  ///
  /// In en, this message translates to:
  /// **'Apartments'**
  String get categoryApartments;

  /// No description provided for @categoryOffices.
  ///
  /// In en, this message translates to:
  /// **'Offices'**
  String get categoryOffices;

  /// No description provided for @bestDeal.
  ///
  /// In en, this message translates to:
  /// **'Best Deal'**
  String get bestDeal;

  /// No description provided for @discountBadge.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discountBadge;

  /// No description provided for @installmentBadge.
  ///
  /// In en, this message translates to:
  /// **'Installments'**
  String get installmentBadge;

  /// No description provided for @unitsAvailableCount.
  ///
  /// In en, this message translates to:
  /// **'{count} available'**
  String unitsAvailableCount(int count);

  /// No description provided for @searchByLocations.
  ///
  /// In en, this message translates to:
  /// **'Search by locations'**
  String get searchByLocations;

  /// No description provided for @liveLocationDistrict.
  ///
  /// In en, this message translates to:
  /// **'Live location · {district}'**
  String liveLocationDistrict(String district);

  /// No description provided for @mapZoomIn.
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get mapZoomIn;

  /// No description provided for @mapZoomOut.
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get mapZoomOut;

  /// No description provided for @tabUnits.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get tabUnits;

  /// No description provided for @tabFloorPlans.
  ///
  /// In en, this message translates to:
  /// **'Floor plans'**
  String get tabFloorPlans;

  /// No description provided for @tabAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get tabAbout;

  /// No description provided for @tabReviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get tabReviews;

  /// No description provided for @tabProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get tabProgress;

  /// No description provided for @overallProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Overall construction progress'**
  String get overallProgressTitle;

  /// No description provided for @actualProgressLabel.
  ///
  /// In en, this message translates to:
  /// **'Actual construction progress'**
  String get actualProgressLabel;

  /// No description provided for @plannedProgressLabel.
  ///
  /// In en, this message translates to:
  /// **'Planned construction progress'**
  String get plannedProgressLabel;

  /// No description provided for @progressOnSchedule.
  ///
  /// In en, this message translates to:
  /// **'On schedule'**
  String get progressOnSchedule;

  /// No description provided for @progressAheadOfSchedule.
  ///
  /// In en, this message translates to:
  /// **'Ahead of schedule'**
  String get progressAheadOfSchedule;

  /// No description provided for @progressAcceptableDeviation.
  ///
  /// In en, this message translates to:
  /// **'Acceptable deviation'**
  String get progressAcceptableDeviation;

  /// No description provided for @progressBehindSchedule.
  ///
  /// In en, this message translates to:
  /// **'Behind schedule'**
  String get progressBehindSchedule;

  /// No description provided for @progressDeviation.
  ///
  /// In en, this message translates to:
  /// **'Deviation {percent}%'**
  String progressDeviation(int percent);

  /// No description provided for @trustIndexLabel.
  ///
  /// In en, this message translates to:
  /// **'Trust index {percent}%'**
  String trustIndexLabel(int percent);

  /// No description provided for @progressComparisonNote.
  ///
  /// In en, this message translates to:
  /// **'A gap of up to 15% is normal on a building site: weather, seasonal work bans and supply delays. Above 15% the platform sends the project for inspection.'**
  String get progressComparisonNote;

  /// No description provided for @progressEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No photo reports yet'**
  String get progressEmptyTitle;

  /// No description provided for @progressEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Dated construction photos will appear here as the developer uploads them.'**
  String get progressEmptySubtitle;

  /// No description provided for @noReviewsYet.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get noReviewsYet;

  /// No description provided for @reviewsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Be the first to share how it went — or ask us anything first.'**
  String get reviewsEmptySubtitle;

  /// No description provided for @writeReviewAction.
  ///
  /// In en, this message translates to:
  /// **'Write a review'**
  String get writeReviewAction;

  /// No description provided for @submitReviewAction.
  ///
  /// In en, this message translates to:
  /// **'Submit review'**
  String get submitReviewAction;

  /// No description provided for @reviewBodyHint.
  ///
  /// In en, this message translates to:
  /// **'Share your experience with this project...'**
  String get reviewBodyHint;

  /// No description provided for @reviewsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} reviews'**
  String reviewsCount(int count);

  /// No description provided for @flagReviewAction.
  ///
  /// In en, this message translates to:
  /// **'Report review'**
  String get flagReviewAction;

  /// No description provided for @reviewFlaggedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Thanks — we\'ll take a look'**
  String get reviewFlaggedSnackbar;

  /// No description provided for @viewUnitGrid.
  ///
  /// In en, this message translates to:
  /// **'View unit grid'**
  String get viewUnitGrid;

  /// No description provided for @requestCallback.
  ///
  /// In en, this message translates to:
  /// **'Request a callback'**
  String get requestCallback;

  /// No description provided for @fromPrice.
  ///
  /// In en, this message translates to:
  /// **'From {price}'**
  String fromPrice(String price);

  /// No description provided for @rentFromPrice.
  ///
  /// In en, this message translates to:
  /// **'Rent from {price}'**
  String rentFromPrice(String price);

  /// No description provided for @noDescription.
  ///
  /// In en, this message translates to:
  /// **'No description.'**
  String get noDescription;

  /// No description provided for @amenitiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Amenities'**
  String get amenitiesTitle;

  /// No description provided for @projectDetailsMenu.
  ///
  /// In en, this message translates to:
  /// **'Project details'**
  String get projectDetailsMenu;

  /// No description provided for @offersInstallmentsMenu.
  ///
  /// In en, this message translates to:
  /// **'Offers & installments'**
  String get offersInstallmentsMenu;

  /// No description provided for @supportMenu.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get supportMenu;

  /// No description provided for @noneLabel.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get noneLabel;

  /// No description provided for @activeOffersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} active'**
  String activeOffersCount(int count);

  /// No description provided for @requestCallbackTrailing.
  ///
  /// In en, this message translates to:
  /// **'Request callback'**
  String get requestCallbackTrailing;

  /// No description provided for @builtPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}% built'**
  String builtPercent(int percent);

  /// No description provided for @completionDate.
  ///
  /// In en, this message translates to:
  /// **'Completion: {date}'**
  String completionDate(String date);

  /// No description provided for @readyToMoveIn.
  ///
  /// In en, this message translates to:
  /// **'Ready to move in'**
  String get readyToMoveIn;

  /// No description provided for @handedOverToResidents.
  ///
  /// In en, this message translates to:
  /// **'Handed over to residents'**
  String get handedOverToResidents;

  /// No description provided for @offersSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Offers'**
  String get offersSheetTitle;

  /// No description provided for @noActiveOffers.
  ///
  /// In en, this message translates to:
  /// **'No active offers for this project yet.'**
  String get noActiveOffers;

  /// No description provided for @iBuildPartner.
  ///
  /// In en, this message translates to:
  /// **'iBuild partner'**
  String get iBuildPartner;

  /// No description provided for @verifiedBadgeLabel.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verifiedBadgeLabel;

  /// No description provided for @verificationPendingBadgeLabel.
  ///
  /// In en, this message translates to:
  /// **'Verification in progress'**
  String get verificationPendingBadgeLabel;

  /// No description provided for @verificationDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'\"Verified\" means iBuild has checked the developer\'s submitted documents against public government registries as of the date shown. It is not a guarantee of construction completion, nor legal or financial advice — please verify current details yourself before making a decision.'**
  String get verificationDisclaimer;

  /// No description provided for @documentTypeLicense.
  ///
  /// In en, this message translates to:
  /// **'Business license'**
  String get documentTypeLicense;

  /// No description provided for @documentTypeConstructionPermit.
  ///
  /// In en, this message translates to:
  /// **'Construction permit'**
  String get documentTypeConstructionPermit;

  /// No description provided for @documentTypeLandRights.
  ///
  /// In en, this message translates to:
  /// **'Land rights'**
  String get documentTypeLandRights;

  /// No description provided for @documentTypeProjectDeclaration.
  ///
  /// In en, this message translates to:
  /// **'Project declaration'**
  String get documentTypeProjectDeclaration;

  /// No description provided for @documentTypeCadastre.
  ///
  /// In en, this message translates to:
  /// **'Cadastre'**
  String get documentTypeCadastre;

  /// No description provided for @documentStatusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get documentStatusAccepted;

  /// No description provided for @documentStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get documentStatusPending;

  /// No description provided for @documentStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get documentStatusRejected;

  /// No description provided for @documentStatusMissing.
  ///
  /// In en, this message translates to:
  /// **'Not submitted'**
  String get documentStatusMissing;

  /// No description provided for @availabilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get availabilityTitle;

  /// No description provided for @legendSoldRented.
  ///
  /// In en, this message translates to:
  /// **'Sold / Rented'**
  String get legendSoldRented;

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

  /// No description provided for @unitFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unitFallbackTitle;

  /// No description provided for @unitNumberTitle.
  ///
  /// In en, this message translates to:
  /// **'Unit {number}'**
  String unitNumberTitle(String number);

  /// No description provided for @unitNotFound.
  ///
  /// In en, this message translates to:
  /// **'Unit not found'**
  String get unitNotFound;

  /// No description provided for @roomsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} rooms'**
  String roomsCount(int count);

  /// No description provided for @floorLabel.
  ///
  /// In en, this message translates to:
  /// **'Floor {floor}'**
  String floorLabel(int floor);

  /// No description provided for @viewLabel.
  ///
  /// In en, this message translates to:
  /// **'{view} view'**
  String viewLabel(String view);

  /// No description provided for @offplanInstallmentBadge.
  ///
  /// In en, this message translates to:
  /// **'Off-plan · installment available'**
  String get offplanInstallmentBadge;

  /// No description provided for @minimumLeaseMonths.
  ///
  /// In en, this message translates to:
  /// **'Minimum lease: {months} months'**
  String minimumLeaseMonths(int months);

  /// No description provided for @bookViewing.
  ///
  /// In en, this message translates to:
  /// **'Book a viewing'**
  String get bookViewing;

  /// No description provided for @rentEnquiry.
  ///
  /// In en, this message translates to:
  /// **'Rent enquiry'**
  String get rentEnquiry;

  /// No description provided for @reserve.
  ///
  /// In en, this message translates to:
  /// **'Reserve'**
  String get reserve;

  /// No description provided for @newInquiryTitle.
  ///
  /// In en, this message translates to:
  /// **'New inquiry'**
  String get newInquiryTitle;

  /// No description provided for @whatDoYouNeed.
  ///
  /// In en, this message translates to:
  /// **'What do you need?'**
  String get whatDoYouNeed;

  /// No description provided for @contactPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Contact phone'**
  String get contactPhoneLabel;

  /// No description provided for @commentOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Comment (optional)'**
  String get commentOptionalLabel;

  /// No description provided for @commentHint.
  ///
  /// In en, this message translates to:
  /// **'Preferred time, questions...'**
  String get commentHint;

  /// No description provided for @piiConsentLabel.
  ///
  /// In en, this message translates to:
  /// **'I agree to the processing of my personal data (name and phone number) so iBuild and this developer can contact me about my enquiry.'**
  String get piiConsentLabel;

  /// No description provided for @piiConsentRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Please agree to the processing of your personal data to continue.'**
  String get piiConsentRequiredError;

  /// No description provided for @submitInquiry.
  ///
  /// In en, this message translates to:
  /// **'Submit inquiry'**
  String get submitInquiry;

  /// No description provided for @leadSubmittedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Lead {number} submitted'**
  String leadSubmittedSnackbar(String number);

  /// No description provided for @leadSignInRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to send this inquiry'**
  String get leadSignInRequiredTitle;

  /// No description provided for @leadSignInRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'Create or sign in to your iBuild account so the developer can reach you about this request.'**
  String get leadSignInRequiredBody;

  /// No description provided for @leadSignInCta.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get leadSignInCta;

  /// No description provided for @leadSignInRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to submit this inquiry.'**
  String get leadSignInRequiredError;

  /// No description provided for @myInquiriesTitle.
  ///
  /// In en, this message translates to:
  /// **'My inquiries'**
  String get myInquiriesTitle;

  /// No description provided for @tabActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get tabActive;

  /// No description provided for @tabCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get tabCompleted;

  /// No description provided for @tabCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get tabCancelled;

  /// No description provided for @nothingHereYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get nothingHereYet;

  /// No description provided for @inquiriesEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your callback and viewing requests will show up here.'**
  String get inquiriesEmptySubtitle;

  /// No description provided for @inquiriesSignInRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to see your inquiries'**
  String get inquiriesSignInRequiredTitle;

  /// No description provided for @inquiriesSignInRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your iBuild account to view callback and viewing requests.'**
  String get inquiriesSignInRequiredBody;

  /// No description provided for @savedTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get savedTitle;

  /// No description provided for @tabSavedSearches.
  ///
  /// In en, this message translates to:
  /// **'Saved searches'**
  String get tabSavedSearches;

  /// No description provided for @noFavoritesYet.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet'**
  String get noFavoritesYet;

  /// No description provided for @favoritesEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap the heart on any listing to save it here.'**
  String get favoritesEmptySubtitle;

  /// No description provided for @savedSearchesEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save a search from the filters sheet to get back to it quickly.'**
  String get savedSearchesEmptySubtitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @guestUser.
  ///
  /// In en, this message translates to:
  /// **'Guest user'**
  String get guestUser;

  /// No description provided for @appearanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceTitle;

  /// No description provided for @darkModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get darkModeLabel;

  /// No description provided for @lightModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Light mode'**
  String get lightModeLabel;

  /// No description provided for @paletteLabel.
  ///
  /// In en, this message translates to:
  /// **'Palette'**
  String get paletteLabel;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @currencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currencyLabel;

  /// No description provided for @exchangeRateTooltip.
  ///
  /// In en, this message translates to:
  /// **'1 USD = {rate} UZS'**
  String exchangeRateTooltip(String rate);

  /// No description provided for @timeJustNow.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String timeMinutesAgo(int count);

  /// No description provided for @timeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String timeHoursAgo(int count);

  /// No description provided for @timeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String timeDaysAgo(int count);

  /// No description provided for @accountTitle.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountTitle;

  /// No description provided for @preferencesLabel.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferencesLabel;

  /// No description provided for @notificationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsLabel;

  /// No description provided for @helpSupportLabel.
  ///
  /// In en, this message translates to:
  /// **'Help & support'**
  String get helpSupportLabel;

  /// No description provided for @signOutLabel.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOutLabel;

  /// No description provided for @accountBannedTitle.
  ///
  /// In en, this message translates to:
  /// **'Your account has been banned'**
  String get accountBannedTitle;

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

  /// No description provided for @unitKindApartment.
  ///
  /// In en, this message translates to:
  /// **'Apartment'**
  String get unitKindApartment;

  /// No description provided for @unitKindOffice.
  ///
  /// In en, this message translates to:
  /// **'Office'**
  String get unitKindOffice;

  /// No description provided for @unitKindRetail.
  ///
  /// In en, this message translates to:
  /// **'Retail'**
  String get unitKindRetail;

  /// No description provided for @projectStatusPlanned.
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get projectStatusPlanned;

  /// No description provided for @projectStatusUnderConstruction.
  ///
  /// In en, this message translates to:
  /// **'Under construction'**
  String get projectStatusUnderConstruction;

  /// No description provided for @projectStatusReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get projectStatusReady;

  /// No description provided for @projectStatusHandedOver.
  ///
  /// In en, this message translates to:
  /// **'Handed over'**
  String get projectStatusHandedOver;

  /// No description provided for @statusAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get statusAvailable;

  /// No description provided for @statusReserved.
  ///
  /// In en, this message translates to:
  /// **'Reserved'**
  String get statusReserved;

  /// No description provided for @statusSold.
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get statusSold;

  /// No description provided for @statusRented.
  ///
  /// In en, this message translates to:
  /// **'Rented'**
  String get statusRented;

  /// No description provided for @statusBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get statusBlocked;

  /// No description provided for @leadIntentBuy.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get leadIntentBuy;

  /// No description provided for @leadIntentBuyOffplan.
  ///
  /// In en, this message translates to:
  /// **'Off-plan reservation'**
  String get leadIntentBuyOffplan;

  /// No description provided for @leadIntentRent.
  ///
  /// In en, this message translates to:
  /// **'Rent enquiry'**
  String get leadIntentRent;

  /// No description provided for @leadIntentViewing.
  ///
  /// In en, this message translates to:
  /// **'Viewing'**
  String get leadIntentViewing;

  /// No description provided for @leadIntentCallback.
  ///
  /// In en, this message translates to:
  /// **'Callback'**
  String get leadIntentCallback;

  /// No description provided for @leadStatusNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get leadStatusNew;

  /// No description provided for @leadStatusContacted.
  ///
  /// In en, this message translates to:
  /// **'Contacted'**
  String get leadStatusContacted;

  /// No description provided for @leadStatusScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get leadStatusScheduled;

  /// No description provided for @leadStatusVisited.
  ///
  /// In en, this message translates to:
  /// **'Visited'**
  String get leadStatusVisited;

  /// No description provided for @leadStatusWon.
  ///
  /// In en, this message translates to:
  /// **'Won'**
  String get leadStatusWon;

  /// No description provided for @leadStatusLost.
  ///
  /// In en, this message translates to:
  /// **'Lost'**
  String get leadStatusLost;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get somethingWentWrong;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @viewGalleryCount.
  ///
  /// In en, this message translates to:
  /// **'Gallery · {count} photos'**
  String viewGalleryCount(int count);

  /// No description provided for @galleryPhotoOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{index} / {total}'**
  String galleryPhotoOfTotal(int index, int total);

  /// No description provided for @floorPlansEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Floor plans will appear here once available.'**
  String get floorPlansEmptyMessage;

  /// No description provided for @layoutsTitle.
  ///
  /// In en, this message translates to:
  /// **'Apartment layouts'**
  String get layoutsTitle;

  /// No description provided for @layoutRoomsLabel.
  ///
  /// In en, this message translates to:
  /// **'{count}-room'**
  String layoutRoomsLabel(int count);

  /// No description provided for @layoutAvailability.
  ///
  /// In en, this message translates to:
  /// **'{available} of {total} available'**
  String layoutAvailability(int available, int total);

  /// No description provided for @viewAvailableUnits.
  ///
  /// In en, this message translates to:
  /// **'View available units'**
  String get viewAvailableUnits;

  /// No description provided for @callAgentLabel.
  ///
  /// In en, this message translates to:
  /// **'Call agent'**
  String get callAgentLabel;

  /// No description provided for @agentPhoneUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Phone number unavailable'**
  String get agentPhoneUnavailable;

  /// No description provided for @callFailedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t start the call'**
  String get callFailedSnackbar;

  /// No description provided for @contactAgentTitle.
  ///
  /// In en, this message translates to:
  /// **'Sales agent'**
  String get contactAgentTitle;

  /// No description provided for @viewInsideLabel.
  ///
  /// In en, this message translates to:
  /// **'Look inside'**
  String get viewInsideLabel;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search projects, districts...'**
  String get searchHint;

  /// No description provided for @filtersTitle.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filtersTitle;

  /// No description provided for @districtLabel.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get districtLabel;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// No description provided for @priceRangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Price: {min} – {max}'**
  String priceRangeLabel(String min, String max);

  /// No description provided for @roomsLabel.
  ///
  /// In en, this message translates to:
  /// **'Rooms'**
  String get roomsLabel;

  /// No description provided for @roomsStudio.
  ///
  /// In en, this message translates to:
  /// **'Studio'**
  String get roomsStudio;

  /// No description provided for @roomsPlus.
  ///
  /// In en, this message translates to:
  /// **'{count}+'**
  String roomsPlus(int count);

  /// No description provided for @areaMinLabel.
  ///
  /// In en, this message translates to:
  /// **'Area from, m²'**
  String get areaMinLabel;

  /// No description provided for @offplanOnlyLabel.
  ///
  /// In en, this message translates to:
  /// **'Off-plan only'**
  String get offplanOnlyLabel;

  /// No description provided for @applyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply filters'**
  String get applyFilters;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// No description provided for @filtersApplied.
  ///
  /// In en, this message translates to:
  /// **'Filters applied'**
  String get filtersApplied;

  /// No description provided for @filterDistrictsHint.
  ///
  /// In en, this message translates to:
  /// **'Select one or more districts'**
  String get filterDistrictsHint;

  /// No description provided for @districtsSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} districts selected'**
  String districtsSelectedCount(int count);

  /// No description provided for @saveThisSearch.
  ///
  /// In en, this message translates to:
  /// **'Save this search'**
  String get saveThisSearch;

  /// No description provided for @savedSearchSavedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Search saved'**
  String get savedSearchSavedSnackbar;

  /// No description provided for @savedSearchUnderPrice.
  ///
  /// In en, this message translates to:
  /// **'under {price}'**
  String savedSearchUnderPrice(String price);

  /// No description provided for @savedSearchFromPrice.
  ///
  /// In en, this message translates to:
  /// **'from {price}'**
  String savedSearchFromPrice(String price);

  /// No description provided for @noSavedSearchesYet.
  ///
  /// In en, this message translates to:
  /// **'No saved searches yet'**
  String get noSavedSearchesYet;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get notificationsEmpty;

  /// No description provided for @notificationsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll let you know about price drops, new offers and updates.'**
  String get notificationsEmptySubtitle;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllRead;

  /// No description provided for @notifLeadStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Inquiry status updated'**
  String get notifLeadStatusTitle;

  /// No description provided for @notifLeadStatusBody.
  ///
  /// In en, this message translates to:
  /// **'Your inquiry is now “{status}”.'**
  String notifLeadStatusBody(String status);

  /// No description provided for @notifNewOfferTitle.
  ///
  /// In en, this message translates to:
  /// **'New offer available'**
  String get notifNewOfferTitle;

  /// No description provided for @notifNewOfferBody.
  ///
  /// In en, this message translates to:
  /// **'A new offer was added to a project you follow.'**
  String get notifNewOfferBody;

  /// No description provided for @notifLeadCreatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Inquiry received'**
  String get notifLeadCreatedTitle;

  /// No description provided for @notifLeadCreatedBody.
  ///
  /// In en, this message translates to:
  /// **'We received your inquiry and will be in touch shortly.'**
  String get notifLeadCreatedBody;

  /// No description provided for @compareModeAction.
  ///
  /// In en, this message translates to:
  /// **'Compare units'**
  String get compareModeAction;

  /// No description provided for @compareCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Compare ({count})'**
  String compareCountLabel(int count);

  /// No description provided for @addToCompareAction.
  ///
  /// In en, this message translates to:
  /// **'Add to compare'**
  String get addToCompareAction;

  /// No description provided for @compareTitle.
  ///
  /// In en, this message translates to:
  /// **'Compare units'**
  String get compareTitle;

  /// No description provided for @compareEmpty.
  ///
  /// In en, this message translates to:
  /// **'Select units to compare them side by side'**
  String get compareEmpty;

  /// No description provided for @compareAreaLabel.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get compareAreaLabel;

  /// No description provided for @comparePriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get comparePriceLabel;

  /// No description provided for @compareFloorLabel.
  ///
  /// In en, this message translates to:
  /// **'Floor'**
  String get compareFloorLabel;

  /// No description provided for @compareRoomsLabel.
  ///
  /// In en, this message translates to:
  /// **'Rooms'**
  String get compareRoomsLabel;

  /// No description provided for @compareStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get compareStatusLabel;

  /// No description provided for @compareViewLabel.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get compareViewLabel;

  /// No description provided for @installmentCalculatorTitle.
  ///
  /// In en, this message translates to:
  /// **'Installment calculator'**
  String get installmentCalculatorTitle;

  /// No description provided for @downPaymentLabel.
  ///
  /// In en, this message translates to:
  /// **'Down payment: {percent}% ({amount})'**
  String downPaymentLabel(int percent, String amount);

  /// No description provided for @termMonthsLabel.
  ///
  /// In en, this message translates to:
  /// **'Term: {months} months'**
  String termMonthsLabel(int months);

  /// No description provided for @monthlyPaymentLabel.
  ///
  /// In en, this message translates to:
  /// **'Monthly payment'**
  String get monthlyPaymentLabel;

  /// No description provided for @calculateInstallmentAction.
  ///
  /// In en, this message translates to:
  /// **'Calculate'**
  String get calculateInstallmentAction;

  /// No description provided for @rentalRentLabel.
  ///
  /// In en, this message translates to:
  /// **'Monthly rent'**
  String get rentalRentLabel;

  /// No description provided for @ownerListingsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Owner listings nearby'**
  String get ownerListingsSectionTitle;

  /// No description provided for @secondaryTag.
  ///
  /// In en, this message translates to:
  /// **'Secondary'**
  String get secondaryTag;

  /// No description provided for @perMonthSuffix.
  ///
  /// In en, this message translates to:
  /// **'/mo'**
  String get perMonthSuffix;

  /// No description provided for @forBusinessTitle.
  ///
  /// In en, this message translates to:
  /// **'Own a property or a business?'**
  String get forBusinessTitle;

  /// No description provided for @forBusinessSubtitle.
  ///
  /// In en, this message translates to:
  /// **'List sale or rental inventory, manage leads and track analytics in iBuild for Business.'**
  String get forBusinessSubtitle;

  /// No description provided for @forBusinessAction.
  ///
  /// In en, this message translates to:
  /// **'Open iBuild for Business'**
  String get forBusinessAction;

  /// No description provided for @mortgageCalculatorAction.
  ///
  /// In en, this message translates to:
  /// **'Mortgage calculator'**
  String get mortgageCalculatorAction;

  /// No description provided for @mortgageCalculatorTitle.
  ///
  /// In en, this message translates to:
  /// **'Bank mortgage calculator'**
  String get mortgageCalculatorTitle;

  /// No description provided for @mortgagePropertyPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Property price'**
  String get mortgagePropertyPriceLabel;

  /// No description provided for @toolsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get toolsSectionTitle;

  /// No description provided for @interestRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Bank rate: {percent}% / year'**
  String interestRateLabel(String percent);

  /// No description provided for @termYearsLabel.
  ///
  /// In en, this message translates to:
  /// **'Term: {years} years'**
  String termYearsLabel(int years);

  /// No description provided for @totalInterestLabel.
  ///
  /// In en, this message translates to:
  /// **'Total interest'**
  String get totalInterestLabel;

  /// No description provided for @totalPaymentLabel.
  ///
  /// In en, this message translates to:
  /// **'Total payment'**
  String get totalPaymentLabel;

  /// No description provided for @downPaymentAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Down payment'**
  String get downPaymentAmountLabel;

  /// No description provided for @bankReferralConsentLabel.
  ///
  /// In en, this message translates to:
  /// **'I agree to be contacted by an iBuild bank partner about this mortgage'**
  String get bankReferralConsentLabel;

  /// No description provided for @requestBankConsultationAction.
  ///
  /// In en, this message translates to:
  /// **'Request bank consultation'**
  String get requestBankConsultationAction;

  /// No description provided for @bankReferralSubmittedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'A bank partner will contact you shortly'**
  String get bankReferralSubmittedSnackbar;

  /// No description provided for @rentalYieldCalculatorAction.
  ///
  /// In en, this message translates to:
  /// **'Rental yield calculator'**
  String get rentalYieldCalculatorAction;

  /// No description provided for @rentalYieldCalculatorTitle.
  ///
  /// In en, this message translates to:
  /// **'Rental yield calculator'**
  String get rentalYieldCalculatorTitle;

  /// No description provided for @grossYieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Gross yield'**
  String get grossYieldLabel;

  /// No description provided for @paybackYearsLabel.
  ///
  /// In en, this message translates to:
  /// **'Payback period'**
  String get paybackYearsLabel;

  /// No description provided for @paybackYearsValue.
  ///
  /// In en, this message translates to:
  /// **'{years} years'**
  String paybackYearsValue(String years);

  /// No description provided for @annualRentLabel.
  ///
  /// In en, this message translates to:
  /// **'Annual rent'**
  String get annualRentLabel;

  /// No description provided for @calculatingLabel.
  ///
  /// In en, this message translates to:
  /// **'Calculating...'**
  String get calculatingLabel;

  /// No description provided for @quizTitle.
  ///
  /// In en, this message translates to:
  /// **'Find your match'**
  String get quizTitle;

  /// No description provided for @quizIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Let\'s personalize your search'**
  String get quizIntroTitle;

  /// No description provided for @quizIntroBody.
  ///
  /// In en, this message translates to:
  /// **'Answer 4 quick questions and we\'ll tune your feed and shape an on-device AI preview — just for you.'**
  String get quizIntroBody;

  /// No description provided for @quizStartAction.
  ///
  /// In en, this message translates to:
  /// **'Start the quiz'**
  String get quizStartAction;

  /// No description provided for @quizStepCounter.
  ///
  /// In en, this message translates to:
  /// **'{current} of {total}'**
  String quizStepCounter(int current, int total);

  /// No description provided for @quizSavedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Preferences saved'**
  String get quizSavedSnackbar;

  /// No description provided for @quizGoalQuestion.
  ///
  /// In en, this message translates to:
  /// **'What matters most in your next home?'**
  String get quizGoalQuestion;

  /// No description provided for @quizGoalBudget.
  ///
  /// In en, this message translates to:
  /// **'Great value'**
  String get quizGoalBudget;

  /// No description provided for @quizGoalFamily.
  ///
  /// In en, this message translates to:
  /// **'Room for the family'**
  String get quizGoalFamily;

  /// No description provided for @quizGoalInvestment.
  ///
  /// In en, this message translates to:
  /// **'A smart investment'**
  String get quizGoalInvestment;

  /// No description provided for @quizGoalLuxury.
  ///
  /// In en, this message translates to:
  /// **'Premium living'**
  String get quizGoalLuxury;

  /// No description provided for @quizLocationQuestion.
  ///
  /// In en, this message translates to:
  /// **'Where do you picture yourself?'**
  String get quizLocationQuestion;

  /// No description provided for @quizLocationCityCenter.
  ///
  /// In en, this message translates to:
  /// **'In the heart of the city'**
  String get quizLocationCityCenter;

  /// No description provided for @quizLocationQuietSuburb.
  ///
  /// In en, this message translates to:
  /// **'A calm, green neighbourhood'**
  String get quizLocationQuietSuburb;

  /// No description provided for @quizLocationBusinessDistrict.
  ///
  /// In en, this message translates to:
  /// **'Close to the business district'**
  String get quizLocationBusinessDistrict;

  /// No description provided for @quizLocationUpAndComing.
  ///
  /// In en, this message translates to:
  /// **'An up-and-coming area'**
  String get quizLocationUpAndComing;

  /// No description provided for @quizTimelineQuestion.
  ///
  /// In en, this message translates to:
  /// **'When would you like to move in?'**
  String get quizTimelineQuestion;

  /// No description provided for @quizTimelineReadyNow.
  ///
  /// In en, this message translates to:
  /// **'As soon as possible'**
  String get quizTimelineReadyNow;

  /// No description provided for @quizTimelineOffplanOk.
  ///
  /// In en, this message translates to:
  /// **'Happy to wait for a new build'**
  String get quizTimelineOffplanOk;

  /// No description provided for @quizTimelineFlexible.
  ///
  /// In en, this message translates to:
  /// **'I\'m flexible'**
  String get quizTimelineFlexible;

  /// No description provided for @quizPriorityQuestion.
  ///
  /// In en, this message translates to:
  /// **'Pick your number-one priority'**
  String get quizPriorityQuestion;

  /// No description provided for @quizPriorityPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get quizPriorityPrice;

  /// No description provided for @quizPrioritySpace.
  ///
  /// In en, this message translates to:
  /// **'Space & layout'**
  String get quizPrioritySpace;

  /// No description provided for @quizPriorityAmenities.
  ///
  /// In en, this message translates to:
  /// **'Amenities'**
  String get quizPriorityAmenities;

  /// No description provided for @quizPriorityLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get quizPriorityLocation;

  /// No description provided for @quizResultEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Your buyer persona'**
  String get quizResultEyebrow;

  /// No description provided for @quizPersonaFirstTimeBuyer.
  ///
  /// In en, this message translates to:
  /// **'First-time buyer'**
  String get quizPersonaFirstTimeBuyer;

  /// No description provided for @quizPersonaFamilyNester.
  ///
  /// In en, this message translates to:
  /// **'Family nester'**
  String get quizPersonaFamilyNester;

  /// No description provided for @quizPersonaInvestor.
  ///
  /// In en, this message translates to:
  /// **'Savvy investor'**
  String get quizPersonaInvestor;

  /// No description provided for @quizPersonaLuxurySeeker.
  ///
  /// In en, this message translates to:
  /// **'Luxury seeker'**
  String get quizPersonaLuxurySeeker;

  /// No description provided for @quizPersonaFirstTimeBuyerDesc.
  ///
  /// In en, this message translates to:
  /// **'You want the best possible home for your budget. We\'ll surface strong-value units and flexible installment plans.'**
  String get quizPersonaFirstTimeBuyerDesc;

  /// No description provided for @quizPersonaFamilyNesterDesc.
  ///
  /// In en, this message translates to:
  /// **'Space and comfort come first. We\'ll highlight larger layouts in calm, well-served neighbourhoods.'**
  String get quizPersonaFamilyNesterDesc;

  /// No description provided for @quizPersonaInvestorDesc.
  ///
  /// In en, this message translates to:
  /// **'You\'re after returns. We\'ll spotlight high-yield units and off-plan opportunities with upside.'**
  String get quizPersonaInvestorDesc;

  /// No description provided for @quizPersonaLuxurySeekerDesc.
  ///
  /// In en, this message translates to:
  /// **'Only the finest will do. We\'ll curate premium residences with standout amenities and locations.'**
  String get quizPersonaLuxurySeekerDesc;

  /// No description provided for @quizPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Your AI preview'**
  String get quizPreviewTitle;

  /// No description provided for @quizPreviewPromptLabel.
  ///
  /// In en, this message translates to:
  /// **'Prompt (on-device mock)'**
  String get quizPreviewPromptLabel;

  /// No description provided for @quizPreviewBody.
  ///
  /// In en, this message translates to:
  /// **'As a {persona}, you\'ll see the best-matching homes first. We\'ll lead with what you care about and refresh it as new listings arrive. This preview is generated locally — no data leaves your device.'**
  String quizPreviewBody(String persona);

  /// No description provided for @quizDoneAction.
  ///
  /// In en, this message translates to:
  /// **'Browse my matches'**
  String get quizDoneAction;

  /// No description provided for @quizRetakeAction.
  ///
  /// In en, this message translates to:
  /// **'Retake quiz'**
  String get quizRetakeAction;

  /// No description provided for @quizEntryAction.
  ///
  /// In en, this message translates to:
  /// **'Take the quiz'**
  String get quizEntryAction;

  /// No description provided for @leadSubjectLabel.
  ///
  /// In en, this message translates to:
  /// **'What\'s this about?'**
  String get leadSubjectLabel;

  /// No description provided for @leadSubjectProject.
  ///
  /// In en, this message translates to:
  /// **'A project'**
  String get leadSubjectProject;

  /// No description provided for @leadSubjectUnit.
  ///
  /// In en, this message translates to:
  /// **'A specific unit'**
  String get leadSubjectUnit;

  /// No description provided for @leadSubjectRent.
  ///
  /// In en, this message translates to:
  /// **'Renting'**
  String get leadSubjectRent;

  /// No description provided for @leadSubjectOffice.
  ///
  /// In en, this message translates to:
  /// **'An office'**
  String get leadSubjectOffice;

  /// No description provided for @leadSubjectMortgage.
  ///
  /// In en, this message translates to:
  /// **'Mortgage consult'**
  String get leadSubjectMortgage;

  /// No description provided for @leadSubjectOther.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get leadSubjectOther;

  /// No description provided for @aiFabTooltip.
  ///
  /// In en, this message translates to:
  /// **'Ask iBuild AI'**
  String get aiFabTooltip;

  /// No description provided for @aiChatTitle.
  ///
  /// In en, this message translates to:
  /// **'iBuild AI'**
  String get aiChatTitle;

  /// No description provided for @aiChatInfoTooltip.
  ///
  /// In en, this message translates to:
  /// **'About iBuild AI'**
  String get aiChatInfoTooltip;

  /// No description provided for @aiChatInfoBody.
  ///
  /// In en, this message translates to:
  /// **'Ask about the catalogue, a specific complex or unit, or how installments and mortgages work — iBuild AI answers using iBuild\'s own listings and terms.'**
  String get aiChatInfoBody;

  /// No description provided for @aiChatErrorSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t get a reply. Please try again.'**
  String get aiChatErrorSnackbar;

  /// No description provided for @aiChatQuotaExhaustedTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily limit reached'**
  String get aiChatQuotaExhaustedTitle;

  /// No description provided for @aiChatQuotaExhaustedBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used today\'s iBuild AI messages. Please come back tomorrow.'**
  String get aiChatQuotaExhaustedBody;

  /// No description provided for @aiChatUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'iBuild AI is taking a break'**
  String get aiChatUnavailableTitle;

  /// No description provided for @aiChatUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'The assistant is temporarily unavailable. Please try again later.'**
  String get aiChatUnavailableBody;

  /// No description provided for @aiChatEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Ask iBuild AI anything'**
  String get aiChatEmptyTitle;

  /// No description provided for @aiChatEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Try “Which complexes in Chilanzar have installments?” or “What\'s a good mortgage rate for a \$60,000 flat?”'**
  String get aiChatEmptyBody;

  /// No description provided for @aiChatInputHint.
  ///
  /// In en, this message translates to:
  /// **'Message iBuild AI...'**
  String get aiChatInputHint;

  /// No description provided for @aiChatSendTooltip.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get aiChatSendTooltip;

  /// No description provided for @aiBetaNoticeTitle.
  ///
  /// In en, this message translates to:
  /// **'iBuild AI is in testing'**
  String get aiBetaNoticeTitle;

  /// No description provided for @aiBetaNoticeBody.
  ///
  /// In en, this message translates to:
  /// **'Answers may occasionally be inaccurate — always double-check details like price and availability on the listing itself.'**
  String get aiBetaNoticeBody;

  /// No description provided for @aiQuotaTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily quota'**
  String get aiQuotaTitle;

  /// No description provided for @aiQuotaUsedLabel.
  ///
  /// In en, this message translates to:
  /// **'{used} of {limit} messages used today'**
  String aiQuotaUsedLabel(int used, int limit);

  /// No description provided for @aiQuotaResetLabel.
  ///
  /// In en, this message translates to:
  /// **'Resets {time}'**
  String aiQuotaResetLabel(String time);

  /// No description provided for @aiSearchInfoExamplesTitle.
  ///
  /// In en, this message translates to:
  /// **'Try asking'**
  String get aiSearchInfoExamplesTitle;

  /// No description provided for @aiSearchInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'AI smart search'**
  String get aiSearchInfoTitle;

  /// No description provided for @aiSearchInfoBody.
  ///
  /// In en, this message translates to:
  /// **'Describe what you\'re looking for in plain language — rooms, budget, district, anything that matters to you — and iBuild AI will parse it into a live search of the catalogue.'**
  String get aiSearchInfoBody;

  /// No description provided for @aiSearchExample1.
  ///
  /// In en, this message translates to:
  /// **'2-room in Chilanzar under \$60k'**
  String get aiSearchExample1;

  /// No description provided for @aiSearchExample2.
  ///
  /// In en, this message translates to:
  /// **'3-bedroom office near the business district, ready now'**
  String get aiSearchExample2;

  /// No description provided for @aiSearchExample3.
  ///
  /// In en, this message translates to:
  /// **'Apartment for rent, not on the first floor, with parking'**
  String get aiSearchExample3;

  /// No description provided for @aiSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Describe what you\'re looking for...'**
  String get aiSearchHint;

  /// No description provided for @aiSearchClearTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get aiSearchClearTooltip;

  /// No description provided for @aiSearchSubmitTooltip.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get aiSearchSubmitTooltip;

  /// No description provided for @aiSearchInfoTooltip.
  ///
  /// In en, this message translates to:
  /// **'About AI search'**
  String get aiSearchInfoTooltip;

  /// No description provided for @aiSearchRateLimitedTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily search limit reached'**
  String get aiSearchRateLimitedTitle;

  /// No description provided for @aiSearchRateLimitedBody.
  ///
  /// In en, this message translates to:
  /// **'You have reached the daily AI search limit. Please come back {time}.'**
  String aiSearchRateLimitedBody(String time);

  /// No description provided for @aiSearchUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'AI search is taking a break'**
  String get aiSearchUnavailableTitle;

  /// No description provided for @aiSearchUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'Smart search is temporarily unavailable. Please try again later.'**
  String get aiSearchUnavailableBody;

  /// No description provided for @aiSearchGenericErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t run that search'**
  String get aiSearchGenericErrorTitle;

  /// No description provided for @aiSearchGenericErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again in a moment.'**
  String get aiSearchGenericErrorBody;

  /// No description provided for @aiSearchUnrecognizedNote.
  ///
  /// In en, this message translates to:
  /// **'Not sure what you meant by: {terms}'**
  String aiSearchUnrecognizedNote(String terms);

  /// No description provided for @aiSearchSummary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No matches} =1{1 match} other{{count} matches}}'**
  String aiSearchSummary(int count);

  /// No description provided for @aiSearchResultsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No matches yet'**
  String get aiSearchResultsEmptyTitle;

  /// No description provided for @aiSearchResultsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Try loosening a constraint — a wider budget or a nearby district often helps.'**
  String get aiSearchResultsEmptyBody;

  /// No description provided for @aiSearchMatchScoreLabel.
  ///
  /// In en, this message translates to:
  /// **'{score}% match'**
  String aiSearchMatchScoreLabel(int score);

  /// No description provided for @aiSearchStatusStarting.
  ///
  /// In en, this message translates to:
  /// **'Getting started...'**
  String get aiSearchStatusStarting;

  /// No description provided for @aiSearchTabHintTooltip.
  ///
  /// In en, this message translates to:
  /// **'Press Tab to accept the suggestion'**
  String get aiSearchTabHintTooltip;

  /// No description provided for @aiSearchTabAcceptLabel.
  ///
  /// In en, this message translates to:
  /// **'Accept the AI suggestion'**
  String get aiSearchTabAcceptLabel;

  /// No description provided for @aiSearchClarifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not understand the query'**
  String get aiSearchClarifyTitle;

  /// No description provided for @aiSearchClarifyBody.
  ///
  /// In en, this message translates to:
  /// **'These words are not in the catalogue: {terms}. Rephrase the query or pick one of the suggestions below.'**
  String aiSearchClarifyBody(String terms);

  /// No description provided for @aiSearchClarifyExamplesHint.
  ///
  /// In en, this message translates to:
  /// **'Try one of these instead:'**
  String get aiSearchClarifyExamplesHint;

  /// No description provided for @aiSearchDidYouMean.
  ///
  /// In en, this message translates to:
  /// **'Did you mean “{suggestion}”?'**
  String aiSearchDidYouMean(String suggestion);

  /// No description provided for @aiSearchQuotedTerm.
  ///
  /// In en, this message translates to:
  /// **'“{term}”'**
  String aiSearchQuotedTerm(String term);

  /// No description provided for @aiSearchRelaxConstraint.
  ///
  /// In en, this message translates to:
  /// **'Drop: {constraint}'**
  String aiSearchRelaxConstraint(String constraint);

  /// No description provided for @aiStepParsingV1.
  ///
  /// In en, this message translates to:
  /// **'Reading your request ({count} details)...'**
  String aiStepParsingV1(int count);

  /// No description provided for @aiStepParsingV2.
  ///
  /// In en, this message translates to:
  /// **'Understanding what you\'re after ({count} details)...'**
  String aiStepParsingV2(int count);

  /// No description provided for @aiStepParsingV3.
  ///
  /// In en, this message translates to:
  /// **'Parsing {count, plural, =1{1 requirement} other{{count} requirements}}...'**
  String aiStepParsingV3(int count);

  /// No description provided for @aiStepParsingV4.
  ///
  /// In en, this message translates to:
  /// **'Breaking down your request into {count} parts...'**
  String aiStepParsingV4(int count);

  /// No description provided for @aiStepScanningDistrictV1.
  ///
  /// In en, this message translates to:
  /// **'Scanning {district} ({count} projects)...'**
  String aiStepScanningDistrictV1(String district, int count);

  /// No description provided for @aiStepScanningDistrictV2.
  ///
  /// In en, this message translates to:
  /// **'Looking through {count} projects in {district}...'**
  String aiStepScanningDistrictV2(String district, int count);

  /// No description provided for @aiStepScanningDistrictV3.
  ///
  /// In en, this message translates to:
  /// **'Checking availability in {district} ({count} projects)...'**
  String aiStepScanningDistrictV3(String district, int count);

  /// No description provided for @aiStepScanningDistrictV4.
  ///
  /// In en, this message translates to:
  /// **'Surveying {district} ({count} projects)...'**
  String aiStepScanningDistrictV4(String district, int count);

  /// No description provided for @aiStepFoundInDistrictV1.
  ///
  /// In en, this message translates to:
  /// **'Found {count} in {district}'**
  String aiStepFoundInDistrictV1(String district, int count);

  /// No description provided for @aiStepFoundInDistrictV2.
  ///
  /// In en, this message translates to:
  /// **'{count} candidates spotted in {district}'**
  String aiStepFoundInDistrictV2(String district, int count);

  /// No description provided for @aiStepFoundInDistrictV3.
  ///
  /// In en, this message translates to:
  /// **'{district}: {count} worth a closer look'**
  String aiStepFoundInDistrictV3(String district, int count);

  /// No description provided for @aiStepFoundInDistrictV4.
  ///
  /// In en, this message translates to:
  /// **'Shortlisted {count} in {district}'**
  String aiStepFoundInDistrictV4(String district, int count);

  /// No description provided for @aiStepOpeningProjectV1.
  ///
  /// In en, this message translates to:
  /// **'Opening {project} ({index}/{total})...'**
  String aiStepOpeningProjectV1(String project, int index, int total);

  /// No description provided for @aiStepOpeningProjectV2.
  ///
  /// In en, this message translates to:
  /// **'Looking inside {project} ({index} of {total})...'**
  String aiStepOpeningProjectV2(String project, int index, int total);

  /// No description provided for @aiStepOpeningProjectV3.
  ///
  /// In en, this message translates to:
  /// **'Checking {project} ({index} of {total})...'**
  String aiStepOpeningProjectV3(String project, int index, int total);

  /// No description provided for @aiStepOpeningProjectV4.
  ///
  /// In en, this message translates to:
  /// **'Now viewing {project} ({index}/{total})...'**
  String aiStepOpeningProjectV4(String project, int index, int total);

  /// No description provided for @aiStepScanningUnitsV1.
  ///
  /// In en, this message translates to:
  /// **'Scanning units in {project} ({count})...'**
  String aiStepScanningUnitsV1(String project, int count);

  /// No description provided for @aiStepScanningUnitsV2.
  ///
  /// In en, this message translates to:
  /// **'Checking {count} units in {project}...'**
  String aiStepScanningUnitsV2(String project, int count);

  /// No description provided for @aiStepScanningUnitsV3.
  ///
  /// In en, this message translates to:
  /// **'Going through the floor plans in {project} ({count} units)...'**
  String aiStepScanningUnitsV3(String project, int count);

  /// No description provided for @aiStepScanningUnitsV4.
  ///
  /// In en, this message translates to:
  /// **'{project}: reviewing {count} units...'**
  String aiStepScanningUnitsV4(String project, int count);

  /// No description provided for @aiStepFilteringBookedV1.
  ///
  /// In en, this message translates to:
  /// **'Filtering out {removed} unavailable, {left} left...'**
  String aiStepFilteringBookedV1(int removed, int left);

  /// No description provided for @aiStepFilteringBookedV2.
  ///
  /// In en, this message translates to:
  /// **'Removing {removed} sold and reserved units ({left} remain)...'**
  String aiStepFilteringBookedV2(int removed, int left);

  /// No description provided for @aiStepFilteringBookedV3.
  ///
  /// In en, this message translates to:
  /// **'Skipping {removed} already taken, {left} left...'**
  String aiStepFilteringBookedV3(int removed, int left);

  /// No description provided for @aiStepFilteringBookedV4.
  ///
  /// In en, this message translates to:
  /// **'Keeping only the {left} available units (removed {removed})...'**
  String aiStepFilteringBookedV4(int removed, int left);

  /// No description provided for @aiStepRankingPriceV1.
  ///
  /// In en, this message translates to:
  /// **'Ranking {count} by best fit...'**
  String aiStepRankingPriceV1(int count);

  /// No description provided for @aiStepRankingPriceV2.
  ///
  /// In en, this message translates to:
  /// **'Sorting {count} by price and match quality...'**
  String aiStepRankingPriceV2(int count);

  /// No description provided for @aiStepRankingPriceV3.
  ///
  /// In en, this message translates to:
  /// **'Comparing {count} options...'**
  String aiStepRankingPriceV3(int count);

  /// No description provided for @aiStepRankingPriceV4.
  ///
  /// In en, this message translates to:
  /// **'Lining up the best {count} matches...'**
  String aiStepRankingPriceV4(int count);

  /// No description provided for @aiStepDoneV1.
  ///
  /// In en, this message translates to:
  /// **'Done · {count, plural, =0{no matches} =1{1 match} other{{count} matches}} in {elapsedMs}ms'**
  String aiStepDoneV1(int count, int elapsedMs);

  /// No description provided for @aiStepDoneV2.
  ///
  /// In en, this message translates to:
  /// **'All set — {count, plural, =0{nothing quite matched} =1{1 match found} other{{count} matches found}} ({elapsedMs}ms)'**
  String aiStepDoneV2(int count, int elapsedMs);

  /// No description provided for @aiStepDoneV3.
  ///
  /// In en, this message translates to:
  /// **'Search complete ({count, plural, =0{0 results} =1{1 result} other{{count} results}}, {elapsedMs}ms)'**
  String aiStepDoneV3(int count, int elapsedMs);

  /// No description provided for @aiStepDoneV4.
  ///
  /// In en, this message translates to:
  /// **'Ready — {count, plural, =0{no matches this time} =1{1 strong match} other{{count} strong matches}} ({elapsedMs}ms)'**
  String aiStepDoneV4(int count, int elapsedMs);

  /// No description provided for @aiStepNoMatchIntent.
  ///
  /// In en, this message translates to:
  /// **'Nothing in the catalogue matches {terms} — stopping here'**
  String aiStepNoMatchIntent(String terms);

  /// No description provided for @aiStepLowConfidence.
  ///
  /// In en, this message translates to:
  /// **'Not fully sure about {terms} — showing broader matches ({count})'**
  String aiStepLowConfidence(String terms, int count);

  /// No description provided for @aiStepAutocorrected.
  ///
  /// In en, this message translates to:
  /// **'Read “{from}” as “{to}”'**
  String aiStepAutocorrected(String from, String to);

  /// No description provided for @aiStepSoftenedAmenity.
  ///
  /// In en, this message translates to:
  /// **'Relaxed the “{amenity}” requirement to find options'**
  String aiStepSoftenedAmenity(String amenity);

  /// No description provided for @aiReasonDistrictMatch.
  ///
  /// In en, this message translates to:
  /// **'Right district'**
  String get aiReasonDistrictMatch;

  /// No description provided for @aiReasonRoomsMatch.
  ///
  /// In en, this message translates to:
  /// **'Room count matches'**
  String get aiReasonRoomsMatch;

  /// No description provided for @aiReasonPriceFit.
  ///
  /// In en, this message translates to:
  /// **'Fits your budget'**
  String get aiReasonPriceFit;

  /// No description provided for @aiReasonPriceBelowBudget.
  ///
  /// In en, this message translates to:
  /// **'Below budget'**
  String get aiReasonPriceBelowBudget;

  /// No description provided for @aiReasonAreaFit.
  ///
  /// In en, this message translates to:
  /// **'Area matches'**
  String get aiReasonAreaFit;

  /// No description provided for @aiReasonFloorPreference.
  ///
  /// In en, this message translates to:
  /// **'Floor preference'**
  String get aiReasonFloorPreference;

  /// No description provided for @aiReasonDealTypeMatch.
  ///
  /// In en, this message translates to:
  /// **'Sale/rent matches'**
  String get aiReasonDealTypeMatch;

  /// No description provided for @aiReasonKindMatch.
  ///
  /// In en, this message translates to:
  /// **'Unit type matches'**
  String get aiReasonKindMatch;

  /// No description provided for @aiReasonAvailableNow.
  ///
  /// In en, this message translates to:
  /// **'Available now'**
  String get aiReasonAvailableNow;

  /// No description provided for @aiReasonAmenityMatch.
  ///
  /// In en, this message translates to:
  /// **'Has requested amenities'**
  String get aiReasonAmenityMatch;

  /// No description provided for @aiReasonDeveloperMatch.
  ///
  /// In en, this message translates to:
  /// **'Requested developer'**
  String get aiReasonDeveloperMatch;

  /// No description provided for @aiReasonProjectMatch.
  ///
  /// In en, this message translates to:
  /// **'Requested project'**
  String get aiReasonProjectMatch;

  /// No description provided for @aiReasonHighTrustIndex.
  ///
  /// In en, this message translates to:
  /// **'High trust index'**
  String get aiReasonHighTrustIndex;

  /// No description provided for @aiReasonReadySoon.
  ///
  /// In en, this message translates to:
  /// **'Ready soon'**
  String get aiReasonReadySoon;

  /// No description provided for @aiReasonOffplanDiscount.
  ///
  /// In en, this message translates to:
  /// **'Off-plan discount'**
  String get aiReasonOffplanDiscount;

  /// No description provided for @aiChipAreaRange.
  ///
  /// In en, this message translates to:
  /// **'{min}–{max} m²'**
  String aiChipAreaRange(int min, int max);

  /// No description provided for @aiChipAreaUpTo.
  ///
  /// In en, this message translates to:
  /// **'up to {max} m²'**
  String aiChipAreaUpTo(int max);

  /// No description provided for @aiChipAreaFrom.
  ///
  /// In en, this message translates to:
  /// **'from {min} m²'**
  String aiChipAreaFrom(int min);

  /// No description provided for @aiDealTypeRent.
  ///
  /// In en, this message translates to:
  /// **'For rent'**
  String get aiDealTypeRent;

  /// No description provided for @aiDealTypeSale.
  ///
  /// In en, this message translates to:
  /// **'For sale'**
  String get aiDealTypeSale;

  /// No description provided for @aiUnitKindApartment.
  ///
  /// In en, this message translates to:
  /// **'Apartment'**
  String get aiUnitKindApartment;

  /// No description provided for @aiUnitKindCommercial.
  ///
  /// In en, this message translates to:
  /// **'Commercial'**
  String get aiUnitKindCommercial;

  /// No description provided for @aiUnitKindParking.
  ///
  /// In en, this message translates to:
  /// **'Parking'**
  String get aiUnitKindParking;

  /// No description provided for @aiChipFloorRange.
  ///
  /// In en, this message translates to:
  /// **'Floor {min}–{max}'**
  String aiChipFloorRange(int min, int max);

  /// No description provided for @aiChipFloorFrom.
  ///
  /// In en, this message translates to:
  /// **'Floor {min}+'**
  String aiChipFloorFrom(int min);

  /// No description provided for @aiChipFloorUpTo.
  ///
  /// In en, this message translates to:
  /// **'Up to floor {max}'**
  String aiChipFloorUpTo(int max);

  /// No description provided for @aiChipNotFirstFloor.
  ///
  /// In en, this message translates to:
  /// **'Not first floor'**
  String get aiChipNotFirstFloor;

  /// No description provided for @aiChipNotLastFloor.
  ///
  /// In en, this message translates to:
  /// **'Not last floor'**
  String get aiChipNotLastFloor;

  /// No description provided for @aiChipAvailableOnly.
  ///
  /// In en, this message translates to:
  /// **'Available only'**
  String get aiChipAvailableOnly;

  /// No description provided for @aiSearchShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show all {count}'**
  String aiSearchShowAll(int count);

  /// No description provided for @aiSearchAllResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'All results'**
  String get aiSearchAllResultsTitle;

  /// No description provided for @aiConstraintWithout.
  ///
  /// In en, this message translates to:
  /// **'Without {amenity}'**
  String aiConstraintWithout(String amenity);
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
