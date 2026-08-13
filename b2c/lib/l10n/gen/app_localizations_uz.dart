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
  String get onboardingEyebrow =>
      'Quruvchidan xavfsiz xarid qiling. Bir ilovada.';

  @override
  String get onboardingDescription =>
      'Tekshirilgan yangi qurilishlarni solishtiring, real mavjudlikni koʻring va soʻrovni toʻgʻridan-toʻgʻri quruvchiga yuboring — vositachisiz, taxminsiz.';

  @override
  String get start => 'Boshlash';

  @override
  String get startDemo => 'Boshlash (demo)';

  @override
  String get signIn => 'Kirish';

  @override
  String get signInDemo => 'Kirish (demo)';

  @override
  String get demoButton => 'Demo';

  @override
  String get demoModeTitle => 'Demo rejim';

  @override
  String get demoModeMessage =>
      'Siz iBuild ilovasini faqat ko‘rish rejimida sinab ko‘ryapsiz. Barcha ekran va funksiyalarni oching — hech narsa ma’lumotlar bazasiga saqlanmaydi.';

  @override
  String get demoModeGotIt => 'Tushundim';

  @override
  String get demoModeBanner => 'Demo rejim — o‘zgarishlar saqlanmaydi';

  @override
  String get demoWriteBlocked =>
      'Demo rejim faqat ko‘rish uchun — amal saqlanmadi.';

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
  String get otpDevHint => 'Test rejimi';

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
  String get actualProgressLabel => 'Haqiqiy qurilish jarayoni';

  @override
  String get plannedProgressLabel => 'Rejadagi qurilish jarayoni';

  @override
  String get progressOnSchedule => 'Jadvalga mos';

  @override
  String get progressAheadOfSchedule => 'Jadvaldan oldinda';

  @override
  String get progressAcceptableDeviation => 'Ruxsat etilgan chetlanish';

  @override
  String get progressBehindSchedule => 'Jadvaldan orqada';

  @override
  String progressDeviation(int percent) {
    return 'Farq $percent%';
  }

  @override
  String trustIndexLabel(int percent) {
    return 'Ishonch indeksi $percent%';
  }

  @override
  String get progressComparisonNote =>
      '15% gacha farq qurilishda odatiy holat: ob-havo, mavsumiy cheklovlar va yetkazib berish kechikishlari. 15% dan ortiq boʻlsa, platforma obyektni tekshiruvga yuboradi.';

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
  String get inquiriesSignInRequiredTitle =>
      'Murojaatlarni koʻrish uchun tizimga kiring';

  @override
  String get inquiriesSignInRequiredBody =>
      'Qayta qoʻngʻiroq va koʻrik soʻrovlarini koʻrish uchun iBuild hisobingizga kiring.';

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
  String get lightModeLabel => 'Yorugʻ rejim';

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
  String get filtersApplied => 'Filtrlar qo\'llanildi';

  @override
  String get filterDistrictsHint => 'Bir yoki bir nechta tuman tanlang';

  @override
  String districtsSelectedCount(int count) {
    return 'Tanlangan tumanlar: $count';
  }

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
  String get notifLeadStatusTitle => 'Murojaat holati yangilandi';

  @override
  String notifLeadStatusBody(String status) {
    return 'Murojaatingiz endi: «$status».';
  }

  @override
  String get notifNewOfferTitle => 'Yangi taklif';

  @override
  String get notifNewOfferBody =>
      'Kuzatayotgan loyihangizga yangi taklif qoʻshildi.';

  @override
  String get notifLeadCreatedTitle => 'Murojaat qabul qilindi';

  @override
  String get notifLeadCreatedBody =>
      'Murojaatingizni oldik — tez orada bogʻlanamiz.';

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

  @override
  String get leadSubjectLabel => 'Bu nima haqida?';

  @override
  String get leadSubjectProject => 'Loyiha haqida';

  @override
  String get leadSubjectUnit => 'Aniq xonadon haqida';

  @override
  String get leadSubjectRent => 'Ijara haqida';

  @override
  String get leadSubjectOffice => 'Ofis haqida';

  @override
  String get leadSubjectMortgage => 'Ipoteka konsultatsiyasi';

  @override
  String get leadSubjectOther => 'Boshqa';

  @override
  String get aiFabTooltip => 'iBuild AI\'dan so‘rash';

  @override
  String get aiChatTitle => 'iBuild AI';

  @override
  String get aiChatInfoTooltip => 'iBuild AI haqida';

  @override
  String get aiChatInfoBody =>
      'Katalog, aniq majmua yoki xonadon, muddatli to‘lov va ipoteka haqida so‘rang — iBuild AI iBuild\'ning o‘z ma\'lumotlari va shartlariga asoslanib javob beradi.';

  @override
  String get aiChatErrorSnackbar => 'Javob olinmadi. Qaytadan urinib ko‘ring.';

  @override
  String get aiChatQuotaExhaustedTitle => 'Kunlik limit tugadi';

  @override
  String get aiChatQuotaExhaustedBody =>
      'Bugungi iBuild AI xabarlar limitidan foydalandingiz. Ertaga qayting.';

  @override
  String get aiChatUnavailableTitle => 'iBuild AI vaqtincha ishlamayapti';

  @override
  String get aiChatUnavailableBody =>
      'Yordamchi vaqtincha mavjud emas. Birozdan keyin qaytadan urinib ko‘ring.';

  @override
  String get aiChatEmptyTitle => 'iBuild AI\'dan istagan narsani so‘rang';

  @override
  String get aiChatEmptyBody =>
      'Masalan: «Chilonzorda qaysi majmualarda muddatli to‘lov bor?» yoki «\$60 000 xonadon uchun qanday ipoteka stavkasi maqbul?»';

  @override
  String get aiChatInputHint => 'iBuild AI\'ga yozing...';

  @override
  String get aiChatSendTooltip => 'Yuborish';

  @override
  String get aiBetaNoticeTitle => 'iBuild AI sinov rejimida';

  @override
  String get aiBetaNoticeBody =>
      'Javoblar ba\'zan noaniq bo‘lishi mumkin — narx va mavjudlik kabi tafsilotlarni har doim e\'lonning o‘zidan tekshiring.';

  @override
  String get aiQuotaTitle => 'Kunlik limit';

  @override
  String aiQuotaUsedLabel(int used, int limit) {
    return 'Bugun $limit tadan $used xabar ishlatildi';
  }

  @override
  String aiQuotaResetLabel(String time) {
    return 'Yangilanadi: $time';
  }

  @override
  String get aiSearchInfoExamplesTitle => 'Shunday so‘rab ko‘ring';

  @override
  String get aiSearchInfoTitle => 'AI aqlli qidiruv';

  @override
  String get aiSearchInfoBody =>
      'Nima izlayotganingizni oddiy so‘zlar bilan tasvirlang — xonalar, byudjet, tuman, sizga muhim bo‘lgan har narsa — iBuild AI buni katalogdagi jonli qidiruvga aylantiradi.';

  @override
  String get aiSearchExample1 => 'Chilonzorda \$60 000 gacha 2 xonali';

  @override
  String get aiSearchExample2 =>
      'Biznes markazga yaqin 3 xonali ofis, hozir tayyor';

  @override
  String get aiSearchExample3 =>
      'Ijaraga xonadon, birinchi qavat emas, parking bilan';

  @override
  String get aiSearchHint => 'Nima izlayotganingizni yozing...';

  @override
  String get aiSearchClearTooltip => 'Qidiruvni tozalash';

  @override
  String get aiSearchSubmitTooltip => 'Qidirish';

  @override
  String get aiSearchInfoTooltip => 'AI qidiruv haqida';

  @override
  String get aiSearchRateLimitedTitle => 'Kunlik qidiruv limiti tugadi';

  @override
  String aiSearchRateLimitedBody(String time) {
    return 'Bugungi AI qidiruv limitidan foydalandingiz. $time qaytib keling.';
  }

  @override
  String get aiSearchUnavailableTitle => 'AI qidiruv vaqtincha ishlamayapti';

  @override
  String get aiSearchUnavailableBody =>
      'Aqlli qidiruv vaqtincha mavjud emas. Birozdan keyin qaytadan urinib ko‘ring.';

  @override
  String get aiSearchGenericErrorTitle => 'Qidiruvni amalga oshirib bo‘lmadi';

  @override
  String get aiSearchGenericErrorBody =>
      'Nimadir xato ketdi. Birozdan keyin qaytadan urinib ko‘ring.';

  @override
  String aiSearchUnrecognizedNote(String terms) {
    return 'Aniqlanmadi: $terms';
  }

  @override
  String aiSearchSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mos variant',
      one: '1 mos variant',
      zero: 'Mos kelmadi',
    );
    return '$_temp0';
  }

  @override
  String get aiSearchResultsEmptyTitle => 'Hozircha mos variant yo‘q';

  @override
  String get aiSearchResultsEmptyBody =>
      'Shartlardan birini yumshating — byudjetni kengaytiring yoki qo‘shni tumanni ko‘rib chiqing.';

  @override
  String aiSearchMatchScoreLabel(int score) {
    return '$score% mos';
  }

  @override
  String get aiSearchStatusStarting => 'Qidiruv boshlanmoqda...';

  @override
  String get aiSearchTabHintTooltip => 'Tab — taklifni qabul qilish';

  @override
  String get aiSearchTabAcceptLabel => 'AI taklifini qabul qilish';

  @override
  String get aiSearchClarifyTitle => 'So‘rovni tushunolmadim';

  @override
  String aiSearchClarifyBody(String terms) {
    return 'Bu so‘zlar katalogda yo‘q: $terms. So‘rovni aniqlashtiring yoki quyidagi takliflardan birini tanlang.';
  }

  @override
  String get aiSearchClarifyExamplesHint =>
      'Yoki quyidagi misollardan birini sinab ko‘ring:';

  @override
  String aiSearchDidYouMean(String suggestion) {
    return '«$suggestion» demoqchimidingiz?';
  }

  @override
  String aiSearchQuotedTerm(String term) {
    return '«$term»';
  }

  @override
  String aiSearchRelaxConstraint(String constraint) {
    return 'Shartni olib tashlash: $constraint';
  }

  @override
  String aiStepParsingV1(int count) {
    return 'So‘rovingiz o‘qilmoqda...';
  }

  @override
  String aiStepParsingV2(int count) {
    return 'Nima kerakligini aniqlayapman...';
  }

  @override
  String aiStepParsingV3(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count talab',
      one: '1 talab',
    );
    return '$_temp0 tahlil qilinmoqda...';
  }

  @override
  String aiStepParsingV4(int count) {
    return 'So‘rovingiz bo‘laklarga ajratilmoqda...';
  }

  @override
  String aiStepScanningDistrictV1(String district, int count) {
    return '$district tumani ko‘rib chiqilmoqda...';
  }

  @override
  String aiStepScanningDistrictV2(String district, int count) {
    return '$district\'dagi $count loyiha ko‘rib chiqilmoqda...';
  }

  @override
  String aiStepScanningDistrictV3(String district, int count) {
    return '$district tumanidagi mavjudlik tekshirilmoqda...';
  }

  @override
  String aiStepScanningDistrictV4(String district, int count) {
    return '$district tumani ($count loyiha) o‘rganilmoqda...';
  }

  @override
  String aiStepFoundInDistrictV1(String district, int count) {
    return '$district tumanida $count ta topildi';
  }

  @override
  String aiStepFoundInDistrictV2(String district, int count) {
    return '$district\'da $count ta nomzod topildi';
  }

  @override
  String aiStepFoundInDistrictV3(String district, int count) {
    return '$district: $count ta e\'tiborga loyiq';
  }

  @override
  String aiStepFoundInDistrictV4(String district, int count) {
    return '$district tumanida $count ta tanlandi';
  }

  @override
  String aiStepOpeningProjectV1(String project, int index, int total) {
    return '$project ochilmoqda ($index/$total)...';
  }

  @override
  String aiStepOpeningProjectV2(String project, int index, int total) {
    return '$project ichi ko‘rilmoqda...';
  }

  @override
  String aiStepOpeningProjectV3(String project, int index, int total) {
    return '$project tekshirilmoqda ($index/$total)...';
  }

  @override
  String aiStepOpeningProjectV4(String project, int index, int total) {
    return 'Hozir $project ko‘rilmoqda...';
  }

  @override
  String aiStepScanningUnitsV1(String project, int count) {
    return '$project\'dagi xonadonlar skanerlanmoqda ($count)...';
  }

  @override
  String aiStepScanningUnitsV2(String project, int count) {
    return '$project\'dagi $count ta xonadon tekshirilmoqda...';
  }

  @override
  String aiStepScanningUnitsV3(String project, int count) {
    return '$project tartiblari ko‘rib chiqilmoqda...';
  }

  @override
  String aiStepScanningUnitsV4(String project, int count) {
    return '$project: $count ta xonadon ko‘rilmoqda...';
  }

  @override
  String aiStepFilteringBookedV1(int removed, int left) {
    return '$removed ta band chiqarib tashlanmoqda, $left ta qoldi...';
  }

  @override
  String aiStepFilteringBookedV2(int removed, int left) {
    return 'Sotilgan va band qilinganlar chiqarilmoqda ($left ta qoldi)...';
  }

  @override
  String aiStepFilteringBookedV3(int removed, int left) {
    return '$removed ta band bo‘lgani o‘tkazib yuborilmoqda...';
  }

  @override
  String aiStepFilteringBookedV4(int removed, int left) {
    return 'Faqat mavjud xonadonlar qoldirilmoqda ($left)...';
  }

  @override
  String aiStepRankingPriceV1(int count) {
    return '$count ta eng mosligiga ko‘ra tartiblanmoqda...';
  }

  @override
  String aiStepRankingPriceV2(int count) {
    return 'Narx va moslikka ko‘ra saralanmoqda...';
  }

  @override
  String aiStepRankingPriceV3(int count) {
    return '$count ta variant solishtirilmoqda...';
  }

  @override
  String aiStepRankingPriceV4(int count) {
    return 'Eng yaxshi $count ta variant tanlanmoqda...';
  }

  @override
  String aiStepDoneV1(int count, int elapsedMs) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mos variant',
      one: '1 mos variant',
      zero: 'mos variant yo‘q',
    );
    return 'Tayyor · $_temp0, $elapsedMs ms ichida';
  }

  @override
  String aiStepDoneV2(int count, int elapsedMs) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mos variant topildi',
      one: '1 mos variant topildi',
      zero: 'hech narsa mos kelmadi',
    );
    return 'Tayyor — $_temp0';
  }

  @override
  String aiStepDoneV3(int count, int elapsedMs) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count natija',
      one: '1 natija',
      zero: '0 natija',
    );
    return 'Qidiruv tugadi ($_temp0)';
  }

  @override
  String aiStepDoneV4(int count, int elapsedMs) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kuchli mos variant',
      one: '1 kuchli mos variant',
      zero: 'bu safar mos variant yo‘q',
    );
    return 'Tayyor — $_temp0';
  }

  @override
  String aiStepNoMatchIntent(String terms) {
    return 'Katalogda $terms ga o‘xshash narsa yo‘q — qidiruv shu yerda to‘xtadi';
  }

  @override
  String aiStepLowConfidence(String terms, int count) {
    return '$terms ni to‘liq tushunmadim — kengroq mos variantlar ko‘rsatilmoqda ($count)';
  }

  @override
  String aiStepAutocorrected(String from, String to) {
    return '«$from» ni «$to» deb o‘qidim';
  }

  @override
  String aiStepSoftenedAmenity(String amenity) {
    return 'Variantlar topish uchun «$amenity» sharti yumshatildi';
  }

  @override
  String get aiReasonDistrictMatch => 'Kerakli tuman';

  @override
  String get aiReasonRoomsMatch => 'Xonalar soni mos';

  @override
  String get aiReasonPriceFit => 'Byudjetga mos';

  @override
  String get aiReasonPriceBelowBudget => 'Byudjetdan past';

  @override
  String get aiReasonAreaFit => 'Maydon mos';

  @override
  String get aiReasonFloorPreference => 'Qavat afzalligi';

  @override
  String get aiReasonDealTypeMatch => 'Sotish/ijara mos';

  @override
  String get aiReasonKindMatch => 'Xonadon turi mos';

  @override
  String get aiReasonAvailableNow => 'Hozir mavjud';

  @override
  String get aiReasonAmenityMatch => 'So‘ralgan qulayliklar bor';

  @override
  String get aiReasonDeveloperMatch => 'So‘ralgan quruvchi';

  @override
  String get aiReasonProjectMatch => 'So‘ralgan loyiha';

  @override
  String get aiReasonHighTrustIndex => 'Yuqori ishonch indeksi';

  @override
  String get aiReasonReadySoon => 'Tez orada tayyor';

  @override
  String get aiReasonOffplanDiscount => 'Qurilish bosqichi chegirmasi';

  @override
  String aiChipAreaRange(int min, int max) {
    return '$min–$max m²';
  }

  @override
  String aiChipAreaUpTo(int max) {
    return '$max m² gacha';
  }

  @override
  String aiChipAreaFrom(int min) {
    return '$min m² dan';
  }

  @override
  String get aiDealTypeRent => 'Ijaraga';

  @override
  String get aiDealTypeSale => 'Sotishga';

  @override
  String get aiUnitKindApartment => 'Kvartira';

  @override
  String get aiUnitKindCommercial => 'Tijorat maydoni';

  @override
  String get aiUnitKindParking => 'Parking';

  @override
  String aiChipFloorRange(int min, int max) {
    return '$min–$max qavat';
  }

  @override
  String aiChipFloorFrom(int min) {
    return '$min+ qavat';
  }

  @override
  String aiChipFloorUpTo(int max) {
    return '$max qavatgacha';
  }

  @override
  String get aiChipNotFirstFloor => 'Birinchi qavat emas';

  @override
  String get aiChipNotLastFloor => 'Oxirgi qavat emas';

  @override
  String get aiChipAvailableOnly => 'Faqat mavjudlar';

  @override
  String aiSearchShowAll(int count) {
    return 'Barcha $count natijani ko‘rish';
  }

  @override
  String get aiSearchAllResultsTitle => 'Barcha natijalar';

  @override
  String aiConstraintWithout(String amenity) {
    return '${amenity}siz';
  }
}
