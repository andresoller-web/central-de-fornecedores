-- =====================================================================
-- SLR Central de Parceiros — Esquema do banco (Fase 2)
-- Cole tudo isto no Supabase: SQL Editor -> New query -> Run
-- Pode rodar mais de uma vez sem problema (é idempotente).
-- =====================================================================

-- Tabela única de dados compartilhados (formato chave-valor JSON).
-- Guarda: usuários/perfis, parceiros, avaliações, disciplinas, etc.
create table if not exists public.app_state (
  key         text primary key,
  value       jsonb not null,
  updated_at  timestamptz not null default now(),
  updated_by  text
);

-- Liga a segurança em nível de linha (RLS).
alter table public.app_state enable row level security;

-- Só quem está LOGADO acessa. Visitantes anônimos não leem nada.
revoke all on public.app_state from anon;
grant select, insert, update, delete on public.app_state to authenticated;

drop policy if exists "app_state authenticated all" on public.app_state;
create policy "app_state authenticated all"
  on public.app_state
  for all
  to authenticated
  using (true)
  with check (true);

-- Atualiza o carimbo de data/hora automaticamente a cada gravação.
create or replace function public.touch_app_state()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end $$;

drop trigger if exists trg_touch_app_state on public.app_state;
create trigger trg_touch_app_state
  before update on public.app_state
  for each row execute function public.touch_app_state();
