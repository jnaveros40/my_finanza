-- SQL para crear la tabla de categorías en Supabase
create table f_categorias (
  id serial primary key,
  nombre text not null,
  tipo_categoria text not null,
  tipo_presupuesto text
);
