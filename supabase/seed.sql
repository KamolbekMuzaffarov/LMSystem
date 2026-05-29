-- ============================================================================
-- Aurora Academy LMS  ·  seed.sql
-- ----------------------------------------------------------------------------
-- Reference + demo data that mirrors the app's mock content (src/lib/mock/*).
-- Runs AFTER all migrations (0001–0008). Idempotent: safe to re-run.
--
-- Layout:
--   1. RBAC reference   (roles, permissions, role_permissions)
--   2. Branches & categories
--   3. Plans, levels, achievements, blog categories, settings, integrations
--   4. Demo identities  (auth.users → profiles → roles → teacher/student ext.)
--   5. Courses + modules + lessons
--   6. Groups, enrollments  (delivery)
--   7. Assessment demo  (one assignment, one test with questions)
--   8. Blog posts, announcement, finance demo (discount/invoice/payment)
--
-- Demo accounts: password for ALL seeded users is  Aurora!2026
-- (emails below, e.g. admin@aurora.uz / dilnoza@aurora.uz / student1@aurora.uz)
-- NOTE: section 4 inserts into auth.users — this targets a standard Supabase
-- project. On bare PostgreSQL without GoTrue's auth schema, skip section 4+.
-- ============================================================================

-- Ensure pgcrypto's crypt()/gen_salt() resolve (Supabase installs pgcrypto in
-- the `extensions` schema). Harmless if `extensions` does not exist.
set search_path = public, extensions;

-- ----------------------------------------------------------------------------
-- 1. RBAC reference  ·  8 platform roles
-- ----------------------------------------------------------------------------
insert into public.roles (key, name, description, level, is_staff) values
  ('super_admin', $$Super administrator$$,     $$Platformaning to'liq egasi$$,        100, true),
  ('admin',       $$Administrator$$,            $$Tizimni boshqaruvchi$$,               90, true),
  ('manager',     $$Menejer$$,                  $$O'quv jarayoni va to'lovlar$$,        70, true),
  ('teacher',     $$O'qituvchi$$,               $$Kurs va guruh o'qituvchisi$$,         50, true),
  ('assistant',   $$Yordamchi o'qituvchi$$,     $$O'qituvchiga ko'maklashuvchi$$,       40, true),
  ('student',     $$O'quvchi$$,                 $$Kursga yozilgan o'quvchi$$,           20, false),
  ('parent',      $$Ota-ona$$,                  $$O'quvchining ota-onasi/vasiysi$$,     15, false),
  ('guest',       $$Mehmon$$,                   $$Ro'yxatdan o'tmagan foydalanuvchi$$,   0, false)
on conflict (key) do nothing;

-- fine-grained permissions
insert into public.permissions (key, description) values
  ('course.manage',     $$Kurslarni boshqarish$$),
  ('user.manage',       $$Foydalanuvchilarni boshqarish$$),
  ('enrollment.manage', $$Ro'yxatga olishni boshqarish$$),
  ('grade.manage',      $$Baholarni qo'yish va tahrirlash$$),
  ('payment.manage',    $$To'lovlarni boshqarish$$),
  ('content.publish',   $$Kontent (blog/dars) chop etish$$),
  ('report.view',       $$Hisobotlarni ko'rish$$),
  ('settings.manage',   $$Tizim sozlamalarini boshqarish$$)
on conflict (key) do nothing;

-- super_admin & admin get every permission
insert into public.role_permissions (role_id, permission_id)
select r.id, p.id
from public.roles r cross join public.permissions p
where r.key in ('super_admin', 'admin')
on conflict do nothing;

-- manager: people, enrollments, payments, reports
insert into public.role_permissions (role_id, permission_id)
select r.id, p.id
from public.roles r join public.permissions p
  on p.key in ('user.manage', 'enrollment.manage', 'payment.manage', 'report.view')
where r.key = 'manager'
on conflict do nothing;

-- teacher: grading + publishing lesson content
insert into public.role_permissions (role_id, permission_id)
select r.id, p.id
from public.roles r join public.permissions p
  on p.key in ('grade.manage', 'content.publish')
where r.key = 'teacher'
on conflict do nothing;

-- assistant: grading only
insert into public.role_permissions (role_id, permission_id)
select r.id, p.id
from public.roles r join public.permissions p on p.key = 'grade.manage'
where r.key = 'assistant'
on conflict do nothing;

-- ----------------------------------------------------------------------------
-- 2. Branches & course categories
-- ----------------------------------------------------------------------------
insert into public.branches (name, slug, address, phone, is_active) values
  ($$Aurora Academy — Bosh filial$$, 'bosh-filial', $$Toshkent sh., Amir Temur ko'chasi 108$$, '+998 71 200 70 70', true),
  ($$Aurora Academy — Chilonzor filiali$$, 'chilonzor', $$Toshkent sh., Chilonzor tumani, Bunyodkor shoh ko'chasi$$, '+998 71 200 70 71', true)
on conflict (slug) do nothing;

insert into public.categories (slug, name, position) values
  ('ingliz-tili', $$Ingliz tili$$, 1),
  ('ielts',       $$IELTS$$,       2),
  ('dasturlash',  $$Dasturlash$$,  3),
  ('matematika',  $$Matematika$$,  4),
  ('dizayn',      $$Dizayn$$,      5)
on conflict (slug) do nothing;

-- ----------------------------------------------------------------------------
-- 3. Plans · levels · achievements · blog categories · settings · integrations
-- ----------------------------------------------------------------------------

-- pricing plans (mirrors src/lib/mock/pricing.ts)
insert into public.plans (slug, name, description, price, period, currency, features, cta_label, gradient, max_courses, is_popular, position) values
  ('standart', $$Standart$$, $$Bitta kurs va asosiy imkoniyatlar bilan boshlang.$$,
    690000, 'monthly', 'UZS',
    array[$$1 ta kursga to'liq kirish$$, $$Video darslar va materiallar$$, $$Vazifa va testlar$$, $$Davomat va jadval$$, $$Telegram bot eslatmalar$$],
    $$Boshlash$$, 'from-aurora-cyan to-aurora-blue', 1, false, 0),
  ('pro', $$Pro$$, $$Eng ko'p tanlanadigan — to'liq tajriba va AI yordamchi.$$,
    1290000, 'monthly', 'UZS',
    array[$$3 ta kursgacha kirish$$, $$AI yozma ish tekshiruvi$$, $$Jonli mock testlar$$, $$Shaxsiy o'quv yo'l xaritasi$$, $$Ustuvor qo'llab-quvvatlash$$, $$Sertifikat va portfolio$$],
    $$Pro'ni tanlash$$, 'from-aurora-violet to-aurora-indigo', 3, true, 1),
  ('premium', $$Premium$$, $$Individual mentor va cheksiz imkoniyatlar.$$,
    2490000, 'monthly', 'UZS',
    array[$$Barcha kurslarga cheksiz kirish$$, $$Shaxsiy mentor (1:1)$$, $$Haftalik individual konsultatsiya$$, $$Speaking partneri$$, $$Ishga joylashuvga ko'maklashish$$, $$Barcha Pro imkoniyatlari$$],
    $$Bog'lanish$$, 'from-aurora-pink to-aurora-fuchsia', null, false, 2)
on conflict (slug) do nothing;

-- gamification levels (XP thresholds)
insert into public.levels (level, min_xp, title, badge) values
  (1,     0, $$Yangi boshlovchi$$, '🌱'),
  (2,   100, $$Izlanuvchi$$,        '📘'),
  (3,   300, $$Tirishqoq$$,         '✏️'),
  (4,   600, $$Faol o'quvchi$$,     '🔥'),
  (5,  1000, $$Bilimdon$$,          '⭐'),
  (6,  1600, $$Mohir$$,             '🚀'),
  (7,  2500, $$Ustoz yo'lida$$,     '🏅'),
  (8,  4000, $$Ekspert$$,           '💎'),
  (9,  6000, $$Maven$$,             '👑'),
  (10, 9000, $$Afsona$$,            '🏆')
on conflict (level) do nothing;

-- achievements
insert into public.achievements (code, name, description, icon, category, rarity, xp_reward, coin_reward, criteria, position) values
  ('first-lesson',   $$Birinchi qadam$$,    $$Birinchi darsni yakunlang$$,           '🎯', 'learning',  'common', 20,   5, $${"lessons":1}$$::jsonb,        0),
  ('streak-7',       $$7 kunlik seriya$$,   $$7 kun ketma-ket faol bo'ling$$,        '🔥', 'streak',    'rare',   50,  20, $${"streak":7}$$::jsonb,         1),
  ('streak-30',      $$30 kunlik seriya$$,  $$30 kun ketma-ket faol bo'ling$$,       '🏆', 'streak',    'epic',  200, 100, $${"streak":30}$$::jsonb,        2),
  ('first-test',     $$Sinov topshirildi$$, $$Birinchi testni topshiring$$,          '📝', 'milestone', 'common', 30,  10, $${"tests":1}$$::jsonb,          3),
  ('perfect-score',  $$Mukammal natija$$,   $$Testda 100% to'plang$$,                '💯', 'learning',  'rare',  100,  50, $${"score":100}$$::jsonb,        4),
  ('course-complete',$$Kurs yakunlandi$$,   $$Birinchi kursni to'liq tugating$$,     '🎓', 'milestone', 'epic',  300, 150, $${"course_completed":1}$$::jsonb, 5),
  ('early-bird',     $$Erta qush$$,         $$Darsni belgilangan vaqtdan oldin tugating$$, '🌅', 'special', 'rare', 40, 15, $${}$$::jsonb,                  6),
  ('social-butterfly',$$Faol suhbatdosh$$,  $$Chatda 50 ta xabar yuboring$$,         '💬', 'social',    'common', 25,  10, $${"messages":50}$$::jsonb,      7)
on conflict (code) do nothing;

-- blog categories (mirrors blog post categories)
insert into public.blog_categories (slug, name, position) values
  ('ielts',       $$IELTS$$,       1),
  ('dasturlash',  $$Dasturlash$$,  2),
  ('ingliz-tili', $$Ingliz tili$$, 3),
  ('matematika',  $$Matematika$$,  4),
  ('dizayn',      $$Dizayn$$,      5)
on conflict (slug) do nothing;

-- public + private settings (feature flags folded into group 'features')
insert into public.settings (key, value, group_name, description, is_public) values
  ('site.title',    '"Aurora Academy"'::jsonb,            'general', $$Sayt nomi$$, true),
  ('site.tagline',  '"Bilimga yangicha qarash"'::jsonb,   'general', $$Shior$$, true),
  ('site.contact',  $${"phone":"+998 71 200 70 70","email":"salom@aurora.uz","address":"Toshkent sh., Amir Temur ko'chasi 108","hours":"Dush–Shan: 09:00–20:00"}$$::jsonb, 'general', $$Aloqa ma'lumotlari$$, true),
  ('site.socials',  $${"telegram":"#","instagram":"#","youtube":"#","facebook":"#"}$$::jsonb, 'general', $$Ijtimoiy tarmoqlar$$, true),
  ('general.currency', '"UZS"'::jsonb,                     'general', $$Asosiy valyuta$$, true),
  ('payments.providers', '["payme","click","uzum","cash"]'::jsonb, 'payments', $$Yoqilgan to'lov usullari$$, true),
  ('features.ai_tutor',     'true'::jsonb,  'features', $$AI yordamchi$$, true),
  ('features.gamification', 'true'::jsonb,  'features', $$Gamifikatsiya$$, true),
  ('features.pwa',          'true'::jsonb,  'features', $$PWA / mobil rejim$$, true),
  ('features.live_chat',    'true'::jsonb,  'features', $$Jonli chat$$, true)
on conflict (key) do nothing;

-- third-party integrations (secrets live in Vault, NOT here)
insert into public.integrations (provider, name, status, is_enabled) values
  ('payme',           $$Payme$$,            'disconnected', false),
  ('click',           $$Click$$,            'disconnected', false),
  ('uzum',            $$Uzum Bank$$,        'disconnected', false),
  ('telegram',        $$Telegram bot$$,     'disconnected', false),
  ('zoom',            $$Zoom$$,             'disconnected', false),
  ('google_calendar', $$Google Calendar$$,  'disconnected', false),
  ('sms',             $$SMS shlyuz$$,       'disconnected', false)
on conflict (provider) do nothing;

-- ----------------------------------------------------------------------------
-- 4. Demo identities  ·  auth.users → profiles → roles → role extensions
-- ----------------------------------------------------------------------------
-- Targets a standard Supabase project (GoTrue auth schema). Password for every
-- account below is:  Aurora!2026
-- ----------------------------------------------------------------------------
insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at,
  confirmation_token, recovery_token, email_change, email_change_token_new
)
select
  '00000000-0000-0000-0000-000000000000', u.id, 'authenticated', 'authenticated',
  u.email, crypt('Aurora!2026', gen_salt('bf')), now(),
  '{"provider":"email","providers":["email"]}'::jsonb, u.meta, false, now(), now(),
  '', '', '', ''
from (values
  ('11111111-1111-1111-1111-111111110001'::uuid, 'admin@aurora.uz',     $${"first_name":"Sarvar","last_name":"Aliyev","phone":"+998 90 100 00 01"}$$::jsonb),
  ('11111111-1111-1111-1111-111111110002'::uuid, 'manager@aurora.uz',   $${"first_name":"Malika","last_name":"Yusupova","phone":"+998 90 100 00 02"}$$::jsonb),
  ('11111111-1111-1111-1111-111111110003'::uuid, 'assistant@aurora.uz', $${"first_name":"Jamshid","last_name":"Ortiqov","phone":"+998 90 100 00 03"}$$::jsonb),
  ('22222222-2222-2222-2222-222222220001'::uuid, 'dilnoza@aurora.uz',   $${"first_name":"Dilnoza","last_name":"Karimova","phone":"+998 90 200 00 01"}$$::jsonb),
  ('22222222-2222-2222-2222-222222220002'::uuid, 'javohir@aurora.uz',   $${"first_name":"Javohir","last_name":"Tursunov","phone":"+998 90 200 00 02"}$$::jsonb),
  ('22222222-2222-2222-2222-222222220003'::uuid, 'sardor@aurora.uz',    $${"first_name":"Sardor","last_name":"Aliyev","phone":"+998 90 200 00 03"}$$::jsonb),
  ('22222222-2222-2222-2222-222222220004'::uuid, 'nodira@aurora.uz',    $${"first_name":"Nodira","last_name":"Yusupova","phone":"+998 90 200 00 04"}$$::jsonb),
  ('22222222-2222-2222-2222-222222220005'::uuid, 'kamola@aurora.uz',    $${"first_name":"Kamola","last_name":"Rashidova","phone":"+998 90 200 00 05"}$$::jsonb),
  ('33333333-3333-3333-3333-333333330001'::uuid, 'student1@aurora.uz',  $${"first_name":"Kamolbek","last_name":"Muzaffarov","phone":"+998 90 300 00 01"}$$::jsonb),
  ('33333333-3333-3333-3333-333333330002'::uuid, 'student2@aurora.uz',  $${"first_name":"Bekzod","last_name":"Olimov","phone":"+998 90 300 00 02"}$$::jsonb),
  ('33333333-3333-3333-3333-333333330003'::uuid, 'student3@aurora.uz',  $${"first_name":"Ali","last_name":"Yo'ldoshev","phone":"+998 90 300 00 03"}$$::jsonb),
  ('44444444-4444-4444-4444-444444440001'::uuid, 'parent@aurora.uz',    $${"first_name":"Dilshod","last_name":"Yo'ldoshev","phone":"+998 90 400 00 01"}$$::jsonb)
) as u(id, email, meta)
on conflict (id) do nothing;

-- profiles (the on_auth_user_created trigger may have created bare rows;
-- this upsert enriches them deterministically and is safe either way).
insert into public.profiles (id, email, first_name, last_name, phone, gender, locale, status, branch_id, bio)
select
  v.id, v.email, v.first_name, v.last_name, v.phone, v.gender::gender_type, 'uz', 'active'::user_status,
  (select id from public.branches where slug = 'bosh-filial'), v.bio
from (values
  ('11111111-1111-1111-1111-111111110001'::uuid, 'admin@aurora.uz',     'Sarvar',  'Aliyev',    '+998 90 100 00 01', 'male',   $$Platforma administratori$$),
  ('11111111-1111-1111-1111-111111110002'::uuid, 'manager@aurora.uz',   'Malika',  'Yusupova',  '+998 90 100 00 02', 'female', $$O'quv jarayoni menejeri$$),
  ('11111111-1111-1111-1111-111111110003'::uuid, 'assistant@aurora.uz', 'Jamshid', 'Ortiqov',   '+998 90 100 00 03', 'male',   $$Yordamchi o'qituvchi$$),
  ('22222222-2222-2222-2222-222222220001'::uuid, 'dilnoza@aurora.uz',   'Dilnoza', 'Karimova',  '+998 90 200 00 01', 'female', $$Cambridge CELTA sertifikatiga ega. O'quvchilarining 92% IELTS 7.0+ ball olgan.$$),
  ('22222222-2222-2222-2222-222222220002'::uuid, 'javohir@aurora.uz',   'Javohir', 'Tursunov',  '+998 90 200 00 02', 'male',   $$Communicative metodika ustasi. Bolalar va kattalar bilan ishlaydi.$$),
  ('22222222-2222-2222-2222-222222220003'::uuid, 'sardor@aurora.uz',    'Sardor',  'Aliyev',    '+998 90 200 00 03', 'male',   $$Senior Frontend Engineer. Bitiruvchilarining 70% IT kompaniyalarga ishga kirgan.$$),
  ('22222222-2222-2222-2222-222222220004'::uuid, 'nodira@aurora.uz',    'Nodira',  'Yusupova',  '+998 90 200 00 04', 'female', $$DTM tayyorgarlik bo'yicha mutaxassis. Olimpiada g'oliblari murabbiysi.$$),
  ('22222222-2222-2222-2222-222222220005'::uuid, 'kamola@aurora.uz',    'Kamola',  'Rashidova', '+998 90 200 00 05', 'female', $$Xalqaro mahsulotlar uchun dizayn qilgan. Figma va dizayn tizimlari ustasi.$$),
  ('33333333-3333-3333-3333-333333330001'::uuid, 'student1@aurora.uz',  'Kamolbek', 'Muzaffarov', '+998 90 300 00 01', 'male', null),
  ('33333333-3333-3333-3333-333333330002'::uuid, 'student2@aurora.uz',  'Bekzod',  'Olimov',    '+998 90 300 00 02', 'male',   null),
  ('33333333-3333-3333-3333-333333330003'::uuid, 'student3@aurora.uz',  'Ali',     'Yo''ldoshev','+998 90 300 00 03','male',   null),
  ('44444444-4444-4444-4444-444444440001'::uuid, 'parent@aurora.uz',    'Dilshod', 'Yo''ldoshev','+998 90 400 00 01','male',   $$O'quvchi ota-onasi$$)
) as v(id, email, first_name, last_name, phone, gender, bio)
on conflict (id) do update set
  email      = excluded.email,
  first_name = excluded.first_name,
  last_name  = excluded.last_name,
  phone      = excluded.phone,
  gender     = excluded.gender,
  status     = excluded.status,
  branch_id  = excluded.branch_id,
  bio        = excluded.bio;

-- role assignments
insert into public.user_roles (user_id, role_id)
select v.uid, r.id
from (values
  ('11111111-1111-1111-1111-111111110001'::uuid, 'super_admin'),
  ('11111111-1111-1111-1111-111111110002'::uuid, 'manager'),
  ('11111111-1111-1111-1111-111111110003'::uuid, 'assistant'),
  ('22222222-2222-2222-2222-222222220001'::uuid, 'teacher'),
  ('22222222-2222-2222-2222-222222220002'::uuid, 'teacher'),
  ('22222222-2222-2222-2222-222222220003'::uuid, 'teacher'),
  ('22222222-2222-2222-2222-222222220004'::uuid, 'teacher'),
  ('22222222-2222-2222-2222-222222220005'::uuid, 'teacher'),
  ('33333333-3333-3333-3333-333333330001'::uuid, 'student'),
  ('33333333-3333-3333-3333-333333330002'::uuid, 'student'),
  ('33333333-3333-3333-3333-333333330003'::uuid, 'student'),
  ('44444444-4444-4444-4444-444444440001'::uuid, 'parent')
) as v(uid, rkey)
join public.roles r on r.key = v.rkey
on conflict (user_id, role_id) do nothing;

-- teacher directory (mirrors src/lib/mock/people.ts)
insert into public.teacher_profiles (user_id, slug, headline, bio, experience_years, rating, students_count, badges, subjects, is_featured, hired_at)
values
  ('22222222-2222-2222-2222-222222220001'::uuid, 'dilnoza-karimova',  $$IELTS bo'yicha katta o'qituvchi$$, $$Cambridge CELTA sertifikatiga ega. O'quvchilarining 92% IELTS 7.0+ ball olgan.$$, 8, 4.9, 1840, array[$$CELTA$$,$$IELTS 8.5$$,$$Mentor$$], array[$$IELTS$$,$$Academic Writing$$], true,  date '2018-09-01'),
  ('22222222-2222-2222-2222-222222220002'::uuid, 'javohir-tursunov',  $$General English o'qituvchisi$$,    $$Communicative metodika ustasi. Bolalar va kattalar bilan ishlaydi.$$, 6, 4.8, 2650, array[$$TKT$$,$$Young Learners$$], array[$$General English$$,$$Kids English$$], true,  date '2020-02-01'),
  ('22222222-2222-2222-2222-222222220003'::uuid, 'sardor-aliyev',     $$Frontend mentor$$,                 $$Senior Frontend Engineer. Bitiruvchilarining 70% IT kompaniyalarga ishga kirgan.$$, 7, 4.9, 1460, array[$$React$$,$$TypeScript$$,$$Senior$$], array[$$Frontend$$,$$JavaScript$$], true,  date '2019-06-01'),
  ('22222222-2222-2222-2222-222222220004'::uuid, 'nodira-yusupova',   $$Matematika o'qituvchisi$$,         $$DTM tayyorgarlik bo'yicha mutaxassis. Respublika olimpiadasi g'oliblari murabbiysi.$$, 10, 4.7, 980, array[$$DTM Pro$$,$$Olimpiada$$], array[$$Matematika$$,$$Algebra$$], false, date '2016-09-01'),
  ('22222222-2222-2222-2222-222222220005'::uuid, 'kamola-rashidova',  $$Product dizayner$$,                $$Xalqaro mahsulotlar uchun dizayn qilgan. Figma va dizayn tizimlari ustasi.$$, 5, 4.8, 720, array[$$Figma$$,$$UX Research$$], array[$$UI/UX$$,$$Product Design$$], false, date '2021-03-01')
on conflict (user_id) do update set
  headline = excluded.headline, bio = excluded.bio, experience_years = excluded.experience_years,
  rating = excluded.rating, students_count = excluded.students_count, badges = excluded.badges,
  subjects = excluded.subjects, is_featured = excluded.is_featured;

-- student gamification state
insert into public.student_profiles (user_id, student_code, level, xp, coins, current_streak, longest_streak, enrolled_at)
values
  ('33333333-3333-3333-3333-333333330001'::uuid, 'AA-2026-0001', 5, 1180, 240, 7, 21, date '2026-01-15'),
  ('33333333-3333-3333-3333-333333330002'::uuid, 'AA-2026-0002', 3,  420,  90, 3, 12, date '2026-02-01'),
  ('33333333-3333-3333-3333-333333330003'::uuid, 'AA-2026-0003', 2,  160,  40, 1,  5, date '2026-03-10')
on conflict (user_id) do update set
  level = excluded.level, xp = excluded.xp, coins = excluded.coins,
  current_streak = excluded.current_streak, longest_streak = excluded.longest_streak;

-- guardianship: parent → kid student
insert into public.guardianships (student_id, guardian_id, relation, is_primary)
values ('33333333-3333-3333-3333-333333330003'::uuid, '44444444-4444-4444-4444-444444440001'::uuid, 'father', true)
on conflict (student_id, guardian_id) do nothing;

-- ----------------------------------------------------------------------------
-- 5. Courses + modules + lessons  (mirrors src/lib/mock/courses.ts)
-- ----------------------------------------------------------------------------
insert into public.courses
  (slug, title, subtitle, description, category_id, level, language, duration_weeks,
   lessons_count, price, old_price, currency, rating, reviews_count, students_count,
   teacher_id, cover_gradient, cover_emoji, highlights, status, is_popular, published_at, created_by)
values
  ('ielts-intensive', $$IELTS Intensive — 7.0+ kafolat$$,
   $$Reading, Listening, Writing, Speaking — to'rt ko'nikma bo'yicha intensiv tayyorgarlik.$$,
   $$Mock testlar, individual fikr-mulohaza va Writing bo'yicha AI tekshiruvi bilan 12 haftada IELTS 7.0+ ga erishish dasturi. Har hafta jonli mock va speaking sessiyalari.$$,
   (select id from public.categories where slug='ielts'), 'advanced', 'uz', 12, 72,
   1490000, 1900000, 'UZS', 4.9, 312, 1840,
   (select user_id from public.teacher_profiles where slug='dilnoza-karimova'),
   'from-aurora-violet via-aurora-indigo to-aurora-blue', '🎯',
   array[$$Haftada 2 ta to'liq mock test$$, $$Writing uchun AI + o'qituvchi tahlili$$, $$Speaking partneri va jonli sessiyalar$$, $$Shaxsiy o'quv yo'l xaritasi$$],
   'published', true, now() - interval '90 days', '11111111-1111-1111-1111-111111110001'),

  ('general-english-a1-b2', $$General English A1 → B2$$,
   $$Noldan ravon suhbatgacha — grammatika, lug'at va jonli amaliyot.$$,
   $$Communicative metodika asosida nol darajadan B2 gacha. Har darsda speaking amaliyoti, real vaziyatlar va o'yinli mashqlar.$$,
   (select id from public.categories where slug='ingliz-tili'), 'beginner', 'uz', 24, 96,
   690000, null, 'UZS', 4.8, 540, 3120,
   (select user_id from public.teacher_profiles where slug='javohir-tursunov'),
   'from-aurora-cyan via-aurora-blue to-aurora-indigo', '💬',
   array[$$Communicative metodika$$, $$Har darsda speaking$$, $$Mobil ilovada mashqlar$$, $$Daraja sertifikati$$],
   'published', true, now() - interval '120 days', '11111111-1111-1111-1111-111111110001'),

  ('frontend-react', $$Frontend Dasturlash — React$$,
   $$HTML, CSS, JavaScript va React bilan zamonaviy interfeyslar qurish.$$,
   $$Amaliy loyihalar asosida frontend dasturlash. Yakunda real portfolio va deploy qilingan loyihalar. Git, REST API va zamonaviy toollar.$$,
   (select id from public.categories where slug='dasturlash'), 'intermediate', 'uz', 20, 80,
   1290000, 1590000, 'UZS', 4.9, 268, 1460,
   (select user_id from public.teacher_profiles where slug='sardor-aliyev'),
   'from-aurora-fuchsia via-aurora-violet to-aurora-indigo', '⚛️',
   array[$$5+ real loyiha$$, $$Git & GitHub amaliyoti$$, $$Portfolio yaratish$$, $$Ishga joylashuvga ko'maklashish$$],
   'published', true, now() - interval '75 days', '11111111-1111-1111-1111-111111110001'),

  ('math-dtm', $$Matematika — DTM tayyorgarlik$$,
   $$DTM formatida blok testlar, masala yechish texnikasi va nazorat.$$,
   $$Oliy o'quv yurtiga kirish uchun matematika. Mavzular bo'yicha bloklar, haftalik testlar va xatolar ustida ishlash.$$,
   (select id from public.categories where slug='matematika'), 'intermediate', 'uz', 16, 64,
   590000, null, 'UZS', 4.7, 198, 980,
   (select user_id from public.teacher_profiles where slug='nodira-yusupova'),
   'from-aurora-blue via-aurora-indigo to-aurora-violet', '📐',
   array[$$DTM formatidagi testlar$$, $$Masala yechish texnikasi$$, $$Haftalik reyting$$, $$Xatolar tahlili$$],
   'published', false, now() - interval '60 days', '11111111-1111-1111-1111-111111110001'),

  ('ui-ux-design', $$UI/UX Dizayn — Figma'dan portfoliogacha$$,
   $$Dizayn fikrlash, Figma, prototip va real mahsulot uchun interfeys.$$,
   $$Foydalanuvchi tadqiqotidan to yuqori sifatli prototipgacha. Figma, dizayn tizimlari va portfolio loyihalari.$$,
   (select id from public.categories where slug='dizayn'), 'beginner', 'uz', 14, 56,
   990000, null, 'UZS', 4.8, 142, 720,
   (select user_id from public.teacher_profiles where slug='kamola-rashidova'),
   'from-aurora-pink via-aurora-fuchsia to-aurora-violet', '🎨',
   array[$$Figma chuqur amaliyot$$, $$Dizayn tizimi qurish$$, $$3 portfolio keys$$, $$Mentor fikr-mulohazasi$$],
   'published', false, now() - interval '45 days', '11111111-1111-1111-1111-111111110001'),

  ('kids-english', $$Bolalar uchun Ingliz tili (7–12 yosh)$$,
   $$O'yin asosida til o'rganish — qo'shiq, hikoya va interaktiv mashqlar.$$,
   $$Bolalar uchun maxsus o'yinli metodika. Har dars qo'shiq, hikoya va harakatli mashqlar bilan to'la.$$,
   (select id from public.categories where slug='ingliz-tili'), 'beginner', 'uz', 36, 108,
   550000, null, 'UZS', 4.9, 410, 1530,
   (select user_id from public.teacher_profiles where slug='javohir-tursunov'),
   'from-aurora-cyan via-aurora-violet to-aurora-pink', '🧸',
   array[$$O'yinli metodika$$, $$Kichik guruhlar (6–8 bola)$$, $$Ota-onaga hisobot$$, $$Mavsumiy tadbirlar$$],
   'published', false, now() - interval '30 days', '11111111-1111-1111-1111-111111110001')
on conflict (slug) do update set
  title = excluded.title, subtitle = excluded.subtitle, description = excluded.description,
  category_id = excluded.category_id, level = excluded.level, price = excluded.price,
  old_price = excluded.old_price, rating = excluded.rating, reviews_count = excluded.reviews_count,
  students_count = excluded.students_count, teacher_id = excluded.teacher_id,
  cover_gradient = excluded.cover_gradient, cover_emoji = excluded.cover_emoji,
  highlights = excluded.highlights, status = excluded.status, is_popular = excluded.is_popular;

-- modules + lessons: built from a JSONB tree (dollar-quoted to avoid escaping).
-- First lesson of the first module of each course is marked as a free preview.
do $$
declare
  v_course   jsonb;
  v_module   jsonb;
  v_lesson   text;
  v_course_id uuid;
  v_module_id uuid;
  v_mpos int;
  v_lpos int;
  v_tree jsonb := $json$
  [
    {"slug":"ielts-intensive","modules":[
      {"title":"Listening strategiyalari","lessons":["Section 1–2 yondashuv","Map & diagram","Multiple choice","Mock #1"]},
      {"title":"Reading texnikasi","lessons":["Skimming & scanning","True/False/NG","Matching headings","Mock #2"]},
      {"title":"Writing Task 1 & 2","lessons":["Grafik tahlili","Essay tuzilishi","Kogerentlik","AI tekshiruv"]},
      {"title":"Speaking","lessons":["Part 1 ravonlik","Part 2 cue card","Part 3 munozara","Final mock"]}
    ]},
    {"slug":"general-english-a1-b2","modules":[
      {"title":"A1 — Asoslar","lessons":["Alifbo va talaffuz","Present Simple","Oddiy dialoglar","Lug'at 500"]},
      {"title":"A2 — Kundalik nutq","lessons":["O'tgan zamon","Kelajak","Sayohat mavzusi","Audio amaliyot"]},
      {"title":"B1 — Mustaqillik","lessons":["Perfect zamonlar","Shartli gaplar","Munozara","Insho asoslari"]},
      {"title":"B2 — Ravonlik","lessons":["Murakkab gaplar","Idioma","Debat","Yakuniy test"]}
    ]},
    {"slug":"frontend-react","modules":[
      {"title":"Web asoslari","lessons":["HTML semantika","CSS Fl/Grid","Responsive","Loyiha #1"]},
      {"title":"JavaScript","lessons":["Sintaksis","DOM","Async/await","API bilan ishlash"]},
      {"title":"React","lessons":["Komponentlar","Hooks","State boshqaruvi","Routing"]},
      {"title":"Pro daraja","lessons":["TypeScript","Tailwind","Deploy","Portfolio loyiha"]}
    ]},
    {"slug":"math-dtm","modules":[
      {"title":"Algebra","lessons":["Tenglamalar","Funksiyalar","Progressiyalar","Blok test"]},
      {"title":"Geometriya","lessons":["Planimetriya","Stereometriya","Vektorlar","Blok test"]},
      {"title":"Trigonometriya","lessons":["Asoslar","Tenglamalar","Grafiklar","Blok test"]},
      {"title":"Yakuniy","lessons":["Aralash masalalar","Vaqt boshqaruvi","Mock DTM","Tahlil"]}
    ]},
    {"slug":"ui-ux-design","modules":[
      {"title":"Asoslar","lessons":["Dizayn fikrlash","Rang & tipografika","Grid","Figma intro"]},
      {"title":"Tadqiqot","lessons":["User persona","Journey map","Wireframe","Usability"]},
      {"title":"Interfeys","lessons":["Komponentlar","Auto-layout","Prototip","Dizayn tizimi"]},
      {"title":"Portfolio","lessons":["Case study","Behance","Taqdimot","Yakuniy loyiha"]}
    ]},
    {"slug":"kids-english","modules":[
      {"title":"Starter","lessons":["Salomlashish","Ranglar","Raqamlar","Qo'shiqlar"]},
      {"title":"Mover","lessons":["Oila","Hayvonlar","Ovqat","Hikoyalar"]},
      {"title":"Flyer","lessons":["Maktab","Sport","Sayohat","Loyiha"]},
      {"title":"Yakuniy","lessons":["Mini-spektakl","Sertifikat","Konkurs","Bayram"]}
    ]}
  ]
  $json$::jsonb;
begin
  for v_course in select * from jsonb_array_elements(v_tree) loop
    select id into v_course_id from public.courses where slug = v_course->>'slug';
    if v_course_id is null then continue; end if;
    -- idempotency: skip courses that already have modules
    if exists (select 1 from public.course_modules where course_id = v_course_id) then continue; end if;
    v_mpos := 0;
    for v_module in select * from jsonb_array_elements(v_course->'modules') loop
      insert into public.course_modules (course_id, title, position)
        values (v_course_id, v_module->>'title', v_mpos)
        returning id into v_module_id;
      v_lpos := 0;
      for v_lesson in select * from jsonb_array_elements_text(v_module->'lessons') loop
        insert into public.lessons (module_id, course_id, title, position, is_free_preview, duration_min)
          values (v_module_id, v_course_id, v_lesson, v_lpos, (v_mpos = 0 and v_lpos = 0), 25);
        v_lpos := v_lpos + 1;
      end loop;
      v_mpos := v_mpos + 1;
    end loop;
  end loop;
end $$;

-- ----------------------------------------------------------------------------
-- 6. Groups & enrollments  (delivery; mirrors panel teacherGroups)
-- ----------------------------------------------------------------------------
insert into public.groups (id, course_id, name, teacher_id, branch_id, room, capacity, mode, schedule, start_date, end_date, status)
values
  ('55555555-5555-5555-5555-555555550001'::uuid,
   (select id from public.courses where slug='ielts-intensive'),
   $$IELTS-A1$$,
   (select user_id from public.teacher_profiles where slug='dilnoza-karimova'),
   (select id from public.branches where slug='bosh-filial'),
   $$201-xona$$, 16, 'offline', $${"days":["mon","wed","fri"],"time":"18:00"}$$::jsonb,
   date '2026-01-13', date '2026-04-06', 'active'),
  ('55555555-5555-5555-5555-555555550002'::uuid,
   (select id from public.courses where slug='general-english-a1-b2'),
   $$GE-Eve$$,
   (select user_id from public.teacher_profiles where slug='javohir-tursunov'),
   (select id from public.branches where slug='bosh-filial'),
   $$105-xona$$, 20, 'offline', $${"days":["tue","thu"],"time":"19:00"}$$::jsonb,
   date '2026-02-03', date '2026-07-30', 'active'),
  ('55555555-5555-5555-5555-555555550003'::uuid,
   (select id from public.courses where slug='kids-english'),
   $$Kids-Sat$$,
   (select user_id from public.teacher_profiles where slug='javohir-tursunov'),
   (select id from public.branches where slug='chilonzor'),
   $$Bolalar zali$$, 8, 'offline', $${"days":["sat"],"time":"10:00"}$$::jsonb,
   date '2026-03-07', date '2026-11-28', 'active')
on conflict (id) do nothing;

insert into public.enrollments (student_id, course_id, group_id, status, progress_pct, enrolled_at)
values
  ('33333333-3333-3333-3333-333333330001'::uuid,
   (select id from public.courses where slug='ielts-intensive'),
   '55555555-5555-5555-5555-555555550001'::uuid, 'active', 65, now() - interval '120 days'),
  ('33333333-3333-3333-3333-333333330002'::uuid,
   (select id from public.courses where slug='general-english-a1-b2'),
   '55555555-5555-5555-5555-555555550002'::uuid, 'active', 40, now() - interval '90 days'),
  ('33333333-3333-3333-3333-333333330003'::uuid,
   (select id from public.courses where slug='kids-english'),
   '55555555-5555-5555-5555-555555550003'::uuid, 'active', 20, now() - interval '60 days')
on conflict (student_id, group_id) do nothing;

-- ----------------------------------------------------------------------------
-- 7. Assessment demo  ·  one assignment + one test (questions/options) + grades
-- ----------------------------------------------------------------------------
do $do$
declare
  v_course  uuid := (select id from public.courses where slug='ielts-intensive');
  v_group   uuid := '55555555-5555-5555-5555-555555550001';
  v_teacher uuid := (select user_id from public.teacher_profiles where slug='dilnoza-karimova');
  v_student uuid := '33333333-3333-3333-3333-333333330001';
  v_test    uuid := '77777777-7777-7777-7777-777777770001';
  v_q1 uuid; v_q2 uuid; v_q3 uuid;
begin
  if v_course is null then return; end if;

  -- assignment (essay)
  insert into public.assignments (id, course_id, group_id, title, description, type, max_score, due_at, created_by)
  values ('66666666-6666-6666-6666-666666660001'::uuid, v_course, v_group,
    $$Writing Task 2 — Essay$$, $$Berilgan mavzuda 250+ so'zli insho yozing.$$, 'essay', 100, now() + interval '7 days', v_teacher)
  on conflict (id) do nothing;

  -- test + questions + options (only seed once)
  if not exists (select 1 from public.tests where id = v_test) then
    insert into public.tests (id, course_id, group_id, title, description, type, duration_min, max_score, attempts_allowed, shuffle, is_published, created_by)
    values (v_test, v_course, v_group, $$IELTS Listening — Mock #1$$, $$Listening bo'limi bo'yicha sinov mock testi.$$, 'mock', 30, 3, 2, true, true, v_teacher);

    insert into public.questions (test_id, type, body, score, position, explanation)
    values (v_test, 'single_choice', $$"Section 1" odatda qanday mavzuda bo'ladi?$$, 1, 0, $$Kundalik ijtimoiy vaziyat (masalan, ro'yxatdan o'tish).$$)
    returning id into v_q1;
    insert into public.question_options (question_id, body, is_correct, position) values
      (v_q1, $$Kundalik ijtimoiy suhbat$$, true,  0),
      (v_q1, $$Akademik ma'ruza$$,        false, 1),
      (v_q1, $$Ilmiy munozara$$,          false, 2),
      (v_q1, $$Monolog taqdimot$$,        false, 3);

    insert into public.questions (test_id, type, body, score, position)
    values (v_test, 'true_false', $$Listening testida javoblarni ko'chirish uchun qo'shimcha vaqt beriladi.$$, 1, 1)
    returning id into v_q2;
    insert into public.question_options (question_id, body, is_correct, position) values
      (v_q2, $$To'g'ri$$,   true,  0),
      (v_q2, $$Noto'g'ri$$, false, 1);

    insert into public.questions (test_id, type, body, score, position)
    values (v_test, 'single_choice', $$"Map labelling" topshirig'ida nimaga e'tibor beriladi?$$, 1, 2)
    returning id into v_q3;
    insert into public.question_options (question_id, body, is_correct, position) values
      (v_q3, $$Yo'nalish va joylashuv so'zlari$$, true,  0),
      (v_q3, $$Faqat raqamlar$$,                  false, 1),
      (v_q3, $$Grammatik zamonlar$$,              false, 2);
  end if;

  -- a gradebook entry for the enrolled student (idempotent on title)
  insert into public.gradebook_entries (student_id, course_id, source, title, score, max_score, weight, recorded_by)
  select v_student, v_course, 'test', $$Mock #1 (Listening)$$, 27, 30, 1, v_teacher
  where not exists (
    select 1 from public.gradebook_entries
    where student_id = v_student and course_id = v_course and title = $$Mock #1 (Listening)$$
  );
end $do$;

-- ----------------------------------------------------------------------------
-- 8. Blog posts · announcement · finance demo
-- ----------------------------------------------------------------------------
-- blog posts (mirrors src/lib/mock/blog.ts); authors linked by full name
insert into public.blog_posts (slug, title, excerpt, category_id, author_id, cover_gradient, cover_emoji, read_time_min, status, published_at)
values
  ('ielts-writing-7', $$IELTS Writing'da 7.0 olishning 5 siri$$,
   $$Ko'pchilik Writing'da qiynaladi. Mana shu 5 ta amaliy texnika ballingizni oshiradi.$$,
   (select id from public.blog_categories where slug='ielts'),
   (select id from public.profiles where full_name='Dilnoza Karimova'),
   'from-aurora-violet to-aurora-blue', '✍️', 6, 'published', timestamptz '2026-05-20 09:00+05'),
  ('frontend-2026', $$2026-yilda Frontend: nimadan boshlash kerak?$$,
   $$Yangi boshlovchilar uchun zamonaviy frontend yo'l xaritasi va kerakli ko'nikmalar.$$,
   (select id from public.blog_categories where slug='dasturlash'),
   (select id from public.profiles where full_name='Sardor Aliyev'),
   'from-aurora-fuchsia to-aurora-violet', '⚛️', 8, 'published', timestamptz '2026-05-14 09:00+05'),
  ('til-organish-motivatsiya', $$Til o'rganishda motivatsiyani qanday saqlash mumkin?$$,
   $$Streak, kichik maqsadlar va to'g'ri muhit — barqaror o'rganishning kaliti.$$,
   (select id from public.blog_categories where slug='ingliz-tili'),
   (select id from public.profiles where full_name='Javohir Tursunov'),
   'from-aurora-cyan to-aurora-indigo', '🔥', 5, 'published', timestamptz '2026-05-08 09:00+05'),
  ('dtm-vaqt-boshqaruvi', $$DTM testida vaqtni to'g'ri taqsimlash$$,
   $$60 daqiqada 30 ta savol — har bir soniyani qanday ishlatish kerak.$$,
   (select id from public.blog_categories where slug='matematika'),
   (select id from public.profiles where full_name='Nodira Yusupova'),
   'from-aurora-blue to-aurora-violet', '⏱️', 4, 'published', timestamptz '2026-04-29 09:00+05'),
  ('portfolio-dizayn', $$Kuchli dizayn portfoliosi qanday tuziladi?$$,
   $$Case study yozish, loyihalarni taqdim etish va e'tiborni jalb qilish.$$,
   (select id from public.blog_categories where slug='dizayn'),
   (select id from public.profiles where full_name='Kamola Rashidova'),
   'from-aurora-pink to-aurora-fuchsia', '🎨', 7, 'published', timestamptz '2026-04-22 09:00+05'),
  ('speaking-qorquv', $$Speaking'dan qo'rqishni qanday yengish mumkin?$$,
   $$Til to'sig'i — bu psixologik to'siq. Mana uni buzishning amaliy yo'llari.$$,
   (select id from public.blog_categories where slug='ingliz-tili'),
   (select id from public.profiles where full_name='Dilnoza Karimova'),
   'from-aurora-violet to-aurora-pink', '🗣️', 5, 'published', timestamptz '2026-04-15 09:00+05')
on conflict (slug) do update set
  title = excluded.title, excerpt = excluded.excerpt, category_id = excluded.category_id,
  author_id = excluded.author_id, cover_gradient = excluded.cover_gradient,
  cover_emoji = excluded.cover_emoji, read_time_min = excluded.read_time_min,
  status = excluded.status, published_at = excluded.published_at;

-- a global welcome announcement
insert into public.announcements (id, scope, title, body, author_id, is_pinned, is_published)
values ('88888888-8888-8888-8888-888888880001'::uuid, 'global',
  $$Aurora Academy platformasiga xush kelibsiz!$$,
  $$Yangi semestr boshlandi. Kurslar, jadval va baholaringizni shaxsiy kabinetingizda kuzatib boring.$$,
  '11111111-1111-1111-1111-111111110001'::uuid, true, true)
on conflict (id) do nothing;

-- finance demo: a discount code + one paid invoice with its payment
insert into public.discounts (code, description, type, value, max_uses, course_id, valid_from, valid_to, is_active)
values ('AURORA10', $$Yangi o'quvchilar uchun 10% chegirma$$, 'percent', 10, 100, null, now() - interval '10 days', now() + interval '80 days', true)
on conflict (code) do nothing;

insert into public.invoices (number, student_id, course_id, group_id, plan_id, amount, currency, status, due_date, issued_at, paid_at)
values ('INV-2026-0001',
  '33333333-3333-3333-3333-333333330001'::uuid,
  (select id from public.courses where slug='ielts-intensive'),
  '55555555-5555-5555-5555-555555550001'::uuid,
  (select id from public.plans where slug='pro'),
  1490000, 'UZS', 'paid', date '2026-01-20', now() - interval '125 days', now() - interval '124 days')
on conflict (number) do nothing;

insert into public.payments (id, invoice_id, student_id, amount, currency, provider, provider_txn_id, status, paid_at)
values ('99999999-9999-9999-9999-999999990001'::uuid,
  (select id from public.invoices where number='INV-2026-0001'),
  '33333333-3333-3333-3333-333333330001'::uuid,
  1490000, 'UZS', 'payme', 'demo-payme-0001', 'success', now() - interval '124 days')
on conflict (id) do nothing;

-- ============================================================================
-- End of seed. Demo login: any *@aurora.uz account · password  Aurora!2026
-- ============================================================================
