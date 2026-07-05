-- =====================================================================
-- SLR Central de Parceiros — Blindagem de segurança (Fase 2.1)
-- "Cofre à prova de exclusão" + Histórico para recuperação.
-- Cole no Supabase: SQL Editor -> New query -> Run. Idempotente.
-- =====================================================================

-- 1) COFRE: ninguém pode APAGAR registros do banco.
--    (O app só sobrescreve; exclusão direta fica proibida.)
revoke delete on public.app_state from authenticated;

drop policy if exists "app_state authenticated all" on public.app_state;
drop policy if exists "app_state select" on public.app_state;
drop policy if exists "app_state insert" on public.app_state;
drop policy if exists "app_state update" on public.app_state;

create policy "app_state select" on public.app_state
  for select to authenticated using (true);
create policy "app_state insert" on public.app_state
  for insert to authenticated with check (true);
create policy "app_state update" on public.app_state
  for update to authenticated using (true) with check (true);
-- (sem policy de DELETE => exclusão bloqueada para todos)

-- 2) HISTÓRICO append-only: guarda a versão ANTERIOR a cada gravação.
create table if not exists public.app_state_history (
  id         bigint generated always as identity primary key,
  key        text not null,
  value      jsonb,
  changed_at timestamptz not null default now(),
  changed_by uuid
);
alter table public.app_state_history enable row level security;

revoke all on public.app_state_history from anon;
revoke insert, update, delete on public.app_state_history from authenticated;
grant select on public.app_state_history to authenticated;

drop policy if exists "history read" on public.app_state_history;
create policy "history read" on public.app_state_history
  for select to authenticated using (true);
-- ninguém insere/edita/apaga direto; só o gatilho abaixo (SECURITY DEFINER)

-- 3) GATILHO: a cada UPDATE, arquiva a versão anterior (recuperação total).
create or replace function public.log_app_state()
returns trigger language plpgsql security definer
set search_path = public as $$
begin
  insert into public.app_state_history(key, value, changed_by)
  values (old.key, old.value, auth.uid());
  return new;
end $$;

drop trigger if exists trg_log_app_state on public.app_state;
create trigger trg_log_app_state
  before update on public.app_state
  for each row execute function public.log_app_state();
