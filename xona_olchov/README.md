# Hisob — xona o‘lchov ilovasi

Xona o‘lchamlarini kiriting — ilova chizmasini chizib, **yuza** va **perimetr**ni hisoblaydi,
chizmani nom, tavsif va lokatsiya bilan qurilma xotirasida **doimiy** saqlaydi.

Ilovada ikkita bo‘lim bor: **Chizmalar** (o‘lchov va hisob) va **Potolok**
(natyajnoy potolok xizmati — narx, ko‘rgazma va ariza).

## Chizmalar bo‘limi

- **Uch rejim:** to‘rtburchak, trapetsiya (namunadagi kabi) va ko‘p burchakli xona —
  devor-devor kiritiladi, burchaklar soni cheklanmagan (L-shakl, U-shakl shablonlari bor).
- **Chizma:** devor uzunliklari, umumiy o‘lcham strelkasi, `S ≈ … m²` yozuvi, ixtiyoriy burchak
  gradusi; avtomatik yopilgan devor uzuq chiziq bilan ko‘rsatiladi; devorlar kesishsa ogohlantiradi.
  Yozuvlar hech qachon ustma-ust tushmaydi: strelka umumiy o‘lchamni bir marta ko‘rsatadi,
  yuza yozuvi devor yozuvidan keyin turadi, joy tor bo‘lsa shrift avtomatik kichrayadi.
- **Xotira:** `shared_preferences` (JSON + zaxira nusxa). Chizmani **o‘chirish imkoni yo‘q** —
  faqat tahrirlash.
- **Material hisobi:** xona balandligi → devorlar yuzasi, hajm, pol+devor yuzasi; zaxira
  foizi (0/5/10/15%) va “1 quti = N m²” bo‘yicha kerakli quti soni.
- **Ulashish va zaxira:** chizmani PNG rasm qilib yuborish; barcha chizmalarni bitta JSON
  faylga saqlash va undan tiklash (tiklash faqat qo‘shadi, hech narsa o‘chirmaydi);
  chizmadan nusxa olish.
- **Lokatsiya:** internet yoqiq bo‘lsa GPS ruxsati so‘raladi; Google Maps havolasi yoki
  koordinatani qo‘lda kiritish; manzil nomi (teskari geokodlash); xaritada ochish.
- **Dizayn:** namunadagi qorong‘i mavzu (`#151515` fon, `#085041` shakl, `#56BE9B` chegara).

## Potolok bo‘limi

Natyajnoy potolok xizmatining mijozga ko‘rsatiladigan qismi — o‘lchov ilovasi bilan
bitta ilovada.

- **Narx kalkulyatori:** yuzani qo‘lda kiriting yoki **saqlangan chizmadan** oling
  (shift yuzasi pol yuzasiga teng) → `120$ dan ≈ 1 512 000 so‘m`. E‘lon qilinadigan
  narx — faqat eng past daraja: **6 $/m², hammasi ichida**. Yuqori darajalar raqam
  bilan ko‘rsatilmaydi; aniq summa o‘lchovdan keyin, qo‘ng‘iroqda aytiladi.
- **Shift turlari:** glyanets, mat, satin, foto-chop, ko‘p darajali, yulduzli osmon.
  Har biri ilovaning o‘zida chiziladi — internetsiz ham darrov ochiladi.
- **Kafolat va savol-javob:** 15 yil kafolat, 10+ yil tajriba, Buxoro va Navoiy.
- **Ariza (internet orqali):** ism va telefon → `https://premium-potolok.vercel.app/api/lead`.
  Ariza avval xotiraga yoziladi, keyin yuboriladi — internet yo‘q bo‘lsa navbatda qoladi
  va ulanish tiklanganda o‘zi jo‘naydi. Server rad etsa sabab ko‘rsatiladi, zaxira yo‘l
  sifatida matn nusxalanib Telegram bot ochiladi.
- **Aloqa:** qo‘ng‘iroq (raqam sozlamalarda saqlanadi), Telegram kanal va bot, sayt.
- **Arizalarim:** yuborilgan va navbatdagi arizalar tarixi, holati bilan.

Telefon raqami ilovada saqlanadi (repozitoriyda emas): **Aloqa → qalam belgisi**.

## Ishga tushirish

```bash
cd xona_olchov
flutter pub get
flutter run
```

Testlar va tahlil:

```bash
flutter analyze
flutter test
```

## APK

GitHub Actions (`.github/workflows/hisob-apk.yml`) har bir push'da release APK yig‘adi va
uni **Releases** bo‘limiga `Hisob-<versiya>.apk` nomi bilan biriktiradi.
Qo‘lda: `flutter build apk --release` → `build/app/outputs/flutter-apk/app-release.apk`.

> **Imzo kaliti:** `android/app/hisob-release.jks` va `android/key.properties` ataylab
> repozitoriyda — shunda har bir build bir xil imzo bilan chiqadi va ilovani yangilaganda
> saqlangan chizmalar yo‘qolmaydi. Play Store‘ga chiqarishdan oldin yangi, maxfiy kalit
> yarating va uni GitHub Secrets orqali bering.

## Tuzilma

```
lib/
├── core/        geometriya (burchaklar, yuza, perimetr), formatlar, ID, brend
├── data/        SketchStore va PotolokStore — qo‘shish/yangilash, o‘chirish yo‘q
├── models/      Wall, RoomSketch, GeoPoint, Opening, CeilingDesign, Lead
├── services/    lokatsiya, Maps havola parseri, ariza yuborish (HTTP) va navbat
├── screens/     root_shell (ikki bo‘lim), ro‘yxat, tahrirlash, batafsil, potolok/
├── widgets/     SketchPainter, CeilingPreview, lokatsiya tanlagich, umumiy UI
└── theme/       ranglar va Material 3 mavzusi
```
