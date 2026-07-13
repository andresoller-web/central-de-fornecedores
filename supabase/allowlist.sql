-- =====================================================================
-- SLR Central de Parceiros — Lista de acesso (allowlist) + is_allowed()
-- Blindagem: só e-mails nesta lista acessam os dados, mesmo autenticados.
-- Cole no Supabase: SQL Editor -> New query -> Run. Idempotente.
-- =====================================================================

create table if not exists public.app_allow (
  email      text primary key,
  role       text not null default 'operacoes',
  nome       text,
  created_at timestamptz default now()
);
alter table public.app_allow enable row level security;
revoke all on public.app_allow from anon, authenticated;
-- sem policy para authenticated => ninguém lê/escreve direto; só a função abaixo (definer)

insert into public.app_allow (email, role, nome) values
 ('andre.soller@slrengenharia.com','admin','Andre Soller'),
 ('vanessa.falanga@slrengenharia.com','admin','Vanessa Falanga'),
 ('rodrigo.rocha@slrengenharia.com','analista','Rodrigo Rocha'),
 ('victor.almeida@slrengenharia.com','analista','Victor Almeida'),
 ('guilherme.vieira@slrengenharia.com','operacoes','Guilherme Vieira'),
 ('estevan.camargo@slrengenharia.com','operacoes','Estevan Camargo'),
 ('rodrigo.machado@slrengenharia.com','operacoes','Rodrigo Machado'),
 ('barbara.lessa@slrengenharia.com','operacoes','Barbara Lessa'),
 ('ana.ribeiro@slrengenharia.com','operacoes','Ana Ribeiro')
on conflict (email) do nothing;

-- Função: o e-mail do token está na lista?
create or replace function public.is_allowed()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.app_allow where email = lower(auth.jwt()->>'email'));
$$;

-- === Aplicar a checagem em TODAS as tabelas/áreas de dados ===

-- app_state (dados principais)
drop policy if exists "app_state select" on public.app_state;
drop policy if exists "app_state insert" on public.app_state;
drop policy if exists "app_state update" on public.app_state;
create policy "app_state select" on public.app_state for select to authenticated using (public.is_allowed());
create policy "app_state insert" on public.app_state for insert to authenticated with check (public.is_allowed());
create policy "app_state update" on public.app_state for update to authenticated using (public.is_allowed()) with check (public.is_allowed());

-- histórico (recuperação)
drop policy if exists "history read" on public.app_state_history;
create policy "history read" on public.app_state_history for select to authenticated using (public.is_allowed());

-- arquivos (Storage - bucket documentos)
drop policy if exists "documentos read"   on storage.objects;
drop policy if exists "documentos insert" on storage.objects;
drop policy if exists "documentos update" on storage.objects;
drop policy if exists "documentos delete" on storage.objects;
create policy "documentos read"   on storage.objects for select to authenticated using (bucket_id='documentos' and public.is_allowed());
create policy "documentos insert" on storage.objects for insert to authenticated with check (bucket_id='documentos' and public.is_allowed());
create policy "documentos update" on storage.objects for update to authenticated using (bucket_id='documentos' and public.is_allowed()) with check (bucket_id='documentos' and public.is_allowed());
create policy "documentos delete" on storage.objects for delete to authenticated using (bucket_id='documentos' and public.is_allowed());
