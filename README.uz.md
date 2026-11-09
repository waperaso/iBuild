# iBuild

[English](README.md) · [Русский](README.ru.md) · **Oʻzbekcha**

Qurilish krediti nazorati. Bank kreditni transhlar bilan beradi: quruvchi har bir
transhni tasdiqlovchi hujjatlar bilan soʻraydi, texnazorat bajarilgan ishlarni
tasdiqlaydi, bank qancha toʻlashni hal qiladi, va har bir qadam jurnalda qoladi.

Flutter Web va Dart API bitta origin ustida, PostgreSQL Docker ichida.

---

## Ishga tushirish

Docker, Flutter va Dart kerak.

> **Veb ilovani `--no-web-resources-cdn` bayrogʻi bilan yigʻing.**
> Usiz Flutter CanvasKit’ni `gstatic.com` dan yuklaydi, serverning
> Content-Security-Policy’si bu soʻrovni bloklaydi va sahifa boʻsh qoladi.

```bash
(cd app && flutter build web --release --no-web-resources-cdn)
docker compose up -d --build
curl localhost:8080/api/ready
```

Soʻng <http://localhost:8080> ni oching.

Maʼlumotlar bazasi **5433** portda ochiladi, chunki `5432` odatda boshqa
Postgres tomonidan band boʻladi.

---

## Demo hisoblar

Barcha sid loginlarining paroli — `.env` dagi `SEED_PASSWORD`, sukut boʻyicha `123456`.

### Quruvchi tomoni

`a.*` — Навои Девелопмент, `b.*` — Чиланзар Строй.

| Login | Rol |
| --- | --- |
| `a.director` · `b.director` | Quruvchi |
| `a.contractor` · `b.contractor` | Pudratchi |
| `a.tech` · `b.tech` | Texnazorat |

### Bank kabineti

| Login | Rol |
| --- | --- |
| `a.observer` | Kredit mutaxassisi |
| `a.expert` | Texnik ekspert |
| `a.head1` … `a.head3` | Boʻlim boshliqlari |
| `a.committee1` … `a.committee5` | Kredit qoʻmitasi |
| `a.risk` | Risk menejeri |
| `a.bankadmin` | Bank administratori — qoidalar va marshrutlar |
| `b.observer` | Ikkinchi bankning kredit mutaxassisi |

### Platforma

| Login | Rol |
| --- | --- |
| `a.admin` | iBuild administratori |
| `a.disabled` | Ataylab oʻchirilgan, kira olmaydi |

Kirish sahifasida har bir rol uchun **faqat koʻrish uchun demo** ham bor. Demo
seansi hamma narsani koʻradi va hech narsani oʻzgartirmaydi.

---

## Tekshiruvlar

```bash
cd app    && flutter analyze && flutter test
cd server && dart analyze    && dart test
```

Server testlariga `5433` dagi pilot bazasi kerak. Ular `ibuild_test` ni yaratib
ishlatadi va `ibuild` ga tegmaydi.

---

## Zaxira nusxa

Nusxa ishlayotgan stenddan `backups/` ga olinadi. Tiklash alohida
`ibuild_restore` bazasiga boradi, ishchi `ibuild` qayta yozilmaydi. Skript
soʻrovning holati, summasi, tarixi va surati joyidaligini tekshiradi.

```bash
dir=$(./scripts/backup.sh)
./scripts/restore.sh "$dir"
```

---

## Roʻyxatdan oʻtish ekranisiz hisoblar

```bash
cd server
export DATABASE_URL='postgres://ibuild:ibuild@localhost:5433/ibuild?sslmode=disable'
dart run bin/operator.dart create --inn 300000001 --login pilot.user --name "Ism" --password "secret"
dart run bin/operator.dart reset-password --login pilot.user --password "secret"
dart run bin/operator.dart set-active --login pilot.user --active false
```

---

## Hujjatlar

| Hujjat | Nima haqida |
| --- | --- |
| [docs/presentation.ru.md](docs/presentation.ru.md) | mahsulotni 12–15 daqiqada koʻrsatish |
| [docs/audit-pre-demo.ru.md](docs/audit-pre-demo.ru.md) | koʻrsatuvdan oldingi tekshiruv: nima tuzatildi, nimaga qarash kerak |
| [docs/production.ru.md](docs/production.ru.md) | ishlab chiqarishga chiqarish |
| [docs/api.md](docs/api.md) | API shartnomasi |
| [docs/security-matrix.md](docs/security-matrix.md) | kimga nima mumkin |

Soʻrovlar reyestri — `GET /api/requests.csv`. Transhlar ekranida xuddi shu
yuklama tanlangan obyekt va holatni hisobga oladi hamda faqat rol baribir ocha
oladigan soʻrovlarni beradi.

---

## Bu jangovar server emas

Bu yerdagi Compose — mahalliy pilot stend: ommaviy HTTPS yoʻq, demo maʼlumotlar
ishga tushganda yaratiladi. Jangovar sozlamalar — [docs/production.ru.md](docs/production.ru.md) da.
