-- Historico/lixeira da tabela suppliers: arquiva versao anterior em UPDATE/DELETE (recuperavel)
create table if not exists public.suppliers_history (
  hid bigint generated always as identity primary key,
  id text, data jsonb, op text, changed_at timestamptz default now(), changed_by uuid
);
alter table public.suppliers_history enable row level security;
revoke all on public.suppliers_history from anon;
revoke insert, update, delete on public.suppliers_history from authenticated;
grant select on public.suppliers_history to authenticated;
drop policy if exists "sup_hist read" on public.suppliers_history;
create policy "sup_hist read" on public.suppliers_history for select to authenticated using (public.is_allowed());
create or replace function public.log_suppliers()
returns trigger language plpgsql security definer set search_path=public as $$
begin
  if (tg_op='DELETE') then insert into public.suppliers_history(id,data,op,changed_by) values (old.id,old.data,'delete',auth.uid()); return old;
  else insert into public.suppliers_history(id,data,op,changed_by) values (old.id,old.data,'update',auth.uid()); return new; end if;
end $$;
drop trigger if exists trg_log_suppliers on public.suppliers;
create trigger trg_log_suppliers before update or delete on public.suppliers for each row execute function public.log_suppliers();
