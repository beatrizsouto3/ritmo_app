begin;

create table public.baralhos (
  id bigint generated always as identity primary key,
  usuario_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  nome text not null check (length(btrim(nome)) between 1 and 60),
  descricao text check (length(descricao) <= 120),
  criado_em timestamptz not null default now(),
  unique (id, usuario_id)
);

create table public.flashcards (
  id bigint generated always as identity primary key,
  usuario_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  baralho_id bigint not null,
  frente text not null check (length(btrim(frente)) between 1 and 500),
  verso text not null check (length(btrim(verso)) between 1 and 1000),
  imagem_url text check (imagem_url ~ '^https?://'),
  criado_em timestamptz not null default now(),
  proxima_revisao_em timestamptz not null default now(),
  intervalo_dias integer not null default 0 check (intervalo_dias between 0 and 3650),
  repeticoes integer not null default 0 check (repeticoes >= 0),
  unique (id, usuario_id),
  foreign key (baralho_id, usuario_id) references public.baralhos(id, usuario_id) on delete cascade
);

create table public.revisoes_flashcards (
  id bigint generated always as identity primary key,
  usuario_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  flashcard_id bigint not null,
  avaliacao text not null check (avaliacao in ('again', 'hard', 'good', 'easy')),
  revisado_em timestamptz not null,
  proxima_revisao_em timestamptz not null,
  intervalo_dias integer not null check (intervalo_dias between 0 and 3650),
  repeticoes integer not null check (repeticoes >= 0),
  foreign key (flashcard_id, usuario_id) references public.flashcards(id, usuario_id) on delete cascade
);

create index baralhos_usuario_id_criado_em_idx on public.baralhos(usuario_id, criado_em);
create index flashcards_usuario_id_baralho_id_revisao_idx
  on public.flashcards(usuario_id, baralho_id, proxima_revisao_em);
create index revisoes_flashcards_usuario_id_cartao_idx
  on public.revisoes_flashcards(usuario_id, flashcard_id, revisado_em);

alter table public.baralhos enable row level security;
alter table public.flashcards enable row level security;
alter table public.revisoes_flashcards enable row level security;

revoke all on table public.baralhos, public.flashcards, public.revisoes_flashcards from anon, authenticated;
revoke all on sequence public.baralhos_id_seq, public.flashcards_id_seq,
  public.revisoes_flashcards_id_seq from anon, authenticated;

grant usage on schema public to authenticated;
grant select, insert, update, delete on public.baralhos, public.flashcards to authenticated;
grant select, insert on public.revisoes_flashcards to authenticated;
grant usage on sequence public.baralhos_id_seq, public.flashcards_id_seq,
  public.revisoes_flashcards_id_seq to authenticated;

create policy select_own_decks on public.baralhos for select to authenticated
  using ((select auth.uid()) = usuario_id);
create policy insert_own_decks on public.baralhos for insert to authenticated
  with check ((select auth.uid()) = usuario_id);
create policy update_own_decks on public.baralhos for update to authenticated
  using ((select auth.uid()) = usuario_id) with check ((select auth.uid()) = usuario_id);
create policy delete_own_decks on public.baralhos for delete to authenticated
  using ((select auth.uid()) = usuario_id);

create policy select_own_cards on public.flashcards for select to authenticated
  using ((select auth.uid()) = usuario_id);
create policy insert_own_cards on public.flashcards for insert to authenticated
  with check ((select auth.uid()) = usuario_id);
create policy update_own_cards on public.flashcards for update to authenticated
  using ((select auth.uid()) = usuario_id) with check ((select auth.uid()) = usuario_id);
create policy delete_own_cards on public.flashcards for delete to authenticated
  using ((select auth.uid()) = usuario_id);

create policy select_own_card_reviews on public.revisoes_flashcards for select to authenticated
  using ((select auth.uid()) = usuario_id);
create policy insert_own_card_reviews on public.revisoes_flashcards for insert to authenticated
  with check ((select auth.uid()) = usuario_id);

create function public.record_flashcard_review(
  p_card_id bigint,
  p_rating text,
  p_expected_next_review_at timestamptz,
  p_expected_interval_days integer,
  p_expected_repetitions integer,
  p_reviewed_at timestamptz,
  p_next_review_at timestamptz,
  p_interval_days integer,
  p_repetitions integer
)
returns setof public.revisoes_flashcards
language plpgsql
security invoker
set search_path = ''
as $$
declare
  existing_card public.flashcards%rowtype;
  saved_review public.revisoes_flashcards%rowtype;
begin
  if auth.uid() is null then
    raise exception 'Entre na sua conta para continuar.';
  end if;

  select * into existing_card from public.flashcards
    where id = p_card_id and usuario_id = auth.uid() for update;
  if not found then
    raise exception 'O cartão não está disponível para esta conta.';
  end if;

  if p_expected_next_review_at is null or p_expected_interval_days is null
    or p_expected_repetitions is null
    or existing_card.proxima_revisao_em <> p_expected_next_review_at
    or existing_card.intervalo_dias <> p_expected_interval_days
    or existing_card.repeticoes <> p_expected_repetitions then
    raise exception 'O cartão foi alterado. Recarregue o baralho.';
  end if;

  if p_rating is null or p_rating not in ('again', 'hard', 'good', 'easy')
    or p_reviewed_at is null or p_next_review_at is null
    or p_interval_days is null or p_repetitions is null
    or p_interval_days not between 0 and 3650 or p_repetitions < 0
    or p_next_review_at <= p_reviewed_at
    or existing_card.proxima_revisao_em > p_reviewed_at then
    raise exception 'Avaliação de revisão inválida.';
  end if;

  update public.flashcards set proxima_revisao_em = p_next_review_at,
    intervalo_dias = p_interval_days, repeticoes = p_repetitions
    where id = existing_card.id;

  insert into public.revisoes_flashcards
    (flashcard_id, usuario_id, avaliacao, revisado_em, proxima_revisao_em, intervalo_dias, repeticoes)
    values (existing_card.id, auth.uid(), p_rating, p_reviewed_at,
      p_next_review_at, p_interval_days, p_repetitions)
    returning * into saved_review;

  return next saved_review;
end;
$$;

revoke execute on function public.record_flashcard_review(bigint, text, timestamptz, integer,
  integer, timestamptz, timestamptz, integer, integer) from public, anon;
grant execute on function public.record_flashcard_review(bigint, text, timestamptz, integer,
  integer, timestamptz, timestamptz, integer, integer) to authenticated;

commit;
