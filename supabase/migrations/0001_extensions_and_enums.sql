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
