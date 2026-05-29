export interface Plan {
  name: string;
  price: number;
  period: string;
  description: string;
  features: string[];
  cta: string;
  popular?: boolean;
  gradient: string;
}

export const plans: Plan[] = [
  {
    name: "Standart",
    price: 690_000,
    period: "oyiga",
    description: "Bitta kurs va asosiy imkoniyatlar bilan boshlang.",
    gradient: "from-aurora-cyan to-aurora-blue",
    cta: "Boshlash",
    features: [
      "1 ta kursga to'liq kirish",
      "Video darslar va materiallar",
      "Vazifa va testlar",
      "Davomat va jadval",
      "Telegram bot eslatmalar",
    ],
  },
  {
    name: "Pro",
    price: 1_290_000,
    period: "oyiga",
    description: "Eng ko'p tanlanadigan — to'liq tajriba va AI yordamchi.",
    gradient: "from-aurora-violet to-aurora-indigo",
    cta: "Pro'ni tanlash",
    popular: true,
    features: [
      "3 ta kursgacha kirish",
      "AI yozma ish tekshiruvi",
      "Jonli mock testlar",
      "Shaxsiy o'quv yo'l xaritasi",
      "Ustuvor qo'llab-quvvatlash",
      "Sertifikat va portfolio",
    ],
  },
  {
    name: "Premium",
    price: 2_490_000,
    period: "oyiga",
    description: "Individual mentor va cheksiz imkoniyatlar.",
    gradient: "from-aurora-pink to-aurora-fuchsia",
    cta: "Bog'lanish",
    features: [
      "Barcha kurslarga cheksiz kirish",
      "Shaxsiy mentor (1:1)",
      "Haftalik individual konsultatsiya",
      "Speaking partneri",
      "Ishga joylashuvga ko'maklashish",
      "Barcha Pro imkoniyatlari",
    ],
  },
];

export const paymentMethods = ["Payme", "Click", "Uzum Bank", "Naqd"];
