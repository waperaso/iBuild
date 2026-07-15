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
  /// **'Sell. Invest. All in One App.'**
  String get onboardingEyebrow;

  /// No description provided for @onboardingHeadline.
  ///
  /// In en, this message translates to:
  /// **'Find Your\nDream Home\nToday'**
  String get onboardingHeadline;

  /// No description provided for @onboardingDescription.
  ///
  /// In en, this message translates to:
  /// **'Browse ready apartments, off-plan new builds and business-centre offices — all in one place, with live availability and one-tap enquiries.'**
  String get onboardingDescription;

  /// No description provided for @onboardingTrustBadge.
  ///
  /// In en, this message translates to:
  /// **'4.9★ · 500+ happy families'**
  String get onboardingTrustBadge;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

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
  /// **'Dev mode: use code 123456'**
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
