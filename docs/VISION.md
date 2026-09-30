# PrezHome · Visión del producto

App de gestión del hogar para una pareja (hogar compartido), con Presidente Miau
como mascota. Backend en Supabase con RLS por hogar. Estilo visual "Cozy"
(amarillo pastel, madera clara, tarjetas redondeadas, sin bordes duros).

## Objetivo final
Que tú marques las recetas que te gustan y la app:
1. Genere un plan semanal equilibrado (según tus calorías/macros para mantener peso).
2. Dé variedad (no repetir lo mismo días seguidos).
3. Use lo que ya hay en el congelador antes de mandar cocinar/comprar.
4. Planifique a largo plazo: sugerir cocinar de más para reponer el congelador.
5. Te diga cada día qué hacer (cocinar / pasar de congelador a nevera / consumir).
6. Optimice el uso de horno/sartén/olla al cocinar en lote.
7. Genere la lista de la compra con cantidades según la gente del hogar.
8. Vuelque el plan y los avisos a Google Calendar.

## Roadmap por fases

### FASE 1 — Cimientos (EN CURSO)
- Recetas: título, descripción, raciones, kcal, macros (P/C/G), ingredientes con
  cantidades, tiempo de preparación, tiempo de cocción, aparato de cocina
  (Horno/Sartén/Olla/Airfryer/Micro/Ninguno), tipo de comida
  (Desayuno/Comida/Cena/Snack), favorita. Añadir/editar desde la app.
- Perfil nutricional: sexo, fecha de nacimiento, altura (cm), peso (kg), nivel de
  actividad (5 niveles), objetivo = mantener. Cálculo Mifflin-St Jeor →
  calorías diarias y macros. Toggle público/privado (la pareja lo ve si es público).

### FASE 2 — Congelador inteligente
- Inventario de congelador que distingue: plato terminado (vinculado a receta,
  con nº de raciones/tapers), preparado intermedio (sofrito, verdura mixta),
  ingrediente en crudo (cebolla picada, pollo a dados). Con cantidad, fecha de
  congelación y caducidad.

### FASE 3 — Planificador semanal equilibrado
- Genera plan de 7 días respetando kcal/macros y variedad, priorizando lo que ya
  está congelado, y sugiriendo cocinar de más para reponer stock (largo plazo).

### FASE 4 — Agenda de acciones diarias
- Lista diaria: cocinar / pasar de congelador a nevera (descongelar a tiempo) /
  consumir, con el timing correcto.

### FASE 5 — Lista de la compra
- Cantidades escaladas según los miembros del hogar, teniendo en cuenta lo que hay
  que congelar y lo que ya hay en stock.

### FASE 6 — Optimizador de aparatos
- Agenda qué cocinar en paralelo (horno/sartén/olla) para minimizar tiempo total.

### FASE 7 — Google Calendar
- Conectar cuenta (OAuth) y volcar plan + avisos diarios como eventos.

## Cola de mejoras pendientes (por hacer, en orden aproximado)

1. **Comer fuera de casa (por miembro/día):** un miembro puede comer fuera
   ciertos días (ej. en el trabajo). Poder indicar aprox. lo que consume fuera
   y que esos días solo cuenten cena/postre en casa. Ajustable por persona.
2. **Zona de Ajustes organizada:** separar ajustes por tema — lo de comidas en
   Perfil Nutricional; lo de tareas, visualización y hogar en Hogar/Ajustes.
   Incluir mostrar/ocultar los cálculos de gramos/kcal (personalizable).
3. **Onboarding + login moderno:** pantallas de bienvenida que expliquen la app
   + ajuste de perfil antes del registro; login con Google (OAuth) además del
   correo; sesión persistente (no pedir correo al reabrir si no se cerró sesión).
4. **Estadísticas con gráficos:** en Hogar y Economía — puntos de tareas, gasto
   por tienda/categoría, evolución de precios.
5. **Aprendizaje de rutinas (IA):** aprender hábitos de compra/comida a partir de
   los tickets y predecir (qué toca comprar, gasto mensual esperado).
6. **Planificador semanal:** generar el plan de comidas equilibrado que llena el
   calendario, con variedad, uso del congelador y lista de la compra.
7. **Enlace de vídeo en recetas (Instagram/TikTok/YouTube):** guardar el enlace
   como apoyo ("Ver vídeo original"). La transcripción automática del vídeo NO es
   viable de forma fiable (las plataformas bloquean el acceso); alternativa:
   pegar la descripción del post en "Rellenar con IA".

## Notas de diseño
- Sin emojis en la interfaz; estética "Cozy" profesional.
- Presidente Miau como personaje (varias poses según contexto).
- Lenguaje inclusivo de convivencia: "hogar/miembros", no "pareja".
- Útil por defecto pero personalizable/ocultable (cada quien ve lo que quiere).

## Principios de seguridad
Ver `.kiro/steering/security.md`. Perfil físico privado por defecto; recetas
compartidas en el hogar; RLS en todas las tablas.
