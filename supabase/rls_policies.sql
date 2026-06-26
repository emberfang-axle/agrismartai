-- ============================================================================
-- AgriSmartAI :: Row Level Security (RLS) Policies
-- ----------------------------------------------------------------------------
-- Farmers   -> can only read/write their OWN scans, reports & evaluations.
-- Technician -> can read everything + verify reports.
-- Admin     -> full access (OBJECTIVE 4: admin dashboard).
-- ============================================================================

-- Helper: is the current user an admin or technician? -------------------------
create or replace function public.is_staff()
returns boolean
language sql
stable
security definer set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid()
      and role in ('admin', 'technician')
  );
$$;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
$$;

-- ----------------------------------------------------------------------------
-- Enable RLS
-- ----------------------------------------------------------------------------
alter table public.profiles      enable row level security;
alter table public.diseases      enable row level security;
alter table public.scans         enable row level security;
alter table public.reports       enable row level security;
alter table public.evaluations   enable row level security;
alter table public.chat_messages enable row level security;
alter table public.activity_logs enable row level security;

-- ----------------------------------------------------------------------------
-- PROFILES
-- ----------------------------------------------------------------------------
drop policy if exists "profiles_select_self_or_staff" on public.profiles;
create policy "profiles_select_self_or_staff" on public.profiles
  for select using (id = auth.uid() or public.is_staff());

drop policy if exists "profiles_insert_self" on public.profiles;
create policy "profiles_insert_self" on public.profiles
  for insert with check (id = auth.uid());

drop policy if exists "profiles_update_self_or_admin" on public.profiles;
create policy "profiles_update_self_or_admin" on public.profiles
  for update using (id = auth.uid() or public.is_admin())
  with check (id = auth.uid() or public.is_admin());

-- ----------------------------------------------------------------------------
-- DISEASES  (public knowledge base — readable by everyone, writable by admin)
-- ----------------------------------------------------------------------------
drop policy if exists "diseases_select_all" on public.diseases;
create policy "diseases_select_all" on public.diseases
  for select using (true);

drop policy if exists "diseases_write_admin" on public.diseases;
create policy "diseases_write_admin" on public.diseases
  for all using (public.is_admin()) with check (public.is_admin());

-- ----------------------------------------------------------------------------
-- SCANS
-- ----------------------------------------------------------------------------
drop policy if exists "scans_select_own_or_staff" on public.scans;
create policy "scans_select_own_or_staff" on public.scans
  for select using (user_id = auth.uid() or public.is_staff());

drop policy if exists "scans_insert_own" on public.scans;
create policy "scans_insert_own" on public.scans
  for insert with check (user_id = auth.uid());

drop policy if exists "scans_update_own_or_staff" on public.scans;
create policy "scans_update_own_or_staff" on public.scans
  for update using (user_id = auth.uid() or public.is_staff());

drop policy if exists "scans_delete_own_or_admin" on public.scans;
create policy "scans_delete_own_or_admin" on public.scans
  for delete using (user_id = auth.uid() or public.is_admin());

-- ----------------------------------------------------------------------------
-- REPORTS  (OBJECTIVE 4: only staff verify; farmers see their own)
-- ----------------------------------------------------------------------------
drop policy if exists "reports_select_own_or_staff" on public.reports;
create policy "reports_select_own_or_staff" on public.reports
  for select using (farmer_id = auth.uid() or public.is_staff());

drop policy if exists "reports_insert_own" on public.reports;
create policy "reports_insert_own" on public.reports
  for insert with check (farmer_id = auth.uid());

drop policy if exists "reports_insert_staff" on public.reports;
create policy "reports_insert_staff" on public.reports
  for insert with check (public.is_staff());

drop policy if exists "reports_update_staff" on public.reports;
create policy "reports_update_staff" on public.reports
  for update using (public.is_staff()) with check (public.is_staff());

-- ----------------------------------------------------------------------------
-- EVALUATIONS  (OBJECTIVE 4: farmers submit, staff read)
-- ----------------------------------------------------------------------------
drop policy if exists "evaluations_select_own_or_staff" on public.evaluations;
create policy "evaluations_select_own_or_staff" on public.evaluations
  for select using (user_id = auth.uid() or public.is_staff());

drop policy if exists "evaluations_insert_own" on public.evaluations;
create policy "evaluations_insert_own" on public.evaluations
  for insert with check (user_id = auth.uid());

-- ----------------------------------------------------------------------------
-- CHAT MESSAGES  (private to each user)
-- ----------------------------------------------------------------------------
drop policy if exists "chat_select_own" on public.chat_messages;
create policy "chat_select_own" on public.chat_messages
  for select using (user_id = auth.uid());

drop policy if exists "chat_insert_own" on public.chat_messages;
create policy "chat_insert_own" on public.chat_messages
  for insert with check (user_id = auth.uid());

-- ----------------------------------------------------------------------------
-- ACTIVITY LOGS  (staff read; authenticated users can append their own actions)
-- ----------------------------------------------------------------------------
drop policy if exists "activity_logs_select_staff" on public.activity_logs;
create policy "activity_logs_select_staff" on public.activity_logs
  for select using (public.is_staff());

drop policy if exists "activity_logs_insert_authenticated" on public.activity_logs;
create policy "activity_logs_insert_own" on public.activity_logs
  for insert with check (user_id = auth.uid() or public.is_staff());

-- ----------------------------------------------------------------------------
-- STORAGE policies for scan-images bucket (OBJECTIVE 1)
-- ----------------------------------------------------------------------------
drop policy if exists "scan_images_read" on storage.objects;
create policy "scan_images_read" on storage.objects
  for select using (bucket_id = 'scan-images');

drop policy if exists "scan_images_upload" on storage.objects;
create policy "scan_images_upload" on storage.objects
  for insert with check (bucket_id = 'scan-images' and auth.role() = 'authenticated');

drop policy if exists "scan_images_update_own" on storage.objects;
create policy "scan_images_update_own" on storage.objects
  for update using (bucket_id = 'scan-images' and owner = auth.uid());

drop policy if exists "scan_images_delete_own" on storage.objects;
create policy "scan_images_delete_own" on storage.objects
  for delete using (
    bucket_id = 'scan-images'
    and (owner = auth.uid() or public.is_admin())
  );
