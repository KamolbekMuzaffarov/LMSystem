<div align="center">

# Aurora Academy — O'quv Markazi LMS

**IELTS, ingliz tili, dasturlash va dizayn bo'yicha zamonaviy o'quv markazi platformasi**

Jonli darslar, AI yordamchi, sertifikat — barchasi bitta "liquid glass" interfeysda.

![Next.js](https://img.shields.io/badge/Next.js-15-000?logo=nextdotjs)
![React](https://img.shields.io/badge/React-19-149ECA?logo=react)
![TypeScript](https://img.shields.io/badge/TypeScript-5.7-3178C6?logo=typescript)
![Tailwind CSS](https://img.shields.io/badge/Tailwind-3.4-06B6D4?logo=tailwindcss)
![Supabase](https://img.shields.io/badge/Supabase-Postgres-3FCF8E?logo=supabase)

</div>

---

## Loyiha haqida

Aurora Academy — o'quv markazlari uchun to'liq veb-sayt va o'quv boshqaruv tizimi (LMS).
Platforma uch xil rol uchun alohida panellardan iborat: **o'quvchi**, **o'qituvchi** va **administrator**.
Butun interfeys o'zbek tilida, "liquid glass" (suyuq shisha) estetikasi va jonli aurora fon bilan ishlangan.

> **Hozirgi holat:** Frontend mock (namuna) ma'lumotlar bilan to'liq ishlaydi.
> Ma'lumotlar bazasi qatlami (Supabase / PostgreSQL) `supabase/` papkasida tayyor — migratsiyalar,
> seed va RLS siyosatlari bilan. Ilovani jonli bazaga ulash keyingi bosqich.

---

## Asosiy imkoniyatlar

### Ommaviy sayt
- **Landing** — jonli aurora fon, glass kartalar, kurs ko'rgazmasi, bitiruvchilar va sharhlar
- **Kurslar** katalogi va har bir kurs uchun batafsil sahifa
- **Narxlar**, **aloqa**, **blog** va **bitiruvchilar** sahifalari
- **Kirish / ro'yxatdan o'tish** ekranlari

### O'quvchi paneli
- Boshqaruv paneli: KPI kartalar, kurs progressi, bugungi jadval, yutuqlar (gamifikatsiya)
- Kurslarim, vazifalar, testlar, jadval, to'lovlar va profil

### O'qituvchi paneli
- Guruhlar, baholash navbati, davomat, daromad statistikasi
- Vazifalar, testlar, o'quvchilar, jadval va xabarlar (chat)

### Administrator paneli
- Foydalanuvchilar, kurslar, guruhlar, moliya, hisobotlar (grafiklar)
- Kontent (CMS) va tizim sozlamalari

---

## Texnologiyalar

| Qatlam | Texnologiya |
| --- | --- |
| Framework | Next.js 15 (App Router) |
| Til | TypeScript 5.7 |
| UI | React 19, Tailwind CSS 3.4 |
| Animatsiya | Framer Motion 11 |
| Ikonlar | lucide-react |
| Ma'lumotlar bazasi | Supabase (PostgreSQL) — 51 jadval, 114 RLS siyosati, 13 yordamchi funksiya |

---

## Ishga tushirish (local)

Talab: **Node.js 18+** va **npm**.

```bash
# 1) Bog'liqliklarni o'rnatish
npm install

# 2) Dev serverni ishga tushirish
npm run dev
```

So'ngra brauzerda oching: **http://localhost:3000**

Boshqa buyruqlar:

```bash
npm run build   # ishlab chiqarish uchun build
npm run start   # build qilingan ilovani ishga tushirish
npm run lint    # ESLint tekshiruvi
```

---

## Ma'lumotlar bazasi (Supabase)

Baza qatlami `supabase/` papkasida tayyor:

```
supabase/
├── migrations/        # 0001–0008: extensions, sxemalar, RLS, helperlar
├── seed.sql           # namuna ma'lumotlar (idempotent)
├── config.toml        # Supabase loyiha sozlamalari
└── _full_setup.sql    # barcha migratsiya + seed bitta faylda
```

Eng tez yo'l — Supabase dashboard'da **SQL Editor**'ni oching va `supabase/_full_setup.sql`
faylining to'liq mazmunini bir marta ishga tushiring.

> ⚠️ `_full_setup.sql` faqat **bir marta** ishga tushirilishi kerak (migratsiyalar idempotent emas).

Muqobil — Supabase CLI orqali:

```bash
supabase db reset     # local
supabase db push      # hosting
```

---

## Demo hisoblar

Seed barcha demo foydalanuvchilar uchun bitta parol o'rnatadi:

| Rol | Email | Parol |
| --- | --- | --- |
| O'quvchi | `student1@aurora.uz` | `Aurora!2026` |
| O'qituvchi | `teacher1@aurora.uz` | `Aurora!2026` |
| Administrator | `admin@aurora.uz` | `Aurora!2026` |

> Bu **faqat demo** uchun hisoblar. Ishlab chiqarishda albatta o'zgartiring.

---

## Loyiha tuzilishi

```
src/
├── app/                # Next.js App Router sahifalari
│   ├── (site)/         # ommaviy sayt (kurslar, blog, narxlar...)
│   ├── student/        # o'quvchi paneli
│   ├── teacher/        # o'qituvchi paneli
│   └── admin/          # administrator paneli
├── components/
│   ├── ui/             # glass tizim: GlassCard, AuroraBackground, CursorGlow...
│   ├── cards/          # kurs/o'qituvchi kartalari
│   ├── sections/       # landing bo'limlari (Hero...)
│   └── panel/          # panel komponentlari
└── lib/
    ├── mock/           # namuna ma'lumotlar (frontend uchun)
    └── utils.ts        # deterministik formatlovchilar (raqam, narx, sana)
```

---

## Mobil ilova — Hisob (Flutter)

`xona_olchov/` papkasida alohida Flutter ilovasi bor: xona o‘lchamlarini kiritasiz — ilova
chizmasini chizib, yuzasini hisoblaydi va chizmani lokatsiya bilan doimiy saqlaydi.
Batafsil: [`xona_olchov/README.md`](xona_olchov/README.md).
Release APK har bir push’da GitHub Actions orqali yig‘ilib, **Releases** bo‘limiga qo‘yiladi.

---

## Xavfsizlik eslatmalari

- `.env` fayllari `.gitignore`'da — hech qachon repozitoriyga qo'shilmaydi.
- `SUPABASE_SERVICE_ROLE_KEY` faqat **server tomonida** ishlatiladi va RLS'ni chetlab o'tadi —
  uni **hech qachon** brauzerga/klientga oshkor qilmang.
- Integratsiya maxfiy kalitlari Supabase Vault'da saqlanadi (kodga yozilmaydi).
- Demo parol (`Aurora!2026`) faqat namuna; ishlab chiqarishda o'zgartiring.

---

## Litsenziya

Shaxsiy / o'quv loyihasi. Barcha huquqlar muallifga tegishli.
