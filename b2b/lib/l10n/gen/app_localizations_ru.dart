// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get languageLabel => 'Язык';

  @override
  String get commonCancel => 'Отмена';

  @override
  String get commonSave => 'Сохранить';

  @override
  String get commonAdd => 'Добавить';

  @override
  String get commonClose => 'Закрыть';

  @override
  String get commonSignOut => 'Выйти';

  @override
  String get commonExit => 'Выйти';

  @override
  String get logoutConfirmTitle => 'Выйти из аккаунта?';

  @override
  String get logoutConfirmMessage =>
      'Чтобы продолжить работу, потребуется войти снова.';

  @override
  String get loginTitle => 'Вход для администратора';

  @override
  String get loginSubtitle => 'Администрирование платформы и ЖК';

  @override
  String get loginPhoneHint => 'Номер телефона';

  @override
  String get loginSendCode => 'Отправить код';

  @override
  String get loginSendCodeError =>
      'Не удалось отправить код. Попробуйте снова.';

  @override
  String get otpTitle => 'Введите код';

  @override
  String otpSentTo(String phone) {
    return 'Отправлен на $phone';
  }

  @override
  String get otpHint => '000000';

  @override
  String get otpDevHelper => 'Тест-режим: 123456, если Eskiz не настроен';

  @override
  String get otpVerify => 'Подтвердить';

  @override
  String get otpInvalidError => 'Неверный или истёкший код';

  @override
  String get otpResendPrompt => 'Не получили код?';

  @override
  String get otpResendAction => 'Отправить код повторно';

  @override
  String otpResendCountdown(int seconds) {
    return 'Повторно через $seconds с';
  }

  @override
  String get otpResendSuccess => 'Новый код отправлен';

  @override
  String otpResendError(String error) {
    return 'Не удалось отправить код повторно: $error';
  }

  @override
  String get applyStepWelcome => 'Добро пожаловать';

  @override
  String get applyStepRole => 'Ваша роль';

  @override
  String get applyStepDetails => 'Данные компании';

  @override
  String get applyOnboardingTitle => 'Настройка доступа к ЖК';

  @override
  String get applyOnboardingSubtitle =>
      'Короткая настройка, чтобы ваша команда могла управлять комплексами, юнитами и заявками. Проверка платформой обычно занимает один рабочий день.';

  @override
  String get applyOnboardingPointWorkspace =>
      'Одно рабочее пространство на компанию для ваших ЖК';

  @override
  String get applyOnboardingPointAccess =>
      'Доступ открывается после быстрой проверки платформой';

  @override
  String get applyGetStarted => 'Начать';

  @override
  String get applyHaveAccount => 'У меня есть аккаунт';

  @override
  String get authHeroTitle => 'Платформа для застройщиков';

  @override
  String get authHeroSubtitle =>
      'Управляйте жилыми комплексами, юнитами и заявками покупателей в едином рабочем пространстве iBuild — созданном для команд, а не только администраторов.';

  @override
  String get authHeroPointVerified =>
      'Проверенные застройщики и объекты — доверие покупателей';

  @override
  String get authHeroPointLeads =>
      'Заявки покупателей и арендаторов приходят прямо в вашу CRM';

  @override
  String get applyRoleTitle => 'Регистрация застройщика';

  @override
  String get applyRoleSubtitle =>
      'Публикуйте свои жилые комплексы и управляйте юнитами и заявками покупателей. Если вы также ведёте строительство самостоятельно, отметьте это ниже.';

  @override
  String get applyContinue => 'Продолжить';

  @override
  String get applyKindDeveloperLabel => 'Застройщик';

  @override
  String get applyKindDeveloperSubtitle =>
      'Вы строите и продаёте собственные жилые комплексы — публикуйте проекты и управляйте юнитами и заявками покупателей.';

  @override
  String get applyKindConstructionLabel => 'Строительная компания';

  @override
  String get applyKindConstructionSubtitle =>
      'Вы строите для других застройщиков (подрядчик) — координируйте работы на объекте, склад и доступ к ЖК.';

  @override
  String get applyAlsoContractorLabel =>
      'Также веду строительство самостоятельно';

  @override
  String get applyAlsoContractorSubtitle =>
      'Отметьте, если вы застройщик, который сам выступает подрядчиком на своих объектах — понадобится номер строительной лицензии.';

  @override
  String get applyDetailsTitle => 'Данные юридического лица';

  @override
  String applyDetailsSubtitle(String kind) {
    return 'Регистрационные данные Узбекистана (СТИР/ИНН, ПИНФЛ директора, конечный владелец). Требуется для проверки платформой как $kind.';
  }

  @override
  String get applyBrandName => 'Бренд / торговое название *';

  @override
  String get applyLegalName => 'Полное юридическое название *';

  @override
  String get applyInn => 'ИНН / СТИР (9 цифр) *';

  @override
  String get applyLegalForm =>
      'Организационно-правовая форма (ООО / ИП / АО) *';

  @override
  String get applyRegistrationNumber => 'Номер государственной регистрации';

  @override
  String get applyLegalAddress => 'Юридический адрес *';

  @override
  String get applyOfficeAddress => 'Адрес офиса / отдела продаж';

  @override
  String get applyRegion => 'Регион';

  @override
  String get applyRegionTashkent => 'Ташкент';

  @override
  String get applyRegionNewTashkent => 'Новый Ташкент';

  @override
  String get applyEmail => 'Email компании';

  @override
  String get applyDirectorSectionTitle => 'Директор (руководитель)';

  @override
  String get applyDirectorFullName => 'ФИО директора *';

  @override
  String get applyDirectorPinfl => 'ПИНФЛ директора (14 цифр) *';

  @override
  String get applyDirectorPassport => 'Серия и номер паспорта';

  @override
  String get applyDirectorPhone => 'Телефон директора';

  @override
  String get applyUboName => 'Конечный владелец (если отличается)';

  @override
  String get applyLicense => 'Номер строительной лицензии';

  @override
  String get applyUboConfirm =>
      'Подтверждаю, что данные конечного владельца (UBO) точны (правила AML / регистрации РУз). *';

  @override
  String get applyUboHelper =>
      'Конечный владелец (UBO) — физическое лицо, которое в конечном счёте владеет компанией или контролирует её (обычно доля 25% и более). Правила AML РУз требуют указания этих данных.';

  @override
  String get applySubmit => 'Сохранить черновик';

  @override
  String get applySaveDraft => 'Сохранить черновик';

  @override
  String get applySaveDraftSuccess =>
      'Черновик сохранён — проверьте данные и отправьте на рассмотрение, когда будете готовы.';

  @override
  String get applySubmitSuccess =>
      'Заявка отправлена — ожидает одобрения платформы.';

  @override
  String get applyDraftTitle => 'Черновик сохранён';

  @override
  String get applyDraftSubtitle =>
      'Проверьте данные и отправьте заявку на рассмотрение платформы, когда будете готовы.';

  @override
  String get applySubmitForReview => 'Отправить на рассмотрение';

  @override
  String get applySubmitForReviewSuccess =>
      'Заявка отправлена — ожидает рассмотрения платформой.';

  @override
  String get applyDocumentsRequiredHint =>
      'Загрузите все 4 документа для верификации выше, прежде чем отправить заявку на рассмотрение.';

  @override
  String applyDocumentsMissingHint(String names) {
    return 'Вы не добавили: $names. Загрузите их выше, прежде чем отправить заявку на рассмотрение.';
  }

  @override
  String get applyReviewDecisionLabel => 'Решение';

  @override
  String get applyPendingTitle => 'Заявка отправлена';

  @override
  String get applyPendingSubtitle =>
      'Мы рассмотрим вашу заявку и сообщим здесь о решении. Обычно это занимает один рабочий день.';

  @override
  String get applyPendingRefresh => 'Обновить статус';

  @override
  String get applyRejectedTitle => 'Заявка отклонена';

  @override
  String get applyRejectedReasonLabel => 'Причина отказа';

  @override
  String get applyRejectedResendAction => 'Изменить и отправить снова';

  @override
  String get applyApprovedTitle => 'Заявка одобрена';

  @override
  String get applyApprovedSubtitle => 'Переходим в ваш кабинет…';

  @override
  String applyRequestFailed(String code) {
    return 'Запрос не выполнен ($code). Попробуйте снова.';
  }

  @override
  String get applyNetworkError =>
      'Не удалось связаться с сервером. Проверьте подключение.';

  @override
  String get navPlatform => 'Платформа';

  @override
  String get navResidence => 'ЖК';

  @override
  String get navOrganization => 'Организация';

  @override
  String get navSettings => 'Настройки';

  @override
  String get shellAdminFallback => 'Админ';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsAppearance => 'Оформление';

  @override
  String get settingsDarkMode => 'Тёмная тема';

  @override
  String get settingsPalette => 'Цветовая тема';

  @override
  String get settingsAccount => 'Аккаунт';

  @override
  String get platformTitle => 'Администрирование платформы';

  @override
  String get platformSubtitle =>
      'Одобряйте компании, модерируйте проекты, отслеживайте подписки \$299/мес.';

  @override
  String platformAnalyticsError(String error) {
    return 'Ошибка аналитики: $error';
  }

  @override
  String get statUsers => 'Пользователи';

  @override
  String get statProjects => 'Проекты';

  @override
  String get statPublished => 'Опубликовано';

  @override
  String get statLeads => 'Заявки';

  @override
  String get statAppsPending => 'Заявок на рассмотрении';

  @override
  String get statProjectsPending => 'Проектов на модерации';

  @override
  String get statPaid => 'Оплачено';

  @override
  String get statUnpaid => 'Не оплачено';

  @override
  String get platformBusinessesSectionTitle =>
      'Зарегистрированные компании · оплата';

  @override
  String get platformNoBusinesses => 'Пока нет зарегистрированных компаний';

  @override
  String platformBusinessesError(String error) {
    return 'Ошибка компаний: $error';
  }

  @override
  String get platformPendingAppsSectionTitle => 'Заявки на рассмотрении';

  @override
  String get platformNoPendingApps => 'Нет заявок на рассмотрении';

  @override
  String get platformViewKyc => 'Просмотреть KYC';

  @override
  String get platformApprove => 'Одобрить';

  @override
  String get platformReject => 'Отклонить';

  @override
  String get platformRejectReasonDefault => 'Не соответствует требованиям';

  @override
  String get devStatusPending => 'Ожидает рассмотрения';

  @override
  String get devStatusDraft => 'Черновик';

  @override
  String get devStatusInReview => 'На рассмотрении';

  @override
  String get devStatusApproved => 'Одобрено';

  @override
  String get devStatusRejected => 'Отклонено';

  @override
  String get platformChangeStatusTooltip => 'Изменить статус';

  @override
  String get platformStatusMenuAccept => 'Одобрить';

  @override
  String get platformStatusMenuDecline => 'Отклонить…';

  @override
  String get platformStatusUpdated => 'Статус заявки обновлён';

  @override
  String get platformDeclineDialogTitle => 'Отклонить заявку';

  @override
  String get platformDeclineReasonLabel => 'Причина';

  @override
  String get platformDeclineReasonHint => 'Почему эта заявка отклоняется?';

  @override
  String get platformDeclineConfirm => 'Отклонить заявку';

  @override
  String get platformPendingProjectsSectionTitle => 'Проекты на модерации';

  @override
  String get platformNoPendingProjects => 'Нет проектов, ожидающих модерации';

  @override
  String get platformPublish => 'Опубликовать';

  @override
  String get platformProjectDetails => 'Подробнее';

  @override
  String get platformProjectDescriptionLabel => 'Описание';

  @override
  String get platformProjectPricingLabel => 'Цены';

  @override
  String platformProjectPriceRange(String min, String max) {
    return '$min – $max сум';
  }

  @override
  String platformProjectRentRange(String min, String max) {
    return 'Аренда: $min – $max сум/мес';
  }

  @override
  String platformProjectCompletionLabel(String date) {
    return 'Срок сдачи: $date';
  }

  @override
  String get platformProjectGalleryLabel => 'Галерея';

  @override
  String get platformProjectUnitsLabel => 'Юниты';

  @override
  String platformProjectUnitsSummary(int buildings, int total) {
    return '$buildings корпусов · $total юнитов';
  }

  @override
  String get platformProjectUnitsEmpty => 'Юниты пока не добавлены';

  @override
  String platformProjectLoadError(String error) {
    return 'Не удалось загрузить данные проекта: $error';
  }

  @override
  String get platformPublishedProjectsSectionTitle => 'Опубликованные проекты';

  @override
  String get platformNoPublishedProjects => 'Нет опубликованных проектов';

  @override
  String get platformUnpublish => 'Снять с публикации';

  @override
  String get platformWarn => 'Предупреждение';

  @override
  String platformWarnDialogTitle(String name) {
    return 'Предупреждение для «$name»';
  }

  @override
  String get platformWarnReasonHint => 'Что нужно исправить застройщику?';

  @override
  String get platformUnpublishConfirm => 'Снять с публикации';

  @override
  String get platformActionSuccess => 'Готово';

  @override
  String platformActionError(String error) {
    return 'Ошибка: $error';
  }

  @override
  String get platformPendingReviewsSectionTitle => 'Отзывы на модерации';

  @override
  String get platformNoPendingReviews => 'Нет отзывов, ожидающих модерации';

  @override
  String get platformReviewRatingLocation => 'Расположение';

  @override
  String get platformReviewRatingQuality => 'Качество';

  @override
  String get platformReviewRatingValue => 'Цена/качество';

  @override
  String platformReviewProjectLabel(String name) {
    return 'Проект: $name';
  }

  @override
  String get platformAnonymous => 'Анонимно';

  @override
  String get platformKeep => 'Оставить';

  @override
  String get platformRemove => 'Удалить';

  @override
  String get platformPendingRentalsSectionTitle =>
      'Объявления об аренде на модерации';

  @override
  String get platformNoPendingRentals => 'Нет объявлений, ожидающих модерации';

  @override
  String get platformRentalRejectNoteDefault =>
      'Не соответствует требованиям к объявлению';

  @override
  String platformRentalMonthlyRent(String amount) {
    return '$amount сум/мес';
  }

  @override
  String platformRentalContactLabel(String phone) {
    return 'Контакт: $phone';
  }

  @override
  String get platformAuditLogSectionTitle => 'Журнал действий';

  @override
  String get platformNoAuditEvents => 'Пока нет событий в журнале';

  @override
  String platformAuditError(String error) {
    return 'Ошибка журнала действий: $error';
  }

  @override
  String get platformAuditLogActorPrefix => 'Изменил';

  @override
  String get platformAuditLogActorUnknown => 'Неизвестный пользователь';

  @override
  String platformAuditLogPageInfo(int page, int total) {
    return 'Страница $page из $total';
  }

  @override
  String get platformAuditLogPrevPage => 'Предыдущая страница';

  @override
  String get platformAuditLogNextPage => 'Следующая страница';

  @override
  String get notificationsTitle => 'Уведомления';

  @override
  String get notificationsSubtitle =>
      'Все изменения проектов и отправленные документы, которые нужно проверить.';

  @override
  String get notificationsMarkAllRead => 'Отметить все как прочитанные';

  @override
  String get notificationsSectionTitle => 'Все уведомления';

  @override
  String notificationsUnreadSectionTitle(int count) {
    return '$count непрочитанных';
  }

  @override
  String notificationsError(String error) {
    return 'Ошибка уведомлений: $error';
  }

  @override
  String get notificationsEmptyTitle => 'Пока нет уведомлений';

  @override
  String get notificationsEmptySubtitle =>
      'Новые проекты, изменения и отправленные документы появятся здесь.';

  @override
  String get notificationsJustNow => 'Только что';

  @override
  String notificationsMinutesAgo(int minutes) {
    return '$minutes мин назад';
  }

  @override
  String notificationsHoursAgo(int hours) {
    return '$hours ч назад';
  }

  @override
  String notificationsDaysAgo(int days) {
    return '$days дн назад';
  }

  @override
  String get platformUsersSectionTitle => 'Пользователи и роли';

  @override
  String get platformColPhone => 'Телефон';

  @override
  String get platformColRole => 'Роль';

  @override
  String get platformColStatus => 'Статус';

  @override
  String get platformColActions => 'Действия';

  @override
  String platformBannedTooltip(String by, String reason) {
    return 'Заблокирован пользователем $by: $reason';
  }

  @override
  String get platformBannedLabel => 'Заблокирован';

  @override
  String get platformSetRoleTooltip => 'Назначить роль';

  @override
  String get platformSetRoleLabel => 'Назначить роль';

  @override
  String get platformUnban => 'Разблокировать';

  @override
  String get platformBan => 'Заблокировать';

  @override
  String get platformDeleteAdminTooltip =>
      'Удалить аккаунт администратора платформы';

  @override
  String platformDeleteAdminConfirmTitle(String phone) {
    return 'Удалить $phone?';
  }

  @override
  String get platformDeleteAdminConfirmBody =>
      'Аккаунт администратора платформы будет удалён без возможности восстановления, доступ будет отозван везде.';

  @override
  String get platformDeleteAdminConfirm => 'Удалить аккаунт';

  @override
  String get platformDeleteAdminSelfHint =>
      'Это ваш собственный аккаунт — войдите под другим админом, чтобы удалить его.';

  @override
  String platformBanDialogTitle(String phone) {
    return 'Блокировка $phone';
  }

  @override
  String get platformBanDialogUserFallback => 'пользователя';

  @override
  String get platformBanDialogBody =>
      'Это заморозит аккаунт везде, кроме собственного профиля и выхода из системы.';

  @override
  String get platformBanReasonLabel => 'Причина';

  @override
  String get platformBanReasonHint => 'Почему блокируется этот аккаунт?';

  @override
  String get platformBanByLabel => 'Кем заблокирован (имя)';

  @override
  String get platformBanByHint => 'Отображается пользователю в его аккаунте';

  @override
  String get platformBanConfirm => 'Заблокировать аккаунт';

  @override
  String get accountBannedTitle => 'Ваш аккаунт заблокирован';

  @override
  String get accountBannedBody =>
      'Аккаунт заморожен. Пока администратор платформы не снимет бан, доступны только это уведомление и выход из системы.';

  @override
  String get accountBannedReasonLabel => 'Причина';

  @override
  String accountBannedByLabel(String name) {
    return 'Заблокировал: $name';
  }

  @override
  String platformKycTitle(String name) {
    return 'KYC · $name';
  }

  @override
  String get kycCompanyName => 'Название компании';

  @override
  String get kycLegalName => 'Юридическое название';

  @override
  String get kycAccountKind => 'Тип аккаунта';

  @override
  String get kycLegalForm => 'Организационно-правовая форма';

  @override
  String get kycInn => 'ИНН';

  @override
  String get kycRegistrationNumber => 'Номер регистрации';

  @override
  String get kycOkedCode => 'Код ОКЭД';

  @override
  String get kycLegalAddress => 'Юридический адрес';

  @override
  String get kycOfficeAddress => 'Адрес офиса';

  @override
  String get kycRegion => 'Регион';

  @override
  String get kycEmail => 'Email';

  @override
  String get kycWebsite => 'Веб-сайт';

  @override
  String get kycDirectorFullName => 'ФИО директора';

  @override
  String get kycDirectorPinfl => 'ПИНФЛ директора';

  @override
  String get kycDirectorPassport => 'Паспорт директора';

  @override
  String get kycDirectorPhone => 'Телефон директора';

  @override
  String get kycDirectorEmail => 'Email директора';

  @override
  String get kycUboDeclared => 'UBO заявлен';

  @override
  String get kycUboFullName => 'ФИО конечного владельца';

  @override
  String get kycUboHelper =>
      'Конечный владелец — физическое лицо, которое в конечном счёте владеет компанией или контролирует её (обычно ≥25%).';

  @override
  String get kycConstructionLicense => 'Строительная лицензия';

  @override
  String get platformKycDocumentsTitle => 'Документы';

  @override
  String get platformKycDocumentsEmpty => 'Документы еще не загружены';

  @override
  String platformKycDocumentsError(String error) {
    return 'Ошибка документов: $error';
  }

  @override
  String get platformKycDocumentView => 'Открыть';

  @override
  String get platformKycDocumentAccept => 'Принять';

  @override
  String get platformKycDocumentReject => 'Отклонить';

  @override
  String get platformKycDocumentRejectDialogTitle => 'Отклонить документ';

  @override
  String get platformKycDocumentRejectReasonHint =>
      'Почему документ отклоняется?';

  @override
  String get residenceNewProjectDialogTitle => 'Новый проект';

  @override
  String get residenceNameHint => 'Название';

  @override
  String get residenceTypeHint => 'Тип недвижимости';

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
  String get residenceDistrictHint => 'Район';

  @override
  String get residenceDistrictOther => 'Другой (указать)';

  @override
  String get residenceDistrictOtherHint => 'Название района';

  @override
  String get residenceAddressHint => 'Адрес (улица, дом)';

  @override
  String get mapLocationTapHint =>
      'Нажмите на карту, чтобы указать расположение объекта';

  @override
  String get mapLocationManualHint => 'Или введите точные координаты';

  @override
  String get mapLocationLatitudeLabel => 'Широта';

  @override
  String get mapLocationLongitudeLabel => 'Долгота';

  @override
  String get mapLocationApplyCoordinates => 'Применить';

  @override
  String get mapLocationInvalidCoordinates =>
      'Укажите корректную широту (от -90 до 90) и долготу (от -180 до 180)';

  @override
  String mapLocationCoordinates(String lat, String lng) {
    return 'Координаты: $lat, $lng';
  }

  @override
  String get mapLocationZoomIn => 'Увеличить';

  @override
  String get mapLocationZoomOut => 'Уменьшить';

  @override
  String get residenceCreate => 'Создать';

  @override
  String get residenceCreatedSnackbar =>
      'Проект сохранён как черновик — отправьте на модерацию, когда будете готовы';

  @override
  String residencePublishingLocked(String price) {
    return 'Публикация заблокирована до оформления подписки (\$$price/мес). Вы всё же можете настроить профиль организации.';
  }

  @override
  String get residenceTitle => 'Администрирование ЖК';

  @override
  String get residenceSubtitle =>
      'Управляйте фондом, статусами юнитов, медиа и CRM заявок.';

  @override
  String get residenceNewProject => 'Новый проект';

  @override
  String get residenceProjectsSectionTitle => 'Ваши проекты';

  @override
  String get residenceNoProjects => 'Пока нет проектов';

  @override
  String get residenceNoProjectsSubtitle =>
      'Создайте проект и дождитесь одобрения платформы.';

  @override
  String residenceLoadError(String error) {
    return 'Ошибка загрузки (нужен одобренный застройщик + роль residence_admin): $error';
  }

  @override
  String residenceProjectMeta(
    String district,
    String moderation,
    String published,
  ) {
    return '$district · модерация: $moderation · опубликован: $published';
  }

  @override
  String get orgPlanUnlimited => 'неограничено';

  @override
  String get orgPlanActive => 'Активен';

  @override
  String get orgPlanCurrentPlan => 'Текущий тариф';

  @override
  String get orgPlanSubscribe => 'Подписаться';

  @override
  String orgPlanSummary(
    String price,
    String maxProjects,
    String maxUnits,
    String leads,
    String payPerLead,
  ) {
    return '\$$price/мес · $maxProjects проектов · $maxUnits юнитов · $leads заявок включено · \$$payPerLead/заявка сверх лимита';
  }

  @override
  String get orgTitle => 'Профиль организации';

  @override
  String get orgSubtitle =>
      'Настройте, как компания и ЖК отображаются покупателям. Публикация требует активной подписки \$299/мес.';

  @override
  String get orgNoProfile => 'Профиль организации пока не создан.';

  @override
  String orgError(String error) {
    return 'Ошибка: $error';
  }

  @override
  String orgLegalLine(String legalName, String inn) {
    return '$legalName · ИНН $inn';
  }

  @override
  String orgPaymentLabel(String status) {
    return 'Оплата: $status';
  }

  @override
  String get orgPublishingUnlocked => ' · публикация разблокирована';

  @override
  String get orgPublishingLocked => ' · публикация заблокирована';

  @override
  String get orgSubscriptionPlansTitle => 'Тарифы подписки';

  @override
  String get orgSubscriptionPlansSubtitle =>
      'Выберите тариф по количеству публикуемых проектов/юнитов и включённых заявок до оплаты за каждую сверх лимита.';

  @override
  String orgPlansError(String error) {
    return 'Ошибка тарифов: $error';
  }

  @override
  String get orgDocumentsTitle => 'Документы верификации';

  @override
  String get orgDocumentsSubtitle =>
      'Загрузите все 4 обязательных документа и дождитесь их принятия платформой — после этого покупателям будет виден значок «Проверено».';

  @override
  String orgDocumentsError(String error) {
    return 'Ошибка документов: $error';
  }

  @override
  String get orgDocumentNotUploaded => 'Не загружен';

  @override
  String get orgDocumentUpload => 'Загрузить';

  @override
  String get orgDocumentReplace => 'Заменить';

  @override
  String orgDocumentUploading(int percent) {
    return 'Загрузка… $percent%';
  }

  @override
  String get orgDocumentUploaded =>
      'Документ загружен — ожидает проверки платформой.';

  @override
  String orgDocumentUploadError(String error) {
    return 'Ошибка загрузки: $error';
  }

  @override
  String orgDocumentRejectReason(String reason) {
    return 'Отклонено: $reason';
  }

  @override
  String get orgDocumentView => 'Открыть';

  @override
  String get orgDocumentConfirmTitle => 'Подтвердите отправку';

  @override
  String orgDocumentConfirmMessage(String type) {
    return 'Внимательно проверьте этот документ ($type) — после отправки его увидит команда платформы.';
  }

  @override
  String get orgDocumentConfirmSend => 'Отправить на проверку';

  @override
  String get orgDocumentOptionalSectionTitle => 'Необязательные документы';

  @override
  String get orgDocumentOptionalBadge => 'Необязательно';

  @override
  String get orgPublicPresenceTitle => 'Публичный профиль';

  @override
  String get orgAboutHint => 'О вашей организации / ЖК';

  @override
  String get orgOfficeHint => 'Адрес отдела продаж';

  @override
  String get orgWebsiteHint => 'Веб-сайт';

  @override
  String get orgLogoHint => 'URL логотипа';

  @override
  String get orgCoverHint => 'URL обложки';

  @override
  String get orgBrandColorHint => 'Фирменный цвет (например, #1A1A1A)';

  @override
  String get orgSaveProfile => 'Сохранить профиль';

  @override
  String get orgSavedMessage => 'Профиль сохранён.';

  @override
  String get orgPlanDetailsShow => 'Показать детали видимости';

  @override
  String get orgPlanDetailsHide => 'Скрыть детали видимости';

  @override
  String get orgPlanAlwaysOnTopTitle => 'Видимость «Всегда наверху»';

  @override
  String get orgPlanAlwaysOnTopSubtitle =>
      'Пока подписка активна, объявления ранжируются с коэффициентом усиления 0.4. После окончания подписки усиление снижается до 0.04 в течение двух недель.';

  @override
  String get orgPlanDecayActiveLegend => 'Активна (0.4)';

  @override
  String get orgPlanDecayExpiredLegend => 'После окончания (→0.04)';

  @override
  String get orgPlanDecayWeeksAxis => 'Недели от окончания';

  @override
  String get orgPlanDecayCoefficientAxis => 'Усиление';

  @override
  String get orgAiSectionTitle => 'Шаблон черновика описания';

  @override
  String get orgAiSectionSubtitle =>
      'Добавьте ссылки и, при желании, презентацию компании — по шаблону будет составлен черновик (это не написано ИИ), отредактируйте его перед сохранением.';

  @override
  String get orgAiWebsiteHint => 'URL веб-сайта';

  @override
  String get orgAiInstagramHint => 'URL Instagram';

  @override
  String get orgAiPickPdf => 'Прикрепить PDF компании';

  @override
  String orgAiPdfSelected(String name) {
    return 'Прикреплено: $name';
  }

  @override
  String get orgAiGenerate => 'Составить черновик по шаблону';

  @override
  String get orgAiGenerating => 'Составление…';

  @override
  String get orgAiApply => 'Использовать этот черновик';

  @override
  String get orgAiResultHint => 'Черновик по шаблону (редактируемый)';

  @override
  String get orgAiNoInputs => 'Сначала добавьте веб-сайт, Instagram или PDF.';

  @override
  String get orgAiApplied => 'Черновик применён — проверьте и сохраните.';

  @override
  String get projectLoadError => 'Не удалось загрузить проект';

  @override
  String get projectBack => 'Назад';

  @override
  String projectModerationLabel(String status) {
    return 'Модерация: $status';
  }

  @override
  String get projectModerationStatusDraft => 'Черновик';

  @override
  String get projectModerationStatusPending => 'На рассмотрении';

  @override
  String get projectModerationStatusRejected => 'Отклонён';

  @override
  String get projectSubmitForReview => 'Отправить на рассмотрение';

  @override
  String get projectDraftBanner =>
      'ЖК сохранён как черновик. Заполните данные и отправьте на модерацию платформы, когда будете готовы.';

  @override
  String get projectRejectedBanner =>
      'ЖК отклонён. Исправьте замечания платформы и отправьте снова.';

  @override
  String get projectWarningBanner => 'Предупреждение от платформы';

  @override
  String get projectWarningBannerSubtitle =>
      'Исправьте замечания ниже. ЖК остаётся опубликованным, пока платформа не снимет его с публикации.';

  @override
  String get residenceProjectWarned => 'Есть предупреждение платформы';

  @override
  String get projectUnpublish => 'Снять с публикации';

  @override
  String get projectPublish => 'Опубликовать';

  @override
  String get projectRepublish => 'Переопубликовать';

  @override
  String get projectUnpublishConfirm =>
      'ЖК исчезнет из каталога B2C. Продолжить?';

  @override
  String get projectPublishSuccess => 'ЖК снова в каталоге';

  @override
  String get projectUnpublishSuccess => 'ЖК снят с публикации';

  @override
  String get projectDelete => 'Удалить ЖК';

  @override
  String projectDeleteConfirmTitle(String name) {
    return 'Удалить «$name»?';
  }

  @override
  String get projectDeleteConfirmBody =>
      'Это необратимо: корпуса, юниты, акции и заявки по этому ЖК будут удалены.';

  @override
  String get projectDeleteSuccess => 'ЖК удалён';

  @override
  String get projectPublishNeedsReview =>
      'Сначала отправьте ЖК на модерацию платформы';

  @override
  String get projectPublishNeedsSubscription =>
      'Нужна активная подписка, чтобы опубликовать ЖК';

  @override
  String get navActiveProjects => 'Активные ЖК';

  @override
  String get activeProjectsTitle => 'Активные ЖК';

  @override
  String get activeProjectsSubtitle =>
      'Опубликованные комплексы в каталоге — предупреждения и снятие с публикации.';

  @override
  String get projectSubmitForReviewSuccess =>
      'Отправлено на модерацию — ожидает рассмотрения платформой.';

  @override
  String get projectLocationSectionTitle => 'Расположение на карте';

  @override
  String get projectLocationSave => 'Сохранить точку';

  @override
  String get projectLocationSaved => 'Расположение сохранено';

  @override
  String projectPublishedLabel(String value) {
    return 'Опубликован: $value';
  }

  @override
  String get publishedYes => 'Да';

  @override
  String get publishedNo => 'Нет';

  @override
  String platformProjectDeveloper(String name) {
    return 'Застройщик: $name';
  }

  @override
  String get projectAnalyticsTitle => 'Аналитика';

  @override
  String get projectOffersTitle => 'Акции';

  @override
  String get projectAddOffer => 'Добавить акцию';

  @override
  String get projectNoOffers => 'Нет активных акций';

  @override
  String get projectNoOffersSubtitle =>
      'Добавьте скидку, план рассрочки или промо на аренду.';

  @override
  String get projectRemoveOfferTooltip => 'Удалить акцию';

  @override
  String get projectUnitsTitle => 'Юниты';

  @override
  String get projectAddBuilding => 'Добавить корпус';

  @override
  String get projectBulkAddUnits => 'Массовое добавление юнитов';

  @override
  String get projectViewToggleList => 'Список';

  @override
  String get projectViewToggleChessboard => 'Шахматка';

  @override
  String get projectBuildingFallback => 'Корпус';

  @override
  String projectUnitLabel(String number) {
    return 'Юнит $number';
  }

  @override
  String projectUnitLabelWithStatus(String number, String status) {
    return 'Юнит $number · $status';
  }

  @override
  String projectUnitMetaLine(
    String kind,
    String dealType,
    String status,
    String mediaCount,
  ) {
    return '$kind · $dealType · $status · медиа: $mediaCount';
  }

  @override
  String projectUnitMetaLineNoStatus(
    String kind,
    String dealType,
    String mediaCount,
  ) {
    return '$kind · $dealType · медиа: $mediaCount';
  }

  @override
  String get projectAddMediaUrl => 'Добавить URL медиа';

  @override
  String get projectStatusButton => 'Статус';

  @override
  String get projectChangeStatusButton => 'Изменить статус';

  @override
  String get projectLeadCrmTitle => 'CRM заявок';

  @override
  String get projectKanbanHint =>
      'Перетащите карточку в другую колонку, чтобы изменить статус.';

  @override
  String get projectNoLeads => 'Пока нет заявок';

  @override
  String projectLeadSummary(String number, String intent, String status) {
    return '$number · $intent · $status';
  }

  @override
  String projectLeadContactLine(String phone, String message) {
    return '$phone · $message';
  }

  @override
  String get projectUpdateLeadStatus => 'Обновить';

  @override
  String get projectTagsScoreTooltip => 'Теги и оценка';

  @override
  String get projectNewBuildingDialogTitle => 'Добавить корпус';

  @override
  String get projectBuildingNameLabel => 'Название';

  @override
  String get projectFloorsLabel => 'Этажи';

  @override
  String get projectMediaUrlHint => 'https://...';

  @override
  String get projectAddBuildingFirstSnackbar => 'Сначала добавьте корпус';

  @override
  String projectUnitsAddedSnackbar(String count) {
    return 'Добавлено юнитов: $count';
  }

  @override
  String projectUnitsPartiallyAddedSnackbar(String count, String error) {
    return 'Остановлено после добавления $count юнитов: $error';
  }

  @override
  String get projectOfferEditorTitle => 'Добавить акцию';

  @override
  String get projectOfferTypeLabel => 'Тип';

  @override
  String get projectOfferTitleLabel => 'Заголовок';

  @override
  String get projectOfferDescriptionLabel => 'Описание';

  @override
  String get projectDownPaymentLabel => 'Первоначальный взнос %';

  @override
  String get projectTermMonthsLabel => 'Срок (месяцев)';

  @override
  String get projectInterestRateLabel => 'Процентная ставка %';

  @override
  String get projectBulkUnitsDialogTitle => 'Массовое добавление юнитов';

  @override
  String get projectBuildingLabel => 'Корпус';

  @override
  String get projectFloorFromLabel => 'Этаж от';

  @override
  String get projectFloorToLabel => 'Этаж до';

  @override
  String get projectUnitsPerFloorLabel => 'Юнитов на этаже';

  @override
  String get projectStartingNumberLabel => 'Начальный номер';

  @override
  String get projectKindLabel => 'Тип';

  @override
  String get projectDealLabel => 'Сделка';

  @override
  String get projectAreaLabel => 'Площадь (м²)';

  @override
  String get projectRoomsLabel => 'Комнаты';

  @override
  String get projectPriceLabel => 'Цена (\$)';

  @override
  String get projectPriceM2Label => 'Цена/м²';

  @override
  String get chessboardFilterAll => 'Все типы';

  @override
  String get chessboardRoomsLegendTitle => 'Комнаты:';

  @override
  String get chessboardRooms4Plus => '4+';

  @override
  String get projectRentLabel => 'Аренда/мес (\$)';

  @override
  String get projectGenerate => 'Создать';

  @override
  String get projectLegendSoldRented => 'продано / сдано';

  @override
  String get projectLeadsStat => 'Заявки (30 дн.)';

  @override
  String get projectLeadsTotalStat => 'Заявок всего';

  @override
  String get projectSellThroughStat => 'Продано, %';

  @override
  String get projectMonthsToSellOutStat => 'Прогноз распродажи, мес.';

  @override
  String get projectUnitsStat => 'Юниты';

  @override
  String get projectLeadFunnelTitle => 'Воронка заявок';

  @override
  String get projectUnitsByStatusTitle => 'Юниты по статусу';

  @override
  String get projectPhotoReportsTitle => 'Фотоотчёты о строительстве';

  @override
  String get projectPhotoReportsSubtitle =>
      'Датированные фото объекта, сгруппированные по месяцам, с необязательным процентом готовности.';

  @override
  String get projectAddPhotoReport => 'Добавить фото';

  @override
  String get projectPhotoReportsEmpty => 'Пока нет фотоотчётов';

  @override
  String projectPhotoReportUploading(int percent) {
    return 'Загрузка… $percent%';
  }

  @override
  String projectPhotoReportUploadError(String error) {
    return 'Ошибка загрузки: $error';
  }

  @override
  String get projectPhotoReportDialogTitle => 'Добавить фотоотчёт';

  @override
  String get projectPhotoReportDateLabel => 'Дата съёмки';

  @override
  String get projectPhotoReportProgressLabel =>
      'Процент готовности (необязательно)';

  @override
  String get projectPhotoReportDeleteTooltip => 'Удалить фотоотчёт';

  @override
  String projectPhotoReportProgressBadge(int percent) {
    return '$percent%';
  }

  @override
  String get statusAvailable => 'свободен';

  @override
  String get statusReserved => 'забронирован';

  @override
  String get statusSold => 'продан';

  @override
  String get statusRented => 'сдан';

  @override
  String get statusBlocked => 'заблокирован';

  @override
  String get offerTypeDiscount => 'скидка';

  @override
  String get offerTypeInstallment => 'рассрочка';

  @override
  String get offerTypeRentPromo => 'промо на аренду';

  @override
  String get unitKindApartment => 'квартира';

  @override
  String get unitKindOffice => 'офис';

  @override
  String get unitKindRetail => 'торговое помещение';

  @override
  String get dealTypeSale => 'продажа';

  @override
  String get dealTypeRent => 'аренда';

  @override
  String get leadScoreHot => 'горячий';

  @override
  String get leadScoreWarm => 'тёплый';

  @override
  String get leadScoreCold => 'холодный';

  @override
  String get leadStatusNew => 'новый';

  @override
  String get leadStatusContacted => 'связались';

  @override
  String get leadStatusScheduled => 'запланирован';

  @override
  String get leadStatusVisited => 'посетил';

  @override
  String get leadStatusWon => 'успешно';

  @override
  String get leadStatusLost => 'отказ';

  @override
  String get roleOrdinaryUser => 'обычный пользователь';

  @override
  String get roleResidenceAdmin => 'админ ЖК';

  @override
  String get roleSystemAdmin => 'администратор платформы';

  @override
  String get leadStatusQualified => 'квалифицирован';

  @override
  String get documentTypeLicense => 'Лицензия';

  @override
  String get documentTypeLicenseHint =>
      'Лицензия на строительную деятельность, подтверждающая, что компания имеет законное право выступать застройщиком.';

  @override
  String get documentTypeConstructionPermit => 'Разрешение на строительство';

  @override
  String get documentTypeConstructionPermitHint =>
      'Официальное разрешение местного органа власти на строительство именно этого объекта.';

  @override
  String get documentTypeLandRights => 'Права на землю';

  @override
  String get documentTypeLandRightsHint =>
      'Документ, подтверждающий право собственности или долгосрочной аренды на земельный участок под застройку.';

  @override
  String get documentTypeProjectDeclaration => 'Проектная декларация';

  @override
  String get documentTypeProjectDeclarationHint =>
      'Декларация с описанием проекта: сроки, характеристики объекта и застройщика — обычно требуется для долевого строительства.';

  @override
  String get documentTypeCadastre => 'Кадастр';

  @override
  String get documentTypeCadastreHint =>
      'Кадастровый паспорт участка с его точными границами и учётными данными.';

  @override
  String get documentStatusPending => 'На проверке';

  @override
  String get documentStatusAccepted => 'Принято';

  @override
  String get documentStatusRejected => 'Отклонено';

  @override
  String get navModeration => 'Модерация';

  @override
  String get navCrm => 'CRM';

  @override
  String get navTickets => 'Тикеты';

  @override
  String get moderationTitle => 'Модерация';

  @override
  String get moderationSubtitle =>
      'Новые заявки на ЖК, ожидающие проверки, и жалобы на отзывы.';

  @override
  String get adminProjectsTitle => 'Администрирование ЖК';

  @override
  String get adminProjectsSubtitle =>
      'Все жилые комплексы и бизнес-центры на платформе — как оформлены и что к ним прикреплено. Администратор платформы не владеет проектами.';

  @override
  String get adminProjectsFilterAll => 'Все';

  @override
  String get adminProjectsFilterPending => 'На модерации';

  @override
  String get adminProjectsFilterApproved => 'Одобрено';

  @override
  String get adminProjectsFilterRejected => 'Отклонено';

  @override
  String get adminProjectsEmpty => 'Нет проектов по этому фильтру';

  @override
  String adminProjectsMeta(int count, String units) {
    return '$count фото · $units юнитов';
  }

  @override
  String get adminProjectsUnpublished => 'Снят с публикации';

  @override
  String get crmTitle => 'CRM';

  @override
  String get crmSubtitle =>
      'Все обращения по всем ЖК — общий спрос на платформе, а не только по одному проекту.';

  @override
  String get crmKanbanHint =>
      'Перетащите карточку в другую колонку, чтобы изменить статус.';

  @override
  String get crmSearchHint => 'Поиск по телефону, проекту или менеджеру';

  @override
  String get crmEmpty => 'Нет обращений по этому фильтру';

  @override
  String get crmEdit => 'Изменить';

  @override
  String crmAssignedTo(String name) {
    return 'Ответственный: $name';
  }

  @override
  String get crmStatusLabel => 'Статус';

  @override
  String get crmScoreLabel => 'Оценка';

  @override
  String get crmAssignedManagerLabel => 'Ответственный менеджер';

  @override
  String get crmNotesLabel => 'Заметки';

  @override
  String get crmOwnerLabel => 'Владелец';

  @override
  String get crmOwnerUnassigned => 'Не назначен';

  @override
  String get crmOwnerFilterAll => 'Все лиды';

  @override
  String get crmOwnerFilterMine => 'Мои лиды';

  @override
  String get crmOwnerFilterUnassigned => 'Без владельца';

  @override
  String get crmAssignToMe => 'Назначить мне';

  @override
  String get crmAssigneesLoadError => 'Не удалось загрузить менеджеров';

  @override
  String get crmTransferLabel => 'Передать';

  @override
  String get crmTransferHint => 'Передать другому менеджеру';

  @override
  String get crmTransferNone => 'Без передачи';

  @override
  String get crmTransferNoteLabel => 'Комментарий к передаче';

  @override
  String get crmLeadEditorTitle => 'CRM лида';

  @override
  String get crmTagsLabel => 'Теги (через запятую)';

  @override
  String get crmEventHistoryTitle => 'История';

  @override
  String get crmEventHistoryEmpty => 'Пока нет событий';

  @override
  String get crmEventAssigned => 'Назначен';

  @override
  String get crmEventTransferred => 'Передан';

  @override
  String get crmEventUnassigned => 'Снят владелец';

  @override
  String crmEventStatusChanged(String detail) {
    return 'Статус: $detail';
  }

  @override
  String get crmEventNote => 'Добавлена заметка';

  @override
  String get ticketsTitle => 'Тикеты';

  @override
  String get ticketsSubtitle =>
      'Обращения от покупателей, арендаторов, застройщиков и администраторов ЖК.';

  @override
  String get ticketsEmpty => 'Тикетов пока нет';

  @override
  String get ticketStatusOpen => 'Открыт';

  @override
  String get ticketStatusInProgress => 'В работе';

  @override
  String get ticketStatusResolved => 'Решён';

  @override
  String get ticketStatusClosed => 'Закрыт';

  @override
  String get ticketCategoryBilling => 'Оплата';

  @override
  String get ticketCategoryModeration => 'Модерация';

  @override
  String get ticketCategoryTechnical => 'Техническое';

  @override
  String get ticketCategoryOther => 'Другое';

  @override
  String get ticketReplyHint => 'Написать ответ…';

  @override
  String get ticketSend => 'Отправить';

  @override
  String get ticketNew => 'Новый тикет';

  @override
  String get ticketSubjectHint => 'Тема';

  @override
  String get ticketMessageHint => 'Опишите вопрос или проблему';

  @override
  String get supportTicketsSubtitle =>
      'Свяжитесь с командой платформы — оплата, модерация или техническая проблема.';
}
