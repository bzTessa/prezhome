-- ============================================================================
-- PrezHome · GRANTs para el rol service_role (usado por las Edge Functions)
-- ============================================================================
-- Las Edge Functions se conectan con la service_role key para operar saltándose
-- el RLS (p. ej. leer el perfil del usuario y consumir créditos de IA). Tras el
-- reset con CASCADE se perdieron estos permisos base, lo que provocaba
-- "permission denied for table profiles" (42501) dentro de las funciones.
--
-- Damos permisos base al service_role sobre el esquema public. El service_role
-- ya ignora el RLS por diseño (es un rol de confianza del servidor), así que
-- esto no afecta a la seguridad del cliente.
-- ============================================================================

grant usage on schema public to service_role;

grant select, insert, update, delete
  on all tables in schema public to service_role;

grant execute on all functions in schema public to service_role;

-- Que las tablas/funciones creadas en el futuro también hereden estos permisos.
alter default privileges in schema public
  grant select, insert, update, delete on tables to service_role;
alter default privileges in schema public
  grant execute on functions to service_role;
