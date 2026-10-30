# iBuild

**Oʻzbekiston uchun qurilish kreditlari transhlari platformasi**  
Quruvchi kabineti · bank kabineti · platforma admini · yagona API

[English](README.md) · [Русский](README.ru.md) · **Oʻzbekcha**

![Flutter](https://img.shields.io/badge/Flutter-Web-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-Shelf%20API-0175C2?logo=dart&logoColor=white)
![Stage](https://img.shields.io/badge/bosqich-pilot-orange)

**Mundarija:** Repozitoriy · Holat · Rollar · Transh yoʻli · Bank kabineti · Roʻyxatdan oʻtish va CRM · Xavfsizlik · Hujjatlar

> Loyihaning avvalgi versiyasi (yangi binolar vitrinasi va AI orqali foto tekshiruvi) [`archive/legacy-v1`](https://github.com/waperaso/iBuild/tree/archive/legacy-v1) shoxida saqlanadi. `main` — yangi iBuild.

---

## Repozitoriy

| Yoʻl | Vazifasi |
| --- | --- |
| [app/](app) | Barcha rollar uchun bitta Flutter Web ilova: quruvchi, pudratchi, texnik nazorat, bank, platforma admini. Rus, ingliz, oʻzbek tillarida |
| server | Dart REST API va PostgreSQL — **yopiq repozitoriy**, bu yerda eʼlon qilinmaydi |
| [docs/](docs) | MVP chegaralari, roʻyxatdan oʻtish va qonunlar boʻyicha yozuvlar |

---

## Holat

| Qatlam | Holat |
| --- | --- |
| Obyekt byudjeti: limit, transhlarda, toʻlangan, qoldiq | **live** |
| Foto bilan transh arizasi: qoralama → texnik nazorat → direktor → bank → toʻlandi | **live** |
| Toʻlovni yozish va pul chiqmasa tasdiqni qaytarish | **live** |
| Bank kabineti: navbat, SLA muddatlari, qoʻmita, qoidalar va marshrutlar, hisobotlar | **live** |
| Bank buyurtmasi bilan inspeksiyalar, kredit stoli, transhni rasmiylashtirish ustasi | **live** |
| Quruvchi va banklarning ochiq roʻyxatdan oʻtishi, qoʻngʻiroq va tekshiruvli admin CRM | **live** |
| Faqat oʻqish uchun demo: kirish ekranida rol tugmalari, haqiqiy kompaniyalardan alohida | **live** |
| Parolni almashtirish, birinchi kirishda majburiy almashtirish, sessiya va CSRF himoyasi | **live** |
| Email xabarnomalar va jadval boʻyicha bank hisobotlari | **alpha** |
| Arizalar reyestri CSV formatida | **live** |
| Ochiq HTTPS | **planned** — pilot lokal stend sifatida ishlaydi |
| Toʻgʻridan-toʻgʻri toʻlovlar, EIP, davlat reyestrlari API, SMS, Telegram | **planned** |

---

## Rollar

Bitta hisob — obyektda bitta rol. Pudratchi oʻz arizasini tekshirmaydi.

| Rol | Qila oladi | Qila olmaydi |
| --- | --- | --- |
| Quruvchi (direktor) | Obyekt yaratish, byudjetni yuritish, odamlarni tayinlash, toʻlovni tasdiqlash va yozish | Boshqa kompaniyani koʻrish |
| Pudratchi | Tayinlangan obyektlarni koʻrish, foto bilan transh arizasi berish | Boshqa arizalarni koʻrish, obyekt yaratish |
| Texnik nazorat | Foto boʻyicha ish hajmini tasdiqlash | Toʻlovni tasdiqlash va yozish |
| Bank | Transhni koʻrib chiqish, tasdiqlash yoki rad etish, inspeksiya buyurtma qilish, hisobotlar | Quruvchi byudjetini oʻzgartirish |
| Platforma admini | Arizalarni koʻrib chiqish, qoʻngʻiroq qilish va tekshirish, kirishni ochish | — |

Yashirilgan tugma himoya emas: server har bir soʻrovda rol va aʼzolikni tekshiradi.

---

## Transh yoʻli

| Qadam | Ekrandagi holat | Pul |
| --- | --- | --- |
| 1 | Qoralama | Zaxiralanmaydi |
| 2 | Texnik nazorat tekshiruvida | Zaxirada |
| 3 | Direktor tasdigʻida | Zaxirada |
| 4 | Toʻlovga tasdiqlangan | Toʻlov yozilguncha zaxirada |
| 5 | Toʻlangan | Zaxiradan toʻlanganga oʻtadi |
| — | Rad etilgan · Bekor qilingan | Zaxira boʻshatiladi |

Pul `NUMERIC(18,2)` satrlari sifatida saqlanadi va uzatiladi, suzuvchi nuqtali sonlarsiz. Valyuta — UZS.

---

## Bank kabineti

| Imkoniyat | Holat |
| --- | --- |
| SLA muddatlari va ustuvorliklar bilan transhlar navbati | **live** |
| Transh kartasi: byudjet, foto, tarix, qaror, toʻlov | **live** |
| Bank ichidagi rollar: kredit mutaxassisi, ekspert, boʻlim boshliqlari, kredit qoʻmitasi, risk-menejer, bank admini | **live** |
| Bank admini tahrirlaydigan tasdiqlash qoidalari va marshrutlari | **live** |
| Portfel, yuklab olish, jadval boʻyicha hisobotlar | **alpha** |

---

## Roʻyxatdan oʻtish va CRM

Quruvchi yoki bank ochiq shaklda katta ariza qoldiradi. Platforma admini uni CRM sifatida yuritadi: holat, qoʻngʻiroqlar jurnali, izohlar, hujjat soʻrovi, majburiy tekshiruvlar. Tasdiqlash bitta tranzaksiyada kompaniya, direktor hisobi va birinchi obyektni yaratadi. Ariza beruvchi arizani shaxsiy havola orqali kuzatadi.

Hujjatlar va tekshiruvlar roʻyxati Oʻzbekiston qonunlariga asoslanadi (JKPTMQ, shaxsiy maʼlumotlar, ulushli qurilish). Tafsilotlar va yuristga savollar: [docs/registration.ru.md](docs/registration.ru.md). Bu ishchi yozuv, yuridik maslahat emas.

---

## Xavfsizlik

Backend, baza sxemasi, joylashtirish fayllari va kirish testlari yopiq repozitoriyda saqlanadi. Kirishni har bir soʻrovda server tekshiradi, mijoz uni faqat aks ettiradi.

---

## Hujjatlar

| Hujjat | Mazmuni |
| --- | --- |
| [docs/mvp.md](docs/mvp.md) | Pilot chegaralari, rollar, holatlar |
| [docs/registration.ru.md](docs/registration.ru.md) | Roʻyxatdan oʻtish, hujjatlar va qonunlar boʻyicha yozuvlar |

---

iBuild · © iBuild
