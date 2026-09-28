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

## Principios de seguridad
Ver `.kiro/steering/security.md`. Perfil físico privado por defecto; recetas
compartidas en el hogar; RLS en todas las tablas.
