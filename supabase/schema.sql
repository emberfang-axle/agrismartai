-- ============================================================================
-- AgriSmartAI :: Database Schema
-- AI-Powered Rice Crop Disease Monitoring and Detection
-- Location: New Bataan, Davao de Oro, Philippines
-- ----------------------------------------------------------------------------
-- OBJECTIVE 1: Collect images from New Bataan  (scans.image_url + geo columns)
-- OBJECTIVE 2: 85%+ accuracy model             (scans.confidence tracking)
-- OBJECTIVE 3: App + fertilizer + DA referral  (diseases.fertilizer / da_office)
-- OBJECTIVE 4: Farmer evaluation + admin board  (evaluations + reports verify)
-- ============================================================================

-- Required extensions ---------------------------------------------------------
create extension if not exists "uuid-ossp";
create extension if not exists "pgcrypto";

-- ----------------------------------------------------------------------------
-- ENUM TYPES
-- ----------------------------------------------------------------------------
do $$
begin
  if not exists (select 1 from pg_type where typname = 'user_role') then
    create type user_role as enum ('farmer', 'technician', 'admin');
  end if;

  if not exists (select 1 from pg_type where typname = 'disease_code') then
    -- 'healthy' included so we can store negative detections too
    create type disease_code as enum ('bacterial_leaf_blight', 'rice_blast', 'tungro', 'healthy');
  end if;

  if not exists (select 1 from pg_type where typname = 'report_status') then
    create type report_status as enum ('pending', 'verified', 'rejected');
  end if;
end$$;

-- ----------------------------------------------------------------------------
-- TABLE: profiles  (mirrors auth.users)
-- OBJECTIVE 3/4: links every farmer/technician/admin to the system
-- ----------------------------------------------------------------------------
create table if not exists public.profiles (
  id           uuid primary key references auth.users (id) on delete cascade,
  full_name    text not null default '',
  email        text not null default '',
  phone        text,
  role         user_role not null default 'farmer',
  barangay     text default 'New Bataan',
  municipality text default 'New Bataan',
  province     text default 'Davao de Oro',
  farm_size_ha numeric(10, 2),
  avatar_url   text,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

comment on table public.profiles is 'User profiles for farmers, technicians and admins.';

-- ----------------------------------------------------------------------------
-- TABLE: diseases  (reference / knowledge base)
-- OBJECTIVE 3: fertilizer recommendation + DA referral directives live here
-- ----------------------------------------------------------------------------
create table if not exists public.diseases (
  id                  uuid primary key default uuid_generate_v4(),
  code                disease_code not null unique,
  name                text not null,
  scientific_name     text,
  description         text,
  symptoms            text,
  causes              text,
  treatment           text,
  fertilizer          text,            -- OBJECTIVE 3: fertilizer recommendation
  prevention          text,
  da_directive        text,            -- OBJECTIVE 3: Dept. of Agriculture referral
  severity_label      text default 'Moderate',
  created_at          timestamptz not null default now()
);

comment on table public.diseases is 'Reference knowledge base for the 3 target rice diseases.';

-- ----------------------------------------------------------------------------
-- TABLE: scans  (every detection performed by a farmer)
-- OBJECTIVE 1: image_url + latitude/longitude collect data from New Bataan
-- OBJECTIVE 2: confidence + model_version track 85%+ accuracy target
-- ----------------------------------------------------------------------------
create table if not exists public.scans (
  id              uuid primary key default uuid_generate_v4(),
  user_id         uuid not null references public.profiles (id) on delete cascade,
  disease_id      uuid references public.diseases (id) on delete set null,
  disease_code    disease_code not null default 'healthy',
  disease_name    text not null default 'Healthy',
  confidence      numeric(5, 2) not null default 0,         -- percentage 0-100
  model_version   text not null default 'mobilenetv2-sim-1.0',
  is_rice_leaf    boolean not null default true,            -- rice leaf validation
  image_url       text,
  thumbnail_url   text,
  latitude        numeric(9, 6),                            -- OBJECTIVE 1
  longitude       numeric(9, 6),                            -- OBJECTIVE 1
  barangay        text default 'New Bataan',
  notes           text,
  created_at      timestamptz not null default now()
);

comment on table public.scans is 'Individual disease detection scans submitted by farmers.';

create index if not exists idx_scans_user_id      on public.scans (user_id);
create index if not exists idx_scans_disease_code on public.scans (disease_code);
create index if not exists idx_scans_created_at   on public.scans (created_at desc);

-- ----------------------------------------------------------------------------
-- TABLE: reports  (technician/admin verification queue)
-- OBJECTIVE 4: admin dashboard verifies field reports
-- ----------------------------------------------------------------------------
create table if not exists public.reports (
  id            uuid primary key default uuid_generate_v4(),
  scan_id       uuid not null references public.scans (id) on delete cascade,
  farmer_id     uuid not null references public.profiles (id) on delete cascade,
  status        report_status not null default 'pending',
  reviewed_by   uuid references public.profiles (id) on delete set null,
  reviewer_note text,
  reviewed_at   timestamptz,
  created_at    timestamptz not null default now()
);

comment on table public.reports is 'Verification queue surfaced on the admin dashboard.';

create unique index if not exists idx_reports_scan_id on public.reports (scan_id);
create index if not exists idx_reports_status on public.reports (status);

-- ----------------------------------------------------------------------------
-- TABLE: evaluations  (farmer feedback on the app / detection)
-- OBJECTIVE 4: farmer evaluation of the system
-- ----------------------------------------------------------------------------
create table if not exists public.evaluations (
  id           uuid primary key default uuid_generate_v4(),
  user_id      uuid not null references public.profiles (id) on delete cascade,
  scan_id      uuid references public.scans (id) on delete set null,
  rating       int  not null check (rating between 1 and 5),
  usefulness   int  check (usefulness between 1 and 5),
  ease_of_use  int  check (ease_of_use between 1 and 5),
  comment      text,
  created_at   timestamptz not null default now()
);

comment on table public.evaluations is 'Farmer satisfaction / usability evaluations.';

-- ----------------------------------------------------------------------------
-- TABLE: chat_messages  (local AgriSmartAI chat history)
-- ----------------------------------------------------------------------------
create table if not exists public.chat_messages (
  id         uuid primary key default uuid_generate_v4(),
  user_id    uuid not null references public.profiles (id) on delete cascade,
  role       text not null check (role in ('user', 'assistant')),
  content    text not null,
  source     text default 'agrismart_ai',  -- 'agrismart_ai' | 'offline'
  created_at timestamptz not null default now()
);

create index if not exists idx_chat_user_id on public.chat_messages (user_id, created_at);

-- ----------------------------------------------------------------------------
-- TABLE: activity_logs  (admin audit trail)
-- ----------------------------------------------------------------------------
create table if not exists public.activity_logs (
  id          uuid primary key default uuid_generate_v4(),
  user_id     uuid references public.profiles (id) on delete set null,
  action      text not null,
  entity_type text,
  entity_id   uuid,
  metadata    jsonb default '{}'::jsonb,
  ip_address  text,
  created_at  timestamptz not null default now()
);

comment on table public.activity_logs is 'System activity for admin dashboard monitoring.';

create index if not exists idx_activity_logs_created_at on public.activity_logs (created_at desc);
create index if not exists idx_activity_logs_user_id on public.activity_logs (user_id);

-- ----------------------------------------------------------------------------
-- VIEWS: capstone-friendly aliases
-- profiles = users | scans split into uploaded_images + disease_predictions
-- ----------------------------------------------------------------------------
create or replace view public.uploaded_images as
select
  id,
  user_id,
  image_url,
  thumbnail_url,
  barangay,
  latitude,
  longitude,
  created_at
from public.scans
where image_url is not null;

create or replace view public.disease_predictions as
select
  id,
  user_id,
  disease_id,
  disease_code,
  disease_name,
  confidence,
  model_version,
  is_rice_leaf,
  image_url,
  created_at
from public.scans;

-- ----------------------------------------------------------------------------
-- TRIGGER: keep updated_at fresh on profiles
-- ----------------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_profiles_updated_at on public.profiles;
create trigger trg_profiles_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

-- ----------------------------------------------------------------------------
-- TRIGGER: auto-create profile row when a new auth user signs up
-- ----------------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, email, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', ''),
    coalesce(new.email, ''),
    coalesce((new.raw_user_meta_data ->> 'role')::user_role, 'farmer')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ----------------------------------------------------------------------------
-- VIEW: disease_stats  (powers admin analytics charts - OBJECTIVE 4)
-- ----------------------------------------------------------------------------
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

-- ----------------------------------------------------------------------------
-- STORAGE bucket for rice-leaf images (OBJECTIVE 1)
-- ----------------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('scan-images', 'scan-images', true)
on conflict (id) do nothing;
