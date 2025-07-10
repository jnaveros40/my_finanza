-- SQL para crear la tabla de movimientos en Supabase
create table movimientos (
  id serial primary key,
  descripcion text not null,
  monto numeric not null,
  fecha date not null,
  cuenta_id integer not null references cuentas(id),
  categoria_id integer references categorias(id),
  tipo_movimiento text not null, -- ingreso, gasto, transferencia
  observacion text,
  cuenta_destino_id integer references cuentas(id), -- solo para transferencias y pagos
  saldo_origen_antes numeric,
  saldo_origen_despues numeric,
  saldo_destino_antes numeric,
  saldo_destino_despues numeric
);

-- Adecuaciones posteriores:
-- 2025-07-10: Agregadas columnas para registrar el saldo antes y después del movimiento en cuenta origen y destino.
ALTER TABLE movimientos ADD COLUMN saldo_origen_antes numeric;
ALTER TABLE movimientos ADD COLUMN saldo_origen_despues numeric;
ALTER TABLE movimientos ADD COLUMN saldo_destino_antes numeric;
ALTER TABLE movimientos ADD COLUMN saldo_destino_despues numeric;
