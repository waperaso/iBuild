/// What the sign-up form asks and which papers it wants.
///
/// The server holds the same list in `server/lib/src/registration_spec.dart`
/// and decides what is valid. `registration_spec_test.dart` checks that the
/// form keys, choices and papers match on both sides.
///
/// Legal base: Law ZRU-660-II of 26.08.2004 (know your customer), Law ZRU-547
/// of 02.07.2019 (personal data), Presidential Decree UP-11 of 27.01.2025
/// (housing built with buyers' money).
library;

import 'l10n.dart';

/// Russian, English, Uzbek.
typedef Words = (String, String, String);

enum RegKind { text, long, digits, phone, email, date, money, number, percent, choice, yesNo }

class RegChoice {
  const RegChoice(this.code, this.label);

  final String code;
  final Words label;
}

class RegField {
  const RegField(
    this.key,
    this.kind,
    this.label, {
    this.required = true,
    this.length = 0,
    this.max = 200,
    this.choices = const [],
    this.help,
    this.wide = false,
    this.suffix,
  });

  final String key;
  final RegKind kind;
  final Words label;
  final bool required;
  final int length;
  final int max;
  final List<RegChoice> choices;
  final Words? help;
  final bool wide;
  final Words? suffix;
}

enum RegExtra { none, owners, licenses, interests }

class RegSection {
  const RegSection(this.id, this.title, this.fields, {this.intro, this.extra = RegExtra.none});

  final String id;
  final Words title;
  final Words? intro;
  final List<RegField> fields;
  final RegExtra extra;
}

class RegDoc {
  const RegDoc(this.type, this.title, this.hint, {this.required = true});

  final String type;
  final Words title;
  final Words hint;
  final bool required;
}

const _yes = RegChoice('yes', ('Да', 'Yes', 'Ha'));
const _no = RegChoice('no', ('Нет', 'No', 'Yo‘q'));
const yesNoChoices = [_yes, _no];

const _regions = [
  RegChoice('karakalpakstan', ('Республика Каракалпакстан', 'Republic of Karakalpakstan', 'Qoraqalpog‘iston Respublikasi')),
  RegChoice('andijan', ('Андижанская область', 'Andijan region', 'Andijon viloyati')),
  RegChoice('bukhara', ('Бухарская область', 'Bukhara region', 'Buxoro viloyati')),
  RegChoice('jizzakh', ('Джизакская область', 'Jizzakh region', 'Jizzax viloyati')),
  RegChoice('kashkadarya', ('Кашкадарьинская область', 'Kashkadarya region', 'Qashqadaryo viloyati')),
  RegChoice('navoi', ('Навоийская область', 'Navoi region', 'Navoiy viloyati')),
  RegChoice('namangan', ('Наманганская область', 'Namangan region', 'Namangan viloyati')),
  RegChoice('samarkand', ('Самаркандская область', 'Samarkand region', 'Samarqand viloyati')),
  RegChoice('surkhandarya', ('Сурхандарьинская область', 'Surkhandarya region', 'Surxondaryo viloyati')),
  RegChoice('syrdarya', ('Сырдарьинская область', 'Syrdarya region', 'Sirdaryo viloyati')),
  RegChoice('tashkent_region', ('Ташкентская область', 'Tashkent region', 'Toshkent viloyati')),
  RegChoice('fergana', ('Ферганская область', 'Fergana region', 'Farg‘ona viloyati')),
  RegChoice('khorezm', ('Хорезмская область', 'Khorezm region', 'Xorazm viloyati')),
  RegChoice('tashkent_city', ('город Ташкент', 'Tashkent city', 'Toshkent shahri')),
];

const _callTimes = [
  RegChoice('morning', ('Утром, 9–12', 'Morning, 9–12', 'Ertalab, 9–12')),
  RegChoice('day', ('Днём, 12–17', 'Daytime, 12–17', 'Kunduzi, 12–17')),
  RegChoice('evening', ('Вечером, 17–20', 'Evening, 17–20', 'Kechqurun, 17–20')),
  RegChoice('any', ('В любое время', 'Any time', 'Istalgan vaqtda')),
];

const _languages = [
  RegChoice('ru', ('Русский', 'Russian', 'Rus tili')),
  RegChoice('uz', ('Узбекский', 'Uzbek', 'O‘zbek tili')),
  RegChoice('en', ('Английский', 'English', 'Ingliz tili')),
];

const _phoneHelp = ('Номер, по которому мы позвоним.', 'The number we will call.', 'Biz qo‘ng‘iroq qiladigan raqam.');

const developerSections = <RegSection>[
  RegSection(
    'org',
    ('О компании', 'About the company', 'Kompaniya haqida'),
    intro: (
      'Пишите так, как указано в свидетельстве о регистрации.',
      'Write it the way it is in the registration certificate.',
      'Ro‘yxatdan o‘tish guvohnomasidagidek yozing.',
    ),
    [
      RegField('org_full_name', RegKind.text, ('Полное название', 'Full name', 'To‘liq nomi'), max: 300, wide: true),
      RegField('org_short_name', RegKind.text, ('Краткое название', 'Short name', 'Qisqa nomi'), required: false),
      RegField('legal_form', RegKind.choice, ('Форма компании', 'Company type', 'Kompaniya shakli'), choices: [
        RegChoice('llc', ('ООО', 'LLC', 'MChJ')),
        RegChoice('jsc', ('Акционерное общество', 'Joint-stock company', 'Aksiyadorlik jamiyati')),
        RegChoice('private', ('Частное предприятие', 'Private enterprise', 'Xususiy korxona')),
        RegChoice('other', ('Другая', 'Other', 'Boshqa')),
      ]),
      RegField('inn', RegKind.digits, ('ИНН', 'Tax number (INN)', 'STIR'), length: 9, help: ('9 цифр', '9 digits', '9 ta raqam')),
      RegField('oked', RegKind.digits, ('Код ОКЭД', 'Activity code (OKED)', 'IFUT kodi'), required: false, length: 5, help: ('5 цифр, если знаете', '5 digits, if you know it', 'Bilsangiz, 5 ta raqam')),
      RegField('reg_number', RegKind.text, ('Номер регистрации', 'Registration number', 'Ro‘yxatdan o‘tish raqami'), max: 60),
      RegField('reg_date', RegKind.date, ('Дата регистрации', 'Registration date', 'Ro‘yxatdan o‘tgan sana')),
      RegField('reg_authority', RegKind.text, ('Кто зарегистрировал', 'Registered by', 'Ro‘yxatdan o‘tkazgan organ')),
      RegField('charter_capital', RegKind.money, ('Уставный капитал', 'Charter capital', 'Ustav kapitali'), suffix: ('сум', 'UZS', 'so‘m')),
      RegField('legal_address', RegKind.text, ('Юридический адрес', 'Legal address', 'Yuridik manzil'), max: 500, wide: true),
      RegField('actual_address', RegKind.text, ('Где находится офис', 'Office address', 'Ofis manzili'), max: 500, wide: true),
      RegField('region', RegKind.choice, ('Область или город', 'Region or city', 'Viloyat yoki shahar'), choices: _regions),
      RegField('website', RegKind.text, ('Сайт', 'Website', 'Veb-sayt'), required: false),
      RegField('org_phone', RegKind.phone, ('Телефон компании', 'Company phone', 'Kompaniya telefoni')),
      RegField('org_email', RegKind.email, ('Почта компании', 'Company email', 'Kompaniya pochtasi')),
    ],
  ),
  RegSection(
    'director',
    ('Руководитель', 'Head of the company', 'Rahbar'),
    [
      RegField('dir_name', RegKind.text, ('ФИО', 'Full name', 'F.I.Sh.'), wide: true),
      RegField('dir_position', RegKind.text, ('Должность', 'Position', 'Lavozim')),
      RegField('dir_pinfl', RegKind.digits, ('ПИНФЛ', 'Personal ID number (PINFL)', 'JShShIR'), length: 14, help: ('14 цифр', '14 digits', '14 ta raqam')),
      RegField('dir_passport', RegKind.text, ('Паспорт или ID-карта', 'Passport or ID card', 'Pasport yoki ID-karta'), max: 12, help: ('Две буквы и 7 цифр, например AA1234567', 'Two letters and 7 digits, for example AA1234567', 'Ikki harf va 7 ta raqam, masalan AA1234567')),
      RegField('dir_passport_issued', RegKind.date, ('Когда выдан', 'Issued on', 'Berilgan sana')),
      RegField('dir_passport_authority', RegKind.text, ('Кем выдан', 'Issued by', 'Kim bergan')),
      RegField('dir_citizenship', RegKind.text, ('Гражданство', 'Citizenship', 'Fuqarolik'), max: 80),
      RegField('dir_phone', RegKind.phone, ('Телефон', 'Phone', 'Telefon')),
      RegField('dir_email', RegKind.email, ('Почта', 'Email', 'Pochta')),
      RegField('dir_basis', RegKind.choice, ('Действует на основании', 'Acts under', 'Quyidagi asosda ish yuritadi'), choices: [
        RegChoice('charter', ('Устава', 'The charter', 'Ustav')),
        RegChoice('poa', ('Доверенности', 'A power of attorney', 'Ishonchnoma')),
      ]),
    ],
  ),
  RegSection(
    'owners',
    ('Владельцы компании', 'Owners of the company', 'Kompaniya egalari'),
    intro: (
      'Запишите членов совета директоров и учредителей компании.',
      'List the members of the board of directors and the founders of the company.',
      'Kompaniyaning direktorlar kengashi a’zolari va ta’sischilarini yozing.',
    ),
    [
      RegField('beneficial_name', RegKind.text, ('Конечный владелец, ФИО', 'Final owner, full name', 'Oxirgi benefitsiar egasi, F.I.Sh.'), wide: true),
      RegField('beneficial_id', RegKind.text, ('ПИНФЛ или номер документа', 'PINFL or document number', 'JShShIR yoki hujjat raqami'), max: 40),
      RegField('pdl', RegKind.yesNo, ('Есть ли среди владельцев или руководителей высокопоставленные чиновники?', 'Is any owner or manager a senior public official?', 'Egalar yoki rahbarlar orasida yuqori lavozimli amaldor bormi?'), choices: yesNoChoices, wide: true),
      RegField('pdl_note', RegKind.long, ('Кто это и на какой должности', 'Who it is and the position', 'Kim va qaysi lavozimda'), required: false, max: 500, wide: true),
    ],
    extra: RegExtra.owners,
  ),
  RegSection(
    'licenses',
    ('Лицензии', 'Licences', 'Litsenziyalar'),
    intro: (
      'Добавьте лицензию, если для вашей работы она нужна. Если нет, пропустите этот раздел.',
      'Add a licence if your work needs one. If not, skip this part.',
      'Ishingiz uchun litsenziya kerak bo‘lsa, qo‘shing. Aks holda bu bo‘limni o‘tkazib yuboring.',
    ),
    [],
    extra: RegExtra.licenses,
  ),
  RegSection(
    'object',
    ('Первый объект', 'First project', 'Birinchi obyekt'),
    [
      RegField('object_name', RegKind.text, ('Название TJ', 'Name of the complex', 'TJ nomi')),
      RegField('object_address', RegKind.text, ('Адрес', 'Address', 'Manzil'), max: 500, wide: true),
      RegField('object_cadastre', RegKind.text, ('Кадастровый номер участка', 'Land cadastral number', 'Yer uchastkasining kadastr raqami'), max: 60),
      RegField('land_basis', RegKind.choice, ('Право на землю', 'Right to the land', 'Yerga bo‘lgan huquq'), choices: [
        RegChoice('lease', ('Аренда', 'Lease', 'Ijara')),
        RegChoice('use', ('Право пользования', 'Right of use', 'Foydalanish huquqi')),
        RegChoice('ownership', ('Собственность', 'Ownership', 'Mulk')),
        RegChoice('other', ('Другое', 'Other', 'Boshqa')),
      ]),
      RegField('land_doc_no', RegKind.text, ('Документ на землю: номер и дата', 'Land document: number and date', 'Yer hujjati: raqami va sanasi'), max: 120, wide: true),
      RegField('permit_number', RegKind.text, ('Номер разрешения на строительство', 'Building permit number', 'Qurilish ruxsatnomasi raqami'), max: 60),
      RegField('permit_date', RegKind.date, ('Дата разрешения', 'Permit date', 'Ruxsatnoma sanasi')),
      RegField('expertise_number', RegKind.text, ('Номер заключения экспертизы', 'Design review conclusion number', 'Ekspertiza xulosasi raqami'), max: 60),
      RegField('expertise_date', RegKind.date, ('Дата заключения', 'Conclusion date', 'Xulosa sanasi')),
      RegField('object_cost', RegKind.money, ('Стоимость стройки', 'Construction cost', 'Qurilish qiymati'), suffix: ('сум', 'UZS', 'so‘m')),
      RegField('object_area', RegKind.number, ('Общая площадь', 'Total area', 'Umumiy maydon'), suffix: ('м²', 'm²', 'm²')),
      RegField('object_floors', RegKind.number, ('Этажей', 'Floors', 'Qavatlar'), required: false),
      RegField('object_flats', RegKind.number, ('Квартир', 'Flats', 'Xonadonlar'), required: false),
      RegField('commissioning_date', RegKind.date, ('Когда сдаёте по проекту', 'Planned handover date', 'Loyiha bo‘yicha topshirish sanasi')),
      RegField('own_funds_percent', RegKind.percent, ('Своих денег в проекте', 'Your own money in the project', 'Loyihada o‘z mablag‘ingiz'), suffix: ('%', '%', '%'), help: (
        'Банки обычно ждут от застройщика не меньше 30% своих средств (указ УП-11 от 27.01.2025).',
        'Banks usually expect at least 30% of the developer’s own money (decree UP-11 of 27.01.2025).',
        'Banklar odatda quruvchidan kamida 30% o‘z mablag‘ini kutadi (2025-yil 27-yanvardagi PF-11-son farmon).',
      )),
      RegField('escrow_status', RegKind.choice, ('Эскроу-счёт для денег покупателей', 'Escrow account for buyers’ money', 'Xaridorlar puli uchun eskrou hisob'), choices: [
        RegChoice('none', ('Пока нет', 'Not yet', 'Hozircha yo‘q')),
        RegChoice('planned', ('Планируем открыть', 'We plan to open one', 'Ochishni rejalashtiryapmiz')),
        RegChoice('opened', ('Уже открыт', 'Already open', 'Allaqachon ochilgan')),
      ]),
      RegField('partner_bank', RegKind.text, ('Банк-партнёр по этому объекту', 'Partner bank for this project', 'Shu obyekt bo‘yicha hamkor bank'), required: false),
    ],
  ),
  RegSection(
    'bank',
    ('Банковские реквизиты компании', 'Company bank details', 'Kompaniyaning bank rekvizitlari'),
    [
      RegField('bank_name', RegKind.text, ('Банк, где открыт счёт', 'Bank holding the account', 'Hisob ochilgan bank')),
      RegField('bank_mfo', RegKind.digits, ('МФО банка', 'Bank code (MFO)', 'Bank MFO si'), length: 5, help: ('5 цифр', '5 digits', '5 ta raqam')),
      RegField('bank_inn', RegKind.digits, ('ИНН', 'Tax number (INN)', 'STIR'), required: false, length: 9, help: ('9 цифр, как в разделе «О компании»', '9 digits, as in “About the company”', '9 ta raqam, “Kompaniya haqida” dagidek')),
      RegField('bank_oked', RegKind.digits, ('ОКЭД', 'Activity code (OKED)', 'IFUT'), required: false, length: 5, help: ('5 цифр', '5 digits', '5 ta raqam')),
      RegField('bank_account', RegKind.digits, ('Расчётный счёт в сумах (UZS)', 'Account in sums (UZS)', 'So‘m hisob raqami (UZS)'), length: 20, help: ('20 цифр', '20 digits', '20 ta raqam')),
      RegField('acc_usd', RegKind.digits, ('Валютный счёт USD', 'Currency account USD', 'Valyuta hisobi USD'), required: false, length: 20, help: ('20 цифр, если есть', '20 digits, if you have one', 'Bo‘lsa, 20 ta raqam')),
      RegField('acc_cny', RegKind.digits, ('Валютный счёт CNY', 'Currency account CNY', 'Valyuta hisobi CNY'), required: false, length: 20, help: ('20 цифр, если есть', '20 digits, if you have one', 'Bo‘lsa, 20 ta raqam')),
      RegField('acc_eur', RegKind.digits, ('Валютный счёт EUR', 'Currency account EUR', 'Valyuta hisobi EUR'), required: false, length: 20, help: ('20 цифр, если есть', '20 digits, if you have one', 'Bo‘lsa, 20 ta raqam')),
      RegField('acc_rub', RegKind.digits, ('Валютный счёт RUB', 'Currency account RUB', 'Valyuta hisobi RUB'), required: false, length: 20, help: ('20 цифр, если есть', '20 digits, if you have one', 'Bo‘lsa, 20 ta raqam')),
    ],
  ),
  RegSection(
    'contact',
    ('Кто с вами свяжется', 'Who we will talk to', 'Biz kim bilan gaplashamiz'),
    intro: (
      'Мы позвоним, чтобы подтвердить заявку и уточнить детали. Выберите удобное время.',
      'We will call to confirm the application and ask about details. Pick a convenient time.',
      'Arizani tasdiqlash va tafsilotlarni aniqlash uchun qo‘ng‘iroq qilamiz. Qulay vaqtni tanlang.',
    ),
    [
      RegField('contact_name', RegKind.text, ('ФИО', 'Full name', 'F.I.Sh.')),
      RegField('contact_position', RegKind.text, ('Должность', 'Position', 'Lavozim')),
      RegField('contact_phone', RegKind.phone, ('Телефон для звонка', 'Phone for the call', 'Qo‘ng‘iroq uchun telefon'), help: _phoneHelp),
      RegField('contact_email', RegKind.email, ('Почта', 'Email', 'Pochta'), help: (
        'Эта почта станет вашим логином после одобрения.',
        'This email becomes your login once you are approved.',
        'Tasdiqlangach bu pochta loginingiz bo‘ladi.',
      )),
      RegField('call_time', RegKind.choice, ('Когда звонить', 'When to call', 'Qachon qo‘ng‘iroq qilish'), choices: _callTimes),
      RegField('language', RegKind.choice, ('Язык разговора', 'Language for the call', 'Suhbat tili'), choices: _languages),
      RegField('comment', RegKind.long, ('Что ещё нам знать', 'Anything else we should know', 'Yana nimani bilishimiz kerak'), required: false, max: 1500, wide: true),
    ],
  ),
];

const bankInterestChoices = [
  RegChoice('project_finance', ('Финансирование стройки', 'Construction lending', 'Qurilishni moliyalashtirish')),
  RegChoice('escrow', ('Эскроу-счета покупателей', 'Buyers’ escrow accounts', 'Xaridorlarning eskrou hisoblari')),
  RegChoice('tranche_control', ('Выплаты траншами по готовности работ', 'Paying in tranches as work is done', 'Ish tayyorligi bo‘yicha transhlar to‘lovi')),
  RegChoice('monitoring', ('Контроль хода стройки', 'Monitoring construction progress', 'Qurilish borishini nazorat qilish')),
  RegChoice('other', ('Другое', 'Other', 'Boshqa')),
];

const bankSections = <RegSection>[
  RegSection(
    'org',
    ('О банке', 'About the bank', 'Bank haqida'),
    [
      RegField('org_full_name', RegKind.text, ('Полное название банка', 'Full name of the bank', 'Bankning to‘liq nomi'), max: 300, wide: true),
      RegField('inn', RegKind.digits, ('ИНН', 'Tax number (INN)', 'STIR'), length: 9, help: ('9 цифр', '9 digits', '9 ta raqam')),
      RegField('bank_mfo', RegKind.digits, ('МФО', 'Bank code (MFO)', 'MFO'), length: 5, help: ('5 цифр', '5 digits', '5 ta raqam')),
      RegField('license_number', RegKind.text, ('Номер лицензии Центрального банка', 'Central Bank licence number', 'Markaziy bank litsenziyasi raqami'), max: 60),
      RegField('license_date', RegKind.date, ('Дата лицензии', 'Licence date', 'Litsenziya sanasi')),
      RegField('legal_address', RegKind.text, ('Юридический адрес', 'Legal address', 'Yuridik manzil'), max: 500, wide: true),
      RegField('region', RegKind.choice, ('Область или город', 'Region or city', 'Viloyat yoki shahar'), choices: _regions),
      RegField('website', RegKind.text, ('Сайт', 'Website', 'Veb-sayt'), required: false),
      RegField('org_phone', RegKind.phone, ('Телефон банка', 'Bank phone', 'Bank telefoni')),
      RegField('org_email', RegKind.email, ('Почта банка', 'Bank email', 'Bank pochtasi')),
      RegField('branch', RegKind.text, ('Подразделение, которое занимается стройкой', 'Department that handles construction lending', 'Qurilish kreditlari bilan shug‘ullanuvchi bo‘lim'), required: false, wide: true),
    ],
  ),
  RegSection(
    'interest',
    ('Что вам интересно', 'What you are interested in', 'Sizni nima qiziqtiradi'),
    intro: (
      'Отметьте всё, что подходит. Это поможет нам заранее понять, о чём говорить.',
      'Tick everything that fits. It helps us know what to talk about.',
      'Mos keladigan hammasini belgilang. Bu nima haqida gaplashishni oldindan bilishga yordam beradi.',
    ),
    [
      RegField('active_projects', RegKind.number, ('Сколько строек сейчас финансируете', 'How many construction projects you fund now', 'Hozir nechta qurilishni moliyalashtiryapsiz'), required: false),
    ],
    extra: RegExtra.interests,
  ),
  RegSection(
    'contact',
    ('Кто с вами свяжется', 'Who we will talk to', 'Biz kim bilan gaplashamiz'),
    intro: (
      'Мы позвоним, чтобы познакомиться и рассказать, как подключить банк.',
      'We will call to get to know you and explain how to connect the bank.',
      'Tanishish va bankni qanday ulashni tushuntirish uchun qo‘ng‘iroq qilamiz.',
    ),
    [
      RegField('contact_name', RegKind.text, ('ФИО', 'Full name', 'F.I.Sh.')),
      RegField('contact_position', RegKind.text, ('Должность', 'Position', 'Lavozim')),
      RegField('contact_phone', RegKind.phone, ('Телефон для звонка', 'Phone for the call', 'Qo‘ng‘iroq uchun telefon'), help: _phoneHelp),
      RegField('contact_email', RegKind.email, ('Почта', 'Email', 'Pochta')),
      RegField('authority_basis', RegKind.choice, ('Вы представляете банк на основании', 'You represent the bank under', 'Siz bankni quyidagi asosda vakil qilasiz'), choices: [
        RegChoice('poa', ('Доверенности', 'A power of attorney', 'Ishonchnoma')),
        RegChoice('order', ('Приказа', 'An order', 'Buyruq')),
        RegChoice('charter', ('Устава', 'The charter', 'Ustav')),
      ]),
      RegField('call_time', RegKind.choice, ('Когда звонить', 'When to call', 'Qachon qo‘ng‘iroq qilish'), choices: _callTimes),
      RegField('language', RegKind.choice, ('Язык разговора', 'Language for the call', 'Suhbat tili'), choices: _languages),
      RegField('comment', RegKind.long, ('Что ещё нам знать', 'Anything else we should know', 'Yana nimani bilishimiz kerak'), required: false, max: 1500, wide: true),
    ],
  ),
];

const developerDocs = <RegDoc>[
  RegDoc('registration_cert', ('Свидетельство о регистрации', 'Registration certificate', 'Ro‘yxatdan o‘tish guvohnomasi'), ('Или свежая выписка из реестра.', 'Or a recent extract from the register.', 'Yoki reyestrdan yangi ko‘chirma.')),
  RegDoc('charter', ('Устав', 'Charter', 'Ustav'), ('Действующая редакция, все страницы.', 'Current version, every page.', 'Amaldagi tahrir, barcha sahifalar.')),
  RegDoc('director_id', ('Паспорт или ID-карта руководителя', 'Head’s passport or ID card', 'Rahbarning pasporti yoki ID-kartasi'), ('Разворот с фото и данными.', 'The page with the photo and details.', 'Rasm va ma’lumotlar bor sahifa.')),
  RegDoc('owners_proof', ('Документ об учредителях и их долях', 'Paper showing owners and their shares', 'Ta’sischilar va ularning ulushlari haqida hujjat'), ('Выписка или реестр участников. Если владелец компания, схема владения до человека.', 'An extract or the register of members. If an owner is a company, the ownership chain down to the person.', 'Ko‘chirma yoki ishtirokchilar reyestri. Ega kompaniya bo‘lsa, shaxsgacha egalik zanjiri.')),
  RegDoc('bank_details', ('Справка банка о расчётном счёте', 'Bank letter about the account', 'Bankning hisob raqami haqida ma’lumotnomasi'), ('Подойдёт справка или реквизиты на бланке банка.', 'A letter or details on the bank’s letterhead.', 'Bank blankasidagi ma’lumotnoma yoki rekvizitlar mos keladi.')),
  RegDoc('land_rights', ('Кадастровая документация', 'Cadastral documentation', 'Kadastr hujjatlari'), ('Кадастровый паспорт и выписка на участок, а также документ о праве на землю.', 'Cadastral passport and extract for the plot, plus the document of the right to the land.', 'Yer uchastkasi kadastr pasporti va ko‘chirmasi hamda yerga bo‘lgan huquq hujjati.')),
  RegDoc('construction_permit', ('Разрешение на строительство', 'Building permit', 'Qurilish ruxsatnomasi'), ('На объект, который вы указали выше.', 'For the project you listed above.', 'Yuqorida ko‘rsatgan obyekt uchun.')),
  RegDoc('expertise_conclusion', ('Заключение экспертизы проекта', 'Design review conclusion', 'Loyiha ekspertizasi xulosasi'), ('Положительное заключение по проектной документации.', 'The positive conclusion on the design documents.', 'Loyiha hujjatlari bo‘yicha ijobiy xulosa.')),
  RegDoc('tax_clearance', ('Официальная справка об отсутствии налоговой задолженности', 'Official tax clearance certificate', 'Soliq qarzi yo‘qligi haqida rasmiy ma’lumotnoma'), ('Только официальная справка налогового органа, выданная недавно. Без неё заявку не одобрят.', 'Only an official certificate from the tax authority, issued recently. The application cannot be approved without it.', 'Soliq organining yaqinda berilgan rasmiy ma’lumotnomasi. Usiz ariza tasdiqlanmaydi.')),
  RegDoc('ecology_approval', ('Заключение экологической экспертизы', 'Environmental approval', 'Ekologik ekspertiza xulosasi'), ('Документ о том, что комитет по экологии согласовал проект.', 'The document showing the ecology committee has approved the project.', 'Ekologiya qo‘mitasi loyihani kelishgani haqidagi hujjat.')),
  RegDoc('financials', ('Бухгалтерская отчётность за последний год', 'Last year’s financial statements', 'Oxirgi yilgi buxgalteriya hisoboti'), ('Баланс и отчёт о прибылях.', 'Balance sheet and profit statement.', 'Balans va foyda hisoboti.'), required: false),
  RegDoc('license', ('Лицензии', 'Licences', 'Litsenziyalar'), ('Если для вашей работы они нужны.', 'If your work needs them.', 'Ishingiz uchun kerak bo‘lsa.'), required: false),
  RegDoc('poa', ('Доверенность', 'Power of attorney', 'Ishonchnoma'), ('Если заявку подаёт не руководитель.', 'If someone other than the head applies.', 'Ariza rahbar tomonidan berilmasa.'), required: false),
  RegDoc('bank_letter', ('Письмо банка по этому объекту', 'Bank letter about this project', 'Shu obyekt bo‘yicha bank xati'), ('Договор или письмо о финансировании или эскроу, если уже есть.', 'A financing or escrow agreement or letter, if you have one.', 'Moliyalashtirish yoki eskrou shartnomasi yoki xati, agar bo‘lsa.'), required: false),
  RegDoc('other', ('Другие документы', 'Other documents', 'Boshqa hujjatlar'), ('Всё, что поможет нас убедить.', 'Anything that helps us check you.', 'Tekshirishda yordam beradigan boshqa hujjatlar.'), required: false),
];

const bankDocs = <RegDoc>[
  RegDoc('bank_license', ('Лицензия Центрального банка', 'Central Bank licence', 'Markaziy bank litsenziyasi'), ('На банковские операции.', 'For banking operations.', 'Bank operatsiyalariga.')),
  RegDoc('bank_registration', ('Свидетельство о регистрации банка', 'Bank registration certificate', 'Bankni ro‘yxatdan o‘tkazish guvohnomasi'), ('Или свежая выписка из реестра.', 'Or a recent extract from the register.', 'Yoki reyestrdan yangi ko‘chirma.')),
  RegDoc('charter', ('Устав банка', 'Bank charter', 'Bank ustavi'), ('Действующая редакция, все страницы.', 'Current version, every page.', 'Amaldagi tahrir, barcha sahifalar.')),
  RegDoc('authority', ('Документ о ваших полномочиях', 'Paper showing your authority', 'Vakolatingizni tasdiqlovchi hujjat'), ('Доверенность или приказ, по которому вы представляете банк.', 'The power of attorney or order under which you represent the bank.', 'Bankni vakil qilish uchun ishonchnoma yoki buyruq.')),
  RegDoc('representative_id', ('Паспорт или ID-карта представителя', 'Representative’s passport or ID card', 'Vakilning pasporti yoki ID-kartasi'), ('Разворот с фото и данными.', 'The page with the photo and details.', 'Rasm va ma’lumotlar bor sahifa.')),
  RegDoc('aml_policy', ('Правила внутреннего контроля (ПОД/ФТ)', 'Internal control rules (AML/CFT)', 'Ichki nazorat qoidalari (JKPYQ/TMM)'), ('Как банк проверяет клиентов и операции.', 'How the bank checks clients and transactions.', 'Bank mijozlar va operatsiyalarni qanday tekshiradi.'), required: false),
  RegDoc('lending_terms', ('Условия кредитования застройщиков', 'Developer lending terms', 'Quruvchilarni kreditlash shartlari'), ('Ставки, сроки, требования к залогу и своим средствам.', 'Rates, terms, collateral and own-funds requirements.', 'Foiz stavkalari, muddatlar, garov va o‘z mablag‘iga talablar.'), required: false),
  RegDoc('escrow_template', ('Типовой договор эскроу', 'Standard escrow agreement', 'Eskrou shartnomasining namunasi'), ('Если банк открывает эскроу-счета.', 'If the bank opens escrow accounts.', 'Bank eskrou hisoblarini ochsa.'), required: false),
  RegDoc('financials', ('Финансовая отчётность банка', 'Bank financial statements', 'Bankning moliyaviy hisoboti'), ('Последний годовой отчёт или аудиторское заключение.', 'The last annual report or audit opinion.', 'Oxirgi yillik hisobot yoki audit xulosasi.'), required: false),
  RegDoc('other', ('Другие документы', 'Other documents', 'Boshqa hujjatlar'), ('Презентация, условия, всё полезное.', 'A presentation, terms, anything useful.', 'Taqdimot, shartlar va boshqa foydali narsalar.'), required: false),
];

List<RegSection> sectionsFor(String kind) => kind == 'bank' ? bankSections : developerSections;
List<RegDoc> docsFor(String kind) => kind == 'bank' ? bankDocs : developerDocs;

Iterable<RegField> allFields(String kind) sync* {
  for (final section in sectionsFor(kind)) {
    yield* section.fields;
  }
}

const checkLabels = <String, Words>{
  'registry': ('Данные компании и ИНН сверены с государственным реестром', 'Company details and tax number match the state register', 'Kompaniya ma’lumotlari va STIR davlat reyestri bilan solishtirildi'),
  'director': ('Руководитель и его полномочия подтверждены документами', 'The head and their authority are confirmed by documents', 'Rahbar va uning vakolatlari hujjatlar bilan tasdiqlandi'),
  'owners': ('Владельцы, их доли и конечный владелец установлены', 'Owners, their shares and the final owner are established', 'Egalar, ularning ulushlari va oxirgi benefitsiar aniqlandi'),
  'screening': ('Компания и владельцы проверены по перечням причастных к терроризму и отмыванию денег', 'Company and owners checked against the terrorism and money-laundering lists', 'Kompaniya va egalar terrorizm va pul yuvishga aloqador shaxslar ro‘yxati bo‘yicha tekshirildi'),
  'land_permit': ('Права на землю и разрешение на строительство подлинные', 'Land rights and the building permit are genuine', 'Yerga huquq va qurilish ruxsatnomasi haqiqiy'),
  'expertise': ('Заключение экспертизы проекта подлинное', 'The design review conclusion is genuine', 'Loyiha ekspertizasi xulosasi haqiqiy'),
  'bank_account': ('Расчётный счёт и реквизиты проверены', 'Bank account and details checked', 'Hisob raqami va rekvizitlar tekshirildi'),
  'callback': ('Перезвонили по номеру из официальных источников и подтвердили заявку', 'Called back on a number from official sources and confirmed the application', 'Rasmiy manbadagi raqamga qo‘ng‘iroq qilib, arizani tasdiqladik'),
  'license': ('Лицензия Центрального банка действует', 'The Central Bank licence is valid', 'Markaziy bank litsenziyasi amal qilmoqda'),
  'person': ('Контактное лицо и его полномочия подтверждены', 'The contact person and their authority are confirmed', 'Aloqa shaxsi va uning vakolatlari tasdiqlandi'),
};

const statusLabels = <String, Words>{
  'new': ('Новая', 'New', 'Yangi'),
  'calling': ('Прозвон', 'Calling', 'Qo‘ng‘iroq'),
  'docs_requested': ('Ждём документы', 'Waiting for documents', 'Hujjatlar kutilmoqda'),
  'in_review': ('Проверка', 'In review', 'Tekshiruvda'),
  'approved': ('Одобрена', 'Approved', 'Tasdiqlandi'),
  'rejected': ('Отклонена', 'Rejected', 'Rad etildi'),
};

const applicantStatusLabels = <String, Words>{
  'new': ('Заявка получена', 'Application received', 'Ariza qabul qilindi'),
  'calling': ('Мы звоним вам', 'We are getting in touch by phone', 'Siz bilan telefon orqali bog‘lanamiz'),
  'docs_requested': ('Нужны документы', 'We need documents', 'Hujjatlar kerak'),
  'in_review': ('Проверяем документы', 'We are checking your documents', 'Hujjatlaringizni tekshiryapmiz'),
  'approved': ('Заявка одобрена', 'Application approved', 'Ariza tasdiqlandi'),
  'rejected': ('Заявка отклонена', 'Application declined', 'Ariza rad etildi'),
};

const callOutcomes = <String, Words>{
  'reached': ('Дозвонились', 'Reached them', 'Gaplashdik'),
  'no_answer': ('Не ответили', 'No answer', 'Javob berishmadi'),
  'busy': ('Занято', 'Busy', 'Band'),
  'call_later': ('Просили перезвонить', 'Asked to call back', 'Qayta qo‘ng‘iroq qilishni so‘rashdi'),
  'wrong_number': ('Неверный номер', 'Wrong number', 'Noto‘g‘ri raqam'),
};

extension SayWords on AppCopy {
  String say(Words words) => pick(words.$1, words.$2, words.$3);

  String docName(String type) {
    for (final doc in [...developerDocs, ...bankDocs]) {
      if (doc.type == type) return say(doc.title);
    }
    return type;
  }
}
