-- Codify `bank_transactions` — existed in prod as manual DDL but was never
-- covered by a migration, breaking `supabase db reset` / branches / CI.
--
-- Source: live introspection against prod (2026-04-22), mirrored exactly.
-- Idempotent: safe to run on prod (no-op via `if not exists`) and on fresh DB.
--
-- Referenced by: admin.html, berichte.html, cockpit.html, finanzen.html.

create table if not exists bank_transactions (
  id uuid primary key default gen_random_uuid(),
  farm_id uuid not null default default_farm_id() references farms(id),
  transaction_date date not null,
  value_date date,
  reference text,
  description text not null,
  debit_nad numeric,
  credit_nad numeric,
  balance_nad numeric,
  bank text not null default 'nedbank',
  category text,
  category_confirmed boolean default false,
  source_file text,
  created_at timestamptz default now(),
  active boolean not null default true,
  constraint bank_transactions_farm_id_transaction_date_reference_descri_key
    unique (farm_id, transaction_date, reference, description, debit_nad, credit_nad)
);

create index if not exists idx_bank_tx_active
  on bank_transactions(active) where active;

alter table bank_transactions enable row level security;

-- Policies via DO blocks so we don't error on re-apply.
do $$
begin
  if not exists (select 1 from pg_policy where polname = 'farm_read'
                   and polrelid = 'public.bank_transactions'::regclass) then
    create policy "farm_read" on bank_transactions for select to authenticated
      using (farm_id = (select farm_id from profiles where id = auth.uid()));
  end if;

  if not exists (select 1 from pg_policy where polname = 'farm_insert'
                   and polrelid = 'public.bank_transactions'::regclass) then
    create policy "farm_insert" on bank_transactions for insert to authenticated
      with check (farm_id = (select farm_id from profiles where id = auth.uid()));
  end if;

  if not exists (select 1 from pg_policy where polname = 'farm_update'
                   and polrelid = 'public.bank_transactions'::regclass) then
    create policy "farm_update" on bank_transactions for update to authenticated
      using (farm_id = (select farm_id from profiles where id = auth.uid()));
  end if;

  if not exists (select 1 from pg_policy where polname = 'service_all'
                   and polrelid = 'public.bank_transactions'::regclass) then
    create policy "service_all" on bank_transactions for all to service_role
      using (true);
  end if;
end $$;
