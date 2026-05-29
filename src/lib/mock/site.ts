import {
  GraduationCap,
  Users,
  Trophy,
  Star,
  BrainCircuit,
  Gamepad2,
  MessageSquareText,
  Smartphone,
  ShieldCheck,
  CalendarDays,
  type LucideIcon,
} from "lucide-react";

export const site = {
  name: "Aurora Academy",
  tagline: "Bilimga yangicha qarash",
  phone: "+998 71 200 70 70",
  email: "salom@aurora.uz",
  address: "Toshkent sh., Amir Temur ko'chasi 108",
  hours: "Dush–Shan: 09:00–20:00",
  socials: { telegram: "#", instagram: "#", youtube: "#", facebook: "#" },
};

export const navLinks = [
  { label: "Kurslar", href: "/kurslar" },
  { label: "O'qituvchilar", href: "/oqituvchilar" },
  { label: "Bitiruvchilar", href: "/bitiruvchilar" },
  { label: "Narxlar", href: "/narxlar" },
  { label: "Blog", href: "/blog" },
  { label: "Aloqa", href: "/aloqa" },
];

export interface Stat {
  icon: LucideIcon;
  value: number;
  suffix?: string;
  label: string;
  decimals?: number;
}

export const stats: Stat[] = [
  { icon: Users, value: 12400, suffix: "+", label: "Faol o'quvchilar" },
  { icon: GraduationCap, value: 8600, suffix: "+", label: "Bitiruvchilar" },
  { icon: Trophy, value: 7.5, label: "O'rtacha IELTS bali", decimals: 1 },
  { icon: Star, value: 98, suffix: "%", label: "Mamnunlik darajasi" },
];

export interface Feature {
  icon: LucideIcon;
  title: string;
  text: string;
  gradient: string;
}

export const features: Feature[] = [
  {
    icon: BrainCircuit,
    title: "AI yordamchi",
    text: "Yozma ishlarni avtomatik tekshirish, kuchsiz mavzularni aniqlash va shaxsiy o'quv yo'l xaritasi.",
    gradient: "from-aurora-violet to-aurora-indigo",
  },
  {
    icon: Gamepad2,
    title: "Gamifikatsiya",
    text: "XP ballar, darajalar, medallar va haftalik reyting — o'rganishni o'yinga aylantiramiz.",
    gradient: "from-aurora-pink to-aurora-fuchsia",
  },
  {
    icon: MessageSquareText,
    title: "Jonli aloqa",
    text: "O'qituvchi bilan real-time chat, video darslar va Telegram bot orqali eslatmalar.",
    gradient: "from-aurora-cyan to-aurora-blue",
  },
  {
    icon: CalendarDays,
    title: "Aqlli jadval",
    text: "Davomat, dars eslatmalari va Google Calendar bilan sinxronizatsiya bir joyda.",
    gradient: "from-aurora-blue to-aurora-violet",
  },
  {
    icon: Smartphone,
    title: "Mobil tayyor (PWA)",
    text: "Telefonda ilovadek ishlaydi, offline darslar va push bildirishnomalar.",
    gradient: "from-aurora-fuchsia to-aurora-violet",
  },
  {
    icon: ShieldCheck,
    title: "Xavfsizlik",
    text: "JWT autentifikatsiya, rol asosida ruxsatlar va shifrlangan to'lovlar.",
    gradient: "from-aurora-indigo to-aurora-cyan",
  },
];

export interface FaqItem {
  q: string;
  a: string;
}

export const faq: FaqItem[] = [
  {
    q: "Kurslar qanday formatda o'tadi?",
    a: "Online va offline formatlar mavjud. Har bir dars yozib olinadi, shuning uchun o'tkazib yuborsangiz keyin ko'rishingiz mumkin.",
  },
  {
    q: "To'lovni qanday amalga oshiraman?",
    a: "Payme, Click va Uzum Bank orqali online, yoki markazda naqd to'lash mumkin. Bo'lib to'lash imkoniyati ham bor.",
  },
  {
    q: "Bepul sinov darsi bormi?",
    a: "Ha, har bir kurs uchun bitta bepul demo dars va sinov testidan o'tishingiz mumkin — ro'yxatdan o'tmasdan ham.",
  },
  {
    q: "Sertifikat beriladimi?",
    a: "Kursni muvaffaqiyatli tugatgach avtomatik raqamli sertifikat olasiz va uni ijtimoiy tarmoqlarda ulashishingiz mumkin.",
  },
  {
    q: "Ota-onalar farzandini kuzata oladimi?",
    a: "Albatta. Ota-ona paneli orqali davomat, baholar, to'lovlar va o'qituvchi izohlarini real vaqtda ko'rasiz.",
  },
];

export interface Step {
  number: string;
  title: string;
  text: string;
}

export const steps: Step[] = [
  { number: "01", title: "Ro'yxatdan o'ting", text: "Email yoki Telegram orqali 1 daqiqada hisob yarating." },
  { number: "02", title: "Kursni tanlang", text: "Bepul demo darsdan o'ting va o'zingizga mos kursni toping." },
  { number: "03", title: "O'rganing", text: "Jonli darslar, vazifalar va testlar bilan har kuni o'sing." },
  { number: "04", title: "Sertifikat oling", text: "Maqsadingizga erishing va natijangizni dunyoga ko'rsating." },
];
