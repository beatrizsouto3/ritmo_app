begin;
create table public.preferencias_estudo (
  usuario_id uuid primary key default auth.uid() references auth.users(id) on delete cascade,
  nome text not null default '' check (length(nome) <= 100),
  objetivo text not null default 'Universidade' check (length(objetivo) between 1 and 100),
  horas_diarias integer not null default 2 check (horas_diarias between 1 and 12),
  foco_minutos integer not null default 25 check (foco_minutos between 1 and 120),
  pausa_curta integer not null default 5 check (pausa_curta between 1 and 60),
  pausa_longa integer not null default 15 check (pausa_longa between 1 and 60),
  dias integer[] not null default '{1,2,3,4,5}' check (dias <@ array[1,2,3,4,5,6,7]),
  turno text not null default 'Manhã' check (turno in ('Manhã', 'Tarde', 'Noite')),
  configurado boolean not null default false
);
create table public.sessoes_foco (
  -- Client-generated key is reused on retry, making a completed cycle idempotent.
  id text primary key check (length(id) between 1 and 120),
  usuario_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  disciplina_id bigint not null,
  segundos integer not null check (segundos between 1 and 7200),
  concluido_em timestamptz not null,
  foreign key (disciplina_id, usuario_id) references public.disciplinas(id, usuario_id) on delete cascade
);
create index sessoes_foco_usuario_data_idx on public.sessoes_foco(usuario_id, concluido_em);
alter table public.preferencias_estudo enable row level security;
alter table public.sessoes_foco enable row level security;
revoke all on public.preferencias_estudo, public.sessoes_foco from anon, authenticated;
grant select, insert, update on public.preferencias_estudo to authenticated;
grant select, insert on public.sessoes_foco to authenticated;
create policy preferences_read on public.preferencias_estudo for select to authenticated using (auth.uid() = usuario_id);
create policy preferences_insert on public.preferencias_estudo for insert to authenticated with check (auth.uid() = usuario_id);
create policy preferences_update on public.preferencias_estudo for update to authenticated using (auth.uid() = usuario_id) with check (auth.uid() = usuario_id);
create policy sessions_read on public.sessoes_foco for select to authenticated using (auth.uid() = usuario_id);
create policy sessions_insert on public.sessoes_foco for insert to authenticated with check (auth.uid() = usuario_id);
commit;
