begin;

-- The composite key makes it impossible for a topic to point at another
-- user's discipline, even if a client submits a forged discipline_id.
create unique index if not exists disciplinas_id_usuario_id_uidx
  on public.disciplinas (id, usuario_id);

create table public.topicos (
  id bigint generated always as identity primary key,
  usuario_id uuid not null default auth.uid()
    references auth.users(id) on delete cascade,
  disciplina_id bigint not null,
  nome text not null check (length(btrim(nome)) between 1 and 160),
  ordem integer not null default 0 check (ordem >= 0),
  teoria_lida boolean not null default false,
  resumo_feito boolean not null default false,
  exercicios_resolvidos boolean not null default false,
  criado_em timestamptz not null default now(),
  atualizado_em timestamptz not null default now(),
  constraint topicos_id_usuario_id_uidx unique (id, usuario_id),
  constraint topicos_disciplina_usuario_fk
    foreign key (disciplina_id, usuario_id)
    references public.disciplinas (id, usuario_id) on delete cascade
);

create index topicos_usuario_disciplina_ordem_idx
  on public.topicos (usuario_id, disciplina_id, ordem, id);

create function public.set_topic_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.atualizado_em := now();
  return new;
end;
$$;

create trigger topicos_set_updated_at
  before update on public.topicos
  for each row execute function public.set_topic_updated_at();

alter table public.topicos enable row level security;
revoke all on table public.topicos from anon, authenticated;
revoke all on sequence public.topicos_id_seq from anon, authenticated;

grant usage on schema public to authenticated;
grant select, insert, update, delete on table public.topicos to authenticated;
grant usage on sequence public.topicos_id_seq to authenticated;

create policy select_own_topics on public.topicos
  for select to authenticated
  using ((select auth.uid()) = usuario_id);

create policy insert_own_topics on public.topicos
  for insert to authenticated
  with check ((select auth.uid()) = usuario_id);

create policy update_own_topics on public.topicos
  for update to authenticated
  using ((select auth.uid()) = usuario_id)
  with check ((select auth.uid()) = usuario_id);

create policy delete_own_topics on public.topicos
  for delete to authenticated
  using ((select auth.uid()) = usuario_id);

commit;
