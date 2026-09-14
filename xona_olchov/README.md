# Hisob — xona o‘lchov ilovasi

Xona o‘lchamlarini kiriting — ilova chizmasini chizib, **yuza** va **perimetr**ni hisoblaydi,
chizmani nom, tavsif va lokatsiya bilan qurilma xotirasida **doimiy** saqlaydi.

## Imkoniyatlar

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
├── core/        geometriya (burchaklar, yuza, perimetr), formatlar, ID
├── data/        SketchStore — faqat qo‘shish/yangilash, o‘chirish yo‘q
├── models/      Wall, RoomSketch, GeoPoint
├── services/    lokatsiya (GPS, geokodlash), Google Maps havola parseri
├── screens/     ro‘yxat, tahrirlash, batafsil, ilova haqida
├── widgets/     SketchPainter (chizma), lokatsiya tanlagich, umumiy UI
└── theme/       ranglar va Material 3 mavzusi
```
