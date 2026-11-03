create extension if not exists pgcrypto;

create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  report_data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint reports_report_data_is_object check (jsonb_typeof(report_data) = 'object')
);

create index if not exists reports_owner_updated_idx
  on public.reports (owner_id, updated_at desc);

create index if not exists reports_owner_created_idx
  on public.reports (owner_id, created_at desc);

alter table public.reports enable row level security;

create or replace function public.set_reports_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists reports_updated_at on public.reports;
create trigger reports_updated_at
before update on public.reports
for each row
execute function public.set_reports_updated_at();

create policy "Users can view their own reports"
on public.reports
for select
using (auth.uid() = owner_id);

create policy "Users can create their own reports"
on public.reports
for insert
with check (auth.uid() = owner_id);

create policy "Users can update their own reports"
on public.reports
for update
using (auth.uid() = owner_id)
with check (auth.uid() = owner_id);

create policy "Users can delete their own reports"
on public.reports
for delete
using (auth.uid() = owner_id);

grant usage on schema public to authenticated;
grant select, insert, update, delete on public.reports to authenticated;
