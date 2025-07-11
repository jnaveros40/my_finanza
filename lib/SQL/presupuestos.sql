-- SQL para la tabla de presupuestos 50/30/20
create table f_presupuestos (
  id serial primary key,
  periodo_mes smallint not null,
  periodo_anio smallint not null,
  monto_total numeric not null,
  porcentaje_necesidades numeric not null,
  porcentaje_deseos numeric not null,
  porcentaje_ahorros numeric not null,
  monto_necesidades numeric not null,
  monto_deseos numeric not null,
  monto_ahorros numeric not null,
  actual_necesidades numeric not null default 0,
  actual_deseos numeric not null default 0,
  actual_ahorros numeric not null default 0,
  fecha_creacion timestamp not null default now(),
  fecha_actualizacion timestamp not null default now()
);
-- La suma de los porcentajes debe ser 100. Validar en la app.
-- Los montos se calculan en la app según el monto_total y los porcentajes.
