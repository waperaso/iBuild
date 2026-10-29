part of 'l10n.dart';

/// Text for company sign-up and the admin's applications desk.
/// Form labels and document names live in `registration_spec.dart`.
extension RegisterCopy on AppCopy {
  // ── Sign-in page ───────────────────────────────────────────────────────

  String get registerLink => _t(('Регистрация', 'Register', 'Ro‘yxatdan o‘tish'));
  String get registerHint => _t((
    'Новая компания? Подайте заявку на подключение.',
    'New company? Apply to join.',
    'Yangi kompaniyami? Ulanish uchun ariza qoldiring.',
  ));

  // ── Choosing who you are ───────────────────────────────────────────────

  String get registerTitle => _t(('Заявка на подключение', 'Application to join', 'Ulanish uchun ariza'));
  String get registerPick => _t((
    'Выберите, кто вы. Мы проверим данные, позвоним и откроем доступ.',
    'Tell us who you are. We will check the details, call you and open access.',
    'Siz kimligingizni tanlang. Ma’lumotlarni tekshirib, qo‘ng‘iroq qilamiz va kirishni ochamiz.',
  ));
  String get kindDeveloper => _t(('Я застройщик', 'I am a developer', 'Men quruvchiman'));
  String get kindDeveloperBody => '';
  String get kindBank => _t(('Я представляю банк', 'I represent a bank', 'Men bankni vakil qilaman'));
  String get kindBankBody => '';
  String get kindDevelopers => _t(('Застройщики', 'Developers', 'Quruvchilar'));
  String get kindBanks => _t(('Банки', 'Banks', 'Banklar'));
  String get haveAccount => _t(('Уже есть вход? Войти', 'Already have an account? Sign in', 'Kirish bormi? Kirish'));
  String get changeKind => _t(('Сменить тип', 'Change type', 'Turini o‘zgartirish'));
  String get kindAll => _t(('Все', 'All', 'Hammasi'));

  // ── The form ───────────────────────────────────────────────────────────

  String get prepareTitle => _t(('Что подготовить', 'What to have ready', 'Nimalar tayyor bo‘lishi kerak'));
  String get prepareDeveloper => _t((
    'Заполнение займёт около 20 минут. Держите под рукой документы компании и объекта: список в конце формы. Файлы можно приложить сразу или позже по ссылке на статус.',
    'It takes about 20 minutes. Keep the company and project documents at hand: the list is at the end of the form. You can attach the files now or later from the status link.',
    'Taxminan 20 daqiqa ketadi. Kompaniya va obyekt hujjatlarini tayyorlab qo‘ying: ro‘yxat formaning oxirida. Fayllarni hozir yoki keyinroq holat havolasi orqali qo‘shishingiz mumkin.',
  ));
  String get prepareBank => _t((
    'Заполнение займёт около 5 минут. Нужны лицензия банка и документ, который подтверждает ваши полномочия.',
    'It takes about 5 minutes. You need the bank’s licence and a paper that shows your authority.',
    'Taxminan 5 daqiqa ketadi. Bank litsenziyasi va vakolatingizni tasdiqlovchi hujjat kerak.',
  ));
  String get whyTitle => _t(('Зачем столько вопросов', 'Why so many questions', 'Nega bunchalik ko‘p savol'));
  String get whyDeveloper => _t((
    'Банк и платформа обязаны знать, с кем работают. Закон о противодействии отмыванию денег (ЗРУ-660-II от 26.08.2004) требует установить компанию, её руководителя, владельцев и конечного владельца. Чтобы строить на деньги покупателей, нужны права на землю, разрешение на строительство и заключение экспертизы (указ УП-11 от 27.01.2025). Данные мы берём по закону о персональных данных (ЗРУ-547) и используем только для проверки заявки. Это не юридическая консультация, правила могут меняться.',
    'The bank and the platform must know who they work with. The anti-money-laundering law (ZRU-660-II of 26.08.2004) requires us to identify the company, its head, its owners and the final owner. To build with buyers’ money you need land rights, a building permit and a design review conclusion (decree UP-11 of 27.01.2025). We handle the data under the personal-data law (ZRU-547) and use it only to check the application. This is not legal advice, and the rules may change.',
    'Bank va platforma kim bilan ishlashini bilishi shart. Pul yuvishga qarshi qonun (2004-yil 26-avgustdagi O‘RQ-660-II) kompaniyani, uning rahbarini, egalarini va oxirgi benefitsiarni aniqlashni talab qiladi. Xaridorlar puli hisobiga qurish uchun yerga huquq, qurilish ruxsatnomasi va ekspertiza xulosasi kerak (2025-yil 27-yanvardagi PF-11-son farmon). Ma’lumotlarni shaxsga doir ma’lumotlar qonuni (O‘RQ-547) bo‘yicha olamiz va faqat arizani tekshirish uchun ishlatamiz. Bu yuridik maslahat emas, qoidalar o‘zgarishi mumkin.',
  ));
  String get whyBank => _t((
    'Мы проверим, что банк работает по лицензии Центрального банка и что вы вправе говорить от его имени. Данные используем только для связи и проверки.',
    'We will check that the bank works under a Central Bank licence and that you may speak for it. We use the data only to get in touch and to check.',
    'Bank Markaziy bank litsenziyasi asosida ishlashini va siz uning nomidan gapirishga haqli ekanligingizni tekshiramiz. Ma’lumotlarni faqat bog‘lanish va tekshirish uchun ishlatamiz.',
  ));
  String get documentsTitle => _t(('Документы', 'Documents', 'Hujjatlar'));
  String get documentsRule => _t((
    'Подойдёт фото (JPEG, PNG, WebP) или PDF. Файл до 10 МБ, фото до 5 МБ. Текст должен читаться. На один пункт можно добавить до 5 файлов.',
    'A photo (JPEG, PNG, WebP) or a PDF works. Up to 10 MB a file, photos up to 5 MB. The text must be readable. Up to 5 files per item.',
    'Foto (JPEG, PNG, WebP) yoki PDF mos keladi. Fayl 10 MB gacha, foto 5 MB gacha. Matn o‘qilishi kerak. Har bir band uchun 5 tagacha fayl.',
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
    'Поставьте обе галочки, чтобы отправить заявку.',
    'Tick both boxes to send the application.',
    'Arizani yuborish uchun ikkala belgini qo‘ying.',
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
    'Мы изучим данные и позвоним вам. Сохраните номер и ссылку: по ним можно узнать, как идёт проверка, и добавить документы.',
    'We will look at the details and call you. Keep the number and the link: they show how the check is going and let you add documents.',
    'Ma’lumotlarni ko‘rib chiqib, sizga qo‘ng‘iroq qilamiz. Raqam va havolani saqlang: ular orqali tekshiruv borishini bilib, hujjat qo‘shish mumkin.',
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
    'Звонок. Мы позвоним в удобное вам время и уточним детали.',
    'A call. We phone you at your chosen time and ask about the details.',
    'Qo‘ng‘iroq. Siz tanlagan vaqtda qo‘ng‘iroq qilib, tafsilotlarni aniqlaymiz.',
  ));
  String get nextCheck => _t((
    'Проверка. Сверим данные и документы с государственными реестрами.',
    'A check. We compare the details and documents with the state registers.',
    'Tekshiruv. Ma’lumot va hujjatlarni davlat reyestrlari bilan solishtiramiz.',
  ));
  String get nextDecision => _t((
    'Решение. Если всё в порядке, мы передадим вам доступ.',
    'A decision. If all is in order, we hand over your access.',
    'Qaror. Hammasi joyida bo‘lsa, kirishni topshiramiz.',
  ));

  // ── Status page ────────────────────────────────────────────────────────

  String get statusTitle => _t(('Статус заявки', 'Application status', 'Ariza holati'));
  String get statusNotFound => _t((
    'Заявка не найдена. Проверьте ссылку.',
    'Application not found. Check the link.',
    'Ariza topilmadi. Havolani tekshiring.',
  ));
  String get adminAsks => _t(('Что просит проверяющий', 'What the reviewer asks for', 'Tekshiruvchi nimani so‘raydi'));
  String get declineReason => _t(('Причина отказа', 'Reason for the decline', 'Rad etish sababi'));
  String get approvedNote => _t((
    'Мы свяжемся с вами по телефону и передадим доступ.',
    'We will phone you and hand over your access.',
    'Siz bilan telefon orqali bog‘lanib, kirishni topshiramiz.',
  ));
  String get stillMissing => _t(('Ещё не хватает', 'Still missing', 'Hali yetishmaydi'));
  String get sentFiles => _t(('Вы уже приложили', 'Already attached', 'Allaqachon ilova qilingan'));
  String get nothingMissing => _t(('Все нужные документы есть', 'All needed documents are here', 'Kerakli hujjatlar to‘liq'));
  String get uploadMore => _t(('Добавить документы', 'Add documents', 'Hujjat qo‘shish'));
  String get refresh => _t(('Обновить', 'Refresh', 'Yangilash'));

  // ── Admin: the applications desk ───────────────────────────────────────

  String get applications => _t(('Заявки', 'Applications', 'Arizalar'));
  String get applicationsSubtitle => _t((
    'Новые компании. Позвоните, проверьте документы и примите решение.',
    'New companies. Call them, check the documents and decide.',
    'Yangi kompaniyalar. Qo‘ng‘iroq qiling, hujjatlarni tekshiring va qaror qiling.',
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
    'Когда кто-то подаст заявку на странице входа, она появится здесь.',
    'When someone applies on the sign-in page, it shows up here.',
    'Kimdir kirish sahifasida ariza qoldirsa, u shu yerda paydo bo‘ladi.',
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

  String get crmActions => _t(('Что делать', 'What to do', 'Nima qilish kerak'));
  String get logCall => _t(('Записать звонок', 'Log a call', 'Qo‘ng‘iroqni yozish'));
  String get requestDocs => _t(('Запросить документы', 'Ask for documents', 'Hujjat so‘rash'));
  String get takeToReview => _t(('Взять в проверку', 'Start the review', 'Tekshiruvga olish'));
  String get approveApplication => _t(('Одобрить', 'Approve', 'Tasdiqlash'));
  String get rejectApplication => _t(('Отклонить', 'Decline', 'Rad etish'));
  String get callOutcome => _t(('Чем закончился звонок', 'How the call ended', 'Qo‘ng‘iroq qanday tugadi'));
  String get callNote => _t(('Что узнали', 'What you learned', 'Nimani bildingiz'));
  String get nextCallOn => _t(('Когда позвонить снова', 'When to call again', 'Qachon qayta qo‘ng‘iroq qilish'));
  String get noteLabel => _t(('Заметка', 'Note', 'Eslatma'));
  String get addNote => _t(('Добавить заметку', 'Add a note', 'Eslatma qo‘shish'));
  String get docsNeededLabel => _t(('Какие документы нужны', 'Which documents are needed', 'Qaysi hujjatlar kerak'));
  String get sendRequest => _t(('Отправить запрос', 'Send the request', 'So‘rovni yuborish'));
  String get checklistTitle => _t(('Проверка', 'Checks', 'Tekshiruv'));
  String get checklistHint => _t((
    'Отметьте всё, что проверили. Пока отмечено не всё, одобрить нельзя.',
    'Tick what you have checked. You cannot approve until everything is ticked.',
    'Tekshirganlaringizni belgilang. Hammasi belgilanmaguncha tasdiqlab bo‘lmaydi.',
  ));
  String get historyTitle => _t(('История', 'History', 'Tarix'));
  String get applicationData => _t(('Данные из заявки', 'Details from the application', 'Arizadagi ma’lumotlar'));
  String get fileMissing => _t(('Нет файла', 'No file', 'Fayl yo‘q'));
  String get openFile => _t(('Открыть', 'Open', 'Ochish'));
  String get approveTitle => _t(('Одобрить заявку?', 'Approve the application?', 'Arizani tasdiqlaysizmi?'));
  String get approveDeveloperBody => _t((
    'Мы создадим компанию, вход для контактного лица и первый объект. Пароль покажем один раз.',
    'We will create the company, a sign-in for the contact person and the first project. The password is shown once.',
    'Kompaniya, aloqa shaxsi uchun kirish va birinchi obyekt yaratiladi. Parol bir marta ko‘rsatiladi.',
  ));
  String get approveBankBody => _t((
    'Банк будет отмечен как одобренный. Кабинет банка подключается отдельно.',
    'The bank will be marked as approved. The bank’s workspace is set up separately.',
    'Bank tasdiqlangan deb belgilanadi. Bank kabineti alohida ulanadi.',
  ));
  String get accountReady => _t(('Доступ создан', 'Access created', 'Kirish yaratildi'));
  String get accountBody => _t((
    'Передайте эти данные по телефону. Пароль виден только сейчас.',
    'Pass these details on by phone. The password is only visible now.',
    'Bu ma’lumotlarni telefon orqali bering. Parol faqat hozir ko‘rinadi.',
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
  String get interestsLabel => _t(('Что интересует', 'Interested in', 'Qiziqish'));
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
