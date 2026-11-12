/// Siguiente persona en una tarea por turnos: la que va después de [current]
/// en [people] (ya ordenadas), volviendo a la primera al llegar al final.
/// Si [current] no está (o es null), le toca a la primera. Null si no hay
/// nadie.
String? nextInRotation(List<String> people, String? current) {
  if (people.isEmpty) return null;
  final i = current == null ? -1 : people.indexOf(current);
  return people[(i + 1) % people.length];
}

/// Orden fijo de los turnos: por nombre y, a igual nombre, por id.
List<String> rotationOrder(Map<String, String> members) {
  final entries = members.entries.toList()
    ..sort((a, b) {
      final byName = a.value.toLowerCase().compareTo(b.value.toLowerCase());
      return byName != 0 ? byName : a.key.compareTo(b.key);
    });
  return [for (final e in entries) e.key];
}
