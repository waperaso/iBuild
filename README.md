# iBuild

Локальный стенд пилота: Flutter Web и Dart API на одном origin, PostgreSQL в Docker.

Старый продукт лежит отдельно в `~/ibuild-legacy` (клон [waperaso/iBuild](https://github.com/waperaso/iBuild.git), коммит `df7e8f8`). Его не меняем. Это витрина новостроек. Новый iBuild — учёт бюджета и заявок на оплату.

## Запуск

Нужны Docker, Flutter и Dart. Порт `5432` на этой машине уже занят другим Postgres, поэтому база пилота публикуется на **5433**.

Compose отдаёт веб-приложение из `app/build/web`, поэтому сначала собираем его,
и обязательно с `--no-web-resources-cdn`: без этого флага Flutter тянет CanvasKit
с `gstatic.com`, а Content-Security-Policy сервера такой запрос блокирует — страница
остаётся пустой.

```bash
cd ~/ibuild-new
(cd app && flutter build web --release --no-web-resources-cdn)
docker compose up -d --build
```

Откройте http://localhost:8080.

Локальный пароль всех сидов: `123456`.

| Логин | Роль | Компания |
|---|---|---|
| `a.director` | Застройщик | Навои Девелопмент |
| `a.contractor` | Подрядчик | Навои Девелопмент |
| `a.tech` | Технадзор | Навои Девелопмент |
| `a.observer` | Банк (кредитный специалист) | Банк Навои |
| `b.director` | Застройщик | Чиланзар Строй |
| `b.contractor` | Подрядчик | Чиланзар Строй |
| `b.tech` | Технадзор | Чиланзар Строй |
| `b.observer` | Банк | Чиланзар Строй |

Кабинет банка (Банк Навои):

| Логин | Роль |
|---|---|
| `a.observer` | Кредитный специалист |
| `a.expert` | Технический эксперт |
| `a.head1`, `a.head2`, `a.head3` | Начальники отделов |
| `a.committee1` … `a.committee5` | Кредитный комитет |
| `a.risk` | Риск-менеджер |
| `a.bankadmin` | Администратор банка (правила и маршруты) |

Администратор платформы: `a.admin` (панель «ibuild admin»).

Сценарий показа продукта: `docs/presentation.ru.md`. Запуск в продакшн: `docs/production.ru.md`.

`a.disabled` существует и не входит: учётная запись отключена.

Оператор, без экрана регистрации:

```bash
cd server
export DATABASE_URL='postgres://ibuild:ibuild@localhost:5433/ibuild?sslmode=disable'
dart run bin/operator.dart create --inn 300000001 --login pilot.user --name "Имя" --password "secret"
dart run bin/operator.dart reset-password --login pilot.user --password "secret"
dart run bin/operator.dart set-active --login pilot.user --active false
```

## Проверки

```bash
cd app && flutter test && flutter build web --release --no-web-resources-cdn
cd ../server && dart test
```

## Копия и реестр

Реестр заявок — `GET /api/requests.csv`. На экране траншей та же выгрузка учитывает выбранные объект и статус. Видны только заявки, которые эта роль и так может открыть.

Копия снимается с запущенного стенда и кладётся в `backups/`. Восстановление идёт в отдельную базу `ibuild_restore`, рабочая база `ibuild` не перезаписывается. Скрипт проверяет, что у заявки на месте статус, сумма, история и фото.

```bash
dir=$(./scripts/backup.sh)
./scripts/restore.sh "$dir"
```

Публичного HTTPS нет. Локальный Compose — стенд пилота, не боевой сервер.

## Что уже на стенде

Вход, две компании, объекты, фирмы подрядчика, назначения и бюджет финансирования: лимит, в транше, выдано, остаток. Застройщик правит бюджет, пока по объекту нет отправленного транша. Подрядчик видит свои статьи. Чужой объект — 404.

Застройщик или подрядчик сохраняет черновик, прикладывает фото и отправляет транш на проверку. Технадзор подтверждает объём. Банк одобряет выдачу и записывает уже проведённый платёж либо снимает одобрение, если платёж не ушёл.
