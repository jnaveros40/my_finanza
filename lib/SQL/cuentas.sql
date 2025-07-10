-- SQL para crear la tabla de cuentas en Supabase
create table cuentas (
  id serial primary key,
  nombre text not null,
  tipo_cuenta text not null,
  moneda text not null,
  saldo_inicial numeric not null,
  tasa_rendimiento numeric,
  llave text,
  numero_cuenta text
);
