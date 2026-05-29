-- ============================================================================
-- Aurora Academy LMS — TO'LIQ O'RNATISH (SQL Editor uchun)
-- Bu fayl 0001..0008 migration'lar + seed.sql ni TARTIB bilan birlashtiradi.
-- SQL Editor'ga to'liq nusxalab, Run bosing. FAQAT BIR MARTA ishga tushiring.
-- ============================================================================


-- ████████████████████████████████████████████████████████████████████████
-- ██  supabase/migrations/0001_extensions_and_enums.sql
-- ████████████████████████████████████████████████████████████████████████

-- ============================================================================
-- Aurora Academy LMS  ·  0001 — Extensions, enum types & shared helpers
-- ----------------------------------------------------------------------------
-- Target: PostgreSQL 15 / Supabase.
-- Apply order: FIRST. Every later migration depends on the enums defined here.
-- Apply with the Supabase CLI (`supabase db push`) or psql, in filename order.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Extensions
-- ---------------------------------------------------------------------------
create extension if not exists pgcrypto;   -- gen_random_uuid()
create extension if not exists citext;     -- case-insensitive text (emails)
create extension if not exists pg_trgm;    -- trigram indexes for fuzzy search

-- ---------------------------------------------------------------------------
-- Enum types  (grouped by domain)
-- ---------------------------------------------------------------------------

-- Identity & access
create type user_status        as enum ('active', 'inactive', 'suspended', 'pending');
create type gender_type        as enum ('male', 'female', 'other');
create type guardian_relation  as enum ('mother', 'father', 'guardian', 'other');

-- Education
create type course_level       as enum ('beginner', 'intermediate', 'advanced');
create type course_status      as enum ('draft', 'published', 'archived');
create type material_type      as enum ('video', 'pdf', 'link', 'file', 'audio', 'image');
create type group_status       as enum ('draft', 'active', 'paused', 'finished', 'archived');
create type enrollment_status  as enum ('pending', 'active', 'completed', 'dropped', 'paused');
create type session_mode       as enum ('online', 'offline', 'hybrid');
create type session_status     as enum ('scheduled', 'ongoing', 'completed', 'cancelled');
create type attendance_status  as enum ('present', 'absent', 'late', 'excused');
create type progress_status    as enum ('not_started', 'in_progress', 'completed');

-- Assessment
create type assignment_type    as enum ('homework', 'project', 'essay', 'lab', 'practical');
create type submission_status  as enum ('pending', 'submitted', 'late', 'graded', 'returned');
create type test_type          as enum ('quiz', 'exam', 'mock', 'placement');
create type attempt_status     as enum ('in_progress', 'submitted', 'graded', 'expired');
create type question_type      as enum ('single_choice', 'multiple_choice', 'true_false', 'short_text', 'essay', 'matching', 'ordering');
create type grade_source       as enum ('assignment', 'test', 'manual');

-- Finance
create type billing_period     as enum ('one_time', 'monthly', 'quarterly', 'yearly');
create type invoice_status     as enum ('draft', 'pending', 'paid', 'overdue', 'cancelled', 'refunded');
create type payment_provider   as enum ('payme', 'click', 'uzum', 'telegram', 'cash', 'bank_transfer');
create type payment_status     as enum ('pending', 'processing', 'success', 'failed', 'refunded', 'cancelled');
create type discount_type      as enum ('percent', 'fixed');

-- Communication
create type notification_channel as enum ('in_app', 'email', 'sms', 'telegram', 'push');
create type notification_type    as enum ('assignment', 'grade', 'payment', 'schedule', 'announcement', 'message', 'achievement', 'system');
create type conversation_type    as enum ('direct', 'group');
create type announcement_scope   as enum ('global', 'branch', 'course', 'group');

-- System / CMS
create type integration_provider as enum ('payme', 'click', 'uzum', 'telegram', 'zoom', 'google_calendar', 'sms');
create type integration_status   as enum ('connected', 'disconnected', 'error');
create type post_status          as enum ('draft', 'published', 'scheduled', 'archived');

-- ---------------------------------------------------------------------------
-- Shared trigger helper: keep updated_at fresh on every UPDATE
-- ---------------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

comment on function public.set_updated_at() is
  'Generic BEFORE UPDATE trigger: stamps updated_at with now().';


-- ████████████████████████████████████████████████████████████████████████
-- ██  supabase/migrations/0002_identity_access.sql
-- ████████████████████████████████████████████████████████████████████████

-- ============================================================================
-- Aurora Academy LMS  ·  0002 — Identity & Access (RBAC)
-- ----------------------------------------------------------------------------
-- 8-role RBAC, profiles bound to Supabase auth.users, branches, guardianships,
-- and role-specific extension tables. Defines the RLS helper functions every
-- later migration relies on, then enables Row Level Security.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- roles  ·  the 8 platform roles
-- ---------------------------------------------------------------------------
create table public.roles (
  id          integer generated by default as identity primary key,
  key         text    not null unique,           -- machine key, used in code & RLS
  name        text    not null,                   -- human label (Uzbek)
  description text,
  level       smallint not null default 0,        -- privilege weight, higher = more
  is_staff    boolean  not null default false,    -- counts as internal staff
  created_at  timestamptz not null default now()
);
comment on table public.roles is 'Platform roles for RBAC (super_admin … guest).';

-- ---------------------------------------------------------------------------
-- permissions  ·  granular capabilities (optional fine-grained layer)
-- ---------------------------------------------------------------------------
create table public.permissions (
  id          integer generated by default as identity primary key,
  key         text not null unique,               -- e.g. 'course.create'
  description text,
  created_at  timestamptz not null default now()
);
comment on table public.permissions is 'Fine-grained capabilities assignable to roles.';

create table public.role_permissions (
  role_id       integer not null references public.roles(id) on delete cascade,
  permission_id integer not null references public.permissions(id) on delete cascade,
  primary key (role_id, permission_id)
);
comment on table public.role_permissions is 'Many-to-many: which permissions a role grants.';

-- ---------------------------------------------------------------------------
-- branches  ·  physical/virtual locations of the academy
-- ---------------------------------------------------------------------------
create table public.branches (
  id         uuid primary key default gen_random_uuid(),
  name       text not null,
  slug       text unique,
  address    text,
  phone      text,
  is_active  boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create trigger trg_branches_updated before update on public.branches
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- profiles  ·  1:1 with auth.users, public application identity
-- ---------------------------------------------------------------------------
create table public.profiles (
  id           uuid primary key references auth.users(id) on delete cascade,
  email        citext unique,
  first_name   text,
  last_name    text,
  full_name    text generated always as
                 (btrim(coalesce(first_name, '') || ' ' || coalesce(last_name, ''))) stored,
  phone        text,
  avatar_url   text,
  gender       gender_type,
  birth_date   date,
  locale       text not null default 'uz',
  bio          text,
  status       user_status not null default 'active',
  branch_id    uuid references public.branches(id) on delete set null,
  last_seen_at timestamptz,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);
comment on table public.profiles is 'Application profile for each auth user.';
create index idx_profiles_branch on public.profiles(branch_id);
create index idx_profiles_status on public.profiles(status);
create index idx_profiles_name_trgm on public.profiles using gin (full_name gin_trgm_ops);
create trigger trg_profiles_updated before update on public.profiles
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- user_roles  ·  many-to-many; a user may be e.g. teacher AND parent
-- ---------------------------------------------------------------------------
create table public.user_roles (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid    not null references public.profiles(id) on delete cascade,
  role_id     integer not null references public.roles(id)    on delete cascade,
  branch_id   uuid    references public.branches(id) on delete set null,
  assigned_by uuid    references public.profiles(id) on delete set null,
  assigned_at timestamptz not null default now(),
  unique (user_id, role_id)
);
create index idx_user_roles_user on public.user_roles(user_id);
create index idx_user_roles_role on public.user_roles(role_id);

-- ---------------------------------------------------------------------------
-- guardianships  ·  links parent/guardian profiles to student profiles
-- ---------------------------------------------------------------------------
create table public.guardianships (
  id          uuid primary key default gen_random_uuid(),
  student_id  uuid not null references public.profiles(id) on delete cascade,
  guardian_id uuid not null references public.profiles(id) on delete cascade,
  relation    guardian_relation not null default 'guardian',
  is_primary  boolean not null default false,
  created_at  timestamptz not null default now(),
  unique (student_id, guardian_id),
  check (student_id <> guardian_id)
);
create index idx_guardianships_guardian on public.guardianships(guardian_id);
create index idx_guardianships_student  on public.guardianships(student_id);

-- ---------------------------------------------------------------------------
-- teacher_profiles  ·  role-specific extension for teachers
-- ---------------------------------------------------------------------------
create table public.teacher_profiles (
  user_id          uuid primary key references public.profiles(id) on delete cascade,
  slug             text unique,
  headline         text,
  bio              text,
  experience_years smallint default 0,
  hourly_rate      numeric(12,2),
  rating           numeric(2,1) default 0 check (rating between 0 and 5),
  students_count   integer default 0,
  badges           text[] not null default '{}',
  subjects         text[] not null default '{}',
  is_featured      boolean not null default false,
  hired_at         date,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);
comment on table public.teacher_profiles is 'Public teacher directory data.';
create trigger trg_teacher_profiles_updated before update on public.teacher_profiles
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- student_profiles  ·  role-specific extension incl. gamification counters
-- ---------------------------------------------------------------------------
create table public.student_profiles (
  user_id        uuid primary key references public.profiles(id) on delete cascade,
  student_code   text unique,
  level          smallint not null default 1,
  xp             integer  not null default 0,
  coins          integer  not null default 0,
  current_streak smallint not null default 0,
  longest_streak smallint not null default 0,
  enrolled_at    date,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);
comment on table public.student_profiles is 'Per-student counters & gamification state.';
create trigger trg_student_profiles_updated before update on public.student_profiles
  for each row execute function public.set_updated_at();

-- ============================================================================
-- RLS HELPER FUNCTIONS
-- SECURITY DEFINER so they can read user_roles regardless of the caller's RLS.
-- Used throughout every later migration's policies.
-- ============================================================================
create or replace function public.has_role(p_role text)
returns boolean
language sql stable security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.user_roles ur
    join public.roles r on r.id = ur.role_id
    where ur.user_id = auth.uid()
      and r.key = p_role
  );
$$;

create or replace function public.has_any_role(p_roles text[])
returns boolean
language sql stable security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.user_roles ur
    join public.roles r on r.id = ur.role_id
    where ur.user_id = auth.uid()
      and r.key = any(p_roles)
  );
$$;

create or replace function public.is_admin()
returns boolean
language sql stable security definer
set search_path = public
as $$
  select public.has_any_role(array['super_admin', 'admin']);
$$;

-- Any internal staff member (admin, manager, teacher, assistant).
create or replace function public.is_staff()
returns boolean
language sql stable security definer
set search_path = public
as $$
  select public.has_any_role(array['super_admin', 'admin', 'manager', 'teacher', 'assistant']);
$$;

create or replace function public.is_teacher()
returns boolean
language sql stable security definer
set search_path = public
as $$
  select public.has_any_role(array['teacher', 'assistant']);
$$;

-- True when the current user is a guardian of the given student.
create or replace function public.is_guardian_of(p_student uuid)
returns boolean
language sql stable security definer
set search_path = public
as $$
  select exists (
    select 1 from public.guardianships g
    where g.student_id = p_student and g.guardian_id = auth.uid()
  );
$$;

-- ---------------------------------------------------------------------------
-- New-user hook: create a profile row when a Supabase auth user signs up.
-- ---------------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, first_name, last_name, phone)
  values (
    new.id,
    new.email,
    nullif(new.raw_user_meta_data ->> 'first_name', ''),
    nullif(new.raw_user_meta_data ->> 'last_name', ''),
    nullif(new.raw_user_meta_data ->> 'phone', '')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================
alter table public.roles            enable row level security;
alter table public.permissions      enable row level security;
alter table public.role_permissions enable row level security;
alter table public.branches         enable row level security;
alter table public.profiles         enable row level security;
alter table public.user_roles       enable row level security;
alter table public.guardianships    enable row level security;
alter table public.teacher_profiles enable row level security;
alter table public.student_profiles enable row level security;

-- roles / permissions are reference data: readable by any authenticated user,
-- writable only by admins.
create policy roles_read   on public.roles            for select to authenticated using (true);
create policy roles_admin  on public.roles            for all    to authenticated using (public.is_admin()) with check (public.is_admin());
create policy perms_read   on public.permissions      for select to authenticated using (true);
create policy perms_admin  on public.permissions      for all    to authenticated using (public.is_admin()) with check (public.is_admin());
create policy rp_read      on public.role_permissions for select to authenticated using (true);
create policy rp_admin     on public.role_permissions for all    to authenticated using (public.is_admin()) with check (public.is_admin());

-- branches: visible to everyone (public site lists them); managed by admins.
create policy branches_read  on public.branches for select using (true);
create policy branches_admin on public.branches for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- profiles: a user sees & edits their own; staff & guardians can read; admins manage.
create policy profiles_select_self    on public.profiles for select to authenticated
  using (id = auth.uid() or public.is_staff() or public.is_guardian_of(id));
create policy profiles_insert_self     on public.profiles for insert to authenticated
  with check (id = auth.uid());
create policy profiles_update_self     on public.profiles for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());
create policy profiles_admin_all       on public.profiles for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- user_roles: a user can see their own role assignments; only admins change them.
create policy user_roles_select on public.user_roles for select to authenticated
  using (user_id = auth.uid() or public.is_staff());
create policy user_roles_admin  on public.user_roles for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- guardianships: visible to the student, the guardian, or staff; admins manage.
create policy guardianships_select on public.guardianships for select to authenticated
  using (student_id = auth.uid() or guardian_id = auth.uid() or public.is_staff());
create policy guardianships_admin  on public.guardianships for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- teacher_profiles: PUBLIC read (marketing directory); self-edit or admin write.
create policy teacher_profiles_read   on public.teacher_profiles for select using (true);
create policy teacher_profiles_self   on public.teacher_profiles for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy teacher_profiles_admin  on public.teacher_profiles for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- student_profiles: student, their guardians, and staff can read; admin manages.
create policy student_profiles_select on public.student_profiles for select to authenticated
  using (user_id = auth.uid() or public.is_staff() or public.is_guardian_of(user_id));
create policy student_profiles_admin  on public.student_profiles for all to authenticated
  using (public.is_admin()) with check (public.is_admin());


-- ████████████████████████████████████████████████████████████████████████
-- ██  supabase/migrations/0003_education.sql
-- ████████████████████████████████████████████████████████████████████████

-- ============================================================================
-- Aurora Academy LMS  ·  0003 — Education
-- ----------------------------------------------------------------------------
-- Course catalog (categories → courses → modules → lessons → materials) and
-- delivery (groups → enrollments, class_sessions → attendance, lesson_progress).
-- ============================================================================

-- ---------------------------------------------------------------------------
-- categories
-- ---------------------------------------------------------------------------
create table public.categories (
  id         integer generated by default as identity primary key,
  slug       text not null unique,
  name       text not null,
  position   smallint not null default 0,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- courses
-- ---------------------------------------------------------------------------
create table public.courses (
  id             uuid primary key default gen_random_uuid(),
  slug           text not null unique,
  title          text not null,
  subtitle       text,
  description    text,
  category_id    integer references public.categories(id) on delete set null,
  level          course_level not null default 'beginner',
  language       text not null default 'uz',
  duration_weeks smallint,
  lessons_count  smallint default 0,
  price          numeric(12,2) not null default 0,
  old_price      numeric(12,2),
  currency       text not null default 'UZS',
  rating         numeric(2,1) default 0 check (rating between 0 and 5),
  reviews_count  integer default 0,
  students_count integer default 0,
  teacher_id     uuid references public.profiles(id) on delete set null,  -- lead teacher
  cover_gradient text,                                  -- tailwind gradient classes
  cover_emoji    text,
  highlights     text[] not null default '{}',
  status         course_status not null default 'draft',
  is_popular     boolean not null default false,
  published_at   timestamptz,
  created_by     uuid references public.profiles(id) on delete set null,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);
create index idx_courses_category on public.courses(category_id);
create index idx_courses_teacher  on public.courses(teacher_id);
create index idx_courses_status   on public.courses(status);
create index idx_courses_title_trgm on public.courses using gin (title gin_trgm_ops);
create trigger trg_courses_updated before update on public.courses
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- course_modules
-- ---------------------------------------------------------------------------
create table public.course_modules (
  id         uuid primary key default gen_random_uuid(),
  course_id  uuid not null references public.courses(id) on delete cascade,
  title      text not null,
  summary    text,
  position   smallint not null default 0,
  created_at timestamptz not null default now()
);
create index idx_modules_course on public.course_modules(course_id);

-- ---------------------------------------------------------------------------
-- lessons
-- ---------------------------------------------------------------------------
create table public.lessons (
  id              uuid primary key default gen_random_uuid(),
  module_id       uuid not null references public.course_modules(id) on delete cascade,
  course_id       uuid not null references public.courses(id) on delete cascade,
  title           text not null,
  slug            text,
  content         text,
  video_url       text,
  duration_min    smallint,
  position        smallint not null default 0,
  is_free_preview boolean not null default false,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);
create index idx_lessons_module on public.lessons(module_id);
create index idx_lessons_course on public.lessons(course_id);
create trigger trg_lessons_updated before update on public.lessons
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- lesson_materials
-- ---------------------------------------------------------------------------
create table public.lesson_materials (
  id         uuid primary key default gen_random_uuid(),
  lesson_id  uuid not null references public.lessons(id) on delete cascade,
  title      text not null,
  type       material_type not null default 'file',
  url        text not null,
  size_bytes bigint,
  position   smallint not null default 0,
  created_at timestamptz not null default now()
);
create index idx_materials_lesson on public.lesson_materials(lesson_id);

-- ---------------------------------------------------------------------------
-- groups  ·  a cohort taking a course on a schedule
-- ---------------------------------------------------------------------------
create table public.groups (
  id         uuid primary key default gen_random_uuid(),
  course_id  uuid not null references public.courses(id) on delete restrict,
  name       text not null,
  teacher_id uuid references public.profiles(id) on delete set null,
  branch_id  uuid references public.branches(id) on delete set null,
  room       text,
  capacity   smallint default 20,
  mode       session_mode not null default 'offline',
  schedule   jsonb,                       -- e.g. {"days":["mon","wed","fri"],"time":"18:00"}
  start_date date,
  end_date   date,
  status     group_status not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index idx_groups_course  on public.groups(course_id);
create index idx_groups_teacher on public.groups(teacher_id);
create index idx_groups_status  on public.groups(status);
create trigger trg_groups_updated before update on public.groups
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- enrollments  ·  a student's membership in a group/course
-- ---------------------------------------------------------------------------
create table public.enrollments (
  id           uuid primary key default gen_random_uuid(),
  student_id   uuid not null references public.profiles(id) on delete cascade,
  course_id    uuid not null references public.courses(id) on delete cascade,
  group_id     uuid references public.groups(id) on delete set null,
  status       enrollment_status not null default 'active',
  progress_pct numeric(5,2) not null default 0 check (progress_pct between 0 and 100),
  enrolled_at  timestamptz not null default now(),
  completed_at timestamptz,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  unique (student_id, group_id)
);
create index idx_enrollments_student on public.enrollments(student_id);
create index idx_enrollments_course  on public.enrollments(course_id);
create index idx_enrollments_group   on public.enrollments(group_id);
create trigger trg_enrollments_updated before update on public.enrollments
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- class_sessions  ·  a scheduled meeting of a group
-- ---------------------------------------------------------------------------
create table public.class_sessions (
  id          uuid primary key default gen_random_uuid(),
  group_id    uuid not null references public.groups(id) on delete cascade,
  lesson_id   uuid references public.lessons(id) on delete set null,
  title       text not null,
  starts_at   timestamptz not null,
  ends_at     timestamptz,
  room        text,
  mode        session_mode not null default 'offline',
  meeting_url text,                         -- Zoom / Meet link for online sessions
  status      session_status not null default 'scheduled',
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
create index idx_sessions_group on public.class_sessions(group_id);
create index idx_sessions_start on public.class_sessions(starts_at);
create trigger trg_sessions_updated before update on public.class_sessions
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- attendance
-- ---------------------------------------------------------------------------
create table public.attendance (
  id         uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.class_sessions(id) on delete cascade,
  student_id uuid not null references public.profiles(id) on delete cascade,
  status     attendance_status not null default 'present',
  note       text,
  marked_by  uuid references public.profiles(id) on delete set null,
  marked_at  timestamptz not null default now(),
  unique (session_id, student_id)
);
create index idx_attendance_student on public.attendance(student_id);
create index idx_attendance_session on public.attendance(session_id);

-- ---------------------------------------------------------------------------
-- lesson_progress  ·  per-student, per-lesson completion
-- ---------------------------------------------------------------------------
create table public.lesson_progress (
  id            uuid primary key default gen_random_uuid(),
  enrollment_id uuid not null references public.enrollments(id) on delete cascade,
  lesson_id     uuid not null references public.lessons(id) on delete cascade,
  status        progress_status not null default 'not_started',
  watch_seconds integer not null default 0,
  completed_at  timestamptz,
  updated_at    timestamptz not null default now(),
  unique (enrollment_id, lesson_id)
);
create index idx_progress_enrollment on public.lesson_progress(enrollment_id);
create trigger trg_progress_updated before update on public.lesson_progress
  for each row execute function public.set_updated_at();

-- ============================================================================
-- RLS HELPERS specific to education (defined now that the tables exist)
-- ============================================================================

-- Is the current user actively enrolled in a course?
create or replace function public.is_enrolled(p_course uuid)
returns boolean
language sql stable security definer
set search_path = public
as $$
  select exists (
    select 1 from public.enrollments e
    where e.course_id = p_course
      and e.student_id = auth.uid()
      and e.status in ('active', 'completed')
  );
$$;

-- Does the current user teach (lead) the given group?
create or replace function public.teaches_group(p_group uuid)
returns boolean
language sql stable security definer
set search_path = public
as $$
  select exists (
    select 1 from public.groups g
    where g.id = p_group and g.teacher_id = auth.uid()
  );
$$;

-- Does the current user teach the given course (as lead or via any group)?
create or replace function public.teaches_course(p_course uuid)
returns boolean
language sql stable security definer
set search_path = public
as $$
  select exists (select 1 from public.courses c where c.id = p_course and c.teacher_id = auth.uid())
      or exists (select 1 from public.groups  g where g.course_id = p_course and g.teacher_id = auth.uid());
$$;

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================
alter table public.categories       enable row level security;
alter table public.courses           enable row level security;
alter table public.course_modules    enable row level security;
alter table public.lessons           enable row level security;
alter table public.lesson_materials  enable row level security;
alter table public.groups            enable row level security;
alter table public.enrollments       enable row level security;
alter table public.class_sessions    enable row level security;
alter table public.attendance        enable row level security;
alter table public.lesson_progress   enable row level security;

-- categories: public read, admin write
create policy categories_read  on public.categories for select using (true);
create policy categories_admin on public.categories for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- courses: published courses are public; staff see all; owner-teacher & admin write
create policy courses_read_public on public.courses for select
  using (status = 'published' or public.is_staff());
create policy courses_admin on public.courses for all to authenticated
  using (public.is_admin() or teacher_id = auth.uid())
  with check (public.is_admin() or teacher_id = auth.uid());

-- modules: readable when the parent course is published / enrolled / staff
create policy modules_read on public.course_modules for select using (
  public.is_staff()
  or public.teaches_course(course_id)
  or public.is_enrolled(course_id)
  or exists (select 1 from public.courses c where c.id = course_id and c.status = 'published')
);
create policy modules_admin on public.course_modules for all to authenticated
  using (public.is_admin() or public.teaches_course(course_id))
  with check (public.is_admin() or public.teaches_course(course_id));

-- lessons: free-preview & published-course metadata public; full access for
-- enrolled students, course teachers, and staff.
create policy lessons_read on public.lessons for select using (
  is_free_preview
  or public.is_staff()
  or public.teaches_course(course_id)
  or public.is_enrolled(course_id)
);
create policy lessons_admin on public.lessons for all to authenticated
  using (public.is_admin() or public.teaches_course(course_id))
  with check (public.is_admin() or public.teaches_course(course_id));

-- lesson_materials: follow the parent lesson's access (enrolled / teacher / staff)
create policy materials_read on public.lesson_materials for select using (
  public.is_staff()
  or exists (
    select 1 from public.lessons l
    where l.id = lesson_id
      and (l.is_free_preview or public.teaches_course(l.course_id) or public.is_enrolled(l.course_id))
  )
);
create policy materials_admin on public.lesson_materials for all to authenticated
  using (
    public.is_admin()
    or exists (select 1 from public.lessons l where l.id = lesson_id and public.teaches_course(l.course_id))
  )
  with check (
    public.is_admin()
    or exists (select 1 from public.lessons l where l.id = lesson_id and public.teaches_course(l.course_id))
  );

-- groups: staff & lead teacher; students see groups they belong to
create policy groups_read on public.groups for select to authenticated using (
  public.is_staff()
  or teacher_id = auth.uid()
  or exists (select 1 from public.enrollments e where e.group_id = id and e.student_id = auth.uid())
);
create policy groups_admin on public.groups for all to authenticated
  using (public.is_admin() or teacher_id = auth.uid())
  with check (public.is_admin() or teacher_id = auth.uid());

-- enrollments: student owns; group teacher & staff read; admin/teacher manage
create policy enrollments_select on public.enrollments for select to authenticated using (
  student_id = auth.uid()
  or public.is_staff()
  or public.teaches_group(group_id)
  or public.is_guardian_of(student_id)
);
create policy enrollments_admin on public.enrollments for all to authenticated
  using (public.is_admin() or public.teaches_group(group_id))
  with check (public.is_admin() or public.teaches_group(group_id));

-- class_sessions: enrolled students + group teacher + staff read; teacher/admin manage
create policy sessions_select on public.class_sessions for select to authenticated using (
  public.is_staff()
  or public.teaches_group(group_id)
  or exists (select 1 from public.enrollments e where e.group_id = group_id and e.student_id = auth.uid())
);
create policy sessions_admin on public.class_sessions for all to authenticated
  using (public.is_admin() or public.teaches_group(group_id))
  with check (public.is_admin() or public.teaches_group(group_id));

-- attendance: student sees own; group teacher & staff manage
create policy attendance_select on public.attendance for select to authenticated using (
  student_id = auth.uid()
  or public.is_staff()
  or public.is_guardian_of(student_id)
  or exists (
    select 1 from public.class_sessions s
    where s.id = session_id and public.teaches_group(s.group_id)
  )
);
create policy attendance_write on public.attendance for all to authenticated
  using (
    public.is_admin()
    or exists (select 1 from public.class_sessions s where s.id = session_id and public.teaches_group(s.group_id))
  )
  with check (
    public.is_admin()
    or exists (select 1 from public.class_sessions s where s.id = session_id and public.teaches_group(s.group_id))
  );

-- lesson_progress: the owning student writes; staff read
create policy progress_select on public.lesson_progress for select to authenticated using (
  public.is_staff()
  or exists (select 1 from public.enrollments e where e.id = enrollment_id and e.student_id = auth.uid())
);
create policy progress_write on public.lesson_progress for all to authenticated
  using (
    public.is_admin()
    or exists (select 1 from public.enrollments e where e.id = enrollment_id and e.student_id = auth.uid())
  )
  with check (
    public.is_admin()
    or exists (select 1 from public.enrollments e where e.id = enrollment_id and e.student_id = auth.uid())
  );


-- ████████████████████████████████████████████████████████████████████████
-- ██  supabase/migrations/0004_assessment.sql
-- ████████████████████████████████████████████████████████████████████████

-- ============================================================================
-- Aurora Academy LMS  ·  0004 — Assessment
-- ----------------------------------------------------------------------------
-- Assignments & submissions, the test/quiz engine (tests → questions →
-- options, attempts → answers), a flexible gradebook, and certificates.
--
-- SECURITY NOTE: question_options holds the correct-answer flag. Its SELECT
-- policy is staff/teacher-only. Students must receive sanitized options through
-- a SECURITY DEFINER RPC (e.g. get_test_questions) added in the app phase —
-- never by selecting question_options directly.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- assignments
-- ---------------------------------------------------------------------------
create table public.assignments (
  id          uuid primary key default gen_random_uuid(),
  course_id   uuid not null references public.courses(id) on delete cascade,
  group_id    uuid references public.groups(id) on delete cascade,
  lesson_id   uuid references public.lessons(id) on delete set null,
  title       text not null,
  description text,
  type        assignment_type not null default 'homework',
  max_score   numeric(6,2) not null default 100,
  due_at      timestamptz,
  created_by  uuid references public.profiles(id) on delete set null,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
create index idx_assignments_course on public.assignments(course_id);
create index idx_assignments_group  on public.assignments(group_id);
create index idx_assignments_due    on public.assignments(due_at);
create trigger trg_assignments_updated before update on public.assignments
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- assignment_submissions
-- ---------------------------------------------------------------------------
create table public.assignment_submissions (
  id            uuid primary key default gen_random_uuid(),
  assignment_id uuid not null references public.assignments(id) on delete cascade,
  student_id    uuid not null references public.profiles(id) on delete cascade,
  content       text,
  file_url      text,
  status        submission_status not null default 'pending',
  score         numeric(6,2),
  feedback      text,
  submitted_at  timestamptz,
  graded_by     uuid references public.profiles(id) on delete set null,
  graded_at     timestamptz,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  unique (assignment_id, student_id)
);
create index idx_submissions_assignment on public.assignment_submissions(assignment_id);
create index idx_submissions_student    on public.assignment_submissions(student_id);
create index idx_submissions_status     on public.assignment_submissions(status);
create trigger trg_submissions_updated before update on public.assignment_submissions
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- tests  ·  quizzes, exams, mock tests, placement tests
-- ---------------------------------------------------------------------------
create table public.tests (
  id              uuid primary key default gen_random_uuid(),
  course_id       uuid references public.courses(id) on delete cascade,
  group_id        uuid references public.groups(id) on delete cascade,
  title           text not null,
  description     text,
  type            test_type not null default 'quiz',
  duration_min    smallint,
  max_score       numeric(6,2) not null default 100,
  attempts_allowed smallint not null default 1,
  shuffle         boolean not null default false,
  is_published    boolean not null default false,
  available_from  timestamptz,
  available_to    timestamptz,
  created_by      uuid references public.profiles(id) on delete set null,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);
create index idx_tests_course on public.tests(course_id);
create index idx_tests_group  on public.tests(group_id);
create trigger trg_tests_updated before update on public.tests
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- questions
-- ---------------------------------------------------------------------------
create table public.questions (
  id          uuid primary key default gen_random_uuid(),
  test_id     uuid not null references public.tests(id) on delete cascade,
  type        question_type not null default 'single_choice',
  body        text not null,
  score       numeric(6,2) not null default 1,
  position    smallint not null default 0,
  explanation text,
  created_at  timestamptz not null default now()
);
create index idx_questions_test on public.questions(test_id);

-- ---------------------------------------------------------------------------
-- question_options  ·  CONTAINS CORRECT-ANSWER FLAG — staff-only SELECT
-- ---------------------------------------------------------------------------
create table public.question_options (
  id          uuid primary key default gen_random_uuid(),
  question_id uuid not null references public.questions(id) on delete cascade,
  body        text not null,
  is_correct  boolean not null default false,
  position    smallint not null default 0
);
create index idx_options_question on public.question_options(question_id);

-- ---------------------------------------------------------------------------
-- test_attempts
-- ---------------------------------------------------------------------------
create table public.test_attempts (
  id             uuid primary key default gen_random_uuid(),
  test_id        uuid not null references public.tests(id) on delete cascade,
  student_id     uuid not null references public.profiles(id) on delete cascade,
  started_at     timestamptz not null default now(),
  submitted_at   timestamptz,
  score          numeric(6,2),
  max_score      numeric(6,2),
  status         attempt_status not null default 'in_progress',
  time_spent_sec integer,
  created_at     timestamptz not null default now()
);
create index idx_attempts_test    on public.test_attempts(test_id);
create index idx_attempts_student on public.test_attempts(student_id);

-- ---------------------------------------------------------------------------
-- test_answers
-- ---------------------------------------------------------------------------
create table public.test_answers (
  id                 uuid primary key default gen_random_uuid(),
  attempt_id         uuid not null references public.test_attempts(id) on delete cascade,
  question_id        uuid not null references public.questions(id) on delete cascade,
  selected_option_ids uuid[] not null default '{}',
  answer_text        text,
  is_correct         boolean,
  score              numeric(6,2),
  created_at         timestamptz not null default now(),
  unique (attempt_id, question_id)
);
create index idx_answers_attempt on public.test_answers(attempt_id);

-- ---------------------------------------------------------------------------
-- gradebook_entries  ·  unified gradebook across assignments / tests / manual
-- ---------------------------------------------------------------------------
create table public.gradebook_entries (
  id          uuid primary key default gen_random_uuid(),
  student_id  uuid not null references public.profiles(id) on delete cascade,
  course_id   uuid not null references public.courses(id) on delete cascade,
  source      grade_source not null,
  source_id   uuid,                          -- assignment_submission / test_attempt id
  title       text,
  score       numeric(6,2) not null,
  max_score   numeric(6,2) not null default 100,
  weight      numeric(5,2) not null default 1,
  recorded_by uuid references public.profiles(id) on delete set null,
  recorded_at timestamptz not null default now()
);
create index idx_gradebook_student on public.gradebook_entries(student_id);
create index idx_gradebook_course  on public.gradebook_entries(course_id);

-- ---------------------------------------------------------------------------
-- certificates
-- ---------------------------------------------------------------------------
create table public.certificates (
  id         uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.profiles(id) on delete cascade,
  course_id  uuid not null references public.courses(id) on delete cascade,
  serial     text not null unique,
  url        text,
  issued_at  timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique (student_id, course_id)
);
create index idx_certificates_student on public.certificates(student_id);

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================
alter table public.assignments            enable row level security;
alter table public.assignment_submissions enable row level security;
alter table public.tests                   enable row level security;
alter table public.questions               enable row level security;
alter table public.question_options        enable row level security;
alter table public.test_attempts           enable row level security;
alter table public.test_answers            enable row level security;
alter table public.gradebook_entries       enable row level security;
alter table public.certificates            enable row level security;

-- assignments: enrolled students + course teacher + staff read; teacher/admin manage
create policy assignments_select on public.assignments for select to authenticated using (
  public.is_staff() or public.teaches_course(course_id) or public.is_enrolled(course_id)
);
create policy assignments_admin on public.assignments for all to authenticated
  using (public.is_admin() or public.teaches_course(course_id))
  with check (public.is_admin() or public.teaches_course(course_id));

-- submissions: student owns; course teacher & staff read + grade
create policy submissions_select on public.assignment_submissions for select to authenticated using (
  student_id = auth.uid()
  or public.is_staff()
  or public.is_guardian_of(student_id)
  or exists (select 1 from public.assignments a where a.id = assignment_id and public.teaches_course(a.course_id))
);
-- student creates / edits their own submission
create policy submissions_student_write on public.assignment_submissions for all to authenticated
  using (student_id = auth.uid())
  with check (student_id = auth.uid());
-- teacher / admin grade (update any field)
create policy submissions_grade on public.assignment_submissions for all to authenticated
  using (
    public.is_admin()
    or exists (select 1 from public.assignments a where a.id = assignment_id and public.teaches_course(a.course_id))
  )
  with check (
    public.is_admin()
    or exists (select 1 from public.assignments a where a.id = assignment_id and public.teaches_course(a.course_id))
  );

-- tests: published + enrolled/teacher/staff read; teacher/admin manage
create policy tests_select on public.tests for select to authenticated using (
  public.is_staff()
  or (course_id is not null and public.teaches_course(course_id))
  or (course_id is not null and public.is_enrolled(course_id) and is_published)
);
create policy tests_admin on public.tests for all to authenticated
  using (public.is_admin() or (course_id is not null and public.teaches_course(course_id)))
  with check (public.is_admin() or (course_id is not null and public.teaches_course(course_id)));

-- questions: enrolled students may read the prompt; teacher/staff full
create policy questions_select on public.questions for select to authenticated using (
  public.is_staff()
  or exists (
    select 1 from public.tests t
    where t.id = test_id
      and (public.teaches_course(t.course_id) or (public.is_enrolled(t.course_id) and t.is_published))
  )
);
create policy questions_admin on public.questions for all to authenticated
  using (
    public.is_admin()
    or exists (select 1 from public.tests t where t.id = test_id and public.teaches_course(t.course_id))
  )
  with check (
    public.is_admin()
    or exists (select 1 from public.tests t where t.id = test_id and public.teaches_course(t.course_id))
  );

-- question_options: STAFF / TEACHER ONLY (protects is_correct). Students get
-- sanitized options via a SECURITY DEFINER RPC, not by selecting this table.
create policy options_staff_only on public.question_options for select to authenticated using (
  public.is_staff()
);
create policy options_admin on public.question_options for all to authenticated
  using (
    public.is_admin()
    or exists (
      select 1 from public.questions q join public.tests t on t.id = q.test_id
      where q.id = question_id and public.teaches_course(t.course_id)
    )
  )
  with check (
    public.is_admin()
    or exists (
      select 1 from public.questions q join public.tests t on t.id = q.test_id
      where q.id = question_id and public.teaches_course(t.course_id)
    )
  );

-- test_attempts: student owns; test teacher & staff read
create policy attempts_select on public.test_attempts for select to authenticated using (
  student_id = auth.uid()
  or public.is_staff()
  or exists (select 1 from public.tests t where t.id = test_id and public.teaches_course(t.course_id))
);
create policy attempts_student_write on public.test_attempts for all to authenticated
  using (student_id = auth.uid()) with check (student_id = auth.uid());
create policy attempts_admin on public.test_attempts for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- test_answers: tied to the owning attempt
create policy answers_select on public.test_answers for select to authenticated using (
  public.is_staff()
  or exists (select 1 from public.test_attempts a where a.id = attempt_id and a.student_id = auth.uid())
  or exists (
    select 1 from public.test_attempts a join public.tests t on t.id = a.test_id
    where a.id = attempt_id and public.teaches_course(t.course_id)
  )
);
create policy answers_student_write on public.test_answers for all to authenticated
  using (exists (select 1 from public.test_attempts a where a.id = attempt_id and a.student_id = auth.uid()))
  with check (exists (select 1 from public.test_attempts a where a.id = attempt_id and a.student_id = auth.uid()));

-- gradebook: student & guardian read own; course teacher & staff read/manage
create policy gradebook_select on public.gradebook_entries for select to authenticated using (
  student_id = auth.uid()
  or public.is_staff()
  or public.is_guardian_of(student_id)
  or public.teaches_course(course_id)
);
create policy gradebook_admin on public.gradebook_entries for all to authenticated
  using (public.is_admin() or public.teaches_course(course_id))
  with check (public.is_admin() or public.teaches_course(course_id));

-- certificates: student & guardian read own; staff read; admin issues
create policy certificates_select on public.certificates for select to authenticated using (
  student_id = auth.uid() or public.is_staff() or public.is_guardian_of(student_id)
);
create policy certificates_admin on public.certificates for all to authenticated
  using (public.is_admin()) with check (public.is_admin());


-- ████████████████████████████████████████████████████████████████████████
-- ██  supabase/migrations/0005_finance.sql
-- ████████████████████████████████████████████████████████████████████████

-- ============================================================================
-- Aurora Academy LMS  ·  0005 — Finance
-- ----------------------------------------------------------------------------
-- Subscription/tariff plans, invoices, payments (Payme · Click · Uzum ·
-- Telegram · cash), and discount codes with redemption tracking.
--
-- NOTE: payment-provider webhooks should run with the Supabase service_role
-- key, which bypasses RLS. The policies below govern end-user (authenticated)
-- access only. Money-writing operations are restricted to admins/managers.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- plans  ·  pricing tiers (Standart / Pro / Premium)
-- ---------------------------------------------------------------------------
create table public.plans (
  id          integer generated by default as identity primary key,
  slug        text not null unique,
  name        text not null,
  description text,
  price       numeric(12,2) not null default 0,
  period      billing_period not null default 'monthly',
  currency    text not null default 'UZS',
  features    text[] not null default '{}',
  cta_label   text,
  gradient    text,
  max_courses smallint,                    -- null = unlimited
  is_popular  boolean not null default false,
  is_active   boolean not null default true,
  position    smallint not null default 0,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
create trigger trg_plans_updated before update on public.plans
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- invoices
-- ---------------------------------------------------------------------------
create table public.invoices (
  id         uuid primary key default gen_random_uuid(),
  number     text not null unique,         -- human-facing invoice number
  student_id uuid not null references public.profiles(id) on delete cascade,
  course_id  uuid references public.courses(id) on delete set null,
  group_id   uuid references public.groups(id) on delete set null,
  plan_id    integer references public.plans(id) on delete set null,
  amount     numeric(12,2) not null,
  currency   text not null default 'UZS',
  status     invoice_status not null default 'pending',
  due_date   date,
  issued_at  timestamptz not null default now(),
  paid_at    timestamptz,
  meta       jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index idx_invoices_student on public.invoices(student_id);
create index idx_invoices_status  on public.invoices(status);
create trigger trg_invoices_updated before update on public.invoices
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- payments  ·  individual transactions against invoices
-- ---------------------------------------------------------------------------
create table public.payments (
  id              uuid primary key default gen_random_uuid(),
  invoice_id      uuid references public.invoices(id) on delete set null,
  student_id      uuid not null references public.profiles(id) on delete cascade,
  amount          numeric(12,2) not null,
  currency        text not null default 'UZS',
  provider        payment_provider not null,
  provider_txn_id text,
  status          payment_status not null default 'pending',
  paid_at         timestamptz,
  meta            jsonb not null default '{}',
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);
create index idx_payments_invoice on public.payments(invoice_id);
create index idx_payments_student on public.payments(student_id);
create index idx_payments_status  on public.payments(status);
create unique index uq_payments_provider_txn
  on public.payments(provider, provider_txn_id)
  where provider_txn_id is not null;
create trigger trg_payments_updated before update on public.payments
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- discounts  ·  promo / coupon codes
-- ---------------------------------------------------------------------------
create table public.discounts (
  id          uuid primary key default gen_random_uuid(),
  code        citext not null unique,
  description text,
  type        discount_type not null default 'percent',
  value       numeric(12,2) not null,       -- percent (0-100) or fixed amount
  max_uses    integer,                       -- null = unlimited
  used_count  integer not null default 0,
  course_id   uuid references public.courses(id) on delete cascade,
  valid_from  timestamptz,
  valid_to    timestamptz,
  is_active   boolean not null default true,
  created_at  timestamptz not null default now()
);
create index idx_discounts_active on public.discounts(is_active);

-- ---------------------------------------------------------------------------
-- discount_redemptions
-- ---------------------------------------------------------------------------
create table public.discount_redemptions (
  id          uuid primary key default gen_random_uuid(),
  discount_id uuid not null references public.discounts(id) on delete cascade,
  student_id  uuid not null references public.profiles(id) on delete cascade,
  invoice_id  uuid references public.invoices(id) on delete set null,
  amount      numeric(12,2),
  redeemed_at timestamptz not null default now(),
  unique (discount_id, student_id)
);
create index idx_redemptions_student on public.discount_redemptions(student_id);

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================
alter table public.plans                enable row level security;
alter table public.invoices             enable row level security;
alter table public.payments             enable row level security;
alter table public.discounts            enable row level security;
alter table public.discount_redemptions enable row level security;

-- plans: active plans are public (pricing page); admins manage
create policy plans_read  on public.plans for select using (is_active or public.is_staff());
create policy plans_admin on public.plans for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- invoices: student & guardian read own; admins/managers manage
create policy invoices_select on public.invoices for select to authenticated using (
  student_id = auth.uid() or public.is_guardian_of(student_id)
  or public.has_any_role(array['super_admin','admin','manager'])
);
create policy invoices_admin on public.invoices for all to authenticated
  using (public.has_any_role(array['super_admin','admin','manager']))
  with check (public.has_any_role(array['super_admin','admin','manager']));

-- payments: student & guardian read own; admins/managers manage (webhooks use service_role)
create policy payments_select on public.payments for select to authenticated using (
  student_id = auth.uid() or public.is_guardian_of(student_id)
  or public.has_any_role(array['super_admin','admin','manager'])
);
create policy payments_admin on public.payments for all to authenticated
  using (public.has_any_role(array['super_admin','admin','manager']))
  with check (public.has_any_role(array['super_admin','admin','manager']));

-- discounts: staff-only visibility (codes are validated server-side); admin manage
create policy discounts_staff on public.discounts for select to authenticated using (public.is_staff());
create policy discounts_admin on public.discounts for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- discount_redemptions: student reads own; staff read; admins/managers manage
create policy redemptions_select on public.discount_redemptions for select to authenticated using (
  student_id = auth.uid() or public.has_any_role(array['super_admin','admin','manager'])
);
create policy redemptions_admin on public.discount_redemptions for all to authenticated
  using (public.has_any_role(array['super_admin','admin','manager']))
  with check (public.has_any_role(array['super_admin','admin','manager']));


-- ████████████████████████████████████████████████████████████████████████
-- ██  supabase/migrations/0006_communication.sql
-- ████████████████████████████████████████████████████████████████████████

-- ============================================================================
-- Aurora Academy LMS  ·  0006 — Communication
-- ----------------------------------------------------------------------------
-- In-app notifications (+ per-user channel preferences), direct & group
-- messaging (conversations → participants → messages), and scoped
-- announcements (global / branch / course / group).
--
-- NOTE: notifications are normally written server-side (service_role, which
-- bypasses RLS) by triggers/edge functions. The policies below let end users
-- read and acknowledge (mark-read) their own rows; staff get broader access.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- notifications
-- ---------------------------------------------------------------------------
create table public.notifications (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles(id) on delete cascade,
  type       notification_type not null default 'system',
  channel    notification_channel not null default 'in_app',
  title      text not null,
  body       text,
  link       text,                          -- in-app deep link (e.g. /student/grades)
  data       jsonb not null default '{}',   -- arbitrary payload for the client
  is_read    boolean not null default false,
  read_at    timestamptz,
  created_at timestamptz not null default now()
);
create index idx_notifications_user    on public.notifications(user_id);
create index idx_notifications_unread  on public.notifications(user_id) where not is_read;
create index idx_notifications_created on public.notifications(created_at);

-- ---------------------------------------------------------------------------
-- notification_preferences  ·  one row per user; channel toggles + per-type overrides
-- ---------------------------------------------------------------------------
create table public.notification_preferences (
  user_id        uuid primary key references public.profiles(id) on delete cascade,
  in_app_enabled boolean not null default true,
  email_enabled  boolean not null default true,
  sms_enabled    boolean not null default false,
  telegram_enabled boolean not null default false,
  push_enabled   boolean not null default true,
  -- per-notification-type overrides, e.g. {"payment":{"sms":true},"message":{"email":false}}
  type_overrides jsonb not null default '{}',
  quiet_from     time,                      -- optional do-not-disturb window
  quiet_to       time,
  updated_at     timestamptz not null default now()
);
create trigger trg_notif_prefs_updated before update on public.notification_preferences
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- conversations  ·  direct (1:1) or group threads
-- ---------------------------------------------------------------------------
create table public.conversations (
  id              uuid primary key default gen_random_uuid(),
  type            conversation_type not null default 'direct',
  title           text,                     -- group title (null for direct)
  course_id       uuid references public.courses(id) on delete set null,
  group_id        uuid references public.groups(id) on delete set null,
  created_by      uuid references public.profiles(id) on delete set null,
  last_message_at timestamptz,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);
create index idx_conversations_group  on public.conversations(group_id);
create index idx_conversations_last   on public.conversations(last_message_at desc);
create trigger trg_conversations_updated before update on public.conversations
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- conversation_participants
-- ---------------------------------------------------------------------------
create table public.conversation_participants (
  id              uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  user_id         uuid not null references public.profiles(id) on delete cascade,
  is_admin        boolean not null default false,   -- can rename / add / remove
  last_read_at    timestamptz,
  muted           boolean not null default false,
  joined_at       timestamptz not null default now(),
  unique (conversation_id, user_id)
);
create index idx_participants_user on public.conversation_participants(user_id);
create index idx_participants_conv on public.conversation_participants(conversation_id);

-- ---------------------------------------------------------------------------
-- messages
-- ---------------------------------------------------------------------------
create table public.messages (
  id              uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_id       uuid references public.profiles(id) on delete set null,
  body            text,
  attachments     jsonb not null default '[]',   -- [{url,name,type,size}]
  reply_to_id     uuid references public.messages(id) on delete set null,
  edited_at       timestamptz,
  deleted_at      timestamptz,                    -- soft delete
  created_at      timestamptz not null default now()
);
create index idx_messages_conversation on public.messages(conversation_id, created_at);
create index idx_messages_sender       on public.messages(sender_id);

-- ---------------------------------------------------------------------------
-- announcements  ·  one-way broadcasts scoped to an audience
-- ---------------------------------------------------------------------------
create table public.announcements (
  id           uuid primary key default gen_random_uuid(),
  scope        announcement_scope not null default 'global',
  branch_id    uuid references public.branches(id) on delete cascade,
  course_id    uuid references public.courses(id) on delete cascade,
  group_id     uuid references public.groups(id) on delete cascade,
  title        text not null,
  body         text,
  author_id    uuid references public.profiles(id) on delete set null,
  is_pinned    boolean not null default false,
  is_published boolean not null default true,
  published_at timestamptz not null default now(),
  expires_at   timestamptz,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);
create index idx_announcements_scope     on public.announcements(scope);
create index idx_announcements_course    on public.announcements(course_id);
create index idx_announcements_group     on public.announcements(group_id);
create index idx_announcements_published on public.announcements(published_at desc);
create trigger trg_announcements_updated before update on public.announcements
  for each row execute function public.set_updated_at();

-- ============================================================================
-- RLS HELPERS specific to communication
-- ============================================================================

-- Is the current user a participant of the given conversation?
-- SECURITY DEFINER so policies can call it WITHOUT re-triggering RLS on
-- conversation_participants (which would cause infinite-recursion errors).
create or replace function public.in_conversation(p_conversation uuid)
returns boolean
language sql stable security definer
set search_path = public
as $$
  select exists (
    select 1 from public.conversation_participants cp
    where cp.conversation_id = p_conversation and cp.user_id = auth.uid()
  );
$$;

-- Is the current user an admin of the given conversation? Same recursion-safe
-- pattern: used by policies on conversations & conversation_participants.
create or replace function public.is_conversation_admin(p_conversation uuid)
returns boolean
language sql stable security definer
set search_path = public
as $$
  select exists (
    select 1 from public.conversation_participants cp
    where cp.conversation_id = p_conversation and cp.user_id = auth.uid() and cp.is_admin
  );
$$;

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================
alter table public.notifications              enable row level security;
alter table public.notification_preferences   enable row level security;
alter table public.conversations              enable row level security;
alter table public.conversation_participants  enable row level security;
alter table public.messages                   enable row level security;
alter table public.announcements              enable row level security;

-- notifications: user reads & acknowledges own; admins manage. (System writes
-- via service_role.) Update is restricted to is_read/read_at by the app layer.
create policy notifications_select on public.notifications for select to authenticated
  using (user_id = auth.uid() or public.is_admin());
create policy notifications_update_self on public.notifications for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy notifications_delete_self on public.notifications for delete to authenticated
  using (user_id = auth.uid() or public.is_admin());
create policy notifications_admin on public.notifications for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- notification_preferences: each user owns their single row; admins may read.
create policy notif_prefs_select on public.notification_preferences for select to authenticated
  using (user_id = auth.uid() or public.is_admin());
create policy notif_prefs_write on public.notification_preferences for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- conversations: participants read; staff read; creator/participant-admin manage.
create policy conversations_select on public.conversations for select to authenticated
  using (public.in_conversation(id) or public.is_staff());
create policy conversations_insert on public.conversations for insert to authenticated
  with check (created_by = auth.uid() or public.is_staff());
create policy conversations_update on public.conversations for update to authenticated
  using (public.is_admin() or public.is_conversation_admin(id))
  with check (public.is_admin() or public.is_conversation_admin(id));

-- conversation_participants: a user sees rows for conversations they belong to;
-- conversation-admins (and platform admins) add/remove; users update their own
-- row (last_read_at, muted) and may leave (delete self).
create policy participants_select on public.conversation_participants for select to authenticated
  using (public.in_conversation(conversation_id) or public.is_staff());
create policy participants_self_update on public.conversation_participants for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy participants_self_leave on public.conversation_participants for delete to authenticated
  using (user_id = auth.uid() or public.is_admin());
create policy participants_admin_manage on public.conversation_participants for all to authenticated
  using (public.is_admin() or public.is_conversation_admin(conversation_id))
  with check (public.is_admin() or public.is_conversation_admin(conversation_id));

-- messages: only participants read; sender writes their own; sender edits/deletes own.
create policy messages_select on public.messages for select to authenticated
  using (public.in_conversation(conversation_id) or public.is_admin());
create policy messages_insert on public.messages for insert to authenticated
  with check (sender_id = auth.uid() and public.in_conversation(conversation_id));
create policy messages_update_own on public.messages for update to authenticated
  using (sender_id = auth.uid()) with check (sender_id = auth.uid());
create policy messages_delete on public.messages for delete to authenticated
  using (sender_id = auth.uid() or public.is_admin());

-- announcements: visibility follows scope; staff/teachers author within their reach.
create policy announcements_select on public.announcements for select to authenticated using (
  is_published and (
    public.is_staff()
    or scope = 'global'
    or (scope = 'branch'  and exists (select 1 from public.profiles p where p.id = auth.uid() and p.branch_id = announcements.branch_id))
    or (scope = 'course'  and (public.is_enrolled(course_id) or public.teaches_course(course_id)))
    or (scope = 'group'   and (
          public.teaches_group(group_id)
          or exists (select 1 from public.enrollments e where e.group_id = announcements.group_id and e.student_id = auth.uid())
        ))
  )
);
-- managers/admins author any; teachers may author for courses/groups they teach.
create policy announcements_admin on public.announcements for all to authenticated
  using (
    public.has_any_role(array['super_admin','admin','manager'])
    or (scope = 'course' and public.teaches_course(course_id))
    or (scope = 'group'  and public.teaches_group(group_id))
  )
  with check (
    public.has_any_role(array['super_admin','admin','manager'])
    or (scope = 'course' and public.teaches_course(course_id))
    or (scope = 'group'  and public.teaches_group(group_id))
  );


-- ████████████████████████████████████████████████████████████████████████
-- ██  supabase/migrations/0007_gamification.sql
-- ████████████████████████████████████████████████████████████████████████

-- ============================================================================
-- Aurora Academy LMS  ·  0007 — Gamification
-- ----------------------------------------------------------------------------
-- Levels (XP thresholds), achievements & per-user unlocks, and an append-only
-- XP/coin ledger. Aggregate counters (xp, coins, level, streaks) live on
-- public.student_profiles (migration 0002); this layer is the source of truth
-- and audit trail behind those counters.
--
-- NOTE: awarding XP / unlocking achievements is done server-side (triggers,
-- edge functions, or SECURITY DEFINER RPCs running as service_role). End users
-- get read-only access to their own progress; admins manage definitions.
-- ============================================================================

-- Gamification-local enums (kept here so 0001 stays domain-agnostic).
create type achievement_category as enum ('learning', 'streak', 'social', 'milestone', 'special');
create type achievement_rarity   as enum ('common', 'rare', 'epic', 'legendary');
create type xp_reason            as enum ('lesson', 'assignment', 'test', 'streak', 'achievement', 'enrollment', 'bonus', 'manual', 'penalty');

-- ---------------------------------------------------------------------------
-- levels  ·  XP thresholds & titles (reference data)
-- ---------------------------------------------------------------------------
create table public.levels (
  level      smallint primary key,
  min_xp     integer not null,             -- cumulative XP required to reach this level
  title      text not null,
  perks      text[] not null default '{}',
  badge      text,                          -- emoji / icon key
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- achievements  ·  badge definitions
-- ---------------------------------------------------------------------------
create table public.achievements (
  id          uuid primary key default gen_random_uuid(),
  code        text not null unique,         -- machine key, used by award logic
  name        text not null,
  description text,
  icon        text,                          -- emoji / icon key
  category    achievement_category not null default 'milestone',
  rarity      achievement_rarity   not null default 'common',
  xp_reward   integer not null default 0,
  coin_reward integer not null default 0,
  criteria    jsonb   not null default '{}', -- machine-readable unlock rule
  is_active   boolean not null default true,
  is_secret   boolean not null default false,
  position    smallint not null default 0,
  created_at  timestamptz not null default now()
);
create index idx_achievements_active on public.achievements(is_active);

-- ---------------------------------------------------------------------------
-- user_achievements  ·  unlocks & progress
-- ---------------------------------------------------------------------------
create table public.user_achievements (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null references public.profiles(id) on delete cascade,
  achievement_id uuid not null references public.achievements(id) on delete cascade,
  progress       numeric(5,2) not null default 100 check (progress between 0 and 100),
  is_unlocked    boolean not null default true,
  unlocked_at    timestamptz not null default now(),
  unique (user_id, achievement_id)
);
create index idx_user_achievements_user on public.user_achievements(user_id);

-- ---------------------------------------------------------------------------
-- xp_ledger  ·  append-only XP & coin movements (audit trail behind counters)
-- ---------------------------------------------------------------------------
create table public.xp_ledger (
  id          bigint generated by default as identity primary key,
  user_id     uuid not null references public.profiles(id) on delete cascade,
  reason      xp_reason not null default 'manual',
  xp_delta    integer not null default 0,
  coin_delta  integer not null default 0,
  source_type text,                          -- 'lesson' | 'assignment' | 'test' | 'achievement' | ...
  source_id   uuid,
  note        text,
  awarded_by  uuid references public.profiles(id) on delete set null,
  created_at  timestamptz not null default now()
);
create index idx_xp_ledger_user    on public.xp_ledger(user_id);
create index idx_xp_ledger_created on public.xp_ledger(created_at);

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================
alter table public.levels            enable row level security;
alter table public.achievements      enable row level security;
alter table public.user_achievements enable row level security;
alter table public.xp_ledger         enable row level security;

-- levels & achievements: public catalog (powers profile/marketing UI); admin writes.
create policy levels_read  on public.levels for select using (true);
create policy levels_admin on public.levels for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- secret achievements are hidden until the viewer has unlocked them (or is staff).
create policy achievements_read on public.achievements for select using (
  (is_active and not is_secret)
  or public.is_staff()
  or exists (
    select 1 from public.user_achievements ua
    where ua.achievement_id = achievements.id and ua.user_id = auth.uid()
  )
);
create policy achievements_admin on public.achievements for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- user_achievements: user & guardian & staff read; admin manages (awards via service_role).
create policy user_achievements_select on public.user_achievements for select to authenticated using (
  user_id = auth.uid() or public.is_staff() or public.is_guardian_of(user_id)
);
create policy user_achievements_admin on public.user_achievements for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- xp_ledger: user & guardian & staff read; admin manages (awards via service_role).
create policy xp_ledger_select on public.xp_ledger for select to authenticated using (
  user_id = auth.uid() or public.is_staff() or public.is_guardian_of(user_id)
);
create policy xp_ledger_admin on public.xp_ledger for all to authenticated
  using (public.is_admin()) with check (public.is_admin());


-- ████████████████████████████████████████████████████████████████████████
-- ██  supabase/migrations/0008_system_cms.sql
-- ████████████████████████████████████████████████████████████████████████

-- ============================================================================
-- Aurora Academy LMS  ·  0008 — System & CMS
-- ----------------------------------------------------------------------------
-- Blog/CMS (categories → posts), key-value settings (feature flags folded in
-- here), an app-level file registry, third-party integrations, lead capture
-- (contact messages & course applications), and an append-only audit log.
--
-- NOTE: integration secrets do NOT live here — store API keys/tokens in
-- Supabase Vault. The `config` column holds non-secret configuration only.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- blog_categories
-- ---------------------------------------------------------------------------
create table public.blog_categories (
  id         integer generated by default as identity primary key,
  slug       text not null unique,
  name       text not null,
  position   smallint not null default 0,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- blog_posts
-- ---------------------------------------------------------------------------
create table public.blog_posts (
  id             uuid primary key default gen_random_uuid(),
  slug           text not null unique,
  title          text not null,
  excerpt        text,
  body           text,
  category_id    integer references public.blog_categories(id) on delete set null,
  author_id      uuid references public.profiles(id) on delete set null,
  cover_gradient text,
  cover_emoji    text,
  read_time_min  smallint,
  tags           text[] not null default '{}',
  status         post_status not null default 'draft',
  views_count    integer not null default 0,
  published_at   timestamptz,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);
create index idx_blog_posts_status    on public.blog_posts(status);
create index idx_blog_posts_category  on public.blog_posts(category_id);
create index idx_blog_posts_published on public.blog_posts(published_at desc);
create index idx_blog_posts_title_trgm on public.blog_posts using gin (title gin_trgm_ops);
create trigger trg_blog_posts_updated before update on public.blog_posts
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- settings  ·  key-value app config; feature flags live here (group = 'features')
-- ---------------------------------------------------------------------------
create table public.settings (
  key         text primary key,             -- e.g. 'site.title', 'features.ai_tutor'
  value       jsonb not null default '{}',
  group_name  text not null default 'general',
  description text,
  is_public   boolean not null default false,  -- public settings readable anonymously
  updated_by  uuid references public.profiles(id) on delete set null,
  updated_at  timestamptz not null default now()
);
create index idx_settings_group on public.settings(group_name);
create trigger trg_settings_updated before update on public.settings
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- files  ·  app-level metadata for objects stored in Supabase Storage
-- ---------------------------------------------------------------------------
create table public.files (
  id         uuid primary key default gen_random_uuid(),
  owner_id   uuid references public.profiles(id) on delete set null,
  bucket     text not null default 'public',
  path       text not null,                 -- storage object path
  url        text,
  name       text,
  mime_type  text,
  size_bytes bigint,
  kind       text,                          -- 'avatar' | 'material' | 'submission' | 'certificate' | 'blog' | ...
  is_public  boolean not null default false,
  created_at timestamptz not null default now()
);
create index idx_files_owner on public.files(owner_id);
create index idx_files_kind  on public.files(kind);

-- ---------------------------------------------------------------------------
-- integrations  ·  third-party connections (Payme, Click, Zoom, Telegram, ...)
-- ---------------------------------------------------------------------------
create table public.integrations (
  id           integer generated by default as identity primary key,
  provider     integration_provider not null unique,
  name         text not null,
  status       integration_status not null default 'disconnected',
  is_enabled   boolean not null default false,
  config       jsonb not null default '{}', -- NON-SECRET config only (secrets → Vault)
  last_sync_at timestamptz,
  connected_at timestamptz,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);
create trigger trg_integrations_updated before update on public.integrations
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- contact_messages  ·  public "contact us" form submissions (lead capture)
-- ---------------------------------------------------------------------------
create table public.contact_messages (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  email       citext,
  phone       text,
  subject     text,
  message     text not null,
  source      text,                          -- which page/form
  status      text not null default 'new',   -- new | read | replied | archived
  handled_by  uuid references public.profiles(id) on delete set null,
  created_at  timestamptz not null default now()
);
create index idx_contact_messages_status on public.contact_messages(status);

-- ---------------------------------------------------------------------------
-- course_applications  ·  prospective-student applications (admin "Applications")
-- ---------------------------------------------------------------------------
create table public.course_applications (
  id          uuid primary key default gen_random_uuid(),
  course_id   uuid references public.courses(id) on delete set null,
  branch_id   uuid references public.branches(id) on delete set null,
  full_name   text not null,
  phone       text not null,
  email       citext,
  message     text,
  status      text not null default 'new',   -- new | contacted | enrolled | rejected
  assigned_to uuid references public.profiles(id) on delete set null,
  student_id  uuid references public.profiles(id) on delete set null,  -- set once enrolled
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
create index idx_course_applications_status on public.course_applications(status);
create index idx_course_applications_course on public.course_applications(course_id);
create trigger trg_course_applications_updated before update on public.course_applications
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- audit_logs  ·  append-only record of sensitive actions
-- ---------------------------------------------------------------------------
create table public.audit_logs (
  id          bigint generated by default as identity primary key,
  actor_id    uuid references public.profiles(id) on delete set null,
  action      text not null,                 -- 'create' | 'update' | 'delete' | 'login' | ...
  entity_type text,                          -- 'invoice' | 'enrollment' | 'profile' | ...
  entity_id   text,                          -- uuid/int as text (heterogeneous keys)
  summary     text,
  diff        jsonb,                         -- {before, after}
  ip          inet,
  user_agent  text,
  created_at  timestamptz not null default now()
);
create index idx_audit_actor   on public.audit_logs(actor_id);
create index idx_audit_entity  on public.audit_logs(entity_type, entity_id);
create index idx_audit_created on public.audit_logs(created_at);

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================
alter table public.blog_categories      enable row level security;
alter table public.blog_posts           enable row level security;
alter table public.settings             enable row level security;
alter table public.files                enable row level security;
alter table public.integrations         enable row level security;
alter table public.contact_messages     enable row level security;
alter table public.course_applications  enable row level security;
alter table public.audit_logs           enable row level security;

-- blog: published content is public; categories public; staff author, admin manage.
create policy blog_categories_read  on public.blog_categories for select using (true);
create policy blog_categories_admin on public.blog_categories for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

create policy blog_posts_read on public.blog_posts for select
  using (status = 'published' or public.is_staff());
create policy blog_posts_admin on public.blog_posts for all to authenticated
  using (public.is_admin() or author_id = auth.uid())
  with check (public.is_admin() or author_id = auth.uid());

-- settings: public flag exposes to anon (e.g. site title, enabled features); admin writes.
create policy settings_read_public on public.settings for select
  using (is_public or public.is_staff());
create policy settings_admin on public.settings for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- files: owner & staff read; public files readable by anyone; owner/admin write.
create policy files_select on public.files for select
  using (is_public or owner_id = auth.uid() or public.is_staff());
create policy files_owner_write on public.files for all to authenticated
  using (owner_id = auth.uid() or public.is_admin())
  with check (owner_id = auth.uid() or public.is_admin());

-- integrations: admin-only (configuration surface).
create policy integrations_admin on public.integrations for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- contact_messages: anyone (incl. anonymous) may submit; staff read; admin manage.
create policy contact_messages_insert on public.contact_messages for insert to anon, authenticated
  with check (true);
create policy contact_messages_select on public.contact_messages for select to authenticated
  using (public.is_staff());
create policy contact_messages_admin on public.contact_messages for all to authenticated
  using (public.has_any_role(array['super_admin','admin','manager']))
  with check (public.has_any_role(array['super_admin','admin','manager']));

-- course_applications: anyone may apply; staff read; managers/admins manage.
create policy course_applications_insert on public.course_applications for insert to anon, authenticated
  with check (true);
create policy course_applications_select on public.course_applications for select to authenticated
  using (public.is_staff());
create policy course_applications_admin on public.course_applications for all to authenticated
  using (public.has_any_role(array['super_admin','admin','manager']))
  with check (public.has_any_role(array['super_admin','admin','manager']));

-- audit_logs: admins read; no client writes (written by service_role / triggers).
create policy audit_logs_admin_read on public.audit_logs for select to authenticated
  using (public.is_admin());


-- ████████████████████████████████████████████████████████████████████████
-- ██  supabase/seed.sql  (demo ma'lumot)
-- ████████████████████████████████████████████████████████████████████████

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
