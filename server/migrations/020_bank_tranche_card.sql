-- Tranche card: order of checks, check texts, date technical supervision
-- confirmed the request. The data below fills the demo tranche of Bank Navoi
-- when it already exists. A fresh database gets the same values from the seed.

ALTER TABLE bank_checks
  ADD COLUMN sort_order integer NOT NULL DEFAULT 0;

ALTER TABLE bank_tranches
  ADD COLUMN tech_confirmed_on date;

UPDATE bank_tranches
SET tech_confirmed_on = DATE '2026-10-24',
    submitted_at = TIMESTAMPTZ '2026-10-24 18:10:00+05'
WHERE tranche_no = 2
  AND problems_label = '1 блок · 3 предупреждения';

UPDATE bank_checks AS c
SET detail = v.detail,
    sort_order = v.sort_order
FROM (
  VALUES
    ('certificate', 'Статья «Арматура A500C и бетон на площадке». Без сертификата платёж не принимается. Застройщику отправлен запрос 25.10 в 09:12.', 1),
    ('above_confirmed', 'Фундаментная плита: 980,0 против 867,9. Каркас: 640,0 против 576,0. По умолчанию к выдаче стоит подтверждённая сумма.', 2),
    ('subcontractor', 'ООО «Монолит Строй Сервис», каркас. Оплата допускается только за выполненные работы — эксперт подтвердил 12% готовности.', 3),
    ('forecast', 'Срок по ПСД — 30.06.2028, прогноз эксперта — 15.08.2028. До шестимесячного порога, после которого дольщики могут расторгнуть договор, остаётся около 4,5 месяца.', 4)
) AS v (code, detail, sort_order)
WHERE c.code = v.code
  AND c.detail = '';

UPDATE bank_checks AS c
SET title = v.title,
    basis = v.basis,
    sort_order = v.sort_order
FROM (
  VALUES
    ('passed_1', 'Акт выполненных работ приложен', 'ГС п. 3.5', 11),
    ('passed_2', 'Справка ф.3 о стоимости работ', 'ГС п. 4.12', 12),
    ('passed_3', 'ЭСФ или счёт-фактура на каждый платёж', 'ГС п. 3.5', 13),
    ('passed_4', 'Отчёт технадзора застройщика сдан', 'ГС п. 4.2', 14),
    ('passed_5', 'Договор с подрядчиком приложен', 'ГС п. 3.5', 15),
    ('passed_6', 'Лицензия подрядчика действует', 'ГС п. 3.5', 16),
    ('passed_7', 'Остаток лимита покрывает транш', 'ГС п. 3.7', 17),
    ('passed_8', 'Финансирование объекта не приостановлено', 'ГС п. 4.10', 18)
) AS v (code, title, basis, sort_order)
WHERE c.code = v.code
  AND c.title LIKE 'Пройденная проверка%';
