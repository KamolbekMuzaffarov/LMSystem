export interface Teacher {
  slug: string;
  name: string;
  initials: string;
  gradient: string;
  role: string;
  experience: string;
  rating: number;
  students: number;
  bio: string;
  badges: string[];
  subjects: string[];
}

export const teachers: Teacher[] = [
  {
    slug: "dilnoza-karimova",
    name: "Dilnoza Karimova",
    initials: "DK",
    gradient: "from-aurora-violet to-aurora-pink",
    role: "IELTS bo'yicha katta o'qituvchi",
    experience: "8 yil tajriba",
    rating: 4.9,
    students: 1840,
    bio: "Cambridge CELTA sertifikatiga ega. O'quvchilarining 92% IELTS 7.0+ ball olgan.",
    badges: ["CELTA", "IELTS 8.5", "Mentor"],
    subjects: ["IELTS", "Academic Writing"],
  },
  {
    slug: "javohir-tursunov",
    name: "Javohir Tursunov",
    initials: "JT",
    gradient: "from-aurora-cyan to-aurora-indigo",
    role: "General English o'qituvchisi",
    experience: "6 yil tajriba",
    rating: 4.8,
    students: 2650,
    bio: "Communicative metodika ustasi. Bolalar va kattalar bilan ishlaydi.",
    badges: ["TKT", "Young Learners"],
    subjects: ["General English", "Kids English"],
  },
  {
    slug: "sardor-aliyev",
    name: "Sardor Aliyev",
    initials: "SA",
    gradient: "from-aurora-fuchsia to-aurora-violet",
    role: "Frontend mentor",
    experience: "7 yil tajriba",
    rating: 4.9,
    students: 1460,
    bio: "Senior Frontend Engineer. Bitiruvchilarining 70% IT kompaniyalarga ishga kirgan.",
    badges: ["React", "TypeScript", "Senior"],
    subjects: ["Frontend", "JavaScript"],
  },
  {
    slug: "nodira-yusupova",
    name: "Nodira Yusupova",
    initials: "NY",
    gradient: "from-aurora-blue to-aurora-cyan",
    role: "Matematika o'qituvchisi",
    experience: "10 yil tajriba",
    rating: 4.7,
    students: 980,
    bio: "DTM tayyorgarlik bo'yicha mutaxassis. Respublika olimpiadasi g'oliblari murabbiysi.",
    badges: ["DTM Pro", "Olimpiada"],
    subjects: ["Matematika", "Algebra"],
  },
  {
    slug: "kamola-rashidova",
    name: "Kamola Rashidova",
    initials: "KR",
    gradient: "from-aurora-pink to-aurora-fuchsia",
    role: "Product dizayner",
    experience: "5 yil tajriba",
    rating: 4.8,
    students: 720,
    bio: "Xalqaro mahsulotlar uchun dizayn qilgan. Figma va dizayn tizimlari ustasi.",
    badges: ["Figma", "UX Research"],
    subjects: ["UI/UX", "Product Design"],
  },
];

export function getTeacher(slug: string) {
  return teachers.find((t) => t.slug === slug);
}

export interface Graduate {
  name: string;
  initials: string;
  gradient: string;
  result: string;
  detail: string;
  company?: string;
  quote: string;
}

export const graduates: Graduate[] = [
  {
    name: "Kamolbek Muzaffarov",
    initials: "KM",
    gradient: "from-aurora-violet to-aurora-blue",
    result: "IELTS 8.0",
    detail: "Mock 6.5 → real 8.0",
    company: "Chevening grant",
    quote: "Writing bo'yicha AI tahlili menga eng ko'p yordam berdi. 3 oyda 1.5 ball o'sdim.",
  },
  {
    name: "Bekzod Olimov",
    initials: "BO",
    gradient: "from-aurora-fuchsia to-aurora-violet",
    result: "Frontend Developer",
    detail: "0 dan ishga joylashdi",
    company: "Uzum Tech",
    quote: "Real loyihalar portfoliomni to'ldirdi. Kursdan keyin 2 oyda ish topdim.",
  },
  {
    name: "Madina Saidova",
    initials: "MS",
    gradient: "from-aurora-pink to-aurora-cyan",
    result: "DTM 189 ball",
    detail: "Matematika 58/60",
    company: "TATU",
    quote: "Blok testlar va xatolar tahlili tufayli o'zimga ishonchim ortdi.",
  },
  {
    name: "Jasur Komilov",
    initials: "JK",
    gradient: "from-aurora-cyan to-aurora-indigo",
    result: "IELTS 7.5",
    detail: "Speaking 8.0",
    company: "Germaniya universiteti",
    quote: "Speaking partneri va jonli sessiyalar ravonligimni butunlay o'zgartirdi.",
  },
  {
    name: "Sevara Tosheva",
    initials: "ST",
    gradient: "from-aurora-violet to-aurora-fuchsia",
    result: "UI/UX Designer",
    detail: "3 ta portfolio loyiha",
    company: "Freelance",
    quote: "Mentor fikr-mulohazasi har bir loyihamni professional darajaga olib chiqdi.",
  },
  {
    name: "Otabek Nazarov",
    initials: "ON",
    gradient: "from-aurora-blue to-aurora-violet",
    result: "B2 → C1",
    detail: "6 oyda 2 daraja",
    company: "Xalqaro kompaniya",
    quote: "Har darsda speaking amaliyoti til to'sig'ini yo'qotdi.",
  },
];

export interface Testimonial {
  name: string;
  initials: string;
  gradient: string;
  role: string;
  text: string;
  rating: number;
}

export const testimonials: Testimonial[] = [
  {
    name: "Dilshod Yo'ldoshev",
    initials: "DY",
    gradient: "from-aurora-violet to-aurora-indigo",
    role: "O'quvchi ota-onasi",
    rating: 5,
    text: "Farzandimning rivojini ilovada kuzatib boraman — har bir baho va davomat ko'rinib turadi. Ajoyib tizim.",
  },
  {
    name: "Gulnoza Aliyeva",
    initials: "GA",
    gradient: "from-aurora-pink to-aurora-violet",
    role: "IELTS o'quvchisi",
    rating: 5,
    text: "Platformaning o'zi shu qadar chiroyliki, har kuni kirgim keladi. Streak tizimi motivatsiya beradi.",
  },
  {
    name: "Rustam Mirzayev",
    initials: "RM",
    gradient: "from-aurora-cyan to-aurora-blue",
    role: "Frontend bitiruvchisi",
    rating: 5,
    text: "O'qituvchi izohlari va kod tekshiruvi haqiqiy ish muhitidagidek. Tavsiya qilaman.",
  },
  {
    name: "Nigora Qodirova",
    initials: "NQ",
    gradient: "from-aurora-fuchsia to-aurora-pink",
    role: "DTM o'quvchisi",
    rating: 5,
    text: "Haftalik reyting va xatolar tahlili qaysi mavzuni mustahkamlashim kerakligini aniq ko'rsatadi.",
  },
];
