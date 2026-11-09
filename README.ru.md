# iBuild

[English](README.md) · **Русский** · [Oʻzbekcha](README.uz.md)

Контроль строительного кредита. Банк выдаёт кредит траншами: застройщик просит
очередной транш с подтверждениями, технадзор подтверждает выполненные работы,
банк решает, сколько выдать, и каждый шаг остаётся в журнале.

Flutter Web и Dart API на одном origin, PostgreSQL в Docker.

---

## Запуск

Нужны Docker, Flutter и Dart.

> **Собирайте веб с флагом `--no-web-resources-cdn`.**
> Без него Flutter тянет CanvasKit с `gstatic.com`, Content-Security-Policy
> сервера такой запрос блокирует, и страница остаётся пустой.

```bash
(cd app && flutter build web --release --no-web-resources-cdn)
docker compose up -d --build
curl localhost:8080/api/ready
```

Откройте <http://localhost:8080>.

База публикуется на **5433**: порт `5432` обычно занят другим Postgres.

---

## Демо-доступы

Пароль всех сидовых логинов — `SEED_PASSWORD` из `.env`, по умолчанию `123456`.

### Сторона застройщика

`a.*` — Навои Девелопмент, `b.*` — Чиланзар Строй.

| Логин | Роль |
| --- | --- |
| `a.director` · `b.director` | Застройщик |
| `a.contractor` · `b.contractor` | Подрядчик |
| `a.tech` · `b.tech` | Технадзор |

### Кабинет банка

| Логин | Роль |
| --- | --- |
| `a.observer` | Кредитный специалист |
| `a.expert` | Технический эксперт |
| `a.head1` … `a.head3` | Начальники отделов |
| `a.committee1` … `a.committee5` | Кредитный комитет |
| `a.risk` | Риск-менеджер |
| `a.bankadmin` | Администратор банка — правила и маршруты |
| `b.observer` | Кредитный специалист второго банка |

### Платформа

| Логин | Роль |
| --- | --- |
| `a.admin` | Администратор iBuild |
| `a.disabled` | Отключён намеренно, войти нельзя |

На странице входа есть ещё **демо только для просмотра** по каждой роли. Демо-сессия
видит всё и не меняет ничего.

---

## Проверки

```bash
cd app    && flutter analyze && flutter test
cd server && dart analyze    && dart test
```

Тестам сервера нужна база пилота на `5433`. Они заводят и используют
`ibuild_test` и не трогают `ibuild`.

---

## Копия

Копия снимается с запущенного стенда в `backups/`. Восстановление идёт в
отдельную базу `ibuild_restore`, рабочая `ibuild` не перезаписывается. Скрипт
проверяет, что у заявки на месте статус, сумма, история и фото.

```bash
dir=$(./scripts/backup.sh)
./scripts/restore.sh "$dir"
```

---

## Учётные записи без экрана регистрации

```bash
cd server
export DATABASE_URL='postgres://ibuild:ibuild@localhost:5433/ibuild?sslmode=disable'
dart run bin/operator.dart create --inn 300000001 --login pilot.user --name "Имя" --password "secret"
dart run bin/operator.dart reset-password --login pilot.user --password "secret"
dart run bin/operator.dart set-active --login pilot.user --active false
```

---

## Документы

| Документ | О чём |
| --- | --- |
| [docs/presentation.ru.md](docs/presentation.ru.md) | показ продукта на 12–15 минут |
| [docs/audit-pre-demo.ru.md](docs/audit-pre-demo.ru.md) | проверка перед показом: что починили, на что смотреть |
| [docs/production.ru.md](docs/production.ru.md) | запуск в продакшн |
| [docs/api.md](docs/api.md) | контракт API |
| [docs/security-matrix.md](docs/security-matrix.md) | кому что можно |

Реестр заявок — `GET /api/requests.csv`. На экране траншей та же выгрузка
учитывает выбранные объект и статус и отдаёт только те заявки, которые роль и
так может открыть.

---

## Это не боевой сервер

Compose здесь — локальный стенд пилота: публичного HTTPS нет, демо-данные
создаются на старте. Боевые настройки — в [docs/production.ru.md](docs/production.ru.md).
