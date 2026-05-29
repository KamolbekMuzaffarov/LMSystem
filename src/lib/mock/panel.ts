import {
  LayoutDashboard,
  BookOpen,
  ClipboardList,
  FileCheck2,
  CalendarDays,
  CreditCard,
  Bell,
  User,
  Users,
  GraduationCap,
  BarChart3,
  Settings,
  MessageSquare,
  FolderKanban,
  Wallet,
  Megaphone,
  type LucideIcon,
} from "lucide-react";

export interface NavItem {
  label: string;
  href: string;
  icon: LucideIcon;
  badge?: number;
}

export const studentNav: NavItem[] = [
  { label: "Boshqaruv paneli", href: "/student", icon: LayoutDashboard },
  { label: "Kurslarim", href: "/student/kurslarim", icon: BookOpen },
  { label: "Vazifalar", href: "/student/vazifalar", icon: ClipboardList, badge: 3 },
  { label: "Testlar", href: "/student/testlar", icon: FileCheck2 },
  { label: "Jadval", href: "/student/jadval", icon: CalendarDays },
  { label: "To'lovlar", href: "/student/tolovlar", icon: CreditCard },
  { label: "Profil", href: "/student/profil", icon: User },
];

export const teacherNav: NavItem[] = [
  { label: "Boshqaruv paneli", href: "/teacher", icon: LayoutDashboard },
  { label: "Kurslarim", href: "/teacher/kurslar", icon: BookOpen },
  { label: "Vazifalar", href: "/teacher/vazifalar", icon: ClipboardList, badge: 12 },
  { label: "Testlar", href: "/teacher/testlar", icon: FileCheck2 },
  { label: "O'quvchilar", href: "/teacher/oquvchilar", icon: Users },
  { label: "Jadval", href: "/teacher/jadval", icon: CalendarDays },
  { label: "Xabarlar", href: "/teacher/xabarlar", icon: MessageSquare, badge: 5 },
];

export const adminNav: NavItem[] = [
  { label: "Boshqaruv paneli", href: "/admin", icon: LayoutDashboard },
  { label: "Foydalanuvchilar", href: "/admin/foydalanuvchilar", icon: Users },
  { label: "Kurslar", href: "/admin/kurslar", icon: BookOpen },
  { label: "Guruhlar", href: "/admin/guruhlar", icon: FolderKanban },
  { label: "Moliya", href: "/admin/moliya", icon: Wallet },
  { label: "Hisobotlar", href: "/admin/hisobotlar", icon: BarChart3 },
  { label: "Kontent (CMS)", href: "/admin/kontent", icon: Megaphone },
  { label: "Sozlamalar", href: "/admin/sozlamalar", icon: Settings },
];

/* ---------------- STUDENT ---------------- */
export interface KpiCard {
  icon: LucideIcon;
  label: string;
  value: string;
  trend?: string;
  gradient: string;
}

export const studentKpis: KpiCard[] = [
  { icon: BookOpen, label: "Faol kurslar", value: "3", trend: "+1 bu oy", gradient: "from-aurora-violet to-aurora-indigo" },
  { icon: ClipboardList, label: "Bajarilgan vazifalar", value: "47", trend: "92% o'z vaqtida", gradient: "from-aurora-cyan to-aurora-blue" },
  { icon: FileCheck2, label: "O'rtacha ball", value: "84%", trend: "+6% o'sish", gradient: "from-aurora-pink to-aurora-fuchsia" },
  { icon: GraduationCap, label: "XP ballar", value: "2 340", trend: "Level 7", gradient: "from-aurora-fuchsia to-aurora-violet" },
];

export interface CourseProgress {
  title: string;
  emoji: string;
  gradient: string;
  progress: number;
  nextLesson: string;
}

export const studentCourses: CourseProgress[] = [
  { title: "IELTS Intensive", emoji: "🎯", gradient: "from-aurora-violet to-aurora-blue", progress: 68, nextLesson: "Writing Task 2 — Coherence" },
  { title: "General English B2", emoji: "💬", gradient: "from-aurora-cyan to-aurora-indigo", progress: 41, nextLesson: "Conditionals (Type 3)" },
  { title: "Frontend — React", emoji: "⚛️", gradient: "from-aurora-fuchsia to-aurora-violet", progress: 23, nextLesson: "useState va useEffect" },
];

export interface Assignment {
  title: string;
  course: string;
  due: string;
  status: "Kutilmoqda" | "Tekshirilmoqda" | "Baholandi";
  score?: string;
}

export const studentAssignments: Assignment[] = [
  { title: "Essay: Technology in education", course: "IELTS Intensive", due: "Ertaga, 18:00", status: "Kutilmoqda" },
  { title: "Grammar worksheet — Unit 7", course: "General English", due: "29-may", status: "Tekshirilmoqda" },
  { title: "To-do List ilovasi", course: "Frontend — React", due: "26-may", status: "Baholandi", score: "9/10" },
  { title: "Listening practice #4", course: "IELTS Intensive", due: "25-may", status: "Baholandi", score: "8.5/9" },
];

export interface ScheduleItem {
  time: string;
  title: string;
  teacher: string;
  mode: "Online" | "Offline";
  gradient: string;
}

export const todaySchedule: ScheduleItem[] = [
  { time: "10:00", title: "IELTS Speaking Club", teacher: "Dilnoza Karimova", mode: "Offline", gradient: "from-aurora-violet to-aurora-pink" },
  { time: "14:30", title: "React Hooks chuqur", teacher: "Sardor Aliyev", mode: "Online", gradient: "from-aurora-fuchsia to-aurora-violet" },
  { time: "18:00", title: "General English B2", teacher: "Javohir Tursunov", mode: "Offline", gradient: "from-aurora-cyan to-aurora-indigo" },
];

export const achievements = [
  { emoji: "🔥", label: "12 kunlik streak" },
  { emoji: "🎯", label: "Mock 7.0+" },
  { emoji: "⚡", label: "Tezkor javob" },
  { emoji: "📚", label: "50 dars" },
  { emoji: "🏆", label: "Top 10 reyting" },
];

/* ---------------- TEACHER ---------------- */
export const teacherKpis: KpiCard[] = [
  { icon: Users, label: "Faol o'quvchilar", value: "128", trend: "4 ta guruh", gradient: "from-aurora-violet to-aurora-indigo" },
  { icon: ClipboardList, label: "Tekshirilmagan", value: "12", trend: "Bugun topshirilgan", gradient: "from-aurora-pink to-aurora-fuchsia" },
  { icon: CalendarDays, label: "Bugungi darslar", value: "5", trend: "Keyingisi 14:30", gradient: "from-aurora-cyan to-aurora-blue" },
  { icon: Wallet, label: "Oylik daromad", value: "18.4 mln", trend: "+12% o'sish", gradient: "from-aurora-fuchsia to-aurora-violet" },
];

export interface GroupRow {
  name: string;
  course: string;
  students: number;
  attendance: number;
  avgScore: number;
  gradient: string;
}

export const teacherGroups: GroupRow[] = [
  { name: "IELTS-A1", course: "IELTS Intensive", students: 14, attendance: 96, avgScore: 7.2, gradient: "from-aurora-violet to-aurora-blue" },
  { name: "IELTS-B2", course: "IELTS Intensive", students: 16, attendance: 91, avgScore: 6.8, gradient: "from-aurora-pink to-aurora-violet" },
  { name: "GE-Eve", course: "General English", students: 18, attendance: 88, avgScore: 78, gradient: "from-aurora-cyan to-aurora-indigo" },
  { name: "Kids-Sat", course: "Kids English", students: 8, attendance: 99, avgScore: 92, gradient: "from-aurora-fuchsia to-aurora-pink" },
];

export interface GradingRow {
  student: string;
  initials: string;
  gradient: string;
  task: string;
  submitted: string;
}

export const gradingQueue: GradingRow[] = [
  { student: "Kamolbek Muzaffarov", initials: "KM", gradient: "from-aurora-violet to-aurora-blue", task: "Essay: Technology", submitted: "2 soat oldin" },
  { student: "Bekzod Olimov", initials: "BO", gradient: "from-aurora-fuchsia to-aurora-violet", task: "Listening #4", submitted: "3 soat oldin" },
  { student: "Madina Saidova", initials: "MS", gradient: "from-aurora-pink to-aurora-cyan", task: "Speaking record", submitted: "5 soat oldin" },
  { student: "Jasur Komilov", initials: "JK", gradient: "from-aurora-cyan to-aurora-indigo", task: "Writing Task 1", submitted: "Kecha" },
];

/* ---------------- ADMIN ---------------- */
export const adminKpis: KpiCard[] = [
  { icon: Users, label: "Jami o'quvchilar", value: "12 480", trend: "+340 bu oy", gradient: "from-aurora-violet to-aurora-indigo" },
  { icon: Wallet, label: "Oylik daromad", value: "1.24 mlrd", trend: "+18% o'sish", gradient: "from-aurora-cyan to-aurora-blue" },
  { icon: GraduationCap, label: "Faol o'qituvchilar", value: "64", trend: "5 ta yangi", gradient: "from-aurora-pink to-aurora-fuchsia" },
  { icon: BookOpen, label: "Faol kurslar", value: "38", trend: "98% to'ldirilgan", gradient: "from-aurora-fuchsia to-aurora-violet" },
];

// monthly revenue (mln so'm) for a simple bar chart
export const revenueData = [
  { month: "Yan", value: 820 },
  { month: "Fev", value: 910 },
  { month: "Mar", value: 880 },
  { month: "Apr", value: 1040 },
  { month: "May", value: 1180 },
  { month: "Iyun", value: 1240 },
];

export interface Application {
  name: string;
  initials: string;
  gradient: string;
  course: string;
  time: string;
  status: "Yangi" | "Ko'rildi" | "Qabul";
}

export const applications: Application[] = [
  { name: "Sevinch Abdullayeva", initials: "SA", gradient: "from-aurora-violet to-aurora-pink", course: "IELTS Intensive", time: "5 daqiqa oldin", status: "Yangi" },
  { name: "Doston Kamolov", initials: "DK", gradient: "from-aurora-cyan to-aurora-blue", course: "Frontend — React", time: "20 daqiqa oldin", status: "Yangi" },
  { name: "Malika Yusupova", initials: "MY", gradient: "from-aurora-pink to-aurora-fuchsia", course: "UI/UX Dizayn", time: "1 soat oldin", status: "Ko'rildi" },
  { name: "Akmal To'rayev", initials: "AT", gradient: "from-aurora-blue to-aurora-indigo", course: "DTM Matematika", time: "2 soat oldin", status: "Qabul" },
];

export const notificationsFeed = [
  { icon: Bell, text: "Yangi vazifa: Essay — Technology in education", time: "10 daqiqa oldin" },
  { icon: FileCheck2, text: "Listening #4 baholandi: 8.5/9", time: "2 soat oldin" },
  { icon: CreditCard, text: "Iyun oyi to'lovi muvaffaqiyatli amalga oshirildi", time: "Kecha" },
  { icon: GraduationCap, text: "Tabriklaymiz! 12 kunlik streak", time: "Kecha" },
];
