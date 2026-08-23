<p align="center">
  <img src="DESIGN/ibuild-logo.jpg" alt="iBuild" width="96" height="96" style="border-radius: 12px">
</p>

<h1 align="center">iBuild</h1>

<p align="center">
  <strong>Платформа верификации строительства в Узбекистане</strong><br>
  <sub>Клиентское приложение · панель застройщика · платформенная админка · общий API</sub>
</p>

<p align="center">
  <a href="README.md">English</a> · <strong>Русский</strong> · <a href="README.uz.md">Oʻzbekcha</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/stack-Dart%20%7C%20PostgreSQL-002147" alt="Stack">
  <img src="https://img.shields.io/badge/market-Uzbekistan-14866d" alt="Market">
</p>

**Содержание:** [Репозиторий](#репозиторий) · [Статус](#статус) · [Искусственный интеллект](#искусственный-интеллект) · [Карта кода](#карта-кода--пайплайн-верификации) · [Цепочка мониторинга](#цепочка-мониторинга-от-снимка-до-ведомства) · [Возможности для клиентов](#возможности-для-клиентов) · [Возможности для бизнеса](#возможности-для-бизнеса)

---

## Репозиторий

| Путь | Назначение |
|---|---|
| [`b2c/`](b2c/) | Клиентское приложение — карта, поиск, шахматка, лента фото, умный поиск |
| [`b2b/`](b2b/) | Панель застройщика и платформы — CRM, юниты, UI верификации фото |
| [`server/`](server/) | Dart REST + WebSocket API, PostgreSQL, AI-движки |
| [`packages/ibuild_core/`](packages/ibuild_core/) | Общая тема, виджеты, доменные модели |

---

## Статус

| Слой | Статус |
|---|---|
| Умный поиск (собственный движок) | **live** |
| Скоринг лидов CRM (собственный движок) | **live** |
| Движок верификации фото (собственный — EXIF, геотег, хеши, стадия) | **alpha** → [`readiness_engine.dart`](server/lib/src/ai/readiness_engine.dart) |
| GPT-vision оверлей | **testing** — `AI_VISION_ENABLED=true` по умолчанию, активен при заданном `OPENAI_API_KEY` |
| Чат покупателя / админа (опциональный адаптер) | **planned** — написан, подключён, скрыт за `AI_CHAT_ENABLED=false` в обоих приложениях |
| Собственная construction-vision модель | **planned** — размеченные снимки собираются; **модель ещё не обучена** |
| Маркетплейс для покупателей (карта, поиск, шахматка, лента фото) | **live** |
| Панель застройщика / платформы (CRM, аналитика, юниты) | **live** — редактор инвентаря **в доработке** |

---

## Искусственный интеллект

<table width="100%" cellspacing="0" cellpadding="0">
<tr>
<td width="6" bgcolor="#14866d"></td>
<td valign="top">
<table cellspacing="0" cellpadding="16">
<tr>
<td valign="top">

<table>
<tr>
<th align="left">Движок</th>
<th align="center">Обращается к внешней модели?</th>
<th align="left">Статус</th>
<th align="left">Код сервера</th>
<th align="left">Код клиента</th>
</tr>
<tr>
<td><strong>Умный поиск</strong></td>
<td align="center">Нет</td>
<td><strong>live</strong></td>
<td><a href="server/lib/src/ai/smart_search_engine.dart"><code>smart_search_engine.dart</code></a>, <a href="server/lib/src/ai/search_dictionary.dart"><code>search_dictionary.dart</code></a>, <a href="server/lib/src/ai/search_suggester.dart"><code>search_suggester.dart</code></a></td>
<td><a href="b2c/lib/features/ai/"><code>b2c/lib/features/ai/</code></a></td>
</tr>
<tr>
<td><strong>CRM-ассистент</strong></td>
<td align="center">Нет</td>
<td><strong>live</strong></td>
<td><a href="server/lib/src/ai/lead_scoring_engine.dart"><code>lead_scoring_engine.dart</code></a></td>
<td><a href="b2b/lib/features/ai_crm/"><code>b2b/lib/features/ai_crm/</code></a></td>
</tr>
<tr>
<td><strong>Верификация фото</strong></td>
<td align="center">Только опциональный оверлей</td>
<td><strong>alpha</strong></td>
<td><a href="server/lib/src/ai/readiness_engine.dart"><code>readiness_engine.dart</code></a></td>
<td><a href="b2b/lib/features/residence/project_detail_readiness.dart"><code>project_detail_readiness.dart</code></a>, <a href="b2b/lib/features/residence/residence_site_photos.dart"><code>residence_site_photos.dart</code></a></td>
</tr>
<tr>
<td><strong>Чат покупателя / админа</strong></td>
<td align="center">Да, при включении</td>
<td><strong>planned</strong>, UI скрыт</td>
<td><a href="server/lib/src/ai/openai_client.dart"><code>openai_client.dart</code></a>, <a href="server/lib/src/ai/prompts.dart"><code>prompts.dart</code></a></td>
<td><a href="b2c/lib/features/ai/presentation/ai_chat_sheet.dart"><code>ai_chat_sheet.dart</code></a> — <code>AI_CHAT_ENABLED=false</code></td>
</tr>
</table>

<h3>Верификация фото с места строительства · <strong>alpha</strong></h3>

<table>
<tr><td><strong>Движок</strong></td><td><a href="server/lib/src/ai/readiness_engine.dart"><code>server/lib/src/ai/readiness_engine.dart</code></a></td></tr>
<tr><td><strong>Тесты</strong></td><td><a href="server/test/ai_readiness_engine_test.dart"><code>server/test/ai_readiness_engine_test.dart</code></a></td></tr>
<tr><td><strong>GPT-vision</strong> (testing)</td><td><a href="server/lib/src/ai/openai_client.dart"><code>openai_client.dart</code></a> + <a href="server/lib/src/ai/prompts.dart"><code>prompts.dart</code></a></td></tr>
<tr><td><strong>Схема</strong></td><td><a href="server/migrations/0019_ai.sql"><code>server/migrations/0019_ai.sql</code></a></td></tr>
<tr><td><strong>Флаг</strong></td><td><code>AI_VISION_ENABLED=true</code> в <a href="server/.env.example"><code>server/.env.example</code></a> — активен при заданном <code>OPENAI_API_KEY</code></td></tr>
</table>

**7 локальных этапов:**

1. Валидность входа — декодирование; дата EXIF; геотег vs координаты проекта. Отсутствие EXIF/GPS не блокирует загрузку, только помечается предупреждением — метаданные пока не обязательны, это сознательное послабление на текущем этапе раннего тестирования
2. Поиск дублей — перцептивный хеш vs прошлые отчёты
3. Классификация стадии — earthworks → landscaping
4. Заявленная vs обнаруженная стадия
5. Прогресс vs предыдущий подтверждённый отчёт
6. Визуальные риск-индикаторы (СИЗ, трещины, мусор)
7. Вердикт — `confirmed` · `requires_manual_review` · `discrepancy_found` · `violation_found`

Движок запускается из двух маршрутов: автоматически и по принципу best-effort на каждой реальной загрузке (`POST /v1/admin/projects/<id>/photo-reports`) — упавшая проверка никогда не блокирует и не срывает сохранение отчёта — и по запросу как **предпросмотр** (`POST /v1/admin/projects/<id>/photo-reports/analyze`), который администратор может вызвать до публикации: те же 7 стадий, ничего не сохраняется. Низкая уверенность классификации понижает жёсткий отказ до пометки «на ручную проверку» вместо ложного отклонения.

**GPT-vision** (testing): визуальный проход того же пайплайна верификации. Сверяет снимок B с базовым снимком A и заявленным планом — та же точка съёмки, что реально изменилось на площадке, и соответствует ли видимый прогресс заявленной стадии. Промпты: [`prompts.dart`](server/lib/src/ai/prompts.dart) и пакет промптов [`construction_verify/`](server/lib/src/ai/prompts/construction_verify/).

<h3>Умный поиск · <strong>live</strong> · без upstream-модели</h3>

Свободный текст на русском, узбекском или английском разбирается в структурные условия, юниты каталога ранжируются, при вводе появляется подсказка «серым текстом».

**Чем отличается от типичного поиска** ([подробнее](AI_SEARCH_DIFFERENTIATORS.md)):

- Понимает **отрицание** («без парковки», `mebelsiz`) — исключает, а не включает
- **Блокирует** запросы, которые не смог разобрать — не притворяется, что понял
- Ранжирует с **индексом доверия** (`constructionProgress / plannedProgress`) и именованными причинами совпадения
- **Смягчает** невыполнимые удобства вместо пустой выдачи
- Возвращает **`steps`** — трейс выполнения для клиента

Файлы: [`smart_search_engine.dart`](server/lib/src/ai/smart_search_engine.dart), [`search_dictionary.dart`](server/lib/src/ai/search_dictionary.dart), [`search_suggester.dart`](server/lib/src/ai/search_suggester.dart), тесты в [`ai_smart_search_test.dart`](server/test/ai_smart_search_test.dart) · Клиент: [`b2c/lib/features/ai/`](b2c/lib/features/ai/)

<h3>CRM-ассистент · <strong>live</strong> · без upstream-модели</h3>

Каждый лид оценивается как горячий / тёплый / холодный по намерению, глубине сообщения, таймерам SLA, дефициту юнитов и ключевым словам ru/uz/en. Сам ассистент — **дерево вариантов**.

**Функции CRM-ассистента** ([подробнее](AI_CRM_DIFFERENTIATORS.md)):

- **Объяснимый** скоринг с кодами причин, которые локализует клиент
- Сигналы недвижимости: дефицит юнитов, горячие проекты, повторный телефон
- Эскалация **SLA и молчания** (нет ответа 24ч / 3д, застрявший статус)
- **Спрос vs свободные юниты** по проектам
- Автооценка никогда не перезаписывает ручную — отдельные поля, поэтому решение человека переживает каждый новый пересчёт

Файл: [`lead_scoring_engine.dart`](server/lib/src/ai/lead_scoring_engine.dart), тесты в [`ai_lead_scoring_test.dart`](server/test/ai_lead_scoring_test.dart) · Клиент: [`b2b/lib/features/ai_crm/`](b2b/lib/features/ai_crm/)

</td>
</tr>
</table>
</td>
</tr>
</table>

---

## Карта кода — пайплайн верификации

| Что | Где |
|---|---|
| Движок верификации фото (собственный, alpha) | [`server/lib/src/ai/readiness_engine.dart`](server/lib/src/ai/readiness_engine.dart) |
| Тесты верификации | [`server/test/ai_readiness_engine_test.dart`](server/test/ai_readiness_engine_test.dart) |
| Схема вердикта в PostgreSQL | [`server/migrations/0019_ai.sql`](server/migrations/0019_ai.sql) |
| Журнал аудита A→B вызовов | [`server/migrations/0020_site_photo_cycles.sql`](server/migrations/0020_site_photo_cycles.sql) |
| Движок умного поиска (собственный, live) | [`server/lib/src/ai/smart_search_engine.dart`](server/lib/src/ai/smart_search_engine.dart) |
| Движок скоринга лидов CRM (собственный, live) | [`server/lib/src/ai/lead_scoring_engine.dart`](server/lib/src/ai/lead_scoring_engine.dart) |
| Тесты поиска и CRM | [`ai_smart_search_test.dart`](server/test/ai_smart_search_test.dart), [`ai_lead_scoring_test.dart`](server/test/ai_lead_scoring_test.dart) |
| Все AI-эндпоинты | [`server/lib/src/ai/ai_routes.dart`](server/lib/src/ai/ai_routes.dart) |
| GPT-vision оверлей (включён по умолчанию) + скрытый чат | [`server/lib/src/ai/openai_client.dart`](server/lib/src/ai/openai_client.dart) |
| Промпты для адаптера выше | [`server/lib/src/ai/prompts.dart`](server/lib/src/ai/prompts.dart) |
| Шаблон окружения — без ключей | [`server/.env.example`](server/.env.example) |

---

## Цепочка мониторинга: от снимка до ведомства

| Шаг | Этап | Статус |
|:---:|---|---|
| 1 | Фотоотчёт застройщика — датированный, с процентом готовности; геометка проверяется при наличии, пока не обязательна (раннее тестирование) | **live** |
| 2 | ИИ-верификация снимка — геотег/метаданные плюс визуальное сравнение с прошлыми отчётами | **alpha** |
| 3 | Пометка «требует уточнения» — при несовпадении застройщик объясняет и переснимает | **alpha** |
| 4 | Оповещение системы — нет корректного ответа или отставание свыше порога — критическое уведомление админу | **alpha** |
| 5 | Сигнал в ответственное ведомство | **planned** |
| 6 | Центр онлайн-наблюдения смотрит результаты проверок — [Указ Президента № УП-104](https://lex.uz/ru/docs/8245277) от 4 июня 2026 г. | **planned** |
| 7 | Результат в карточке — итог мониторинга публикуется и влияет на индекс доверия | **planned** |

---

## Возможности для клиентов

| Возможность | Статус |
|---|---|
| Карта и поиск с фильтрами «Купить / Снять / Новостройки» | **live** |
| «Шахматка» — сетка квартир и офисов со статусами в реальном времени | **live** |
| Заявка в один тап: просмотр, звонок, бронь, аренда | **live** |
| Датированная лента фотоотчётов о ходе строительства | **live** |
| Две полосы хода строительства и индекс доверия | **alpha** |
| Карточка застройщика с верифицированными документами | **live** |
| Калькуляторы ипотеки, рассрочки и доходности аренды | **alpha** |
| Избранное, сохранённые поиски, «Мои заявки», отзывы, три языка | **alpha** |
| Push-уведомления о цене и этапах строительства | **alpha** |
| Реф. ссылка банка на ипотеку/кредит; голосовой подбор (Newo AI) | **planned** |

---

## Возможности для бизнеса

| Возможность | Статус |
|---|---|
| Проекты, корпуса, юниты, медиатека и планировки | **live** (в доработке) |
| Редактор «шахматки» с защитой от конфликтов правок | **live** (в доработке) |
| CRM заявок: воронка, статусы, теги, история событий | **live** |
| Фотоотчёты и ввод планового графика строительства | **alpha** |
| Аналитика: спрос, воронка, конверсия заявок | **live** |
| Верификация застройщика, модерация проектов и отзывов, журнал | **alpha** |
| Оповещения, включая критические по отклонению сроков | **alpha** |
| Оплата подписки через банковский перевод | **planned** |
| Отчёты банку и реферальные лиды на ипотеку/кредит | **planned** |

---

<p align="center">
  <sub>iBuild · © iBuild</sub>
</p>
