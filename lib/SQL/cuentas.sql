
-- SQL para crear la tabla de cuentas en Supabase
create table f_cuentas (
  id serial primary key,
  nombre text not null,
  tipo_cuenta text not null,
  moneda text not null,
  saldo_inicial numeric not null,
  saldo_actual numeric,
  tasa_rendimiento numeric,
  llave text,
  numero_cuenta text,
  cupo numeric, -- Solo para tarjetas de crédito
  fecha_corte smallint, -- Día del mes (1-30) de corte, solo para tarjetas de crédito
  fecha_pago smallint -- Día del mes (1-30) de pago, solo para tarjetas de crédito
  
);

-- 2025-07-10: Modificados fecha_corte y fecha_pago a smallint (día del mes 1-30) para tarjetas de crédito.
-- ALTER TABLE cuentas ALTER COLUMN fecha_corte TYPE smallint USING fecha_corte::smallint;
-- ALTER TABLE cuentas ALTER COLUMN fecha_pago TYPE smallint USING fecha_pago::smallint;
ALTER TABLE f_cuentas ADD COLUMN cupo numeric;
ALTER TABLE f_cuentas ADD COLUMN fecha_corte smallint;
ALTER TABLE f_cuentas ADD COLUMN fecha_pago smallint;
-- 2025-07-10: Agregado campo saldo_actual para reflejar el saldo en tiempo real de la cuenta.
-- Para cuentas existentes, puedes inicializar saldo_actual igual a saldo_inicial:
-- UPDATE cuentas SET saldo_actual = saldo_inicial;
-- Script para agregar saldo_actual a una tabla ya existente y actualizarlo con el saldo inicial
-- Ejecutar en la consola SQL de Supabase si la tabla ya existe:
   ALTER TABLE f_cuentas ADD COLUMN saldo_actual numeric;
   UPDATE f_cuentas SET saldo_actual = saldo_inicial;