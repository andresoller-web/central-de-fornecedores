-- Tabela de parceiros (uma linha por parceiro) — substitui o "pacote unico" sgf:suppliers
create table if not exists public.suppliers (
  id text primary key, data jsonb not null, updated_at timestamptz not null default now()
);
alter table public.suppliers enable row level security;
revoke all on public.suppliers from anon;
grant select, insert, update, delete on public.suppliers to authenticated;
drop policy if exists "suppliers select" on public.suppliers;
drop policy if exists "suppliers insert" on public.suppliers;
drop policy if exists "suppliers update" on public.suppliers;
drop policy if exists "suppliers delete" on public.suppliers;
create policy "suppliers select" on public.suppliers for select to authenticated using (public.is_allowed());
create policy "suppliers insert" on public.suppliers for insert to authenticated with check (public.is_allowed());
create policy "suppliers update" on public.suppliers for update to authenticated using (public.is_allowed()) with check (public.is_allowed());
create policy "suppliers delete" on public.suppliers for delete to authenticated using (public.is_allowed());
