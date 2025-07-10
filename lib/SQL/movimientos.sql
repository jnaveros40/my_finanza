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
  cuenta_destino_id integer references cuentas(id) -- solo para transferencias
);
