# PrezHome · Principios de Seguridad y Auditoría

Aplica estos principios en TODO cambio de backend, base de datos o código que
toque datos de usuario. PrezHome es una app de hogar para una pareja.

## Modelo de datos
- Un usuario pertenece a UN solo hogar (`profiles.home_id`).
- Todas las tablas de datos de usuario llevan `home_id` y RLS por hogar.
- Función central de RLS: `public.auth_home_id()` (SECURITY DEFINER, search_path fijo).

## 1. Aislamiento de datos (RLS)
- RLS activado desde el diseño en TODA tabla de datos de usuario.
- Regla base: solo miembros del mismo `home_id` pueden leer/modificar los datos.
- Ningún acceso directo e ilimitado a tablas ajenas o compartidas sin validación.

## 2. Separación de datos sensibles y de control
- NO mezclar datos operativos (recetas, inventario, tareas, tickets) con campos
  de control: roles, permisos, suscripciones o límites de uso de IA.
- Roles → tabla de control `home_members` (el cliente solo LEE, nunca escribe).
- Suscripción y límites de IA → tabla `subscriptions` (el cliente solo LEE).
- Cambios de rol/plan/home_id solo vía RPC `SECURITY DEFINER` o `service_role`.
- El cliente NUNCA puede modificar su propio rol, permisos ni límites.

## 3. Privacidad OCR de tickets
- Imágenes de tickets en bucket de Storage PRIVADO (`tickets`, ruta `tickets/{home_id}/...`).
- Acceso solo bajo el token del usuario, restringido a su `home_id`.
- Sanitizar los datos antes de guardar para no almacenar PII sensible por error.

## 4. Auditoría preventiva con IA
Antes de dar por terminado cualquier cambio de DB/backend, autoaudita con estas preguntas:
1. ¿Puede un usuario modificar su rol, permisos o campos de control desde el cliente?
2. ¿Hay alguna brecha que exponga datos entre usuarios/hogares o accesos no autorizados?
3. ¿Hay puntos manipulables en llamadas a APIs o consumo de IA?
Identifica fallos ocultos y corrige antes de entregar.

## Notas de implementación
- La `publishableKey` en el cliente es normal; la seguridad real recae en RLS.
- Nunca poner la `service_role key` en el cliente Flutter.
