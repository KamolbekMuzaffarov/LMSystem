# Potolok — AI yordamchi serveri (`api/chat.js`)

Hisob ilovasining **Potolok** bo‘limidagi «AI yordamchi» shu funksiya orqali
Claude'ga savol beradi. Funksiya `premium-potolok` (Vercel) loyihasida yashaydi —
xuddi `api/lead.js`, `api/photo.js` kabi.

## Nega ilovaning o‘zida emas?

Claude API kaliti mobil ilovaga qo‘yilsa, uni APK ichidan har kim chiqarib
olishi mumkin. Shuning uchun:

```
Ilova  ──POST /api/chat──▶  Vercel funksiyasi  ──▶  Claude API
                            (kalit shu yerda)
```

Kalit **faqat Vercel env**'da turadi — ilovada ham, bu repozitoriyda ham yo‘q.

## O‘rnatish

1. `api/chat.js` faylini `premium-potolok` loyihasining `api/` papkasiga qo‘ying.
2. `@anthropic-ai/sdk` o‘rnatilgan bo‘lsin. `api/room-ai.js` allaqachon Claude'ni
   ishlatgani uchun, ehtimol, bor. Bo‘lmasa:
   ```bash
   npm install @anthropic-ai/sdk
   ```
3. **API kalitini Chrome orqali oling va Vercel'ga qo‘ying** (kodga yozilmaydi):
   - Chrome'da <https://console.anthropic.com> → **Settings → API Keys** →
     `Create Key` → kalitни nusxa oling (`sk-ant-...`).
   - Chrome'da Vercel → `premium-potolok` → **Settings → Environment Variables**:
     - `ANTHROPIC_API_KEY` = o‘sha kalit. *(Loyihada allaqachon bo‘lishi mumkin —
       `room-ai.js` shuni ishlatadi. Shunda qayta qo‘shish shart emas.)*
     - `ANTHROPIC_MODEL` = ixtiyoriy. Standart `claude-opus-5`. **$5 kreditni
       cho‘zish uchun** `claude-haiku-4-5` qo‘ying — sezilarli arzon.
4. O‘zgarishni push qiling — Vercel o‘zi joylashtiradi.

## Tekshirish

```bash
curl -s https://premium-potolok.vercel.app/api/chat \
  -H 'Content-Type: application/json' \
  -d '{"messages":[{"role":"user","content":"Narxi qancha?"}]}'
# → {"reply":"Narx 6$/m² dan boshlanadi ..."}
```

## Xarajat va xavfsizlik

- Model, `max_tokens` (1024) va tarix uzunligi (oxirgi 20 xabar) cheklangan.
- Bu **ochiq** endpoint — kalit himoyalangan, lekin URL'ni topgan har kim so‘rov
  yubora oladi. $5 kredit tez tugamasligi uchun:
  - `ANTHROPIC_MODEL=claude-haiku-4-5` qo‘ying.
  - Vercel → **Firewall / Rate Limit** orqali IP'ga so‘rovlar sonini cheklang.
- So‘rov cheklovlari va yordamchining vazifasi (system prompt) faylning ichida —
  ilovadan o‘zgartirib bo‘lmaydi.
