import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Tipo de tarea del hogar, sacado del título, para darle icono y color.
/// Su nombre visible está en el ARB (`taskKind`, por [name]).
enum TaskKind {
  bano(Icons.bathtub_rounded),
  ropa(Icons.local_laundry_service_rounded),
  compra(Icons.shopping_cart_rounded),
  basura(Icons.recycling_rounded),
  platos(Icons.flatware_rounded),
  limpieza(Icons.cleaning_services_rounded),
  plantas(Icons.local_florist_rounded),
  cama(Icons.bed_rounded),
  mascota(Icons.pets_rounded),
  cocinar(Icons.soup_kitchen_rounded),
  pagos(Icons.receipt_long_rounded),
  mantenimiento(Icons.handyman_rounded),
  otra(Icons.home_rounded);

  const TaskKind(this.icon);
  final IconData icon;

  /// Fondo suave y color del icono (claro u oscuro según el tema).
  (Color, Color) get colors => switch (this) {
    bano || plantas => (AppColors.frostBg, AppColors.frost),
    ropa || cama => (AppColors.lilacBg, AppColors.lilac),
    compra || pagos || mantenimiento => (AppColors.sageBg, AppColors.sage),
    basura || mascota => (AppColors.soonBg, AppColors.soon),
    platos || cocinar => (AppColors.peachBg, AppColors.peach),
    limpieza => (AppColors.terracottaBg, AppColors.terracotta),
    otra => (AppColors.peachBg, AppColors.woodDark),
  };
}

// Palabras (sin acentos) que delatan cada tipo, en los idiomas de la app;
// gana el primero que encaja.
const _keywords = <TaskKind, List<String>>{
  TaskKind.bano: [
    'bano', 'vater', 'inodoro', 'ducha', 'banera', 'lavabo', //
    'bath', 'toilet', 'shower', 'bad', 'bain', 'douche', 'bagno', 'doccia',
    'banho', 'sanita', 'kupatil',
  ],
  TaskKind.ropa: [
    'lavadora', 'ropa', 'tender', 'plancha', 'secadora', //
    'laundry', 'clothes', 'iron', 'wasche', 'lessive', 'linge', 'bucato',
    'stirare', 'roupa', 'maquina', 'ves',
  ],
  TaskKind.compra: [
    'compra', 'super', 'mercado', //
    'shopping', 'grocer', 'einkauf', 'courses', 'spesa', 'kupovin', 'namirnic',
  ],
  TaskKind.basura: [
    'basura', 'reciclar', 'reciclaje', 'contenedor', //
    'trash', 'garbage', 'rubbish', 'recycl', 'mull', 'abfall', 'poubelle',
    'dechet', 'spazzatur', 'rifiuti', 'lixo', 'smece', 'otpad',
  ],
  TaskKind.platos: [
    'plato', 'lavavajillas', 'vajilla', //
    'dish', 'geschirr', 'vaisselle', 'piatti', 'stovigli', 'loica', 'sude',
  ],
  TaskKind.plantas: [
    'planta', 'regar', 'jardin', 'flores', //
    'plant', 'garden', 'flower', 'pflanz', 'gies', 'garten', 'blume', 'arros',
    'jardim', 'piant', 'annaff', 'giardin', 'fiori', 'biljk', 'zali', 'basta',
  ],
  TaskKind.cama: [
    'cama', 'sabana', //
    'bed', 'sheet', 'bett', 'drap', 'letto', 'lenzuol', 'lenco', 'krevet',
    'posteljin',
  ],
  TaskKind.mascota: [
    'perro', 'gato', 'arena', 'mascota', 'pasear', //
    'dog', 'litter', 'hund', 'katze', 'gassi', 'chien', 'gatto', 'cao',
    'macka',
  ],
  TaskKind.cocinar: [
    'cocinar', 'comida', 'cena', 'batch', 'tupper', //
    'cook', 'meal', 'dinner', 'lunch', 'koch', 'cuisiner', 'cucinar', 'cozinh',
    'kuha',
  ],
  TaskKind.pagos: [
    'pagar', 'factura', 'recibo', 'banco', //
    'pay', 'bill', 'invoice', 'bank', 'rechnung', 'zahl', 'bezahl', 'facture',
    'banque', 'bollett', 'racun', 'platit',
  ],
  // Antes que limpieza: "Limpiar los filtros" es mantenimiento.
  TaskKind.mantenimiento: [
    'caldera', 'filtro', 'itv', 'coche', 'colchon', 'cortina', 'revisar', //
    'boiler', 'filter', 'mattress', 'curtain', 'heizung', 'tuv',
    'matratz', 'vorhang', 'chaudiere', 'filtre', 'controle', 'matelas',
    'rideau', 'caldaia', 'materass', 'tende', 'revision', 'caldeira',
    'inspec', 'colchao', 'bojler', 'pregled', 'madrac', 'zavjes',
  ],
  TaskKind.limpieza: [
    'aspirar',
    'barrer',
    'fregar',
    'limpiar',
    'polvo',
    'cristales',
    'suelo',
    'cocina',
    'nevera',
    'horno', //
    'clean', 'vacuum', 'sweep', 'mop', 'dust', 'window', 'floor', 'kitchen',
    'fridge', 'oven', 'putz', 'staub', 'saug', 'wisch', 'fenster', 'boden',
    'kuche', 'nettoy', 'aspir', 'balay', 'menage', 'pulir', 'pulizi',
    'spolver', 'limpa', 'ocist', 'cisc', 'usis', 'brisa', 'prozor',
  ],
};

String _plain(String s) {
  const from = 'áàäâãéèëêíìïîóòöôõúùüûñçčćšžđß';
  const to = 'aaaaaeeeeiiiiooooouuuuncccszds';
  final b = StringBuffer();
  for (final ch in s.toLowerCase().split('')) {
    final i = from.indexOf(ch);
    b.write(i >= 0 ? to[i] : ch);
  }
  return b.toString();
}

/// Tipo de una tarea por su título ("Limpiar el baño" → baño).
TaskKind taskKindFor(String title) {
  // Por inicio de palabra: "regar" no debe saltar con "fregar".
  final words = _plain(title).split(RegExp(r'[^a-z]+'));
  for (final e in _keywords.entries) {
    if (e.value.any((k) => words.any((w) => w.startsWith(k)))) return e.key;
  }
  return TaskKind.otra;
}

/// Tareas típicas para crear con un toque, con su repetición habitual. El
/// título visible sale del ARB (`taskPreset`, por [key]).
const taskPresets = <({String key, String recurrence})>[
  (key: 'dishes', recurrence: 'daily'),
  (key: 'vacuum', recurrence: 'weekly'),
  (key: 'bathroom', recurrence: 'weekly'),
  (key: 'laundry', recurrence: 'weekly'),
  (key: 'trash', recurrence: 'daily'),
  (key: 'shopping', recurrence: 'weekly'),
  (key: 'plants', recurrence: 'weekly'),
  (key: 'sheets', recurrence: 'weekly'),
];

/// Mantenimiento de la casa: lo que toca cada pocos meses o cada año. El
/// título visible sale del ARB (`maintPreset`, por [key]).
const maintenancePresets =
    <({String key, int count, String unit, IconData icon})>[
      (key: 'fridge', count: 1, unit: 'month', icon: Icons.kitchen_rounded),
      (
        key: 'washer',
        count: 1,
        unit: 'month',
        icon: Icons.local_laundry_service_rounded,
      ),
      (key: 'filters', count: 3, unit: 'month', icon: Icons.air_rounded),
      (key: 'oven', count: 3, unit: 'month', icon: Icons.microwave_rounded),
      (key: 'mattress', count: 6, unit: 'month', icon: Icons.bed_rounded),
      (key: 'curtains', count: 6, unit: 'month', icon: Icons.curtains_rounded),
      (
        key: 'boiler',
        count: 1,
        unit: 'year',
        icon: Icons.local_fire_department_rounded,
      ),
      (key: 'car', count: 1, unit: 'year', icon: Icons.directions_car_rounded),
    ];
