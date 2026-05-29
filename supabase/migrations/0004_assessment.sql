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
