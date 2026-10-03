# Guia de configuracion de secrets para CI/CD

Esta guia esta pensada para ti, Tessa. Explica, paso a paso y sin tecnicismos,
que "secrets" (datos secretos) debes configurar en GitHub para que la
automatizacion del proyecto funcione, de donde sale cada valor y por que esta
parte la haces tu.

## Por que esto lo configuras tu y no el asistente

Los secrets son credenciales de tu proyecto de Supabase (y una clave de Google).
Son como contrasenas: dan acceso a tu base de datos y a tus servicios. Por
seguridad, el asistente NO acepta ni ve esas credenciales. Los workflows de
automatizacion ya quedan listos en el repositorio, pero quien pega las
credenciales en GitHub eres tu.

Lo importante que debes saber:

- Los secrets se guardan cifrados dentro de GitHub. Nunca aparecen en el codigo
  ni en el historial del repositorio.
- Una vez guardados, solo se usan dentro de los procesos automaticos (los
  "workflows"). Ni siquiera tu podras volver a verlos en texto; solo
  reemplazarlos por un valor nuevo.
- El asistente deja preparada la automatizacion, pero no puede desplegar por ti
  ni ver tus credenciales.

## Como abrir la pantalla de secrets en GitHub

Sigue esta ruta exacta dentro del navegador:

1. Entra en la pagina del repositorio en GitHub.
2. Pulsa la pestana **Settings** (Ajustes), arriba del todo del repositorio.
3. En el menu de la izquierda, busca y despliega **Secrets and variables**.
4. Dentro de ese apartado, pulsa **Actions**.
5. Pulsa el boton **New repository secret** (Nuevo secret del repositorio).
6. Rellena los dos campos:
   - En **Name** (Nombre) escribe el nombre del secret EXACTAMENTE como aparece
     en esta guia, en mayusculas y con guiones bajos. Un solo caracter distinto
     hace que la automatizacion no lo encuentre.
   - En **Secret** (Valor) pega el valor correspondiente.
7. Pulsa **Add secret** (Anadir secret) para guardarlo.
8. Repite los pasos 5 a 7 para cada uno de los secrets de esta guia.

> Nota importante: los nombres de los secrets deben coincidir EXACTAMENTE con
> los que usan los workflows del repositorio. Si cambias el nombre, aunque sea
> una letra, la automatizacion fallara porque no sabra encontrarlo.

## Dos sitios distintos para los secrets (no los confundas)

Hay dos lugares donde viven los datos privados, y cada uno sirve para una cosa:

- **Secrets del repositorio en GitHub Actions** (los que explica esta guia): los
  usa la automatizacion para la CLI de Supabase, para aplicar migraciones y para
  desplegar las funciones. Son `SUPABASE_ACCESS_TOKEN`, `SUPABASE_PROJECT_REF` y
  `SUPABASE_DB_PASSWORD`.
- **Secrets de Edge Functions dentro del panel de Supabase**: los usan las
  funciones cuando se ejecutan (por ejemplo la clave de Unsplash para las fotos,
  o la clave de Gemini para generar recetas). Esos NO van en GitHub: van en el
  panel web de Supabase, en **Edge Functions -> Secrets**.

## Las funciones ahora se despliegan solas

Novedad importante: las Edge Functions (las funciones en `supabase/functions/`)
**ya se despliegan automaticamente** cuando un cambio llega a `main`. El workflow
de despliegue instala la CLI de Supabase y despliega todas las funciones por su
nombre: `analyze-meal`, `discover-recipes`, `generate-recipe`, `recipe-photo` y
`scan-ticket`.

Esto significa que **ya no hace falta ejecutar nunca a mano**
`supabase functions deploy`. En particular, las funciones de Gemini
(`generate-recipe`, `discover-recipes`, `analyze-meal`), que antes habia que
desplegar a mano, tambien se despliegan solas con este workflow.

Para que las **fotos de las recetas** funcionen, lo UNICO que tienes que hacer
tu es anadir, una sola vez y sin terminal, el secret `UNSPLASH_ACCESS_KEY` en el
panel web de Supabase (**Edge Functions -> Secrets**, o
**Project Settings -> Edge Functions -> Secrets**). El paso a paso con capturas
mentales esta en `docs/RECETAS_FOTOS.md`. Ojo: ese `UNSPLASH_ACCESS_KEY` NO es un
secret de GitHub Actions; va en el panel de Supabase, que es distinto de los
"repository secrets" que explica el resto de esta guia (esos siguen siendo solo
para la CLI y las migraciones).

## Los secrets, uno por uno

### 1. SUPABASE_ACCESS_TOKEN

- **Para que sirve:** es un token personal que permite a la automatizacion
  iniciar sesion en Supabase (como si entraras tu con tu usuario). Lo usa el
  despliegue de migraciones.
- **Donde conseguirlo:** entra en el panel de Supabase, en la pagina de tokens
  de acceso: [https://supabase.com/dashboard/account/tokens](https://supabase.com/dashboard/account/tokens)
  (tambien se llega desde **Account** -> **Access Tokens**). Genera un token
  nuevo y dale un nombre que reconozcas, por ejemplo "GitHub Actions".
- **Que pegar:** copia el token completo que te muestra Supabase y pegalo en el
  campo **Secret**. Supabase solo te ensena el token una vez al crearlo, asi que
  copialo en ese momento. Si lo pierdes, genera uno nuevo.

### 2. SUPABASE_PROJECT_REF

- **Para que sirve:** es el identificador de tu proyecto de Supabase. Le dice a
  la automatizacion a que proyecto conectarse.
- **Donde conseguirlo:** para este proyecto el valor es exactamente:

  ```
  ubrihtnnkbwcbchvvlno
  ```

  La URL de tu proyecto es `https://ubrihtnnkbwcbchvvlno.supabase.co` y el
  identificador (ref) es la parte que va antes de `.supabase.co`, es decir
  `ubrihtnnkbwcbchvvlno`.
- **Que pegar:** escribe o pega exactamente `ubrihtnnkbwcbchvvlno` en el campo
  **Secret** (sin `https://`, sin `.supabase.co` y sin espacios).

### 3. SUPABASE_DB_PASSWORD

- **Para que sirve:** es la contrasena de la base de datos de tu proyecto. La
  automatizacion la necesita para conectarse y aplicar los cambios de la base de
  datos (las migraciones).
- **Donde conseguirlo:** en el panel de Supabase, entra en tu proyecto y ve a
  **Project Settings** -> **Database** -> apartado **Database password**. Ahi
  esta la contrasena de la base de datos.
- **Que pegar:** pega la contrasena de la base de datos en el campo **Secret**.
  Si no la recuerdas, en esa misma pantalla puedes reiniciarla para generar una
  nueva. Aviso: reiniciar la contrasena puede afectar a otras conexiones que ya
  esten usando la contrasena antigua (otras aplicaciones o servicios), asi que
  si la cambias, acuerdate de actualizarla tambien aqui en GitHub.

### 4. GEMINI_API_KEY

- **Para que sirve:** es la clave de la API de Google Gemini. En este proyecto
  la usan las Edge Functions de Supabase (las funciones en `supabase/functions/`)
  cuando se ejecutan, por ejemplo para generar o descubrir recetas.
- **Donde va este secret:** esta clave la usan las Edge Functions de Supabase en
  tiempo de ejecucion, asi que va en el panel web de Supabase
  (**Edge Functions -> Secrets**), NO como repository secret de GitHub Actions.
  El workflow de despliegue ahora instala las funciones de Gemini
  (`generate-recipe`, `discover-recipes`, `analyze-meal`) de forma automatica al
  llegar un cambio a `main`, pero para que funcionen en ejecucion necesitan tener
  su `GEMINI_API_KEY` guardada en los secrets de Edge Functions de Supabase. Si
  en el futuro algun workflow de GitHub Actions necesitara esta clave, entonces
  si tendrias que anadirla tambien como repository secret de Actions con este
  mismo nombre exacto, `GEMINI_API_KEY`; hoy no hace falta.
- **Donde conseguirlo:** en Google AI Studio, en la pagina de claves de API:
  [https://aistudio.google.com/app/apikey](https://aistudio.google.com/app/apikey)
- **Que pegar:** copia la clave completa de Gemini y pegala en el campo
  **Secret** (ya sea como secret de Edge Function en Supabase, que es donde se
  usa hoy, o como repository secret de Actions si en el futuro hiciera falta).

## Tabla resumen

| Nombre del secret | Para que sirve | Donde conseguirlo |
| --- | --- | --- |
| `SUPABASE_ACCESS_TOKEN` | Permite a la automatizacion iniciar sesion en Supabase para desplegar migraciones | Panel de Supabase, Account -> Access Tokens: https://supabase.com/dashboard/account/tokens |
| `SUPABASE_PROJECT_REF` | Identifica a que proyecto de Supabase conectarse | Valor fijo de este proyecto: `ubrihtnnkbwcbchvvlno` (parte anterior a `.supabase.co` en `https://ubrihtnnkbwcbchvvlno.supabase.co`) |
| `SUPABASE_DB_PASSWORD` | Contrasena de la base de datos, necesaria para aplicar los cambios | Panel de Supabase, Project Settings -> Database -> Database password |
| `GEMINI_API_KEY` | Clave de Google Gemini que usan las Edge Functions de Supabase | Google AI Studio: https://aistudio.google.com/app/apikey |

> Recuerda: los nombres deben coincidir EXACTAMENTE con los que usan los
> workflows. Copialos tal cual aparecen en esta tabla (mayusculas y guiones
> bajos incluidos).

## Aprobacion manual real de los despliegues (Environment "production")

Para que la aprobacion de un despliegue sea de verdad (que GitHub pare el
proceso y espere a que una persona lo apruebe, en lugar de aplicarse solo), el
workflow de despliegue usa un "Environment" (entorno) llamado `production`. Si
quieres que esa aprobacion manual quede forzada por la plataforma, configuralo
asi una sola vez:

1. Entra en la pagina del repositorio en GitHub.
2. Pulsa la pestana **Settings** (Ajustes).
3. En el menu de la izquierda, pulsa **Environments** (Entornos).
4. Pulsa **New environment** (Nuevo entorno), escribe exactamente `production`
   como nombre y pulsa **Configure environment**.
5. Marca la opcion **Required reviewers** (Revisores requeridos) y anadete a ti
   misma (o a quien deba aprobar). Guarda los cambios con **Save protection rules**.

A partir de ese momento, cada vez que haya que desplegar migraciones a Supabase,
el proceso quedara EN PAUSA esperando tu aprobacion. Recibiras un aviso en GitHub
y tendras que pulsar **Review deployments** -> **Approve and deploy** para que se
apliquen los cambios. Si no lo apruebas, no se despliega nada.

> Nota honesta: si NO configuras este entorno con revisores requeridos, el
> despliegue se aplicara de forma automatica en cuanto cambien las migraciones
> en `main`. El paso de pausa y aprobacion solo existe si creas el entorno
> `production` con la regla de revisores como se explica arriba. El gate de
> seguridad del workflow de validacion (DROP, RLS, auth) actua antes, en los
> pull requests, pero esa comprobacion por si sola no detiene el despliegue a
> `main`: para detenerlo de verdad necesitas el entorno protegido.

## Que depende de ti y que deja listo el asistente

Para que quede claro quien hace que:

- **Tu te encargas de:**
  - Configurar los secrets en GitHub siguiendo esta guia.
  - Configurar el entorno `production` con revisores requeridos (ver la seccion
    "Aprobacion manual real de los despliegues") si quieres que GitHub pare el
    despliegue y espere tu aprobacion. Mientras no lo configures, los
    despliegues a `main` se aplican automaticamente.
  - Aprobar y ejecutar los despliegues cuando corresponda. El workflow de
    validacion marca para revision manual los cambios delicados (destructivos o
    de permisos de seguridad) en los pull requests; y, si configuras el entorno
    `production`, cada despliegue a la base de datos esperara tu aprobacion
    explicita antes de aplicarse.
- **El asistente deja listo:**
  - Los workflows de automatizacion (CI, despliegue y validacion de cambios) ya
    preparados en el repositorio.
- **El asistente NO puede:**
  - Ver ni aceptar tus credenciales de Supabase o de Google.
  - Desplegar por ti ni aprobar despliegues en tu nombre.

Si configuras bien los cuatro valores con sus nombres exactos, la automatizacion
podra hacer su trabajo y tu mantienes el control de las credenciales y de las
aprobaciones.
