begin;

grant update, delete on public.disciplinas to authenticated;

create policy update_own_subjects on public.disciplinas
  for update to authenticated
  using ((select auth.uid()) = usuario_id)
  with check ((select auth.uid()) = usuario_id);

create policy delete_own_subjects on public.disciplinas
  for delete to authenticated
  using ((select auth.uid()) = usuario_id);

create unique index topicos_id_disciplina_usuario_uidx
  on public.topicos(id, disciplina_id, usuario_id);

create table public.sessoes_planejadas (
  id bigint generated always as identity primary key,
  usuario_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  disciplina_id bigint not null,
  topico_id bigint,
  inicio_em timestamptz not null,
  fim_em timestamptz not null,
  estado text not null default 'planned' check (estado in ('planned', 'completed', 'cancelled')),
  observacoes text check (length(observacoes) <= 500),
  check (fim_em > inicio_em),
  foreign key (disciplina_id, usuario_id) references public.disciplinas(id, usuario_id) on delete cascade,
  foreign key (topico_id, disciplina_id, usuario_id)
    references public.topicos(id, disciplina_id, usuario_id) on delete set null (topico_id)
);

create index sessoes_planejadas_usuario_inicio_idx
  on public.sessoes_planejadas(usuario_id, inicio_em);

create table public.registros_questoes (
  id bigint generated always as identity primary key,
  usuario_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  disciplina_id bigint not null,
  topico_id bigint,
  total integer not null check (total > 0),
  acertos integer not null check (acertos >= 0),
  erros integer not null check (erros >= 0),
  realizado_em timestamptz not null default now(),
  check (total = acertos + erros),
  foreign key (disciplina_id, usuario_id) references public.disciplinas(id, usuario_id) on delete cascade,
  foreign key (topico_id, disciplina_id, usuario_id)
    references public.topicos(id, disciplina_id, usuario_id) on delete set null (topico_id)
);

create index registros_questoes_usuario_data_idx
  on public.registros_questoes(usuario_id, realizado_em desc);
create index registros_questoes_usuario_topico_idx
  on public.registros_questoes(usuario_id, topico_id);

alter table public.sessoes_planejadas enable row level security;
alter table public.registros_questoes enable row level security;
revoke all on public.sessoes_planejadas, public.registros_questoes from anon, authenticated;
revoke all on sequence public.sessoes_planejadas_id_seq, public.registros_questoes_id_seq from anon, authenticated;
grant select, insert, update, delete on public.sessoes_planejadas, public.registros_questoes to authenticated;
grant usage on sequence public.sessoes_planejadas_id_seq, public.registros_questoes_id_seq to authenticated;

create policy planned_sessions_read on public.sessoes_planejadas for select to authenticated
  using ((select auth.uid()) = usuario_id);
create policy planned_sessions_insert on public.sessoes_planejadas for insert to authenticated
  with check ((select auth.uid()) = usuario_id);
create policy planned_sessions_update on public.sessoes_planejadas for update to authenticated
  using ((select auth.uid()) = usuario_id) with check ((select auth.uid()) = usuario_id);
create policy planned_sessions_delete on public.sessoes_planejadas for delete to authenticated
  using ((select auth.uid()) = usuario_id);

create policy question_records_read on public.registros_questoes for select to authenticated
  using ((select auth.uid()) = usuario_id);
create policy question_records_insert on public.registros_questoes for insert to authenticated
  with check ((select auth.uid()) = usuario_id);
create policy question_records_update on public.registros_questoes for update to authenticated
  using ((select auth.uid()) = usuario_id) with check ((select auth.uid()) = usuario_id);
create policy question_records_delete on public.registros_questoes for delete to authenticated
  using ((select auth.uid()) = usuario_id);

commit;
