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
