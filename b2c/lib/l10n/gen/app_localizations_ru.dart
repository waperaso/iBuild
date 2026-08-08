// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get navHome => 'Главная';

  @override
  String get navSearch => 'Поиск';

  @override
  String get navFavorites => 'Избранное';

  @override
  String get navInquiries => 'Заявки';

  @override
  String get navSettings => 'Настройки';

  @override
  String get onboardingSlogan => 'iBuild the dream';

  @override
  String get onboardingEyebrow =>
      'Продавайте. Инвестируйте. Всё в одном приложении.';

  @override
  String get onboardingDescription =>
      'Готовые квартиры, новостройки в рассрочку и офисы в бизнес-центрах — всё в одном месте, с актуальной доступностью и заявкой в один клик.';

  @override
  String get onboardingTrustBadge => '4.9★ · 500+ довольных семей';

  @override
  String get start => 'Начать';

  @override
  String get signIn => 'Войти';

  @override
  String get welcomeTitle => 'Добро пожаловать в iBuild';

  @override
  String get welcomeSubtitle => 'Войдите по номеру телефона';

  @override
  String get phoneHint => '+998 90 123 45 67';

  @override
  String get sendCode => 'Отправить код';

  @override
  String get phoneRequiredError => 'Введите номер телефона';

  @override
  String get otpTitle => 'Введите код';

  @override
  String otpSubtitle(String phone) {
    return 'Мы отправили 6-значный код на $phone';
  }

  @override
  String get otpCodeHint => '6-значный код';

  @override
  String get otpDevHint => 'Тестовый режим';

  @override
  String get stepOneOfTwo => 'Шаг 1 из 2';

  @override
  String get stepTwoOfTwo => 'Шаг 2 из 2';

  @override
  String get verifyCode => 'Подтвердить';

  @override
  String get resendCode => 'Отправить код повторно';

  @override
  String get invalidCodeError =>
      'Неверный или просроченный код. Попробуйте снова.';

  @override
  String get signedInLabel => 'Вы вошли';

  @override
  String get accountTypeOrdinaryUser => 'Обычный пользователь';

  @override
  String get signInPromptMessage =>
      'Войдите, чтобы сохранять избранное, следить за заявками и получать обновления.';

  @override
  String get madeForYou => 'Специально для вас';

  @override
  String get exploreProperties => 'Изучите объекты';

  @override
  String get recommendForYou => 'Рекомендуем для вас';

  @override
  String get statsListingsLabel => 'Объекты';

  @override
  String get statsAvailableLabel => 'Свободно юнитов';

  @override
  String get statsDistrictsLabel => 'Районы';

  @override
  String get statsRatingLabel => 'Средний рейтинг';

  @override
  String get featuredForYouTitle => 'Специально отобрано';

  @override
  String get popularDistrictsTitle => 'Популярные районы';

  @override
  String get developersTitle => 'Застройщики';

  @override
  String developerProjectsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count проектов',
      many: '$count проектов',
      few: '$count проекта',
      one: '$count проект',
    );
    return '$_temp0';
  }

  @override
  String get developerContactsTitle => 'Контакты';

  @override
  String get developerResidencesTitle => 'Жилые комплексы';

  @override
  String get developerOfficesTitle => 'Офисы';

  @override
  String get developerNotFoundTitle => 'Застройщик не найден';

  @override
  String get developerNotFoundSubtitle =>
      'Этого застройщика больше нет в каталоге.';

  @override
  String districtListingsCount(int count) {
    return '$count объектов';
  }

  @override
  String get promoBannerTitle => 'Новые старты продаж';

  @override
  String get promoBannerSubtitle =>
      'Бронируйте заранее с гибкой рассрочкой на новостройки.';

  @override
  String get promoBannerAction => 'Смотреть новостройки';

  @override
  String get browseListingsAction => 'Смотреть объекты';

  @override
  String get modeBuy => 'Купить';

  @override
  String get modeRent => 'Снять';

  @override
  String get modeNewBuilds => 'Новостройки';

  @override
  String get categoryAll => 'Все';

  @override
  String get categoryApartments => 'Квартиры';

  @override
  String get categoryOffices => 'Офисы';

  @override
  String get bestDeal => 'Лучшее предложение';

  @override
  String get discountBadge => 'Скидка';

  @override
  String get installmentBadge => 'Рассрочка';

  @override
  String unitsAvailableCount(int count) {
    return '$count доступно';
  }

  @override
  String get searchByLocations => 'Поиск по локациям';

  @override
  String liveLocationDistrict(String district) {
    return 'Местоположение · $district';
  }

  @override
  String get mapZoomIn => 'Увеличить';

  @override
  String get mapZoomOut => 'Уменьшить';

  @override
  String get tabUnits => 'Юниты';

  @override
  String get tabFloorPlans => 'Планировки';

  @override
  String get tabAbout => 'О проекте';

  @override
  String get tabReviews => 'Отзывы';

  @override
  String get tabProgress => 'Ход строительства';

  @override
  String get overallProgressTitle => 'Общий ход строительства';

  @override
  String get actualProgressLabel => 'Фактический ход строительства';

  @override
  String get plannedProgressLabel => 'Плановый ход строительства';

  @override
  String get progressOnSchedule => 'Соответствует графику';

  @override
  String get progressAheadOfSchedule => 'Опережает график';

  @override
  String get progressAcceptableDeviation => 'Допустимое отклонение';

  @override
  String get progressBehindSchedule => 'Отставание от графика';

  @override
  String progressDeviation(int percent) {
    return 'Расхождение $percent%';
  }

  @override
  String trustIndexLabel(int percent) {
    return 'Индекс доверия $percent%';
  }

  @override
  String get progressComparisonNote =>
      'Отклонение до 15% — обычная часть стройки: погода, сезонные ограничения работ, задержки поставок. Больше 15% — платформа передаёт объект на проверку.';

  @override
  String get progressEmptyTitle => 'Пока нет фотоотчётов';

  @override
  String get progressEmptySubtitle =>
      'Датированные фото со стройки появятся здесь по мере загрузки застройщиком.';

  @override
  String get noReviewsYet => 'Пока нет отзывов';

  @override
  String get reviewsEmptySubtitle =>
      'Станьте первым, кто оставит отзыв — или сначала задайте нам вопрос.';

  @override
  String get writeReviewAction => 'Написать отзыв';

  @override
  String get submitReviewAction => 'Отправить отзыв';

  @override
  String get reviewBodyHint => 'Поделитесь впечатлениями об этом проекте...';

  @override
  String reviewsCount(int count) {
    return '$count отзывов';
  }

  @override
  String get flagReviewAction => 'Пожаловаться';

  @override
  String get reviewFlaggedSnackbar => 'Спасибо — мы проверим';

  @override
  String get viewUnitGrid => 'Смотреть шахматку';

  @override
  String get requestCallback => 'Запросить звонок';

  @override
  String fromPrice(String price) {
    return 'От $price';
  }

  @override
  String rentFromPrice(String price) {
    return 'Аренда от $price';
  }

  @override
  String get noDescription => 'Нет описания.';

  @override
  String get amenitiesTitle => 'Удобства';

  @override
  String get projectDetailsMenu => 'О проекте';

  @override
  String get offersInstallmentsMenu => 'Акции и рассрочка';

  @override
  String get supportMenu => 'Поддержка';

  @override
  String get noneLabel => 'Нет';

  @override
  String activeOffersCount(int count) {
    return '$count активно';
  }

  @override
  String get requestCallbackTrailing => 'Запросить звонок';

  @override
  String builtPercent(int percent) {
    return 'Готовность $percent%';
  }

  @override
  String completionDate(String date) {
    return 'Срок сдачи: $date';
  }

  @override
  String get readyToMoveIn => 'Готово к заселению';

  @override
  String get handedOverToResidents => 'Сдано жильцам';

  @override
  String get offersSheetTitle => 'Акции';

  @override
  String get noActiveOffers => 'Пока нет активных акций по этому проекту.';

  @override
  String get iBuildPartner => 'Партнёр iBuild';

  @override
  String get verifiedBadgeLabel => 'Проверен';

  @override
  String get verificationPendingBadgeLabel => 'Проверка идёт';

  @override
  String get verificationDisclaimer =>
      'Статус «Проверен» означает, что iBuild сверил предоставленные застройщиком документы с открытыми государственными реестрами на указанную дату. Это не является гарантией завершения строительства, юридической или финансовой рекомендацией. Принимая решение, проверяйте актуальные данные самостоятельно.';

  @override
  String get documentTypeLicense => 'Лицензия застройщика';

  @override
  String get documentTypeConstructionPermit => 'Разрешение на строительство';

  @override
  String get documentTypeLandRights => 'Права на земельный участок';

  @override
  String get documentTypeProjectDeclaration => 'Проектная декларация';

  @override
  String get documentTypeCadastre => 'Кадастр';

  @override
  String get documentStatusAccepted => 'Принят';

  @override
  String get documentStatusPending => 'На проверке';

  @override
  String get documentStatusRejected => 'Отклонён';

  @override
  String get documentStatusMissing => 'Не предоставлен';

  @override
  String get availabilityTitle => 'Доступность';

  @override
  String get legendSoldRented => 'Продано / Сдано';

  @override
  String get chessboardFilterAll => 'Все типы';

  @override
  String get chessboardRoomsLegendTitle => 'Комнаты:';

  @override
  String get chessboardRooms4Plus => '4+';

  @override
  String get unitFallbackTitle => 'Юнит';

  @override
  String unitNumberTitle(String number) {
    return 'Юнит $number';
  }

  @override
  String get unitNotFound => 'Юнит не найден';

  @override
  String roomsCount(int count) {
    return '$count комн.';
  }

  @override
  String floorLabel(int floor) {
    return 'Этаж $floor';
  }

  @override
  String viewLabel(String view) {
    return 'Вид: $view';
  }

  @override
  String get offplanInstallmentBadge => 'Новостройка · доступна рассрочка';

  @override
  String minimumLeaseMonths(int months) {
    return 'Минимальный срок аренды: $months мес.';
  }

  @override
  String get bookViewing => 'Записаться на просмотр';

  @override
  String get rentEnquiry => 'Заявка на аренду';

  @override
  String get reserve => 'Забронировать';

  @override
  String get newInquiryTitle => 'Новая заявка';

  @override
  String get whatDoYouNeed => 'Что вам нужно?';

  @override
  String get contactPhoneLabel => 'Контактный телефон';

  @override
  String get commentOptionalLabel => 'Комментарий (необязательно)';

  @override
  String get commentHint => 'Удобное время, вопросы...';

  @override
  String get piiConsentLabel =>
      'Я согласен на обработку моих персональных данных (имя и номер телефона), чтобы iBuild и этот застройщик могли связаться со мной по моей заявке.';

  @override
  String get piiConsentRequiredError =>
      'Чтобы продолжить, подтвердите согласие на обработку персональных данных.';

  @override
  String get submitInquiry => 'Отправить заявку';

  @override
  String leadSubmittedSnackbar(String number) {
    return 'Заявка $number отправлена';
  }

  @override
  String get leadSignInRequiredTitle => 'Войдите, чтобы отправить заявку';

  @override
  String get leadSignInRequiredBody =>
      'Создайте аккаунт или войдите в iBuild, чтобы застройщик мог связаться с вами по этой заявке.';

  @override
  String get leadSignInCta => 'Войти, чтобы продолжить';

  @override
  String get leadSignInRequiredError =>
      'Войдите в аккаунт, чтобы отправить заявку.';

  @override
  String get myInquiriesTitle => 'Мои заявки';

  @override
  String get tabActive => 'Активные';

  @override
  String get tabCompleted => 'Завершённые';

  @override
  String get tabCancelled => 'Отменённые';

  @override
  String get nothingHereYet => 'Здесь пока пусто';

  @override
  String get inquiriesEmptySubtitle =>
      'Ваши заявки на звонок и просмотр появятся здесь.';

  @override
  String get inquiriesSignInRequiredTitle => 'Войдите, чтобы увидеть заявки';

  @override
  String get inquiriesSignInRequiredBody =>
      'Войдите в аккаунт iBuild, чтобы просматривать заявки на звонок и просмотр.';

  @override
  String get savedTitle => 'Сохранённое';

  @override
  String get tabSavedSearches => 'Сохранённые поиски';

  @override
  String get noFavoritesYet => 'Пока нет избранного';

  @override
  String get favoritesEmptySubtitle =>
      'Нажмите на сердечко у объекта, чтобы сохранить его здесь.';

  @override
  String get savedSearchesEmptySubtitle =>
      'Сохраните поиск в фильтрах, чтобы быстро вернуться к нему.';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get guestUser => 'Гость';

  @override
  String get appearanceTitle => 'Оформление';

  @override
  String get darkModeLabel => 'Тёмная тема';

  @override
  String get lightModeLabel => 'Светлая тема';

  @override
  String get paletteLabel => 'Палитра';

  @override
  String get languageLabel => 'Язык';

  @override
  String get currencyLabel => 'Валюта';

  @override
  String exchangeRateTooltip(String rate) {
    return '1 USD = $rate UZS';
  }

  @override
  String get timeJustNow => 'сейчас';

  @override
  String timeMinutesAgo(int count) {
    return '$count мин назад';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count ч назад';
  }

  @override
  String timeDaysAgo(int count) {
    return '$count дн назад';
  }

  @override
  String get accountTitle => 'Аккаунт';

  @override
  String get preferencesLabel => 'Предпочтения';

  @override
  String get notificationsLabel => 'Уведомления';

  @override
  String get helpSupportLabel => 'Помощь и поддержка';

  @override
  String get signOutLabel => 'Выйти';

  @override
  String get accountBannedTitle => 'Ваш аккаунт заблокирован';

  @override
  String get accountBannedReasonLabel => 'Причина';

  @override
  String accountBannedByLabel(String name) {
    return 'Заблокировал: $name';
  }

  @override
  String get projectTypeResidentialComplex => 'Жилой комплекс';

  @override
  String get projectTypeBusinessCentre => 'Бизнес-центр';

  @override
  String get projectTypeStreetRetail => 'Стрит-ритейл';

  @override
  String get projectTypeOffice => 'Офис';

  @override
  String get projectTypeCottage => 'Коттедж';

  @override
  String get unitKindApartment => 'Квартира';

  @override
  String get unitKindOffice => 'Офис';

  @override
  String get unitKindRetail => 'Торговое помещение';

  @override
  String get projectStatusPlanned => 'Запланировано';

  @override
  String get projectStatusUnderConstruction => 'Строится';

  @override
  String get projectStatusReady => 'Готово';

  @override
  String get projectStatusHandedOver => 'Сдано';

  @override
  String get statusAvailable => 'Свободно';

  @override
  String get statusReserved => 'Забронировано';

  @override
  String get statusSold => 'Продано';

  @override
  String get statusRented => 'Сдано';

  @override
  String get statusBlocked => 'Заблокировано';

  @override
  String get leadIntentBuy => 'Покупка';

  @override
  String get leadIntentBuyOffplan => 'Бронирование новостройки';

  @override
  String get leadIntentRent => 'Заявка на аренду';

  @override
  String get leadIntentViewing => 'Просмотр';

  @override
  String get leadIntentCallback => 'Обратный звонок';

  @override
  String get leadStatusNew => 'Новая';

  @override
  String get leadStatusContacted => 'Связались';

  @override
  String get leadStatusScheduled => 'Запланирована';

  @override
  String get leadStatusVisited => 'Состоялся просмотр';

  @override
  String get leadStatusWon => 'Успешно';

  @override
  String get leadStatusLost => 'Отклонена';

  @override
  String get somethingWentWrong => 'Что-то пошло не так.';

  @override
  String get retry => 'Повторить';

  @override
  String viewGalleryCount(int count) {
    return 'Галерея · $count фото';
  }

  @override
  String galleryPhotoOfTotal(int index, int total) {
    return '$index / $total';
  }

  @override
  String get floorPlansEmptyMessage =>
      'Планы этажей появятся здесь, когда будут готовы.';

  @override
  String get layoutsTitle => 'Планировки квартир';

  @override
  String layoutRoomsLabel(int count) {
    return '$count-комнатная';
  }

  @override
  String layoutAvailability(int available, int total) {
    return '$available из $total доступно';
  }

  @override
  String get viewAvailableUnits => 'Смотреть доступные квартиры';

  @override
  String get callAgentLabel => 'Позвонить агенту';

  @override
  String get agentPhoneUnavailable => 'Номер телефона недоступен';

  @override
  String get callFailedSnackbar => 'Не удалось начать звонок';

  @override
  String get contactAgentTitle => 'Менеджер по продажам';

  @override
  String get viewInsideLabel => 'Посмотреть внутри';

  @override
  String get searchHint => 'Поиск проектов, районов...';

  @override
  String get filtersTitle => 'Фильтры';

  @override
  String get districtLabel => 'Район';

  @override
  String get statusLabel => 'Статус';

  @override
  String priceRangeLabel(String min, String max) {
    return 'Цена: $min – $max';
  }

  @override
  String get roomsLabel => 'Комнаты';

  @override
  String get roomsStudio => 'Студия';

  @override
  String roomsPlus(int count) {
    return '$count+';
  }

  @override
  String get areaMinLabel => 'Площадь от, м²';

  @override
  String get offplanOnlyLabel => 'Только новостройки';

  @override
  String get applyFilters => 'Применить';

  @override
  String get clearFilters => 'Сбросить';

  @override
  String get saveThisSearch => 'Сохранить поиск';

  @override
  String get savedSearchSavedSnackbar => 'Поиск сохранён';

  @override
  String savedSearchUnderPrice(String price) {
    return 'до $price';
  }

  @override
  String savedSearchFromPrice(String price) {
    return 'от $price';
  }

  @override
  String get noSavedSearchesYet => 'Пока нет сохранённых поисков';

  @override
  String get notificationsTitle => 'Уведомления';

  @override
  String get notificationsEmpty => 'Пока нет уведомлений';

  @override
  String get notificationsEmptySubtitle =>
      'Мы сообщим о снижении цен, новых предложениях и обновлениях.';

  @override
  String get markAllRead => 'Прочитать все';

  @override
  String get notifLeadStatusTitle => 'Статус заявки обновлён';

  @override
  String notifLeadStatusBody(String status) {
    return 'Ваша заявка теперь: «$status».';
  }

  @override
  String get notifNewOfferTitle => 'Новое предложение';

  @override
  String get notifNewOfferBody =>
      'В проекте, за которым вы следите, появилось новое предложение.';

  @override
  String get notifLeadCreatedTitle => 'Заявка получена';

  @override
  String get notifLeadCreatedBody =>
      'Мы получили вашу заявку и скоро свяжемся с вами.';

  @override
  String get compareModeAction => 'Сравнить квартиры';

  @override
  String compareCountLabel(int count) {
    return 'Сравнить ($count)';
  }

  @override
  String get addToCompareAction => 'Добавить к сравнению';

  @override
  String get compareTitle => 'Сравнение квартир';

  @override
  String get compareEmpty => 'Выберите квартиры, чтобы сравнить их';

  @override
  String get compareAreaLabel => 'Площадь';

  @override
  String get comparePriceLabel => 'Цена';

  @override
  String get compareFloorLabel => 'Этаж';

  @override
  String get compareRoomsLabel => 'Комнаты';

  @override
  String get compareStatusLabel => 'Статус';

  @override
  String get compareViewLabel => 'Вид';

  @override
  String get installmentCalculatorTitle => 'Калькулятор рассрочки';

  @override
  String downPaymentLabel(int percent, String amount) {
    return 'Первый взнос: $percent% ($amount)';
  }

  @override
  String termMonthsLabel(int months) {
    return 'Срок: $months мес.';
  }

  @override
  String get monthlyPaymentLabel => 'Ежемесячный платёж';

  @override
  String get calculateInstallmentAction => 'Рассчитать';

  @override
  String get rentalRentLabel => 'Аренда в месяц';

  @override
  String get ownerListingsSectionTitle => 'Объявления от собственников рядом';

  @override
  String get secondaryTag => 'Вторичка';

  @override
  String get perMonthSuffix => '/мес';

  @override
  String get forBusinessTitle => 'Вы владеете недвижимостью или бизнесом?';

  @override
  String get forBusinessSubtitle =>
      'Размещайте объекты на продажу и в аренду, управляйте заявками и аналитикой в iBuild для бизнеса.';

  @override
  String get forBusinessAction => 'Открыть iBuild для бизнеса';

  @override
  String get mortgageCalculatorAction => 'Ипотечный калькулятор';

  @override
  String get mortgageCalculatorTitle => 'Ипотечный калькулятор';

  @override
  String get mortgagePropertyPriceLabel => 'Стоимость объекта';

  @override
  String get toolsSectionTitle => 'Инструменты';

  @override
  String interestRateLabel(String percent) {
    return 'Ставка банка: $percent% годовых';
  }

  @override
  String termYearsLabel(int years) {
    return 'Срок: $years лет';
  }

  @override
  String get totalInterestLabel => 'Итого проценты';

  @override
  String get totalPaymentLabel => 'Итого выплата';

  @override
  String get downPaymentAmountLabel => 'Первоначальный взнос';

  @override
  String get bankReferralConsentLabel =>
      'Согласен на связь с партнёром-банком iBuild по этой ипотеке';

  @override
  String get requestBankConsultationAction => 'Заявка на консультацию банка';

  @override
  String get bankReferralSubmittedSnackbar =>
      'Партнёр-банк свяжется с вами в ближайшее время';

  @override
  String get rentalYieldCalculatorAction => 'Калькулятор доходности';

  @override
  String get rentalYieldCalculatorTitle => 'Калькулятор доходности аренды';

  @override
  String get grossYieldLabel => 'Валовая доходность';

  @override
  String get paybackYearsLabel => 'Срок окупаемости';

  @override
  String paybackYearsValue(String years) {
    return '$years лет';
  }

  @override
  String get annualRentLabel => 'Годовая аренда';

  @override
  String get calculatingLabel => 'Расчёт...';

  @override
  String get quizTitle => 'Подберём ваш вариант';

  @override
  String get quizIntroTitle => 'Персонализируем поиск';

  @override
  String get quizIntroBody =>
      'Ответьте на 4 быстрых вопроса — мы настроим ленту и сформируем AI-превью прямо на устройстве, только для вас.';

  @override
  String get quizStartAction => 'Начать викторину';

  @override
  String quizStepCounter(int current, int total) {
    return '$current из $total';
  }

  @override
  String get quizSavedSnackbar => 'Предпочтения сохранены';

  @override
  String get quizGoalQuestion => 'Что для вас важнее всего в новом жилье?';

  @override
  String get quizGoalBudget => 'Выгодная цена';

  @override
  String get quizGoalFamily => 'Простор для семьи';

  @override
  String get quizGoalInvestment => 'Умная инвестиция';

  @override
  String get quizGoalLuxury => 'Премиальная жизнь';

  @override
  String get quizLocationQuestion => 'Где вы себя представляете?';

  @override
  String get quizLocationCityCenter => 'В центре города';

  @override
  String get quizLocationQuietSuburb => 'Тихий зелёный район';

  @override
  String get quizLocationBusinessDistrict => 'Рядом с деловым районом';

  @override
  String get quizLocationUpAndComing => 'Перспективный район';

  @override
  String get quizTimelineQuestion => 'Когда хотите заселиться?';

  @override
  String get quizTimelineReadyNow => 'Как можно скорее';

  @override
  String get quizTimelineOffplanOk => 'Готов(а) подождать новостройку';

  @override
  String get quizTimelineFlexible => 'Гибкие сроки';

  @override
  String get quizPriorityQuestion => 'Выберите главный приоритет';

  @override
  String get quizPriorityPrice => 'Цена';

  @override
  String get quizPrioritySpace => 'Простор и планировка';

  @override
  String get quizPriorityAmenities => 'Инфраструктура';

  @override
  String get quizPriorityLocation => 'Расположение';

  @override
  String get quizResultEyebrow => 'Ваш профиль покупателя';

  @override
  String get quizPersonaFirstTimeBuyer => 'Первая покупка';

  @override
  String get quizPersonaFamilyNester => 'Семейный дом';

  @override
  String get quizPersonaInvestor => 'Инвестор';

  @override
  String get quizPersonaLuxurySeeker => 'Ценитель премиума';

  @override
  String get quizPersonaFirstTimeBuyerDesc =>
      'Вам нужно лучшее жильё в рамках бюджета. Мы покажем выгодные варианты и гибкие рассрочки.';

  @override
  String get quizPersonaFamilyNesterDesc =>
      'На первом месте простор и комфорт. Мы выделим большие планировки в спокойных районах с инфраструктурой.';

  @override
  String get quizPersonaInvestorDesc =>
      'Вы ориентированы на доходность. Мы подсветим варианты с высокой доходностью и перспективные новостройки.';

  @override
  String get quizPersonaLuxurySeekerDesc =>
      'Только лучшее. Мы подберём премиальные резиденции с особыми удобствами и локациями.';

  @override
  String get quizPreviewTitle => 'Ваше AI-превью';

  @override
  String get quizPreviewPromptLabel => 'Запрос (локальный мок)';

  @override
  String quizPreviewBody(String persona) {
    return 'Как $persona, вы первыми увидите наиболее подходящее жильё. Мы будем показывать то, что важно именно вам, и обновлять подборку с новыми объявлениями. Это превью формируется локально — данные не покидают устройство.';
  }

  @override
  String get quizDoneAction => 'К моим вариантам';

  @override
  String get quizRetakeAction => 'Пройти заново';

  @override
  String get quizEntryAction => 'Пройти викторину';
}
