// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navHome => 'Home';

  @override
  String get navSearch => 'Search';

  @override
  String get navFavorites => 'Favorites';

  @override
  String get navInquiries => 'Inquiries';

  @override
  String get navSettings => 'Settings';

  @override
  String get onboardingEyebrow => 'Buy from the developer. Safely. In one app.';

  @override
  String get onboardingDescription =>
      'Compare verified new builds, see live availability, and send an enquiry straight to the developer — no middlemen, no guesswork.';

  @override
  String get start => 'Start';

  @override
  String get startDemo => 'Start (demo)';

  @override
  String get signIn => 'Sign in';

  @override
  String get signInDemo => 'Sign in (demo)';

  @override
  String get demoButton => 'Demo';

  @override
  String get demoModeTitle => 'Demo mode';

  @override
  String get demoModeMessage =>
      'You\'re exploring iBuild in read-only demo mode. Browse every screen and feature — nothing you do will be saved to the database.';

  @override
  String get demoModeGotIt => 'Got it';

  @override
  String get demoModeBanner => 'Demo mode — changes are not saved';

  @override
  String get demoWriteBlocked =>
      'Demo mode is view-only — this action was not saved.';

  @override
  String get welcomeTitle => 'Welcome to iBuild';

  @override
  String get welcomeSubtitle => 'Sign in with your phone number';

  @override
  String get phoneHint => '+998 90 123 45 67';

  @override
  String get sendCode => 'Send code';

  @override
  String get phoneRequiredError => 'Enter your phone number';

  @override
  String get otpTitle => 'Enter the code';

  @override
  String otpSubtitle(String phone) {
    return 'We sent a 6-digit code to $phone';
  }

  @override
  String get otpCodeHint => '6-digit code';

  @override
  String get otpDevHint => 'Test mode';

  @override
  String get stepOneOfTwo => 'Step 1 of 2';

  @override
  String get stepTwoOfTwo => 'Step 2 of 2';

  @override
  String get verifyCode => 'Verify';

  @override
  String get resendCode => 'Resend code';

  @override
  String get invalidCodeError => 'Invalid or expired code. Please try again.';

  @override
  String get signedInLabel => 'Signed in';

  @override
  String get accountTypeOrdinaryUser => 'Ordinary user';

  @override
  String get signInPromptMessage =>
      'Sign in to save favorites, track inquiries and get updates.';

  @override
  String get madeForYou => 'Made for You';

  @override
  String get exploreProperties => 'Explore Properties';

  @override
  String get recommendForYou => 'Recommend for You';

  @override
  String get statsListingsLabel => 'Listings';

  @override
  String get statsAvailableLabel => 'Available units';

  @override
  String get statsDistrictsLabel => 'Districts';

  @override
  String get statsRatingLabel => 'Avg. rating';

  @override
  String get featuredForYouTitle => 'Featured for you';

  @override
  String get popularDistrictsTitle => 'Popular districts';

  @override
  String get developersTitle => 'Developers';

  @override
  String developerProjectsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count projects',
      one: '1 project',
    );
    return '$_temp0';
  }

  @override
  String get developerContactsTitle => 'Contacts';

  @override
  String get developerResidencesTitle => 'Residences';

  @override
  String get developerOfficesTitle => 'Offices';

  @override
  String get developerNotFoundTitle => 'Developer not found';

  @override
  String get developerNotFoundSubtitle =>
      'This developer is no longer in our catalogue.';

  @override
  String districtListingsCount(int count) {
    return '$count listings';
  }

  @override
  String get promoBannerTitle => 'New off-plan launches';

  @override
  String get promoBannerSubtitle =>
      'Reserve early with flexible installments on select new builds.';

  @override
  String get promoBannerAction => 'Explore new builds';

  @override
  String get browseListingsAction => 'Browse listings';

  @override
  String get modeBuy => 'Buy';

  @override
  String get modeRent => 'Rent';

  @override
  String get modeNewBuilds => 'New builds';

  @override
  String get categoryAll => 'All';

  @override
  String get categoryApartments => 'Apartments';

  @override
  String get categoryOffices => 'Offices';

  @override
  String get bestDeal => 'Best Deal';

  @override
  String get discountBadge => 'Discount';

  @override
  String get installmentBadge => 'Installments';

  @override
  String unitsAvailableCount(int count) {
    return '$count available';
  }

  @override
  String get searchByLocations => 'Search by locations';

  @override
  String liveLocationDistrict(String district) {
    return 'Live location · $district';
  }

  @override
  String get mapZoomIn => 'Zoom in';

  @override
  String get mapZoomOut => 'Zoom out';

  @override
  String get tabUnits => 'Units';

  @override
  String get tabFloorPlans => 'Floor plans';

  @override
  String get tabAbout => 'About';

  @override
  String get tabReviews => 'Reviews';

  @override
  String get tabProgress => 'Progress';

  @override
  String get overallProgressTitle => 'Overall construction progress';

  @override
  String get actualProgressLabel => 'Actual construction progress';

  @override
  String get plannedProgressLabel => 'Planned construction progress';

  @override
  String get progressOnSchedule => 'On schedule';

  @override
  String get progressAheadOfSchedule => 'Ahead of schedule';

  @override
  String get progressAcceptableDeviation => 'Acceptable deviation';

  @override
  String get progressBehindSchedule => 'Behind schedule';

  @override
  String progressDeviation(int percent) {
    return 'Deviation $percent%';
  }

  @override
  String trustIndexLabel(int percent) {
    return 'Trust index $percent%';
  }

  @override
  String get progressComparisonNote =>
      'A gap of up to 15% is normal on a building site: weather, seasonal work bans and supply delays. Above 15% the platform sends the project for inspection.';

  @override
  String get progressEmptyTitle => 'No photo reports yet';

  @override
  String get progressEmptySubtitle =>
      'Dated construction photos will appear here as the developer uploads them.';

  @override
  String get noReviewsYet => 'No reviews yet';

  @override
  String get reviewsEmptySubtitle =>
      'Be the first to share how it went — or ask us anything first.';

  @override
  String get writeReviewAction => 'Write a review';

  @override
  String get submitReviewAction => 'Submit review';

  @override
  String get reviewBodyHint => 'Share your experience with this project...';

  @override
  String reviewsCount(int count) {
    return '$count reviews';
  }

  @override
  String get flagReviewAction => 'Report review';

  @override
  String get reviewFlaggedSnackbar => 'Thanks — we\'ll take a look';

  @override
  String get viewUnitGrid => 'View unit grid';

  @override
  String get requestCallback => 'Request a callback';

  @override
  String fromPrice(String price) {
    return 'From $price';
  }

  @override
  String rentFromPrice(String price) {
    return 'Rent from $price';
  }

  @override
  String get noDescription => 'No description.';

  @override
  String get amenitiesTitle => 'Amenities';

  @override
  String get projectDetailsMenu => 'Project details';

  @override
  String get offersInstallmentsMenu => 'Offers & installments';

  @override
  String get supportMenu => 'Support';

  @override
  String get noneLabel => 'None';

  @override
  String activeOffersCount(int count) {
    return '$count active';
  }

  @override
  String get requestCallbackTrailing => 'Request callback';

  @override
  String builtPercent(int percent) {
    return '$percent% built';
  }

  @override
  String completionDate(String date) {
    return 'Completion: $date';
  }

  @override
  String get readyToMoveIn => 'Ready to move in';

  @override
  String get handedOverToResidents => 'Handed over to residents';

  @override
  String get offersSheetTitle => 'Offers';

  @override
  String get noActiveOffers => 'No active offers for this project yet.';

  @override
  String get iBuildPartner => 'iBuild partner';

  @override
  String get verifiedBadgeLabel => 'Verified';

  @override
  String get verificationPendingBadgeLabel => 'Verification in progress';

  @override
  String get verificationDisclaimer =>
      '\"Verified\" means iBuild has checked the developer\'s submitted documents against public government registries as of the date shown. It is not a guarantee of construction completion, nor legal or financial advice — please verify current details yourself before making a decision.';

  @override
  String get documentTypeLicense => 'Business license';

  @override
  String get documentTypeConstructionPermit => 'Construction permit';

  @override
  String get documentTypeLandRights => 'Land rights';

  @override
  String get documentTypeProjectDeclaration => 'Project declaration';

  @override
  String get documentTypeCadastre => 'Cadastre';

  @override
  String get documentStatusAccepted => 'Accepted';

  @override
  String get documentStatusPending => 'Pending';

  @override
  String get documentStatusRejected => 'Rejected';

  @override
  String get documentStatusMissing => 'Not submitted';

  @override
  String get availabilityTitle => 'Availability';

  @override
  String get legendSoldRented => 'Sold / Rented';

  @override
  String get chessboardFilterAll => 'All types';

  @override
  String get chessboardRoomsLegendTitle => 'Rooms:';

  @override
  String get chessboardRooms4Plus => '4+';

  @override
  String get unitFallbackTitle => 'Unit';

  @override
  String unitNumberTitle(String number) {
    return 'Unit $number';
  }

  @override
  String get unitNotFound => 'Unit not found';

  @override
  String roomsCount(int count) {
    return '$count rooms';
  }

  @override
  String floorLabel(int floor) {
    return 'Floor $floor';
  }

  @override
  String viewLabel(String view) {
    return '$view view';
  }

  @override
  String get offplanInstallmentBadge => 'Off-plan · installment available';

  @override
  String minimumLeaseMonths(int months) {
    return 'Minimum lease: $months months';
  }

  @override
  String get bookViewing => 'Book a viewing';

  @override
  String get rentEnquiry => 'Rent enquiry';

  @override
  String get reserve => 'Reserve';

  @override
  String get newInquiryTitle => 'New inquiry';

  @override
  String get whatDoYouNeed => 'What do you need?';

  @override
  String get contactPhoneLabel => 'Contact phone';

  @override
  String get commentOptionalLabel => 'Comment (optional)';

  @override
  String get commentHint => 'Preferred time, questions...';

  @override
  String get piiConsentLabel =>
      'I agree to the processing of my personal data (name and phone number) so iBuild and this developer can contact me about my enquiry.';

  @override
  String get piiConsentRequiredError =>
      'Please agree to the processing of your personal data to continue.';

  @override
  String get submitInquiry => 'Submit inquiry';

  @override
  String leadSubmittedSnackbar(String number) {
    return 'Lead $number submitted';
  }

  @override
  String get leadSignInRequiredTitle => 'Sign in to send this inquiry';

  @override
  String get leadSignInRequiredBody =>
      'Create or sign in to your iBuild account so the developer can reach you about this request.';

  @override
  String get leadSignInCta => 'Sign in to continue';

  @override
  String get leadSignInRequiredError =>
      'Please sign in to submit this inquiry.';

  @override
  String get myInquiriesTitle => 'My inquiries';

  @override
  String get tabActive => 'Active';

  @override
  String get tabCompleted => 'Completed';

  @override
  String get tabCancelled => 'Cancelled';

  @override
  String get nothingHereYet => 'Nothing here yet';

  @override
  String get inquiriesEmptySubtitle =>
      'Your callback and viewing requests will show up here.';

  @override
  String get inquiriesSignInRequiredTitle => 'Sign in to see your inquiries';

  @override
  String get inquiriesSignInRequiredBody =>
      'Sign in to your iBuild account to view callback and viewing requests.';

  @override
  String get savedTitle => 'Saved';

  @override
  String get tabSavedSearches => 'Saved searches';

  @override
  String get noFavoritesYet => 'No favorites yet';

  @override
  String get favoritesEmptySubtitle =>
      'Tap the heart on any listing to save it here.';

  @override
  String get savedSearchesEmptySubtitle =>
      'Save a search from the filters sheet to get back to it quickly.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get guestUser => 'Guest user';

  @override
  String get appearanceTitle => 'Appearance';

  @override
  String get darkModeLabel => 'Dark mode';

  @override
  String get lightModeLabel => 'Light mode';

  @override
  String get paletteLabel => 'Palette';

  @override
  String get languageLabel => 'Language';

  @override
  String get currencyLabel => 'Currency';

  @override
  String exchangeRateTooltip(String rate) {
    return '1 USD = $rate UZS';
  }

  @override
  String get timeJustNow => 'now';

  @override
  String timeMinutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String timeHoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String timeDaysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String get accountTitle => 'Account';

  @override
  String get preferencesLabel => 'Preferences';

  @override
  String get notificationsLabel => 'Notifications';

  @override
  String get helpSupportLabel => 'Help & support';

  @override
  String get signOutLabel => 'Sign out';

  @override
  String get accountBannedTitle => 'Your account has been banned';

  @override
  String get accountBannedReasonLabel => 'Reason';

  @override
  String accountBannedByLabel(String name) {
    return 'Banned by $name';
  }

  @override
  String get projectTypeResidentialComplex => 'Residential complex';

  @override
  String get projectTypeBusinessCentre => 'Business centre';

  @override
  String get projectTypeStreetRetail => 'Street retail';

  @override
  String get projectTypeOffice => 'Office';

  @override
  String get projectTypeCottage => 'Cottage';

  @override
  String get unitKindApartment => 'Apartment';

  @override
  String get unitKindOffice => 'Office';

  @override
  String get unitKindRetail => 'Retail';

  @override
  String get projectStatusPlanned => 'Planned';

  @override
  String get projectStatusUnderConstruction => 'Under construction';

  @override
  String get projectStatusReady => 'Ready';

  @override
  String get projectStatusHandedOver => 'Handed over';

  @override
  String get statusAvailable => 'Available';

  @override
  String get statusReserved => 'Reserved';

  @override
  String get statusSold => 'Sold';

  @override
  String get statusRented => 'Rented';

  @override
  String get statusBlocked => 'Blocked';

  @override
  String get leadIntentBuy => 'Buy';

  @override
  String get leadIntentBuyOffplan => 'Off-plan reservation';

  @override
  String get leadIntentRent => 'Rent enquiry';

  @override
  String get leadIntentViewing => 'Viewing';

  @override
  String get leadIntentCallback => 'Callback';

  @override
  String get leadStatusNew => 'New';

  @override
  String get leadStatusContacted => 'Contacted';

  @override
  String get leadStatusScheduled => 'Scheduled';

  @override
  String get leadStatusVisited => 'Visited';

  @override
  String get leadStatusWon => 'Won';

  @override
  String get leadStatusLost => 'Lost';

  @override
  String get somethingWentWrong => 'Something went wrong.';

  @override
  String get retry => 'Retry';

  @override
  String viewGalleryCount(int count) {
    return 'Gallery · $count photos';
  }

  @override
  String galleryPhotoOfTotal(int index, int total) {
    return '$index / $total';
  }

  @override
  String get floorPlansEmptyMessage =>
      'Floor plans will appear here once available.';

  @override
  String get layoutsTitle => 'Apartment layouts';

  @override
  String layoutRoomsLabel(int count) {
    return '$count-room';
  }

  @override
  String layoutAvailability(int available, int total) {
    return '$available of $total available';
  }

  @override
  String get viewAvailableUnits => 'View available units';

  @override
  String get callAgentLabel => 'Call agent';

  @override
  String get agentPhoneUnavailable => 'Phone number unavailable';

  @override
  String get callFailedSnackbar => 'Couldn\'t start the call';

  @override
  String get contactAgentTitle => 'Sales agent';

  @override
  String get viewInsideLabel => 'Look inside';

  @override
  String get searchHint => 'Search projects, districts...';

  @override
  String get filtersTitle => 'Filters';

  @override
  String get districtLabel => 'District';

  @override
  String get statusLabel => 'Status';

  @override
  String priceRangeLabel(String min, String max) {
    return 'Price: $min – $max';
  }

  @override
  String get roomsLabel => 'Rooms';

  @override
  String get roomsStudio => 'Studio';

  @override
  String roomsPlus(int count) {
    return '$count+';
  }

  @override
  String get areaMinLabel => 'Area from, m²';

  @override
  String get offplanOnlyLabel => 'Off-plan only';

  @override
  String get applyFilters => 'Apply filters';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get filtersApplied => 'Filters applied';

  @override
  String get filterDistrictsHint => 'Select one or more districts';

  @override
  String districtsSelectedCount(int count) {
    return '$count districts selected';
  }

  @override
  String get saveThisSearch => 'Save this search';

  @override
  String get savedSearchSavedSnackbar => 'Search saved';

  @override
  String savedSearchUnderPrice(String price) {
    return 'under $price';
  }

  @override
  String savedSearchFromPrice(String price) {
    return 'from $price';
  }

  @override
  String get noSavedSearchesYet => 'No saved searches yet';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsEmpty => 'No notifications yet';

  @override
  String get notificationsEmptySubtitle =>
      'We\'ll let you know about price drops, new offers and updates.';

  @override
  String get markAllRead => 'Mark all read';

  @override
  String get notifLeadStatusTitle => 'Inquiry status updated';

  @override
  String notifLeadStatusBody(String status) {
    return 'Your inquiry is now “$status”.';
  }

  @override
  String get notifNewOfferTitle => 'New offer available';

  @override
  String get notifNewOfferBody =>
      'A new offer was added to a project you follow.';

  @override
  String get notifLeadCreatedTitle => 'Inquiry received';

  @override
  String get notifLeadCreatedBody =>
      'We received your inquiry and will be in touch shortly.';

  @override
  String get compareModeAction => 'Compare units';

  @override
  String compareCountLabel(int count) {
    return 'Compare ($count)';
  }

  @override
  String get addToCompareAction => 'Add to compare';

  @override
  String get compareTitle => 'Compare units';

  @override
  String get compareEmpty => 'Select units to compare them side by side';

  @override
  String get compareAreaLabel => 'Area';

  @override
  String get comparePriceLabel => 'Price';

  @override
  String get compareFloorLabel => 'Floor';

  @override
  String get compareRoomsLabel => 'Rooms';

  @override
  String get compareStatusLabel => 'Status';

  @override
  String get compareViewLabel => 'View';

  @override
  String get installmentCalculatorTitle => 'Installment calculator';

  @override
  String downPaymentLabel(int percent, String amount) {
    return 'Down payment: $percent% ($amount)';
  }

  @override
  String termMonthsLabel(int months) {
    return 'Term: $months months';
  }

  @override
  String get monthlyPaymentLabel => 'Monthly payment';

  @override
  String get calculateInstallmentAction => 'Calculate';

  @override
  String get rentalRentLabel => 'Monthly rent';

  @override
  String get ownerListingsSectionTitle => 'Owner listings nearby';

  @override
  String get secondaryTag => 'Secondary';

  @override
  String get perMonthSuffix => '/mo';

  @override
  String get forBusinessTitle => 'Own a property or a business?';

  @override
  String get forBusinessSubtitle =>
      'List sale or rental inventory, manage leads and track analytics in iBuild for Business.';

  @override
  String get forBusinessAction => 'Open iBuild for Business';

  @override
  String get mortgageCalculatorAction => 'Mortgage calculator';

  @override
  String get mortgageCalculatorTitle => 'Bank mortgage calculator';

  @override
  String get mortgagePropertyPriceLabel => 'Property price';

  @override
  String get toolsSectionTitle => 'Tools';

  @override
  String interestRateLabel(String percent) {
    return 'Bank rate: $percent% / year';
  }

  @override
  String termYearsLabel(int years) {
    return 'Term: $years years';
  }

  @override
  String get totalInterestLabel => 'Total interest';

  @override
  String get totalPaymentLabel => 'Total payment';

  @override
  String get downPaymentAmountLabel => 'Down payment';

  @override
  String get bankReferralConsentLabel =>
      'I agree to be contacted by an iBuild bank partner about this mortgage';

  @override
  String get requestBankConsultationAction => 'Request bank consultation';

  @override
  String get bankReferralSubmittedSnackbar =>
      'A bank partner will contact you shortly';

  @override
  String get rentalYieldCalculatorAction => 'Rental yield calculator';

  @override
  String get rentalYieldCalculatorTitle => 'Rental yield calculator';

  @override
  String get grossYieldLabel => 'Gross yield';

  @override
  String get paybackYearsLabel => 'Payback period';

  @override
  String paybackYearsValue(String years) {
    return '$years years';
  }

  @override
  String get annualRentLabel => 'Annual rent';

  @override
  String get calculatingLabel => 'Calculating...';

  @override
  String get quizTitle => 'Find your match';

  @override
  String get quizIntroTitle => 'Let\'s personalize your search';

  @override
  String get quizIntroBody =>
      'Answer 4 quick questions and we\'ll tune your feed and shape an on-device AI preview — just for you.';

  @override
  String get quizStartAction => 'Start the quiz';

  @override
  String quizStepCounter(int current, int total) {
    return '$current of $total';
  }

  @override
  String get quizSavedSnackbar => 'Preferences saved';

  @override
  String get quizGoalQuestion => 'What matters most in your next home?';

  @override
  String get quizGoalBudget => 'Great value';

  @override
  String get quizGoalFamily => 'Room for the family';

  @override
  String get quizGoalInvestment => 'A smart investment';

  @override
  String get quizGoalLuxury => 'Premium living';

  @override
  String get quizLocationQuestion => 'Where do you picture yourself?';

  @override
  String get quizLocationCityCenter => 'In the heart of the city';

  @override
  String get quizLocationQuietSuburb => 'A calm, green neighbourhood';

  @override
  String get quizLocationBusinessDistrict => 'Close to the business district';

  @override
  String get quizLocationUpAndComing => 'An up-and-coming area';

  @override
  String get quizTimelineQuestion => 'When would you like to move in?';

  @override
  String get quizTimelineReadyNow => 'As soon as possible';

  @override
  String get quizTimelineOffplanOk => 'Happy to wait for a new build';

  @override
  String get quizTimelineFlexible => 'I\'m flexible';

  @override
  String get quizPriorityQuestion => 'Pick your number-one priority';

  @override
  String get quizPriorityPrice => 'Price';

  @override
  String get quizPrioritySpace => 'Space & layout';

  @override
  String get quizPriorityAmenities => 'Amenities';

  @override
  String get quizPriorityLocation => 'Location';

  @override
  String get quizResultEyebrow => 'Your buyer persona';

  @override
  String get quizPersonaFirstTimeBuyer => 'First-time buyer';

  @override
  String get quizPersonaFamilyNester => 'Family nester';

  @override
  String get quizPersonaInvestor => 'Savvy investor';

  @override
  String get quizPersonaLuxurySeeker => 'Luxury seeker';

  @override
  String get quizPersonaFirstTimeBuyerDesc =>
      'You want the best possible home for your budget. We\'ll surface strong-value units and flexible installment plans.';

  @override
  String get quizPersonaFamilyNesterDesc =>
      'Space and comfort come first. We\'ll highlight larger layouts in calm, well-served neighbourhoods.';

  @override
  String get quizPersonaInvestorDesc =>
      'You\'re after returns. We\'ll spotlight high-yield units and off-plan opportunities with upside.';

  @override
  String get quizPersonaLuxurySeekerDesc =>
      'Only the finest will do. We\'ll curate premium residences with standout amenities and locations.';

  @override
  String get quizPreviewTitle => 'Your AI preview';

  @override
  String get quizPreviewPromptLabel => 'Prompt (on-device mock)';

  @override
  String quizPreviewBody(String persona) {
    return 'As a $persona, you\'ll see the best-matching homes first. We\'ll lead with what you care about and refresh it as new listings arrive. This preview is generated locally — no data leaves your device.';
  }

  @override
  String get quizDoneAction => 'Browse my matches';

  @override
  String get quizRetakeAction => 'Retake quiz';

  @override
  String get quizEntryAction => 'Take the quiz';

  @override
  String get leadSubjectLabel => 'What\'s this about?';

  @override
  String get leadSubjectProject => 'A project';

  @override
  String get leadSubjectUnit => 'A specific unit';

  @override
  String get leadSubjectRent => 'Renting';

  @override
  String get leadSubjectOffice => 'An office';

  @override
  String get leadSubjectMortgage => 'Mortgage consult';

  @override
  String get leadSubjectOther => 'Something else';

  @override
  String get aiFabTooltip => 'Ask iBuild AI';

  @override
  String get aiChatTitle => 'iBuild AI';

  @override
  String get aiChatInfoTooltip => 'About iBuild AI';

  @override
  String get aiChatInfoBody =>
      'Ask about the catalogue, a specific complex or unit, or how installments and mortgages work — iBuild AI answers using iBuild\'s own listings and terms.';

  @override
  String get aiChatErrorSnackbar => 'Couldn\'t get a reply. Please try again.';

  @override
  String get aiChatQuotaExhaustedTitle => 'Daily limit reached';

  @override
  String get aiChatQuotaExhaustedBody =>
      'You\'ve used today\'s iBuild AI messages. Please come back tomorrow.';

  @override
  String get aiChatUnavailableTitle => 'iBuild AI is taking a break';

  @override
  String get aiChatUnavailableBody =>
      'The assistant is temporarily unavailable. Please try again later.';

  @override
  String get aiChatEmptyTitle => 'Ask iBuild AI anything';

  @override
  String get aiChatEmptyBody =>
      'Try “Which complexes in Chilanzar have installments?” or “What\'s a good mortgage rate for a \$60,000 flat?”';

  @override
  String get aiChatInputHint => 'Message iBuild AI...';

  @override
  String get aiChatSendTooltip => 'Send';

  @override
  String get aiBetaNoticeTitle => 'iBuild AI is in testing';

  @override
  String get aiBetaNoticeBody =>
      'Answers may occasionally be inaccurate — always double-check details like price and availability on the listing itself.';

  @override
  String get aiQuotaTitle => 'Daily quota';

  @override
  String aiQuotaUsedLabel(int used, int limit) {
    return '$used of $limit messages used today';
  }

  @override
  String aiQuotaResetLabel(String time) {
    return 'Resets $time';
  }

  @override
  String get aiSearchInfoExamplesTitle => 'Try asking';

  @override
  String get aiSearchInfoTitle => 'AI smart search';

  @override
  String get aiSearchInfoBody =>
      'Describe what you\'re looking for in plain language — rooms, budget, district, anything that matters to you — and iBuild AI will parse it into a live search of the catalogue.';

  @override
  String get aiSearchExample1 => '2-room in Chilanzar under \$60k';

  @override
  String get aiSearchExample2 =>
      '3-bedroom office near the business district, ready now';

  @override
  String get aiSearchExample3 =>
      'Apartment for rent, not on the first floor, with parking';

  @override
  String get aiSearchHint => 'Describe what you\'re looking for...';

  @override
  String get aiSearchClearTooltip => 'Clear search';

  @override
  String get aiSearchSubmitTooltip => 'Search';

  @override
  String get aiSearchInfoTooltip => 'About AI search';

  @override
  String get aiSearchRateLimitedTitle => 'Daily search limit reached';

  @override
  String aiSearchRateLimitedBody(String time) {
    return 'You have reached the daily AI search limit. Please come back $time.';
  }

  @override
  String get aiSearchUnavailableTitle => 'AI search is taking a break';

  @override
  String get aiSearchUnavailableBody =>
      'Smart search is temporarily unavailable. Please try again later.';

  @override
  String get aiSearchGenericErrorTitle => 'Couldn\'t run that search';

  @override
  String get aiSearchGenericErrorBody =>
      'Something went wrong. Please try again in a moment.';

  @override
  String aiSearchUnrecognizedNote(String terms) {
    return 'Not sure what you meant by: $terms';
  }

  @override
  String aiSearchSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count matches',
      one: '1 match',
      zero: 'No matches',
    );
    return '$_temp0';
  }

  @override
  String get aiSearchResultsEmptyTitle => 'No matches yet';

  @override
  String get aiSearchResultsEmptyBody =>
      'Try loosening a constraint — a wider budget or a nearby district often helps.';

  @override
  String aiSearchMatchScoreLabel(int score) {
    return '$score% match';
  }

  @override
  String get aiSearchStatusStarting => 'Getting started...';

  @override
  String get aiSearchTabHintTooltip => 'Press Tab to accept the suggestion';

  @override
  String get aiSearchTabAcceptLabel => 'Accept the AI suggestion';

  @override
  String get aiSearchClarifyTitle => 'Could not understand the query';

  @override
  String aiSearchClarifyBody(String terms) {
    return 'These words are not in the catalogue: $terms. Rephrase the query or pick one of the suggestions below.';
  }

  @override
  String get aiSearchClarifyExamplesHint => 'Try one of these instead:';

  @override
  String aiSearchDidYouMean(String suggestion) {
    return 'Did you mean “$suggestion”?';
  }

  @override
  String aiSearchQuotedTerm(String term) {
    return '“$term”';
  }

  @override
  String aiSearchRelaxConstraint(String constraint) {
    return 'Drop: $constraint';
  }

  @override
  String aiStepParsingV1(int count) {
    return 'Reading your request ($count details)...';
  }

  @override
  String aiStepParsingV2(int count) {
    return 'Understanding what you\'re after ($count details)...';
  }

  @override
  String aiStepParsingV3(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count requirements',
      one: '1 requirement',
    );
    return 'Parsing $_temp0...';
  }

  @override
  String aiStepParsingV4(int count) {
    return 'Breaking down your request into $count parts...';
  }

  @override
  String aiStepScanningDistrictV1(String district, int count) {
    return 'Scanning $district ($count projects)...';
  }

  @override
  String aiStepScanningDistrictV2(String district, int count) {
    return 'Looking through $count projects in $district...';
  }

  @override
  String aiStepScanningDistrictV3(String district, int count) {
    return 'Checking availability in $district ($count projects)...';
  }

  @override
  String aiStepScanningDistrictV4(String district, int count) {
    return 'Surveying $district ($count projects)...';
  }

  @override
  String aiStepFoundInDistrictV1(String district, int count) {
    return 'Found $count in $district';
  }

  @override
  String aiStepFoundInDistrictV2(String district, int count) {
    return '$count candidates spotted in $district';
  }

  @override
  String aiStepFoundInDistrictV3(String district, int count) {
    return '$district: $count worth a closer look';
  }

  @override
  String aiStepFoundInDistrictV4(String district, int count) {
    return 'Shortlisted $count in $district';
  }

  @override
  String aiStepOpeningProjectV1(String project, int index, int total) {
    return 'Opening $project ($index/$total)...';
  }

  @override
  String aiStepOpeningProjectV2(String project, int index, int total) {
    return 'Looking inside $project ($index of $total)...';
  }

  @override
  String aiStepOpeningProjectV3(String project, int index, int total) {
    return 'Checking $project ($index of $total)...';
  }

  @override
  String aiStepOpeningProjectV4(String project, int index, int total) {
    return 'Now viewing $project ($index/$total)...';
  }

  @override
  String aiStepScanningUnitsV1(String project, int count) {
    return 'Scanning units in $project ($count)...';
  }

  @override
  String aiStepScanningUnitsV2(String project, int count) {
    return 'Checking $count units in $project...';
  }

  @override
  String aiStepScanningUnitsV3(String project, int count) {
    return 'Going through the floor plans in $project ($count units)...';
  }

  @override
  String aiStepScanningUnitsV4(String project, int count) {
    return '$project: reviewing $count units...';
  }

  @override
  String aiStepFilteringBookedV1(int removed, int left) {
    return 'Filtering out $removed unavailable, $left left...';
  }

  @override
  String aiStepFilteringBookedV2(int removed, int left) {
    return 'Removing $removed sold and reserved units ($left remain)...';
  }

  @override
  String aiStepFilteringBookedV3(int removed, int left) {
    return 'Skipping $removed already taken, $left left...';
  }

  @override
  String aiStepFilteringBookedV4(int removed, int left) {
    return 'Keeping only the $left available units (removed $removed)...';
  }

  @override
  String aiStepRankingPriceV1(int count) {
    return 'Ranking $count by best fit...';
  }

  @override
  String aiStepRankingPriceV2(int count) {
    return 'Sorting $count by price and match quality...';
  }

  @override
  String aiStepRankingPriceV3(int count) {
    return 'Comparing $count options...';
  }

  @override
  String aiStepRankingPriceV4(int count) {
    return 'Lining up the best $count matches...';
  }

  @override
  String aiStepDoneV1(int count, int elapsedMs) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count matches',
      one: '1 match',
      zero: 'no matches',
    );
    return 'Done · $_temp0 in ${elapsedMs}ms';
  }

  @override
  String aiStepDoneV2(int count, int elapsedMs) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count matches found',
      one: '1 match found',
      zero: 'nothing quite matched',
    );
    return 'All set — $_temp0 (${elapsedMs}ms)';
  }

  @override
  String aiStepDoneV3(int count, int elapsedMs) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results',
      one: '1 result',
      zero: '0 results',
    );
    return 'Search complete ($_temp0, ${elapsedMs}ms)';
  }

  @override
  String aiStepDoneV4(int count, int elapsedMs) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count strong matches',
      one: '1 strong match',
      zero: 'no matches this time',
    );
    return 'Ready — $_temp0 (${elapsedMs}ms)';
  }

  @override
  String aiStepNoMatchIntent(String terms) {
    return 'Nothing in the catalogue matches $terms — stopping here';
  }

  @override
  String aiStepLowConfidence(String terms, int count) {
    return 'Not fully sure about $terms — showing broader matches ($count)';
  }

  @override
  String aiStepAutocorrected(String from, String to) {
    return 'Read “$from” as “$to”';
  }

  @override
  String aiStepSoftenedAmenity(String amenity) {
    return 'Relaxed the “$amenity” requirement to find options';
  }

  @override
  String get aiReasonDistrictMatch => 'Right district';

  @override
  String get aiReasonRoomsMatch => 'Room count matches';

  @override
  String get aiReasonPriceFit => 'Fits your budget';

  @override
  String get aiReasonPriceBelowBudget => 'Below budget';

  @override
  String get aiReasonAreaFit => 'Area matches';

  @override
  String get aiReasonFloorPreference => 'Floor preference';

  @override
  String get aiReasonDealTypeMatch => 'Sale/rent matches';

  @override
  String get aiReasonKindMatch => 'Unit type matches';

  @override
  String get aiReasonAvailableNow => 'Available now';

  @override
  String get aiReasonAmenityMatch => 'Has requested amenities';

  @override
  String get aiReasonDeveloperMatch => 'Requested developer';

  @override
  String get aiReasonProjectMatch => 'Requested project';

  @override
  String get aiReasonHighTrustIndex => 'High trust index';

  @override
  String get aiReasonReadySoon => 'Ready soon';

  @override
  String get aiReasonOffplanDiscount => 'Off-plan discount';

  @override
  String aiChipAreaRange(int min, int max) {
    return '$min–$max m²';
  }

  @override
  String aiChipAreaUpTo(int max) {
    return 'up to $max m²';
  }

  @override
  String aiChipAreaFrom(int min) {
    return 'from $min m²';
  }

  @override
  String get aiDealTypeRent => 'For rent';

  @override
  String get aiDealTypeSale => 'For sale';

  @override
  String get aiUnitKindApartment => 'Apartment';

  @override
  String get aiUnitKindCommercial => 'Commercial';

  @override
  String get aiUnitKindParking => 'Parking';

  @override
  String aiChipFloorRange(int min, int max) {
    return 'Floor $min–$max';
  }

  @override
  String aiChipFloorFrom(int min) {
    return 'Floor $min+';
  }

  @override
  String aiChipFloorUpTo(int max) {
    return 'Up to floor $max';
  }

  @override
  String get aiChipNotFirstFloor => 'Not first floor';

  @override
  String get aiChipNotLastFloor => 'Not last floor';

  @override
  String get aiChipAvailableOnly => 'Available only';

  @override
  String aiSearchShowAll(int count) {
    return 'Show all $count';
  }

  @override
  String get aiSearchAllResultsTitle => 'All results';

  @override
  String aiConstraintWithout(String amenity) {
    return 'Without $amenity';
  }
}
