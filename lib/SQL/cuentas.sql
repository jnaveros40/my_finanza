
-- SQL para crear la tabla de cuentas en Supabase
create table cuentas (
  id serial primary key,
  nombre text not null,
  tipo_cuenta text not null,
  moneda text not null,
  saldo_inicial numeric not null,
  saldo_actual numeric,
  tasa_rendimiento numeric,
  llave text,
  numero_cuenta text
  
);

-- Adecuaciones posteriores:
-- 2025-07-10: Agregado campo saldo_actual para reflejar el saldo en tiempo real de la cuenta.
-- Para cuentas existentes, puedes inicializar saldo_actual igual a saldo_inicial:
-- UPDATE cuentas SET saldo_actual = saldo_inicial;
-- Script para agregar saldo_actual a una tabla ya existente y actualizarlo con el saldo inicial
-- Ejecutar en la consola SQL de Supabase si la tabla ya existe:
   ALTER TABLE cuentas ADD COLUMN saldo_actual numeric;
   UPDATE cuentas SET saldo_actual = saldo_inicial;