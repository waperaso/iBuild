// Copy for the v2 landing.
//
// RU is the source of truth. EN is a full translation.
// UZ reuses the previous landing's wording where the keys match (marked "v1") and
// follows the app's own Uzbek terminology elsewhere — but the new strings were
// written here, so have a native speaker read the UZ block before launch.
window.IBUILD_V2_I18N = {
  ru: {
    title: 'iBuild — банк платит за то, что построено',
    description: 'iBuild связывает бюджет объекта, заявку на транш, заключение эксперта и решение банка в одной карточке.',

    skip: 'К содержанию',
    navProcess: 'Как работает',
    navRoles: 'Для кого',
    login: 'Войти',
    apply: 'Подать заявку',

    heroBadge: 'На стадии разработки',
    heroTitleA: 'Банк платит за то,',
    heroTitleB: 'что действительно построено',
    heroLead: 'Бюджет объекта, заявка на транш, заключение эксперта и решение банка — в одной карточке. Видно, кто что решил и на каком основании.',
    heroCta: 'Посмотреть процесс',
    heroScroll: 'Листайте',
    heroChipA: 'Осмотр выполнен',
    heroChipB: 'Нет сертификата · ГС п. 3.5',
    heroChipC: 'К выплате 1 723,9',
    frameBank: 'Кабинет банка',
    frameDeveloper: 'Кабинет застройщика',
    sample: 'Пример данных',

    problemKicker: 'Как сейчас',
    problemTitle: 'Ответ на вопрос «что построено» собирают вручную',
    problemLead: 'Банк выдаёт кредит частями. Перед каждой следующей частью нужно понять, за что он платит.',
    problem1: 'Документы врозь',
    problem1Text: 'Бюджет, счета, акты и фото лежат в файлах, чатах и почте. Кто-то сводит их заново под каждую заявку.',
    problem2: 'Осмотры не сравнить',
    problem2Text: 'Два заключения описывают разные работы разными словами. Сопоставить один выезд с другим не получается.',
    problem3: 'Просрочка всплывает поздно',
    problem3Text: 'Отдельный отчёт выглядит нормально, а график сдвигается месяц за месяцем. Это видно, когда деньги уже ушли.',

    processKicker: 'Как работает',
    processTitle: 'Путь одного транша',
    processLead: 'Четыре шага, четыре экрана. Листайте — и транш пройдёт весь путь.',
    stepRequest: 'Заявка',
    textRequest: 'Застройщик выбирает вид работ, указывает сумму и прикладывает подтверждения.',
    stepInspection: 'Осмотр',
    textInspection: 'Эксперт выезжает на объект и фиксирует фактическую готовность работ.',
    stepReview: 'Решение',
    textReview: 'Специалист сверяет суммы, разбирает замечания и готовит решение по каждой строке.',
    stepApproval: 'Согласование',
    textApproval: 'Решение уходит второму согласующему. Тот, кто готовил, согласовать его не может.',

    rolesKicker: 'Для кого',
    rolesTitle: 'У каждого своя часть работы',
    bank: 'Банк',
    bankText: 'Видит портфель объектов, очередь траншей, сроки и причины возвратов.',
    developer: 'Застройщик',
    developerText: 'Ведёт бюджет, отправляет транши и правит только спорные строки.',
    expert: 'Эксперт',
    expertText: 'Получает задание на осмотр и фиксирует готовность прямо на объекте.',

    auditKicker: 'Журнал',
    auditTitle: 'Каждое решение остаётся в истории',
    auditText: 'Кто решил, когда, на основании чего и по какой версии правил. Транш, осмотр и согласование связаны друг с другом.',
    audit1: 'Журнал изменений по объекту и траншу',
    audit2: 'Заключения осмотров с фото и координатами',
    audit3: 'Отчёты с выгрузкой в XLSX, PDF и CSV',
    audit4: 'Роль и доступ проверяются на сервере',

    closingTitle: 'Подключите свою организацию',
    closingText: 'Заявки принимаются от банков и застройщиков.',
    footerNote: 'Экраны iBuild с тестовыми данными.',
  },

  // Uzbek. Strings marked "v1" are carried over verbatim from the previous landing
  // (i18n.js). The rest follow the app's own Uzbek wording in lib/l10n.dart
  // (transh, navbat, ko'rik, mutaxassis qarori, bank qoidalari) but were written
  // here — have a native speaker read them before launch.
  uz: {
    title: 'iBuild — bank qurilgan ish uchun to\u2018laydi',
    description: 'iBuild obyekt byudjeti, transh so\u2018rovi, ekspert xulosasi va bank qarorini bitta kartada saqlaydi.',

    skip: 'Asosiy mazmunga o\u2018tish',                 // v1
    navProcess: 'Qanday ishlaydi',                   // v1
    navRoles: 'Kimlar uchun',                        // v1
    login: 'Kirish',                                 // v1
    apply: 'Ariza yuborish',                         // v1

    heroBadge: 'Ishlab chiqilmoqda',                 // v1
    heroTitleA: 'Bank haqiqatda qurilgan',
    heroTitleB: 'ish uchun to\u2018laydi',
    heroLead: 'Obyekt byudjeti, transh so\u2018rovi, ekspert xulosasi va bank qarori \u2014 bitta kartada. Kim nimani hal qilgani va qanday asosda hal qilgani ko\u2018rinib turadi.',
    heroCta: 'Jarayonni ko\u2018rish',                   // v1
    heroScroll: 'Pastga suring',
    heroChipA: 'Ko\u2018rik bajarildi',
    heroChipB: 'Sertifikat yo\u2018q \u00b7 QS 3.5-band',
    heroChipC: 'To\u2018lash uchun 1 723,9',
    frameBank: 'Bank kabineti',                      // v1
    frameDeveloper: 'Quruvchi kabineti',             // v1
    sample: 'Namunaviy ma\u2019lumotlar',               // v1

    problemKicker: 'Hozir qanday',
    problemTitle: '\u00abNima qurildi\u00bb degan savolga javob qo\u2018lda yig\u2018iladi',
    problemLead: 'Bank kreditni qismlarga bo\u2018lib beradi. Har bir keyingi qismdan oldin u nima uchun to\u2018layotganini bilishi kerak.',
    problem1: 'Hujjatlar tarqoq',
    problem1Text: 'Byudjet, hisob-fakturalar, dalolatnomalar va fotosuratlar fayllar, chatlar va pochtada yotadi. Har bir so\u2018rov uchun ularni kimdir qaytadan yig\u2018adi.',
    problem2: 'Ko\u2018riklarni solishtirib bo\u2018lmaydi',
    problem2Text: 'Ikki xulosa bir xil ishni turlicha ta\u2019riflaydi. Bir chiqishni boshqasi bilan taqqoslash imkoni yo\u2018q.',
    problem3: 'Kechikish kech ma\u2019lum bo\u2018ladi',
    problem3Text: 'Alohida hisobot yaxshi ko\u2018rinadi, grafik esa oydan oyga suriladi. Bu pul chiqib bo\u2018lganda bilinadi.',

    processKicker: 'Qanday ishlaydi',                // v1
    processTitle: 'Bitta transhning yo\u2018li',
    processLead: 'To\u2018rt bosqich, to\u2018rt ekran. Suring \u2014 transh butun yo\u2018lni bosib o\u2018tadi.',
    stepRequest: 'So\u2018rov',                          // v1
    textRequest: 'Quruvchi ish turini tanlaydi, summani kiritadi va tasdiqlovchi hujjatlarni ilova qiladi.',  // v1
    stepInspection: 'Ko\u2018rik',                       // v1
    textInspection: 'Ekspert obyektga boradi va bajarilgan ish hajmini qayd etadi.',
    stepReview: 'Qaror',                             // v1
    textReview: 'Mutaxassis summalarni solishtiradi, izohlarni ko\u2018rib chiqadi va har bir band bo\u2018yicha qaror qabul qiladi.',
    stepApproval: 'Kelishuv',                        // v1
    textApproval: 'Qaror ikkinchi kelishuvchiga boradi. Qarorni tayyorlagan odam uni kelisha olmaydi.',

    rolesKicker: 'Kimlar uchun',                     // v1
    rolesTitle: 'Har bir ishtirokchining o\u2018z vazifasi bor',
    bank: 'Bank',                                    // v1
    bankText: 'Obyektlar portfeli, transhlar navbati, muddatlar va qaytarish sabablarini ko\u2018radi.',
    developer: 'Quruvchi',                           // v1
    developerText: 'Byudjetni yuritadi, transhlarni yuboradi va faqat bahsli bandlarni tuzatadi.',
    expert: 'Ekspert',                               // v1
    expertText: 'Ko\u2018rik topshirig\u2018ini oladi va bajarilgan ish hajmini obyektning o\u2018zida qayd etadi.',

    auditKicker: 'Jurnal',
    auditTitle: 'Har bir qaror tarixda qoladi',
    auditText: 'Kim, qachon, qanday asosda va qoidalarning qaysi versiyasi bo\u2018yicha hal qilgan. Transh, ko\u2018rik va kelishuv bir-biriga bog\u2018langan.',
    audit1: 'Obyekt va transh bo\u2018yicha o\u2018zgarishlar jurnali',
    audit2: 'Foto va koordinatalar bilan ko\u2018rik xulosalari',
    audit3: 'XLSX, PDF va CSV ga yuklab olinadigan hisobotlar',
    audit4: 'Rol va ruxsat serverda tekshiriladi',

    closingTitle: 'Tashkilotingizni ulang',          // v1
    closingText: 'Banklar va quruvchilar ariza yuborishi mumkin.',  // v1
    footerNote: 'iBuild ekranlari namunaviy ma\u2019lumotlar bilan.',
  },

  en: {
    title: 'iBuild — the bank pays for what is actually built',
    description: 'iBuild keeps the project budget, the tranche request, the inspection findings and the bank decision on one card.',

    skip: 'Skip to content',
    navProcess: 'How it works',
    navRoles: "Who it's for",
    login: 'Sign in',
    apply: 'Apply for access',

    heroBadge: 'In development',
    heroTitleA: 'The bank pays for',
    heroTitleB: 'what is actually built',
    heroLead: 'The project budget, the tranche request, the inspection findings and the decision — on one card. You can see who decided what, and on what grounds.',
    heroCta: 'See the workflow',
    heroScroll: 'Scroll',
    heroChipA: 'Inspection done',
    heroChipB: 'No certificate · Rule 3.5',
    heroChipC: 'To pay out 1 723,9',
    frameBank: 'Bank workspace',
    frameDeveloper: 'Developer workspace',
    sample: 'Sample data',

    problemKicker: 'Today',
    problemTitle: 'The answer to "what has been built" is assembled by hand',
    problemLead: 'A construction loan is paid out in parts. Before each next part, the bank has to know what it is paying for.',
    problem1: 'Evidence is scattered',
    problem1Text: 'Budgets, invoices, acts and site photos live across files, chats and email. Someone reconciles them again for every request.',
    problem2: 'Inspections do not compare',
    problem2Text: 'Two reports describe different work in different words, so one visit cannot be matched against the last.',
    problem3: 'Delays surface late',
    problem3Text: 'A single report reads fine while the schedule slips month after month. It shows up once the money is already out.',

    processKicker: 'How it works',
    processTitle: 'The path of one tranche',
    processLead: 'Four steps, four screens. Keep scrolling and the tranche goes the whole way.',
    stepRequest: 'Request',
    textRequest: 'The developer picks the work item, enters the amount and attaches the evidence.',
    stepInspection: 'Inspection',
    textInspection: 'The expert visits the site and records how much of the work is actually done.',
    stepReview: 'Decision',
    textReview: 'The specialist checks the amounts, works through the findings and decides line by line.',
    stepApproval: 'Sign-off',
    textApproval: 'The decision goes to a second approver. Whoever prepared it cannot sign it off.',

    rolesKicker: "Who it's for",
    rolesTitle: 'Each side has its own part of the work',
    bank: 'Bank',
    bankText: 'Sees the portfolio, the tranche queue, the deadlines and the reasons for every return.',
    developer: 'Developer',
    developerText: 'Keeps the budget, submits tranches and corrects only the lines in dispute.',
    expert: 'Expert',
    expertText: 'Receives the inspection task and records what is done, on site.',

    auditKicker: 'Journal',
    auditTitle: 'Every decision stays on the record',
    auditText: 'Who decided, when, on what grounds and under which version of the rules. The tranche, the inspection and the sign-off stay attached to each other.',
    audit1: 'Change journal on every project and tranche',
    audit2: 'Inspection findings with photos and coordinates',
    audit3: 'Reports exported to XLSX, PDF and CSV',
    audit4: 'Role and access checked on the server',

    closingTitle: 'Connect your organisation',
    closingText: 'Applications are accepted from banks and developers.',
    footerNote: 'iBuild screens with sample data.',
  },
};
