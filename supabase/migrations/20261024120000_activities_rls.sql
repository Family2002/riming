-- 日铭 activities: mirrors local Drift fields + user_id, with RLS.
-- Prefer creating the Supabase project in Tokyo (ap-northeast-1) for China users.

create table if not exists public.activities (
  id uuid primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  title text not null,
  start_at timestamptz not null,
  end_at timestamptz,
  updated_at timestamptz not null,
  deleted_at timestamptz,
  constraint activities_title_length check (
    char_length(title) >= 1 and char_length(title) <= 200
  )
);

comment on table public.activities is 'Timed activity segments synced from the Riming app';

-- At most one ongoing (end_at null, not deleted) activity per user.
create unique index if not exists activities_one_ongoing_per_user
  on public.activities (user_id)
  where end_at is null and deleted_at is null;

create index if not exists activities_user_updated_at_idx
  on public.activities (user_id, updated_at);

alter table public.activities enable row level security;

-- SELECT required for UPDATE under RLS.
create policy "activities_select_own"
  on public.activities
  for select
  to authenticated
  using (auth.uid() = user_id);

create policy "activities_insert_own"
  on public.activities
  for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy "activities_update_own"
  on public.activities
  for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "activities_delete_own"
  on public.activities
  for delete
  to authenticated
  using (auth.uid() = user_id);

grant select, insert, update, delete on table public.activities to authenticated;
