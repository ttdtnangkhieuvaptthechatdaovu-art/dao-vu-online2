-- ĐẠO VŨ KARATE ONLINE: chạy toàn bộ SQL này trong Supabase SQL Editor.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  role text not null default 'parent' check (role in ('admin','coach','parent')),
  created_at timestamptz not null default now()
);
create table if not exists public.students (
  id uuid primary key default gen_random_uuid(),
  student_code text not null unique,
  full_name text not null,
  belt_rank text not null default 'Trắng',
  class_name text not null default 'Lớp cơ bản',
  monthly_fee integer not null default 500000 check (monthly_fee >= 0),
  class_fund integer not null default 50000 check (class_fund >= 0),
  parent_name text,
  parent_email text,
  phone text,
  status text not null default 'Đang học',
  created_at timestamptz not null default now()
);
create table if not exists public.parent_students (
  parent_id uuid not null references auth.users(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  primary key(parent_id, student_id)
);
create table if not exists public.attendance (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students(id) on delete cascade,
  attendance_date date not null default current_date,
  status text not null check (status in ('Có mặt','Vắng','Có phép','Muộn')),
  note text,
  coach_id uuid references auth.users(id),
  created_at timestamptz not null default now(),
  unique(student_id, attendance_date)
);
create table if not exists public.monthly_fees (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students(id) on delete cascade,
  fee_month text not null,
  tuition_amount integer not null default 0,
  fund_amount integer not null default 0,
  paid_amount integer not null default 0,
  status text not null default 'Chưa thanh toán',
  paid_at timestamptz,
  created_at timestamptz not null default now(),
  unique(student_id, fee_month)
);
create table if not exists public.announcements (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  content text not null,
  category text not null default 'Thông báo chung',
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);
create table if not exists public.coach_reviews (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students(id) on delete cascade,
  coach_id uuid references auth.users(id),
  review_month text not null,
  technical_comment text not null,
  discipline_comment text,
  created_at timestamptz not null default now()
);

create or replace function public.current_role() returns text language sql stable security definer set search_path=public as $$
  select role from public.profiles where id=auth.uid();
$$;
create or replace function public.is_admin_or_coach() returns boolean language sql stable security definer set search_path=public as $$
  select coalesce(public.current_role() in ('admin','coach'),false);
$$;

alter table public.profiles enable row level security;
alter table public.students enable row level security;
alter table public.parent_students enable row level security;
alter table public.attendance enable row level security;
alter table public.monthly_fees enable row level security;
alter table public.announcements enable row level security;
alter table public.coach_reviews enable row level security;

DROP POLICY IF EXISTS "profile self or admin read" ON public.profiles;
create policy "profile self or admin read" on public.profiles for select to authenticated using (id=auth.uid() or public.current_role()='admin');
DROP POLICY IF EXISTS "admin manage profiles" ON public.profiles;
create policy "admin manage profiles" on public.profiles for all to authenticated using (public.current_role()='admin') with check (public.current_role()='admin');
DROP POLICY IF EXISTS "staff manage students" ON public.students;
create policy "staff manage students" on public.students for all to authenticated using (public.is_admin_or_coach()) with check (public.is_admin_or_coach());
DROP POLICY IF EXISTS "parent read linked students" ON public.students;
create policy "parent read linked students" on public.students for select to authenticated using (exists(select 1 from public.parent_students ps where ps.student_id=students.id and ps.parent_id=auth.uid()));
DROP POLICY IF EXISTS "staff manage parent links" ON public.parent_students;
create policy "staff manage parent links" on public.parent_students for all to authenticated using (public.current_role()='admin') with check (public.current_role()='admin');
DROP POLICY IF EXISTS "parent read own links" ON public.parent_students;
create policy "parent read own links" on public.parent_students for select to authenticated using (parent_id=auth.uid());
DROP POLICY IF EXISTS "staff manage attendance" ON public.attendance;
create policy "staff manage attendance" on public.attendance for all to authenticated using (public.is_admin_or_coach()) with check (public.is_admin_or_coach());
DROP POLICY IF EXISTS "parent read linked attendance" ON public.attendance;
create policy "parent read linked attendance" on public.attendance for select to authenticated using (exists(select 1 from public.parent_students ps where ps.student_id=attendance.student_id and ps.parent_id=auth.uid()));
DROP POLICY IF EXISTS "admin manage fees" ON public.monthly_fees;
create policy "admin manage fees" on public.monthly_fees for all to authenticated using (public.current_role()='admin') with check (public.current_role()='admin');
DROP POLICY IF EXISTS "parent read linked fees" ON public.monthly_fees;
create policy "parent read linked fees" on public.monthly_fees for select to authenticated using (exists(select 1 from public.parent_students ps where ps.student_id=monthly_fees.student_id and ps.parent_id=auth.uid()));
DROP POLICY IF EXISTS "authenticated read announcements" ON public.announcements;
create policy "authenticated read announcements" on public.announcements for select to authenticated using (true);
DROP POLICY IF EXISTS "admin manage announcements" ON public.announcements;
create policy "admin manage announcements" on public.announcements for all to authenticated using (public.current_role()='admin') with check (public.current_role()='admin');
DROP POLICY IF EXISTS "staff manage reviews" ON public.coach_reviews;
create policy "staff manage reviews" on public.coach_reviews for all to authenticated using (public.is_admin_or_coach()) with check (public.is_admin_or_coach());
DROP POLICY IF EXISTS "parent read linked reviews" ON public.coach_reviews;
create policy "parent read linked reviews" on public.coach_reviews for select to authenticated using (exists(select 1 from public.parent_students ps where ps.student_id=coach_reviews.student_id and ps.parent_id=auth.uid()));

-- Tạo profile cho người dùng mới: mặc định là phụ huynh; Admin cần nâng role thủ công trong SQL Editor.
create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path=public as $$
begin
  insert into public.profiles(id,full_name,role) values(new.id,coalesce(new.raw_user_meta_data->>'full_name',''),'parent');
  return new;
end; $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();

-- Sau khi đăng ký tài khoản quản trị đầu tiên, chạy câu lệnh dưới đây với email thực tế:
-- update public.profiles set role='admin' where id=(select id from auth.users where email='admin@example.com');


-- BANG DU LIEU DONG BO CUA UNG DUNG HTML
-- ĐẠO VŨ KARATE ONLINE
-- Chạy file này trong Supabase > SQL Editor > New query > Run.
-- Điều kiện: đã tạo bảng public.profiles theo schema_fixed.sql / schema.sql trước đó.

create table if not exists public.app_state (
  user_id uuid primary key references auth.users(id) on delete cascade,
  payload jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

alter table public.app_state enable row level security;

drop policy if exists "app_state_select_own" on public.app_state;
drop policy if exists "app_state_insert_own" on public.app_state;
drop policy if exists "app_state_update_own" on public.app_state;
drop policy if exists "app_state_delete_own" on public.app_state;

create policy "app_state_select_own"
  on public.app_state for select to authenticated
  using (user_id = auth.uid());

create policy "app_state_insert_own"
  on public.app_state for insert to authenticated
  with check (user_id = auth.uid());

create policy "app_state_update_own"
  on public.app_state for update to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy "app_state_delete_own"
  on public.app_state for delete to authenticated
  using (user_id = auth.uid());

grant select, insert, update, delete on public.app_state to authenticated;

-- Sau khi tạo tài khoản quản lý trong Authentication > Users,
-- thay email bên dưới bằng email thật rồi chạy riêng câu UPDATE:
-- update public.profiles
-- set role = 'admin'
-- where id = (select id from auth.users where email = 'EMAIL_QUAN_LY_CUA_BAN');
