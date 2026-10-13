import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Tipo de tarea del hogar, sacado del título, para darle icono y color.
enum TaskKind {
  bano('Baño', Icons.bathtub_rounded),
  ropa('Ropa', Icons.local_laundry_service_rounded),
  compra('Compra', Icons.shopping_cart_rounded),
  basura('Basura', Icons.recycling_rounded),
  platos('Platos', Icons.flatware_rounded),
  limpieza('Limpieza', Icons.cleaning_services_rounded),
  plantas('Plantas', Icons.local_florist_rounded),
  cama('Cama', Icons.bed_rounded),
  mascota('Mascota', Icons.pets_rounded),
  cocinar('Cocinar', Icons.soup_kitchen_rounded),
  pagos('Pagos', Icons.receipt_long_rounded),
  otra('Tarea', Icons.home_rounded);

  const TaskKind(this.label, this.icon);
  final String label;
  final IconData icon;

  /// Fondo suave y color del icono (claro u oscuro según el tema).
  (Color, Color) get colors => switch (this) {
    bano || plantas => (AppColors.frostBg, AppColors.frost),
    ropa || cama => (AppColors.lilacBg, AppColors.lilac),
    compra || pagos => (AppColors.sageBg, AppColors.sage),
    basura || mascota => (AppColors.soonBg, AppColors.soon),
    platos || cocinar => (AppColors.peachBg, AppColors.peach),
    limpieza => (AppColors.terracottaBg, AppColors.terracotta),
    otra => (AppColors.peachBg, AppColors.woodDark),
  };
}

// Palabras (sin acentos) que delatan cada tipo; gana el primero que encaja.
const _keywords = <TaskKind, List<String>>{
  TaskKind.bano: ['bano', 'vater', 'inodoro', 'ducha', 'banera', 'lavabo'],
  TaskKind.ropa: ['lavadora', 'ropa', 'tender', 'plancha', 'secadora'],
  TaskKind.compra: ['compra', 'super', 'mercado'],
  TaskKind.basura: ['basura', 'reciclar', 'reciclaje', 'contenedor'],
  TaskKind.platos: ['plato', 'lavavajillas', 'vajilla'],
  TaskKind.plantas: ['planta', 'regar', 'jardin', 'flores'],
  TaskKind.cama: ['cama', 'sabana'],
  TaskKind.mascota: ['perro', 'gato', 'arena', 'mascota', 'pasear'],
  TaskKind.cocinar: ['cocinar', 'comida', 'cena', 'batch', 'tupper'],
  TaskKind.pagos: ['pagar', 'factura', 'recibo', 'banco'],
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
    'horno',
  ],
};

String _plain(String s) {
  const from = 'áàäâéèëêíìïîóòöôúùüûñ';
  const to = 'aaaaeeeeiiiioooouuuun';
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

/// Tareas típicas para crear con un toque, con su repetición habitual.
const taskPresets = <({String title, String recurrence})>[
  (title: 'Fregar los platos', recurrence: 'daily'),
  (title: 'Aspirar', recurrence: 'weekly'),
  (title: 'Limpiar el baño', recurrence: 'weekly'),
  (title: 'Poner lavadora', recurrence: 'weekly'),
  (title: 'Sacar la basura', recurrence: 'daily'),
  (title: 'Hacer la compra', recurrence: 'weekly'),
  (title: 'Regar las plantas', recurrence: 'weekly'),
  (title: 'Cambiar sábanas', recurrence: 'weekly'),
];
