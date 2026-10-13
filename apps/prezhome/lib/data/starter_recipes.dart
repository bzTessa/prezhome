/// Recetas caseras con las que empieza un hogar nuevo, para que el
/// cuestionario inicial termine con la semana ya planificada (ver
/// `StarterWeek`). Cantidades para 2 raciones; el plan las escala.
library;

class StarterRecipe {
  const StarterRecipe({
    required this.title,
    required this.mealTypes,
    required this.appliance,
    required this.prepMinutes,
    required this.cookMinutes,
    required this.ingredients,
    required this.steps,
    this.freezable = false,
  });

  final String title;
  final List<String> mealTypes;
  final String appliance;
  final int prepMinutes;
  final int cookMinutes;
  final bool freezable;

  /// (nombre, cantidad, unidad)
  final List<(String, double?, String?)> ingredients;
  final List<String> steps;
}

const starterRecipes = <StarterRecipe>[
  StarterRecipe(
    title: 'Lentejas con verduras',
    mealTypes: ['lunch'],
    appliance: 'pot',
    prepMinutes: 10,
    cookMinutes: 40,
    freezable: true,
    ingredients: [
      ('Lentejas', 160, 'g'),
      ('Zanahoria', 1, 'unidad'),
      ('Cebolla', 0.5, 'unidad'),
      ('Pimiento verde', 0.5, 'unidad'),
      ('Patata', 1, 'unidad'),
      ('Pimentón dulce', 1, 'cdta'),
      ('Aceite de oliva', 2, 'cda'),
    ],
    steps: [
      'Pica la cebolla, el pimiento y la zanahoria.',
      'Sofríe la verdura en la olla con el aceite durante 5 minutos.',
      'Añade el pimentón, las lentejas, la patata en trozos y agua hasta cubrir.',
      'Cuece a fuego medio 35 minutos, hasta que las lentejas estén tiernas.',
    ],
  ),
  StarterRecipe(
    title: 'Tortilla de patatas',
    mealTypes: ['dinner'],
    appliance: 'stovetop',
    prepMinutes: 10,
    cookMinutes: 25,
    ingredients: [
      ('Huevos', 4, 'unidad'),
      ('Patata', 2, 'unidad'),
      ('Cebolla', 0.5, 'unidad'),
      ('Aceite de oliva', 100, 'ml'),
    ],
    steps: [
      'Pela y corta las patatas y la cebolla en láminas finas.',
      'Fríelas a fuego medio en el aceite 20 minutos, hasta que estén blandas.',
      'Escúrrelas y mézclalas con los huevos batidos y sal.',
      'Cuaja la tortilla en la sartén 3 minutos por cada lado.',
    ],
  ),
  StarterRecipe(
    title: 'Pollo al horno con patatas',
    mealTypes: ['lunch'],
    appliance: 'oven',
    prepMinutes: 10,
    cookMinutes: 50,
    ingredients: [
      ('Muslos de pollo', 4, 'unidad'),
      ('Patata', 2, 'unidad'),
      ('Cebolla', 1, 'unidad'),
      ('Ajo', 2, 'diente'),
      ('Limón', 1, 'unidad'),
      ('Aceite de oliva', 2, 'cda'),
    ],
    steps: [
      'Precalienta el horno a 200 grados.',
      'Pon en la bandeja las patatas y la cebolla en rodajas, y encima el pollo.',
      'Riega con aceite, el zumo de limón, el ajo picado y sal.',
      'Hornea 50 minutos, dando la vuelta al pollo a mitad.',
    ],
  ),
  StarterRecipe(
    title: 'Macarrones con tomate y atún',
    mealTypes: ['lunch'],
    appliance: 'stovetop',
    prepMinutes: 5,
    cookMinutes: 15,
    ingredients: [
      ('Macarrones', 200, 'g'),
      ('Tomate frito', 200, 'g'),
      ('Atún en lata', 2, 'lata'),
      ('Queso rallado', 40, 'g'),
    ],
    steps: [
      'Cuece los macarrones en agua con sal unos 10 minutos.',
      'Escúrrelos y mézclalos con el tomate y el atún escurrido.',
      'Sirve con el queso rallado por encima.',
    ],
  ),
  StarterRecipe(
    title: 'Crema de calabacín',
    mealTypes: ['dinner'],
    appliance: 'pot',
    prepMinutes: 10,
    cookMinutes: 20,
    freezable: true,
    ingredients: [
      ('Calabacín', 2, 'unidad'),
      ('Patata', 1, 'unidad'),
      ('Cebolla', 0.5, 'unidad'),
      ('Quesitos', 2, 'unidad'),
      ('Aceite de oliva', 1, 'cda'),
    ],
    steps: [
      'Pica la cebolla y póchala en la olla con el aceite 5 minutos.',
      'Añade el calabacín y la patata en trozos, cubre con agua y sal.',
      'Cuece 15 minutos.',
      'Tritura con los quesitos hasta que quede fina.',
    ],
  ),
  StarterRecipe(
    title: 'Merluza al horno con limón',
    mealTypes: ['dinner'],
    appliance: 'oven',
    prepMinutes: 5,
    cookMinutes: 15,
    ingredients: [
      ('Merluza', 2, 'filete'),
      ('Limón', 1, 'unidad'),
      ('Ajo', 1, 'diente'),
      ('Perejil', null, null),
      ('Aceite de oliva', 2, 'cda'),
    ],
    steps: [
      'Precalienta el horno a 200 grados.',
      'Pon la merluza en una bandeja con sal, el ajo y el perejil picados.',
      'Riega con aceite y zumo de limón.',
      'Hornea 15 minutos.',
    ],
  ),
  StarterRecipe(
    title: 'Arroz con pollo',
    mealTypes: ['lunch'],
    appliance: 'stovetop',
    prepMinutes: 10,
    cookMinutes: 30,
    ingredients: [
      ('Arroz', 160, 'g'),
      ('Pechuga de pollo', 300, 'g'),
      ('Pimiento rojo', 0.5, 'unidad'),
      ('Tomate triturado', 100, 'g'),
      ('Caldo de pollo', 500, 'ml'),
      ('Aceite de oliva', 2, 'cda'),
    ],
    steps: [
      'Dora el pollo en trozos con el aceite 5 minutos.',
      'Añade el pimiento picado y el tomate, y sofríe 5 minutos.',
      'Echa el arroz, remueve y añade el caldo caliente.',
      'Cuece a fuego medio 18 minutos y deja reposar 5 minutos.',
    ],
  ),
  StarterRecipe(
    title: 'Garbanzos con espinacas',
    mealTypes: ['lunch'],
    appliance: 'stovetop',
    prepMinutes: 5,
    cookMinutes: 15,
    freezable: true,
    ingredients: [
      ('Garbanzos cocidos', 400, 'g'),
      ('Espinacas', 200, 'g'),
      ('Ajo', 2, 'diente'),
      ('Pimentón dulce', 1, 'cdta'),
      ('Comino', 0.5, 'cdta'),
      ('Aceite de oliva', 2, 'cda'),
    ],
    steps: [
      'Dora el ajo laminado en el aceite.',
      'Añade las espinacas y cocina 3 minutos hasta que se reduzcan.',
      'Echa el pimentón, el comino y los garbanzos escurridos.',
      'Cocina 10 minutos con un poco de agua y sal.',
    ],
  ),
  StarterRecipe(
    title: 'Ensalada de pasta',
    mealTypes: ['dinner'],
    appliance: 'stovetop',
    prepMinutes: 10,
    cookMinutes: 10,
    ingredients: [
      ('Pasta corta', 160, 'g'),
      ('Tomate cherry', 150, 'g'),
      ('Atún en lata', 1, 'lata'),
      ('Maíz dulce', 1, 'lata'),
      ('Aceitunas', 50, 'g'),
      ('Aceite de oliva', 2, 'cda'),
    ],
    steps: [
      'Cuece la pasta 10 minutos, escúrrela y enfríala con agua.',
      'Mézclala con los tomates partidos, el atún, el maíz y las aceitunas.',
      'Aliña con aceite y sal.',
    ],
  ),
  StarterRecipe(
    title: 'Revuelto de champiñones',
    mealTypes: ['dinner'],
    appliance: 'stovetop',
    prepMinutes: 5,
    cookMinutes: 10,
    ingredients: [
      ('Huevos', 4, 'unidad'),
      ('Champiñones', 250, 'g'),
      ('Ajo', 1, 'diente'),
      ('Pan', 4, 'rebanada'),
      ('Aceite de oliva', 1, 'cda'),
    ],
    steps: [
      'Saltea los champiñones laminados con el ajo y el aceite 5 minutos.',
      'Baja el fuego, añade los huevos batidos con sal y remueve hasta que cuajen.',
      'Sirve con pan tostado.',
    ],
  ),
  StarterRecipe(
    title: 'Albóndigas en salsa de tomate',
    mealTypes: ['lunch'],
    appliance: 'stovetop',
    prepMinutes: 20,
    cookMinutes: 25,
    freezable: true,
    ingredients: [
      ('Carne picada', 400, 'g'),
      ('Huevos', 1, 'unidad'),
      ('Pan rallado', 40, 'g'),
      ('Ajo', 1, 'diente'),
      ('Tomate triturado', 400, 'g'),
      ('Cebolla', 0.5, 'unidad'),
      ('Aceite de oliva', 3, 'cda'),
    ],
    steps: [
      'Mezcla la carne con el huevo, el pan rallado, el ajo picado y sal.',
      'Forma bolas y dóralas en la sartén con el aceite.',
      'Sofríe la cebolla picada, añade el tomate y cocina 5 minutos.',
      'Echa las albóndigas en la salsa y cuece 20 minutos.',
    ],
  ),
  StarterRecipe(
    title: 'Salmón a la plancha con verduras',
    mealTypes: ['dinner'],
    appliance: 'stovetop',
    prepMinutes: 10,
    cookMinutes: 15,
    ingredients: [
      ('Salmón', 2, 'filete'),
      ('Calabacín', 1, 'unidad'),
      ('Pimiento rojo', 0.5, 'unidad'),
      ('Aceite de oliva', 2, 'cda'),
    ],
    steps: [
      'Corta las verduras en tiras y saltéalas con aceite 8 minutos.',
      'Haz el salmón a la plancha 3 minutos por cada lado.',
      'Sirve el salmón con las verduras y sal.',
    ],
  ),
  StarterRecipe(
    title: 'Sopa de fideos',
    mealTypes: ['dinner'],
    appliance: 'pot',
    prepMinutes: 5,
    cookMinutes: 10,
    ingredients: [
      ('Caldo de pollo', 1, 'l'),
      ('Fideos', 80, 'g'),
      ('Huevos', 1, 'unidad'),
    ],
    steps: [
      'Calienta el caldo hasta que hierva.',
      'Añade los fideos y cuece 5 minutos.',
      'Sirve con el huevo cocido picado por encima.',
    ],
  ),
  StarterRecipe(
    title: 'Pisto con huevo',
    mealTypes: ['dinner'],
    appliance: 'stovetop',
    prepMinutes: 15,
    cookMinutes: 30,
    freezable: true,
    ingredients: [
      ('Calabacín', 1, 'unidad'),
      ('Berenjena', 1, 'unidad'),
      ('Pimiento rojo', 1, 'unidad'),
      ('Cebolla', 1, 'unidad'),
      ('Tomate triturado', 200, 'g'),
      ('Huevos', 2, 'unidad'),
      ('Aceite de oliva', 3, 'cda'),
    ],
    steps: [
      'Pica todas las verduras en dados.',
      'Pocha la cebolla y el pimiento en el aceite 10 minutos.',
      'Añade el calabacín y la berenjena y cocina 10 minutos.',
      'Echa el tomate y cocina 10 minutos más; sirve con un huevo frito.',
    ],
  ),
];
