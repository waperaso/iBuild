// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Uzbek (`uz`).
class AppLocalizationsUz extends AppLocalizations {
  AppLocalizationsUz([String locale = 'uz']) : super(locale);

  @override
  String get languageLabel => 'Til';

  @override
  String get commonCancel => 'Bekor qilish';

  @override
  String get commonSave => 'Saqlash';

  @override
  String get commonAdd => 'Qoʻshish';

  @override
  String get commonClose => 'Yopish';

  @override
  String get commonSignOut => 'Chiqish';

  @override
  String get commonExit => 'Chiqish';

  @override
  String get logoutConfirmTitle => 'Chiqmoqchimisiz?';

  @override
  String get logoutConfirmMessage =>
      'Davom etish uchun qayta kirishingiz kerak bo\'ladi.';

  @override
  String get loginTitle => 'Administrator kirishi';

  @override
  String get loginSubtitle => 'Platforma va TJ boshqaruvi';

  @override
  String get loginPhoneHint => 'Telefon raqami';

  @override
  String get loginSendCode => 'Kod yuborish';

  @override
  String get loginSendCodeError =>
      'Kodni yuborib boʻlmadi. Qayta urinib koʻring.';

  @override
  String get otpTitle => 'Kodni kiriting';

  @override
  String otpSentTo(String phone) {
    return '$phone raqamiga yuborildi';
  }

  @override
  String get otpHint => '000000';

  @override
  String get otpDevHelper => 'Test rejimi';

  @override
  String get otpVerify => 'Tasdiqlash';

  @override
  String get otpInvalidError => 'Kod xato yoki muddati oʻtgan';

  @override
  String get otpResendPrompt => 'Kod kelmadimi?';

  @override
  String get otpResendAction => 'Kodni qayta yuborish';

  @override
  String otpResendCountdown(int seconds) {
    return '$seconds soniyadan keyin qayta yuborish';
  }

  @override
  String get otpResendSuccess => 'Yangi kod yuborildi';

  @override
  String otpResendError(String error) {
    return 'Kodni qayta yuborib bo\'lmadi: $error';
  }

  @override
  String get applyStepWelcome => 'Xush kelibsiz';

  @override
  String get applyStepRole => 'Sizning rolingiz';

  @override
  String get applyStepDetails => 'Kompaniya maʼlumotlari';

  @override
  String get applyOnboardingTitle => 'ЖКga kirishni sozlash';

  @override
  String get applyOnboardingSubtitle =>
      'Jamoangiz majmualar, yunitlar va murojaatlarni boshqarishi uchun qisqa sozlash. Platforma tekshiruvi odatda bir ish kuni davom etadi.';

  @override
  String get applyOnboardingPointWorkspace =>
      'Har bir kompaniya uchun ЖКlar bo\'yicha bitta ish maydoni';

  @override
  String get applyOnboardingPointAccess =>
      'Kirish tezkor platforma tekshiruvidan soʻng ochiladi';

  @override
  String get applyGetStarted => 'Boshlash';

  @override
  String get applyHaveAccount => 'Mening hisobim bor';

  @override
  String get authHeroTitle => 'Quruvchilar uchun platforma';

  @override
  String get authHeroSubtitle =>
      'Turar-joy majmualarini, xonadonlarni va xaridor arizalarini yagona iBuild ish maydonida boshqaring — nafaqat administratorlar, balki butun jamoa uchun.';

  @override
  String get authHeroPointVerified =>
      'Tekshirilgan quruvchilar va loyihalar xaridorlar ishonchini qozonadi';

  @override
  String get authHeroPointLeads =>
      'Xaridor va ijarachi arizalari to\'g\'ridan-to\'g\'ri CRM\'ga tushadi';

  @override
  String get applyRoleTitle => 'Quruvchini roʻyxatdan oʻtkazish';

  @override
  String get applyRoleSubtitle =>
      'Turar-joy majmualaringizni eʼlon qiling, yunitlar va xaridor murojaatlarini boshqaring. Agar oʻz loyihalaringizni oʻzingiz qursangiz, quyidagi belgini qo\'ying.';

  @override
  String get applyContinue => 'Davom etish';

  @override
  String get applyKindDeveloperLabel => 'Quruvchi-tashkilot';

  @override
  String get applyKindDeveloperSubtitle =>
      'Siz oʻz turar-joy majmualaringizni quryapsiz va sotasiz — loyihalarni eʼlon qiling, yunitlar va xaridor murojaatlarini boshqaring.';

  @override
  String get applyKindConstructionLabel => 'Qurilish kompaniyasi';

  @override
  String get applyKindConstructionSubtitle =>
      'Siz boshqa quruvchilar uchun quryapsiz (pudratchi) — obyektdagi ishlar, ombor va ЖКga kirishni muvofiqlashtiring.';

  @override
  String get applyAlsoContractorLabel => 'Men loyihalarni oʻzim ham quraman';

  @override
  String get applyAlsoContractorSubtitle =>
      'Agar siz oʻz obyektlaringizda pudratchi vazifasini ham bajaradigan quruvchi boʻlsangiz, buni belgilang — qurilish litsenziyasi raqami kerak boʻladi.';

  @override
  String get applyDetailsTitle => 'Yuridik shaxs maʼlumotlari';

  @override
  String applyDetailsSubtitle(String kind) {
    return 'O\'zbekiston roʻyxatga olish maʼlumotlari (STIR/INN, direktor PINFL, UBO). $kind sifatida platforma tekshiruvi uchun talab qilinadi.';
  }

  @override
  String get applyBrandName => 'Brend / tijorat nomi *';

  @override
  String get applyLegalName => 'Toʻliq yuridik nomi *';

  @override
  String get applyInn => 'INN / STIR (9 raqam) *';

  @override
  String get applyLegalForm => 'Tashkiliy-huquqiy shakli (MChJ / YaTT / АJ) *';

  @override
  String get applyRegistrationNumber => 'Davlat roʻyxatga olish raqami';

  @override
  String get applyLegalAddress => 'Yuridik manzil *';

  @override
  String get applyOfficeAddress => 'Ofis / savdo ofisi manzili';

  @override
  String get applyRegion => 'Hudud';

  @override
  String get applyRegionTashkent => 'Toshkent';

  @override
  String get applyRegionNewTashkent => 'Yangi Toshkent';

  @override
  String get applyEmail => 'Kompaniya emaili';

  @override
  String get applyDirectorSectionTitle => 'Direktor (rahbar)';

  @override
  String get applyDirectorFullName => 'Direktorning toʻliq ismi *';

  @override
  String get applyDirectorPinfl => 'Direktor PINFL (14 raqam) *';

  @override
  String get applyDirectorPassport => 'Pasport seriyasi va raqami';

  @override
  String get applyDirectorPhone => 'Direktor telefoni';

  @override
  String get applyUboName => 'Yakuniy foydali egasi (agar farq qilsa)';

  @override
  String get applyLicense => 'Qurilish litsenziyasi raqami';

  @override
  String get applyUboConfirm =>
      'Yakuniy foydali egasi (UBO) maʼlumotlari toʻgʻriligini tasdiqlayman (AML / OʻZ roʻyxatga olish qoidalari). *';

  @override
  String get applyUboHelper =>
      'Yakuniy foydali egasi (UBO) — kompaniyaga pirovardida egalik qiluvchi yoki uni nazorat qiluvchi jismoniy shaxs (odatda 25% va undan koʻp ulush). OʻZ AML qoidalari buni eʼlon qilishni talab qiladi.';

  @override
  String get applySubmit => 'Qoralamani saqlash';

  @override
  String get applySaveDraft => 'Qoralamani saqlash';

  @override
  String get applySaveDraftSuccess =>
      'Qoralama saqlandi — ma\'lumotlarni tekshiring va tayyor bo\'lgach ko\'rib chiqish uchun yuboring.';

  @override
  String get applySubmitSuccess =>
      'Ariza yuborildi — platforma tasdiqlashini kutmoqda.';

  @override
  String get applyDraftTitle => 'Qoralama saqlandi';

  @override
  String get applyDraftSubtitle =>
      'Ma\'lumotlarni tekshiring va tayyor bo\'lgach arizani platformaga ko\'rib chiqish uchun yuboring.';

  @override
  String get applySubmitForReview => 'Ko\'rib chiqish uchun yuborish';

  @override
  String get applySubmitForReviewSuccess =>
      'Ariza yuborildi — platforma ko\'rib chiqishini kutmoqda.';

  @override
  String get applyDocumentsRequiredHint =>
      'Arizani ko\'rib chiqishga yuborishdan oldin yuqoridagi barcha 4 ta tasdiqlash hujjatini yuklang.';

  @override
  String applyDocumentsMissingHint(String names) {
    return 'Siz qo\'shmadingiz: $names. Arizani ko\'rib chiqishga yuborishdan oldin ularni yuqorida yuklang.';
  }

  @override
  String get applyReviewDecisionLabel => 'Qaror';

  @override
  String get applyPendingTitle => 'Ariza yuborildi';

  @override
  String get applyPendingSubtitle =>
      'Arizangizni koʻrib chiqamiz va qaror haqida shu yerda xabar beramiz. Odatda bu bir ish kunini oladi.';

  @override
  String get applyPendingRefresh => 'Holatni yangilash';

  @override
  String get applyRejectedTitle => 'Ariza rad etildi';

  @override
  String get applyRejectedReasonLabel => 'Rad etish sababi';

  @override
  String get applyRejectedResendAction => 'Tahrirlash va qayta yuborish';

  @override
  String get applyApprovedTitle => 'Ariza tasdiqlandi';

  @override
  String get applyApprovedSubtitle => 'Ish maydoningizga oʻtilmoqda…';

  @override
  String applyRequestFailed(String code) {
    return 'Soʻrov bajarilmadi ($code). Qayta urinib koʻring.';
  }

  @override
  String get applyNetworkError =>
      'Serverga ulanib boʻlmadi. Ulanishni tekshiring.';

  @override
  String get navPlatform => 'Platforma';

  @override
  String get navResidence => 'ЖК';

  @override
  String get navOrganization => 'Tashkilot';

  @override
  String get navSettings => 'Sozlamalar';

  @override
  String get shellAdminFallback => 'Administrator';

  @override
  String get settingsTitle => 'Sozlamalar';

  @override
  String get settingsAppearance => 'Ko‘rinish';

  @override
  String get settingsLightMode => 'Yorug‘';

  @override
  String get settingsDarkShort => 'Tungi';

  @override
  String get settingsDarkMode => 'Tungi rejim';

  @override
  String get settingsPalette => 'Rang mavzusi';

  @override
  String get settingsAccount => 'Hisob';

  @override
  String get platformTitle => 'Platforma boshqaruvi';

  @override
  String get platformSubtitle => 'Platformani boshqaring.';

  @override
  String platformAnalyticsError(String error) {
    return 'Analitika xatosi: $error';
  }

  @override
  String get statUsers => 'Foydalanuvchilar';

  @override
  String get statProjects => 'Loyihalar';

  @override
  String get statPublished => 'Nashr etilgan';

  @override
  String get statLeads => 'Murojaatlar';

  @override
  String get statAppsPending => 'Kutilayotgan arizalar';

  @override
  String get statProjectsPending => 'Kutilayotgan loyihalar';

  @override
  String get statPaid => 'Toʻlangan';

  @override
  String get statUnpaid => 'Toʻlanmagan';

  @override
  String get platformBusinessesSectionTitle =>
      'Roʻyxatdan oʻtgan kompaniyalar · toʻlov';

  @override
  String get platformNoBusinesses =>
      'Hozircha roʻyxatdan oʻtgan kompaniyalar yoʻq';

  @override
  String platformBusinessesError(String error) {
    return 'Kompaniyalar xatosi: $error';
  }

  @override
  String get platformPendingAppsSectionTitle => 'Kutilayotgan arizalar';

  @override
  String get platformNoPendingApps => 'Kutilayotgan arizalar yoʻq';

  @override
  String get platformViewKyc => 'KYC koʻrish';

  @override
  String get platformApprove => 'Tasdiqlash';

  @override
  String get platformReject => 'Rad etish';

  @override
  String get platformRejectReasonDefault => 'Talablarga javob bermaydi';

  @override
  String get devStatusPending => 'Koʻrib chiqilishini kutmoqda';

  @override
  String get devStatusDraft => 'Qoralama';

  @override
  String get devStatusInReview => 'Koʻrib chiqilmoqda';

  @override
  String get devStatusApproved => 'Tasdiqlandi';

  @override
  String get devStatusRejected => 'Rad etildi';

  @override
  String get platformChangeStatusTooltip => 'Holatni oʻzgartirish';

  @override
  String get platformStatusMenuAccept => 'Tasdiqlash';

  @override
  String get platformStatusMenuDecline => 'Rad etish…';

  @override
  String get platformStatusUpdated => 'Ariza holati yangilandi';

  @override
  String get platformDeclineDialogTitle => 'Arizani rad etish';

  @override
  String get platformDeclineReasonLabel => 'Sabab';

  @override
  String get platformDeclineReasonHint => 'Bu ariza nima uchun rad etilmoqda?';

  @override
  String get platformDeclineConfirm => 'Arizani rad etish';

  @override
  String get platformPendingProjectsSectionTitle => 'Moderatsiyadagi loyihalar';

  @override
  String get platformNoPendingProjects =>
      'Moderatsiya kutayotgan loyihalar yoʻq';

  @override
  String get platformPublish => 'Nashr etish';

  @override
  String get platformProjectDetails => 'Batafsil';

  @override
  String get platformProjectDescriptionLabel => 'Tavsif';

  @override
  String get platformProjectPricingLabel => 'Narxlar';

  @override
  String platformProjectPriceRange(String min, String max) {
    return '$min – $max soʻm';
  }

  @override
  String platformProjectRentRange(String min, String max) {
    return 'Ijara: $min – $max soʻm/oy';
  }

  @override
  String platformProjectCompletionLabel(String date) {
    return 'Topshirish muddati: $date';
  }

  @override
  String get platformProjectGalleryLabel => 'Galereya';

  @override
  String get platformProjectUnitsLabel => 'Yunitlar';

  @override
  String platformProjectUnitsSummary(int buildings, int total) {
    return '$buildings bino · $total yunit';
  }

  @override
  String get platformProjectUnitsEmpty => 'Hali yunitlar qoʻshilmagan';

  @override
  String platformProjectLoadError(String error) {
    return 'Loyiha maʼlumotlarini yuklab boʻlmadi: $error';
  }

  @override
  String get platformPublishedProjectsSectionTitle => 'Nashr etilgan loyihalar';

  @override
  String get platformNoPublishedProjects => 'Nashr etilgan loyihalar yoʻq';

  @override
  String get platformUnpublish => 'Nashrdan olib tashlash';

  @override
  String get platformWarn => 'Ogohlantirish';

  @override
  String platformWarnDialogTitle(String name) {
    return '«$name» uchun ogohlantirish';
  }

  @override
  String get platformWarnReasonHint => 'Quruvchi nima tuzatishi kerak?';

  @override
  String get platformUnpublishConfirm => 'Nashrdan olib tashlash';

  @override
  String get platformActionSuccess => 'Tayyor';

  @override
  String platformActionError(String error) {
    return 'Xato: $error';
  }

  @override
  String get platformPendingReviewsSectionTitle => 'Moderatsiyadagi sharhlar';

  @override
  String get platformNoPendingReviews => 'Moderatsiya kutayotgan sharhlar yoʻq';

  @override
  String get platformReviewRatingLocation => 'Joylashuv';

  @override
  String get platformReviewRatingQuality => 'Sifat';

  @override
  String get platformReviewRatingValue => 'Narx/sifat';

  @override
  String platformReviewProjectLabel(String name) {
    return 'Loyiha: $name';
  }

  @override
  String get platformAnonymous => 'Anonim';

  @override
  String get platformKeep => 'Saqlab qolish';

  @override
  String get platformRemove => 'Oʻchirish';

  @override
  String get platformPendingRentalsSectionTitle =>
      'Moderatsiyadagi ijara eʼlonlari';

  @override
  String get platformNoPendingRentals =>
      'Moderatsiya kutayotgan ijara eʼlonlari yoʻq';

  @override
  String get platformRentalRejectNoteDefault =>
      'Eʼlon talablariga javob bermaydi';

  @override
  String platformRentalMonthlyRent(String amount) {
    return '$amount soʻm/oy';
  }

  @override
  String platformRentalContactLabel(String phone) {
    return 'Aloqa: $phone';
  }

  @override
  String get platformAuditLogSectionTitle => 'Amallar jurnali';

  @override
  String get platformNoAuditEvents => 'Hozircha jurnalda voqealar yoʻq';

  @override
  String platformAuditError(String error) {
    return 'Jurnal xatosi: $error';
  }

  @override
  String get platformAuditLogActorPrefix => 'O\'zgartirdi';

  @override
  String get platformAuditLogActorUnknown => 'Nomaʼlum foydalanuvchi';

  @override
  String platformAuditLogPageInfo(int page, int total) {
    return '$page/$total sahifa';
  }

  @override
  String get platformAuditLogPrevPage => 'Oldingi sahifa';

  @override
  String get platformAuditLogNextPage => 'Keyingi sahifa';

  @override
  String get notificationsTitle => 'Bildirishnomalar';

  @override
  String get notificationsSubtitle =>
      'Loyihalardagi barcha oʻzgarishlar va yuborilgan hujjatlar.';

  @override
  String get notificationsMarkAllRead => 'Barchasini oʻqilgan deb belgilash';

  @override
  String get notificationsSectionTitle => 'Barcha bildirishnomalar';

  @override
  String notificationsUnreadSectionTitle(int count) {
    return '$count oʻqilmagan';
  }

  @override
  String notificationsError(String error) {
    return 'Bildirishnomalar xatosi: $error';
  }

  @override
  String get notificationsEmptyTitle => 'Hozircha bildirishnomalar yoʻq';

  @override
  String get notificationsEmptySubtitle =>
      'Yangi loyihalar, oʻzgarishlar va yuborilgan hujjatlar shu yerda paydo boʻladi.';

  @override
  String get notificationsCriticalBadge => 'Muhim';

  @override
  String get notificationsJustNow => 'Hozirgina';

  @override
  String notificationsMinutesAgo(int minutes) {
    return '$minutes daqiqa oldin';
  }

  @override
  String notificationsHoursAgo(int hours) {
    return '$hours soat oldin';
  }

  @override
  String notificationsDaysAgo(int days) {
    return '$days kun oldin';
  }

  @override
  String notifDeveloperSubmittedTitle(String name) {
    return 'Quruvchi arizasi: $name';
  }

  @override
  String notifDeveloperSubmittedBody(String name) {
    return '$name KYC arizasini tekshiruvga yubordi.';
  }

  @override
  String notifDocumentUploadedTitle(String documentType) {
    return 'Hujjat yuborildi: $documentType';
  }

  @override
  String notifDocumentUploadedBody(String name, String documentType) {
    return '$name «$documentType» hujjatini tekshiruvga yukladi.';
  }

  @override
  String notifProjectCreatedTitle(String name) {
    return 'Yangi loyiha: $name';
  }

  @override
  String notifProjectCreatedBody(String name) {
    return '$name yangi loyiha qoralamasini yaratdi.';
  }

  @override
  String get notifProjectCreatedBodyAnonymous =>
      'Yangi loyiha qoralamasi yaratildi.';

  @override
  String notifProjectSubmittedTitle(String name) {
    return 'Loyiha tekshiruvga: $name';
  }

  @override
  String notifProjectSubmittedBody(String name) {
    return '$name loyihani moderatsiyaga yubordi.';
  }

  @override
  String get notifProjectSubmittedBodyAnonymous =>
      'Loyiha moderatsiyaga yuborildi.';

  @override
  String notifProjectUpdatedTitle(String name) {
    return 'Loyiha yangilandi: $name';
  }

  @override
  String notifProjectUpdatedBody(String fields) {
    return 'Oʻzgargan maydonlar: $fields';
  }

  @override
  String notifProgressDeviationTitle(String name) {
    return 'Jadvaldan orqada: $name';
  }

  @override
  String notifProgressDeviationBody(int actual, int planned, int gap) {
    return 'Tasdiqlangan $actual% — vaʼda $planned%, farq $gap%. Obyektda tekshiruv kerak.';
  }

  @override
  String get platformUsersSectionTitle => 'Foydalanuvchilar va rollar';

  @override
  String get platformColPhone => 'Telefon';

  @override
  String get platformColRole => 'Rol';

  @override
  String get platformColStatus => 'Holat';

  @override
  String get platformColActions => 'Amallar';

  @override
  String platformBannedTooltip(String by, String reason) {
    return '$by tomonidan bloklangan: $reason';
  }

  @override
  String get platformBannedLabel => 'Bloklangan';

  @override
  String get platformSetRoleTooltip => 'Rolni belgilash';

  @override
  String get platformSetRoleLabel => 'Rolni belgilash';

  @override
  String get platformUnban => 'Blokdan chiqarish';

  @override
  String get platformBan => 'Bloklash';

  @override
  String get platformDeleteAdminTooltip =>
      'Platforma administratori hisobini o\'chirish';

  @override
  String platformDeleteAdminConfirmTitle(String phone) {
    return '$phone o\'chirilsinmi?';
  }

  @override
  String get platformDeleteAdminConfirmBody =>
      'Platforma administratori hisobi butunlay o\'chiriladi va barcha joylarda kirish huquqi bekor qilinadi. Bu amalni ortga qaytarib bo\'lmaydi.';

  @override
  String get platformDeleteAdminConfirm => 'Hisobni o\'chirish';

  @override
  String get platformDeleteAdminSelfHint =>
      'Bu sizning hisobingiz — uni o\'chirish uchun boshqa administrator sifatida tizimga kiring.';

  @override
  String platformBanDialogTitle(String phone) {
    return '${phone}ni bloklash';
  }

  @override
  String get platformBanDialogUserFallback => 'foydalanuvchi';

  @override
  String get platformBanDialogBody =>
      'Bu hisobni oʻz profili va tizimdan chiqishdan tashqari hamma joyda muzlatadi.';

  @override
  String get platformBanReasonLabel => 'Sabab';

  @override
  String get platformBanReasonHint => 'Bu hisob nima uchun bloklanmoqda?';

  @override
  String get platformBanByLabel => 'Kim bloklagan (ism)';

  @override
  String get platformBanByHint => 'Foydalanuvchiga oʻz hisobida koʻrsatiladi';

  @override
  String get platformBanConfirm => 'Hisobni bloklash';

  @override
  String get accountBannedTitle => 'Hisobingiz bloklangan';

  @override
  String get accountBannedBody =>
      'Hisob muzlatilgan. Platforma administratori bandan chiqarmaguncha faqat shu bildirishnoma va tizimdan chiqish mumkin.';

  @override
  String get accountBannedReasonLabel => 'Sabab';

  @override
  String accountBannedByLabel(String name) {
    return 'Bloklagan: $name';
  }

  @override
  String platformKycTitle(String name) {
    return 'KYC · $name';
  }

  @override
  String get kycCompanyName => 'Kompaniya nomi';

  @override
  String get kycLegalName => 'Yuridik nomi';

  @override
  String get kycAccountKind => 'Hisob turi';

  @override
  String get kycLegalForm => 'Tashkiliy-huquqiy shakli';

  @override
  String get kycInn => 'INN';

  @override
  String get kycRegistrationNumber => 'Roʻyxatga olish raqami';

  @override
  String get kycOkedCode => 'OKED kodi';

  @override
  String get kycLegalAddress => 'Yuridik manzil';

  @override
  String get kycOfficeAddress => 'Ofis manzili';

  @override
  String get kycRegion => 'Hudud';

  @override
  String get kycEmail => 'Email';

  @override
  String get kycWebsite => 'Veb-sayt';

  @override
  String get kycDirectorFullName => 'Direktorning toʻliq ismi';

  @override
  String get kycDirectorPinfl => 'Direktor PINFL';

  @override
  String get kycDirectorPassport => 'Direktor pasporti';

  @override
  String get kycDirectorPhone => 'Direktor telefoni';

  @override
  String get kycDirectorEmail => 'Direktor emaili';

  @override
  String get kycUboDeclared => 'UBO eʼlon qilingan';

  @override
  String get kycUboFullName => 'UBOning toʻliq ismi';

  @override
  String get kycUboHelper =>
      'Yakuniy foydali egasi — kompaniyaga pirovardida egalik qiluvchi yoki uni nazorat qiluvchi jismoniy shaxs (odatda ≥25%).';

  @override
  String get kycConstructionLicense => 'Qurilish litsenziyasi';

  @override
  String get platformKycDocumentsTitle => 'Hujjatlar';

  @override
  String get platformKycDocumentsEmpty => 'Hujjatlar hali yuklanmagan';

  @override
  String platformKycDocumentsError(String error) {
    return 'Hujjatlar xatosi: $error';
  }

  @override
  String get platformKycDocumentView => 'Ochish';

  @override
  String get platformKycDocumentAccept => 'Qabul qilish';

  @override
  String get platformKycDocumentReject => 'Rad etish';

  @override
  String get platformKycDocumentRejectDialogTitle => 'Hujjatni rad etish';

  @override
  String get platformKycDocumentRejectReasonHint =>
      'Hujjat nima uchun rad etilmoqda?';

  @override
  String get residenceNewProjectDialogTitle => 'Yangi loyiha';

  @override
  String get residenceNameHint => 'Nomi';

  @override
  String get residenceTypeHint => 'Mulk turi';

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
  String get residenceDistrictHint => 'Tuman';

  @override
  String get residenceDistrictOther => 'Boshqa (kiritish)';

  @override
  String get residenceDistrictOtherHint => 'Tuman nomi';

  @override
  String get residenceAddressHint => 'Manzil (koʻcha, uy)';

  @override
  String get mapLocationTapHint =>
      'Obekt joylashuvini belgilash uchun xaritani bosing';

  @override
  String get mapLocationManualHint => 'Yoki koordinatalarni qoʻlda kiriting';

  @override
  String get mapLocationLatitudeLabel => 'Kenglik';

  @override
  String get mapLocationLongitudeLabel => 'Uzunlik';

  @override
  String get mapLocationApplyCoordinates => 'Qoʻllash';

  @override
  String get mapLocationInvalidCoordinates =>
      'Toʻgʻri kenglik (-90 dan 90 gacha) va uzunlik (-180 dan 180 gacha) kiriting';

  @override
  String mapLocationCoordinates(String lat, String lng) {
    return 'Koordinatalar: $lat, $lng';
  }

  @override
  String get mapLocationZoomIn => 'Kattalashtirish';

  @override
  String get mapLocationZoomOut => 'Kichiklashtirish';

  @override
  String get residenceCreate => 'Yaratish';

  @override
  String get residenceCreatedSnackbar =>
      'Loyiha qoralama sifatida saqlandi — tayyor bo\'lgach moderatsiyaga yuboring';

  @override
  String residencePublishingLocked(String price) {
    return 'Obuna boʻlmaguningizcha nashr etish bloklangan (\$$price/oy). Tashkilot profilini sozlashda davom etishingiz mumkin.';
  }

  @override
  String get residenceTitle => 'ЖК boshqaruvi';

  @override
  String get residenceSubtitle =>
      'Fondni, yunit holatini, media URL va murojaatlar CRM\'ini boshqaring.';

  @override
  String get residenceNewProject => 'Yangi loyiha';

  @override
  String get residenceProjectsSectionTitle => 'Sizning loyihalaringiz';

  @override
  String get residenceNoProjects => 'Hozircha loyihalar yoʻq';

  @override
  String get residenceNoProjectsSubtitle =>
      'Bittasini yarating va platforma tasdiqlashini kuting.';

  @override
  String residenceLoadError(String error) {
    return 'Yuklash xatosi (tasdiqlangan quruvchi + residence_admin roli kerak): $error';
  }

  @override
  String residenceProjectMeta(
    String district,
    String moderation,
    String published,
  ) {
    return '$district · moderatsiya: $moderation · nashr etilgan: $published';
  }

  @override
  String get orgPlanUnlimited => 'cheksiz';

  @override
  String get orgPlanActive => 'Faol';

  @override
  String get orgPlanCurrentPlan => 'Joriy tarif';

  @override
  String get orgPlanSubscribe => 'Obuna boʻlish';

  @override
  String orgPlanSummary(
    String price,
    String maxProjects,
    String maxUnits,
    String leads,
    String payPerLead,
  ) {
    return '\$$price/oy · $maxProjects loyiha · $maxUnits yunit · $leads murojaat kiritilgan · \$$payPerLead/murojaat undan keyin';
  }

  @override
  String get orgTitle => 'Tashkilot profili';

  @override
  String get orgSubtitle =>
      'Kompaniyangiz va ЖКlaringiz qanday koʻrinishini sozlang. Xaridorlarga nashr etish uchun faol \$299/oy obuna talab qilinadi.';

  @override
  String get orgNoProfile => 'Hozircha tashkilot profili yoʻq.';

  @override
  String orgError(String error) {
    return 'Xato: $error';
  }

  @override
  String orgLegalLine(String legalName, String inn) {
    return '$legalName · INN $inn';
  }

  @override
  String orgPaymentLabel(String status) {
    return 'Toʻlov: $status';
  }

  @override
  String get orgPublishingUnlocked => ' · nashr etish ochilgan';

  @override
  String get orgPublishingLocked => ' · nashr etish bloklangan';

  @override
  String get orgSubscriptionPlansTitle => 'Obuna tariflari';

  @override
  String get orgSubscriptionPlansSubtitle =>
      'Nechta loyiha/yunit nashr etishingiz va limitdan tashqari toʻlovgacha nechta murojaat kiritilganiga qarab tarifni tanlang.';

  @override
  String orgPlansError(String error) {
    return 'Tariflar xatosi: $error';
  }

  @override
  String get orgDocumentsTitle => 'Tasdiqlash hujjatlari';

  @override
  String get orgDocumentsSubtitle =>
      '4 ta talab qilingan hujjatning barchasini yuklang va platforma jamoasi qabul qilishini kutib turing — shundan keyin xaridorlarga «Tasdiqlangan» belgisi koʻrinadi.';

  @override
  String orgDocumentsError(String error) {
    return 'Hujjatlar xatosi: $error';
  }

  @override
  String get orgDocumentNotUploaded => 'Yuklanmagan';

  @override
  String get orgDocumentUpload => 'Yuklash';

  @override
  String get orgDocumentReplace => 'Almashtirish';

  @override
  String orgDocumentUploading(int percent) {
    return 'Yuklanmoqda… $percent%';
  }

  @override
  String get orgDocumentUploaded =>
      'Hujjat yuklandi — platforma tekshiruvini kutmoqda.';

  @override
  String orgDocumentUploadError(String error) {
    return 'Yuklash xatosi: $error';
  }

  @override
  String orgDocumentRejectReason(String reason) {
    return 'Rad etilgan: $reason';
  }

  @override
  String get orgDocumentView => 'Ochish';

  @override
  String get orgDocumentConfirmTitle => 'Yuborishdan oldin tasdiqlang';

  @override
  String orgDocumentConfirmMessage(String type) {
    return 'Bu hujjatni ($type) diqqat bilan tekshiring — yuborilgandan soʻng platforma jamoasi uni koʻradi.';
  }

  @override
  String get orgDocumentConfirmSend => 'Tekshiruvga yuborish';

  @override
  String get orgDocumentOptionalSectionTitle => 'Ixtiyoriy hujjatlar';

  @override
  String get orgDocumentOptionalBadge => 'Ixtiyoriy';

  @override
  String get orgPublicPresenceTitle => 'Ommaviy profil';

  @override
  String get orgAboutHint => 'Tashkilotingiz / ЖКlaringiz haqida';

  @override
  String get orgOfficeHint => 'Savdo ofisi manzili';

  @override
  String get orgWebsiteHint => 'Veb-sayt';

  @override
  String get orgLogoHint => 'Logotip rasm URL';

  @override
  String get orgCoverHint => 'Muqova rasm URL';

  @override
  String get orgBrandColorHint => 'Brend rangi (masalan, #1A1A1A)';

  @override
  String get orgSaveProfile => 'Profilni saqlash';

  @override
  String get orgSavedMessage => 'Profil saqlandi.';

  @override
  String get orgPlanDetailsShow => 'Koʻrinish tafsilotlarini koʻrsatish';

  @override
  String get orgPlanDetailsHide => 'Koʻrinish tafsilotlarini yashirish';

  @override
  String get orgPlanAlwaysOnTopTitle => '«Doim tepada» koʻrinishi';

  @override
  String get orgPlanAlwaysOnTopSubtitle =>
      'Obuna faol boʻlganda, eʼlonlar 0.4 kuchaytirish koeffitsiyenti bilan tartiblanadi. Obuna tugagach, kuchaytirish ikki hafta ichida 0.04 gacha pasayadi.';

  @override
  String get orgPlanDecayActiveLegend => 'Faol (0.4)';

  @override
  String get orgPlanDecayExpiredLegend => 'Tugagandan soʻng (→0.04)';

  @override
  String get orgPlanDecayWeeksAxis => 'Tugashdan hafta';

  @override
  String get orgPlanDecayCoefficientAxis => 'Kuchaytirish';

  @override
  String get orgAiSectionTitle => 'Qoralama tavsif shabloni';

  @override
  String get orgAiSectionSubtitle =>
      'Havolalaringiz va ixtiyoriy kompaniya taqdimotini qoʻshing — shablon asosida qoralama tuziladi (bu AI tomonidan yozilmagan), saqlashdan oldin tahrirlang.';

  @override
  String get orgAiWebsiteHint => 'Veb-sayt URL';

  @override
  String get orgAiInstagramHint => 'Instagram URL';

  @override
  String get orgAiPickPdf => 'Kompaniya PDF faylini biriktirish';

  @override
  String orgAiPdfSelected(String name) {
    return 'Biriktirildi: $name';
  }

  @override
  String get orgAiGenerate => 'Shablon boʻyicha qoralama tuzish';

  @override
  String get orgAiGenerating => 'Tuzilmoqda…';

  @override
  String get orgAiApply => 'Ushbu qoralamadan foydalanish';

  @override
  String get orgAiResultHint => 'Shablon qoralamasi (tahrirlanadi)';

  @override
  String get orgAiNoInputs => 'Avval veb-sayt, Instagram yoki PDF qoʻshing.';

  @override
  String get orgAiApplied => 'Qoralama qoʻllandi — koʻrib chiqing va saqlang.';

  @override
  String get projectLoadError => 'Loyihani yuklab boʻlmadi';

  @override
  String get projectBack => 'Orqaga';

  @override
  String projectModerationLabel(String status) {
    return 'Moderatsiya: $status';
  }

  @override
  String get projectModerationStatusDraft => 'Qoralama';

  @override
  String get projectModerationStatusPending => 'Ko\'rib chiqilmoqda';

  @override
  String get projectModerationStatusRejected => 'Rad etilgan';

  @override
  String get projectSubmitForReview => 'Ko\'rib chiqish uchun yuborish';

  @override
  String get projectDraftBanner =>
      'Loyiha qoralama sifatida saqlangan. Ma\'lumotlarni to\'ldiring va tayyor bo\'lgach platforma moderatsiyasiga yuboring.';

  @override
  String get projectRejectedBanner =>
      'Loyiha rad etilgan. Platforma izohlarini tuzating va qayta yuboring.';

  @override
  String get projectWarningBanner => 'Platforma ogohlantirishi';

  @override
  String get projectWarningBannerSubtitle =>
      'Quyidagi izohlarni tuzating. Platforma nashrdan olmaguncha loyiha ochiq qoladi.';

  @override
  String get residenceProjectWarned => 'Platforma ogohlantirishi bor';

  @override
  String get projectUnpublish => 'Nashrdan olish';

  @override
  String get projectPublish => 'Nashr etish';

  @override
  String get projectRepublish => 'Qayta nashr etish';

  @override
  String get projectUnpublishConfirm =>
      'Loyiha B2C katalogidan yo\'qoladi. Davom etasizmi?';

  @override
  String get projectPublishSuccess => 'Loyiha yana katalogda';

  @override
  String get projectUnpublishSuccess => 'Loyiha nashrdan olindi';

  @override
  String get projectDelete => 'Loyihani o\'chirish';

  @override
  String projectDeleteConfirmTitle(String name) {
    return '«$name» o\'chirilsinmi?';
  }

  @override
  String get projectDeleteConfirmBody =>
      'Bu qaytarilmaydi: binolar, yunitlar, aksiyalar va leadlar o\'chiriladi.';

  @override
  String get projectDeleteSuccess => 'Loyiha o\'chirildi';

  @override
  String get projectPublishNeedsReview =>
      'Avval platforma moderatsiyasiga yuboring';

  @override
  String get projectPublishNeedsSubscription => 'Nashr uchun faol obuna kerak';

  @override
  String get navActiveProjects => 'Faol ЖК';

  @override
  String get activeProjectsTitle => 'Faol ЖК';

  @override
  String get activeProjectsSubtitle =>
      'Katalogdagi nashr etilgan loyihalar — ogohlantirish va nashrdan olish.';

  @override
  String get projectSubmitForReviewSuccess =>
      'Moderatsiyaga yuborildi — platforma ko\'rib chiqishini kutmoqda.';

  @override
  String get projectLocationSectionTitle => 'Xaritadagi joylashuv';

  @override
  String get projectLocationSave => 'Nuqtani saqlash';

  @override
  String get projectLocationSaved => 'Joylashuv saqlandi';

  @override
  String projectPublishedLabel(String value) {
    return 'Nashr etilgan: $value';
  }

  @override
  String get publishedYes => 'Ha';

  @override
  String get publishedNo => 'Yo\'q';

  @override
  String platformProjectDeveloper(String name) {
    return 'Quruvchi: $name';
  }

  @override
  String get projectAnalyticsTitle => 'Analitika';

  @override
  String get projectOffersTitle => 'Aksiyalar';

  @override
  String get projectAddOffer => 'Aksiya qoʻshish';

  @override
  String get projectNoOffers => 'Faol aksiyalar yoʻq';

  @override
  String get projectNoOffersSubtitle =>
      'Chegirma, boʻlib toʻlash rejasi yoki ijara promosini qoʻshing.';

  @override
  String get projectRemoveOfferTooltip => 'Aksiyani oʻchirish';

  @override
  String get projectUnitsTitle => 'Yunitlar';

  @override
  String get projectAddBuilding => 'Bino qoʻshish';

  @override
  String get projectBulkAddUnits => 'Yunitlarni ommaviy qoʻshish';

  @override
  String get projectViewToggleList => 'Roʻyxat';

  @override
  String get projectViewToggleChessboard => 'Shaxmat taxtasi';

  @override
  String get projectBuildingFallback => 'Bino';

  @override
  String projectUnitLabel(String number) {
    return 'Yunit $number';
  }

  @override
  String projectUnitLabelWithStatus(String number, String status) {
    return 'Yunit $number · $status';
  }

  @override
  String projectUnitMetaLine(
    String kind,
    String dealType,
    String status,
    String mediaCount,
  ) {
    return '$kind · $dealType · $status · media: $mediaCount';
  }

  @override
  String projectUnitMetaLineNoStatus(
    String kind,
    String dealType,
    String mediaCount,
  ) {
    return '$kind · $dealType · media: $mediaCount';
  }

  @override
  String get projectAddMediaUrl => 'Media URL qoʻshish';

  @override
  String get projectStatusButton => 'Holat';

  @override
  String get projectChangeStatusButton => 'Holatni oʻzgartirish';

  @override
  String get projectLeadCrmTitle => 'Murojaatlar CRM';

  @override
  String get projectKanbanHint =>
      'Statusni oʻzgartirish uchun kartani boshqa ustunga tashlang.';

  @override
  String get projectNoLeads => 'Hozircha murojaatlar yoʻq';

  @override
  String projectLeadSummary(String number, String intent, String status) {
    return '$number · $intent · $status';
  }

  @override
  String projectLeadContactLine(String phone, String message) {
    return '$phone · $message';
  }

  @override
  String get projectUpdateLeadStatus => 'Yangilash';

  @override
  String get projectTagsScoreTooltip => 'Teglar va baho';

  @override
  String get projectNewBuildingDialogTitle => 'Bino qoʻshish';

  @override
  String get projectBuildingNameLabel => 'Nomi';

  @override
  String get projectFloorsLabel => 'Qavatlar';

  @override
  String get projectMediaUrlHint => 'https://...';

  @override
  String get projectAddBuildingFirstSnackbar => 'Avval bino qoʻshing';

  @override
  String projectUnitsAddedSnackbar(String count) {
    return '$count yunit qoʻshildi';
  }

  @override
  String projectUnitsPartiallyAddedSnackbar(String count, String error) {
    return '$count ta yunit qoʻshilgach toʻxtadi: $error';
  }

  @override
  String get projectOfferEditorTitle => 'Aksiya qoʻshish';

  @override
  String get projectOfferTypeLabel => 'Turi';

  @override
  String get projectOfferTitleLabel => 'Sarlavha';

  @override
  String get projectOfferDescriptionLabel => 'Tavsif';

  @override
  String get projectDownPaymentLabel => 'Boshlangʻich toʻlov %';

  @override
  String get projectTermMonthsLabel => 'Muddat (oy)';

  @override
  String get projectInterestRateLabel => 'Foiz stavkasi %';

  @override
  String get projectBulkUnitsDialogTitle => 'Yunitlarni ommaviy qoʻshish';

  @override
  String get projectBuildingLabel => 'Bino';

  @override
  String get projectFloorFromLabel => 'Qavatdan';

  @override
  String get projectFloorToLabel => 'Qavatgacha';

  @override
  String get projectUnitsPerFloorLabel => 'Har qavatda yunitlar';

  @override
  String get projectStartingNumberLabel => 'Boshlanish raqami';

  @override
  String get projectKindLabel => 'Turi';

  @override
  String get projectDealLabel => 'Bitim';

  @override
  String get projectAreaLabel => 'Maydon (m²)';

  @override
  String get projectRoomsLabel => 'Xonalar';

  @override
  String get projectPriceLabel => 'Narx (\$)';

  @override
  String get projectPriceM2Label => 'Narx/m²';

  @override
  String get chessboardFilterAll => 'Barcha turlar';

  @override
  String get chessboardRoomsLegendTitle => 'Xonalar:';

  @override
  String get chessboardRooms4Plus => '4+';

  @override
  String get projectRentLabel => 'Ijara/oy (\$)';

  @override
  String get projectGenerate => 'Yaratish';

  @override
  String get projectLegendSoldRented => 'sotilgan / ijaraga berilgan';

  @override
  String get projectLeadsStat => 'Murojaatlar (30 kun)';

  @override
  String get projectLeadsTotalStat => 'Jami murojaatlar';

  @override
  String get projectSellThroughStat => 'Sotilgan foiz';

  @override
  String get projectMonthsToSellOutStat => 'Tugash muddati (oy)';

  @override
  String get projectUnitsStat => 'Yunitlar';

  @override
  String get projectLeadFunnelTitle => 'Murojaatlar funneli';

  @override
  String get projectUnitsByStatusTitle => 'Holat boʻyicha yunitlar';

  @override
  String get projectScheduleSectionTitle => 'Qurilish jadvali';

  @override
  String get projectScheduleSubtitle =>
      'Eʼlon qilingan jadvalingiz bugunga vaʼda qilgan tayyorlik darajasi. Xaridor uni fotohisobotlardan olingan tasdiqlangan koʻrsatkich yonida koʻradi, shuning uchun qiymatni haqiqiy reja bilan mos saqlang.';

  @override
  String get projectPlannedProgressLabel => 'Rejadagi tayyorlik, %';

  @override
  String get projectScheduleSave => 'Jadvalni saqlash';

  @override
  String get projectScheduleSaved => 'Jadval saqlandi';

  @override
  String get projectScheduleInvalid => '0 dan 100 gacha butun son kiriting';

  @override
  String projectActualProgressHint(int percent) {
    return 'Tasdiqlangan tayyorlik: $percent%';
  }

  @override
  String projectScheduleGapOk(int percent) {
    return 'Farq $percent% — ruxsat etilgan chegarada';
  }

  @override
  String projectScheduleGapAlert(int percent) {
    return 'Farq $percent% — 15% dan ortiq, platforma obyektni tekshiruvga yuboradi';
  }

  @override
  String get projectPhotoReportsTitle => 'Qurilish fotohisobotlari';

  @override
  String get projectPhotoReportsSubtitle =>
      'Oy boʻyicha guruhlangan, sanasi belgilangan obekt fotolari, ixtiyoriy ravishda qurilish tayyorlik foizi bilan.';

  @override
  String get projectAddPhotoReport => 'Foto qoʻshish';

  @override
  String get projectPhotoReportsEmpty => 'Hozircha fotohisobotlar yoʻq';

  @override
  String projectPhotoReportUploading(int percent) {
    return 'Yuklanmoqda… $percent%';
  }

  @override
  String projectPhotoReportUploadError(String error) {
    return 'Yuklash xatosi: $error';
  }

  @override
  String get projectPhotoReportDialogTitle => 'Fotohisobot qoʻshish';

  @override
  String get projectPhotoReportDateLabel => 'Suratga olingan sana';

  @override
  String get projectPhotoReportProgressLabel =>
      'Qurilish tayyorlik foizi (ixtiyoriy)';

  @override
  String get projectPhotoReportDeleteTooltip => 'Fotohisobotni oʻchirish';

  @override
  String projectPhotoReportProgressBadge(int percent) {
    return '$percent%';
  }

  @override
  String get statusAvailable => 'boʻsh';

  @override
  String get statusReserved => 'band qilingan';

  @override
  String get statusSold => 'sotilgan';

  @override
  String get statusRented => 'ijaraga berilgan';

  @override
  String get statusBlocked => 'bloklangan';

  @override
  String get offerTypeDiscount => 'chegirma';

  @override
  String get offerTypeInstallment => 'boʻlib toʻlash';

  @override
  String get offerTypeRentPromo => 'ijara promosi';

  @override
  String get unitKindApartment => 'kvartira';

  @override
  String get unitKindOffice => 'ofis';

  @override
  String get unitKindRetail => 'savdo maydoni';

  @override
  String get dealTypeSale => 'sotish';

  @override
  String get dealTypeRent => 'ijara';

  @override
  String get leadScoreHot => 'issiq';

  @override
  String get leadScoreWarm => 'iliq';

  @override
  String get leadScoreCold => 'sovuq';

  @override
  String get leadStatusNew => 'yangi';

  @override
  String get leadStatusContacted => 'bogʻlanildi';

  @override
  String get leadStatusScheduled => 'rejalashtirilgan';

  @override
  String get leadStatusVisited => 'tashrif buyurdi';

  @override
  String get leadStatusWon => 'muvaffaqiyatli';

  @override
  String get leadStatusLost => 'yoʻqotilgan';

  @override
  String get roleOrdinaryUser => 'oddiy foydalanuvchi';

  @override
  String get roleResidenceAdmin => 'ЖК administratori';

  @override
  String get roleSystemAdmin => 'platforma administratori';

  @override
  String get leadStatusQualified => 'malakali';

  @override
  String get documentTypeLicense => 'Litsenziya';

  @override
  String get documentTypeLicenseHint =>
      'Kompaniyaning quruvchi sifatida faoliyat yuritishga qonuniy huquqini tasdiqlaydigan qurilish litsenziyasi.';

  @override
  String get documentTypeConstructionPermit => 'Qurilish ruxsatnomasi';

  @override
  String get documentTypeConstructionPermitHint =>
      'Aynan shu loyihani qurish uchun mahalliy hokimiyatning rasmiy ruxsatnomasi.';

  @override
  String get documentTypeLandRights => 'Yer huquqlari';

  @override
  String get documentTypeLandRightsHint =>
      'Qurilish olib borilayotgan yer uchastkasiga egalik yoki uzoq muddatli ijara huquqini tasdiqlovchi hujjat.';

  @override
  String get documentTypeProjectDeclaration => 'Loyiha deklaratsiyasi';

  @override
  String get documentTypeProjectDeclarationHint =>
      'Loyihani tasvirlovchi deklaratsiya: muddatlar, obyekt va quruvchi xususiyatlari — odatda ulushli qurilish uchun talab qilinadi.';

  @override
  String get documentTypeCadastre => 'Kadastr';

  @override
  String get documentTypeCadastreHint =>
      'Uchastkaning aniq chegaralari va roʻyxat maʼlumotlari boʻlgan kadastr pasporti.';

  @override
  String get documentStatusPending => 'Tekshirilmoqda';

  @override
  String get documentStatusAccepted => 'Qabul qilindi';

  @override
  String get documentStatusRejected => 'Rad etildi';

  @override
  String get navModeration => 'Moderatsiya';

  @override
  String get navCrm => 'CRM';

  @override
  String get navTickets => 'Chiptalar';

  @override
  String get moderationTitle => 'Moderatsiya';

  @override
  String get moderationSubtitle =>
      'Koʻrib chiqilishini kutayotgan yangi ЖК arizalari va sharhlar shikoyatlari.';

  @override
  String get adminProjectsTitle => 'ЖК boshqaruvi';

  @override
  String get adminProjectsSubtitle =>
      'Platformadagi barcha turar-joy majmualari va biznes-markazlar — qanday tuzilgan va nimalar biriktirilganini ko\'rish. Platforma administratori loyihalarga egalik qilmaydi.';

  @override
  String get adminProjectsFilterAll => 'Barchasi';

  @override
  String get adminProjectsFilterPending => 'Kutilmoqda';

  @override
  String get adminProjectsFilterApproved => 'Tasdiqlangan';

  @override
  String get adminProjectsFilterRejected => 'Rad etilgan';

  @override
  String get adminProjectsEmpty => 'Bu filtr bo\'yicha loyihalar yo\'q';

  @override
  String adminProjectsMeta(int count, String units) {
    return '$count foto · $units birlik';
  }

  @override
  String get adminProjectsUnpublished => 'Chop etilmagan';

  @override
  String get crmTitle => 'CRM';

  @override
  String get crmSubtitle =>
      'Barcha ЖК bo\'yicha barcha murojaatlar — bitta loyiha emas, butun platforma bo\'yicha talab.';

  @override
  String get crmKanbanHint =>
      'Statusni oʻzgartirish uchun kartani boshqa ustunga tashlang.';

  @override
  String get crmSearchHint => 'Telefon, loyiha yoki menejer bo\'yicha qidirish';

  @override
  String get crmEmpty => 'Bu filtr bo\'yicha murojaatlar yo\'q';

  @override
  String get crmEdit => 'Tahrirlash';

  @override
  String crmAssignedTo(String name) {
    return 'Mas\'ul: $name';
  }

  @override
  String get crmStatusLabel => 'Holat';

  @override
  String get crmScoreLabel => 'Baho';

  @override
  String get crmAssignedManagerLabel => 'Mas\'ul menejer';

  @override
  String get crmNotesLabel => 'Izohlar';

  @override
  String get crmOwnerLabel => 'Mas\'ul';

  @override
  String get crmOwnerUnassigned => 'Tayinlanmagan';

  @override
  String get crmOwnerFilterAll => 'Barcha lidlar';

  @override
  String get crmOwnerFilterMine => 'Mening lidlarim';

  @override
  String get crmOwnerFilterUnassigned => 'Tayinlanmagan';

  @override
  String get crmAssignToMe => 'O\'zimga tayinlash';

  @override
  String get crmAssigneesLoadError => 'Menejerlar yuklanmadi';

  @override
  String get crmTransferLabel => 'O\'tkazish';

  @override
  String get crmTransferHint => 'Boshqa menejerga o\'tkazish';

  @override
  String get crmTransferNone => 'O\'tkazmaslik';

  @override
  String get crmTransferNoteLabel => 'O\'tkazish izohi';

  @override
  String get crmLeadEditorTitle => 'Lid CRM';

  @override
  String get crmTagsLabel => 'Teglar (vergul bilan)';

  @override
  String get crmEventHistoryTitle => 'Faoliyat';

  @override
  String get crmEventHistoryEmpty => 'Hali voqealar yo\'q';

  @override
  String get crmEventAssigned => 'Tayinlandi';

  @override
  String get crmEventTransferred => 'O\'tkazildi';

  @override
  String get crmEventUnassigned => 'Mas\'ul olib tashlandi';

  @override
  String crmEventStatusChanged(String detail) {
    return 'Status: $detail';
  }

  @override
  String get crmEventNote => 'Izoh qo\'shildi';

  @override
  String get ticketsTitle => 'Chiptalar';

  @override
  String get ticketsSubtitle =>
      'Xaridorlar, ijarachilar, quruvchilar va ЖК administratorlaridan murojaatlar.';

  @override
  String get ticketsEmpty => 'Hozircha chiptalar yo\'q';

  @override
  String get ticketStatusOpen => 'Ochiq';

  @override
  String get ticketStatusInProgress => 'Jarayonda';

  @override
  String get ticketStatusResolved => 'Hal qilingan';

  @override
  String get ticketStatusClosed => 'Yopilgan';

  @override
  String get ticketCategoryBilling => 'To\'lov';

  @override
  String get ticketCategoryModeration => 'Moderatsiya';

  @override
  String get ticketCategoryTechnical => 'Texnik';

  @override
  String get ticketCategoryOther => 'Boshqa';

  @override
  String get ticketReplyHint => 'Javob yozing…';

  @override
  String get ticketSend => 'Yuborish';

  @override
  String get ticketNew => 'Yangi chipta';

  @override
  String get ticketSubjectHint => 'Mavzu';

  @override
  String get ticketMessageHint => 'Savol yoki muammoni tasvirlab bering';

  @override
  String get supportTicketsSubtitle =>
      'Platforma jamoasiga murojaat qiling — to\'lov, moderatsiya yoki texnik muammo.';
}
