// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Uzbek (`uz`).
class AppLocalizationsUz extends AppLocalizations {
  AppLocalizationsUz([String locale = 'uz']) : super(locale);

  @override
  String get navHome => 'Bosh sahifa';

  @override
  String get navSearch => 'Qidiruv';

  @override
  String get navFavorites => 'Sevimlilar';

  @override
  String get navInquiries => 'Murojaatlar';

  @override
  String get navSettings => 'Sozlamalar';

  @override
  String get onboardingSlogan => 'iBuild the dream';

  @override
  String get onboardingEyebrow => 'Soting. Sarmoya kiriting. Bir ilovada.';

  @override
  String get onboardingDescription =>
      'Tayyor kvartiralar, muddatli toʻlov bilan yangi qurilishlar va biznes-markazlardagi ofislar — barchasi bir joyda, real vaqtdagi mavjudlik va bir bosishda soʻrov bilan.';

  @override
  String get onboardingTrustBadge => '4.9★ · 500+ mamnun oila';

  @override
  String get start => 'Boshlash';

  @override
  String get signIn => 'Kirish';

  @override
  String get welcomeTitle => 'iBuildga xush kelibsiz';

  @override
  String get welcomeSubtitle => 'Telefon raqamingiz orqali kiring';

  @override
  String get phoneHint => '+998 90 123 45 67';

  @override
  String get sendCode => 'Kodni yuborish';

  @override
  String get phoneRequiredError => 'Telefon raqamingizni kiriting';

  @override
  String get otpTitle => 'Kodni kiriting';

  @override
  String otpSubtitle(String phone) {
    return '$phone raqamiga 6 xonali kod yubordik';
  }

  @override
  String get otpCodeHint => '6 xonali kod';

  @override
  String get otpDevHint => 'Test rejimi: 123456 kodidan foydalaning';

  @override
  String get stepOneOfTwo => '1-qadam, 2 tadan';

  @override
  String get stepTwoOfTwo => '2-qadam, 2 tadan';

  @override
  String get verifyCode => 'Tasdiqlash';

  @override
  String get resendCode => 'Kodni qayta yuborish';

  @override
  String get invalidCodeError =>
      'Kod xato yoki muddati oʻtgan. Qayta urinib koʻring.';

  @override
  String get signedInLabel => 'Tizimga kirilgan';

  @override
  String get accountTypeOrdinaryUser => 'Oddiy foydalanuvchi';

  @override
  String get signInPromptMessage =>
      'Sevimlilarni saqlash, murojaatlarni kuzatish va yangiliklarni olish uchun tizimga kiring.';

  @override
  String get madeForYou => 'Siz uchun tanlandi';

  @override
  String get exploreProperties => 'Obyektlarni koʻrish';

  @override
  String get recommendForYou => 'Sizga tavsiya etiladi';

  @override
  String get statsListingsLabel => 'Eʼlonlar';

  @override
  String get statsAvailableLabel => 'Boʻsh xonadonlar';

  @override
  String get statsDistrictsLabel => 'Tumanlar';

  @override
  String get statsRatingLabel => 'Oʻrtacha reyting';

  @override
  String get featuredForYouTitle => 'Siz uchun tanlangan';

  @override
  String get popularDistrictsTitle => 'Mashhur tumanlar';

  @override
  String get developersTitle => 'Quruvchilar';

  @override
  String developerProjectsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count loyiha',
      one: '1 loyiha',
    );
    return '$_temp0';
  }

  @override
  String get developerContactsTitle => 'Kontaktlar';

  @override
  String get developerResidencesTitle => 'Turar-joy majmualari';

  @override
  String get developerOfficesTitle => 'Ofislar';

  @override
  String get developerNotFoundTitle => 'Quruvchi topilmadi';

  @override
  String get developerNotFoundSubtitle => 'Bu quruvchi katalogda yo\'q.';

  @override
  String districtListingsCount(int count) {
    return '$count ta eʼlon';
  }

  @override
  String get promoBannerTitle => 'Yangi loyihalar boshlandi';

  @override
  String get promoBannerSubtitle =>
      'Tanlangan yangi qurilishlarda moslashuvchan muddatli toʻlov bilan oldindan band qiling.';

  @override
  String get promoBannerAction => 'Yangi qurilishlarni koʻrish';

  @override
  String get browseListingsAction => 'Eʼlonlarni koʻrish';

  @override
  String get modeBuy => 'Sotib olish';

  @override
  String get modeRent => 'Ijaraga olish';

  @override
  String get modeNewBuilds => 'Yangi qurilishlar';

  @override
  String get categoryAll => 'Barchasi';

  @override
  String get categoryApartments => 'Kvartiralar';

  @override
  String get categoryOffices => 'Ofislar';

  @override
  String get bestDeal => 'Eng yaxshi taklif';

  @override
  String get discountBadge => 'Chegirma';

  @override
  String get installmentBadge => 'Muddatli toʻlov';

  @override
  String unitsAvailableCount(int count) {
    return '$count ta boʻsh';
  }

  @override
  String get searchByLocations => 'Manzil boʻyicha qidirish';

  @override
  String liveLocationDistrict(String district) {
    return 'Joylashuv · $district';
  }

  @override
  String get mapZoomIn => 'Kattalashtirish';

  @override
  String get mapZoomOut => 'Kichiklashtirish';

  @override
  String get tabUnits => 'Xonadonlar';

  @override
  String get tabFloorPlans => 'Planlar';

  @override
  String get tabAbout => 'Loyiha haqida';

  @override
  String get tabReviews => 'Sharhlar';

  @override
  String get tabProgress => 'Qurilish jarayoni';

  @override
  String get overallProgressTitle => 'Umumiy qurilish jarayoni';

  @override
  String get progressEmptyTitle => 'Hozircha fotohisobotlar yoʻq';

  @override
  String get progressEmptySubtitle =>
      'Quruvchi yuklagan sanali qurilish fotolari shu yerda paydo boʻladi.';

  @override
  String get noReviewsYet => 'Hozircha sharhlar yoʻq';

  @override
  String get reviewsEmptySubtitle =>
      'Birinchi boʻlib fikr bildiring — yoki avval savol bering.';

  @override
  String get writeReviewAction => 'Sharh yozish';

  @override
  String get submitReviewAction => 'Sharhni yuborish';

  @override
  String get reviewBodyHint => 'Ushbu loyiha haqidagi fikringizni yozing...';

  @override
  String reviewsCount(int count) {
    return '$count sharh';
  }

  @override
  String get flagReviewAction => 'Shikoyat qilish';

  @override
  String get reviewFlaggedSnackbar => 'Rahmat — tekshirib chiqamiz';

  @override
  String get viewUnitGrid => 'Mavjudlik jadvalini koʻrish';

  @override
  String get requestCallback => 'Qayta qoʻngʻiroq soʻrash';

  @override
  String fromPrice(String price) {
    return '$price dan boshlab';
  }

  @override
  String rentFromPrice(String price) {
    return 'Ijaraga $price dan';
  }

  @override
  String get noDescription => 'Tavsif mavjud emas.';

  @override
  String get amenitiesTitle => 'Qulayliklar';

  @override
  String get projectDetailsMenu => 'Loyiha haqida';

  @override
  String get offersInstallmentsMenu => 'Aksiya va muddatli toʻlov';

  @override
  String get supportMenu => 'Yordam';

  @override
  String get noneLabel => 'Yoʻq';

  @override
  String activeOffersCount(int count) {
    return '$count ta faol';
  }

  @override
  String get requestCallbackTrailing => 'Qoʻngʻiroq soʻrash';

  @override
  String builtPercent(int percent) {
    return '$percent% qurilgan';
  }

  @override
  String completionDate(String date) {
    return 'Topshirish sanasi: $date';
  }

  @override
  String get readyToMoveIn => 'Koʻchib oʻtishga tayyor';

  @override
  String get handedOverToResidents => 'Foydalanuvchilarga topshirilgan';

  @override
  String get offersSheetTitle => 'Aksiyalar';

  @override
  String get noActiveOffers => 'Bu loyiha uchun hozircha faol aksiyalar yoʻq.';

  @override
  String get iBuildPartner => 'iBuild hamkori';

  @override
  String get verifiedBadgeLabel => 'Tasdiqlangan';

  @override
  String get verificationPendingBadgeLabel => 'Tekshirilmoqda';

  @override
  String get verificationDisclaimer =>
      '\"Tasdiqlangan\" holati iBuild quruvchi taqdim etgan hujjatlarni koʻrsatilgan sanaga oid ochiq davlat reyestrlari bilan solishtirganini bildiradi. Bu qurilishning yakunlanishiga kafolat, yuridik yoki moliyaviy tavsiya emas — qaror qabul qilishdan oldin dolzarb maʼlumotlarni mustaqil tekshiring.';

  @override
  String get documentTypeLicense => 'Quruvchi litsenziyasi';

  @override
  String get documentTypeConstructionPermit => 'Qurilish ruxsatnomasi';

  @override
  String get documentTypeLandRights => 'Yer huquqlari';

  @override
  String get documentTypeProjectDeclaration => 'Loyiha deklaratsiyasi';

  @override
  String get documentTypeCadastre => 'Kadastr';

  @override
  String get documentStatusAccepted => 'Qabul qilingan';

  @override
  String get documentStatusPending => 'Tekshirilmoqda';

  @override
  String get documentStatusRejected => 'Rad etilgan';

  @override
  String get documentStatusMissing => 'Taqdim etilmagan';

  @override
  String get availabilityTitle => 'Mavjudlik';

  @override
  String get legendSoldRented => 'Sotilgan / Ijaraga berilgan';

  @override
  String get chessboardFilterAll => 'Barcha turlar';

  @override
  String get chessboardRoomsLegendTitle => 'Xonalar:';

  @override
  String get chessboardRooms4Plus => '4+';

  @override
  String get unitFallbackTitle => 'Xonadon';

  @override
  String unitNumberTitle(String number) {
    return 'Xonadon $number';
  }

  @override
  String get unitNotFound => 'Xonadon topilmadi';

  @override
  String roomsCount(int count) {
    return '$count xona';
  }

  @override
  String floorLabel(int floor) {
    return '$floor-qavat';
  }

  @override
  String viewLabel(String view) {
    return 'Manzara: $view';
  }

  @override
  String get offplanInstallmentBadge =>
      'Yangi qurilish · muddatli toʻlov mavjud';

  @override
  String minimumLeaseMonths(int months) {
    return 'Minimal ijara muddati: $months oy';
  }

  @override
  String get bookViewing => 'Koʻrikka yozilish';

  @override
  String get rentEnquiry => 'Ijaraga olish uchun soʻrov';

  @override
  String get reserve => 'Band qilish';

  @override
  String get newInquiryTitle => 'Yangi murojaat';

  @override
  String get whatDoYouNeed => 'Sizga nima kerak?';

  @override
  String get contactPhoneLabel => 'Aloqa telefoni';

  @override
  String get commentOptionalLabel => 'Izoh (ixtiyoriy)';

  @override
  String get commentHint => 'Qulay vaqt, savollar...';

  @override
  String get piiConsentLabel =>
      'Men shaxsiy maʼlumotlarim (ism va telefon raqami) qayta ishlanishiga roziman, shunda iBuild va shu quruvchi murojaatim boʻyicha men bilan bogʻlanishi mumkin.';

  @override
  String get piiConsentRequiredError =>
      'Davom etish uchun shaxsiy maʼlumotlarni qayta ishlashga roziligingizni tasdiqlang.';

  @override
  String get submitInquiry => 'Murojaatni yuborish';

  @override
  String leadSubmittedSnackbar(String number) {
    return '$number raqamli murojaat yuborildi';
  }

  @override
  String get leadSignInRequiredTitle =>
      'Murojaatni yuborish uchun tizimga kiring';

  @override
  String get leadSignInRequiredBody =>
      'Quruvchi sizning murojaatingiz boʻyicha bogʻlanishi uchun iBuild hisobingizga kiring yoki roʻyxatdan oʻting.';

  @override
  String get leadSignInCta => 'Davom etish uchun kiring';

  @override
  String get leadSignInRequiredError =>
      'Murojaatni yuborish uchun tizimga kiring.';

  @override
  String get myInquiriesTitle => 'Mening murojaatlarim';

  @override
  String get tabActive => 'Faol';

  @override
  String get tabCompleted => 'Yakunlangan';

  @override
  String get tabCancelled => 'Bekor qilingan';

  @override
  String get nothingHereYet => 'Hozircha boʻsh';

  @override
  String get inquiriesEmptySubtitle =>
      'Qayta qoʻngʻiroq va koʻrik soʻrovlaringiz shu yerda koʻrinadi.';

  @override
  String get savedTitle => 'Saqlanganlar';

  @override
  String get tabSavedSearches => 'Saqlangan qidiruvlar';

  @override
  String get noFavoritesYet => 'Hozircha sevimlilar yoʻq';

  @override
  String get favoritesEmptySubtitle =>
      'Saqlash uchun eʼlondagi yurak belgisini bosing.';

  @override
  String get savedSearchesEmptySubtitle =>
      'Filtrlar oynasida qidiruvni saqlab, keyin tezda qaytishingiz mumkin.';

  @override
  String get settingsTitle => 'Sozlamalar';

  @override
  String get guestUser => 'Mehmon';

  @override
  String get appearanceTitle => 'Koʻrinish';

  @override
  String get darkModeLabel => 'Tungi rejim';

  @override
  String get paletteLabel => 'Rang sxemasi';

  @override
  String get languageLabel => 'Til';

  @override
  String get currencyLabel => 'Valyuta';

  @override
  String exchangeRateTooltip(String rate) {
    return '1 USD = $rate UZS';
  }

  @override
  String get timeJustNow => 'hozir';

  @override
  String timeMinutesAgo(int count) {
    return '$count daqiqa oldin';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count soat oldin';
  }

  @override
  String timeDaysAgo(int count) {
    return '$count kun oldin';
  }

  @override
  String get accountTitle => 'Hisob';

  @override
  String get preferencesLabel => 'Afzalliklar';

  @override
  String get notificationsLabel => 'Bildirishnomalar';

  @override
  String get helpSupportLabel => 'Yordam va qoʻllab-quvvatlash';

  @override
  String get signOutLabel => 'Chiqish';

  @override
  String get accountBannedTitle => 'Hisobingiz bloklangan';

  @override
  String get accountBannedReasonLabel => 'Sabab';

  @override
  String accountBannedByLabel(String name) {
    return 'Bloklagan: $name';
  }

  @override
  String get projectTypeResidentialComplex => 'Turar-joy majmuasi';

  @override
  String get projectTypeBusinessCentre => 'Biznes-markaz';

  @override
  String get projectTypeStreetRetail => 'Strit-riteyl';

  @override
  String get projectTypeOffice => 'Ofis';

  @override
  String get projectTypeCottage => 'Kottej';

  @override
  String get unitKindApartment => 'Kvartira';

  @override
  String get unitKindOffice => 'Ofis';

  @override
  String get unitKindRetail => 'Savdo maydoni';

  @override
  String get projectStatusPlanned => 'Rejalashtirilgan';

  @override
  String get projectStatusUnderConstruction => 'Qurilmoqda';

  @override
  String get projectStatusReady => 'Tayyor';

  @override
  String get projectStatusHandedOver => 'Topshirilgan';

  @override
  String get statusAvailable => 'Boʻsh';

  @override
  String get statusReserved => 'Band qilingan';

  @override
  String get statusSold => 'Sotilgan';

  @override
  String get statusRented => 'Ijaraga berilgan';

  @override
  String get statusBlocked => 'Bloklangan';

  @override
  String get leadIntentBuy => 'Sotib olish';

  @override
  String get leadIntentBuyOffplan => 'Yangi qurilishni band qilish';

  @override
  String get leadIntentRent => 'Ijaraga olish soʻrovi';

  @override
  String get leadIntentViewing => 'Koʻrik';

  @override
  String get leadIntentCallback => 'Qayta qoʻngʻiroq';

  @override
  String get leadStatusNew => 'Yangi';

  @override
  String get leadStatusContacted => 'Bogʻlanildi';

  @override
  String get leadStatusScheduled => 'Rejalashtirildi';

  @override
  String get leadStatusVisited => 'Koʻrik boʻldi';

  @override
  String get leadStatusWon => 'Muvaffaqiyatli';

  @override
  String get leadStatusLost => 'Bekor qilindi';

  @override
  String get somethingWentWrong => 'Nimadir xato ketdi.';

  @override
  String get retry => 'Qayta urinish';

  @override
  String viewGalleryCount(int count) {
    return 'Galereya · $count surat';
  }

  @override
  String galleryPhotoOfTotal(int index, int total) {
    return '$index / $total';
  }

  @override
  String get floorPlansEmptyMessage =>
      'Qavat rejalari tayyor boʻlganda shu yerda koʻrinadi.';

  @override
  String get layoutsTitle => 'Xonadon planirovkalari';

  @override
  String layoutRoomsLabel(int count) {
    return '$count xonali';
  }

  @override
  String layoutAvailability(int available, int total) {
    return '$total tadan $available tasi boʻsh';
  }

  @override
  String get viewAvailableUnits => 'Boʻsh xonadonlarni koʻrish';

  @override
  String get callAgentLabel => 'Agentga qoʻngʻiroq';

  @override
  String get agentPhoneUnavailable => 'Telefon raqami mavjud emas';

  @override
  String get callFailedSnackbar => 'Qoʻngʻiroqni boshlab boʻlmadi';

  @override
  String get contactAgentTitle => 'Sotuv agenti';

  @override
  String get viewInsideLabel => 'Ichkarini koʻrish';

  @override
  String get searchHint => 'Loyihalar, tumanlarni qidirish...';

  @override
  String get filtersTitle => 'Filtrlar';

  @override
  String get districtLabel => 'Tuman';

  @override
  String get statusLabel => 'Holat';

  @override
  String priceRangeLabel(String min, String max) {
    return 'Narx: $min – $max';
  }

  @override
  String get roomsLabel => 'Xonalar';

  @override
  String get roomsStudio => 'Studiya';

  @override
  String roomsPlus(int count) {
    return '$count+';
  }

  @override
  String get areaMinLabel => 'Maydon, m² dan';

  @override
  String get offplanOnlyLabel => 'Faqat qurilayotgan';

  @override
  String get applyFilters => 'Qoʻllash';

  @override
  String get clearFilters => 'Tozalash';

  @override
  String get saveThisSearch => 'Qidiruvni saqlash';

  @override
  String get savedSearchSavedSnackbar => 'Qidiruv saqlandi';

  @override
  String savedSearchUnderPrice(String price) {
    return '$price gacha';
  }

  @override
  String savedSearchFromPrice(String price) {
    return '$price dan';
  }

  @override
  String get noSavedSearchesYet => 'Saqlangan qidiruvlar yoʻq';

  @override
  String get notificationsTitle => 'Bildirishnomalar';

  @override
  String get notificationsEmpty => 'Hozircha bildirishnomalar yoʻq';

  @override
  String get notificationsEmptySubtitle =>
      'Narx tushishi, yangi taklif va yangiliklar haqida sizga xabar beramiz.';

  @override
  String get markAllRead => 'Barchasini oʻqilgan deb belgilash';

  @override
  String get compareModeAction => 'Xonadonlarni solishtirish';

  @override
  String compareCountLabel(int count) {
    return 'Solishtirish ($count)';
  }

  @override
  String get addToCompareAction => 'Solishtirishga qoʻshish';

  @override
  String get compareTitle => 'Xonadonlarni solishtirish';

  @override
  String get compareEmpty => 'Solishtirish uchun xonadonlarni tanlang';

  @override
  String get compareAreaLabel => 'Maydon';

  @override
  String get comparePriceLabel => 'Narx';

  @override
  String get compareFloorLabel => 'Qavat';

  @override
  String get compareRoomsLabel => 'Xonalar';

  @override
  String get compareStatusLabel => 'Holat';

  @override
  String get compareViewLabel => 'Manzara';

  @override
  String get installmentCalculatorTitle => 'Muddatli toʻlov kalkulyatori';

  @override
  String downPaymentLabel(int percent, String amount) {
    return 'Boshlangʻich toʻlov: $percent% ($amount)';
  }

  @override
  String termMonthsLabel(int months) {
    return 'Muddat: $months oy';
  }

  @override
  String get monthlyPaymentLabel => 'Oylik toʻlov';

  @override
  String get calculateInstallmentAction => 'Hisoblash';

  @override
  String get rentalRentLabel => 'Oylik ijara';

  @override
  String get ownerListingsSectionTitle => 'Yaqin atrofdagi egalar e\'lonlari';

  @override
  String get secondaryTag => 'Ikkilamchi';

  @override
  String get perMonthSuffix => '/oy';

  @override
  String get forBusinessTitle => 'Ko\'chmas mulk yoki biznesga egamisiz?';

  @override
  String get forBusinessSubtitle =>
      'Sotish va ijara obyektlarini joylashtiring, murojaatlar va tahlillarni iBuild for Business orqali boshqaring.';

  @override
  String get forBusinessAction => 'iBuild for Business\'ni ochish';

  @override
  String get mortgageCalculatorAction => 'Ipoteka kalkulyatori';

  @override
  String get mortgageCalculatorTitle => 'Bank ipoteka kalkulyatori';

  @override
  String get mortgagePropertyPriceLabel => 'Uy-joy narxi';

  @override
  String get toolsSectionTitle => 'Vositalar';

  @override
  String interestRateLabel(String percent) {
    return 'Bank stavkasi: yiliga $percent%';
  }

  @override
  String termYearsLabel(int years) {
    return 'Muddat: $years yil';
  }

  @override
  String get totalInterestLabel => 'Jami foiz';

  @override
  String get totalPaymentLabel => 'Jami toʻlov';

  @override
  String get downPaymentAmountLabel => 'Boshlangʻich toʻlov';

  @override
  String get bankReferralConsentLabel =>
      'iBuild bank hamkori ushbu ipoteka boʻyicha men bilan bogʻlanishiga roziman';

  @override
  String get requestBankConsultationAction => 'Bank konsultatsiyasini soʻrash';

  @override
  String get bankReferralSubmittedSnackbar =>
      'Bank hamkori tez orada siz bilan bogʻlanadi';

  @override
  String get rentalYieldCalculatorAction => 'Ijara daromadi kalkulyatori';

  @override
  String get rentalYieldCalculatorTitle => 'Ijara daromadi kalkulyatori';

  @override
  String get grossYieldLabel => 'Yalpi daromad';

  @override
  String get paybackYearsLabel => 'Qaytarilish muddati';

  @override
  String paybackYearsValue(String years) {
    return '$years yil';
  }

  @override
  String get annualRentLabel => 'Yillik ijara';

  @override
  String get calculatingLabel => 'Hisoblanmoqda...';

  @override
  String get quizTitle => 'Mos variantni topamiz';

  @override
  String get quizIntroTitle => 'Qidiruvni moslashtiramiz';

  @override
  String get quizIntroBody =>
      '4 ta tezkor savolga javob bering — biz tasmangizni sozlaymiz va qurilmangizda AI ko‘rinishini shakllantiramiz, faqat siz uchun.';

  @override
  String get quizStartAction => 'Viktorinani boshlash';

  @override
  String quizStepCounter(int current, int total) {
    return '$total dan $current';
  }

  @override
  String get quizSavedSnackbar => 'Afzalliklar saqlandi';

  @override
  String get quizGoalQuestion => 'Keyingi uyingizda eng muhimi nima?';

  @override
  String get quizGoalBudget => 'Qulay narx';

  @override
  String get quizGoalFamily => 'Oila uchun keng joy';

  @override
  String get quizGoalInvestment => 'Aqlli investitsiya';

  @override
  String get quizGoalLuxury => 'Premium hayot';

  @override
  String get quizLocationQuestion => 'O‘zingizni qayerda tasavvur qilasiz?';

  @override
  String get quizLocationCityCenter => 'Shahar markazida';

  @override
  String get quizLocationQuietSuburb => 'Tinch, ko‘kalamzor hudud';

  @override
  String get quizLocationBusinessDistrict => 'Biznes markazga yaqin';

  @override
  String get quizLocationUpAndComing => 'Rivojlanayotgan hudud';

  @override
  String get quizTimelineQuestion => 'Qachon ko‘chib o‘tmoqchisiz?';

  @override
  String get quizTimelineReadyNow => 'Imkon qadar tezroq';

  @override
  String get quizTimelineOffplanOk => 'Yangi qurilishni kutishga tayyorman';

  @override
  String get quizTimelineFlexible => 'Muddat moslashuvchan';

  @override
  String get quizPriorityQuestion => 'Asosiy ustuvorlikni tanlang';

  @override
  String get quizPriorityPrice => 'Narx';

  @override
  String get quizPrioritySpace => 'Keng joy va tartib';

  @override
  String get quizPriorityAmenities => 'Qulayliklar';

  @override
  String get quizPriorityLocation => 'Joylashuv';

  @override
  String get quizResultEyebrow => 'Sizning xaridor profilingiz';

  @override
  String get quizPersonaFirstTimeBuyer => 'Birinchi xarid';

  @override
  String get quizPersonaFamilyNester => 'Oilaviy uy';

  @override
  String get quizPersonaInvestor => 'Zukko investor';

  @override
  String get quizPersonaLuxurySeeker => 'Premium ixlosmandi';

  @override
  String get quizPersonaFirstTimeBuyerDesc =>
      'Sizga byudjetingizga mos eng yaxshi uy kerak. Biz qulay narxli variantlar va moslashuvchan bo‘lib to‘lashni ko‘rsatamiz.';

  @override
  String get quizPersonaFamilyNesterDesc =>
      'Keng joy va qulaylik birinchi o‘rinda. Biz tinch, qulayliklari bor hududlardagi katta tartiblarni ajratib ko‘rsatamiz.';

  @override
  String get quizPersonaInvestorDesc =>
      'Siz daromadga qiziqasiz. Biz yuqori daromadli variantlar va istiqbolli yangi qurilishlarni ta’kidlaymiz.';

  @override
  String get quizPersonaLuxurySeekerDesc =>
      'Faqat eng a’losi. Biz alohida qulayliklar va joylashuvga ega premium turar joylarni tanlaymiz.';

  @override
  String get quizPreviewTitle => 'Sizning AI ko‘rinishingiz';

  @override
  String get quizPreviewPromptLabel => 'So‘rov (lokal mok)';

  @override
  String quizPreviewBody(String persona) {
    return '$persona sifatida siz eng mos uylarni birinchi bo‘lib ko‘rasiz. Biz siz uchun muhim bo‘lgan narsalarni ustuvor qilamiz va yangi e’lonlar bilan yangilab boramiz. Bu ko‘rinish lokal tarzda yaratiladi — ma’lumotlar qurilmangizdan chiqmaydi.';
  }

  @override
  String get quizDoneAction => 'Variantlarimni ko‘rish';

  @override
  String get quizRetakeAction => 'Qayta o‘tish';

  @override
  String get quizEntryAction => 'Viktorinadan o‘tish';
}
