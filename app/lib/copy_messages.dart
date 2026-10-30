part of 'l10n.dart';

/// Messages the server sends (in Russian), with their English and Uzbek versions.
/// The Russian text must match the server text exactly.
/// `app/test/server_messages_test.dart` checks that no server message is missing here.
const _knownMessages = <_Row>[
  // Sign in and session
  (
    'Введите логин и пароль.',
    'Enter your login and password.',
    'Login va parolni kiriting.',
  ),
  (
    'Неверный логин или пароль.',
    'Wrong login or password.',
    'Login yoki parol noto‘g‘ri.',
  ),
  (
    'Слишком длинный логин или пароль.',
    'The login or password is too long.',
    'Login yoki parol juda uzun.',
  ),
  (
    'Эта учётная запись отключена.',
    'This account is turned off.',
    'Bu hisob o‘chirilgan.',
  ),
  (
    'Слишком много попыток. Подождите и попробуйте снова.',
    'Too many attempts. Wait a little and try again.',
    'Juda ko‘p urinish. Biroz kuting va qayta urinib ko‘ring.',
  ),
  (
    'Сессия устарела. Обновите страницу и войдите снова.',
    'Your session has expired. Refresh the page and sign in again.',
    'Sessiya eskirgan. Sahifani yangilang va qaytadan kiring.',
  ),
  (
    'Это демо: данные учебные, изменения не сохраняются.',
    'This is a demo: the data is for practice and changes are not saved.',
    'Bu demo: maʼlumotlar oʻquv uchun, oʻzgarishlar saqlanmaydi.',
  ),
  (
    'Выберите роль для демо.',
    'Pick a role for the demo.',
    'Demo uchun rolni tanlang.',
  ),
  (
    'Демо сейчас недоступно.',
    'The demo is not available right now.',
    'Demo hozir mavjud emas.',
  ),
  (
    'Войдите, чтобы продолжить.',
    'Sign in to continue.',
    'Davom etish uchun tizimga kiring.',
  ),
  (
    'Вы уже вышли из аккаунта.',
    'You have already signed out.',
    'Siz allaqachon tizimdan chiqqansiz.',
  ),
  (
    'У вас нет прав на это действие.',
    'You do not have permission to do this.',
    'Bu amalni bajarishga ruxsatingiz yo‘q.',
  ),

  // General
  (
    'Не получилось обработать запрос. Проверьте данные и попробуйте снова.',
    'We could not process this. Check the details and try again.',
    'So‘rovni bajarib bo‘lmadi. Ma’lumotlarni tekshirib, qayta urinib ko‘ring.',
  ),
  ('Ничего не найдено.', 'Nothing found.', 'Hech narsa topilmadi.'),
  (
    'Обновите страницу и попробуйте снова.',
    'Refresh the page and try again.',
    'Sahifani yangilab, qayta urinib ko‘ring.',
  ),
  (
    'Не получилось отправить. Попробуйте ещё раз.',
    'Could not send it. Please try again.',
    'Yuborib bo‘lmadi. Qayta urinib ko‘ring.',
  ),
  (
    'Попробуйте отправить ещё раз.',
    'Try sending it again.',
    'Yana bir bor yuborib ko‘ring.',
  ),
  (
    'Такой вкладки нет.',
    'There is no such tab.',
    'Bunday bo‘lim yo‘q.',
  ),
  (
    'Такого статуса нет.',
    'There is no such status.',
    'Bunday holat yo‘q.',
  ),
  (
    'Курс Центробанка сейчас недоступен.',
    'The Central Bank rate is not available right now.',
    'Markaziy bank kursi hozir mavjud emas.',
  ),

  // Projects and people
  ('Объект не найден.', 'Project not found.', 'Obyekt topilmadi.'),
  (
    'Напишите название и адрес.',
    'Enter a name and an address.',
    'Nom va manzilni yozing.',
  ),
  (
    'Напишите название объекта.',
    'Enter the project name.',
    'Obyekt nomini yozing.',
  ),
  (
    'Напишите адрес объекта.',
    'Enter the project address.',
    'Obyekt manzilini yozing.',
  ),
  ('Название слишком длинное.', 'The name is too long.', 'Nom juda uzun.'),
  ('Адрес слишком длинный.', 'The address is too long.', 'Manzil juda uzun.'),
  (
    'Описание слишком длинное.',
    'The description is too long.',
    'Tavsif juda uzun.',
  ),
  (
    'Менять карточку объекта может только застройщик.',
    'Only the developer can change the project card.',
    'Obyekt kartasini faqat quruvchi o‘zgartira oladi.',
  ),
  (
    'Правки по этому объекту уже ждут проверки.',
    'Changes to this project are already waiting for review.',
    'Bu obyekt bo‘yicha tahrirlar allaqachon ko‘rib chiqilishini kutmoqda.',
  ),
  (
    'Правки видит только администратор iBuild.',
    'Only an iBuild administrator can see the changes.',
    'Tahrirlarni faqat iBuild administratori ko‘ra oladi.',
  ),
  (
    'Решение принимает администратор iBuild.',
    'An iBuild administrator makes the decision.',
    'Qarorni iBuild administratori qabul qiladi.',
  ),
  ('Правка не найдена.', 'Change not found.', 'Tahrir topilmadi.'),
  (
    'Выберите сотрудника и роль.',
    'Choose a person and a role.',
    'Xodim va rolni tanlang.',
  ),
  ('Сотрудник не найден.', 'Person not found.', 'Xodim topilmadi.'),
  (
    'Этот человек уже добавлен на объект.',
    'This person is already on the project.',
    'Bu odam obyektga allaqachon qo‘shilgan.',
  ),
  (
    'Для подрядчика выберите его компанию.',
    'For a contractor, choose their company.',
    'Pudratchi uchun uning kompaniyasini tanlang.',
  ),
  ('Участник не найден.', 'Member not found.', 'Ishtirokchi topilmadi.'),
  (
    'На объекте должен остаться застройщик.',
    'The project must keep a developer.',
    'Obyektda quruvchi qolishi kerak.',
  ),
  ('Подрядчик не найден.', 'Contractor not found.', 'Pudratchi topilmadi.'),
  (
    'Напишите название и контакт подрядчика.',
    'Enter the contractor’s name and contact.',
    'Pudratchi nomi va aloqa ma’lumotini yozing.',
  ),
  (
    'ИНН состоит из 9 цифр.',
    'The tax ID has 9 digits.',
    'STIR 9 ta raqamdan iborat.',
  ),
  (
    'Подрядчик с таким ИНН уже есть.',
    'A contractor with this tax ID already exists.',
    'Bunday STIRga ega pudratchi allaqachon bor.',
  ),

  // Budget
  (
    'Бюджет больше нельзя менять: по объекту уже есть отправленный транш.',
    'The budget can no longer be changed: a tranche has already been sent for this project.',
    'Byudjetni endi o‘zgartirib bo‘lmaydi: obyekt bo‘yicha transh allaqachon yuborilgan.',
  ),
  ('Вид работ не найден.', 'Work item not found.', 'Ish turi topilmadi.'),
  (
    'Напишите, что за работа.',
    'Write what the work is.',
    'Qanday ish ekanini yozing.',
  ),
  (
    'Выберите подрядчика для этой работы.',
    'Choose a contractor for this work.',
    'Bu ish uchun pudratchini tanlang.',
  ),
  (
    'Сумма должна быть больше нуля, не больше двух знаков после запятой.',
    'The amount must be above zero, with at most two decimal places.',
    'Summa noldan katta bo‘lishi, verguldan keyin esa ikki xonadan oshmasligi kerak.',
  ),
  (
    'Укажите источник, вид и сумму.',
    'Enter the source, the type and the amount.',
    'Manba, tur va summani kiriting.',
  ),
  (
    'Для этого вида работ ещё не выбран подрядчик.',
    'No contractor is chosen for this work item yet.',
    'Bu ish turi uchun pudratchi hali tanlanmagan.',
  ),
  (
    'Название вида работ — не больше 80 символов.',
    'The work item name can be up to 80 characters.',
    'Ish turi nomi 80 belgidan oshmasligi kerak.',
  ),
  (
    'Свой вид работ может добавить только застройщик.',
    'Only the developer can add a custom work item.',
    'O‘z ish turini faqat quruvchi qo‘sha oladi.',
  ),

  // Tranche
  ('Транш не найден.', 'Tranche not found.', 'Transh topilmadi.'),
  (
    'Выберите вид работ и укажите сумму.',
    'Choose a work item and enter an amount.',
    'Ish turini tanlang va summani kiriting.',
  ),
  (
    'Сумма больше, чем можно запросить.',
    'The amount is more than can be requested.',
    'Summa so‘rash mumkin bo‘lganidan katta.',
  ),
  (
    'Транш уже изменили. Обновите страницу.',
    'This tranche has just been changed. Refresh the page.',
    'Transh hozirgina o‘zgartirildi. Sahifani yangilang.',
  ),
  (
    'Транш уже отправлен, его нельзя править.',
    'The tranche has been sent and can no longer be edited.',
    'Transh yuborilgan, uni endi tahrirlab bo‘lmaydi.',
  ),
  (
    'Добавьте хотя бы одно фото работы.',
    'Add at least one photo of the work.',
    'Kamida bitta ish fotosini qo‘shing.',
  ),
  (
    'Добавьте обязательные документы.',
    'Add the required documents.',
    'Majburiy hujjatlarni qo‘shing.',
  ),
  (
    'Подпишите транш перед отправкой.',
    'Sign the tranche before sending it.',
    'Yuborishdan oldin transhni imzolang.',
  ),
  (
    'Без ведомости и сертификатов платёж по ним не принимается.',
    'Without the statement and certificates the bank does not accept payment for them.',
    'Qaydnoma va sertifikatlarsiz ular bo‘yicha to‘lov qabul qilinmaydi.',
  ),
  (
    'Банк вернул транш целиком.',
    'The bank returned the whole tranche.',
    'Bank transhni to‘liq qaytardi.',
  ),
  (
    'Банк вернул эту статью на доработку.',
    'The bank returned this line for rework.',
    'Bank bu moddani qayta ishlash uchun qaytardi.',
  ),
  (
    'Сумма источников не совпадает с суммой транша.',
    'The sources do not add up to the tranche amount.',
    'Manbalar yig‘indisi transh summasiga teng emas.',
  ),
  (
    'Сначала транш должен проверить технадзор.',
    'The technical supervisor has to check the tranche first.',
    'Avval transhni texnazorat tekshirishi kerak.',
  ),
  (
    'Транш можно отозвать, пока банк не принял решение.',
    'A tranche can be withdrawn until the bank decides.',
    'Bank qaror qilmaguncha transhni qaytarib olish mumkin.',
  ),
  ('Напишите причину.', 'Write a reason.', 'Sababni yozing.'),
  ('Напишите сообщение.', 'Write a message.', 'Xabarni yozing.'),
  ('Выберите решение.', 'Choose a decision.', 'Qarorni tanlang.'),
  (
    'Новый транш можно создать только на основе отклонённого.',
    'A new tranche can only be created from a rejected one.',
    'Yangi transhni faqat rad etilgan transh asosida yaratish mumkin.',
  ),
  (
    'Транш можно отправить технадзору или в банк.',
    'A tranche can be sent to the technical supervisor or to the bank.',
    'Transhni texnazoratga yoki bankka yuborish mumkin.',
  ),
  (
    'В банк транш отправляет застройщик после одобрения.',
    'The developer sends the tranche to the bank after it is approved.',
    'Transhni bankka quruvchi ma’qullangandan keyin yuboradi.',
  ),
  (
    'В банк транш получает сотрудник банка с этого объекта.',
    'A bank employee from this project receives the tranche.',
    'Transhni shu obyektdagi bank xodimi oladi.',
  ),
  (
    'Транш уже отправлен в банк.',
    'The tranche has already been sent to the bank.',
    'Transh bankka allaqachon yuborilgan.',
  ),
  (
    'Транш можно передать технадзору или застройщику.',
    'A tranche can be passed to the technical supervisor or the developer.',
    'Transhni texnazoratga yoki quruvchiga topshirish mumkin.',
  ),
  (
    'Передать транш можно, пока он на проверке или одобрен.',
    'A tranche can be passed on while it is being checked or after it is approved.',
    'Transhni tekshiruvda yoki ma’qullangandan keyin topshirish mumkin.',
  ),
  (
    'Выберите другого человека.',
    'Choose someone else.',
    'Boshqa odamni tanlang.',
  ),
  (
    'Выберите, кому отправить транш.',
    'Choose who should receive the tranche.',
    'Transh kimga borishini tanlang.',
  ),

  // Files and payment
  (
    'Подойдёт фото (JPEG, PNG, WebP) или PDF.',
    'Use a photo (JPEG, PNG, WebP) or a PDF.',
    'Foto (JPEG, PNG, WebP) yoki PDF mos keladi.',
  ),
  ('Фото больше 5 МБ.', 'The photo is larger than 5 MB.', 'Foto 5 MB dan katta.'),
  ('PDF больше 10 МБ.', 'The PDF is larger than 10 MB.', 'PDF 10 MB dan katta.'),
  (
    'Можно добавить не больше 5 фото.',
    'You can add up to 5 photos.',
    '5 tagacha foto qo‘shish mumkin.',
  ),
  ('PDF уже добавлен.', 'A PDF is already added.', 'PDF allaqachon qo‘shilgan.'),
  ('Добавьте файл.', 'Add a file.', 'Fayl qo‘shing.'),
  (
    'Можно добавить фото и один PDF.',
    'You can add photos and one PDF.',
    'Foto va bitta PDF qo‘shish mumkin.',
  ),
  (
    'Файлы можно добавлять только в черновик.',
    'Files can only be added to a draft.',
    'Fayllarni faqat qoralamaga qo‘shish mumkin.',
  ),
  (
    'Файлы можно убирать только из черновика.',
    'Files can only be removed from a draft.',
    'Fayllarni faqat qoralamadan olib tashlash mumkin.',
  ),
  (
    'Не удалось сохранить файл.',
    'The file could not be saved.',
    'Faylni saqlab bo‘lmadi.',
  ),
  (
    'Не удалось сохранить фото.',
    'The photo could not be saved.',
    'Fotoni saqlab bo‘lmadi.',
  ),
  (
    'Не удалось сохранить правку.',
    'The change could not be saved.',
    'Tahrirni saqlab bo‘lmadi.',
  ),
  (
    'Подойдёт фото JPEG, PNG или WebP.',
    'Use a JPEG, PNG or WebP photo.',
    'JPEG, PNG yoki WebP foto mos keladi.',
  ),
  ('Фото не найдено.', 'Photo not found.', 'Foto topilmadi.'),
  (
    'Укажите дату и номер платежа.',
    'Enter the payment date and number.',
    'To‘lov sanasi va raqamini yozing.',
  ),
  (
    'Добавьте подтверждение платежа.',
    'Add the payment confirmation.',
    'To‘lov tasdig‘ini qo‘shing.',
  ),
  (
    'Отметить выплату можно после одобрения банка.',
    'You can mark the payout after the bank approves.',
    'To‘lovni bank ma’qullagandan keyin belgilash mumkin.',
  ),
  (
    'Подтверждение можно добавить, когда банк одобрил транш.',
    'The confirmation can be added once the bank approves the tranche.',
    'Tasdiqni bank transhni ma’qullagandan keyin qo‘shish mumkin.',
  ),
  (
    'Подтверждение уже добавлено.',
    'The confirmation is already added.',
    'Tasdiq allaqachon qo‘shilgan.',
  ),
  (
    'Одобрение можно отменить, пока выплата не отмечена.',
    'The approval can be cancelled until the payout is marked.',
    'To‘lov belgilanmaguncha ma’qullashni bekor qilish mumkin.',
  ),
  (
    'Подтвердите, что платёж ещё не ушёл.',
    'Confirm that the payment has not gone out yet.',
    'To‘lov hali ketmaganini tasdiqlang.',
  ),

  // Inspections
  ('Осмотр не найден.', 'Inspection not found.', 'Ko‘rik topilmadi.'),
  (
    'Выберите объект и напишите, что проверить.',
    'Pick a project and write what to check.',
    'Obyektni tanlang va nimani tekshirishni yozing.',
  ),

  (
    'Что-то пошло не так. Попробуйте ещё раз.',
    'Something went wrong. Please try again.',
    'Nimadir xato ketdi. Qayta urinib ko‘ring.',
  ),

  // Company sign-up and the admin's applications desk
  (
    'Слишком много заявок с этого адреса. Попробуйте позже.',
    'Too many applications from this address. Try again later.',
    'Bu manzildan arizalar juda ko‘p. Keyinroq urinib ko‘ring.',
  ),
  (
    'Нужно согласие на обработку данных и подтверждение, что сведения верны.',
    'We need your consent to process the data and your confirmation that the details are true.',
    'Ma’lumotlarni qayta ishlashga rozilik va ma’lumotlar to‘g‘riligini tasdiqlash kerak.',
  ),
  (
    'Проверьте заполнение формы.',
    'Please check the form.',
    'Formani tekshiring.',
  ),
  (
    'Организация с таким ИНН уже работает в iBuild.',
    'A company with this tax number already works in iBuild.',
    'Bu STIR bilan kompaniya iBuild’da allaqachon ishlaydi.',
  ),
  (
    'Заявка от этой организации уже на проверке.',
    'An application from this company is already being checked.',
    'Bu kompaniyadan ariza allaqachon tekshiruvda.',
  ),
  (
    'Сессия устарела. Обновите страницу и попробуйте снова.',
    'Your session expired. Refresh the page and try again.',
    'Seans eskirdi. Sahifani yangilab, qayta urinib ko‘ring.',
  ),
  (
    'Заявка не найдена. Проверьте ссылку.',
    'Application not found. Check the link.',
    'Ariza topilmadi. Havolani tekshiring.',
  ),
  (
    'Заявка закрыта, документы больше не принимаются.',
    'The application is closed and no more documents are accepted.',
    'Ariza yopilgan, hujjatlar endi qabul qilinmaydi.',
  ),
  (
    'Такого документа нет в списке.',
    'This document is not on the list.',
    'Bunday hujjat ro‘yxatda yo‘q.',
  ),
  (
    'Слишком много файлов. Удалите лишние или объедините их в один PDF.',
    'Too many files. Remove some or combine them into one PDF.',
    'Fayllar juda ko‘p. Ortiqchasini olib tashlang yoki bitta PDF ga birlashtiring.',
  ),
  (
    'Файл больше 10 МБ.',
    'The file is larger than 10 MB.',
    'Fayl 10 MB dan katta.',
  ),
  (
    'Не удалось сохранить файл.',
    'Could not save the file.',
    'Faylni saqlab bo‘lmadi.',
  ),
  (
    'Заявки видит только администратор iBuild.',
    'Only the iBuild admin can see applications.',
    'Arizalarni faqat iBuild administratori ko‘radi.',
  ),
  (
    'Заявка не найдена.',
    'Application not found.',
    'Ariza topilmadi.',
  ),
  (
    'Заявка уже закрыта.',
    'The application is already closed.',
    'Ariza allaqachon yopilgan.',
  ),
  (
    'Напишите, какие документы нужны.',
    'Write which documents are needed.',
    'Qaysi hujjatlar kerakligini yozing.',
  ),
  (
    'Напишите причину отказа.',
    'Write the reason for declining.',
    'Rad etish sababini yozing.',
  ),
  (
    'Напишите заметку, не длиннее 2000 знаков.',
    'Write a note, up to 2000 characters.',
    'Eslatma yozing, 2000 belgigacha.',
  ),
  (
    'Отметьте все пункты проверки, прежде чем одобрять.',
    'Tick every check before approving.',
    'Tasdiqlashdan oldin barcha tekshiruv bandlarini belgilang.',
  ),
  (
    'Не хватает обязательных документов.',
    'Required documents are missing.',
    'Majburiy hujjatlar yetishmayapti.',
  ),
  (
    'Этот email уже используют как логин. Укажите другой.',
    'This email is already used as a login. Use another one.',
    'Bu pochta allaqachon login sifatida ishlatilgan. Boshqasini kiriting.',
  ),
  (
    'Такая организация или логин уже есть в системе.',
    'This company or login already exists.',
    'Bunday kompaniya yoki login allaqachon mavjud.',
  ),
  (
    'Файл не найден.',
    'File not found.',
    'Fayl topilmadi.',
  ),

  // The app’s own message when the server cannot be reached.
  (
    'Нет связи с сервером.',
    'Cannot reach the server.',
    'Server bilan aloqa yo‘q.',
  ),
  // Day 6-7 and the platform admin
  (
    'Версия не найдена',
    'Version not found',
    'Versiya topilmadi',
  ),
  (
    'Выберите объект и дату осмотра',
    'Choose a project and an inspection date',
    'Obyekt va ko‘rik sanasini tanlang',
  ),
  (
    'Выберите объект, вид и период отчёта',
    'Choose a project, a type and a period',
    'Obyekt, hisobot turi va davrni tanlang',
  ),
  (
    'Выберите эксперта банка',
    'Choose a bank expert',
    'Bank ekspertini tanlang',
  ),
  (
    'Выберите, о чём напомнить',
    'Choose what to remind about',
    'Nima haqida eslatishni tanlang',
  ),
  (
    'Группа не найдена',
    'Group not found',
    'Guruh topilmadi',
  ),
  (
    'Дата возвращения указана неверно',
    'The return date is not valid',
    'Qaytish sanasi noto‘g‘ri',
  ),
  (
    'Дата завершения указана неверно',
    'The completion date is not valid',
    'Yakunlash sanasi noto‘g‘ri',
  ),
  (
    'Дата указана неверно',
    'The date is not valid',
    'Sana noto‘g‘ri',
  ),
  (
    'Комментарий слишком длинный',
    'The comment is too long',
    'Izoh juda uzun',
  ),
  (
    'Компания указана неверно',
    'The company is not valid',
    'Kompaniya noto‘g‘ri',
  ),
  (
    'Не найдено',
    'Not found',
    'Topilmadi',
  ),
  (
    'Не удалось прочитать запрос',
    'Could not read the request',
    'So‘rovni o‘qib bo‘lmadi',
  ),
  (
    'Нельзя отключить самого себя',
    'You cannot turn yourself off',
    'O‘zingizni o‘chira olmaysiz',
  ),
  (
    'Ничего не изменилось',
    'Nothing has changed',
    'Hech narsa o‘zgarmadi',
  ),
  (
    'Объект не найден',
    'Project not found',
    'Obyekt topilmadi',
  ),
  (
    'Пользователь не найден',
    'User not found',
    'Foydalanuvchi topilmadi',
  ),
  (
    'Правила банка не заданы',
    'The bank rules are not set',
    'Bank qoidalari belgilanmagan',
  ),
  (
    'Проверьте адреса почты',
    'Check the email addresses',
    'Elektron pochta manzillarini tekshiring',
  ),
  (
    'Проверьте период и фильтры',
    'Check the period and the filters',
    'Davr va filtrlarni tekshiring',
  ),
  (
    'Проверьте период и формат',
    'Check the period and the format',
    'Davr va formatni tekshiring',
  ),
  (
    'Раздел только для администратора iBuild.',
    'This section is for the iBuild administrator only.',
    'Bu bo‘lim faqat iBuild administratori uchun.',
  ),
  (
    'Согласий не может быть больше, чем активных участников группы',
    'Approvals cannot exceed the active members of the group',
    'Kelishuvlar soni guruhning faol a’zolaridan oshmasligi kerak',
  ),
  (
    'Сотрудник не найден',
    'Employee not found',
    'Xodim topilmadi',
  ),
  (
    'Такого отчёта нет',
    'There is no such report',
    'Bunday hisobot yo‘q',
  ),
  (
    'У вашей роли нет доступа к этому разделу',
    'Your role has no access to this section',
    'Sizning rolingiz bu bo‘limga kira olmaydi',
  ),
  (
    'Укажите риск и рекомендацию',
    'Give the risk and the recommendation',
    'Xavf va tavsiyani kiriting',
  ),
  (
    'Укажите, включить или отключить',
    'Say whether to turn on or off',
    'Yoqish yoki o‘chirishni ko‘rsating',
  ),
  (
    'Укажите, кому отправлять',
    'Say who to send it to',
    'Kimga yuborishni ko‘rsating',
  ),
  (
    'Число согласий: от 1 до 20',
    'Number of approvals: from 1 to 20',
    'Kelishuvlar soni: 1 dan 20 gacha',
  ),
  (
    'Этот осмотр уже закрыт или назначен другому эксперту',
    'This inspection is already closed or assigned to another expert',
    'Bu ko‘rik yopilgan yoki boshqa ekspertga biriktirilgan',
  ),
  (
    'Файл слишком большой.',
    'The file is too large.',
    'Fayl juda katta.',
  ),
  // Report tables
  (
    '% выданного',
    '% of paid',
    'To‘langanning %',
  ),
  (
    'Возвращено',
    'Returned',
    'Qaytarilgan',
  ),
  (
    'Выдано',
    'Paid',
    'To‘langan',
  ),
  (
    'Выполнено',
    'Done',
    'Bajarilgan',
  ),
  (
    'Дней осталось',
    'Days left',
    'Qolgan kunlar',
  ),
  (
    'Запланировано',
    'Planned',
    'Rejalashtirilgan',
  ),
  (
    'Застройщик',
    'Developer',
    'Quruvchi',
  ),
  (
    'К выдаче',
    'To pay out',
    'To‘lash uchun',
  ),
  (
    'К выдаче по решениям',
    'To pay out by decisions',
    'Qarorlar bo‘yicha to‘lash uchun',
  ),
  (
    'Квартальная отчётность',
    'Quarterly reporting',
    'Choraklik hisobot',
  ),
  (
    'Когда',
    'When',
    'Qachon',
  ),
  (
    'Комментарий',
    'Comment',
    'Izoh',
  ),
  (
    'Кто',
    'Who',
    'Kim',
  ),
  (
    'Кто принял',
    'Accepted by',
    'Kim qabul qildi',
  ),
  (
    'Лимит',
    'Limit',
    'Limit',
  ),
  (
    'На этапе',
    'At the step',
    'Bosqichda',
  ),
  (
    'Объект',
    'Project',
    'Obyekt',
  ),
  (
    'Объектов',
    'Projects',
    'Obyektlar',
  ),
  (
    'Осмотр',
    'Inspection',
    'Ko‘rik',
  ),
  (
    'Основание',
    'Basis',
    'Asos',
  ),
  (
    'Остаток',
    'Left',
    'Qoldiq',
  ),
  (
    'Остаток лимита',
    'Limit left',
    'Limit qoldig‘i',
  ),
  (
    'Отставание, дн.',
    'Lag, days',
    'Ortda qolish, kun',
  ),
  (
    'Отчёт о продажах сдан',
    'Sales report filed',
    'Sotuv hisoboti topshirilgan',
  ),
  (
    'Подтверждено',
    'Confirmed',
    'Tasdiqlangan',
  ),
  (
    'Последний осмотр',
    'Last inspection',
    'Oxirgi ko‘rik',
  ),
  (
    'Принято с обоснованием',
    'Accepted with a reason',
    'Asos bilan qabul qilingan',
  ),
  (
    'Причина',
    'Reason',
    'Sabab',
  ),
  (
    'Проверка',
    'Check',
    'Tekshiruv',
  ),
  (
    'Прогноз эксперта',
    'Expert forecast',
    'Ekspert prognozi',
  ),
  (
    'Просрочено',
    'Overdue',
    'Muddati o‘tgan',
  ),
  (
    'Решение',
    'Decision',
    'Qaror',
  ),
  (
    'Сверх подтверждённого',
    'Above the confirmed',
    'Tasdiqlangandan ortiq',
  ),
  (
    'Среднее, раб. дней',
    'Average, working days',
    'O‘rtacha, ish kuni',
  ),
  (
    'Срок банка, раб. дней',
    'Bank term, working days',
    'Bank muddati, ish kuni',
  ),
  (
    'Срок кредита',
    'Credit term',
    'Kredit muddati',
  ),
  (
    'Срок освоения',
    'Drawdown term',
    'O‘zlashtirish muddati',
  ),
  (
    'Срок, дн.',
    'Term, days',
    'Muddat, kun',
  ),
  (
    'Строк',
    'Rows',
    'Qatorlar',
  ),
  (
    'Сумма',
    'Amount',
    'Summa',
  ),
  (
    'Технадзор не реже 2 раз в месяц',
    'Supervision at least twice a month',
    'Texnik nazorat oyiga kamida 2 marta',
  ),
  (
    'Транш',
    'Tranche',
    'Transh',
  ),
  (
    'Траншей в работе',
    'Tranches in progress',
    'Ishdagi transhlar',
  ),
  (
    'У кого',
    'With whom',
    'Kimda',
  ),
  (
    'Филиал',
    'Branch',
    'Filial',
  ),
  (
    'Эксперт',
    'Expert',
    'Ekspert',
  ),
  (
    'Этап',
    'Step',
    'Bosqich',
  ),
  (
    'Выдано, млн UZS',
    'Paid, m UZS',
    'To‘langan, mln UZS',
  ),
  (
    'Застройщиков',
    'Developers',
    'Quruvchilar',
  ),
  (
    'Исключений',
    'Exceptions',
    'Istisnolar',
  ),
  (
    'Кредитов со сроком',
    'Credits with a term',
    'Muddatli kreditlar',
  ),
  (
    'Лимит, млн UZS',
    'Limit, m UZS',
    'Limit, mln UZS',
  ),
  (
    'Объектов выше порога',
    'Projects above the threshold',
    'Chegaradan yuqori obyektlar',
  ),
  (
    'Объектов с прогнозом',
    'Projects with a forecast',
    'Prognozli obyektlar',
  ),
  (
    'Порог показа, % от выданного',
    'Display threshold, % of paid',
    'Ko‘rsatish chegarasi, to‘langanning %',
  ),
  (
    'Причин',
    'Reasons',
    'Sabablar',
  ),
  (
    'Решений',
    'Decisions',
    'Qarorlar',
  ),
  (
    'Сверх подтверждённого, млн UZS',
    'Above the confirmed, m UZS',
    'Tasdiqlangandan ortiq, mln UZS',
  ),
  (
    'Средний срок транша, раб. дней',
    'Average tranche time, working days',
    'O‘rtacha transh muddati, ish kuni',
  ),
  (
    'Экспертов',
    'Experts',
    'Ekspertlar',
  ),
  (
    'Порог задаётся в «Правилах». Банк не даёт выдать больше подтверждённого, поэтому отчёт показывает исключения, снятые вручную, и старые данные.',
    'The threshold is set in the Rules. The bank does not let pay more than confirmed, so the report shows exceptions lifted by hand and old data.',
    'Chegara “Qoidalar”da belgilanadi. Bank tasdiqlangandan ortiq to‘lashga yo‘l qo‘ymaydi, shuning uchun hisobot qo‘lda olib tashlangan istisnolar va eski ma’lumotlarni ko‘rsatadi.',
  ),
  (
    'Считается по рабочему календарю банка; время у застройщика не входит.',
    'Counted by the bank working calendar; time with the developer is left out.',
    'Bankning ish kalendari bo‘yicha hisoblanadi; quruvchidagi vaqt kirmaydi.',
  ),
  (
    'Прогноз появляется, когда эксперт указывает ожидаемую дату завершения при закрытии осмотра.',
    'A forecast appears when the expert gives the expected completion date while closing a visit.',
    'Prognoz ekspert ko‘rikni yopishda kutilayotgan yakunlash sanasini ko‘rsatganda paydo bo‘ladi.',
  ),
  (
    'Прогноз берётся из последнего осмотра, срок — из кредитного договора.',
    'The forecast comes from the last inspection, the term from the credit agreement.',
    'Prognoz oxirgi ko‘rikdan, muddat kredit shartnomasidan olinadi.',
  ),
  (
    'Отставание от графика, мес.',
    'Lag behind the schedule, months',
    'Jadvaldan ortda qolish, oy',
  ),
  (
    'Прогноз: предупреждение, дн.',
    'Forecast: warning, days',
    'Prognoz: ogohlantirish, kun',
  ),
  (
    'Прогноз: красный сигнал, мес.',
    'Forecast: red signal, months',
    'Prognoz: qizil signal, oy',
  ),
  (
    'Документ получен вне системы',
    'Document received outside the system',
    'Hujjat tizimdan tashqarida olingan',
  ),
  (
    'Исправлено в другой части заявки',
    'Fixed in another part of the request',
    'Arizaning boshqa qismida tuzatilgan',
  ),
  (
    'Утверждённое исключение',
    'An approved exception',
    'Tasdiqlangan istisno',
  ),
  (
    'Другое',
    'Other',
    'Boshqa',
  ),
  (
    'Частичная выдача',
    'Partial payout',
    'Qisman to‘lov',
  ),
  (
    'Возврат целиком',
    'Returned in full',
    'To‘liq qaytarish',
  ),
  (
    'Контрольный замер',
    'Control measurement',
    'Nazorat o‘lchovi',
  ),
  (
    'Приостановка финансирования',
    'Financing suspended',
    'Moliyalashtirish to‘xtatildi',
  ),
  (
    'Возобновление финансирования',
    'Financing resumed',
    'Moliyalashtirish tiklandi',
  ),
  (
    'Проверка документов',
    'Document check',
    'Hujjatlarni tekshirish',
  ),
  (
    'Осмотр эксперта',
    'Expert inspection',
    'Ekspert ko‘rigi',
  ),
  (
    'Решение специалиста',
    'Specialist decision',
    'Mutaxassis qarori',
  ),
  (
    'Согласование',
    'Approval',
    'Kelishuv',
  ),
  (
    'Выплата',
    'Payout',
    'To‘lov',
  ),
  (
    'Текущий пароль указан неверно.',
    'The current password is wrong.',
    'Joriy parol noto‘g‘ri.',
  ),
  (
    'Новый пароль: не короче 10 символов.',
    'New password: at least 10 characters.',
    'Yangi parol: kamida 10 belgi.',
  ),
  (
    'Новый пароль должен отличаться от текущего.',
    'The new password must differ from the current one.',
    'Yangi parol joriyidan farq qilishi kerak.',
  ),
  (
    'Это тестовое письмо из панели администратора iBuild. Если вы его читаете, почта подключена.',
    'This is a test letter from the iBuild admin panel. If you read it, mail is connected.',
    'Bu iBuild administrator panelidan sinov xati. Uni o‘qiyotgan bo‘lsangiz, pochta ulangan.',
  ),
  (
    'Отправлено по расписанию.',
    'Sent on schedule.',
    'Jadval bo‘yicha yuborildi.',
  ),
  (
    'Просим передать отчёт о продажах по объекту.',
    'Please send the sales report for the project.',
    'Obyekt bo‘yicha sotuvlar hisobotini yuborishingizni so‘raymiz.',
  ),
  (
    'Просим обновить график работ по объекту.',
    'Please update the work schedule for the project.',
    'Obyekt bo‘yicha ish jadvalini yangilashingizni so‘raymiz.',
  ),
  (
    'Просим передать недостающие документы по объекту.',
    'Please send the missing documents for the project.',
    'Obyekt bo‘yicha yetishmayotgan hujjatlarni yuborishingizni so‘raymiz.',
  ),
];
