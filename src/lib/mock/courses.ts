export type CourseLevel = "Boshlang'ich" | "O'rta" | "Yuqori";

export interface CourseModule {
  title: string;
  lessons: string[];
}

export interface Course {
  slug: string;
  title: string;
  category: string;
  level: CourseLevel;
  durationWeeks: number;
  lessonsCount: number;
  price: number;
  oldPrice?: number;
  rating: number;
  reviews: number;
  students: number;
  teacherSlug: string;
  gradient: string; // tailwind gradient classes
  emoji: string;
  short: string;
  description: string;
  highlights: string[];
  modules: CourseModule[];
  popular?: boolean;
}

export const categories = [
  "Barchasi",
  "Ingliz tili",
  "IELTS",
  "Dasturlash",
  "Matematika",
  "Dizayn",
] as const;

export const courses: Course[] = [
  {
    slug: "ielts-intensive",
    title: "IELTS Intensive — 7.0+ kafolat",
    category: "IELTS",
    level: "Yuqori",
    durationWeeks: 12,
    lessonsCount: 72,
    price: 1_490_000,
    oldPrice: 1_900_000,
    rating: 4.9,
    reviews: 312,
    students: 1840,
    teacherSlug: "dilnoza-karimova",
    gradient: "from-aurora-violet via-aurora-indigo to-aurora-blue",
    emoji: "🎯",
    short: "Reading, Listening, Writing, Speaking — to'rt ko'nikma bo'yicha intensiv tayyorgarlik.",
    description:
      "Mock testlar, individual fikr-mulohaza va Writing bo'yicha AI tekshiruvi bilan 12 haftada IELTS 7.0+ ga erishish dasturi. Har hafta jonli mock va speaking sessiyalari.",
    highlights: [
      "Haftada 2 ta to'liq mock test",
      "Writing uchun AI + o'qituvchi tahlili",
      "Speaking partneri va jonli sessiyalar",
      "Shaxsiy o'quv yo'l xaritasi",
    ],
    modules: [
      { title: "Listening strategiyalari", lessons: ["Section 1–2 yondashuv", "Map & diagram", "Multiple choice", "Mock #1"] },
      { title: "Reading texnikasi", lessons: ["Skimming & scanning", "True/False/NG", "Matching headings", "Mock #2"] },
      { title: "Writing Task 1 & 2", lessons: ["Grafik tahlili", "Essay tuzilishi", "Kogerentlik", "AI tekshiruv"] },
      { title: "Speaking", lessons: ["Part 1 ravonlik", "Part 2 cue card", "Part 3 munozara", "Final mock"] },
    ],
    popular: true,
  },
  {
    slug: "general-english-a1-b2",
    title: "General English A1 → B2",
    category: "Ingliz tili",
    level: "Boshlang'ich",
    durationWeeks: 24,
    lessonsCount: 96,
    price: 690_000,
    rating: 4.8,
    reviews: 540,
    students: 3120,
    teacherSlug: "javohir-tursunov",
    gradient: "from-aurora-cyan via-aurora-blue to-aurora-indigo",
    emoji: "💬",
    short: "Noldan ravon suhbatgacha — grammatika, lug'at va jonli amaliyot.",
    description:
      "Communicative metodika asosida nol darajadan B2 gacha. Har darsda speaking amaliyoti, real vaziyatlar va o'yinli mashqlar.",
    highlights: [
      "Communicative metodika",
      "Har darsda speaking",
      "Mobil ilovada mashqlar",
      "Daraja sertifikati",
    ],
    modules: [
      { title: "A1 — Asoslar", lessons: ["Alifbo va talaffuz", "Present Simple", "Oddiy dialoglar", "Lug'at 500"] },
      { title: "A2 — Kundalik nutq", lessons: ["O'tgan zamon", "Kelajak", "Sayohat mavzusi", "Audio amaliyot"] },
      { title: "B1 — Mustaqillik", lessons: ["Perfect zamonlar", "Shartli gaplar", "Munozara", "Insho asoslari"] },
      { title: "B2 — Ravonlik", lessons: ["Murakkab gaplar", "Idioma", "Debat", "Yakuniy test"] },
    ],
    popular: true,
  },
  {
    slug: "frontend-react",
    title: "Frontend Dasturlash — React",
    category: "Dasturlash",
    level: "O'rta",
    durationWeeks: 20,
    lessonsCount: 80,
    price: 1_290_000,
    oldPrice: 1_590_000,
    rating: 4.9,
    reviews: 268,
    students: 1460,
    teacherSlug: "sardor-aliyev",
    gradient: "from-aurora-fuchsia via-aurora-violet to-aurora-indigo",
    emoji: "⚛️",
    short: "HTML, CSS, JavaScript va React bilan zamonaviy interfeyslar qurish.",
    description:
      "Amaliy loyihalar asosida frontend dasturlash. Yakunda real portfolio va deploy qilingan loyihalar. Git, REST API va zamonaviy toollar.",
    highlights: [
      "5+ real loyiha",
      "Git & GitHub amaliyoti",
      "Portfolio yaratish",
      "Ishga joylashuvga ko'maklashish",
    ],
    modules: [
      { title: "Web asoslari", lessons: ["HTML semantika", "CSS Fl/Grid", "Responsive", "Loyiha #1"] },
      { title: "JavaScript", lessons: ["Sintaksis", "DOM", "Async/await", "API bilan ishlash"] },
      { title: "React", lessons: ["Komponentlar", "Hooks", "State boshqaruvi", "Routing"] },
      { title: "Pro daraja", lessons: ["TypeScript", "Tailwind", "Deploy", "Portfolio loyiha"] },
    ],
    popular: true,
  },
  {
    slug: "math-dtm",
    title: "Matematika — DTM tayyorgarlik",
    category: "Matematika",
    level: "O'rta",
    durationWeeks: 16,
    lessonsCount: 64,
    price: 590_000,
    rating: 4.7,
    reviews: 198,
    students: 980,
    teacherSlug: "nodira-yusupova",
    gradient: "from-aurora-blue via-aurora-indigo to-aurora-violet",
    emoji: "📐",
    short: "DTM formatida blok testlar, masala yechish texnikasi va nazorat.",
    description:
      "Oliy o'quv yurtiga kirish uchun matematika. Mavzular bo'yicha bloklar, haftalik testlar va xatolar ustida ishlash.",
    highlights: [
      "DTM formatidagi testlar",
      "Masala yechish texnikasi",
      "Haftalik reyting",
      "Xatolar tahlili",
    ],
    modules: [
      { title: "Algebra", lessons: ["Tenglamalar", "Funksiyalar", "Progressiyalar", "Blok test"] },
      { title: "Geometriya", lessons: ["Planimetriya", "Stereometriya", "Vektorlar", "Blok test"] },
      { title: "Trigonometriya", lessons: ["Asoslar", "Tenglamalar", "Grafiklar", "Blok test"] },
      { title: "Yakuniy", lessons: ["Aralash masalalar", "Vaqt boshqaruvi", "Mock DTM", "Tahlil"] },
    ],
  },
  {
    slug: "ui-ux-design",
    title: "UI/UX Dizayn — Figma'dan portfoliogacha",
    category: "Dizayn",
    level: "Boshlang'ich",
    durationWeeks: 14,
    lessonsCount: 56,
    price: 990_000,
    rating: 4.8,
    reviews: 142,
    students: 720,
    teacherSlug: "kamola-rashidova",
    gradient: "from-aurora-pink via-aurora-fuchsia to-aurora-violet",
    emoji: "🎨",
    short: "Dizayn fikrlash, Figma, prototip va real mahsulot uchun interfeys.",
    description:
      "Foydalanuvchi tadqiqotidan to yuqori sifatli prototipgacha. Figma, dizayn tizimlari va portfolio loyihalari.",
    highlights: [
      "Figma chuqur amaliyot",
      "Dizayn tizimi qurish",
      "3 portfolio keys",
      "Mentor fikr-mulohazasi",
    ],
    modules: [
      { title: "Asoslar", lessons: ["Dizayn fikrlash", "Rang & tipografika", "Grid", "Figma intro"] },
      { title: "Tadqiqot", lessons: ["User persona", "Journey map", "Wireframe", "Usability"] },
      { title: "Interfeys", lessons: ["Komponentlar", "Auto-layout", "Prototip", "Dizayn tizimi"] },
      { title: "Portfolio", lessons: ["Case study", "Behance", "Taqdimot", "Yakuniy loyiha"] },
    ],
  },
  {
    slug: "kids-english",
    title: "Bolalar uchun Ingliz tili (7–12 yosh)",
    category: "Ingliz tili",
    level: "Boshlang'ich",
    durationWeeks: 36,
    lessonsCount: 108,
    price: 550_000,
    rating: 4.9,
    reviews: 410,
    students: 1530,
    teacherSlug: "javohir-tursunov",
    gradient: "from-aurora-cyan via-aurora-violet to-aurora-pink",
    emoji: "🧸",
    short: "O'yin asosida til o'rganish — qo'shiq, hikoya va interaktiv mashqlar.",
    description:
      "Bolalar uchun maxsus o'yinli metodika. Har dars qo'shiq, hikoya va harakatli mashqlar bilan to'la.",
    highlights: [
      "O'yinli metodika",
      "Kichik guruhlar (6–8 bola)",
      "Ota-onaga hisobot",
      "Mavsumiy tadbirlar",
    ],
    modules: [
      { title: "Starter", lessons: ["Salomlashish", "Ranglar", "Raqamlar", "Qo'shiqlar"] },
      { title: "Mover", lessons: ["Oila", "Hayvonlar", "Ovqat", "Hikoyalar"] },
      { title: "Flyer", lessons: ["Maktab", "Sport", "Sayohat", "Loyiha"] },
      { title: "Yakuniy", lessons: ["Mini-spektakl", "Sertifikat", "Konkurs", "Bayram"] },
    ],
  },
];

export function getCourse(slug: string) {
  return courses.find((c) => c.slug === slug);
}
