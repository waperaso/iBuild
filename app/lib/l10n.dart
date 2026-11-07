import 'package:flutter/material.dart';

import 'locale_store.dart';
import 'models.dart';
import 'theme.dart';

part 'copy_more.dart';
part 'copy_register.dart';
part 'copy_demo.dart';
part 'copy_messages.dart';

/// The three interface languages. Russian is the default.
enum AppLanguage {
  ru('RU'),
  en('EN'),
  uz('UZ');

  const AppLanguage(this.code);

  final String code;

  static AppLanguage fromCode(String? raw) {
    return switch (raw) {
      'en' => AppLanguage.en,
      'uz' => AppLanguage.uz,
      _ => AppLanguage.ru,
    };
  }
}

typedef _Row = (String, String, String);

/// Every sentence a person can read in the app, in Russian, English and Uzbek.
///
/// Writing rules: short sentences, everyday words, no system terms.
/// A tranche is called a "tranche" everywhere; a "request" is never a separate thing.
class AppCopy {
  const AppCopy(this.language);

  final AppLanguage language;

  String _t(_Row row) {
    return switch (language) {
      AppLanguage.en => row.$2,
      AppLanguage.uz => row.$3,
      AppLanguage.ru => row.$1,
    };
  }

  /// Public form of the picker, for screens that build one-off sentences.
  String pick(String ru, String en, String uz) => _t((ru, en, uz));

  // ── Sign in ────────────────────────────────────────────────────────────

  String get tagline => _t((
    'Финансирование строительства: от заявки на транш до учёта выплаты.',
    'Construction financing, from tranche request to payout record.',
    'Qurilishni moliyalashtirish: transh so‘rovidan to‘lovni qayd etishgacha.',
  ));
  String get signInTitle => _t(('Вход', 'Sign in', 'Kirish'));
  String get loginLabel => _t(('Логин', 'Login', 'Login'));
  String get passwordLabel => _t(('Пароль', 'Password', 'Parol'));
  String get signInButton => _t(('Войти', 'Sign in', 'Kirish'));
  String get enterCredentials => _t((
    'Введите логин и пароль.',
    'Enter your login and password.',
    'Login va parolni kiriting.',
  ));
  String get signOut => _t(('Выйти', 'Sign out', 'Chiqish'));

  // ── Menu and page titles ───────────────────────────────────────────────

  String get home => _t(('Главная', 'Home', 'Bosh sahifa'));
  String get projects => _t(('Объекты', 'Projects', 'Obyektlar'));
  String get requests => _t(('Транши', 'Tranches', 'Transhlar'));
  String get budget => _t(('Бюджет', 'Budget', 'Byudjet'));
  String get inspections => _t(('Осмотры', 'Inspections', 'Ko‘riklar'));
  String get documents => _t(('Документы', 'Documents', 'Hujjatlar'));
  String get people => _t(('Участники', 'People', 'Ishtirokchilar'));
  String get queue => _t(('Очередь', 'Queue', 'Navbat'));
  String get moderation => _t(('Проверка правок', 'Review changes', 'Tahrirlarni ko‘rib chiqish'));

  String get bankCabinet => _t(('Кабинет банка', 'Bank workspace', 'Bank kabineti'));
  String get bankPortfolio => _t(('Портфель', 'Portfolio', 'Portfel'));
  String get bankDevelopers => _t(('Застройщики', 'Developers', 'Quruvchilar'));
  String get bankReports => _t(('Отчёты', 'Reports', 'Hisobotlar'));
  String get bankRules => _t(('Правила банка', 'Bank rules', 'Bank qoidalari'));
  String get bankWaiting => _t(('Ждут решения банка', 'Waiting for the bank', 'Bank qarorini kutmoqda'));
  String get comingSoon => _t((
    'Раздел в разработке.',
    'This section is in development.',
    'Bo‘lim ishlab chiqilmoqda.',
  ));

  // ── Home ───────────────────────────────────────────────────────────────

  String get welcome => _t(('Добро пожаловать!', 'Welcome!', 'Xush kelibsiz!'));
  String get searchHint => _t((
    'Поиск по разделам',
    'Find a section',
    'Bo‘limlarni qidirish',
  ));
  String get spheres => _t(('Разделы', 'Sections', 'Bo‘limlar'));
  String get allServices => _t(('Все объекты', 'All projects', 'Barcha obyektlar'));
  String get seeAll => _t(('Открыть', 'Open', 'Ochish'));
  String get askTranche => _t(('Запросить транш', 'Request a tranche', 'Transh so‘rash'));
  String get openProjects => _t(('Мои объекты', 'My projects', 'Mening obyektlarim'));
  String get homeTranches => _t(('Транши', 'Tranches', 'Transhlar'));
  String get homeMoney => _t((
    'Финансирование',
    'Financing',
    'Moliyalashtirish',
  ));
  String get homeControl => _t(('Контроль', 'Control', 'Nazorat'));
  String get queueEmptyTitle => _t(('Очередь пуста', 'Nothing in the queue', 'Navbat bo‘sh'));
  String get queueEmptyBody => _t((
    'Сейчас нет траншей, которые ждут вашего решения.',
    'No tranches are waiting for you right now.',
    'Hozir sizning qaroringizni kutayotgan transh yo‘q.',
  ));
  String get queueSubtitle => _t((
    'Транши, по которым требуется ваше решение.',
    'Tranches that need your decision.',
    'Qaroringiz talab qilinadigan transhlar.',
  ));

  /// Uzbek writes the Russian «ЖК» as «TJ».
  String place(String name) {
    if (language != AppLanguage.uz) return name;
    return name.replaceAll('ЖК', 'TJ');
  }

  // ── Projects ───────────────────────────────────────────────────────────

  String get downloadRegistry => _t((
    'Скачать реестр траншей',
    'Download tranche register',
    'Transhlar reyestrini yuklab olish',
  ));
  String get createProject => _t(('Добавить объект', 'Add a project', 'Obyekt qo‘shish'));
  String get projectsSubtitle => _t((
    'Строительные объекты, к которым у вас есть доступ.',
    'Construction projects you have access to.',
    'Sizga ruxsat berilgan qurilish obyektlari.',
  ));
  String get noProjects => _t(('Объектов пока нет', 'No projects yet', 'Hozircha obyekt yo‘q'));
  String get noProjectsBody => _t((
    'Объекты появятся после назначения доступа.',
    'Projects appear here once you are granted access.',
    'Ruxsat berilgach, obyektlar shu yerda ko‘rinadi.',
  ));
  String get newProject => _t(('Новый объект', 'New project', 'Yangi obyekt'));
  String get name => _t(('Название', 'Name', 'Nomi'));
  String get address => _t(('Адрес', 'Address', 'Manzil'));
  String get cancel => _t(('Отмена', 'Cancel', 'Bekor qilish'));
  String get needNameAddress => _t((
    'Напишите название и адрес.',
    'Enter a name and an address.',
    'Nom va manzilni yozing.',
  ));
  String get save => _t(('Сохранить', 'Save', 'Saqlash'));
  String get role => _t(('Роль', 'Role', 'Rol'));
  String get status => _t(('Статус', 'Status', 'Holat'));
  String get active => _t((
    'В работе',
    'In progress',
    'Jarayonda',
  ));
  String get archived => _t(('В архиве', 'Archived', 'Arxivda'));
  String get projectUnavailable =>
      _t(('Объект недоступен', 'Project not available', 'Obyekt mavjud emas'));
  String get projectNotAssigned => _t((
    'Вас ещё не добавили на этот объект.',
    'You have not been added to this project.',
    'Sizni bu obyektga hali qo‘shishmagan.',
  ));
  String get backToProjects => _t(('К объектам', 'Back to projects', 'Obyektlarga'));
  String get yourRole => _t(('Ваша роль:', 'Your role:', 'Sizning rolingiz:'));
  String get openProject => _t(('Открыть объект', 'Open a project', 'Obyektni ochish'));
  String get openProjectBody => _t((
    'Выберите объект, чтобы открыть его бюджет, документы или список участников.',
    'Select a project to view its budget, documents or participants.',
    'Byudjet, hujjatlar yoki ishtirokchilarni ko‘rish uchun obyektni tanlang.',
  ));
  String get portfolio => _t(('Портфель', 'Portfolio', 'Portfel'));
  String get needsAction => _t(('Ждёт вашего решения', 'Needs your decision', 'Sizning qaroringizni kutmoqda'));
  String get developerLine => _t(('Застройщик', 'Developer', 'Quruvchi'));
  String get bankLine => _t(('Банк', 'Bank', 'Bank'));

  // ── Money ──────────────────────────────────────────────────────────────

  String get plan => _t(('Лимит', 'Limit', 'Limit'));
  String get reserved => _t((
    'Зарезервировано',
    'Reserved',
    'Band qilingan',
  ));
  String get paid => _t(('Выплачено', 'Paid out', 'To‘langan'));
  String get available => _t((
    'Доступно к запросу',
    'Available to request',
    'So‘rash mumkin',
  ));
  String get formula => _t((
    'Доступно к запросу: лимит за вычетом выплат и сумм по траншам в работе.',
    'Available to request: the limit minus recorded payouts and amounts reserved for active tranches.',
    'So‘rash mumkin bo‘lgan summa: limitdan to‘langan va jarayondagi transhlar uchun band qilingan summalar ayriladi.',
  ));
  String get planNotSet => _t((
    'Лимит ещё не назначен',
    'Limit not set yet',
    'Limit hali belgilanmagan',
  ));
  String get planNotSetBody => _t((
    'Банк должен назначить лимит, и только потом транш можно отправить.',
    'The bank has to set the limit before the tranche can be sent.',
    'Transhni yuborishdan oldin bank limitni belgilashi kerak.',
  ));
  String lineLeft(String amount) => _t((
    'Осталось по этому виду работ: $amount',
    'Left for this work item: $amount',
    'Ushbu ish turi bo‘yicha qoldi: $amount',
  ));

  // ── Budget ─────────────────────────────────────────────────────────────

  String get addLine => _t(('Добавить вид работ', 'Add a work item', 'Ish turini qo‘shish'));
  String get setLimit => _t(('Назначить лимит', 'Set the limit', 'Limitni belgilash'));
  String get newFirm => _t(('Новый подрядчик', 'New contractor', 'Yangi pudratchi'));
  String get budgetLocked => _t((
    'Бюджет закрыт для правок: по объекту уже есть отправленный транш.',
    'The budget can no longer be edited: a tranche has already been sent for this project.',
    'Byudjetni endi o‘zgartirib bo‘lmaydi: obyekt bo‘yicha transh allaqachon yuborilgan.',
  ));
  String get noLines => _t(('Видов работ пока нет', 'No work items yet', 'Ish turlari hali yo‘q'));
  String get noLinesBody => _t((
    'Добавьте вид работ, укажите сумму и выберите подрядчика.',
    'Add a work item, enter the amount and select a contractor.',
    'Ish turini qo‘shing, summani kiriting va pudratchini tanlang.',
  ));
  String get work => _t(('Вид работ', 'Work item', 'Ish turi'));
  String get contractor => _t(('Подрядчик', 'Contractor', 'Pudratchi'));
  String get amount => _t(('Сумма', 'Amount', 'Summa'));
  String get members => _t(('Участники', 'People', 'Ishtirokchilar'));
  String get assign => _t(('Добавить на объект', 'Add to the project', 'Obyektga qo‘shish'));
  String get noMembers => _t(('Участников нет', 'No one here yet', 'Ishtirokchilar yo‘q'));
  String get noMembersBody => _t((
    'На объект добавляют застройщика, подрядчиков и банк.',
    'The developer, contractors and the bank are added to a project.',
    'Obyektga quruvchi, pudratchilar va bank qo‘shiladi.',
  ));
  String get inn => _t(('ИНН', 'Tax ID', 'STIR'));
  String get contact => _t(('Контакт', 'Contact', 'Aloqa'));
  String get lineTitle => _t(('Вид работ', 'Work item', 'Ish turi'));
  String get workName => _t(('Название вида работ', 'Work item name', 'Ish turi nomi'));
  String get amountUzs => _t(('Сумма, сум', 'Amount, UZS', 'Summa, so‘m'));
  String get assignment => _t(('Добавление на объект', 'Add to the project', 'Obyektga qo‘shish'));
  String get employee => _t(('Сотрудник', 'Person', 'Xodim'));
  String get edit => _t(('Изменить', 'Edit', 'Tahrirlash'));
  String get remove => _t(('Убрать', 'Remove', 'Olib tashlash'));
  String get removeLineTitle => _t(('Убрать вид работ?', 'Remove this work item?', 'Ish turi olib tashlansinmi?'));
  String get removeLineBody => _t((
    'Он исчезнет из бюджета, а суммы пересчитаются.',
    'It will leave the budget and the totals will be recalculated.',
    'U byudjetdan chiqadi, summalar qayta hisoblanadi.',
  ));
  String get removeMemberTitle => _t(('Убрать с объекта?', 'Remove from the project?', 'Obyektdan olib tashlansinmi?'));
  String get removeMemberBody => _t((
    'Человек перестанет видеть этот объект.',
    'This person will no longer see the project.',
    'Bu odam obyektni ko‘rmay qoladi.',
  ));
  String get everyoneAssigned => _t((
    'Все сотрудники компании уже добавлены на этот объект.',
    'Everyone from the company is already on this project.',
    'Kompaniyaning barcha xodimlari bu obyektga allaqachon qo‘shilgan.',
  ));

  // ── Tranche list and form ──────────────────────────────────────────────

  String get requestsSubtitle => _t((
    'Черновики, заявки на финансирование и решения по траншам.',
    'Drafts, funding requests and tranche decisions.',
    'Qoralamalar, moliyalashtirish so‘rovlari va transhlar bo‘yicha qarorlar.',
  ));
  String get newRequest => _t(('Новый транш', 'New tranche', 'Yangi transh'));
  String get allProjects => _t(('Все объекты', 'All projects', 'Barcha obyektlar'));
  String get all => _t(('Все', 'All', 'Hammasi'));
  String get noRequestsForStatus => _t((
    'Нет траншей с таким статусом',
    'No tranches with this status',
    'Bu holatda transhlar yo‘q',
  ));
  String get noRequestsForStatusBody => _t((
    'Попробуйте выбрать другой статус.',
    'Try picking another status.',
    'Boshqa holatni tanlab ko‘ring.',
  ));
  String get noRequests => _t(('Траншей пока нет', 'No tranches yet', 'Hozircha transh yo‘q'));
  String get noRequestsBody => _t((
    'Транши по доступным вам объектам появятся здесь.',
    'Tranches for your projects will appear here.',
    'Sizga ochiq obyektlar transhlari shu yerda ko‘rinadi.',
  ));
  String get projectRequestsEmpty => _t((
    'По этому объекту траншей ещё нет.',
    'There are no tranches for this project yet.',
    'Bu obyekt bo‘yicha transhlar hali yo‘q.',
  ));
  String get requestsForProject => _t(('Транши объекта', 'Tranches of this project', 'Obyekt transhlari'));
  String get backToRequests => _t(('К траншам', 'Back to tranches', 'Transhlarga'));
  String get requestMissing => _t(('Транш не найден', 'Tranche not found', 'Transh topilmadi'));
  String get requestMissingBody => _t((
    'Возможно, ссылка устарела.',
    'The link may be out of date.',
    'Havola eskirgan bo‘lishi mumkin.',
  ));
  String get history => _t(('История', 'History', 'Tarix'));
  String get formForContractor => _t((
    'У вашей роли нет права создавать транш',
    'Your role cannot create a tranche',
    'Sizning rolingiz transh yarata olmaydi',
  ));
  String get formForContractorBody => _t((
    'Создавать транши могут застройщики и подрядчики с доступом к объекту.',
    'Developers and contractors with project access can create tranches.',
    'Obyektga ruxsati bor quruvchilar va pudratchilar transh yaratishi mumkin.',
  ));
  String get amountHelper => _t((
    'Сумма в сумах',
    'Amount in UZS',
    'Summa so‘mda',
  ));
  String get price => _t(('Сумма', 'Amount', 'Summa'));
  String get description => _t((
    'Описание выполненных работ',
    'Work completed',
    'Bajarilgan ishlar tavsifi',
  ));
  String get whatFor => _t(('Вид работ', 'Work item', 'Ish turi'));
  String get customType => _t((
    'Другой вид работ',
    'Other work item',
    'Boshqa ish turi',
  ));
  String get customTypeHint => _t(('Например, заливка', 'For example, concrete pouring', 'Masalan, quyma ishlari'));
  String get customTypeNote => _t((
    'Сохраните черновик. Отправить транш можно после того, как банк установит лимит на этот вид работ.',
    'Save the draft. You can submit it once the bank sets a limit for this work item.',
    'Qoralamani saqlang. Bank ushbu ish turiga limit belgilagach, transhni yuborishingiz mumkin.',
  ));
  String get bankHasNoPlan => _t(('Банк ещё не назначил лимит', 'The bank has not set a limit yet', 'Bank hali limit belgilamagan'));
  String get photoEvidence => _t(('Фото работы', 'Photo of the work', 'Ish fotosi'));
  String get photoChosen => _t(('Фото выбрано', 'Photo chosen', 'Foto tanlandi'));
  String get photoEvidenceNote => _t((
    'Для отправки нужно хотя бы одно фото выполненных работ.',
    'Attach at least one photo of the completed work before submitting.',
    'Yuborishdan oldin bajarilgan ishlardan kamida bitta surat ilova qiling.',
  ));
  String get photoNote => _t((
    'Черновик не резервирует сумму в бюджете. Фото и документы сохраняются вместе с ним.',
    'A draft does not reserve any budget. Photos and documents are saved with it.',
    'Qoralama byudjetdan mablag‘ band qilmaydi. Surat va hujjatlar qoralamada saqlanadi.',
  ));
  String get saveDraft => _t(('Сохранить черновик', 'Save as draft', 'Qoralamani saqlash'));
  String get filesTitle => _t(('Фото и документы', 'Photos and documents', 'Foto va hujjatlar'));
  String get photoTile => _t(('Фото', 'Photo', 'Foto'));
  String get pdfTile => _t(('PDF', 'PDF', 'PDF'));
  String get addFile => _t(('Добавить файл', 'Add a file', 'Fayl qo‘shish'));
  String get removeFile => _t(('Убрать файл', 'Remove file', 'Faylni olib tashlash'));
  String get fileRules => _t((
    'Можно добавить до пяти фото (JPEG, PNG или WebP, каждое до 5 МБ) и один PDF до 10 МБ.',
    'You can add up to five photos (JPEG, PNG or WebP, up to 5 MB each) and one PDF up to 10 MB.',
    'Beshtagacha foto (JPEG, PNG yoki WebP, har biri 5 MB gacha) va bitta PDF (10 MB gacha) qo‘shish mumkin.',
  ));
  String get saveChanges => _t(('Сохранить изменения', 'Save changes', 'O‘zgarishlarni saqlash'));
  String get send => _t(('Отправить', 'Send', 'Yuborish'));
  String get checkTitle => _t(('Сумма и остаток', 'Amount and balance', 'Summa va qoldiq'));
  String get requestedAmount => _t(('Сумма транша', 'Tranche amount', 'Transh summasi'));
  String get linePlan => _t(('Лимит по этим работам', 'Limit for this work', 'Shu ishlar uchun limit'));
  String get linePaid => _t(('Уже выплачено', 'Already paid out', 'Allaqachon to‘langan'));
  String get lineReserved => _t((
    'Зарезервировано',
    'Reserved',
    'Band qilingan',
  ));
  String get lineAvailable => _t((
    'Доступно к запросу',
    'Available to request',
    'So‘rash mumkin',
  ));
  String get sendTo => _t(('Кому', 'To', 'Kimga'));
  String get sendToTech => _t(('Отправить в банк', 'Send to the bank', 'Bankka yuborish'));
  String get bankParty => _t(('Банк', 'Bank', 'Bank'));
  String get sendHint => _t((
    'После отправки транш поступит в банк, а сумма будет зарезервирована в бюджете.',
    'Submitting sends the tranche to the bank and reserves the amount in the budget.',
    'Transh bankka yuboriladi va summa byudjetda band qilinadi.',
  ));
  String get addressedToBank => _t((
    'Получатель — банк объекта.',
    'This tranche goes to the project’s bank.',
    'Transh obyekt bankiga yuboriladi.',
  ));
  String get sentToBank => _t(('Отправлен в банк', 'Sent to the bank', 'Bankka yuborilgan'));
  String recipientLine(String role, String name) {
    final label = switch (role) {
      'observer' => bankParty,
      'director' || 'contractor' || 'tech' || 'developer' => roleName(AppRole.parse(role)),
      _ => '',
    };
    if (label.isEmpty) return name;
    return '$label · $name';
  }

  String get openRequest => _t(('Открыть транш', 'Open the tranche', 'Transhni ochish'));
  String get photoRequired => _t((
    'Добавьте хотя бы одно фото работы, иначе транш не отправить.',
    'Add at least one photo of the work, or the tranche cannot be sent.',
    'Kamida bitta ish fotosini qo‘shing, aks holda transhni yuborib bo‘lmaydi.',
  ));
  String get cancelRequest => _t(('Отозвать транш', 'Withdraw the tranche', 'Transhni qaytarib olish'));
  String get cancelRequestTitle => _t(('Отозвать транш?', 'Withdraw the tranche?', 'Transh qaytarib olinsinmi?'));
  String get cancelRequestBody => _t((
    'Банк прекратит рассмотрение транша. Сумма снова будет доступна в бюджете.',
    'The bank will stop reviewing the tranche. The amount will become available again in the budget.',
    'Bank transhni ko‘rib chiqishni to‘xtatadi. Summa byudjetda yana mavjud bo‘ladi.',
  ));
  String get approveWork => _t(('Подтвердить работу', 'Confirm the work', 'Ishni tasdiqlash'));
  String get rejectWork => _t(('Отклонить', 'Reject', 'Rad etish'));
  String get reasonLabel => _t(('Причина', 'Reason', 'Sabab'));
  String get agreeRequest => _t(('Одобрить транш', 'Approve the tranche', 'Transhni ma’qullash'));
  String get waitingForBank => _t((
    'Работы подтверждены. Транш на рассмотрении в банке.',
    'The work is confirmed. The bank is reviewing the tranche.',
    'Ishlar tasdiqlandi. Bank transhni ko‘rib chiqmoqda.',
  ));
  String get waitingForBankNow => _t((
    'Транш на рассмотрении. Решение банка появится в карточке.',
    'The tranche is under review. The bank’s decision will appear here.',
    'Transh ko‘rib chiqilmoqda. Bank qarori shu kartada ko‘rinadi.',
  ));
  String get waitingForRelease => _t((
    'Транш одобрен. Выплата ещё не зарегистрирована.',
    'The tranche is approved. The payout has not been recorded yet.',
    'Transh tasdiqlangan. To‘lov hali qayd etilmagan.',
  ));
  String get keepRequest => _t((
    'Не отзывать',
    'Keep tranche',
    'Qaytarib olmaslik',
  ));
  String get recordPayment => _t((
    'Зарегистрировать выплату',
    'Record payout',
    'To‘lovni qayd etish',
  ));
  String get paymentDate => _t(('Дата платежа', 'Payment date', 'To‘lov sanasi'));
  String get paymentNumber => _t(('Номер платежа', 'Payment number', 'To‘lov raqami'));
  String get paymentHint => _t((
    'Укажите дату и номер уже проведённого платежа, затем приложите подтверждение. iBuild не переводит деньги.',
    'Enter the date and reference of a completed payment, then attach proof. iBuild does not transfer funds.',
    'Amalga oshirilgan to‘lov sanasi va raqamini kiriting, so‘ng tasdiqlovchi hujjatni yuklang. iBuild pul o‘tkazmaydi.',
  ));
  String get paymentTitle => _t(('Выплата транша', 'Paying out the tranche', 'Transhni to‘lash'));
  String get attachProof => _t(('Добавить подтверждение', 'Add the confirmation', 'Tasdiqlovchi hujjat qo‘shish'));
  String get withdrawApproval => _t(('Отменить одобрение', 'Cancel the approval', 'Ma’qullashni bekor qilish'));
  String get withdrawTitle => _t(('Отменить одобрение?', 'Cancel the approval?', 'Ma’qullash bekor qilinsinmi?'));
  String get withdrawBody => _t((
    'Отменяйте одобрение, только если выплаты не было. Сумма вернётся в доступный остаток.',
    'Cancel the approval only if no payout has been made. The amount returns to the available balance.',
    'To‘lov amalga oshirilmagan bo‘lsa, tasdiqni bekor qiling. Summa mavjud qoldiqqa qaytadi.',
  ));
  String get newFromRejection => _t((
    'Создать черновик на основе транша',
    'Create draft from this tranche',
    'Shu transh asosida qoralama yaratish',
  ));
  String get paymentLine => _t(('Платёж', 'Payment', 'To‘lov'));
  String get noRole => _t(('Нет роли на объекте', 'No role on a project', 'Obyektda roli yo‘q'));
  String get serverError => _t((
    'Не удалось выполнить действие. Повторите попытку.',
    'The action could not be completed. Try again.',
    'Amalni bajarib bo‘lmadi. Qayta urinib ko‘ring.',
  ));
  String get offline => _t((
    'Нет связи с сервером. Проверьте интернет и попробуйте ещё раз.',
    'Cannot reach the server. Check your internet and try again.',
    'Server bilan aloqa yo‘q. Internetni tekshirib, qayta urinib ko‘ring.',
  ));

  // ── Statuses and roles ─────────────────────────────────────────────────

  static const statusCodes = [
    'draft',
    'submitted',
    'tech_approved',
    'approved',
    'paid',
    'rejected',
    'cancelled',
  ];

  String roleName(AppRole role) {
    return switch (role) {
      AppRole.director => _t(('Застройщик', 'Developer', 'Quruvchi')),
      AppRole.contractor => _t(('Подрядчик', 'Contractor', 'Pudratchi')),
      AppRole.tech => _t(('Технадзор', 'Technical supervisor', 'Texnazorat')),
      AppRole.observer => _t(('Банк', 'Bank', 'Bank')),
      AppRole.developer => _t(('Полный доступ', 'Full access', 'To‘liq kirish')),
      AppRole.platform => _t(('Администратор', 'Administrator', 'Administrator')),
    };
  }

  String rolesOf(UserProfile user) {
    if (user.platformAdmin) {
      return _t(('Администратор iBuild', 'iBuild administrator', 'iBuild administratori'));
    }
    final labels = user.memberships.map((item) => roleName(item.role)).toSet();
    if (labels.isEmpty) return noRole;
    return labels.join(', ');
  }

  String projectStatus(bool active) => active ? this.active : archived;

  String memberRole(String role) => roleName(AppRole.parse(role));

  String requestStatus(String code) {
    return switch (code) {
      'draft' => _t(('Черновик', 'Draft', 'Qoralama')),
      'submitted' => _t(('Ждёт решения банка', 'Waiting for the bank', 'Bank qarorini kutmoqda')),
      'tech_approved' => _t(('Работы подтверждены', 'Work confirmed', 'Ishlar tasdiqlangan')),
      'approved' => _t(('Ожидает выплаты', 'Awaiting payout', 'To‘lov kutilmoqda')),
      'paid' => _t(('Выплачен', 'Paid out', 'To‘langan')),
      'rejected' => _t(('Отклонён', 'Rejected', 'Rad etilgan')),
      'cancelled' => _t(('Отозван', 'Withdrawn', 'Qaytarib olingan')),
      _ => code,
    };
  }

  String eventAction(String action) {
    return switch (action) {
      'draft_saved' => _t(('Черновик сохранён', 'Draft saved', 'Qoralama saqlandi')),
      'draft_edited' => _t(('Черновик изменён', 'Draft edited', 'Qoralama o‘zgartirildi')),
      'file_added' => _t(('Добавлен файл', 'File added', 'Fayl qo‘shildi')),
      'file_removed' => _t(('Файл убран', 'File removed', 'Fayl olib tashlandi')),
      'submitted' => _t(('Транш отправлен', 'Tranche sent', 'Transh yuborildi')),
      'contact' => _t(('Банк написал застройщику', 'The bank wrote to the developer', 'Bank quruvchiga yozdi')),
      'cancelled' => _t(('Транш отозван', 'Tranche withdrawn', 'Transh qaytarib olindi')),
      'tech_approved' => _t(('Работы подтверждены', 'Work confirmed', 'Ishlar tasdiqlandi')),
      'rejected' => _t(('Транш отклонён', 'Tranche rejected', 'Transh rad etildi')),
      'approved' => _t(('Банк одобрил транш', 'The bank approved the tranche', 'Bank transhni ma’qulladi')),
      'paid' => _t(('Выплата зарегистрирована', 'Payout recorded', 'To‘lov qayd etildi')),
      'director_rejected' => _t(('Банк отклонил транш', 'The bank rejected the tranche', 'Bank transhni rad etdi')),
      'approval_withdrawn' => _t(('Одобрение отменено', 'Approval cancelled', 'Ma’qullash bekor qilindi')),
      'payment_file_added' => _t(('Добавлено подтверждение платежа', 'Payment confirmation added', 'To‘lov tasdig‘i qo‘shildi')),
      'sent_to_bank' => _t(('Отправлен в банк', 'Sent to the bank', 'Bankka yuborildi')),
      'forwarded' => _t(('Передан другому участнику', 'Passed to someone else', 'Boshqa ishtirokchiga topshirildi')),
      _ => action,
    };
  }

  /// Turns a message from the server into the reader’s language.
  /// Unknown messages are shown as they are.
  String known(String message) {
    final copy = _messageCopy[message];
    if (copy != null) return _t(copy);
    for (final row in _knownMessages) {
      if (row.$1 == message) return _t(row);
    }
    return message;
  }
}

class LocaleController extends ChangeNotifier {
  LocaleController() : language = AppLanguage.fromCode(readStoredLanguage());

  AppLanguage language;

  AppCopy get copy => AppCopy(language);

  void select(AppLanguage next) {
    if (next == language) return;
    language = next;
    writeStoredLanguage(next.name);
    notifyListeners();
  }
}

class LocaleScope extends InheritedNotifier<LocaleController> {
  const LocaleScope({
    super.key,
    required LocaleController controller,
    required super.child,
  }) : super(notifier: controller);

  static LocaleController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LocaleScope>();
    assert(scope != null, 'LocaleScope is missing');
    return scope!.notifier!;
  }

  static AppCopy copy(BuildContext context) => of(context).copy;
}

class LanguageSwitch extends StatelessWidget {
  const LanguageSwitch({super.key, this.onDark = false});

  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final locale = LocaleScope.of(context);
    final colors = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final language in AppLanguage.values)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Material(
              color: locale.language == language
                  ? (onDark ? colors.onHeroSurface : colors.accent)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadii.sm),
              child: InkWell(
                key: Key('language-${language.name}'),
                borderRadius: BorderRadius.circular(AppRadii.sm),
                onTap: () => locale.select(language),
                child: Semantics(
                  button: true,
                  selected: locale.language == language,
                  label: language.code,
                  excludeSemantics: true,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: Text(
                      language.code,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: locale.language == language
                            ? (onDark ? colors.accent : colors.onAccent)
                            : (onDark ? colors.onHeroSurface : colors.inkMuted),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
