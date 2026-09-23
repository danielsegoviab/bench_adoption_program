-- Van Cortlandt Park bench adoption: database setup (Supabase / Postgres)
-- Paste this whole file into Supabase > SQL Editor and click Run.

-- Needed so the "no double adoption" rule can compare bench IDs
create extension if not exists btree_gist with schema extensions;

-- ---------------------------------------------------------------
-- 1. The adoptions table: the single source of truth
-- ---------------------------------------------------------------
create table if not exists public.adoptions (
  id          uuid primary key default gen_random_uuid(),
  bench_id    text not null check (bench_id ~ '^B-[0-9]{3}$' and substring(bench_id from 3)::int between 1 and 512),
  adopter     text not null check (char_length(adopter) between 1 and 60),
  email       text check (email is null or email ~ '^[^@\s]+@[^@\s]+\.[^@\s]+$'),
  start_date  date not null default ((now() at time zone 'America/New_York')::date),
  months      int  not null check (months in (6, 12, 24, 36, 60, 120)),
  end_date    date generated always as ((start_date + make_interval(months => months))::date) stored,
  dedication  text check (dedication is null or char_length(dedication) <= 60),
  -- Fee is calculated by the database, so nobody can change the price from their browser:
  -- $3,500 for 10 years (Van Cortlandt Park Alliance), prorated for shorter terms
  fee         int  generated always as (round(3500 * months / 120.0)::int) stored,
  status      text not null default 'pending' check (status in ('pending', 'paid', 'cancelled')),
  is_sample   boolean not null default false,
  created_at  timestamptz not null default now(),

  -- The database itself refuses two active adoptions of the same bench
  -- whose dates overlap, even if two people click at the same moment.
  constraint no_double_adoption exclude using gist (
    bench_id with =,
    daterange(start_date, end_date) with &&
  ) where (status <> 'cancelled')
);

-- ---------------------------------------------------------------
-- 2. Who can do what
--    Public visitors: see adoptions WITHOUT emails, and create new ones.
--    Staff (logged in): see and edit everything.
-- ---------------------------------------------------------------
alter table public.adoptions enable row level security;

revoke all on public.adoptions from anon, authenticated;

-- Public: read every column except email and fee
grant select (id, bench_id, adopter, start_date, months, end_date, dedication, status, is_sample, created_at)
  on public.adoptions to anon;
-- Public: may only fill in these fields; status starts as 'pending' automatically
grant insert (bench_id, adopter, email, months, dedication) on public.adoptions to anon;

-- Staff: full access
grant select, insert, update, delete on public.adoptions to authenticated;

drop policy if exists "Anyone can view adoptions" on public.adoptions;
create policy "Anyone can view adoptions" on public.adoptions
  for select to anon, authenticated using (true);

drop policy if exists "Anyone can adopt" on public.adoptions;
create policy "Anyone can adopt" on public.adoptions
  for insert to anon, authenticated
  with check (status = 'pending' and is_sample = false
              and start_date = (now() at time zone 'America/New_York')::date);

drop policy if exists "Staff can edit" on public.adoptions;
create policy "Staff can edit" on public.adoptions
  for update to authenticated using (true) with check (true);

drop policy if exists "Staff can delete" on public.adoptions;
create policy "Staff can delete" on public.adoptions
  for delete to authenticated using (true);

-- ---------------------------------------------------------------
-- 3. Sample data: about 40% of the 512 benches already adopted,
--    including some ending soon and some already expired
-- ---------------------------------------------------------------
delete from public.adoptions where is_sample;
select setseed(0.2026);

with b as (
  select n, random() r1, random() r2, random() r3, random() r4, random() r5, random() r6
  from generate_series(1, 512) n
), m as (
  select *, (array[6, 12, 12, 24, 24, 36, 60, 120])[1 + floor(r2 * 8)::int] as months
  from b where r1 < 0.42
), s as (
  select *, current_date - floor(r6 * (months * 30 + 150))::int as start_date,
    (array['Maria','James','Aisha','Daniel','Sofia','Kwame','Linda','Carlos','Priya','Thomas',
           'Grace','Luis','Hannah','Omar','Rosa','Michael','Yuki','Esther','Patrick','Ana'])[1 + floor(r4 * 20)::int] as first_name,
    (array['Rivera','O''Connor','Johnson','Nguyen','Goldberg','Mensah','Martinez','Kowalski',
           'Patel','Brennan','Diaz','Cohen','Williams','Santos','Murphy','Okafor'])[1 + floor(r5 * 16)::int] as last_name
  from m
)
insert into public.adoptions (bench_id, adopter, email, start_date, months, dedication, status, is_sample)
select
  'B-' || lpad(n::text, 3, '0'),
  case when r3 < 0.2
       then (array['Riverdale Rotary Club','Friends of Van Cortlandt Park','Kingsbridge Running Club',
                   'Bronx Science Class of 1998','Manhattan College Alumni','Fieldston Garden Society'])[1 + floor(r4 * 6)::int]
       else first_name || ' ' || last_name end,
  lower(first_name) || '.' || lower(replace(last_name, '''', '')) || '@example.com',
  start_date,
  months,
  case when r5 < 0.45
       then (array['In loving memory of','For my father,','Dedicated to','In honor of'])[1 + floor(r3 * 4)::int]
            || ' ' || (array['Rosa Diaz','James Murphy','Grace Okafor','Luis Santos','Hannah Cohen'])[1 + floor(r6 * 5)::int]
       end,
  case when current_date - start_date < 14 and r2 < 0.6 then 'pending' else 'paid' end,
  true
from s;

-- Quick check: how many sample adoptions were created
select count(*) as sample_adoptions from public.adoptions where is_sample;

-- ---------------------------------------------------------------
-- 4. Release unpaid reservations automatically
--    Every day at 5:00 a.m. New York time, adoptions still awaiting
--    payment 14 days after they were made are cancelled, which makes
--    their benches available again.
-- ---------------------------------------------------------------
create extension if not exists pg_cron;

select cron.unschedule('release-unpaid-reservations')
where exists (select 1 from cron.job where jobname = 'release-unpaid-reservations');

select cron.schedule(
  'release-unpaid-reservations',
  '0 9 * * *',   -- 09:00 UTC = 5:00 a.m. in New York
  $$ update public.adoptions
     set status = 'cancelled'
     where status = 'pending' and created_at < now() - interval '14 days' $$
);
