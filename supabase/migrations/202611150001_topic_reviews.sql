begin;

alter table public.topicos
  add column ultima_revisao_em timestamptz;

commit;
