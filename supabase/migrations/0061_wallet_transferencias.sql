-- ============================================================================
-- PrezWallet · Transferencias entre cuentas
-- ============================================================================
-- Idempotente. Una transferencia son dos movimientos con el mismo
-- transfer_id: uno negativo en la cuenta de origen y otro positivo en la de
-- destino. Cambian los saldos pero la app no los cuenta como gasto ni ingreso.
-- Las políticas RLS de wallet_transactions no cambian.
-- ============================================================================

alter table public.wallet_transactions
  add column if not exists transfer_id uuid;

create index if not exists wallet_transactions_transfer_idx
  on public.wallet_transactions (transfer_id)
  where transfer_id is not null;
