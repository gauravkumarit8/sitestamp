-- DRAFT schema for SiteStamp Teams (Supabase / Postgres). Review before use.
create extension if not exists pgcrypto;

create table organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);

create type member_role as enum ('owner', 'admin', 'member');

create table memberships (
  org_id uuid not null references organizations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role member_role not null default 'member',
  status text not null default 'active',   -- active | removed
  created_at timestamptz not null default now(),
  primary key (org_id, user_id)
);

create table invites (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references organizations(id) on delete cascade,
  email text not null,
  role member_role not null default 'member',
  created_at timestamptz not null default now(),
  accepted_at timestamptz
);

create table subscriptions (
  org_id uuid primary key references organizations(id) on delete cascade,
  plan text not null default 'trial',        -- trial | team | business | enterprise
  seats int not null default 5,
  status text not null default 'trialing',   -- trialing | active | past_due | canceled
  current_period_end timestamptz,
  provider text,                              -- razorpay | stripe
  provider_ref text,
  updated_at timestamptz not null default now()
);

create table projects (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references organizations(id) on delete cascade,
  name text not null,
  site_lat double precision,
  site_lon double precision,
  site_radius_m int,
  created_at timestamptz not null default now()
);

create table photos (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references organizations(id) on delete cascade,
  project_id uuid references projects(id) on delete set null,
  user_id uuid not null references auth.users(id),
  photo_id text not null unique,             -- SS-XXXXXXXX
  taken_at timestamptz not null,             -- claimed by the phone
  uploaded_at timestamptz not null default now(),  -- trusted server time
  lat double precision, lon double precision, accuracy_m real,
  address text, memo text,
  sha256 text not null,
  flags jsonb not null default '{}'::jsonb,  -- mock, clock, site status
  storage_path text not null
);

-- Seat limit: active members must not exceed purchased seats
create or replace function enforce_seat_limit() returns trigger
language plpgsql as $$
declare allowed int; used int;
begin
  select seats into allowed from subscriptions where org_id = new.org_id;
  select count(*) into used from memberships
    where org_id = new.org_id and status = 'active'
      and not (user_id = new.user_id);
  if new.status = 'active' and used + 1 > coalesce(allowed, 0) then
    raise exception 'Seat limit reached';
  end if;
  return new;
end $$;

create trigger memberships_seat_limit
before insert or update on memberships
for each row execute function enforce_seat_limit();

-- Row level security
alter table organizations enable row level security;
alter table memberships   enable row level security;
alter table invites       enable row level security;
alter table subscriptions enable row level security;
alter table projects      enable row level security;
alter table photos        enable row level security;

create or replace function is_member(org uuid) returns boolean
language sql security definer set search_path = public as $$
  select exists (select 1 from memberships m
    where m.org_id = org and m.user_id = auth.uid() and m.status = 'active');
$$;

create or replace function is_admin(org uuid) returns boolean
language sql security definer set search_path = public as $$
  select exists (select 1 from memberships m
    where m.org_id = org and m.user_id = auth.uid() and m.status = 'active'
      and m.role in ('owner', 'admin'));
$$;

create policy org_read on organizations for select using (is_member(id));
create policy mem_read on memberships for select using (is_member(org_id));
create policy mem_admin on memberships for all using (is_admin(org_id)) with check (is_admin(org_id));
create policy sub_read on subscriptions for select using (is_member(org_id));
create policy proj_read on projects for select using (is_member(org_id));
create policy proj_admin on projects for all using (is_admin(org_id)) with check (is_admin(org_id));
create policy photo_read on photos for select using (is_admin(org_id) or user_id = auth.uid());
create policy photo_insert on photos for insert with check (is_member(org_id) and user_id = auth.uid());
-- subscriptions are written only by the payment webhook (service role), never by clients
