-- ============================================================
-- Money Tracker - schema Supabase
-- Eseguire una volta nel SQL Editor del progetto.
-- ============================================================


-- Conti (contanti, conto corrente, carte...)
create table public.accounts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name text not null,
  initial_balance numeric(12,2) not null default 0,
  sort int not null default 0,
  archived boolean not null default false,
  created_at timestamptz not null default now()
);

-- Categorie di spesa / entrata, con budget mensile opzionale
create table public.categories (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name text not null,
  kind text not null check (kind in ('expense','income')),
  icon text not null default '•',
  monthly_budget numeric(12,2) check (monthly_budget is null or monthly_budget > 0),
  sort int not null default 0,
  archived boolean not null default false,
  created_at timestamptz not null default now(),
  unique (user_id, kind, name)
);

-- Movimenti ricorrenti (affitto, abbonamenti, stipendio...)
create table public.recurring (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  kind text not null check (kind in ('expense','income')),
  amount numeric(12,2) not null check (amount > 0),
  category_id uuid references public.categories(id) on delete set null,
  account_id uuid not null references public.accounts(id) on delete cascade,
  note text,
  day_of_month int not null check (day_of_month between 1 and 28),
  start_date date not null default current_date,
  end_date date,
  last_generated date,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

-- Movimenti
create table public.transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  date date not null default current_date,
  kind text not null check (kind in ('expense','income','transfer')),
  amount numeric(12,2) not null check (amount > 0),
  category_id uuid references public.categories(id) on delete set null,
  account_id uuid not null references public.accounts(id) on delete restrict,
  to_account_id uuid references public.accounts(id) on delete restrict,
  note text,
  recurring_id uuid references public.recurring(id) on delete set null,
  created_at timestamptz not null default now(),
  constraint transfer_has_target check ((kind = 'transfer') = (to_account_id is not null)),
  constraint transfer_distinct check (to_account_id is null or to_account_id <> account_id),
  -- impedisce di generare due volte la stessa ricorrenza nello stesso giorno
  -- (i NULL sono distinti, quindi non tocca i movimenti manuali)
  constraint recurring_once unique (recurring_id, date)
);

create index transactions_user_date on public.transactions (user_id, date desc);
create index transactions_created on public.transactions (user_id, created_at desc);
-- indici sulle foreign key (servono a delete/update sui conti e sulle categorie)
create index transactions_account on public.transactions (account_id);
create index transactions_to_account on public.transactions (to_account_id);
create index transactions_category on public.transactions (category_id);
create index recurring_account on public.recurring (account_id);
create index recurring_category on public.recurring (category_id);
create index recurring_user on public.recurring (user_id);
create index accounts_user on public.accounts (user_id);

-- ------------------------------------------------------------
-- Row Level Security: ognuno vede e modifica solo le proprie righe
-- ------------------------------------------------------------
do $$
declare t text;
begin
  foreach t in array array['accounts','categories','recurring','transactions'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format(
      'create policy own_rows on public.%I for all to authenticated
         using (user_id = (select auth.uid()))
         with check (user_id = (select auth.uid()))', t);
  end loop;
end $$;

-- ------------------------------------------------------------
-- Viste (security_invoker: rispettano la RLS di chi interroga)
-- ------------------------------------------------------------

-- Saldo attuale per conto
create view public.account_balances with (security_invoker = true) as
select
  a.id,
  a.name,
  a.initial_balance + coalesce(sum(
    case
      when t.kind = 'income'   and t.account_id = a.id    then  t.amount
      when t.kind = 'expense'  and t.account_id = a.id    then -t.amount
      when t.kind = 'transfer' and t.account_id = a.id    then -t.amount
      when t.kind = 'transfer' and t.to_account_id = a.id then  t.amount
    end), 0) as balance
from public.accounts a
left join public.transactions t
  on t.account_id = a.id or t.to_account_id = a.id
group by a.id;

-- Totali mensili (entrate / uscite, trasferimenti esclusi)
create view public.monthly_totals with (security_invoker = true) as
select
  date_trunc('month', date)::date as month,
  coalesce(sum(amount) filter (where kind = 'income'), 0)  as income,
  coalesce(sum(amount) filter (where kind = 'expense'), 0) as expense
from public.transactions
group by 1;
