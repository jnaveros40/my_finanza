-- SQL para crear la tabla de movimientos en Supabase
create table f_movimientos (
  id serial primary key,
  descripcion text not null,
  monto numeric not null,
  fecha date not null,
  cuenta_id integer not null references cuentas(id),
  categoria_id integer references categorias(id),
  tipo_movimiento text not null, -- ingreso, gasto, transferencia
  observacion text,
  cuenta_destino_id integer references cuentas(id), -- solo para transferencias y pagos
  presupuesto_id integer references f_presupuestos(id),
  presupuesto_actual numeric,
  presupuesto_nuevo numeric,
  saldo_origen_antes numeric,
  saldo_origen_despues numeric,
  saldo_destino_antes numeric,
  saldo_destino_despues numeric
);

-- Adecuaciones posteriores:
-- 2025-07-10: Agregadas columnas para registrar el saldo antes y después del movimiento en cuenta origen y destino.
ALTER TABLE f_movimientos ADD COLUMN saldo_origen_antes numeric;
ALTER TABLE f_movimientos ADD COLUMN saldo_origen_despues numeric;
ALTER TABLE f_movimientos ADD COLUMN saldo_destino_antes numeric;
ALTER TABLE f_movimientos ADD COLUMN saldo_destino_despues numeric;
-- 2025-07-11: Auditoría de presupuesto en movimientos
ALTER TABLE f_movimientos ADD COLUMN presupuesto_id integer references f_presupuestos(id);
ALTER TABLE f_movimientos ADD COLUMN presupuesto_actual numeric;
ALTER TABLE f_movimientos ADD COLUMN presupuesto_nuevo numeric;
