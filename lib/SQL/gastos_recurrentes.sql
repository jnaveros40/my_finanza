-- SQL para crear la tabla de gastos_recurrentes en Supabase
create table gastos_recurrentes (
  id serial primary key,
  frecuencia_dias integer not null,
  descripcion text not null,
  monto numeric not null,
  cuenta_id integer not null references cuentas(id),
  categoria_id integer not null references categorias(id),
  fecha_inicio date not null,
  fecha_final date,
  observacion text
);
