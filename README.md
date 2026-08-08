<p align="center">
  <img src="DESIGN/ibuild-logo.jpg" alt="iBuild" width="96" height="96" style="border-radius: 12px">
</p>

<h1 align="center">iBuild</h1>

<p align="center">
  <strong>One platform for buying, renting, and discovering real estate in Uzbekistan</strong>
</p>

<p align="center">
  <a href="#english">English</a> ·
  <a href="#русский">Русский</a> ·
  <a href="#o'zbek">O'zbek</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/languages-EN%20%7C%20RU%20%7C%20UZ-002147" alt="Languages">
  <img src="https://img.shields.io/badge/platforms-Web%20%7C%20iOS%20%7C%20Android%20%7C%20Desktop-lightgrey" alt="Platforms">
</p>

---

## English

**iBuild** is a digital real-estate platform that brings residential complexes and business centres together in one place — for people looking for a home or office, and for developers who need a modern sales channel.

### What you can do

| For buyers & tenants | For developers & operators |
|---|---|
| Search apartments, new builds, and offices | Publish projects and manage inventory |
| See live unit availability on an interactive grid | Receive and manage leads in one CRM |
| Filter by district, budget, and property type | Upload media, floor plans, and offers |
| Save favorites and send a viewing request in one tap | Analytics, moderation, and team roles |

### How it works

iBuild connects **buyers and tenants** with **developers and property managers**. When someone is interested in a unit, they submit a request — the platform delivers the lead to the seller. There is no checkout flow for property purchases on the buyer side; the relationship continues offline with the developer's sales team.

**Primary sales** on the platform are **new homes from developers only**. **Rentals** can include both developer-managed units and moderated listings from owners.

### Products

| App | Audience |
|---|---|
| **B2C** (`/b2c`) | Buyers and tenants — discovery, map, project pages, favorites, inquiries |
| **B2B** (`/b2b`) | Platform admins and residential-complex managers — CRM, units, media, moderation |
| **API** (`/server`) | Shared backend for both apps — REST, WebSocket live updates, PostgreSQL |

All client apps are built with **Flutter** and ship in **English, Russian, and Uzbek**.

### Repository layout

```
b2c/          Buyer & tenant app
b2b/          Admin app (platform + project operators)
server/       API service
packages/     Shared Dart packages (theme, models, widgets)
```

---

## Русский

**iBuild** — цифровая платформа недвижимости, которая объединяет жилые комплексы и бизнес-центры в одном месте: для тех, кто ищет квартиру или офис, и для застройщиков, которым нужен современный канал продаж.

### Возможности

| Покупателям и арендаторам | Застройщикам и операторам |
|---|---|
| Поиск квартир, новостроек и офисов | Публикация проектов и управление лотами |
| Живая «шахматка» доступности квартир | Приём и обработка заявок в CRM |
| Фильтры по району, бюджету и типу | Медиа, планировки, акции и рассрочка |
| Избранное и заявка на просмотр в один тап | Аналитика, модерация, роли команды |

### Как устроена платформа

iBuild связывает **покупателей и арендаторов** с **застройщиками и управляющими**. Интерес к объекту оформляется заявкой — платформа передаёт лид продавцу. Онлайн-оплаты недвижимости на стороне покупателя нет; дальнейшее общение идёт с отделом продаж застройщика.

**Продажа** на платформе — только **первичка от застройщика**. **Аренда** может включать как объекты девелопера, так и модерируемые объявления собственников.

### Продукты

| Приложение | Для кого |
|---|---|
| **B2C** (`/b2c`) | Покупатели и арендаторы — каталог, карта, карточки ЖК, избранное, заявки |
| **B2B** (`/b2b`) | Админы платформы и ЖК — CRM, юниты, медиа, модерация |
| **API** (`/server`) | Общий бэкенд — REST, WebSocket, PostgreSQL |

Клиентские приложения на **Flutter**, интерфейс на **английском, русском и узбекском**.

### Структура репозитория

```
b2c/          Приложение для покупателя
b2b/          Админ-панель
server/       API-сервис
packages/     Общие пакеты (тема, модели, виджеты)
```

---

## O'zbek

**iBuild** — O'zbekistonda uy-joy va ofislarni qidirish hamda sotish uchun yagona raqamli platforma. U xaridorlar, ijarachilar va uy-joy quruvchilari o'rtasidagi ko'prikdir.

### Imkoniyatlar

| Xaridorlar va ijarachilar uchun | Quruvchilar va operatorlar uchun |
|---|---|
| Kvartira, yangi uylar va ofislarni qidirish | Loyihalarni joylash va lotlarni boshqarish |
| Bo'sh xonadonlar jadvalini jonli ko'rish | Arizalarni yagona CRMda qabul qilish |
| Tuman, byudjet va tur bo'yicha filtrlar | Media, reja, aksiyalar va muddatli to'lov |
| Sevimlilar va bir bosishda ko'rish so'rovi | Analitika, moderatsiya, jamoa rollari |

### Platforma qanday ishlaydi

iBuild **xaridorlar va ijarachilarni** **quruvchilar va boshqaruvchilar** bilan bog'laydi. Ob'ektga qiziqish ariza orqali rasmiylashtiriladi — platforma lidni sotuvchiga yetkazadi. Xaridor tomonda onlayn to'lov yo'q; keyingi muloqot quruvchining savdo bo'limi bilan davom etadi.

**Sotuv** — faqat **quruvchidan birlamchi bozor**. **Ijara** — quruvchi ob'ektlari va moderatsiyadan o'tgan egasi e'lonlari.

### Mahsulotlar

| Ilova | Kim uchun |
|---|---|
| **B2C** (`/b2c`) | Xaridorlar — katalog, xarita, loyiha sahifalari, sevimlilar |
| **B2B** (`/b2b`) | Platforma va MK adminlari — CRM, unitlar, media |
| **API** (`/server`) | Umumiy backend — REST, WebSocket, PostgreSQL |

Barcha mijoz ilovalari **Flutter**da, interfeys **ingliz, rus va o'zbek** tillarida.

### Repozitoriy tuzilmasi

```
b2c/          Xaridor ilovasi
b2b/          Admin panel
server/       API xizmati
packages/     Umumiy paketlar (mavzu, modellar, vidjetlar)
```

---

<p align="center">
  <sub>© iBuild · Real estate, simplified.</sub>
</p>
