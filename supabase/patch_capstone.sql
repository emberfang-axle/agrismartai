-- ============================================================================
-- AgriSmartAI :: Capstone patch (run after schema.sql + rls_policies.sql)
-- Safe to re-run — uses IF NOT EXISTS / OR REPLACE / DROP IF EXISTS.
-- ============================================================================

-- Ensure scan-images bucket exists (public read for thumbnails)
insert into storage.buckets (id, name, public)
values ('scan-images', 'scan-images', true)
on conflict (id) do update set public = true;

-- One report row per scan (admin verify upsert)
create unique index if not exists idx_reports_scan_id on public.reports (scan_id);

-- Backfill disease_id on scans when disease_code matches catalog
update public.scans s
set disease_id = d.id
from public.diseases d
where s.disease_id is null
  and s.disease_code = d.code;

-- Auto-set disease_id on insert/update
create or replace function public.set_scan_disease_id()
returns trigger
language plpgsql
as $$
begin
  if new.disease_id is null and new.disease_code is not null then
    select id into new.disease_id
    from public.diseases
    where code = new.disease_code
    limit 1;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_scans_disease_id on public.scans;
create trigger trg_scans_disease_id
  before insert or update of disease_code on public.scans
  for each row execute function public.set_scan_disease_id();

-- Auto-create pending report when a farmer scan is saved
create or replace function public.create_pending_report()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.reports (scan_id, farmer_id, status)
  values (new.id, new.user_id, 'pending')
  on conflict (scan_id) do nothing;
  return new;
end;
$$;

drop trigger if exists trg_scans_pending_report on public.scans;
create trigger trg_scans_pending_report
  after insert on public.scans
  for each row execute function public.create_pending_report();

-- Staff may insert reports (admin verify on scans without a report row yet)
drop policy if exists "reports_insert_staff" on public.reports;
create policy "reports_insert_staff" on public.reports
  for insert with check (public.is_staff());

-- Activity log inserts
drop policy if exists "activity_logs_insert_authenticated" on public.activity_logs;
create policy "activity_logs_insert_own" on public.activity_logs
  for insert with check (user_id = auth.uid() or public.is_staff());

-- Farmers may delete their own uploaded scan images
drop policy if exists "scan_images_delete_own" on storage.objects;
create policy "scan_images_delete_own" on storage.objects
  for delete using (
    bucket_id = 'scan-images'
    and (owner = auth.uid() or public.is_admin())
  );

-- disease_stats view for admin analytics (aligned with schema.sql)
create or replace view public.disease_stats as
select
  d.code                                as disease_code,
  d.name                                as disease_name,
  count(s.id)::int                      as total_scans,
  coalesce(round(avg(s.confidence)::numeric, 1), 0) as avg_confidence,
  count(distinct s.user_id)::int        as affected_farmers,
  max(s.created_at)                     as last_detected
from public.diseases d
left join public.scans s on s.disease_code = d.code
group by d.code, d.name
order by total_scans desc;

comment on view public.disease_stats is 'Aggregated disease counts for admin analytics dashboards.';

-- Ensure known staff emails always have the correct role
-- (safe to re-run; only updates if role is still 'farmer')
update public.profiles
set role = 'admin'
where email = 'admin@agrismartai.ph'
  and role != 'admin';

update public.profiles
set role = 'technician'
where email = 'tech@agrismartai.ph'
  and role != 'technician';
