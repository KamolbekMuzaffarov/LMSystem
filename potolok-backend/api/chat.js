// AI yordamchi — Hisob ilovasining «Potolok» bo'limi shu funksiya orqali
// Claude'ga savol beradi.
//
// MUHIM: Claude API kaliti FAQAT shu serverda (Vercel env) turadi.
// Ilova bu funksiyaga murojaat qiladi, funksiya esa Claude'ga — shuning uchun
// kalit hech qachon ilovada yoki telefonida bo'lmaydi.
//
// O'rnatish:
//   1. Bu faylni premium-potolok loyihasining `api/` papkasiga qo'ying.
//   2. `@anthropic-ai/sdk` o'rnatilgan bo'lsin (room-ai.js allaqachon ishlatadi;
//      bo'lmasa: npm install @anthropic-ai/sdk).
//   3. Vercel → Settings → Environment Variables:
//        ANTHROPIC_API_KEY  — Claude kaliti (allaqachon bor bo'lishi mumkin).
//        ANTHROPIC_MODEL    — ixtiyoriy. Standart: claude-opus-5.
//                             $5 kreditni cho'zish uchun: claude-haiku-4-5.
//   4. Push qiling — Vercel o'zi joylashtiradi.

import Anthropic from '@anthropic-ai/sdk';

// Kalitni muhitdan oladi (ANTHROPIC_API_KEY). Kodga yozilmaydi.
const client = new Anthropic();

// Standart model — opus-5. Arzonroq variant uchun ANTHROPIC_MODEL=claude-haiku-4-5.
const MODEL = process.env.ANTHROPIC_MODEL || 'claude-opus-5';

// Cheklovlar — xarajat va suiiste'molga qarshi.
const MAX_TOKENS = 1024; // qisqa javob yetadi
const MAX_MESSAGES = 20; // faqat oxirgi 20 xabar
const MAX_CHARS = 2000; // bitta xabar uzunligi

// Yordamchining vazifasi va faktlari — server tomonida turadi, shuning uchun
// ilovadan uni o'zgartirib bo'lmaydi.
const SYSTEM = [
  'Sen "НАТЯЖНОЙ ПОТОЛОК" (natyajnoy potolok — taranglashgan shift) xizmatining',
  'yordamchisisan. Buxoro va Navoiy shaharlarida ishlaymiz.',
  '',
  'Vazifang — mijozlarning savollariga O‘ZBEK TILIDA qisqa (2–5 jumla),',
  'samimiy va aniq javob berish.',
  '',
  'Faktlar:',
  '- 15 yillik yozma kafolat, 10+ yil tajriba.',
  '- Narx eng past 6$/m² dan boshlanadi — hammasi ichida (material, profil,',
  '  o‘rnatish). Aniq summani faqat o‘lchovdan keyin usta aytadi.',
  '- Bir kunda o‘rnatiladi, chang deyarli chiqmaydi, mebelni chiqarish shart emas.',
  '- Turlari: glyanets, mat, satin, foto-chop, ko‘p darajali, yulduzli osmon.',
  '- Telegram: @NATYAJN0Y. Ariza boti: @premium_potolok_ariza_bot.',
  '',
  'Qoidalar:',
  '- HAR DOIM o‘zbekcha javob ber.',
  '- YUQORI narxlarni (masalan 10$/m² va undan ortiq) hech qachon raqam bilan',
  '  aytma. Murakkab ish so‘ralsa: "buni o‘lchovda usta aniq hisoblab beradi" de',
  '  va bepul o‘lchovga yozilishni yoki qo‘ng‘iroqni taklif qil.',
  '- Aniq narx yoki hisob so‘ralsa: "6$/m² dan" taxminini ayt, keyin bepul',
  '  o‘lchovga yozilishni taklif qil.',
  '- Bilmagan narsangni o‘ylab topma — "buni usta aniq aytadi" de.',
  '- Emoji ishlatma.',
  '- Mavzudan tashqari savolga xushmuomala qisqa javob ber, keyin potolok',
  '  mavzusiga qaytar.',
].join('\n');

export default async function handler(req, res) {
  // Brauzerdan ham chaqirilishi mumkin (ixtiyoriy).
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  if (req.method === 'OPTIONS') return res.status(204).end();
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Faqat POST' });
  }

  try {
    const body =
      typeof req.body === 'string' ? JSON.parse(req.body || '{}') : req.body || {};
    const incoming = Array.isArray(body.messages) ? body.messages : null;
    if (!incoming || incoming.length === 0) {
      return res.status(400).json({ error: 'messages kerak' });
    }

    // Faqat to'g'ri xabarlarni qoldiramiz va uzunligini cheklaymiz.
    const messages = incoming
      .filter(
        (m) =>
          m &&
          (m.role === 'user' || m.role === 'assistant') &&
          typeof m.content === 'string' &&
          m.content.trim().length > 0,
      )
      .slice(-MAX_MESSAGES)
      .map((m) => ({ role: m.role, content: m.content.slice(0, MAX_CHARS) }));

    if (messages.length === 0 || messages[messages.length - 1].role !== 'user') {
      return res.status(400).json({ error: 'oxirgi xabar user bo‘lishi kerak' });
    }

    const params = {
      model: MODEL,
      max_tokens: MAX_TOKENS,
      system: SYSTEM,
      messages,
    };
    // effort Haiku'da qo'llab-quvvatlanmaydi — faqat boshqa modellarga qo'yamiz.
    if (!/haiku/i.test(MODEL)) {
      params.output_config = { effort: 'low' };
    }

    const response = await client.messages.create(params);

    if (response.stop_reason === 'refusal') {
      return res.status(200).json({
        reply:
          'Bu savolga javob bera olmadim. Iltimos, potolok haqida so‘rang yoki '
          + 'qo‘ng‘iroq qiling.',
      });
    }

    const reply = (response.content || [])
      .filter((b) => b.type === 'text')
      .map((b) => b.text)
      .join('')
      .trim();

    return res
      .status(200)
      .json({ reply: reply || 'Kechirasiz, javob topa olmadim.' });
  } catch (err) {
    const status = err && err.status;
    if (status === 429) {
      return res.status(429).json({ error: 'Yordamchi hozir band — birozdan so‘ng urining' });
    }
    if (status === 401) {
      // Kalit noto'g'ri/yo'q — buni mijozga ko'rsatmaymiz, logga yozamiz.
      console.error('ANTHROPIC_API_KEY xato yoki yo‘q');
      return res.status(502).json({ error: 'AI yordamchi sozlanmagan' });
    }
    console.error('chat xato:', err);
    return res.status(502).json({ error: 'AI yordamchi vaqtincha ishlamayapti' });
  }
}
