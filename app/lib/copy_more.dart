part of 'l10n.dart';

/// Text for the side panels, the loan tools and the smaller screens.
extension MoreCopy on AppCopy {
  // ── Menu and top bars ──────────────────────────────────────────────────

  String get bankInspections => inspections;
  String get collapseMenu => _t(('Свернуть меню', 'Collapse the menu', 'Menyuni yig‘ish'));
  String get expandMenu => _t(('Развернуть меню', 'Expand the menu', 'Menyuni ochish'));
  String get lightTheme => _t(('Светлая тема', 'Light theme', 'Yorug‘ mavzu'));
  String get darkTheme => _t(('Тёмная тема', 'Dark theme', 'Qorong‘i mavzu'));
  String get project => _t(('Объект', 'Project', 'Obyekt'));
  String get pickProject => _t(('Выберите объект', 'Pick a project', 'Obyektni tanlang'));
  String fxDate(String date) => _t((
    'Курс ЦБ на $date',
    'Central Bank rate, $date',
    'Markaziy bank kursi, $date',
  ));

  // ── Project card on the right ──────────────────────────────────────────

  String get changesOnReview => _t((
    'Изменения на проверке',
    'Changes under review',
    'O‘zgarishlar tekshirilmoqda',
  ));
  String get changesRejected => _t((
    'Изменения отклонены',
    'Changes rejected',
    'O‘zgarishlar rad etildi',
  ));
  String get projectCard => _t(('Карточка объекта', 'Project card', 'Obyekt kartasi'));
  String get projectPhoto => _t(('Фото объекта', 'Project photo', 'Obyekt fotosi'));
  String get photoPicked => _t(('Фото выбрано', 'Photo chosen', 'Foto tanlandi'));
  String get sendForReview => _t(('Отправить на проверку', 'Send for review', 'Tekshiruvga yuborish'));
  String get projectPhotoRule => _t((
    'JPEG, PNG или WebP · до 5 МБ.',
    'JPEG, PNG or WebP · up to 5 MB.',
    'JPEG, PNG yoki WebP · 5 MB gacha.',
  ));
  String get projectCardNote => _t((
    'Изменения опубликуются после одобрения администратором iBuild.',
    'Changes appear on the project card once an iBuild administrator approves them.',
    'iBuild administratori tasdiqlagach, o‘zgarishlar obyekt kartasida ko‘rinadi.',
  ));

  // ── Home ───────────────────────────────────────────────────────────────

  String get projectsCardTitle => _t(('Мои объекты', 'My projects', 'Mening obyektlarim'));
  String get sitesCardTitle => inspections;

  // ── Project passport ───────────────────────────────────────────────────

  String developerIs(String name) => _t((
    'Застройщик: $name',
    'Developer: $name',
    'Quruvchi: $name',
  ));
  String bankIs(String name) => _t(('Банк: $name', 'Bank: $name', 'Bank: $name'));

  // ── Money tables ───────────────────────────────────────────────────────

  String get moneyPlan => _t((
    'План финансирования',
    'Funding plan',
    'Moliyalashtirish rejasi',
  ));
  String get sources => _t((
    'Источники финансирования',
    'Funding sources',
    'Moliyalashtirish manbalari',
  ));

  String sourceKind(String kind) {
    return switch (kind) {
      'loan' => _t(('Кредит', 'Loan', 'Kredit')),
      'equity' => _t(('Свои деньги', 'Own money', 'O‘z mablag‘i')),
      'escrow' => _t(('Эскроу', 'Escrow', 'Eskrou')),
      _ => kind,
    };
  }
  String get uses => _t(('Виды работ', 'Work items', 'Ish turlari'));
  String costKind(String kind) {
    return switch (kind) {
      'hard' => _t(('Стройка', 'Construction', 'Qurilish')),
      'soft' => _t(('Прочие расходы', 'Other costs', 'Boshqa xarajatlar')),
      'contingency' => _t(('Резерв', 'Reserve', 'Zaxira')),
      '' => '',
      _ => kind,
    };
  }

  String holdback(String percent, String done) {
    final keep = _t((
      'Придерживаем $percent% до конца работ',
      'Holding back $percent% until the work ends',
      'Ish tugaguncha $percent% ushlab turiladi',
    ));
    if (done.trim().isEmpty || done.trim() == '—') return keep;
    return _t((
      'Придерживаем $percent% до конца работ · готово $done%',
      'Holding back $percent% until the work ends · $done% done',
      'Ish tugaguncha $percent% ushlab turiladi · tayyorlik $done%',
    ));
  }

  String get connectBank => _t(('Подключить банк', 'Connect a bank', 'Bankni ulash'));
  String get bankInn => _t(('ИНН банка', 'Bank tax ID', 'Bank STIR'));
  String get setCreditLimit => _t(('Назначить кредитный лимит', 'Set the credit limit', 'Kredit limitini belgilash'));
  String get addLineNeedsFirm => _t((
    'Чтобы добавить вид работ, сначала создайте карточку подрядчика.',
    'Create a contractor record before adding a work item.',
    'Ish turini qo‘shishdan oldin pudratchi kartasini yarating.',
  ));

  String get noSourcesDirector => _t((
    'Добавьте источник финансирования в бюджете объекта. Без него отправить транш нельзя.',
    'Add a funding source in the project budget before submitting a tranche.',
    'Transhni yuborishdan oldin obyekt byudjetiga moliyalashtirish manbasini qo‘shing.',
  ));

  String get noSourcesOther => _t((
    'Попросите застройщика добавить источник финансирования в бюджет объекта.',
    'Ask the developer to add a funding source to the project budget.',
    'Quruvchidan obyekt byudjetiga moliyalashtirish manbasini qo‘shishini so‘rang.',
  ));
  String get gridOriginal => _t((
    'Исходный бюджет',
    'Original budget',
    'Dastlabki byudjet',
  ));
  String get gridChanges => _t(('Изменения', 'Changes', 'O‘zgarishlar'));
  String get gridNow => _t((
    'Текущий бюджет',
    'Current budget',
    'Joriy byudjet',
  ));
  String get gridPaid => _t(('Выплачено', 'Paid out', 'To‘langan'));
  String get gridLeft => _t(('Осталось', 'Left', 'Qoldi'));

  // ── Budget import ──────────────────────────────────────────────────────

  String get importBudget => _t((
    'Импортировать бюджет',
    'Import budget',
    'Byudjetni import qilish',
  ));
  String get importFormat => _t((
    'В каждой строке через запятую: код, название, вид (hard — стройка, soft — прочие расходы), use (расход) или source (источник денег), сумма.',
    'One line per item, separated by commas: code, name, kind (hard for construction, soft for other costs), use (a cost) or source (where money comes from), amount.',
    'Har bir qatorda vergul bilan: kod, nom, tur (hard — qurilish, soft — boshqa xarajatlar), use (xarajat) yoki source (pul manbasi), summa.',
  ));
  String get importText => _t(('Список (CSV)', 'List (CSV)', 'Ro‘yxat (CSV)'));
  String get templateName => _t(('Название шаблона', 'Template name', 'Shablon nomi'));
  String get copyFromProject => _t(('Взять бюджет с другого объекта', 'Copy the budget from another project', 'Byudjetni boshqa obyektdan olish'));
  String get doImport => _t(('Загрузить', 'Import', 'Yuklash'));
  String get saveTemplate => _t(('Сохранить как шаблон', 'Save as a template', 'Shablon sifatida saqlash'));
  String get doCopy => _t(('Скопировать', 'Copy', 'Nusxalash'));

  // ── Tranches inside a project ──────────────────────────────────────────

  String get drawsEmptyBody => _t((
    'В один транш можно включить несколько видов работ.',
    'A tranche can include more than one work item.',
    'Bir transhga bir nechta ish turini kiritish mumkin.',
  ));
  String get drawRequested => _t(('Запрошено', 'Requested', 'So‘ralgan'));
  String get drawRecommended => _t(('Рекомендует инспектор', 'Inspector recommends', 'Inspektor tavsiyasi'));
  String get drawApproved => _t(('Одобрено банком', 'Approved by the bank', 'Bank ma’qullagan'));

  // ── Inspection report inside a project ─────────────────────────────────

  String gateCodeIs(String code) => _t(('Код от ворот: $code', 'Gate code: $code', 'Darvoza kodi: $code'));
  String get gateCode => _t(('Код от ворот', 'Gate code', 'Darvoza kodi'));
  String get noteToInspector => _t(('Комментарий для инспектора', 'Note for the inspector', 'Inspektor uchun izoh'));
  String get percentDone => _t(('Готово, %', 'Done, %', 'Tayyor, %'));
  String get recommendAmount => _t((
    'Рекомендуемая сумма выплаты, сум',
    'Recommended payout, UZS',
    'Tavsiya etilgan to‘lov summasi, so‘m',
  ));
  String get riskNone => _t(('Без отметки о риске', 'No risk mark', 'Xavf belgisisiz'));
  String get riskOk => _t(('Риск низкий', 'Low risk', 'Xavf past'));
  String get riskWatch => _t((
    'Требует контроля',
    'Needs monitoring',
    'Nazorat talab etiladi',
  ));
  String get riskHigh => _t(('Риск высокий', 'High risk', 'Xavf yuqori'));
  String get inspectorComment => _t(('Комментарий инспектора', 'Inspector’s comment', 'Inspektor izohi'));
  String get sendInspection => _t(('Отправить отчёт об осмотре', 'Send the inspection report', 'Ko‘rik hisobotini yuborish'));

  // ── Documents ──────────────────────────────────────────────────────────

  String get documentsBank => _t((
    'Требования банка к документам',
    'Bank document requirements',
    'Bankning hujjatlarga talablari',
  ));
  String get requiredYes => _t(('Обязательно', 'Required', 'Majburiy'));
  String get requiredNo => _t(('По желанию', 'Optional', 'Ixtiyoriy'));
  String documentTitle(String code, String fallback) {
    return switch (code) {
      'act' => _t(('Акт выполненных работ', 'Certificate of completed work', 'Bajarilgan ishlar dalolatnomasi')),
      'invoice' => _t(('Счёт от подрядчика', 'Contractor’s invoice', 'Pudratchi hisob-fakturasi')),
      'retainage_log' => _t(('Список придержанных сумм', 'List of held-back amounts', 'Ushlab turilgan summalar ro‘yxati')),
      'stored_log' => _t(('Материалы на площадке', 'Materials on site', 'Maydondagi materiallar')),
      'waiver' => _t(('Справка, что претензий нет', 'Statement that there are no claims', 'Da’vo yo‘qligi haqida ma’lumotnoma')),
      _ => fallback,
    };
  }

  String insuranceUntilIs(String date) => _t((
    'Страховка действует до $date',
    'Insurance valid until $date',
    'Sug‘urta $date gacha amal qiladi',
  ));
  String licenseUntilIs(String date) => _t((
    'Лицензия действует до $date',
    'Licence valid until $date',
    'Litsenziya $date gacha amal qiladi',
  ));
  String get contractorDates => _t((
    'Сроки документов подрядчика',
    'Contractor’s document dates',
    'Pudratchi hujjatlari muddati',
  ));
  String get insuranceUntilLabel => _t(('Страховка действует до', 'Insurance valid until', 'Sug‘urta amal qilish muddati'));
  String get licenseUntilLabel => _t(('Лицензия действует до', 'Licence valid until', 'Litsenziya amal qilish muddati'));
  String get saveDates => _t(('Сохранить сроки', 'Save the dates', 'Muddatlarni saqlash'));

  // ── Tranche card ───────────────────────────────────────────────────────

  String get orderInspection => _t((
    'Назначить осмотр',
    'Schedule inspection',
    'Ko‘rikni tayinlash',
  ));
  String inspectionNote(String line) => _t((
    'Проверить: $line',
    'Check: $line',
    'Tekshirish: $line',
  ));
  String get contactTitle => _t(('Написать застройщику', 'Write to the developer', 'Quruvchiga yozish'));
  String get contactMessage => _t(('Сообщение', 'Message', 'Xabar'));
  String get contactSend => _t(('Отправить', 'Send', 'Yuborish'));
  String get contactSent => _t((
    'Сообщение отправлено застройщику',
    'The message was sent to the developer',
    'Xabar quruvchiga yuborildi',
  ));
  String whatWasDone(String text) => _t(('Что сделано: $text', 'What was done: $text', 'Nima qilingan: $text'));
  String paymentOn(String number, String date) => _t((
    'Платёж № $number от $date',
    'Payment no. $number from $date',
    '$date dagi $number-to‘lov',
  ));

  // ── Tranche wizard ─────────────────────────────────────────────────────

  String get drawDefaultName => _t(('Транш', 'Tranche', 'Transh'));
  String get toProject => _t(('К объекту', 'Back to the project', 'Obyektga'));
  String get drawWizardTitle => _t((
    'Транш по бюджету объекта',
    'Project budget tranche',
    'Obyekt byudjeti bo‘yicha transh',
  ));
  String get drawName => _t(('Название транша', 'Tranche name', 'Transh nomi'));
  String get finalDraw => _t((
    'Заключительный транш',
    'Final tranche',
    'Yakuniy transh',
  ));
  String get drawHoldback => _t((
    'Удержание до завершения работ',
    'Retention until completion',
    'Ishlar tugaguncha ushlab qolinadigan summa',
  ));
  String get drawHoldbackRelease => _t((
    'К возврату из удержания',
    'Retention to release',
    'Ushlab qolingan summadan qaytarish',
  ));
  String get drawStored => _t(('Материалы на площадке', 'Materials on site', 'Maydondagi materiallar'));
  String get drawShift => _t(('Перенести между видами работ', 'Move between work items', 'Ish turlari orasida ko‘chirish'));
  String inspectorSays(String value) => _t((
    'Инспектор рекомендует: $value',
    'The inspector recommends: $value',
    'Inspektor tavsiyasi: $value',
  ));
  String get drawApprovedField => _t(('Одобрено', 'Approved', 'Ma’qullangan'));
  String get docMissing => _t(('Не хватает', 'Missing', 'Yetishmaydi'));
  String get docAttached => _t(('Приложен', 'Attached', 'Qo‘shilgan'));
  String get docNotNeeded => _t(('Не нужен', 'Not needed', 'Kerak emas'));
  String get signature => _t((
    'ФИО ответственного',
    'Name of the person submitting',
    'Mas’ul shaxsning F.I.Sh.',
  ));
  String get trimDraw => _t(('Уменьшить транш', 'Reduce the tranche', 'Transhni kamaytirish'));
  String get afterSending => _t(('После отправки', 'After sending', 'Yuborilgandan keyin'));
  String get commentLabel => _t(('Комментарий', 'Comment', 'Izoh'));
  String get sendComment => _t(('Отправить комментарий', 'Send the comment', 'Izohni yuborish'));
  String get contractorInvoice => _t(('Счёт подрядчика', 'Contractor’s invoice', 'Pudratchi hisobi'));
  String get invoiceAmount => _t(('Сумма счёта', 'Invoice amount', 'Hisob summasi'));
  String get saveInvoice => _t((
    'Сохранить счёт и справку об отсутствии претензий',
    'Save the invoice and the no-claims statement',
    'Hisob va da’vo yo‘qligi haqidagi ma’lumotnomani saqlash',
  ));
  String get downloadPackage => _t(('Скачать документы транша', 'Download the tranche documents', 'Transh hujjatlarini yuklab olish'));

  // ── Inspections page ───────────────────────────────────────────────────

  String get inspectionsSubtitle => _t((
    'Назначенные осмотры и отчёты о выполненных работах.',
    'Scheduled inspections and reports on completed work.',
    'Tayinlangan ko‘riklar va bajarilgan ishlar bo‘yicha hisobotlar.',
  ));
  String get inspectionsEmpty => _t(('Осмотров пока нет', 'No inspections yet', 'Hozircha ko‘riklar yo‘q'));
  String get inspectionsEmptyBody => _t((
    'Здесь появятся осмотры по вашим объектам.',
    'Inspections for your projects will appear here.',
    'Obyektlaringiz bo‘yicha ko‘riklar shu yerda ko‘rinadi.',
  ));
  String get inspectionOrdered => _t((
    'Назначен',
    'Scheduled',
    'Tayinlangan',
  ));
  String get inspectionReported => _t(('Отчёт получен', 'Report received', 'Hisobot olindi'));
  String forTranche(String line) => _t(('По траншу: $line', 'For tranche: $line', 'Transh bo‘yicha: $line'));
  String get openProjectWithLimit => _t((
    'Сначала откройте объект, для которого банк назначил лимит.',
    'First open a project for which the bank has set a limit.',
    'Avval bank limit belgilagan obyektni oching.',
  ));
  String get dateHint => _t(('Например, 2026-11-05', 'For example, 2026-11-05', 'Masalan, 2026-11-05'));
  String get dateLabel => _t(('Дата', 'Date', 'Sana'));
  String get whatToCheck => _t(('Что проверить', 'What to check', 'Nimani tekshirish'));
  String get orderIt => _t((
    'Назначить',
    'Schedule',
    'Tayinlash',
  ));
  String get readyPercent => _t(('Готово, %', 'Done, %', 'Tayyor, %'));
  String get commentAndPhoto => _t(('Комментарий и описание фото', 'Comment and photo description', 'Izoh va foto tavsifi'));
  String get submitReport => _t(('Отправить отчёт', 'Send the report', 'Hisobotni yuborish'));

  // ── Review of project card changes (platform administrator) ────────────

  String get moderationSubtitle => _t((
    'Проверьте изменения карточек перед публикацией.',
    'Review changes to project cards before they are published.',
    'Obyekt kartalaridagi o‘zgarishlarni e’lon qilishdan oldin tekshiring.',
  ));
  String get moderationAdminOnly => _t((
    'Проверять правки может только администратор iBuild.',
    'Only an iBuild administrator can review changes.',
    'Tahrirlarni faqat iBuild administratori ko‘rib chiqa oladi.',
  ));
  String get moderationEmpty => _t(('Новых правок нет', 'No new changes', 'Yangi tahrirlar yo‘q'));
  String get moderationEmptyBody => _t((
    'Все поступившие изменения рассмотрены.',
    'No submitted changes need review.',
    'Ko‘rib chiqilishi kerak bo‘lgan o‘zgarish yo‘q.',
  ));
  String currentNameIs(String name) => _t(('Сейчас: $name', 'Now: $name', 'Hozir: $name'));
  String proposedNameIs(String name) => _t(('Предлагают: $name', 'Proposed: $name', 'Taklif: $name'));
  String get accept => _t(('Принять', 'Accept', 'Qabul qilish'));
  String rejectChangeTitle(String name) => _t((
    'Отклонить правку «$name»?',
    'Reject the change “$name”?',
    '“$name” tahririni rad etasizmi?',
  ));
  String get needRejectReason => _t((
    'Напишите, почему вы отклоняете правку.',
    'Write why you are rejecting the change.',
    'Tahrirni nega rad etayotganingizni yozing.',
  ));

  String get techQueue => _t((
    'Транши, по которым нужно подтвердить выполненные работы.',
    'Tranches that need confirmation of completed work.',
    'Bajarilgan ishlarni tasdiqlash talab qilinadigan transhlar.',
  ));
  String get bankQueueNote => _t((
    'Транши на рассмотрении банка.',
    'Tranches under review by the bank.',
    'Bank ko‘rib chiqayotgan transhlar.',
  ));

  // ── Tranche forms ──────────────────────────────────────────────────────

  String get noPlanYet => _t(('Банк ещё не назначил лимит', 'The bank has not set a limit yet', 'Bank hali limit belgilamagan'));
  String get limitMissing => _t(('Лимит не назначен', 'Limit not set', 'Limit belgilanmagan'));

  // ── Bank cabinet ───────────────────────────────────────────────────────

  /// «12 траншей · 18 740,0 млн UZS» in the right grammar for each language.
  String trancheCount(int count) {
    switch (language) {
      case AppLanguage.en:
        return count == 1 ? '1 tranche' : '$count tranches';
      case AppLanguage.uz:
        return '$count ta transh';
      case AppLanguage.ru:
        final mod10 = count % 10;
        final mod100 = count % 100;
        if (mod10 == 1 && mod100 != 11) return '$count транш';
        if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
          return '$count транша';
        }
        return '$count траншей';
    }
  }

  String get millionUzs => _t(('млн UZS', 'mln UZS', 'mln UZS'));
}
