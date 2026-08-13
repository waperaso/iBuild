# Чем CRM AI iBuild отличается от обычного CRM AI

Типичный «CRM AI» — это либо чёрный ящик ML, который выдаёт число без объяснения, либо свободный чат-бот на LLM, который может придумать лид или цифру. Наш CRM AI (`server/lib/src/ai/lead_scoring_engine.dart`) состоит из двух частей: **детерминированный скоринг лидов** и **управляемый ассистент-дерево** (`CrmQueryEngine`). Ни один из компонентов не вызывает внешнюю модель. Ниже — смысл системы и конкретные отличия, проверяемые в коде.

---

## Зачем это нужно

CRM AI отвечает на два вопроса менеджера застройщика:

1. **Кому звонить первым?** — каждый лид получает `aiScore` (0–100), полосу `hot` / `warm` / `cold` и список причин (`aiReasons`), по которым он туда попал.
2. **Что происходит в воронке?** — ассистент по кнопкам ведёт по фиксированным сценариям: горячие лиды, кто ждёт ответа, сводка за день, нагрузка по менеджерам, конверсия, спрос по комнатам, разрез по проекту.

Сервер отдаёт структурированные данные и i18n-коды; текст интерфейса локализует клиент (`b2b/lib/features/ai_crm/`). Эндпоинты: `GET /v1/ai/crm/leads`, `POST /v1/ai/crm/query`.

---

## 1. Скоринг с именованными причинами, а не чёрный ящик

Обычный AI-скоринг в CRM возвращает число «из модели» — менеджер не знает, почему лид горячий, и не может проверить решение.

У нас каждый балл собирается из явных правил, и каждый вклад сразу подписан кодом причины. Примеры: `highIntent`, `specificUnit`, `viewingRequested`, `mortgageInterest`, `urgentKeyword`, `slaBreach`, `repeatContact`, `unitScarcity`, `hotProject`:

```dart
// server/lib/src/ai/lead_scoring_engine.dart
switch (intent) {
  case 'buy_offplan':
    points += 22;
    reasons.add('highIntent');
    reasons.add('offplanInterest');
  case 'buy':
    points += 18;
    reasons.add('highIntent');
  case 'viewing':
    points += 20;
    reasons.add('viewingRequested');
  // ...
}
```

Пороги полос зафиксированы: `hot >= 70`, `warm >= 40`, иначе `cold`. Менеджер видит не «86», а «86, потому что: высокое намерение + конкретный юнит + просрочен SLA» — это можно проверить, оспорить и показать при аудите.

---

## 2. Доменные сигналы рынка недвижимости, а не только «открытия писем»

Типичный лид-скоринг смотрит на источник трафика, клики, email-активность. Наш также учитывает состояние **каталога** и **потока по проекту**:

- **`unitScarcity`** — если в проекте, который интересует лида, свободно меньше 15% юнитов, приоритет растёт (дефицит = нужно закрывать быстрее).
- **`hotProject`** — если по этому же проекту за последние 7 дней пришло 5+ лидов, это сигнал «проект прогревается», даже если сам лид выглядит спокойным.

```dart
// server/lib/src/ai/lead_scoring_engine.dart
if (available / units.length < 0.15) {
  points += 8;
  reasons.add('unitScarcity');
}
// ...
if (recentProjectLeads >= 5) {
  points += 6;
  reasons.add('hotProject');
}
```

Скоринг привязан к реальному инвентарю застройщика, а не к абстрактным CRM-метрикам.

---

## 3. Ловит просрочку и молчание, а не только «горячих покупателей»

Помимо намерения покупателя, движок отдельно эскалирует лиды, которых команда **забыла**:

- **`slaBreach`** — новый лид без ответа дольше 120 минут (`_kSlaMinutes`).
- **`noResponse24h`** / **`noResponse3d`** — лид всё ещё в `new`/`contacted`, но с ним не связывались.
- **`stalled`** — лид застрял в воронке 3+ дня без движения.

```dart
// server/lib/src/ai/lead_scoring_engine.dart
if (status == 'new' && age.inMinutes > _kSlaMinutes) {
  points += 15;
  reasons.add('slaBreach');
}
if (stillWaiting && lastContactAt == null) {
  if (age.inDays >= 3) {
    points += 18;
    reasons.add('noResponse3d');
  } else if (age.inHours >= 24) {
    points += 10;
    reasons.add('noResponse24h');
  }
}
```

Обычная CRM покажет статус «new» без эскалации. Наш AI поднимает таких лидов наверх, потому что потеря из-за медленного ответа — отдельный класс риска.

---

## 4. AI советует, человек решает — ручная оценка не затирается

Ручное поле `score`, которое ставит менеджер, **никогда не трогается** кодом. AI пишет только в отдельные поля `aiScore`, `aiBand`, `aiReasons`, `aiScoredAt`, и в UI ручная оценка всегда выигрывает:

```dart
// server/lib/src/ai/lead_scoring_engine.dart
/// the manual `score` field is never touched, so it keeps winning in the UI.
```

Это другая философия, чем «AI решает, кому звонить первым»: система объясняет и ранжирует, финальное решение остаётся за человеком.

---

## 5. Ассистент — дерево вопросов, а не свободный чат

`CrmQueryEngine` — **не** LLM-чат, где менеджер может спросить что угодно и получить непредсказуемый ответ. Это фиксированное дерево из ~20 узлов (`hotLeads`, `whatNext`, `needsResponse`, `unassigned`, `todaySummary`, `byProject`, `byManager`, `analytics`, `conversion`, `demand`, `projectHot`, `projectFunnel`, `projectDemand`…).

Каждый узел — чистая функция от `(node, params, leadsInScope)`; сервер stateless, `breadcrumb` выводится структурно:

```dart
// server/lib/src/ai/lead_scoring_engine.dart
/// Guided option-tree backend for `POST /v1/ai/crm/query` (plan Part 3 "b2b
/// assistant" — not free chat). Every node is a pure function of
/// `(node, params, leadsInScope)`; the tree is fixed and shallow enough that
/// `breadcrumb` can be derived structurally, so the server stays stateless.
```

Нет генерации текста, нет риска выдумать несуществующий лид или цифру — только реальные посчитанные значения с кодами вроде `crmBot.hotLeads.message`, которые клиент локализует сам.

---

## 6. Спрос против остатков — сигнал для застройщика, не только для отдела продаж

Узлы `demand` и `projectDemand` сопоставляют, **сколько лидов просит квартиры с N комнатами**, с тем, **сколько таких квартир ещё свободно** в проекте:

```dart
// server/lib/src/ai/lead_scoring_engine.dart
/// Room mix asked for inside a single project, next to how many of those
/// homes are still available there — demand and supply side by side.
Map<String, dynamic> _projectDemand(...) {
  final counted = _roomDemand(projectLeads, store);
  final available = <int, int>{};
  // ... count available units by room count ...
  return {
    'cards': [
      ..._demandCards(counted),
      for (final rooms in (available.keys.toList()..sort()))
        _metricCard('crmBot.metric.availableRooms', ...),
    ],
  };
}
```

CRM AI превращается в инструмент для девелопера («спрос на трёшки в 3 раза выше остатка»), а не только в воронку для менеджера.

---

## 7. Агрегаты воронки и SLA — из тех же правил, что и скоринг

Метод `metrics()` на каждый запрос пересчитывает все лиды в scope и отдаёт единый срез:

- объём лидов (сегодня / неделя / месяц),
- распределение по полосам `hot` / `warm` / `cold`,
- нагрузка и скорость ответа **по каждому менеджеру**,
- медиана времени ответа и число нарушений SLA,
- воронка по статусам и **конверсия между этапами** (`new → contacted → scheduled → visited → qualified → won`).

Цифры в ассистенте и в списке лидов всегда согласованы — они из одного движка, а не из разных отчётов.

---

## 8. Не выглядит «пустым» у нового аккаунта

Если у застройщика в CRM пока нет лидов, ассистент не показывает голые нули. Он подставляет явно помеченные примерные карточки (`isExample: true`, `messageCode: crmBot.example.message`), чтобы новый пользователь сразу понял, как это будет выглядеть с реальными данными — без риска спутать демо с живыми лидами:

```dart
// server/lib/src/ai/lead_scoring_engine.dart
/// Sample answer for a workspace that has no leads yet.
Map<String, dynamic> _withExampleFallback(...) {
  if (hasLeads) return answer;
  final cards = _exampleCards(node);
  if (cards == null) return answer;
  return {
    ...answer,
    'messageCode': 'crmBot.example.message',
    'isExample': true,
    'cards': cards,
  };
}
```

У примерных карточек нет `leadId` и действий `openLead` / `assignToMe` — UI не может случайно открыть несуществующий лид.

---

## 9. Полностью детерминированный и без вызова модели

Как и умный поиск, CRM AI — это чистый Dart-расчёт над `store.leads` и опубликованными проектами. Нет обучения, нет OpenAI, нет задержки и стоимости токенов на каждый клик менеджера. В файле прямо указано:

```dart
// server/lib/src/ai/lead_scoring_engine.dart
/// Deterministic CRM lead scoring — plan Part 3. No LLM: pure computation
/// over `store.leads`, feeding `GET /v1/ai/crm/leads` and
/// `POST /v1/ai/crm/query`.
```

---

### Итог

CRM AI iBuild — не «чат с GPT про ваши лиды». Это **объяснимый скоринг** с причинами и доменной логикой застройщика, плюс **предсказуемый ассистент-навigator** по реальным данCRM. Отличия от типичного CRM AI: прозрачные правила вместо чёрного ящика, сигналы инвентаря и SLA вместо только маркетинговых метрик, дерево вопросов вместо свободного чата, спрос vs остатки для девелопера, и полная детерминированность без внешней модели.
