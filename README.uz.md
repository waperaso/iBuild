<p align="center">
  <img src="DESIGN/ibuild-logo.jpg" alt="iBuild" width="96" height="96" style="border-radius: 12px">
</p>

<h1 align="center">iBuild</h1>

<p align="center">
  <strong>Oʻzbekistonda qurilishni tekshirish platformasi</strong><br>
  <sub>Xaridor vitrinasi · quruvchi admin paneli · platforma admin paneli · umumiy API</sub>
</p>

<p align="center">
  <a href="README.md">English</a> · <a href="README.ru.md">Русский</a> · <strong>Oʻzbekcha</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/stack-Dart%20%7C%20PostgreSQL-002147" alt="Stack">
  <img src="https://img.shields.io/badge/market-Uzbekistan-14866d" alt="Market">
</p>

**Mundarija:** [Repozitoriy](#repozitoriy) · [Holat](#holat) · [Sun'iy intellekt](#suniy-intellekt) · [Kod xaritasi](#kod-xaritasi--tekshiruv-zanjiri) · [Monitoring zanjiri](#monitoring-zanjiri-fotosuratdan-idoragacha) · [Xaridor imkoniyatlari](#xaridor-imkoniyatlari) · [Biznes imkoniyatlari](#biznes-imkoniyatlari)

---

## Repozitoriy

| Yoʻl | Vazifasi |
|---|---|
| [`b2c/`](b2c/) | Xaridor ilovasi — xarita, qidiruv, shaxmat taxtasi, foto lenta, AI qidiruv |
| [`b2b/`](b2b/) | Quruvchi + platforma admin — CRM, yunitlar, foto-tekshiruv UI |
| [`server/`](server/) | Dart REST + WebSocket API, PostgreSQL, AI dvigatellari |
| [`packages/ibuild_core/`](packages/ibuild_core/) | Umumiy tema, vidjetlar, domen modellari |

---

## Holat

| Qatlam | Holat |
|---|---|
| Aqlli qidiruv (oʻz dvigateli) | **live** |
| CRM lidlarini baholash (oʻz dvigateli) | **live** |
| Foto-tekshiruv dvigateli (oʻz dvigateli — EXIF, geobelgi, xeshlar, bosqich) | **alpha** → [`readiness_engine.dart`](server/lib/src/ai/readiness_engine.dart) |
| GPT-vision overlay | **testing** — standart holatda `AI_VISION_ENABLED=true`, `OPENAI_API_KEY` oʻrnatilganda faol |
| Xaridor / admin chat (ixtiyoriy adapter) | **planned** — yozilgan, marshrutlangan, ikkala ilovada ham `AI_CHAT_ENABLED=false` orqasida yashiringan |
| Oʻz construction-vision modeli | **planned** — belgilangan suratlar toʻplanmoqda; **model hali oʻqitilmagan** |
| Xaridorlar uchun marketplace (xarita, qidiruv, shaxmat taxtasi, foto lenta) | **live** |
| Quruvchi / platforma admin paneli (CRM, analitika, yunitlar) | **live** — inventar muharriri **takomillashtirilmoqda** |

---

## Sun'iy intellekt

<table width="100%" cellspacing="0" cellpadding="0">
<tr>
<td width="6" bgcolor="#14866d"></td>
<td valign="top">
<table cellspacing="0" cellpadding="16">
<tr>
<td valign="top">

<table>
<tr>
<th align="left">Dvigatel</th>
<th align="center">Tashqi modelga murojaat qiladimi?</th>
<th align="left">Holat</th>
<th align="left">Server kodi</th>
<th align="left">Klient kodi</th>
</tr>
<tr>
<td><strong>Aqlli qidiruv</strong></td>
<td align="center">Yoʻq</td>
<td><strong>live</strong></td>
<td><a href="server/lib/src/ai/smart_search_engine.dart"><code>smart_search_engine.dart</code></a>, <a href="server/lib/src/ai/search_dictionary.dart"><code>search_dictionary.dart</code></a>, <a href="server/lib/src/ai/search_suggester.dart"><code>search_suggester.dart</code></a></td>
<td><a href="b2c/lib/features/ai/"><code>b2c/lib/features/ai/</code></a></td>
</tr>
<tr>
<td><strong>CRM yordamchisi</strong></td>
<td align="center">Yoʻq</td>
<td><strong>live</strong></td>
<td><a href="server/lib/src/ai/lead_scoring_engine.dart"><code>lead_scoring_engine.dart</code></a></td>
<td><a href="b2b/lib/features/ai_crm/"><code>b2b/lib/features/ai_crm/</code></a></td>
</tr>
<tr>
<td><strong>Foto-tekshiruv</strong></td>
<td align="center">Faqat ixtiyoriy overlay</td>
<td><strong>alpha</strong></td>
<td><a href="server/lib/src/ai/readiness_engine.dart"><code>readiness_engine.dart</code></a></td>
<td><a href="b2b/lib/features/residence/project_detail_readiness.dart"><code>project_detail_readiness.dart</code></a>, <a href="b2b/lib/features/residence/residence_site_photos.dart"><code>residence_site_photos.dart</code></a></td>
</tr>
<tr>
<td><strong>Xaridor / admin chat</strong></td>
<td align="center">Ha, yoqilganda</td>
<td><strong>planned</strong>, UI yashiringan</td>
<td><a href="server/lib/src/ai/openai_client.dart"><code>openai_client.dart</code></a>, <a href="server/lib/src/ai/prompts.dart"><code>prompts.dart</code></a></td>
<td><a href="b2c/lib/features/ai/presentation/ai_chat_sheet.dart"><code>ai_chat_sheet.dart</code></a> — <code>AI_CHAT_ENABLED=false</code></td>
</tr>
</table>

<h3>Qurilish maydonidan foto-tekshiruv · <strong>alpha</strong></h3>

<table>
<tr><td><strong>Dvigatel</strong></td><td><a href="server/lib/src/ai/readiness_engine.dart"><code>server/lib/src/ai/readiness_engine.dart</code></a></td></tr>
<tr><td><strong>Testlar</strong></td><td><a href="server/test/ai_readiness_engine_test.dart"><code>server/test/ai_readiness_engine_test.dart</code></a></td></tr>
<tr><td><strong>GPT-vision</strong> (testing)</td><td><a href="server/lib/src/ai/openai_client.dart"><code>openai_client.dart</code></a> + <a href="server/lib/src/ai/prompts.dart"><code>prompts.dart</code></a></td></tr>
<tr><td><strong>Sxema</strong></td><td><a href="server/migrations/0019_ai.sql"><code>server/migrations/0019_ai.sql</code></a></td></tr>
<tr><td><strong>Flag</strong></td><td><a href="server/.env.example"><code>server/.env.example</code></a> faylida <code>AI_VISION_ENABLED=true</code> — <code>OPENAI_API_KEY</code> oʻrnatilganda faol</td></tr>
</table>

**7 ta lokal bosqich:**

1. Kirish maʼlumotining haqiqiyligi — rasmni dekodlash; EXIF sanasi; geobelgining loyiha koordinatalariga mosligi. EXIF/GPS yoʻqligi yuklashni bloklamaydi, faqat ogohlantirish sifatida belgilanadi — metama'lumotlar hali majburiy emas, bu joriy erta-test bosqichi uchun ataylab qoʻyilgan yengillik
2. Dublikatlarni aniqlash — perceptual xesh oldingi hisobotlar bilan solishtiriladi
3. Bosqichni klassifikatsiya qilish — earthworks → landscaping
4. Eʼlon qilingan va aniqlangan bosqichni solishtirish
5. Progressni oldingi tasdiqlangan hisobot bilan solishtirish
6. Vizual xavf koʻrsatkichlari (himoya kiyimi, yoriqlar, chiqindilar)
7. Verdikt — `confirmed` · `requires_manual_review` · `discrepancy_found` · `violation_found`

Dvigatel ikkita marshrutdan ishga tushadi: har bir haqiqiy yuklashda (`POST /v1/admin/projects/<id>/photo-reports`) avtomatik va best-effort tarzda — muvaffaqiyatsiz tekshiruv hech qachon saqlashni bloklamaydi yoki buzmaydi — va admin nashr qilishdan oldin chaqirishi mumkin boʻlgan **preview** sifatida (`POST /v1/admin/projects/<id>/photo-reports/analyze`): xuddi shu 7 bosqich, hech narsa saqlanmaydi. Ishonch darajasi past klassifikatsiya qattiq radni yolgʻon-ijobiy rad etish oʻrniga qoʻlda tekshirish belgisiga tushiradi.

**GPT-vision** (testing): xuddi shu tekshiruv pipeline'ining vizual qismi. Keyingi B fotosuratini bazaviy A va eʼlon qilingan reja bilan solishtiradi — bir xil nuqtai nazar, maydonda nima oʻzgargani va koʻrinadigan progress daʼvo qilingan bosqichga mos keladimi. Promptlar: [`prompts.dart`](server/lib/src/ai/prompts.dart) va [`construction_verify/`](server/lib/src/ai/prompts/construction_verify/) prompt toʻplami.

<h3>Aqlli qidiruv · <strong>live</strong> · tashqi modelsiz</h3>

Rus, oʻzbek yoki ingliz tilidagi erkin matnli soʻrovlar tuzilgan cheklovlarga ajratiladi, katalogdagi yunitlar reytinglanadi va yozayotganingizda "ghost text" koʻrinishidagi taklif chiqadi.

**Oddiy qidiruvdan farqi** ([batafsil](AI_SEARCH_DIFFERENTIATORS.md)):

- **Inkorni** tushunadi ("parkovkasiz", `mebelsiz`) — istisno qiladi, qoʻshmaydi
- Tahlil qila olmagan soʻrovlarni **bloklaydi** — hech qachon tushungandek koʻrsatmaydi
- **Ishonch indeksi** (`constructionProgress / plannedProgress`) va nomlangan mos kelish sabablari bilan reytinglaydi
- Imkonsiz qulayliklarni boʻsh natija oʻrniga **yumshatadi**
- Klient koʻrsata oladigan bajarilish **`steps`** izini qaytaradi

Fayllar: [`smart_search_engine.dart`](server/lib/src/ai/smart_search_engine.dart), [`search_dictionary.dart`](server/lib/src/ai/search_dictionary.dart), [`search_suggester.dart`](server/lib/src/ai/search_suggester.dart), testlari [`ai_smart_search_test.dart`](server/test/ai_smart_search_test.dart) · Klient: [`b2c/lib/features/ai/`](b2c/lib/features/ai/)

<h3>CRM yordamchisi · <strong>live</strong> · tashqi modelsiz</h3>

Har bir lid intent, xabar chuqurligi, SLA taymerlari, inventar tanqisligi va ru/uz/en kalit soʻz signallaridan kelib chiqib hot / warm / cold sifatida baholanadi. Yordamchining oʻzi — **boshqariladigan variantlar daraxti**.

**CRM yordamchisi funksiyalari** ([batafsil](AI_CRM_DIFFERENTIATORS.md)):

- Klient lokalizatsiya qiladigan sabab kodlari bilan **tushuntiriladigan** baholash
- Koʻchmas mulk signallari: yunit tanqisligi, "qizigan" loyihalar, qayta murojaat qilgan telefon
- **SLA va sukut** eskalatsiyasi (24 soat / 3 kun javobsiz, "qotib qolgan" status)
- Loyiha boʻyicha **talab va boʻsh yunitlar** solishtiruvi
- Avto-baho menejerning qoʻlda qoʻygan bahosini hech qachon ustidan yozmaydi — alohida maydonlar, shuning uchun inson qarori har bir qayta hisoblashdan omon qoladi

Fayl: [`lead_scoring_engine.dart`](server/lib/src/ai/lead_scoring_engine.dart), testlari [`ai_lead_scoring_test.dart`](server/test/ai_lead_scoring_test.dart) · Klient: [`b2b/lib/features/ai_crm/`](b2b/lib/features/ai_crm/)

</td>
</tr>
</table>
</td>
</tr>
</table>

---

## Kod xaritasi — tekshiruv zanjiri

| Nima | Qayerda |
|---|---|
| Foto-tekshiruv dvigateli (oʻz, alpha) | [`server/lib/src/ai/readiness_engine.dart`](server/lib/src/ai/readiness_engine.dart) |
| Tekshiruv testlari | [`server/test/ai_readiness_engine_test.dart`](server/test/ai_readiness_engine_test.dart) |
| PostgreSQL'dagi verdikt sxemasi | [`server/migrations/0019_ai.sql`](server/migrations/0019_ai.sql) |
| A→B vendor-chaqiruvlar audit izi | [`server/migrations/0020_site_photo_cycles.sql`](server/migrations/0020_site_photo_cycles.sql) |
| Aqlli qidiruv dvigateli (oʻz, live) | [`server/lib/src/ai/smart_search_engine.dart`](server/lib/src/ai/smart_search_engine.dart) |
| CRM lidlarini baholash dvigateli (oʻz, live) | [`server/lib/src/ai/lead_scoring_engine.dart`](server/lib/src/ai/lead_scoring_engine.dart) |
| Qidiruv va CRM testlari | [`ai_smart_search_test.dart`](server/test/ai_smart_search_test.dart), [`ai_lead_scoring_test.dart`](server/test/ai_lead_scoring_test.dart) |
| Barcha AI HTTP marshrutlari | [`server/lib/src/ai/ai_routes.dart`](server/lib/src/ai/ai_routes.dart) |
| GPT-vision overlay (standart holatda yoqilgan) + kutib turgan chat | [`server/lib/src/ai/openai_client.dart`](server/lib/src/ai/openai_client.dart) |
| Yuqoridagi adapter uchun promptlar | [`server/lib/src/ai/prompts.dart`](server/lib/src/ai/prompts.dart) |
| Muhit shabloni — kalitlarsiz | [`server/.env.example`](server/.env.example) |

---

## Monitoring zanjiri: fotosuratdan idoragacha

| Qadam | Bosqich | Holat |
|:---:|---|---|
| 1 | Quruvchi foto-hisoboti — sanalangan, tayyorlik foizi bilan; geobelgi mavjud boʻlsa tekshiriladi, hali majburiy emas (erta test) | **live** |
| 2 | AI foto-tekshiruvi — geobelgi/metama'lumotlar plyus oldingi hisobotlarga nisbatan vizual progress | **alpha** |
| 3 | "Aniqlashtirish talab qilinadi" belgisi — nomuvofiqlikda quruvchi tushuntiradi va qayta suratga oladi | **alpha** |
| 4 | Tizim ogohlantirishi — haqiqiy javob boʻlmasa yoki chetlanish chegaradan oshsa, adminga kritik ogohlantirish boradi | **alpha** |
| 5 | Masʼul idoraga signal | **planned** |
| 6 | Onlayn kuzatish markazi tekshiruv natijalarini koʻradi — [Prezidentning PF-104-son Farmoni](https://lex.uz/ru/docs/8245277), 2026-yil 4-iyun | **planned** |
| 7 | Kartochkadagi natija — monitoring natijasi eʼlon qilinadi va ishonch indeksiga taʼsir qiladi | **planned** |

---

## Xaridor imkoniyatlari

| Imkoniyat | Holat |
|---|---|
| Sotib olish / Ijara / Yangi qurilish filtrlari bilan xarita va qidiruv | **live** |
| Kvartira va ofislar uchun jonli yunit jadvali ("shaxmat taxtasi") | **live** |
| Bir bosishda murojaat: koʻrish, qoʻngʻiroq, ushlab turish, ijara | **live** |
| Sanalangan qurilish foto-hisobotlari lentasi | **live** |
| Ikkita progress chizigʻi va ishonch indeksi | **alpha** |
| Tasdiqlangan hujjatli quruvchi kartochkasi | **live** |
| Ipoteka, muddatli toʻlov va ijara-daromad kalkulyatorlari | **alpha** |
| Sevimlilar, saqlangan qidiruvlar, "Mening murojaatlarim", sharhlar, uch til | **alpha** |
| Narx va qurilish bosqichlari boʻyicha push-bildirishnomalar | **alpha** |
| Ipoteka/kredit uchun bank referali; ovozli moslashtirish (Newo AI) | **planned** |

---

## Biznes imkoniyatlari

| Imkoniyat | Holat |
|---|---|
| Loyihalar, binolar, yunitlar, media kutubxona, reja chizmalari | **live** (takomillashtirilmoqda) |
| Konflikt-xavfsiz tahrirli shaxmat taxtasi muharriri | **live** (takomillashtirilmoqda) |
| Murojaatlar CRM'i: voronka, statuslar, teglar, hodisalar tarixi | **live** |
| Foto-hisobotlar va rejalashtirilgan qurilish grafigini kiritish | **alpha** |
| Analitika: talab, voronka, murojaat konversiyasi | **live** |
| Quruvchini tasdiqlash, loyiha/sharh moderatsiyasi, audit jurnali | **alpha** |
| Ogohlantirishlar, jumladan kritik muddat-chetlanish ogohlantirishlari | **alpha** |
| Bank oʻtkazmasi orqali obuna toʻlovi | **planned** |
| Bank hisobotlari va ipoteka/kredit referal lidlari | **planned** |

---

<p align="center">
  <sub>iBuild · © iBuild</sub>
</p>
