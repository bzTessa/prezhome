-- PrezWallet: una cuenta compartida con el hogar se ve con su saldo real.
-- Antes la vista sumaba solo los movimientos que el RLS deja ver, así que
-- los demás miembros veían el saldo inicial más los movimientos marcados
-- Hogar. Ahora el saldo se calcula con todos los movimientos de la cuenta,
-- pero solo para cuentas que el usuario puede ver (suyas o de su hogar).
-- Los movimientos sueltos siguen siendo privados.

create or replace function public.wallet_account_balances_visible()
returns table (account_id uuid, balance numeric)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select a.id,
         a.opening_balance + coalesce(sum(t.amount), 0)
  from public.wallet_accounts a
  left join public.wallet_transactions t on t.account_id = a.id
  where a.owner_id = auth.uid()
     or (a.home_id is not null and a.home_id = public.auth_home_id())
  group by a.id;
$$;

revoke execute on function public.wallet_account_balances_visible()
  from public, anon;
grant execute on function public.wallet_account_balances_visible()
  to authenticated;

create or replace view public.wallet_account_balances
with (security_invoker = true) as
  select account_id, balance
  from public.wallet_account_balances_visible();

grant select on public.wallet_account_balances to authenticated;
