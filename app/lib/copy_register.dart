part of 'l10n.dart';

/// Text for company sign-up and the admin's applications desk.
/// Form labels and document names live in `registration_spec.dart`.
extension RegisterCopy on AppCopy {
  // ── Sign-in page ───────────────────────────────────────────────────────

  String get registerLink => _t((
    'Подать заявку',
    'Apply for access',
    'Ariza yuborish',
  ));
  String get registerHint => _t((
    'Подключение для застройщиков и банков',
    'Access for developers and banks',
    'Quruvchilar va banklar uchun',
  ));

  // ── Choosing who you are ───────────────────────────────────────────────

  String get registerTitle => _t((
    'Подключение к iBuild',
    'Apply for iBuild access',
    'iBuild tizimiga ulanish',
  ));
  String get registerPick => _t((
    'Выберите тип организации. Для застройщиков и банков нужны разные документы.',
    'Select your organisation type. Developers and banks submit different documents.',
    'Tashkilot turini tanlang. Quruvchilar va banklar uchun hujjatlar ro‘yxati har xil.',
  ));
  String get kindDeveloper => _t((
    'Застройщик',
    'Developer',
    'Quruvchi',
  ));
  String get kindDeveloperBody => '';
  String get kindBank => _t((
    'Банк',
    'Bank',
    'Bank',
  ));
  String get kindBankBody => '';
  String get kindDevelopers => _t(('Застройщики', 'Developers', 'Quruvchilar'));
  String get kindBanks => _t(('Банки', 'Banks', 'Banklar'));
  String get haveAccount => _t((
    'Уже есть аккаунт? Войти',
    'Already have an account? Sign in',
    'Hisobingiz bormi? Kirish',
  ));
  String get changeKind => _t((
    'Изменить тип организации',
    'Change organisation type',
    'Tashkilot turini o‘zgartirish',
  ));
  String get kindAll => _t(('Все', 'All', 'Hammasi'));

  // ── The form ───────────────────────────────────────────────────────────

  String get prepareTitle => _t(('Что подготовить', 'What to have ready', 'Nimalar tayyor bo‘lishi kerak'));
  String get prepareDeveloper => _t((
    'Подготовьте сведения о компании и объекте. Документы можно приложить сейчас или позже по ссылке на заявку.',
    'Have your company and project details ready. Attach the documents now or add them later using your application link.',
    'Kompaniya va obyekt ma’lumotlarini tayyorlang. Hujjatlarni hozir yoki keyin ariza havolasi orqali yuklang.',
  ));
  String get prepareBank => _t((
    'Подготовьте лицензию банка и документ о полномочиях представителя. Полный список — в конце формы.',
    'Have the bank’s licence and proof of your authority to represent it ready. See the full list at the end of the form.',
    'Bank litsenziyasi va vakilning vakolatini tasdiqlovchi hujjatni tayyorlang. To‘liq ro‘yxat shakl oxirida.',
  ));
  String get whyTitle => _t((
    'Проверка заявки',
    'Application review',
    'Arizani tekshirish',
  ));
  String get whyDeveloper => _t((
    'Перед подключением команда iBuild проверяет сведения о компании, её руководителе, владельцах и объекте по приложенным документам.',
    'Before granting access, the iBuild team checks the company, its management, owners and project against the documents you provide.',
    'Kirish huquqini berishdan oldin iBuild jamoasi kompaniya, rahbar, mulkdorlar va obyekt haqidagi ma’lumotlarni ilova qilingan hujjatlar asosida tekshiradi.',
  ));
  String get whyBank => _t((
    'Команда iBuild проверяет лицензию банка и полномочия представителя по приложенным документам.',
    'The iBuild team reviews the bank’s licence and the representative’s authority using the submitted documents.',
    'iBuild jamoasi bank litsenziyasi va vakilning vakolatini ilova qilingan hujjatlar asosida tekshiradi.',
  ));
  String get documentsTitle => _t(('Документы', 'Documents', 'Hujjatlar'));
  String get documentsRule => _t((
    'До 5 файлов на документ: PDF до 10 МБ, JPEG, PNG или WebP до 5 МБ. Проверьте, что текст читается.',
    'Up to 5 files per document: PDF up to 10 MB; JPEG, PNG or WebP up to 5 MB. Make sure the text is legible.',
    'Har bir hujjatga 5 tagacha fayl: PDF 10 MB gacha, JPEG, PNG yoki WebP 5 MB gacha. Matn o‘qilishi kerak.',
  ));
  String get docRequired => _t(('Нужен', 'Required', 'Majburiy'));
  String get docOptional => _t(('Желательно', 'Helpful', 'Tavsiya etiladi'));
  String get optionalMark => _t(('необязательно', 'optional', 'ixtiyoriy'));
  String get removeRow => _t(('Убрать', 'Remove', 'Olib tashlash'));

  String get addOwner => _t(('Добавить владельца', 'Add an owner', 'Ega qo‘shish'));
  String get ownerPerson => _t(('Человек', 'Person', 'Shaxs'));
  String get ownerCompany => _t(('Компания', 'Company', 'Kompaniya'));
  String get ownerName => _t(('ФИО или название', 'Full name or company name', 'F.I.Sh. yoki nomi'));
  String get ownerTaxId => _t(('ПИНФЛ или ИНН', 'PINFL or tax number', 'JShShIR yoki STIR'));
  String get ownerShare => _t(('Доля, %', 'Share, %', 'Ulush, %'));
  String sharesTotal(String percent) => _t((
    'Всего: $percent%',
    'Total: $percent%',
    'Jami: $percent%',
  ));
  String get addLicense => _t(('Добавить лицензию', 'Add a licence', 'Litsenziya qo‘shish'));
  String get licenseActivity => _t(('Вид деятельности', 'Type of activity', 'Faoliyat turi'));
  String get licenseNumber => _t(('Номер', 'Number', 'Raqami'));
  String get licenseIssued => _t(('Дата выдачи', 'Issued on', 'Berilgan sana'));
  String get licenseUntil => _t(('Действует до', 'Valid until', 'Amal qilish muddati'));

  String get consentPersonalData => _t((
    'Я согласен на обработку моих персональных данных и данных моей компании, чтобы iBuild проверил заявку и связался со мной. Согласие можно отозвать, написав нам.',
    'I agree that my personal data and my company’s data are processed so that iBuild can check the application and contact me. I can withdraw this by writing to you.',
    'Arizani tekshirish va men bilan bog‘lanish uchun shaxsiy ma’lumotlarim va kompaniyam ma’lumotlari qayta ishlanishiga roziman. Rozilikni sizga yozib qaytarib olishim mumkin.',
  ));
  String get consentTruth => _t((
    'Я подтверждаю, что сведения верны, а приложенные документы подлинные.',
    'I confirm the details are true and the attached documents are genuine.',
    'Ma’lumotlar to‘g‘riligini va ilova qilingan hujjatlar haqiqiy ekanini tasdiqlayman.',
  ));
  String get consentsNeeded => _t((
    'Подтвердите согласие на обработку данных и достоверность сведений.',
    'Agree to data processing and confirm that the information is accurate.',
    'Ma’lumotlarni qayta ishlashga rozilik bering va ularning to‘g‘riligini tasdiqlang.',
  ));
  String get submitApplication => _t(('Отправить заявку', 'Send the application', 'Arizani yuborish'));
  String filledProgress(int done, int total) => _t((
    'Заполнено обязательных полей: $done из $total',
    'Required fields filled: $done of $total',
    'To‘ldirilgan majburiy maydonlar: $done / $total',
  ));
  String uploadingProgress(int done, int total) => _t((
    'Загружаем документы: $done из $total',
    'Uploading documents: $done of $total',
    'Hujjatlar yuklanmoqda: $done / $total',
  ));
  String get fixFields => _t((
    'Проверьте отмеченные поля.',
    'Please check the marked fields.',
    'Belgilangan maydonlarni tekshiring.',
  ));
  String get fieldRequired => _t(('Заполните это поле', 'Fill in this field', 'Bu maydonni to‘ldiring'));
  String get fieldInvalid => _t(('Проверьте значение', 'Check the value', 'Qiymatni tekshiring'));
  String get sharesTooBig => _t((
    'Доли вместе больше 100%',
    'The shares add up to more than 100%',
    'Ulushlar yig‘indisi 100% dan oshib ketdi',
  ));
  String get needOwner => _t((
    'Добавьте хотя бы одного владельца',
    'Add at least one owner',
    'Kamida bitta ega qo‘shing',
  ));
  String get needInterest => _t((
    'Отметьте хотя бы один пункт',
    'Tick at least one item',
    'Kamida bitta bandni belgilang',
  ));
  String get pickDate => _t(('Выберите дату', 'Pick a date', 'Sanani tanlang'));

  // ── After sending ──────────────────────────────────────────────────────

  String get sentTitle => _t(('Заявка отправлена', 'Application sent', 'Ariza yuborildi'));
  String get sentBody => _t((
    'Сохраните ссылку на заявку. По ней можно узнать решение и приложить недостающие документы.',
    'Save your application link to check the decision and add any missing documents.',
    'Qarorni bilish va yetishmayotgan hujjatlarni yuklash uchun ariza havolasini saqlang.',
  ));
  String get applicationNumber => _t(('Номер заявки', 'Application number', 'Ariza raqami'));
  String get statusLink => _t(('Ссылка на статус', 'Status link', 'Holat havolasi'));
  String get copyText => _t(('Скопировать', 'Copy', 'Nusxalash'));
  String get copiedText => _t(('Скопировано', 'Copied', 'Nusxalandi'));
  String get openStatus => _t(('Открыть статус заявки', 'Open the application status', 'Ariza holatini ochish'));
  String get backToSignIn => _t(('К странице входа', 'Back to sign in', 'Kirish sahifasiga'));
  String get docsFailed => _t((
    'Не все документы загрузились. Добавьте их на странице статуса.',
    'Some documents did not upload. Add them on the status page.',
    'Ba’zi hujjatlar yuklanmadi. Ularni holat sahifasida qo‘shing.',
  ));
  String get nextTitle => _t(('Что дальше', 'What happens next', 'Keyingi qadamlar'));
  String get nextCall => _t((
    'Команда iBuild свяжется с контактным лицом по указанному номеру.',
    'The iBuild team will call the number listed for the contact person.',
    'iBuild jamoasi ko‘rsatilgan raqam orqali mas’ul shaxs bilan bog‘lanadi.',
  ));
  String get nextCheck => _t((
    'Администратор проверит приложенные документы. Запрос на дополнительные документы появится в заявке.',
    'An administrator reviews the attached documents. Any request for additional documents appears on the application page.',
    'Administrator ilova qilingan hujjatlarni tekshiradi. Qo‘shimcha hujjat so‘ralsa, so‘rov ariza sahifasida ko‘rinadi.',
  ));
  String get nextDecision => _t((
    'Если заявку одобрят, администратор передаст данные для входа.',
    'If your application is approved, the administrator will provide sign-in details.',
    'Ariza tasdiqlansa, administrator kirish ma’lumotlarini beradi.',
  ));

  // ── Status page ────────────────────────────────────────────────────────

  String get statusTitle => _t(('Статус заявки', 'Application status', 'Ariza holati'));
  String get statusNotFound => _t((
    'Заявка не найдена. Проверьте ссылку.',
    'Application not found. Check the link.',
    'Ariza topilmadi. Havolani tekshiring.',
  ));
  String get adminAsks => _t((
    'Запрос администратора',
    'Request from the administrator',
    'Administrator so‘rovi',
  ));
  String get declineReason => _t(('Причина отказа', 'Reason for the decline', 'Rad etish sababi'));
  String get approvedNote => _t((
    'Администратор iBuild свяжется с контактным лицом, чтобы передать данные для входа.',
    'The iBuild administrator will contact your representative with sign-in details.',
    'iBuild administratori kirish ma’lumotlarini berish uchun vakilingiz bilan bog‘lanadi.',
  ));
  String get stillMissing => _t((
    'Недостающие документы',
    'Missing documents',
    'Yetishmayotgan hujjatlar',
  ));
  String get sentFiles => _t((
    'Приложенные файлы',
    'Attached files',
    'Ilova qilingan fayllar',
  ));
  String get nothingMissing => _t((
    'Обязательные документы приложены',
    'Required documents attached',
    'Majburiy hujjatlar ilova qilingan',
  ));
  String get uploadMore => _t(('Добавить документы', 'Add documents', 'Hujjat qo‘shish'));
  String get refresh => _t(('Обновить', 'Refresh', 'Yangilash'));

  // ── Admin: the applications desk ───────────────────────────────────────

  String get applications => _t(('Заявки', 'Applications', 'Arizalar'));
  String get applicationsSubtitle => _t((
    'Подключение застройщиков и банков: документы, звонки и решения.',
    'Developer and bank onboarding: documents, calls and decisions.',
    'Quruvchilar va banklarni ulash: hujjatlar, qo‘ng‘iroqlar va qarorlar.',
  ));
  String get applicationsAdminOnly => _t((
    'Заявки видит только администратор iBuild.',
    'Only the iBuild admin can see applications.',
    'Arizalarni faqat iBuild administratori ko‘radi.',
  ));
  String get searchApplications => _t((
    'Название, ИНН, телефон или номер',
    'Name, tax number, phone or number',
    'Nomi, STIR, telefon yoki raqam',
  ));
  String get noApplications => _t(('Заявок нет', 'No applications', 'Arizalar yo‘q'));
  String get noApplicationsBody => _t((
    'По выбранным фильтрам заявок нет.',
    'No applications match these filters.',
    'Tanlangan filtrlar bo‘yicha ariza yo‘q.',
  ));
  String waitingDays(int days) => days <= 0
      ? _t(('Сегодня', 'Today', 'Bugun'))
      : _t(('$days дн. назад', '$days d ago', '$days kun oldin'));
  String callOn(String date) => _t(('Позвонить $date', 'Call on $date', 'Qo‘ng‘iroq: $date'));
  String docsMissing(int count) => _t((
    'Не хватает документов: $count',
    'Missing documents: $count',
    'Yetishmayotgan hujjatlar: $count',
  ));
  String get docsComplete => _t(('Документы собраны', 'Documents complete', 'Hujjatlar to‘liq'));
  String get backToApplications => _t(('Все заявки', 'All applications', 'Barcha arizalar'));

  String get crmActions => _t((
    'Работа с заявкой',
    'Application actions',
    'Ariza bo‘yicha amallar',
  ));
  String get logCall => _t((
    'Добавить запись о звонке',
    'Log a call',
    'Qo‘ng‘iroq qaydini qo‘shish',
  ));
  String get requestDocs => _t(('Запросить документы', 'Ask for documents', 'Hujjat so‘rash'));
  String get takeToReview => _t(('Взять в проверку', 'Start the review', 'Tekshiruvga olish'));
  String get approveApplication => _t(('Одобрить', 'Approve', 'Tasdiqlash'));
  String get rejectApplication => _t(('Отклонить', 'Decline', 'Rad etish'));
  String get callOutcome => _t((
    'Итог звонка',
    'Call outcome',
    'Qo‘ng‘iroq natijasi',
  ));
  String get callNote => _t((
    'Комментарий к звонку',
    'Call notes',
    'Qo‘ng‘iroq izohi',
  ));
  String get nextCallOn => _t((
    'Дата следующего звонка',
    'Next call date',
    'Keyingi qo‘ng‘iroq sanasi',
  ));
  String get noteLabel => _t(('Заметка', 'Note', 'Eslatma'));
  String get addNote => _t(('Добавить заметку', 'Add a note', 'Eslatma qo‘shish'));
  String get docsNeededLabel => _t((
    'Недостающие документы',
    'Documents needed',
    'Yetishmayotgan hujjatlar',
  ));
  String get sendRequest => _t(('Отправить запрос', 'Send the request', 'So‘rovni yuborish'));
  String get checklistTitle => _t(('Проверка', 'Checks', 'Tekshiruv'));
  String get checklistHint => _t((
    'Заявку можно одобрить после всех обязательных проверок.',
    'Complete all required checks before approving the application.',
    'Arizani tasdiqlashdan oldin barcha majburiy tekshiruvlarni bajaring.',
  ));
  String get historyTitle => _t(('История', 'History', 'Tarix'));
  String get applicationData => _t(('Данные из заявки', 'Details from the application', 'Arizadagi ma’lumotlar'));
  String get fileMissing => _t(('Нет файла', 'No file', 'Fayl yo‘q'));
  String get openFile => _t(('Открыть', 'Open', 'Ochish'));
  String get approveTitle => _t(('Одобрить заявку?', 'Approve the application?', 'Arizani tasdiqlaysizmi?'));
  String get approveDeveloperBody => _t((
    'Будут созданы компания, первый объект и аккаунт директора. Временный пароль отобразится один раз.',
    'This creates the company, its first project and a director account. The temporary password is shown once.',
    'Kompaniya, birinchi obyekt va direktor hisobi yaratiladi. Vaqtinchalik parol bir marta ko‘rsatiladi.',
  ));
  String get approveBankBody => _t((
    'Будут созданы кабинет банка и аккаунт администратора банка. Временный пароль отобразится один раз.',
    'This creates the bank workspace and a bank administrator account. The temporary password is shown once.',
    'Bank kabineti va bank administratori hisobi yaratiladi. Vaqtinchalik parol bir marta ko‘rsatiladi.',
  ));
  String get accountReady => _t(('Доступ создан', 'Access created', 'Kirish yaratildi'));
  String get accountBody => _t((
    'Передайте данные для входа контактному лицу. При первом входе временный пароль нужно сменить.',
    'Give the sign-in details to the contact person. They must change the temporary password on first sign-in.',
    'Kirish ma’lumotlarini mas’ul shaxsga bering. Birinchi kirishda vaqtinchalik parolni almashtirish kerak.',
  ));
  String get closeText => _t(('Закрыть', 'Close', 'Yopish'));
  String get companyLabel => _t(('Компания', 'Company', 'Kompaniya'));
  String get rejectApplicationTitle => _t(('Отклонить заявку', 'Decline the application', 'Arizani rad etish'));
  String get rejectApplicationHint => _t((
    'Причину увидит заявитель на странице статуса.',
    'The applicant sees the reason on the status page.',
    'Sababni ariza beruvchi holat sahifasida ko‘radi.',
  ));
  String consentRecorded(String date, String version) => _t((
    'Согласие на обработку данных получено $date (версия текста $version).',
    'Data-processing consent received on $date (text version $version).',
    'Ma’lumotlarni qayta ishlashga rozilik $date sanasida olingan (matn versiyasi $version).',
  ));
  String get ownersLabel => _t(('Владельцы', 'Owners', 'Egalar'));
  String get licensesLabel => _t(('Лицензии', 'Licences', 'Litsenziyalar'));
  String get interestsLabel => _t((
    'Интересующие услуги',
    'Services of interest',
    'Qiziqtirgan xizmatlar',
  ));
  String get yesText => _t(('Да', 'Yes', 'Ha'));
  String get noText => _t(('Нет', 'No', 'Yo‘q'));

  String eventText(String kind, String outcome, String body) {
    switch (kind) {
      case 'created':
        return _t(('Заявка подана', 'Application submitted', 'Ariza yuborildi'));
      case 'approved':
        return _t(('Заявка одобрена', 'Application approved', 'Ariza tasdiqlandi'));
      case 'note':
        return _t(('Заметка', 'Note', 'Eslatma'));
      case 'document':
        return _t(('Заявитель добавил документ', 'The applicant added a document', 'Ariza beruvchi hujjat qo‘shdi'));
      case 'call':
        return _t(('Звонок', 'Call', 'Qo‘ng‘iroq'));
      case 'status':
        return _t(('Статус изменён', 'Status changed', 'Holat o‘zgartirildi'));
      case 'check':
        return outcome == 'done'
            ? _t(('Проверено', 'Checked', 'Tekshirildi'))
            : _t(('Отметка снята', 'Tick removed', 'Belgi olib tashlandi'));
    }
    return kind;
  }
}
