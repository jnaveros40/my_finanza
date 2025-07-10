-- SQL para crear la tabla de cuentas en Supabase
create table cuentas (
  id serial primary key,
  nombre text not null,
  tipo_cuenta text not null,
  moneda text not null,
  saldo_inicial numeric not null,
  tasa_rendimiento numeric not null,
  llave text not null,
  numero_cuenta text not null
);
