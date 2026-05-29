export interface BlogPost {
  slug: string;
  title: string;
  excerpt: string;
  category: string;
  date: string;
  readTime: string;
  author: string;
  gradient: string;
  emoji: string;
}

export const blogPosts: BlogPost[] = [
  {
    slug: "ielts-writing-7",
    title: "IELTS Writing'da 7.0 olishning 5 siri",
    excerpt: "Ko'pchilik Writing'da qiynaladi. Mana shu 5 ta amaliy texnika ballingizni oshiradi.",
    category: "IELTS",
    date: "2026-05-20",
    readTime: "6 daqiqa",
    author: "Dilnoza Karimova",
    gradient: "from-aurora-violet to-aurora-blue",
    emoji: "✍️",
  },
  {
    slug: "frontend-2026",
    title: "2026-yilda Frontend: nimadan boshlash kerak?",
    excerpt: "Yangi boshlovchilar uchun zamonaviy frontend yo'l xaritasi va kerakli ko'nikmalar.",
    category: "Dasturlash",
    date: "2026-05-14",
    readTime: "8 daqiqa",
    author: "Sardor Aliyev",
    gradient: "from-aurora-fuchsia to-aurora-violet",
    emoji: "⚛️",
  },
  {
    slug: "til-organish-motivatsiya",
    title: "Til o'rganishda motivatsiyani qanday saqlash mumkin?",
    excerpt: "Streak, kichik maqsadlar va to'g'ri muhit — barqaror o'rganishning kaliti.",
    category: "Ingliz tili",
    date: "2026-05-08",
    readTime: "5 daqiqa",
    author: "Javohir Tursunov",
    gradient: "from-aurora-cyan to-aurora-indigo",
    emoji: "🔥",
  },
  {
    slug: "dtm-vaqt-boshqaruvi",
    title: "DTM testida vaqtni to'g'ri taqsimlash",
    excerpt: "60 daqiqada 30 ta savol — har bir soniyani qanday ishlatish kerak.",
    category: "Matematika",
    date: "2026-04-29",
    readTime: "4 daqiqa",
    author: "Nodira Yusupova",
    gradient: "from-aurora-blue to-aurora-violet",
    emoji: "⏱️",
  },
  {
    slug: "portfolio-dizayn",
    title: "Kuchli dizayn portfoliosi qanday tuziladi?",
    excerpt: "Case study yozish, loyihalarni taqdim etish va e'tiborni jalb qilish.",
    category: "Dizayn",
    date: "2026-04-22",
    readTime: "7 daqiqa",
    author: "Kamola Rashidova",
    gradient: "from-aurora-pink to-aurora-fuchsia",
    emoji: "🎨",
  },
  {
    slug: "speaking-qorquv",
    title: "Speaking'dan qo'rqishni qanday yengish mumkin?",
    excerpt: "Til to'sig'i — bu psixologik to'siq. Mana uni buzishning amaliy yo'llari.",
    category: "Ingliz tili",
    date: "2026-04-15",
    readTime: "5 daqiqa",
    author: "Dilnoza Karimova",
    gradient: "from-aurora-violet to-aurora-pink",
    emoji: "🗣️",
  },
];
