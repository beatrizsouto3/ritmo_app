begin;

create table public.disciplinas (
  id bigint generated always as identity primary key,
  usuario_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  nome text not null check (length(btrim(nome)) > 0)
);

create index disciplinas_usuario_id_id_idx on public.disciplinas (usuario_id, id);

alter table public.disciplinas enable row level security;
revoke all on table public.disciplinas from anon, authenticated;
revoke all on sequence public.disciplinas_id_seq from anon, authenticated;

grant usage on schema public to authenticated;
grant select, insert on table public.disciplinas to authenticated;
grant usage on sequence public.disciplinas_id_seq to authenticated;

create policy select_own_subjects on public.disciplinas
  for select to authenticated
  using ((select auth.uid()) = usuario_id);

create policy insert_own_subjects on public.disciplinas
  for insert to authenticated
  with check ((select auth.uid()) = usuario_id);

commit;
