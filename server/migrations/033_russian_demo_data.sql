-- Учебные данные снова на русском. 032 перевела учебный мир на английский для
-- англоязычных показов; интерфейс показывают на русском, поэтому это обратная
-- замена: каждое значение меняется, только пока в нём ещё английский текст из 032,
-- повторный запуск ничего не меняет. Затрагивается только учебный мир (те же ИНН,
-- что в 032). Функция из 030 возвращается с русскими подписями.

-- Companies.
UPDATE companies SET name = 'Навои Девелопмент' WHERE inn = '300000001' AND name = 'Navoi Development';

UPDATE companies SET name = 'Чиланзар Строй' WHERE inn = '300000002' AND name = 'Chilanzar Stroy';

UPDATE companies SET name = 'Банк Навои' WHERE inn = '300000010' AND name = 'Navoi Bank';

UPDATE companies SET name = 'Банк Чиланзара' WHERE inn = '300000011' AND name = 'Chilanzar Bank';

UPDATE companies SET name = 'Портфель банка' WHERE inn = '300000012' AND name = 'Bank Portfolio';

-- People of the seed, found by login.
UPDATE users AS u
SET name = m.new_value
FROM (
  VALUES
    ('a.director', 'Застройщик Навои', 'Navoi Developer'),
    ('a.developer', 'Разработчик (тест)', 'Tester (full access)'),
    ('a.contractor', 'Подрядчик Навои', 'Navoi Contractor'),
    ('a.contractor2', 'Подрядчик инженерии', 'Engineering Contractor'),
    ('a.tech', 'Технадзор Навои', 'Navoi Site Inspector'),
    ('a.observer', 'Д. Рахимов', 'D. Rakhimov'),
    ('a.disabled', 'Отключённый сотрудник', 'Disabled Employee'),
    ('b.director', 'Застройщик Чиланзара', 'Chilanzar Developer'),
    ('b.contractor', 'Подрядчик Чиланзара', 'Chilanzar Contractor'),
    ('b.tech', 'Технадзор Чиланзара', 'Chilanzar Site Inspector'),
    ('b.observer', 'С. Юсупова', 'S. Yusupova'),
    ('a.admin', 'Администратор iBuild', 'iBuild Administrator'),
    ('a.expert', 'А. Каримов', 'A. Karimov'),
    ('a.head1', 'А. Усманов', 'A. Usmanov'),
    ('a.head2', 'Н. Ли', 'N. Li'),
    ('a.head3', 'Р. Ахмедов', 'R. Akhmedov'),
    ('a.committee1', 'Председатель комитета', 'Committee Chair'),
    ('a.committee2', 'Заместитель председателя', 'Deputy Chair'),
    ('a.committee3', 'Директор по рискам', 'Chief Risk Officer'),
    ('a.committee4', 'Директор по кредитованию', 'Lending Director'),
    ('a.committee5', 'Юрист банка', 'Bank Lawyer'),
    ('a.bankadmin', 'Е. Ким', 'E. Kim'),
    ('a.risk', 'С. Алиев', 'S. Aliev')
) AS m (login, new_value, old_value)
WHERE u.login = m.login
  AND u.name = m.old_value
  AND u.company_id IN (SELECT id FROM companies WHERE inn IN ('300000000', '300000001', '300000002', '300000010', '300000011', '300000012'));

-- Projects.
UPDATE projects AS t
SET name = m.new_value
FROM (
  VALUES
    ('ЖК Навои', 'Navoi Residences'),
    ('ЖК Чиланзар', 'Chilanzar Residences'),
    ('ЖК Сергели Нур', 'Sergeli Nur'),
    ('ЖК Юнусабад Гарден', 'Yunusabad Garden'),
    ('ЖК Чиланзар Бахор', 'Chilanzar Bahor'),
    ('ЖК Мирзо-Улугбек', 'Mirzo-Ulugbek Residences'),
    ('ЖК Янгиабад', 'Yangiabad Residences'),
    ('ЖК Сергели 2', 'Sergeli Residences 2'),
    ('ЖК Алмазар', 'Almazar Residences'),
    ('ЖК Учтепа', 'Uchtepa Residences'),
    ('ЖК Бектемир', 'Bektemir Residences'),
    ('ЖК Яккасарай', 'Yakkasaray Residences'),
    ('ЖК Шайхантахур', 'Shaykhantakhur Residences')
) AS m (new_value, old_value)
WHERE t.name = m.old_value
  AND t.company_id IN (SELECT id FROM companies WHERE inn IN ('300000000', '300000001', '300000002', '300000010', '300000011', '300000012'));

UPDATE projects AS t
SET address = m.new_value
FROM (
  VALUES
    ('Ташкент, Яккасарайский район, улица Бабура, 12', '12 Babur Street, Yakkasaray District, Tashkent'),
    ('Ташкент, Чиланзарский район, квартал 9, дом 4', 'Building 4, Block 9, Chilanzar District, Tashkent'),
    ('Ташкент, Сергели', 'Sergeli, Tashkent'),
    ('Ташкент, Юнусабад', 'Yunusabad, Tashkent'),
    ('Ташкент, Чиланзар', 'Chilanzar, Tashkent'),
    ('Ташкент, Мирзо-Улугбек', 'Mirzo-Ulugbek, Tashkent'),
    ('Ташкент, Янгиабад', 'Yangiabad, Tashkent'),
    ('Ташкент, Алмазар', 'Almazar, Tashkent'),
    ('Ташкент, Учтепа', 'Uchtepa, Tashkent'),
    ('Ташкент, Бектемир', 'Bektemir, Tashkent'),
    ('Ташкент, Яккасарай', 'Yakkasaray, Tashkent'),
    ('Ташкент, Шайхантахур', 'Shaykhantakhur, Tashkent')
) AS m (new_value, old_value)
WHERE t.address = m.old_value
  AND t.company_id IN (SELECT id FROM companies WHERE inn IN ('300000000', '300000001', '300000002', '300000010', '300000011', '300000012'));

-- Contractor firms, budget lines and the document checklist of the projects.
UPDATE contractor_firms AS t
SET name = m.new_value
FROM (
  VALUES
    ('Навои Строй Монтаж', 'Navoi Stroy Montazh'),
    ('Навои Инженерные Сети', 'Navoi Engineering Networks'),
    ('Чиланзар Подряд', 'Chilanzar Podryad'),
    ('ООО «Монолит Строй Сервис»', 'Monolit Stroy Servis LLC')
) AS m (new_value, old_value)
WHERE t.name = m.old_value
  AND t.owner_company_id IN (SELECT id FROM companies WHERE inn IN ('300000000', '300000001', '300000002', '300000010', '300000011', '300000012'));

-- budget_item_guard only lets a project director/developer edit titles; a migration has no user.
ALTER TABLE budget_items DISABLE TRIGGER budget_item_guard;

UPDATE budget_items AS t
SET title = m.new_value
FROM (
  VALUES
    ('Фундамент', 'Foundation'),
    ('Кладка и монолит', 'Masonry and cast-in-place concrete'),
    ('Кровля и фасад', 'Roofing and facade'),
    ('Инженерия', 'Building services'),
    ('Благоустройство', 'Landscaping'),
    ('Котлован и земляные работы', 'Excavation and earthworks'),
    ('Фундаментная плита', 'Foundation slab'),
    ('Каркас, 1–4 этажи', 'Frame works, floors 1–4'),
    ('Каркас', 'Frame works'),
    ('Арматура A500C и бетон на площадке', 'Rebar A500C and concrete on site'),
    ('Арматура А500С и бетон на площадке', 'Rebar A500C and concrete on site'),
    ('Работы нулевого цикла', 'Zero-cycle works')
) AS m (new_value, old_value)
WHERE t.title = m.old_value
  AND t.project_id IN (SELECT id FROM projects WHERE company_id IN (SELECT id FROM companies WHERE inn IN ('300000000', '300000001', '300000002', '300000010', '300000011', '300000012')));

ALTER TABLE budget_items ENABLE TRIGGER budget_item_guard;

UPDATE checklist_items AS t
SET title = m.new_value
FROM (
  VALUES
    ('Акт выполненных работ', 'Certificate of completed work'),
    ('Счёт', 'Invoice'),
    ('Ведомость удержания', 'Retainage statement'),
    ('Материалы на площадке', 'Materials on site'),
    ('Отказ от претензий', 'Waiver of claims')
) AS m (new_value, old_value)
WHERE t.title = m.old_value
  AND t.project_id IN (SELECT id FROM projects WHERE company_id IN (SELECT id FROM companies WHERE inn IN ('300000000', '300000001', '300000002', '300000010', '300000011', '300000012')));

-- Developer journal: a tranche passed to the bank.
UPDATE audit_events SET reason = replace(reason, 'To the bank: ', 'В банк: ')
WHERE strpos(reason, 'To the bank: ') > 0 AND project_id IN (SELECT id FROM projects WHERE company_id IN (SELECT id FROM companies WHERE inn IN ('300000000', '300000001', '300000002', '300000010', '300000011', '300000012')));

UPDATE audit_events AS t
SET reason = m.new_value
FROM (
  VALUES
    ('Застройщик Чиланзара', 'Chilanzar Developer'),
    ('Подрядчик Чиланзара', 'Chilanzar Contractor'),
    ('Технадзор Чиланзара', 'Chilanzar Site Inspector'),
    ('Застройщик Навои', 'Navoi Developer'),
    ('Подрядчик Навои', 'Navoi Contractor'),
    ('Подрядчик инженерии', 'Engineering Contractor'),
    ('Технадзор Навои', 'Navoi Site Inspector'),
    ('Разработчик (тест)', 'Tester (full access)'),
    ('Отключённый сотрудник', 'Disabled Employee'),
    ('Администратор iBuild', 'iBuild Administrator'),
    ('Председатель комитета', 'Committee Chair'),
    ('Заместитель председателя', 'Deputy Chair'),
    ('Директор по рискам', 'Chief Risk Officer'),
    ('Директор по кредитованию', 'Lending Director'),
    ('Юрист банка', 'Bank Lawyer'),
    ('Д. Рахимов', 'D. Rakhimov'),
    ('С. Юсупова', 'S. Yusupova'),
    ('А. Каримов', 'A. Karimov'),
    ('А. Усманов', 'A. Usmanov'),
    ('Р. Ахмедов', 'R. Akhmedov'),
    ('Е. Ким', 'E. Kim'),
    ('С. Алиев', 'S. Aliev'),
    ('Н. Ли', 'N. Li')
) AS m (new_value, old_value)
WHERE t.reason = m.old_value
  AND t.project_id IN (SELECT id FROM projects WHERE company_id IN (SELECT id FROM companies WHERE inn IN ('300000000', '300000001', '300000002', '300000010', '300000011', '300000012')));

UPDATE audit_events SET reason = replace(reason, 'Chilanzar Developer', 'Застройщик Чиланзара')
WHERE strpos(reason, 'Chilanzar Developer') > 0 AND project_id IN (SELECT id FROM projects WHERE company_id IN (SELECT id FROM companies WHERE inn IN ('300000000', '300000001', '300000002', '300000010', '300000011', '300000012'))) AND reason LIKE 'В банк: %';

UPDATE audit_events SET reason = replace(reason, 'Chilanzar Contractor', 'Подрядчик Чиланзара')
WHERE strpos(reason, 'Chilanzar Contractor') > 0 AND project_id IN (SELECT id FROM projects WHERE company_id IN (SELECT id FROM companies WHERE inn IN ('300000000', '300000001', '300000002', '300000010', '300000011', '300000012'))) AND reason LIKE 'В банк: %';

UPDATE audit_events SET reason = replace(reason, 'Chilanzar Site Inspector', 'Технадзор Чиланзара')
WHERE strpos(reason, 'Chilanzar Site Inspector') > 0 AND project_id IN (SELECT id FROM projects WHERE company_id IN (SELECT id FROM companies WHERE inn IN ('300000000', '300000001', '300000002', '300000010', '300000011', '300000012'))) AND reason LIKE 'В банк: %';

UPDATE audit_events SET reason = replace(reason, 'Navoi Developer', 'Застройщик Навои')
WHERE strpos(reason, 'Navoi Developer') > 0 AND project_id IN (SELECT id FROM projects WHERE company_id IN (SELECT id FROM companies WHERE inn IN ('300000000', '300000001', '300000002', '300000010', '300000011', '300000012'))) AND reason LIKE 'В банк: %';

UPDATE audit_events SET reason = replace(reason, 'Navoi Contractor', 'Подрядчик Навои')
WHERE strpos(reason, 'Navoi Contractor') > 0 AND project_id IN (SELECT id FROM projects WHERE company_id IN (SELECT id FROM companies WHERE inn IN ('300000000', '300000001', '300000002', '300000010', '300000011', '300000012'))) AND reason LIKE 'В банк: %';

UPDATE audit_events SET reason = replace(reason, 'Engineering Contractor', 'Подрядчик инженерии')
WHERE strpos(reason, 'Engineering Contractor') > 0 AND project_id IN (SELECT id FROM projects WHERE company_id IN (SELECT id FROM companies WHERE inn IN ('300000000', '300000001', '300000002', '300000010', '300000011', '300000012'))) AND reason LIKE 'В банк: %';

UPDATE audit_events SET reason = replace(reason, 'Navoi Site Inspector', 'Технадзор Навои')
WHERE strpos(reason, 'Navoi Site Inspector') > 0 AND project_id IN (SELECT id FROM projects WHERE company_id IN (SELECT id FROM companies WHERE inn IN ('300000000', '300000001', '300000002', '300000010', '300000011', '300000012'))) AND reason LIKE 'В банк: %';

UPDATE audit_events SET reason = replace(reason, 'Tester (full access)', 'Разработчик (тест)')
WHERE strpos(reason, 'Tester (full access)') > 0 AND project_id IN (SELECT id FROM projects WHERE company_id IN (SELECT id FROM companies WHERE inn IN ('300000000', '300000001', '300000002', '300000010', '300000011', '300000012'))) AND reason LIKE 'В банк: %';

UPDATE audit_events SET reason = replace(reason, 'Disabled Employee', 'Отключённый сотрудник')
WHERE strpos(reason, 'Disabled Employee') > 0 AND project_id IN (SELECT id FROM projects WHERE company_id IN (SELECT id FROM companies WHERE inn IN ('300000000', '300000001', '300000002', '300000010', '300000011', '300000012'))) AND reason LIKE 'В банк: %';

UPDATE audit_events SET reason = replace(reason, 'iBuild Administrator', 'Администратор iBuild')
WHERE strpos(reason, 'iBuild Administrator') > 0 AND project_id IN (SELECT id FROM projects WHERE company_id IN (SELECT id FROM companies WHERE inn IN ('300000000', '300000001', '300000002', '300000010', '300000011', '300000012'))) AND reason LIKE 'В банк: %';

UPDATE audit_events SET reason = replace(reason, 'Committee Chair', 'Председатель комитета')
WHERE strpos(reason, 'Committee Chair') > 0 AND project_id IN (SELECT id FROM projects WHERE company_id IN (SELECT id FROM companies WHERE inn IN ('300000000', '300000001', '300000002', '300000010', '300000011', '300000012'))) AND reason LIKE 'В банк: %';

UPDATE audit_events SET reason = replace(reason, 'Deputy Chair', 'Заместитель председателя')
WHERE strpos(reason, 'Deputy Chair') > 0 AND project_id IN (SELECT id FROM projects WHERE company_id IN (SELECT id FROM companies WHERE inn IN ('300000000', '300000001', '300000002', '300000010', '300000011', '300000012'))) AND reason LIKE 'В банк: %';

UPDATE audit_events SET reason = replace(reason, 'Chief Risk Officer', 'Директор по рискам')
WHERE strpos(reason, 'Chief Risk Officer') > 0 AND project_id IN (SELECT id FROM projects WHERE company_id IN (SELECT id FROM companies WHERE inn IN ('300000000', '300000001', '300000002', '300000010', '300000011', '300000012'))) AND reason LIKE 'В банк: %';

UPDATE audit_events SET reason = replace(reason, 'Lending Director', 'Директор по кредитованию')
WHERE strpos(reason, 'Lending Director') > 0 AND project_id IN (SELECT id FROM projects WHERE company_id IN (SELECT id FROM companies WHERE inn IN ('300000000', '300000001', '300000002', '300000010', '300000011', '300000012'))) AND reason LIKE 'В банк: %';

UPDATE audit_events SET reason = replace(reason, 'Bank Lawyer', 'Юрист банка')
WHERE strpos(reason, 'Bank Lawyer') > 0 AND project_id IN (SELECT id FROM projects WHERE company_id IN (SELECT id FROM companies WHERE inn IN ('300000000', '300000001', '300000002', '300000010', '300000011', '300000012'))) AND reason LIKE 'В банк: %';

UPDATE audit_events SET reason = replace(reason, 'D. Rakhimov', 'Д. Рахимов')
WHERE strpos(reason, 'D. Rakhimov') > 0 AND project_id IN (SELECT id FROM projects WHERE company_id IN (SELECT id FROM companies WHERE inn IN ('300000000', '300000001', '300000002', '300000010', '300000011', '300000012'))) AND reason LIKE 'В банк: %';

UPDATE audit_events SET reason = replace(reason, 'S. Yusupova', 'С. Юсупова')
WHERE strpos(reason, 'S. Yusupova') > 0 AND project_id IN (SELECT id FROM projects WHERE company_id IN (SELECT id FROM companies WHERE inn IN ('300000000', '300000001', '300000002', '300000010', '300000011', '300000012'))) AND reason LIKE 'В банк: %';

UPDATE audit_events SET reason = replace(reason, 'A. Karimov', 'А. Каримов')
WHERE strpos(reason, 'A. Karimov') > 0 AND project_id IN (SELECT id FROM projects WHERE company_id IN (SELECT id FROM companies WHERE inn IN ('300000000', '300000001', '300000002', '300000010', '300000011', '300000012'))) AND reason LIKE 'В банк: %';

UPDATE audit_events SET reason = replace(reason, 'A. Usmanov', 'А. Усманов')
WHERE strpos(reason, 'A. Usmanov') > 0 AND project_id IN (SELECT id FROM projects WHERE company_id IN (SELECT id FROM companies WHERE inn IN ('300000000', '300000001', '300000002', '300000010', '300000011', '300000012'))) AND reason LIKE 'В банк: %';

UPDATE audit_events SET reason = replace(reason, 'R. Akhmedov', 'Р. Ахмедов')
WHERE strpos(reason, 'R. Akhmedov') > 0 AND project_id IN (SELECT id FROM projects WHERE company_id IN (SELECT id FROM companies WHERE inn IN ('300000000', '300000001', '300000002', '300000010', '300000011', '300000012'))) AND reason LIKE 'В банк: %';

UPDATE audit_events SET reason = replace(reason, 'E. Kim', 'Е. Ким')
WHERE strpos(reason, 'E. Kim') > 0 AND project_id IN (SELECT id FROM projects WHERE company_id IN (SELECT id FROM companies WHERE inn IN ('300000000', '300000001', '300000002', '300000010', '300000011', '300000012'))) AND reason LIKE 'В банк: %';

UPDATE audit_events SET reason = replace(reason, 'S. Aliev', 'С. Алиев')
WHERE strpos(reason, 'S. Aliev') > 0 AND project_id IN (SELECT id FROM projects WHERE company_id IN (SELECT id FROM companies WHERE inn IN ('300000000', '300000001', '300000002', '300000010', '300000011', '300000012'))) AND reason LIKE 'В банк: %';

UPDATE audit_events SET reason = replace(reason, 'N. Li', 'Н. Ли')
WHERE strpos(reason, 'N. Li') > 0 AND project_id IN (SELECT id FROM projects WHERE company_id IN (SELECT id FROM companies WHERE inn IN ('300000000', '300000001', '300000002', '300000010', '300000011', '300000012'))) AND reason LIKE 'В банк: %';

-- Bank profile, staff, groups, facilities and rule versions.
UPDATE bank_profiles AS t
SET department = m.new_value
FROM (
  VALUES
    ('отдел проектного финансирования', 'project finance department'),
    ('кредитный отдел', 'credit department')
) AS m (new_value, old_value)
WHERE t.department = m.old_value
  AND t.company_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_staff AS t
SET title = m.new_value
FROM (
  VALUES
    ('Технический эксперт', 'Technical expert'),
    ('Начальник отдела', 'Head of department'),
    ('Председатель комитета', 'Committee chair'),
    ('Заместитель председателя', 'Deputy chair'),
    ('Директор по рискам', 'Chief risk officer'),
    ('Директор по кредитованию', 'Lending director'),
    ('Юрист банка', 'Bank lawyer'),
    ('Кредитный специалист', 'Credit specialist'),
    ('Администратор банка', 'Bank administrator'),
    ('Риск-менеджер', 'Risk manager')
) AS m (new_value, old_value)
WHERE t.title = m.old_value
  AND t.bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_staff AS t
SET branch = m.new_value
FROM (
  VALUES
    ('Ташкент', 'Tashkent'),
    ('Ташкент, главный офис', 'Tashkent, head office'),
    ('Ташкент, Юнусабад', 'Tashkent, Yunusabad'),
    ('Ташкент, Чиланзар', 'Tashkent, Chilanzar')
) AS m (new_value, old_value)
WHERE t.branch = m.old_value
  AND t.bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_group_members AS t
SET title = m.new_value
FROM (
  VALUES
    ('Технический эксперт', 'Technical expert'),
    ('Начальник отдела', 'Head of department'),
    ('Председатель комитета', 'Committee chair'),
    ('Заместитель председателя', 'Deputy chair'),
    ('Директор по рискам', 'Chief risk officer'),
    ('Директор по кредитованию', 'Lending director'),
    ('Юрист банка', 'Bank lawyer'),
    ('Кредитный специалист', 'Credit specialist'),
    ('Администратор банка', 'Bank administrator'),
    ('Риск-менеджер', 'Risk manager')
) AS m (new_value, old_value)
WHERE t.title = m.old_value
  AND t.group_id IN (SELECT id FROM bank_groups WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_group_members AS t
SET branch = m.new_value
FROM (
  VALUES
    ('Ташкент', 'Tashkent'),
    ('Ташкент, главный офис', 'Tashkent, head office'),
    ('Ташкент, Юнусабад', 'Tashkent, Yunusabad'),
    ('Ташкент, Чиланзар', 'Tashkent, Chilanzar')
) AS m (new_value, old_value)
WHERE t.branch = m.old_value
  AND t.group_id IN (SELECT id FROM bank_groups WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_groups AS t
SET name = m.new_value
FROM (
  VALUES
    ('Начальники отделов проектного финансирования', 'Heads of project finance departments'),
    ('Начальники отдела', 'Heads of department'),
    ('Кредитный комитет', 'Credit committee')
) AS m (new_value, old_value)
WHERE t.name = m.old_value
  AND t.bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE project_facilities AS t
SET developer_name = m.new_value
FROM (
  VALUES
    ('Навои Девелопмент', 'Navoi Development')
) AS m (new_value, old_value)
WHERE t.developer_name = m.old_value
  AND t.bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_rule_versions AS t
SET note = m.new_value
FROM (
  VALUES
    ('Начальные правила', 'Initial rules')
) AS m (new_value, old_value)
WHERE t.note = m.old_value
  AND t.bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

-- The default document list saved into a rule version of a demo bank.
-- Only whole JSON string values are replaced.
UPDATE bank_rule_versions SET snapshot = replace(snapshot::text, '"Акт выполненных работ"', '"Certificate of completed work"')::jsonb
WHERE strpos(snapshot::text, '"Акт выполненных работ"') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_rule_versions SET snapshot = replace(snapshot::text, '"Справка ф.3 о стоимости работ"', '"Form 3 statement of work cost"')::jsonb
WHERE strpos(snapshot::text, '"Справка ф.3 о стоимости работ"') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_rule_versions SET snapshot = replace(snapshot::text, '"ЭСФ или счёт-фактура"', '"E-invoice or invoice"')::jsonb
WHERE strpos(snapshot::text, '"ЭСФ или счёт-фактура"') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_rule_versions SET snapshot = replace(snapshot::text, '"Отчёт технадзора застройщика"', '"Developer’s site supervision report"')::jsonb
WHERE strpos(snapshot::text, '"Отчёт технадзора застройщика"') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_rule_versions SET snapshot = replace(snapshot::text, '"Копия договора с подрядчиком или поставщиком"', '"Copy of the contract with the contractor or supplier"')::jsonb
WHERE strpos(snapshot::text, '"Копия договора с подрядчиком или поставщиком"') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_rule_versions SET snapshot = replace(snapshot::text, '"Лицензия подрядчика или поставщика"', '"License of the contractor or supplier"')::jsonb
WHERE strpos(snapshot::text, '"Лицензия подрядчика или поставщика"') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_rule_versions SET snapshot = replace(snapshot::text, '"Накладная"', '"Delivery note"')::jsonb
WHERE strpos(snapshot::text, '"Накладная"') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_rule_versions SET snapshot = replace(snapshot::text, '"Сертификат соответствия"', '"Certificate of conformity"')::jsonb
WHERE strpos(snapshot::text, '"Сертификат соответствия"') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_rule_versions SET snapshot = replace(snapshot::text, '"Таможенная декларация"', '"Customs declaration"')::jsonb
WHERE strpos(snapshot::text, '"Таможенная декларация"') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_rule_versions SET snapshot = replace(snapshot::text, '"Журнал бетонных работ, акты скрытых работ"', '"Concrete works log, hidden works certificates"')::jsonb
WHERE strpos(snapshot::text, '"Журнал бетонных работ, акты скрытых работ"') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_rule_versions SET snapshot = replace(snapshot::text, '"каждый транш"', '"every tranche"')::jsonb
WHERE strpos(snapshot::text, '"каждый транш"') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_rule_versions SET snapshot = replace(snapshot::text, '"каждый транш по строительным работам"', '"every tranche for construction works"')::jsonb
WHERE strpos(snapshot::text, '"каждый транш по строительным работам"') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_rule_versions SET snapshot = replace(snapshot::text, '"каждый платёж"', '"every payment"')::jsonb
WHERE strpos(snapshot::text, '"каждый платёж"') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_rule_versions SET snapshot = replace(snapshot::text, '"не реже двух раз в месяц и к траншу"', '"at least twice a month and with each tranche"')::jsonb
WHERE strpos(snapshot::text, '"не реже двух раз в месяц и к траншу"') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_rule_versions SET snapshot = replace(snapshot::text, '"первый платёж по договору"', '"first payment under the contract"')::jsonb
WHERE strpos(snapshot::text, '"первый платёж по договору"') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_rule_versions SET snapshot = replace(snapshot::text, '"поставка материалов"', '"delivery of materials"')::jsonb
WHERE strpos(snapshot::text, '"поставка материалов"') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_rule_versions SET snapshot = replace(snapshot::text, '"материалы, оборудование, работы"', '"materials, equipment, works"')::jsonb
WHERE strpos(snapshot::text, '"материалы, оборудование, работы"') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_rule_versions SET snapshot = replace(snapshot::text, '"импортные товары"', '"imported goods"')::jsonb
WHERE strpos(snapshot::text, '"импортные товары"') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_rule_versions SET snapshot = replace(snapshot::text, '"по соответствующим видам работ"', '"for the relevant types of work"')::jsonb
WHERE strpos(snapshot::text, '"по соответствующим видам работ"') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_rule_versions SET snapshot = replace(snapshot::text, '"Обязателен"', '"Required"')::jsonb
WHERE strpos(snapshot::text, '"Обязателен"') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_rule_versions SET snapshot = replace(snapshot::text, '"Обязательна"', '"Required"')::jsonb
WHERE strpos(snapshot::text, '"Обязательна"') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_rule_versions SET snapshot = replace(snapshot::text, '"Если вид деятельности лицензируется"', '"If the activity is licensed"')::jsonb
WHERE strpos(snapshot::text, '"Если вид деятельности лицензируется"') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_rule_versions SET snapshot = replace(snapshot::text, '"Для материалов"', '"For materials"')::jsonb
WHERE strpos(snapshot::text, '"Для материалов"') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_rule_versions SET snapshot = replace(snapshot::text, '"Если импорт"', '"If imported"')::jsonb
WHERE strpos(snapshot::text, '"Если импорт"') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_rule_versions SET snapshot = replace(snapshot::text, '"Для этих видов работ"', '"For these types of work"')::jsonb
WHERE strpos(snapshot::text, '"Для этих видов работ"') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_rule_versions SET snapshot = replace(snapshot::text, '"ГС п. 3.5, договор п. 2.12"', '"Rule 3.5, contract cl. 2.12"')::jsonb
WHERE strpos(snapshot::text, '"ГС п. 3.5, договор п. 2.12"') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_rule_versions SET snapshot = replace(snapshot::text, '"ГС п. 3.5"', '"Rule 3.5"')::jsonb
WHERE strpos(snapshot::text, '"ГС п. 3.5"') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_rule_versions SET snapshot = replace(snapshot::text, '"ГС п. 4.12"', '"Rule 4.12"')::jsonb
WHERE strpos(snapshot::text, '"ГС п. 4.12"') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_rule_versions SET snapshot = replace(snapshot::text, '"ГС п. 4.2, 4.7"', '"Rule 4.2, 4.7"')::jsonb
WHERE strpos(snapshot::text, '"ГС п. 4.2, 4.7"') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_rule_versions SET snapshot = replace(snapshot::text, '"ГС п. 4.5"', '"Rule 4.5"')::jsonb
WHERE strpos(snapshot::text, '"ГС п. 4.5"') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

-- Tranches of the queue.
UPDATE bank_tranches AS t
SET stage_label = m.new_value
FROM (
  VALUES
    ('Кредитный комитет', 'Credit committee'),
    ('Осмотр 27.10', 'Inspection 27.10'),
    ('Подана', 'Submitted')
) AS m (new_value, old_value)
WHERE t.stage_label = m.old_value
  AND t.bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_tranches AS t
SET holder_label = m.new_value
FROM (
  VALUES
    ('Комитет', 'Committee'),
    ('Застройщик', 'Developer'),
    ('Начальник отдела', 'Head of department'),
    ('Коллега', 'Colleague'),
    ('Платёжный отдел', 'Payments department'),
    ('Кредитный комитет', 'Credit committee'),
    ('ЭЦП и платёж (интеграция в разработке)', 'Signature and payment (integration in development)'),
    ('Эксперт', 'Expert')
) AS m (new_value, old_value)
WHERE t.holder_label = m.old_value
  AND t.bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));



UPDATE bank_tranches SET holder_label = replace(holder_label, 'Chilanzar Developer', 'Застройщик Чиланзара')
WHERE strpos(holder_label, 'Chilanzar Developer') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_tranches SET holder_label = replace(holder_label, 'Chilanzar Contractor', 'Подрядчик Чиланзара')
WHERE strpos(holder_label, 'Chilanzar Contractor') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_tranches SET holder_label = replace(holder_label, 'Chilanzar Site Inspector', 'Технадзор Чиланзара')
WHERE strpos(holder_label, 'Chilanzar Site Inspector') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_tranches SET holder_label = replace(holder_label, 'Navoi Developer', 'Застройщик Навои')
WHERE strpos(holder_label, 'Navoi Developer') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_tranches SET holder_label = replace(holder_label, 'Navoi Contractor', 'Подрядчик Навои')
WHERE strpos(holder_label, 'Navoi Contractor') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_tranches SET holder_label = replace(holder_label, 'Engineering Contractor', 'Подрядчик инженерии')
WHERE strpos(holder_label, 'Engineering Contractor') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_tranches SET holder_label = replace(holder_label, 'Navoi Site Inspector', 'Технадзор Навои')
WHERE strpos(holder_label, 'Navoi Site Inspector') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_tranches SET holder_label = replace(holder_label, 'Tester (full access)', 'Разработчик (тест)')
WHERE strpos(holder_label, 'Tester (full access)') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_tranches SET holder_label = replace(holder_label, 'Disabled Employee', 'Отключённый сотрудник')
WHERE strpos(holder_label, 'Disabled Employee') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_tranches SET holder_label = replace(holder_label, 'iBuild Administrator', 'Администратор iBuild')
WHERE strpos(holder_label, 'iBuild Administrator') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_tranches SET holder_label = replace(holder_label, 'Committee Chair', 'Председатель комитета')
WHERE strpos(holder_label, 'Committee Chair') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_tranches SET holder_label = replace(holder_label, 'Deputy Chair', 'Заместитель председателя')
WHERE strpos(holder_label, 'Deputy Chair') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_tranches SET holder_label = replace(holder_label, 'Chief Risk Officer', 'Директор по рискам')
WHERE strpos(holder_label, 'Chief Risk Officer') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_tranches SET holder_label = replace(holder_label, 'Lending Director', 'Директор по кредитованию')
WHERE strpos(holder_label, 'Lending Director') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_tranches SET holder_label = replace(holder_label, 'Bank Lawyer', 'Юрист банка')
WHERE strpos(holder_label, 'Bank Lawyer') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_tranches SET holder_label = replace(holder_label, 'D. Rakhimov', 'Д. Рахимов')
WHERE strpos(holder_label, 'D. Rakhimov') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_tranches SET holder_label = replace(holder_label, 'S. Yusupova', 'С. Юсупова')
WHERE strpos(holder_label, 'S. Yusupova') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_tranches SET holder_label = replace(holder_label, 'A. Karimov', 'А. Каримов')
WHERE strpos(holder_label, 'A. Karimov') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_tranches SET holder_label = replace(holder_label, 'A. Usmanov', 'А. Усманов')
WHERE strpos(holder_label, 'A. Usmanov') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_tranches SET holder_label = replace(holder_label, 'R. Akhmedov', 'Р. Ахмедов')
WHERE strpos(holder_label, 'R. Akhmedov') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_tranches SET holder_label = replace(holder_label, 'E. Kim', 'Е. Ким')
WHERE strpos(holder_label, 'E. Kim') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_tranches SET holder_label = replace(holder_label, 'S. Aliev', 'С. Алиев')
WHERE strpos(holder_label, 'S. Aliev') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_tranches SET holder_label = replace(holder_label, 'N. Li', 'Н. Ли')
WHERE strpos(holder_label, 'N. Li') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_tranches AS t
SET problems_label = m.new_value
FROM (
  VALUES
    ('Нет 2 документов', '2 documents missing'),
    ('2 строки на доработку', '2 lines to rework'),
    ('1 строка на доработку', '1 line to rework'),
    ('Ждёт комплект', 'Awaiting the document set'),
    ('Ждёт осмотра', 'Awaiting inspection')
) AS m (new_value, old_value)
WHERE t.problems_label = m.old_value
  AND t.bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));





UPDATE bank_tranches SET problems_label = replace(problems_label, 'Accepted with a reason: ', 'Принято с обоснованием: ')
WHERE strpos(problems_label, 'Accepted with a reason: ') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

-- Lines of the tranches.
UPDATE bank_tranche_lines AS t
SET title = m.new_value
FROM (
  VALUES
    ('Фундамент', 'Foundation'),
    ('Кладка и монолит', 'Masonry and cast-in-place concrete'),
    ('Кровля и фасад', 'Roofing and facade'),
    ('Инженерия', 'Building services'),
    ('Благоустройство', 'Landscaping'),
    ('Котлован и земляные работы', 'Excavation and earthworks'),
    ('Фундаментная плита', 'Foundation slab'),
    ('Каркас, 1–4 этажи', 'Frame works, floors 1–4'),
    ('Каркас', 'Frame works'),
    ('Арматура A500C и бетон на площадке', 'Rebar A500C and concrete on site'),
    ('Арматура А500С и бетон на площадке', 'Rebar A500C and concrete on site'),
    ('Работы нулевого цикла', 'Zero-cycle works')
) AS m (new_value, old_value)
WHERE t.title = m.old_value
  AND t.tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));



UPDATE bank_tranche_lines AS t
SET readiness_note = m.new_value
FROM (
  VALUES
    ('склад', 'in storage')
) AS m (new_value, old_value)
WHERE t.readiness_note = m.old_value
  AND t.tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_tranche_lines AS t
SET expert_name = m.new_value
FROM (
  VALUES
    ('Застройщик Чиланзара', 'Chilanzar Developer'),
    ('Подрядчик Чиланзара', 'Chilanzar Contractor'),
    ('Технадзор Чиланзара', 'Chilanzar Site Inspector'),
    ('Застройщик Навои', 'Navoi Developer'),
    ('Подрядчик Навои', 'Navoi Contractor'),
    ('Подрядчик инженерии', 'Engineering Contractor'),
    ('Технадзор Навои', 'Navoi Site Inspector'),
    ('Разработчик (тест)', 'Tester (full access)'),
    ('Отключённый сотрудник', 'Disabled Employee'),
    ('Администратор iBuild', 'iBuild Administrator'),
    ('Председатель комитета', 'Committee Chair'),
    ('Заместитель председателя', 'Deputy Chair'),
    ('Директор по рискам', 'Chief Risk Officer'),
    ('Директор по кредитованию', 'Lending Director'),
    ('Юрист банка', 'Bank Lawyer'),
    ('Д. Рахимов', 'D. Rakhimov'),
    ('С. Юсупова', 'S. Yusupova'),
    ('А. Каримов', 'A. Karimov'),
    ('А. Усманов', 'A. Usmanov'),
    ('Р. Ахмедов', 'R. Akhmedov'),
    ('Е. Ким', 'E. Kim'),
    ('С. Алиев', 'S. Aliev'),
    ('Н. Ли', 'N. Li')
) AS m (new_value, old_value)
WHERE t.expert_name = m.old_value
  AND t.tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_tranche_lines AS t
SET expert_note = m.new_value
FROM (
  VALUES
    ('Котлован выработан до проектной отметки, акт скрытых работ подписан.', 'Excavation is down to the design level. The hidden works certificate is signed.'),
    ('Секции А и Б забетонированы. В секции Б захватка 3 не забетонирована — армирование выполнено на 80%.', 'Sections A and B are concreted. In section B, pour 3 is not concreted — reinforcement is 80% done.'),
    ('Каркас 1–2 этажей смонтирован, 3–4 этажи в работе.', 'Frame for floors 1–2 is erected, floors 3–4 are in progress.'),
    ('Арматура на складе площадки. Сертификат партии не предъявлен.', 'Rebar is in the site storage. The batch certificate has not been provided.')
) AS m (new_value, old_value)
WHERE t.expert_note = m.old_value
  AND t.tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

-- Checks of the tranches. Rule tags 'ГС п. 3.5' become 'Rule 3.5'.
UPDATE bank_checks AS t
SET basis = m.new_value
FROM (
  VALUES
    ('УП-11', 'Decree UP-11')
) AS m (new_value, old_value)
WHERE t.basis = m.old_value
  AND t.tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_checks SET basis = replace(basis, ', contract cl. ', ', договор п. ')
WHERE strpos(basis, ', contract cl. ') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_checks SET basis = replace(basis, 'Rule ', 'ГС п. ')
WHERE strpos(basis, 'Rule ') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_checks AS t
SET title = m.new_value
FROM (
  VALUES
    ('Нет сертификата соответствия на арматуру', 'No certificate of conformity for the rebar'),
    ('Запрошено больше, чем подтвердил эксперт', 'Requested more than the expert confirmed'),
    ('Субподрядчик не в согласованном реестре', 'Subcontractor is not on the approved register'),
    ('Прогноз сдачи позже срока ПСД на 46 дней', 'Completion forecast is 46 days past the design deadline'),
    ('Акт выполненных работ приложен', 'Certificate of completed work attached'),
    ('Справка ф.3 о стоимости работ', 'Form 3 statement of work cost'),
    ('ЭСФ или счёт-фактура на каждый платёж', 'E-invoice or invoice for each payment'),
    ('Отчёт технадзора застройщика сдан', 'Developer’s site supervision report submitted'),
    ('Договор с подрядчиком приложен', 'Contract with the contractor attached'),
    ('Лицензия подрядчика действует', 'Contractor’s license is valid'),
    ('Остаток лимита покрывает транш', 'Remaining limit covers the tranche'),
    ('Финансирование объекта не приостановлено', 'Project financing is not suspended'),
    ('Нет документов на материалы на площадке', 'No documents for the materials on site'),
    ('У подрядчика истекли разрешительные документы', 'The contractor’s permits have expired'),
    ('Нет отказа от претензий по счетам', 'No waiver of claims for the invoices'),
    ('Сумма транша больше остатка лимита', 'The tranche is larger than the remaining limit'),
    ('Финансирование объекта приостановлено', 'Project financing is suspended'),
    ('Счёт приложен', 'Invoice attached'),
    ('Осмотр эксперта проведён', 'Expert inspection done'),
    ('Материалы на площадке подтверждены документами', 'Materials on site are backed by documents'),
    ('Лицензия и страховка подрядчика действуют', 'Contractor’s license and insurance are valid'),
    ('Отказ от претензий есть по каждому счёту', 'Every invoice has a waiver of claims'),
    ('Нет документа: Акт выполненных работ', 'Missing document: Certificate of completed work'),
    ('Нет документа: ЭСФ или счёт-фактура', 'Missing document: E-invoice or invoice')
) AS m (new_value, old_value)
WHERE t.title = m.old_value
  AND t.tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_checks AS t
SET detail = m.new_value
FROM (
  VALUES
    ('Статья «Арматура A500C и бетон на площадке». Без сертификата платёж не принимается. Застройщику отправлен запрос 25.10 в 09:12.', 'Line item “Rebar A500C and concrete on site”. Without the certificate the payment is not accepted. A request was sent to the developer on 25.10 at 09:12.'),
    ('Фундаментная плита: 980,0 против 867,9. Каркас: 640,0 против 576,0. По умолчанию к выдаче стоит подтверждённая сумма.', 'Foundation slab: 980.0 vs 867.9. Frame works: 640.0 vs 576.0. By default the confirmed amount is set for payout.'),
    ('ООО «Монолит Строй Сервис», каркас. Оплата допускается только за выполненные работы — эксперт подтвердил 12% готовности.', 'Monolit Stroy Servis LLC, frame works. Payment is allowed only for completed work — the expert confirmed 12% readiness.'),
    ('Срок по ПСД — 30.06.2028, прогноз эксперта — 15.08.2028. До шестимесячного порога, после которого дольщики могут расторгнуть договор, остаётся около 4,5 месяца.', 'Design deadline — 30.06.2028, expert forecast — 15.08.2028. About 4.5 months remain before the six-month threshold after which buyers may terminate their contracts.'),
    ('Нужен: каждый транш.', 'Required: every tranche.'),
    ('Нужен: каждый платёж.', 'Required: every payment.')
) AS m (new_value, old_value)
WHERE t.detail = m.old_value
  AND t.tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_checks SET detail = replace(detail, 'By default the confirmed amount is set for payout.', 'По умолчанию к выдаче стоит подтверждённая сумма.')
WHERE strpos(detail, 'By default the confirmed amount is set for payout.') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_checks SET detail = replace(detail, 'Payment is allowed only for completed work.', 'Оплата допускается только за выполненные работы.')
WHERE strpos(detail, 'Payment is allowed only for completed work.') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_checks SET detail = replace(detail, 'Without the statement and certificates the bank does not accept payment for them.', 'Без ведомости и сертификатов платёж по ним не принимается.')
WHERE strpos(detail, 'Without the statement and certificates the bank does not accept payment for them.') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_checks SET detail = replace(detail, ' vs ', ' против ')
WHERE strpos(detail, ' vs ') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_checks SET detail = replace(detail, 'license until ', 'лицензия до ')
WHERE strpos(detail, 'license until ') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_checks SET detail = replace(detail, 'insurance until ', 'страховка до ')
WHERE strpos(detail, 'insurance until ') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));




UPDATE bank_checks SET detail = replace(detail, 'Masonry and cast-in-place concrete', 'Кладка и монолит')
WHERE strpos(detail, 'Masonry and cast-in-place concrete') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_checks SET detail = replace(detail, 'Roofing and facade', 'Кровля и фасад')
WHERE strpos(detail, 'Roofing and facade') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_checks SET detail = replace(detail, 'Landscaping', 'Благоустройство')
WHERE strpos(detail, 'Landscaping') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_checks SET detail = replace(detail, 'Excavation and earthworks', 'Котлован и земляные работы')
WHERE strpos(detail, 'Excavation and earthworks') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_checks SET detail = replace(detail, 'Foundation slab', 'Фундаментная плита')
WHERE strpos(detail, 'Foundation slab') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_checks SET detail = replace(detail, 'Frame works, floors 1–4', 'Каркас, 1–4 этажи')
WHERE strpos(detail, 'Frame works, floors 1–4') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_checks SET detail = replace(detail, 'Rebar A500C and concrete on site', 'Арматура A500C и бетон на площадке')
WHERE strpos(detail, 'Rebar A500C and concrete on site') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_checks SET detail = replace(detail, 'Rebar A500C and concrete on site', 'Арматура А500С и бетон на площадке')
WHERE strpos(detail, 'Rebar A500C and concrete on site') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_checks SET detail = replace(detail, 'Zero-cycle works', 'Работы нулевого цикла')
WHERE strpos(detail, 'Zero-cycle works') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

-- Photos, documents and earlier payments of the lines.
UPDATE bank_line_photos AS t
SET caption = m.new_value
FROM (
  VALUES
    ('Секция А, плита', 'Section A, slab'),
    ('Секция Б, захватка 3', 'Section B, pour 3'),
    ('Тот же ракурс, прошлый осмотр', 'Same angle, previous inspection'),
    ('Котлован, общий вид', 'Excavation, general view')
) AS m (new_value, old_value)
WHERE t.caption = m.old_value
  AND t.line_id IN (SELECT id FROM bank_tranche_lines WHERE tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'))));

UPDATE bank_line_documents AS t
SET title = m.new_value
FROM (
  VALUES
    ('Акт выполненных работ №14, строки 2.1–2.6', 'Certificate of completed work No. 14, lines 2.1–2.6'),
    ('Справка ф.3 №14', 'Form 3 statement No. 14'),
    ('ЭСФ от ООО «Монолит Сервис»', 'E-invoice from Monolit Servis LLC'),
    ('Журнал бетонных работ, акт скрытых работ', 'Concrete works log, hidden works certificate'),
    ('Акт выполненных работ №14, строка 1.1', 'Certificate of completed work No. 14, line 1.1'),
    ('Акт выполненных работ №14, строки 3.1–3.4', 'Certificate of completed work No. 14, lines 3.1–3.4'),
    ('ЭСФ от ООО «Монолит Строй Сервис»', 'E-invoice from Monolit Stroy Servis LLC'),
    ('Сертификат соответствия на арматуру', 'Certificate of conformity for the rebar'),
    ('Накладная на поставку', 'Delivery note'),
    ('Ведомость материалов на площадке', 'Statement of materials on site')
) AS m (new_value, old_value)
WHERE t.title = m.old_value
  AND t.line_id IN (SELECT id FROM bank_tranche_lines WHERE tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'))));


UPDATE bank_line_payments AS t
SET label = m.new_value
FROM (
  VALUES
    ('Транш №1 (аванс)', 'Tranche No. 1 (advance)')
) AS m (new_value, old_value)
WHERE t.label = m.old_value
  AND t.line_id IN (SELECT id FROM bank_tranche_lines WHERE tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'))));


-- The sign-off route.
UPDATE bank_approval_steps AS t
SET note = m.new_value
FROM (
  VALUES
    ('Группа из 3 человек, нужно 1 согласие', 'Group of 3, 1 approval needed'),
    ('ЭЦП (интеграция в разработке)', 'Digital signature (integration in development)'),
    ('Платёж (интеграция в разработке)', 'Payment (integration in development)'),
    ('Сумма ниже порога, блоков с обоснованием нет', 'Amount below the threshold, no blocks accepted with a reason'),
    ('Платёж во внешней системе', 'Payment in an external system'),
    ('Внешняя подпись', 'External signature')
) AS m (new_value, old_value)
WHERE t.note = m.old_value
  AND t.tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_approval_steps AS t
SET actor_label = m.new_value
FROM (
  VALUES
    ('Осмотр зафиксирован', 'Inspection recorded')
) AS m (new_value, old_value)
WHERE t.actor_label = m.old_value
  AND t.tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_approval_steps SET actor_label = replace(actor_label, 'Chilanzar Developer', 'Застройщик Чиланзара')
WHERE strpos(actor_label, 'Chilanzar Developer') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_approval_steps SET actor_label = replace(actor_label, 'Chilanzar Contractor', 'Подрядчик Чиланзара')
WHERE strpos(actor_label, 'Chilanzar Contractor') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_approval_steps SET actor_label = replace(actor_label, 'Chilanzar Site Inspector', 'Технадзор Чиланзара')
WHERE strpos(actor_label, 'Chilanzar Site Inspector') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_approval_steps SET actor_label = replace(actor_label, 'Navoi Developer', 'Застройщик Навои')
WHERE strpos(actor_label, 'Navoi Developer') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_approval_steps SET actor_label = replace(actor_label, 'Navoi Contractor', 'Подрядчик Навои')
WHERE strpos(actor_label, 'Navoi Contractor') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_approval_steps SET actor_label = replace(actor_label, 'Engineering Contractor', 'Подрядчик инженерии')
WHERE strpos(actor_label, 'Engineering Contractor') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_approval_steps SET actor_label = replace(actor_label, 'Navoi Site Inspector', 'Технадзор Навои')
WHERE strpos(actor_label, 'Navoi Site Inspector') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_approval_steps SET actor_label = replace(actor_label, 'Tester (full access)', 'Разработчик (тест)')
WHERE strpos(actor_label, 'Tester (full access)') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_approval_steps SET actor_label = replace(actor_label, 'Disabled Employee', 'Отключённый сотрудник')
WHERE strpos(actor_label, 'Disabled Employee') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_approval_steps SET actor_label = replace(actor_label, 'iBuild Administrator', 'Администратор iBuild')
WHERE strpos(actor_label, 'iBuild Administrator') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_approval_steps SET actor_label = replace(actor_label, 'Committee Chair', 'Председатель комитета')
WHERE strpos(actor_label, 'Committee Chair') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_approval_steps SET actor_label = replace(actor_label, 'Deputy Chair', 'Заместитель председателя')
WHERE strpos(actor_label, 'Deputy Chair') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_approval_steps SET actor_label = replace(actor_label, 'Chief Risk Officer', 'Директор по рискам')
WHERE strpos(actor_label, 'Chief Risk Officer') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_approval_steps SET actor_label = replace(actor_label, 'Lending Director', 'Директор по кредитованию')
WHERE strpos(actor_label, 'Lending Director') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_approval_steps SET actor_label = replace(actor_label, 'Bank Lawyer', 'Юрист банка')
WHERE strpos(actor_label, 'Bank Lawyer') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_approval_steps SET actor_label = replace(actor_label, 'D. Rakhimov', 'Д. Рахимов')
WHERE strpos(actor_label, 'D. Rakhimov') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_approval_steps SET actor_label = replace(actor_label, 'S. Yusupova', 'С. Юсупова')
WHERE strpos(actor_label, 'S. Yusupova') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_approval_steps SET actor_label = replace(actor_label, 'A. Karimov', 'А. Каримов')
WHERE strpos(actor_label, 'A. Karimov') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_approval_steps SET actor_label = replace(actor_label, 'A. Usmanov', 'А. Усманов')
WHERE strpos(actor_label, 'A. Usmanov') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_approval_steps SET actor_label = replace(actor_label, 'R. Akhmedov', 'Р. Ахмедов')
WHERE strpos(actor_label, 'R. Akhmedov') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_approval_steps SET actor_label = replace(actor_label, 'E. Kim', 'Е. Ким')
WHERE strpos(actor_label, 'E. Kim') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_approval_steps SET actor_label = replace(actor_label, 'S. Aliev', 'С. Алиев')
WHERE strpos(actor_label, 'S. Aliev') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_approval_steps SET actor_label = replace(actor_label, 'N. Li', 'Н. Ли')
WHERE strpos(actor_label, 'N. Li') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_approval_votes SET actor_label = replace(actor_label, 'Chilanzar Developer', 'Застройщик Чиланзара')
WHERE strpos(actor_label, 'Chilanzar Developer') > 0 AND step_id IN (SELECT id FROM bank_approval_steps WHERE tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'))));

UPDATE bank_approval_votes SET actor_label = replace(actor_label, 'Chilanzar Contractor', 'Подрядчик Чиланзара')
WHERE strpos(actor_label, 'Chilanzar Contractor') > 0 AND step_id IN (SELECT id FROM bank_approval_steps WHERE tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'))));

UPDATE bank_approval_votes SET actor_label = replace(actor_label, 'Chilanzar Site Inspector', 'Технадзор Чиланзара')
WHERE strpos(actor_label, 'Chilanzar Site Inspector') > 0 AND step_id IN (SELECT id FROM bank_approval_steps WHERE tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'))));

UPDATE bank_approval_votes SET actor_label = replace(actor_label, 'Navoi Developer', 'Застройщик Навои')
WHERE strpos(actor_label, 'Navoi Developer') > 0 AND step_id IN (SELECT id FROM bank_approval_steps WHERE tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'))));

UPDATE bank_approval_votes SET actor_label = replace(actor_label, 'Navoi Contractor', 'Подрядчик Навои')
WHERE strpos(actor_label, 'Navoi Contractor') > 0 AND step_id IN (SELECT id FROM bank_approval_steps WHERE tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'))));

UPDATE bank_approval_votes SET actor_label = replace(actor_label, 'Engineering Contractor', 'Подрядчик инженерии')
WHERE strpos(actor_label, 'Engineering Contractor') > 0 AND step_id IN (SELECT id FROM bank_approval_steps WHERE tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'))));

UPDATE bank_approval_votes SET actor_label = replace(actor_label, 'Navoi Site Inspector', 'Технадзор Навои')
WHERE strpos(actor_label, 'Navoi Site Inspector') > 0 AND step_id IN (SELECT id FROM bank_approval_steps WHERE tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'))));

UPDATE bank_approval_votes SET actor_label = replace(actor_label, 'Tester (full access)', 'Разработчик (тест)')
WHERE strpos(actor_label, 'Tester (full access)') > 0 AND step_id IN (SELECT id FROM bank_approval_steps WHERE tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'))));

UPDATE bank_approval_votes SET actor_label = replace(actor_label, 'Disabled Employee', 'Отключённый сотрудник')
WHERE strpos(actor_label, 'Disabled Employee') > 0 AND step_id IN (SELECT id FROM bank_approval_steps WHERE tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'))));

UPDATE bank_approval_votes SET actor_label = replace(actor_label, 'iBuild Administrator', 'Администратор iBuild')
WHERE strpos(actor_label, 'iBuild Administrator') > 0 AND step_id IN (SELECT id FROM bank_approval_steps WHERE tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'))));

UPDATE bank_approval_votes SET actor_label = replace(actor_label, 'Committee Chair', 'Председатель комитета')
WHERE strpos(actor_label, 'Committee Chair') > 0 AND step_id IN (SELECT id FROM bank_approval_steps WHERE tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'))));

UPDATE bank_approval_votes SET actor_label = replace(actor_label, 'Deputy Chair', 'Заместитель председателя')
WHERE strpos(actor_label, 'Deputy Chair') > 0 AND step_id IN (SELECT id FROM bank_approval_steps WHERE tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'))));

UPDATE bank_approval_votes SET actor_label = replace(actor_label, 'Chief Risk Officer', 'Директор по рискам')
WHERE strpos(actor_label, 'Chief Risk Officer') > 0 AND step_id IN (SELECT id FROM bank_approval_steps WHERE tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'))));

UPDATE bank_approval_votes SET actor_label = replace(actor_label, 'Lending Director', 'Директор по кредитованию')
WHERE strpos(actor_label, 'Lending Director') > 0 AND step_id IN (SELECT id FROM bank_approval_steps WHERE tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'))));

UPDATE bank_approval_votes SET actor_label = replace(actor_label, 'Bank Lawyer', 'Юрист банка')
WHERE strpos(actor_label, 'Bank Lawyer') > 0 AND step_id IN (SELECT id FROM bank_approval_steps WHERE tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'))));

UPDATE bank_approval_votes SET actor_label = replace(actor_label, 'D. Rakhimov', 'Д. Рахимов')
WHERE strpos(actor_label, 'D. Rakhimov') > 0 AND step_id IN (SELECT id FROM bank_approval_steps WHERE tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'))));

UPDATE bank_approval_votes SET actor_label = replace(actor_label, 'S. Yusupova', 'С. Юсупова')
WHERE strpos(actor_label, 'S. Yusupova') > 0 AND step_id IN (SELECT id FROM bank_approval_steps WHERE tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'))));

UPDATE bank_approval_votes SET actor_label = replace(actor_label, 'A. Karimov', 'А. Каримов')
WHERE strpos(actor_label, 'A. Karimov') > 0 AND step_id IN (SELECT id FROM bank_approval_steps WHERE tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'))));

UPDATE bank_approval_votes SET actor_label = replace(actor_label, 'A. Usmanov', 'А. Усманов')
WHERE strpos(actor_label, 'A. Usmanov') > 0 AND step_id IN (SELECT id FROM bank_approval_steps WHERE tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'))));

UPDATE bank_approval_votes SET actor_label = replace(actor_label, 'R. Akhmedov', 'Р. Ахмедов')
WHERE strpos(actor_label, 'R. Akhmedov') > 0 AND step_id IN (SELECT id FROM bank_approval_steps WHERE tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'))));

UPDATE bank_approval_votes SET actor_label = replace(actor_label, 'E. Kim', 'Е. Ким')
WHERE strpos(actor_label, 'E. Kim') > 0 AND step_id IN (SELECT id FROM bank_approval_steps WHERE tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'))));

UPDATE bank_approval_votes SET actor_label = replace(actor_label, 'S. Aliev', 'С. Алиев')
WHERE strpos(actor_label, 'S. Aliev') > 0 AND step_id IN (SELECT id FROM bank_approval_steps WHERE tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'))));

UPDATE bank_approval_votes SET actor_label = replace(actor_label, 'N. Li', 'Н. Ли')
WHERE strpos(actor_label, 'N. Li') > 0 AND step_id IN (SELECT id FROM bank_approval_steps WHERE tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'))));

-- Decisions, waivers and the bank journal.
UPDATE bank_decisions SET actor_label = replace(actor_label, 'Chilanzar Developer', 'Застройщик Чиланзара')
WHERE strpos(actor_label, 'Chilanzar Developer') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_decisions SET actor_label = replace(actor_label, 'Chilanzar Contractor', 'Подрядчик Чиланзара')
WHERE strpos(actor_label, 'Chilanzar Contractor') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_decisions SET actor_label = replace(actor_label, 'Chilanzar Site Inspector', 'Технадзор Чиланзара')
WHERE strpos(actor_label, 'Chilanzar Site Inspector') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_decisions SET actor_label = replace(actor_label, 'Navoi Developer', 'Застройщик Навои')
WHERE strpos(actor_label, 'Navoi Developer') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_decisions SET actor_label = replace(actor_label, 'Navoi Contractor', 'Подрядчик Навои')
WHERE strpos(actor_label, 'Navoi Contractor') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_decisions SET actor_label = replace(actor_label, 'Engineering Contractor', 'Подрядчик инженерии')
WHERE strpos(actor_label, 'Engineering Contractor') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_decisions SET actor_label = replace(actor_label, 'Navoi Site Inspector', 'Технадзор Навои')
WHERE strpos(actor_label, 'Navoi Site Inspector') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_decisions SET actor_label = replace(actor_label, 'Tester (full access)', 'Разработчик (тест)')
WHERE strpos(actor_label, 'Tester (full access)') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_decisions SET actor_label = replace(actor_label, 'Disabled Employee', 'Отключённый сотрудник')
WHERE strpos(actor_label, 'Disabled Employee') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_decisions SET actor_label = replace(actor_label, 'iBuild Administrator', 'Администратор iBuild')
WHERE strpos(actor_label, 'iBuild Administrator') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_decisions SET actor_label = replace(actor_label, 'Committee Chair', 'Председатель комитета')
WHERE strpos(actor_label, 'Committee Chair') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_decisions SET actor_label = replace(actor_label, 'Deputy Chair', 'Заместитель председателя')
WHERE strpos(actor_label, 'Deputy Chair') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_decisions SET actor_label = replace(actor_label, 'Chief Risk Officer', 'Директор по рискам')
WHERE strpos(actor_label, 'Chief Risk Officer') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_decisions SET actor_label = replace(actor_label, 'Lending Director', 'Директор по кредитованию')
WHERE strpos(actor_label, 'Lending Director') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_decisions SET actor_label = replace(actor_label, 'Bank Lawyer', 'Юрист банка')
WHERE strpos(actor_label, 'Bank Lawyer') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_decisions SET actor_label = replace(actor_label, 'D. Rakhimov', 'Д. Рахимов')
WHERE strpos(actor_label, 'D. Rakhimov') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_decisions SET actor_label = replace(actor_label, 'S. Yusupova', 'С. Юсупова')
WHERE strpos(actor_label, 'S. Yusupova') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_decisions SET actor_label = replace(actor_label, 'A. Karimov', 'А. Каримов')
WHERE strpos(actor_label, 'A. Karimov') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_decisions SET actor_label = replace(actor_label, 'A. Usmanov', 'А. Усманов')
WHERE strpos(actor_label, 'A. Usmanov') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_decisions SET actor_label = replace(actor_label, 'R. Akhmedov', 'Р. Ахмедов')
WHERE strpos(actor_label, 'R. Akhmedov') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_decisions SET actor_label = replace(actor_label, 'E. Kim', 'Е. Ким')
WHERE strpos(actor_label, 'E. Kim') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_decisions SET actor_label = replace(actor_label, 'S. Aliev', 'С. Алиев')
WHERE strpos(actor_label, 'S. Aliev') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_decisions SET actor_label = replace(actor_label, 'N. Li', 'Н. Ли')
WHERE strpos(actor_label, 'N. Li') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_check_waivers SET actor_label = replace(actor_label, 'Chilanzar Developer', 'Застройщик Чиланзара')
WHERE strpos(actor_label, 'Chilanzar Developer') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_check_waivers SET actor_label = replace(actor_label, 'Chilanzar Contractor', 'Подрядчик Чиланзара')
WHERE strpos(actor_label, 'Chilanzar Contractor') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_check_waivers SET actor_label = replace(actor_label, 'Chilanzar Site Inspector', 'Технадзор Чиланзара')
WHERE strpos(actor_label, 'Chilanzar Site Inspector') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_check_waivers SET actor_label = replace(actor_label, 'Navoi Developer', 'Застройщик Навои')
WHERE strpos(actor_label, 'Navoi Developer') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_check_waivers SET actor_label = replace(actor_label, 'Navoi Contractor', 'Подрядчик Навои')
WHERE strpos(actor_label, 'Navoi Contractor') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_check_waivers SET actor_label = replace(actor_label, 'Engineering Contractor', 'Подрядчик инженерии')
WHERE strpos(actor_label, 'Engineering Contractor') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_check_waivers SET actor_label = replace(actor_label, 'Navoi Site Inspector', 'Технадзор Навои')
WHERE strpos(actor_label, 'Navoi Site Inspector') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_check_waivers SET actor_label = replace(actor_label, 'Tester (full access)', 'Разработчик (тест)')
WHERE strpos(actor_label, 'Tester (full access)') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_check_waivers SET actor_label = replace(actor_label, 'Disabled Employee', 'Отключённый сотрудник')
WHERE strpos(actor_label, 'Disabled Employee') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_check_waivers SET actor_label = replace(actor_label, 'iBuild Administrator', 'Администратор iBuild')
WHERE strpos(actor_label, 'iBuild Administrator') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_check_waivers SET actor_label = replace(actor_label, 'Committee Chair', 'Председатель комитета')
WHERE strpos(actor_label, 'Committee Chair') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_check_waivers SET actor_label = replace(actor_label, 'Deputy Chair', 'Заместитель председателя')
WHERE strpos(actor_label, 'Deputy Chair') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_check_waivers SET actor_label = replace(actor_label, 'Chief Risk Officer', 'Директор по рискам')
WHERE strpos(actor_label, 'Chief Risk Officer') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_check_waivers SET actor_label = replace(actor_label, 'Lending Director', 'Директор по кредитованию')
WHERE strpos(actor_label, 'Lending Director') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_check_waivers SET actor_label = replace(actor_label, 'Bank Lawyer', 'Юрист банка')
WHERE strpos(actor_label, 'Bank Lawyer') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_check_waivers SET actor_label = replace(actor_label, 'D. Rakhimov', 'Д. Рахимов')
WHERE strpos(actor_label, 'D. Rakhimov') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_check_waivers SET actor_label = replace(actor_label, 'S. Yusupova', 'С. Юсупова')
WHERE strpos(actor_label, 'S. Yusupova') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_check_waivers SET actor_label = replace(actor_label, 'A. Karimov', 'А. Каримов')
WHERE strpos(actor_label, 'A. Karimov') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_check_waivers SET actor_label = replace(actor_label, 'A. Usmanov', 'А. Усманов')
WHERE strpos(actor_label, 'A. Usmanov') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_check_waivers SET actor_label = replace(actor_label, 'R. Akhmedov', 'Р. Ахмедов')
WHERE strpos(actor_label, 'R. Akhmedov') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_check_waivers SET actor_label = replace(actor_label, 'E. Kim', 'Е. Ким')
WHERE strpos(actor_label, 'E. Kim') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_check_waivers SET actor_label = replace(actor_label, 'S. Aliev', 'С. Алиев')
WHERE strpos(actor_label, 'S. Aliev') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_check_waivers SET actor_label = replace(actor_label, 'N. Li', 'Н. Ли')
WHERE strpos(actor_label, 'N. Li') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_decisions SET return_lines = replace(return_lines::text, 'Эксперт не подтвердил выдачу по этой статье', 'The expert did not confirm payout for this line item')::jsonb
WHERE strpos(return_lines::text, 'Эксперт не подтвердил выдачу по этой статье') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_decisions SET return_lines = replace(return_lines::text, 'Объём в акте больше подтверждённого (', 'The volume in the certificate exceeds the confirmed one (')::jsonb
WHERE strpos(return_lines::text, 'Объём в акте больше подтверждённого (') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_decisions SET return_lines = replace(return_lines::text, 'Нет сертификата соответствия на арматуру', 'No certificate of conformity for the rebar')::jsonb
WHERE strpos(return_lines::text, 'Нет сертификата соответствия на арматуру') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_decisions SET return_lines = replace(return_lines::text, 'Запрошено больше, чем подтвердил эксперт', 'Requested more than the expert confirmed')::jsonb
WHERE strpos(return_lines::text, 'Запрошено больше, чем подтвердил эксперт') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_decisions SET return_lines = replace(return_lines::text, 'Субподрядчик не в согласованном реестре', 'Subcontractor is not on the approved register')::jsonb
WHERE strpos(return_lines::text, 'Субподрядчик не в согласованном реестре') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_decisions SET return_lines = replace(return_lines::text, 'Прогноз сдачи позже срока ПСД на 46 дней', 'Completion forecast is 46 days past the design deadline')::jsonb
WHERE strpos(return_lines::text, 'Прогноз сдачи позже срока ПСД на 46 дней') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_decisions SET return_lines = replace(return_lines::text, 'Акт выполненных работ приложен', 'Certificate of completed work attached')::jsonb
WHERE strpos(return_lines::text, 'Акт выполненных работ приложен') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_decisions SET return_lines = replace(return_lines::text, 'Справка ф.3 о стоимости работ', 'Form 3 statement of work cost')::jsonb
WHERE strpos(return_lines::text, 'Справка ф.3 о стоимости работ') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_decisions SET return_lines = replace(return_lines::text, 'ЭСФ или счёт-фактура на каждый платёж', 'E-invoice or invoice for each payment')::jsonb
WHERE strpos(return_lines::text, 'ЭСФ или счёт-фактура на каждый платёж') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_decisions SET return_lines = replace(return_lines::text, 'Отчёт технадзора застройщика сдан', 'Developer’s site supervision report submitted')::jsonb
WHERE strpos(return_lines::text, 'Отчёт технадзора застройщика сдан') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_decisions SET return_lines = replace(return_lines::text, 'Договор с подрядчиком приложен', 'Contract with the contractor attached')::jsonb
WHERE strpos(return_lines::text, 'Договор с подрядчиком приложен') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_decisions SET return_lines = replace(return_lines::text, 'Лицензия подрядчика действует', 'Contractor’s license is valid')::jsonb
WHERE strpos(return_lines::text, 'Лицензия подрядчика действует') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_decisions SET return_lines = replace(return_lines::text, 'Остаток лимита покрывает транш', 'Remaining limit covers the tranche')::jsonb
WHERE strpos(return_lines::text, 'Остаток лимита покрывает транш') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_decisions SET return_lines = replace(return_lines::text, 'Финансирование объекта не приостановлено', 'Project financing is not suspended')::jsonb
WHERE strpos(return_lines::text, 'Финансирование объекта не приостановлено') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_decisions SET return_lines = replace(return_lines::text, 'Нет документов на материалы на площадке', 'No documents for the materials on site')::jsonb
WHERE strpos(return_lines::text, 'Нет документов на материалы на площадке') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_decisions SET return_lines = replace(return_lines::text, 'У подрядчика истекли разрешительные документы', 'The contractor’s permits have expired')::jsonb
WHERE strpos(return_lines::text, 'У подрядчика истекли разрешительные документы') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_decisions SET return_lines = replace(return_lines::text, 'Нет отказа от претензий по счетам', 'No waiver of claims for the invoices')::jsonb
WHERE strpos(return_lines::text, 'Нет отказа от претензий по счетам') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_decisions SET return_lines = replace(return_lines::text, 'Сумма транша больше остатка лимита', 'The tranche is larger than the remaining limit')::jsonb
WHERE strpos(return_lines::text, 'Сумма транша больше остатка лимита') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_decisions SET return_lines = replace(return_lines::text, 'Финансирование объекта приостановлено', 'Project financing is suspended')::jsonb
WHERE strpos(return_lines::text, 'Финансирование объекта приостановлено') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_decisions SET return_lines = replace(return_lines::text, 'Счёт приложен', 'Invoice attached')::jsonb
WHERE strpos(return_lines::text, 'Счёт приложен') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_decisions SET return_lines = replace(return_lines::text, 'Осмотр эксперта проведён', 'Expert inspection done')::jsonb
WHERE strpos(return_lines::text, 'Осмотр эксперта проведён') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_decisions SET return_lines = replace(return_lines::text, 'Материалы на площадке подтверждены документами', 'Materials on site are backed by documents')::jsonb
WHERE strpos(return_lines::text, 'Материалы на площадке подтверждены документами') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_decisions SET return_lines = replace(return_lines::text, 'Лицензия и страховка подрядчика действуют', 'Contractor’s license and insurance are valid')::jsonb
WHERE strpos(return_lines::text, 'Лицензия и страховка подрядчика действуют') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_decisions SET return_lines = replace(return_lines::text, 'Отказ от претензий есть по каждому счёту', 'Every invoice has a waiver of claims')::jsonb
WHERE strpos(return_lines::text, 'Отказ от претензий есть по каждому счёту') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_decisions SET return_lines = replace(return_lines::text, 'Нет документа: Акт выполненных работ', 'Missing document: Certificate of completed work')::jsonb
WHERE strpos(return_lines::text, 'Нет документа: Акт выполненных работ') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_decisions SET return_lines = replace(return_lines::text, 'Нет документа: ЭСФ или счёт-фактура', 'Missing document: E-invoice or invoice')::jsonb
WHERE strpos(return_lines::text, 'Нет документа: ЭСФ или счёт-фактура') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_decisions SET return_lines = replace(return_lines::text, 'ГС п. ', 'Rule ')::jsonb
WHERE strpos(return_lines::text, 'ГС п. ') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_decisions SET return_lines = replace(return_lines::text, 'Кладка и монолит', 'Masonry and cast-in-place concrete')::jsonb
WHERE strpos(return_lines::text, 'Кладка и монолит') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_decisions SET return_lines = replace(return_lines::text, 'Кровля и фасад', 'Roofing and facade')::jsonb
WHERE strpos(return_lines::text, 'Кровля и фасад') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_decisions SET return_lines = replace(return_lines::text, 'Благоустройство', 'Landscaping')::jsonb
WHERE strpos(return_lines::text, 'Благоустройство') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_decisions SET return_lines = replace(return_lines::text, 'Котлован и земляные работы', 'Excavation and earthworks')::jsonb
WHERE strpos(return_lines::text, 'Котлован и земляные работы') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_decisions SET return_lines = replace(return_lines::text, 'Фундаментная плита', 'Foundation slab')::jsonb
WHERE strpos(return_lines::text, 'Фундаментная плита') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_decisions SET return_lines = replace(return_lines::text, 'Каркас, 1–4 этажи', 'Frame works, floors 1–4')::jsonb
WHERE strpos(return_lines::text, 'Каркас, 1–4 этажи') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_decisions SET return_lines = replace(return_lines::text, 'Арматура A500C и бетон на площадке', 'Rebar A500C and concrete on site')::jsonb
WHERE strpos(return_lines::text, 'Арматура A500C и бетон на площадке') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_decisions SET return_lines = replace(return_lines::text, 'Арматура А500С и бетон на площадке', 'Rebar A500C and concrete on site')::jsonb
WHERE strpos(return_lines::text, 'Арматура А500С и бетон на площадке') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_decisions SET return_lines = replace(return_lines::text, 'Работы нулевого цикла', 'Zero-cycle works')::jsonb
WHERE strpos(return_lines::text, 'Работы нулевого цикла') > 0 AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));

UPDATE bank_audit_events AS t
SET actor_label = m.new_value
FROM (
  VALUES
    ('Система', 'System')
) AS m (new_value, old_value)
WHERE t.actor_label = m.old_value
  AND t.bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_audit_events SET actor_label = replace(actor_label, 'Chilanzar Developer', 'Застройщик Чиланзара')
WHERE strpos(actor_label, 'Chilanzar Developer') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_audit_events SET actor_label = replace(actor_label, 'Chilanzar Contractor', 'Подрядчик Чиланзара')
WHERE strpos(actor_label, 'Chilanzar Contractor') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_audit_events SET actor_label = replace(actor_label, 'Chilanzar Site Inspector', 'Технадзор Чиланзара')
WHERE strpos(actor_label, 'Chilanzar Site Inspector') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_audit_events SET actor_label = replace(actor_label, 'Navoi Developer', 'Застройщик Навои')
WHERE strpos(actor_label, 'Navoi Developer') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_audit_events SET actor_label = replace(actor_label, 'Navoi Contractor', 'Подрядчик Навои')
WHERE strpos(actor_label, 'Navoi Contractor') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_audit_events SET actor_label = replace(actor_label, 'Engineering Contractor', 'Подрядчик инженерии')
WHERE strpos(actor_label, 'Engineering Contractor') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_audit_events SET actor_label = replace(actor_label, 'Navoi Site Inspector', 'Технадзор Навои')
WHERE strpos(actor_label, 'Navoi Site Inspector') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_audit_events SET actor_label = replace(actor_label, 'Tester (full access)', 'Разработчик (тест)')
WHERE strpos(actor_label, 'Tester (full access)') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_audit_events SET actor_label = replace(actor_label, 'Disabled Employee', 'Отключённый сотрудник')
WHERE strpos(actor_label, 'Disabled Employee') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_audit_events SET actor_label = replace(actor_label, 'iBuild Administrator', 'Администратор iBuild')
WHERE strpos(actor_label, 'iBuild Administrator') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_audit_events SET actor_label = replace(actor_label, 'Committee Chair', 'Председатель комитета')
WHERE strpos(actor_label, 'Committee Chair') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_audit_events SET actor_label = replace(actor_label, 'Deputy Chair', 'Заместитель председателя')
WHERE strpos(actor_label, 'Deputy Chair') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_audit_events SET actor_label = replace(actor_label, 'Chief Risk Officer', 'Директор по рискам')
WHERE strpos(actor_label, 'Chief Risk Officer') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_audit_events SET actor_label = replace(actor_label, 'Lending Director', 'Директор по кредитованию')
WHERE strpos(actor_label, 'Lending Director') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_audit_events SET actor_label = replace(actor_label, 'Bank Lawyer', 'Юрист банка')
WHERE strpos(actor_label, 'Bank Lawyer') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_audit_events SET actor_label = replace(actor_label, 'D. Rakhimov', 'Д. Рахимов')
WHERE strpos(actor_label, 'D. Rakhimov') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_audit_events SET actor_label = replace(actor_label, 'S. Yusupova', 'С. Юсупова')
WHERE strpos(actor_label, 'S. Yusupova') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_audit_events SET actor_label = replace(actor_label, 'A. Karimov', 'А. Каримов')
WHERE strpos(actor_label, 'A. Karimov') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_audit_events SET actor_label = replace(actor_label, 'A. Usmanov', 'А. Усманов')
WHERE strpos(actor_label, 'A. Usmanov') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_audit_events SET actor_label = replace(actor_label, 'R. Akhmedov', 'Р. Ахмедов')
WHERE strpos(actor_label, 'R. Akhmedov') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_audit_events SET actor_label = replace(actor_label, 'E. Kim', 'Е. Ким')
WHERE strpos(actor_label, 'E. Kim') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_audit_events SET actor_label = replace(actor_label, 'S. Aliev', 'С. Алиев')
WHERE strpos(actor_label, 'S. Aliev') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_audit_events SET actor_label = replace(actor_label, 'N. Li', 'Н. Ли')
WHERE strpos(actor_label, 'N. Li') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

-- Inspections.

UPDATE bank_inspections SET expert_label = replace(expert_label, 'Chilanzar Developer', 'Застройщик Чиланзара')
WHERE strpos(expert_label, 'Chilanzar Developer') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_inspections SET expert_label = replace(expert_label, 'Chilanzar Contractor', 'Подрядчик Чиланзара')
WHERE strpos(expert_label, 'Chilanzar Contractor') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_inspections SET expert_label = replace(expert_label, 'Chilanzar Site Inspector', 'Технадзор Чиланзара')
WHERE strpos(expert_label, 'Chilanzar Site Inspector') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_inspections SET expert_label = replace(expert_label, 'Navoi Developer', 'Застройщик Навои')
WHERE strpos(expert_label, 'Navoi Developer') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_inspections SET expert_label = replace(expert_label, 'Navoi Contractor', 'Подрядчик Навои')
WHERE strpos(expert_label, 'Navoi Contractor') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_inspections SET expert_label = replace(expert_label, 'Engineering Contractor', 'Подрядчик инженерии')
WHERE strpos(expert_label, 'Engineering Contractor') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_inspections SET expert_label = replace(expert_label, 'Navoi Site Inspector', 'Технадзор Навои')
WHERE strpos(expert_label, 'Navoi Site Inspector') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_inspections SET expert_label = replace(expert_label, 'Tester (full access)', 'Разработчик (тест)')
WHERE strpos(expert_label, 'Tester (full access)') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_inspections SET expert_label = replace(expert_label, 'Disabled Employee', 'Отключённый сотрудник')
WHERE strpos(expert_label, 'Disabled Employee') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_inspections SET expert_label = replace(expert_label, 'iBuild Administrator', 'Администратор iBuild')
WHERE strpos(expert_label, 'iBuild Administrator') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_inspections SET expert_label = replace(expert_label, 'Committee Chair', 'Председатель комитета')
WHERE strpos(expert_label, 'Committee Chair') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_inspections SET expert_label = replace(expert_label, 'Deputy Chair', 'Заместитель председателя')
WHERE strpos(expert_label, 'Deputy Chair') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_inspections SET expert_label = replace(expert_label, 'Chief Risk Officer', 'Директор по рискам')
WHERE strpos(expert_label, 'Chief Risk Officer') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_inspections SET expert_label = replace(expert_label, 'Lending Director', 'Директор по кредитованию')
WHERE strpos(expert_label, 'Lending Director') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_inspections SET expert_label = replace(expert_label, 'Bank Lawyer', 'Юрист банка')
WHERE strpos(expert_label, 'Bank Lawyer') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_inspections SET expert_label = replace(expert_label, 'D. Rakhimov', 'Д. Рахимов')
WHERE strpos(expert_label, 'D. Rakhimov') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_inspections SET expert_label = replace(expert_label, 'S. Yusupova', 'С. Юсупова')
WHERE strpos(expert_label, 'S. Yusupova') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_inspections SET expert_label = replace(expert_label, 'A. Karimov', 'А. Каримов')
WHERE strpos(expert_label, 'A. Karimov') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_inspections SET expert_label = replace(expert_label, 'A. Usmanov', 'А. Усманов')
WHERE strpos(expert_label, 'A. Usmanov') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_inspections SET expert_label = replace(expert_label, 'R. Akhmedov', 'Р. Ахмедов')
WHERE strpos(expert_label, 'R. Akhmedov') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_inspections SET expert_label = replace(expert_label, 'E. Kim', 'Е. Ким')
WHERE strpos(expert_label, 'E. Kim') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_inspections SET expert_label = replace(expert_label, 'S. Aliev', 'С. Алиев')
WHERE strpos(expert_label, 'S. Aliev') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_inspections SET expert_label = replace(expert_label, 'N. Li', 'Н. Ли')
WHERE strpos(expert_label, 'N. Li') > 0 AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

UPDATE bank_inspections AS t
SET note = m.new_value
FROM (
  VALUES
    ('Проверить объём выполненных работ и материалы на площадке.', 'Check the volume of completed work and the materials on site.'),
    ('Объём работ по фундаменту подтверждён частично.', 'Foundation work volume partly confirmed.')
) AS m (new_value, old_value)
WHERE t.note = m.old_value
  AND t.bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));

-- Comments the bank wrote back into the developer's tranche.


UPDATE draw_comments AS t
SET body = m.new_value
FROM (
  VALUES
    ('Банк вернул эту статью на доработку.', 'The bank returned this line item for rework.')
) AS m (new_value, old_value)
WHERE t.body = m.old_value
  AND t.request_id IN (SELECT id FROM funding_requests WHERE project_id IN (SELECT id FROM projects WHERE company_id IN (SELECT id FROM companies WHERE inn IN ('300000000', '300000001', '300000002', '300000010', '300000011', '300000012'))));


-- The three sample applications of the admin CRM.
UPDATE applications AS t
SET org_name = m.new_value
FROM (
  VALUES
    ('ООО «Янги Уфқ Девелопмент»', 'Yangi Ufq Development LLC'),
    ('ООО «Самарқанд Қурилиш Инвест»', 'Samarqand Qurilish Invest LLC'),
    ('АКБ «Пример Банк»', 'Primer Bank JSCB')
) AS m (new_value, old_value)
WHERE t.org_name = m.old_value
  AND t.inn IN ('307412558', '305998114', '200950123');

UPDATE applications AS t
SET contact_name = m.new_value
FROM (
  VALUES
    ('Азиз Каримов', 'Aziz Karimov'),
    ('Шахзод Рахимов', 'Shakhzod Rakhimov'),
    ('Динара Юсупова', 'Dinara Yusupova')
) AS m (new_value, old_value)
WHERE t.contact_name = m.old_value
  AND t.inn IN ('307412558', '305998114', '200950123');

UPDATE applications SET data = jsonb_set(data, '{org_full_name}', to_jsonb('ООО «Янги Уфқ Девелопмент»'::text))
WHERE inn IN ('307412558', '305998114', '200950123') AND data #>> '{org_full_name}' = 'Yangi Ufq Development LLC';

UPDATE applications SET data = jsonb_set(data, '{org_full_name}', to_jsonb('ООО «Самарқанд Қурилиш Инвест»'::text))
WHERE inn IN ('307412558', '305998114', '200950123') AND data #>> '{org_full_name}' = 'Samarqand Qurilish Invest LLC';

UPDATE applications SET data = jsonb_set(data, '{org_full_name}', to_jsonb('АКБ «Пример Банк»'::text))
WHERE inn IN ('307412558', '305998114', '200950123') AND data #>> '{org_full_name}' = 'Primer Bank JSCB';

UPDATE applications SET data = jsonb_set(data, '{object_name}', to_jsonb('ЖК «Янги Уфқ»'::text))
WHERE inn IN ('307412558', '305998114', '200950123') AND data #>> '{object_name}' = 'Yangi Ufq Residences';

UPDATE applications SET data = jsonb_set(data, '{object_name}', to_jsonb('ЖК «Регистон Парк»'::text))
WHERE inn IN ('307412558', '305998114', '200950123') AND data #>> '{object_name}' = 'Registon Park';

UPDATE applications SET data = jsonb_set(data, '{object_address}', to_jsonb('г. Ташкент, Яшнабадский район'::text))
WHERE inn IN ('307412558', '305998114', '200950123') AND data #>> '{object_address}' = 'Yashnabad District, Tashkent';

UPDATE applications SET data = jsonb_set(data, '{object_address}', to_jsonb('г. Самарканд, ул. Университетский бульвар'::text))
WHERE inn IN ('307412558', '305998114', '200950123') AND data #>> '{object_address}' = 'University Boulevard, Samarkand';

UPDATE applications SET data = jsonb_set(data, '{owners,0,name}', to_jsonb('Азиз Каримов'::text))
WHERE inn IN ('307412558', '305998114', '200950123') AND data #>> '{owners,0,name}' = 'Aziz Karimov';

UPDATE applications SET data = jsonb_set(data, '{owners,0,name}', to_jsonb('Шахзод Рахимов'::text))
WHERE inn IN ('307412558', '305998114', '200950123') AND data #>> '{owners,0,name}' = 'Shakhzod Rakhimov';

UPDATE applications SET data = jsonb_set(data, '{owners,1,name}', to_jsonb('ООО «Регистон Холдинг»'::text))
WHERE inn IN ('307412558', '305998114', '200950123') AND data #>> '{owners,1,name}' = 'Registon Holding LLC';


-- Patterned labels.
UPDATE bank_tranches SET holder_label = regexp_replace(holder_label, ', credit specialist$', ', кредитный специалист')
WHERE holder_label ~ ', credit specialist$' AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));
UPDATE bank_tranches SET holder_label = regexp_replace(holder_label, ', expert$', ', эксперт')
WHERE holder_label ~ ', expert$' AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));
UPDATE bank_tranches SET problems_label = regexp_replace(problems_label, '(^|· )1 block( ·|$)', '\11 блок\2')
WHERE problems_label ~ '(^|· )1 block( ·|$)' AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));
UPDATE bank_tranches SET problems_label = regexp_replace(problems_label, '(^|· )([234]) blocks', '\1\2 блока', 'g')
WHERE problems_label ~ '(^|· )([234]) blocks' AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));
UPDATE bank_tranches SET problems_label = regexp_replace(problems_label, '([0-9]+) blocks', '\1 блоков', 'g')
WHERE problems_label ~ '([0-9]+) blocks' AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));
UPDATE bank_tranches SET problems_label = regexp_replace(problems_label, '(^|· )1 warning( ·|$)', '\11 предупреждение\2')
WHERE problems_label ~ '(^|· )1 warning( ·|$)' AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));
UPDATE bank_tranches SET problems_label = regexp_replace(problems_label, '(^|· )([234]) warnings', '\1\2 предупреждения', 'g')
WHERE problems_label ~ '(^|· )([234]) warnings' AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));
UPDATE bank_tranches SET problems_label = regexp_replace(problems_label, '([0-9]+) warnings', '\1 предупреждений', 'g')
WHERE problems_label ~ '([0-9]+) warnings' AND bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011'));
UPDATE bank_tranche_lines SET readiness_note = regexp_replace(readiness_note, ' since the last inspection$', ' с прошлого осмотра')
WHERE readiness_note ~ ' since the last inspection$' AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));
UPDATE bank_tranche_lines SET readiness_note = regexp_replace(readiness_note, ' since last$', ' с прошлого')
WHERE readiness_note ~ ' since last$' AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));
UPDATE bank_checks SET detail = regexp_replace(detail, '^Line items: ', 'Статьи: ')
WHERE detail ~ '^Line items: ' AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));
UPDATE bank_checks SET detail = regexp_replace(detail, '^Invoices: ', 'Счета: ')
WHERE detail ~ '^Invoices: ' AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));
UPDATE bank_checks SET detail = regexp_replace(detail, '^To pay out: (.*), left in the limit: (.*)$', 'К выдаче \1, в лимите осталось \2')
WHERE detail ~ '^To pay out: (.*), left in the limit: (.*)$' AND tranche_id IN (SELECT id FROM bank_tranches WHERE bank_id IN (SELECT id FROM companies WHERE inn IN ('300000010', '300000011')));
UPDATE bank_line_documents SET title = regexp_replace(title, '^Waiver of claims, invoice ', 'Отказ от претензий, счёт ')
WHERE title ~ '^Waiver of claims, invoice ' ;
UPDATE bank_line_payments SET label = regexp_replace(label, '^Tranche No. ', 'Транш №')
WHERE label ~ '^Tranche No. ' ;
UPDATE bank_inspections SET expert_label = regexp_replace(expert_label, ', expert$', ', эксперт')
WHERE expert_label ~ ', expert$' ;
UPDATE draw_comments SET body = regexp_replace(body, '^The bank returned the whole tranche\.', 'Банк вернул транш целиком.')
WHERE body ~ '^The bank returned the whole tranche\.' AND request_id IN (SELECT id FROM funding_requests WHERE project_id IN (SELECT id FROM projects WHERE company_id IN (SELECT id FROM companies WHERE inn IN ('300000000', '300000001', '300000002', '300000010', '300000011', '300000012'))));
UPDATE draw_comments SET body = regexp_replace(body, '^The bank approved (.*) M and returned (.*) M for rework\.', 'Банк согласовал \1 млн, на доработку вернул \2 млн.')
WHERE body ~ '^The bank approved (.*) M and returned (.*) M for rework\.' AND request_id IN (SELECT id FROM funding_requests WHERE project_id IN (SELECT id FROM projects WHERE company_id IN (SELECT id FROM companies WHERE inn IN ('300000000', '300000001', '300000002', '300000010', '300000011', '300000012'))));
UPDATE draw_comments SET body = regexp_replace(body, '^Bank: ', 'Банк: ')
WHERE body ~ '^Bank: ' AND request_id IN (SELECT id FROM funding_requests WHERE project_id IN (SELECT id FROM projects WHERE company_id IN (SELECT id FROM companies WHERE inn IN ('300000000', '300000001', '300000002', '300000010', '300000011', '300000012'))));

-- Подписи функции из 030.
CREATE OR REPLACE FUNCTION close_stuck_expert_steps()
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
  closed integer;
BEGIN
  WITH candidates AS (
    SELECT
      s.id AS step_id,
      t.id AS tranche_id,
      t.bank_id,
      t.project_id,
      COALESCE(
        (
          SELECT c.ended_at
          FROM bank_tranche_clock c
          WHERE c.tranche_id = t.id
            AND c.stage = 'inspection'
            AND c.ended_at IS NOT NULL
          ORDER BY c.ended_at DESC
          LIMIT 1
        ),
        CASE
          WHEN t.stage IN ('specialist', 'approval', 'payout') THEN t.stage_entered_at
        END,
        fr.updated_at,
        now()
      ) AS decided_at
    FROM bank_approval_steps s
    JOIN bank_tranches t ON t.id = s.tranche_id
    LEFT JOIN funding_requests fr ON fr.id = t.request_id
    WHERE s.code = 'expert'
      AND s.status = 'pending'
      AND (
        t.stage IN ('specialist', 'approval', 'payout')
        OR t.outcome IS NOT NULL
        OR fr.status IN ('tech_approved', 'approved', 'paid')
      )
  ),
  updated AS (
    UPDATE bank_approval_steps s
    SET status = 'done',
        decided_at = c.decided_at,
        actor_label = CASE
          WHEN btrim(s.actor_label) = '' THEN 'Осмотр зафиксирован'
          ELSE s.actor_label
        END
    FROM candidates c
    WHERE s.id = c.step_id
      AND s.status = 'pending'
    RETURNING s.id, c.tranche_id, c.bank_id, c.project_id
  ),
  logged AS (
    INSERT INTO bank_audit_events (
      bank_id, tranche_id, project_id, user_id, actor_label, action, detail
    )
    SELECT
      u.bank_id,
      u.tranche_id,
      u.project_id,
      NULL,
      'Система',
      'expert_step_closed',
      jsonb_build_object(
        'step', 'expert',
        'reason', 'backfill',
        'previous', 'pending',
        'status', 'done'
      )
    FROM updated u
    WHERE NOT EXISTS (
      SELECT 1
      FROM bank_audit_events e
      WHERE e.tranche_id = u.tranche_id
        AND e.action = 'expert_step_closed'
        AND COALESCE(e.detail ->> 'reason', '') = 'backfill'
    )
    RETURNING id
  )
  SELECT count(*)::integer INTO closed FROM updated;
  RETURN closed;
END;
$$;
