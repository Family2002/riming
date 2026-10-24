-- Performance: evaluate auth.uid() once per statement (Supabase advisor auth_rls_initplan).

drop policy if exists "activities_select_own" on public.activities;
drop policy if exists "activities_insert_own" on public.activities;
drop policy if exists "activities_update_own" on public.activities;
drop policy if exists "activities_delete_own" on public.activities;

create policy "activities_select_own"
  on public.activities
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

create policy "activities_insert_own"
  on public.activities
  for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

create policy "activities_update_own"
  on public.activities
  for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "activities_delete_own"
  on public.activities
  for delete
  to authenticated
  using ((select auth.uid()) = user_id);
