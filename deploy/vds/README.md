# Деплой iBuild на VDS

Инструкция для человека и для ИИ-агента. Команды ниже уже соответствуют живому серверу. Не выдумывай другие хосты, порты и файлы.

## Факты, которые нельзя менять молча

```
host: 46.8.195.36
ssh_users: root, ubuntu
ssh_key: ~/.ssh/ibuild_vds_ed25519
ssh_options: -i ~/.ssh/ibuild_vds_ed25519 -o IdentitiesOnly=yes
password_ssh: disabled
sudo: ubuntu has NOPASSWD
old_ip_do_not_use: 46.8.176.254
domains:
  ibuild.uz: static landing
  www.ibuild.uz: redirect to https://ibuild.uz
  admin.ibuild.uz: Flutter cabinet, and /api on the same host
  api.ibuild.uz: API only, anything except /api/ returns 404
api_bind: 127.0.0.1:8080
database_bind: docker network only, not published
demo: DEMO_ENABLED=true
seed: SEED_ON_START=false
demo_password_file: /srv/ibuild/secrets/seed_password
repo: https://github.com/waperaso/iBuild.git
server_checkout: /srv/ibuild/src
compose: /srv/ibuild/docker-compose.yml
landing_root: /var/www/ibuild-landing
secrets_dir: /srv/ibuild/secrets
backups_dir: /srv/ibuild/backups
tls_cert: /etc/letsencrypt/live/ibuild.uz/
nginx_site: /etc/nginx/sites-available/ibuild
timezone: Asia/Tashkent
```

Кабинет ходит в API относительными путями `/api/...` и хранит сессию в cookie `SameSite=Lax` без `Domain`. Поэтому браузерный кабинет и `/api` живут на `admin.ibuild.uz`. Не переноси API кабинета на другой origin и не включай Caddy из `docker-compose.prod.yml`: он займёт 80/443 и сломает nginx.

## Чего агент не делает

- Не коммитит и не печатает в чат приватный ключ, `/srv/ibuild/secrets/*`, пароль базы, `MAIL_KEY`, пароль администратора.
- Не генерирует `MAIL_KEY` и пароль базы заново. Без старого `mail_key` уже записанные письма не прочитать.
- Не открывает наружу порты 5432 и 8080.
- Не включает `PasswordAuthentication` и не выключает ufw.
- Не деплоит на `46.8.176.254`.
- Не ставит `SEED_ON_START=true` на этом сервере. Демо включается отдельно: `DEMO_ENABLED=true`, пароль только в файле `seed_password`.
- Не правит уже выпущенный сертификат руками и не удаляет `/etc/letsencrypt`.

Приватный ключ лежит только на машине, с которой ставили сервер: `~/.ssh/ibuild_vds_ed25519`. На новый компьютер его копируют файлом, права `600`. В git его нет и не будет.

## Как устроено

```
интернет :443
  nginx
    ibuild.uz        -> /var/www/ibuild-landing
    www.ibuild.uz    -> редирект на ibuild.uz
    admin.ibuild.uz  -> 127.0.0.1:8080  (кабинет и /api)
    api.ibuild.uz    -> 127.0.0.1:8080  (только /api/)
         |
         docker compose /srv/ibuild/docker-compose.yml
           api   образ из /srv/ibuild/src, Dockerfile server/Dockerfile.prod
           db    postgres:16, том ibuild_pg
           файлы заявок: том ibuild_files -> /app/data/files
```

Секреты читает процесс в контейнере из файлов, не из переменных:

- `/srv/ibuild/secrets/db_password`
- `/srv/ibuild/secrets/mail_key`
- `/srv/ibuild/secrets/seed_password` — пароль учебных логинов. В git его нет.

Каталог секретов `700`, сами файлы `644`, чтобы пользователь контейнера `ibuild` (uid 10001) мог их прочитать. Другие пользователи хоста в каталог не входят.

Лендинг должен открывать кабинет на другом домене. После каждой заливки `landing/` на сервере обязан существовать файл `/var/www/ibuild-landing/app-url.js`:

```js
window.IBUILD_APP_URL="https://admin.ibuild.uz";
```

В `index.html` перед `v2-i18n.js` должна быть строка `<script src="/app-url.js"></script>`. Скрипт `push-from-laptop.sh` ставит её сам. Если залить лендинг голым `rsync` и забыть это, кнопки «Войти» поведут на `ibuild.uz/#/login`, где кабинета нет.

Веб-клиент в git не хранится. Образ копирует `app/build/web`. Сборку делают на ноутбуке, не на VDS:

```sh
cd app && flutter build web --release --no-web-resources-cdn
```

Флаг `--no-web-resources-cdn` обязателен: боевой CSP не пускает шрифты и CanvasKit с чужих доменов.

## Обычный деплой

С ноутбука, из корня репозитория, после того как нужные коммиты уже есть в `origin/main`:

```sh
chmod +x deploy/vds/push-from-laptop.sh
deploy/vds/push-from-laptop.sh
```

Скрипт по очереди:

1. `git pull --ff-only` в `/srv/ibuild/src`
2. собирает Flutter web локально
3. заливает `app/build/web` и `landing/`
4. восстанавливает `app-url.js`
5. на сервере запускает `/srv/ibuild/deploy.sh` (`docker compose up -d --build`)
6. проверяет `https://api.ibuild.uz/api/ready`

Если `git pull --ff-only` отказал, на сервере есть локальные правки в `/srv/ibuild/src`. Не делай `reset --hard`, пока не поймёшь, чьи они. Рабочий каталог на сервере должен совпадать с `origin/main`.

Проверка с ноутбука. Подстановка `--resolve` нужна, если локальный DNS ещё помнит старый адрес:

```sh
curl -fsS --resolve api.ibuild.uz:443:46.8.195.36 https://api.ibuild.uz/api/ready
curl -sS -o /dev/null -w '%{http_code}\n' --resolve ibuild.uz:443:46.8.195.36 https://ibuild.uz/
curl -sS -o /dev/null -w '%{http_code} %{redirect_url}\n' --resolve www.ibuild.uz:443:46.8.195.36 https://www.ibuild.uz/
curl -sS -o /dev/null -w '%{http_code}\n' --resolve admin.ibuild.uz:443:46.8.195.36 https://admin.ibuild.uz/
curl -sS -o /dev/null -w '%{http_code}\n' --resolve api.ibuild.uz:443:46.8.195.36 https://api.ibuild.uz/
```

Ожидание: ready `{"ok":true}`, лендинг `200`, www `301` на `https://ibuild.uz/`, кабинет `200`, корень API `404`.

## SSH

```sh
ssh -i ~/.ssh/ibuild_vds_ed25519 -o IdentitiesOnly=yes root@46.8.195.36
ssh -i ~/.ssh/ibuild_vds_ed25519 -o IdentitiesOnly=yes ubuntu@46.8.195.36
```

`ubuntu` выполняет `sudo` без пароля. Парольный вход выключен файлом `/etc/ssh/sshd_config.d/00-ibuild.conf`. Имя файла начинается с `00`, потому что OpenSSH берёт первое значение, а `50-cloud-init.conf` включает пароль. Не переименовывай `00-ibuild.conf` в файл, который сортируется позже `50-cloud-init.conf`.

Перезагрузка sshd только после проверки, что новый сеанс по ключу открывается:

```sh
sshd -t && systemctl reload ssh
```

## Логи и перезапуск

```sh
ssh -i ~/.ssh/ibuild_vds_ed25519 -o IdentitiesOnly=yes root@46.8.195.36
docker compose -f /srv/ibuild/docker-compose.yml ps
docker compose -f /srv/ibuild/docker-compose.yml logs -f --tail 100 api
docker compose -f /srv/ibuild/docker-compose.yml restart api
```

Сборка образа пишет в `/var/log/ibuild-build.log`, если её запускали через `nohup`. Обычный деплой печатает лог прямо в этот SSH-сеанс.

Первый администратор платформы уже создан, логин `admin`. Пароль в эту инструкцию не входит. Сброс на сервере, новым паролем длиннее 12 символов, не печатая старый:

```sh
docker compose -f /srv/ibuild/docker-compose.yml exec -T api \
  /app/bin/operator reset-password --login admin --password 'НОВЫЙ_ПАРОЛЬ'
```

Новый пароль передай человеку один раз и не клади в git, тикет и этот файл.

## Nginx, лимиты, сертификат

Конфиг в репозитории: `deploy/vds/nginx-ibuild.conf` и `deploy/vds/ibuild-proxy.conf`. На сервере:

```
/etc/nginx/sites-available/ibuild
/etc/nginx/ibuild-proxy.conf
```

Лимиты: сайт 30 запросов/с, API 10 запросов/с, вход и регистрация 6 запросов/мин. Лишнее получает `429`. fail2ban смотрит `/var/log/nginx/error.log` и sshd. Не бани `127.0.0.1`.

После правки nginx:

```sh
nginx -t && systemctl reload nginx
```

Сертификат один на все четыре имени, каталог `/etc/letsencrypt/live/ibuild.uz/`. Его выпустил certbot, срок до 2027-02-14. Продление:

- таймер `certbot.timer` (штатно, когда до конца меньше 30 дней)
- `/etc/cron.d/ibuild`: 1-го числа в 04:00 по Ташкенту `certbot renew --quiet --deploy-hook "systemctl reload nginx"`

Повторный выпуск вручную, только если имён не хватает:

```sh
certbot certonly --webroot -w /var/www/certbot \
  --cert-name ibuild.uz \
  -d ibuild.uz -d www.ibuild.uz -d admin.ibuild.uz -d api.ibuild.uz \
  --non-interactive --agree-tos --keep-until-expiring
```

Порт 80 нужен для проверки Let's Encrypt. Не закрывай его.

## Бэкап

Каждый день в 03:15 cron пишет `/srv/ibuild/backups/ibuild-YYYYMMDD.dump` через `pg_dump` внутри контейнера базы. Это custom-формат Postgres. Файл `600`.

Ручной снимок:

```sh
docker compose -f /srv/ibuild/docker-compose.yml exec -T db \
  pg_dump -U ibuild -d ibuild --no-owner --format=custom > /srv/ibuild/backups/manual.dump
chmod 600 /srv/ibuild/backups/manual.dump
```

Восстанавливай только в новую базу, не в живую `ibuild`, пока человек явно не попросил заменить боевые данные.

## Демо для тестов и показа

`DEMO_ENABLED=true` при старте создаёт учебный мир, если его ещё нет. Боевая компания администратора (ИНН `000000000`, логин `admin`) не помечается учебной и свой пароль не меняет.

Кнопки на экране входа открывают учебный мир только для просмотра: сохранить ничего нельзя. Тот же логин с паролем из `seed_password` входит обычной сессией и может менять только учебные компании.

Логины, один пароль на всех: `a.director`, `a.contractor`, `a.tech`, `a.observer`, `a.admin`, `a.expert`, `a.head1`, `a.bankadmin`, `a.risk`, `a.committee1`. Второй объект: `b.director`, `b.contractor`, `b.tech`, `b.observer`.

## Что проверить после деплоя

- `https://api.ibuild.uz/api/ready` → `{"ok":true}`
- `https://ibuild.uz/app-url.js` содержит `https://admin.ibuild.uz`
- снаружи закрыты 5432 и 8080: `nc -z -G 5 46.8.195.36 5432` не подключается
- `docker compose ps`: api healthy, db healthy, порт API `127.0.0.1:8080->8080`
- вход в кабинет под своей учёткой, не под чужой
- `GET https://admin.ibuild.uz/api/config` отдаёт `demoEnabled: true`
- вход `a.director` с паролем из `seed_password` возвращает 200 и может менять только учебные данные
- кнопка демо на экране входа открывает тот же мир только для просмотра

Локальный DNS может ещё несколько часов отдавать старый `46.8.176.254`. Проверяй через `--resolve ...:443:46.8.195.36` или `dig @1.1.1.1`. Авторитетные серверы `dns1.airnet.uz` и `dns2.airnet.uz` уже указывают на `46.8.195.36`.
