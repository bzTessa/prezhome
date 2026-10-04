/// Almacenamiento local PURO para la caché offline-first (Paso 7).
///
/// La app debe cargar la lista de la compra y la despensa AL INSTANTE desde una
/// caché en disco, aunque no haya cobertura (p. ej. dentro del supermercado), y
/// encolar los cambios hechos sin conexión para sincronizarlos con Supabase en
/// cuanto vuelva la red. Toda esa lógica (caché + cola) necesita leer y escribir
/// cadenas por clave, pero NO debe acoplarse a un plugin nativo concreto: eso
/// rompería `flutter test` en la VM (no hay emulador para sqflite/hive/disco).
///
/// Por eso definimos una INTERFAZ mínima [LocalStore] y la inyectamos. Hay dos
/// implementaciones:
/// - [InMemoryLocalStore]: pura, con un `Map` interno; se usa en los tests y
///   como arranque sin disco.
/// - `FileLocalStore` (JSON en el directorio de documentos vía path_provider):
///   vive en su propio archivo y SOLO ella toca el binding nativo, para no
///   contaminar el núcleo puro. Se añade en una feature posterior.
///
/// IMPORTANTE: este archivo NO importa `package:supabase_flutter` ni
/// `package:flutter/material.dart`. Es Dart puro y testeable en la VM.
///
/// Las claves se esperan NAMESPACED por hogar (p. ej.
/// `shopping_list_items:<home_id>`) para que la caché nunca mezcle datos de
/// hogares distintos; la responsabilidad de componer la clave es de quien llama.
library;

/// Contrato de almacenamiento clave-valor asíncrono para la caché offline.
///
/// Es deliberadamente pequeño (strings por clave): la (de)serialización a JSON
/// de la caché y de la cola la hacen las capas superiores (SyncQueue, merge),
/// de modo que el store no necesita conocer los modelos.
abstract class LocalStore {
  /// Lee el valor asociado a [key], o `null` si no existe.
  Future<String?> read(String key);

  /// Escribe (crea o reemplaza) el valor [value] bajo [key].
  Future<void> write(String key, String value);

  /// Elimina la entrada [key] si existe (no falla si no está).
  Future<void> remove(String key);

  /// Borra TODAS las entradas. Se usa al cerrar sesión o cambiar de hogar para
  /// que la caché local nunca arrastre datos de otro hogar (ver steering de
  /// seguridad: datos aislados por hogar).
  Future<void> clearAll();
}

/// Implementación EN MEMORIA de [LocalStore], pura y sin dependencias.
///
/// Pensada para los tests (lógica de caché/cola sin disco ni red) y como
/// respaldo de arranque si todavía no hay persistencia disponible. Los datos
/// viven solo mientras exista la instancia.
class InMemoryLocalStore implements LocalStore {
  final Map<String, String> _data = {};

  /// Vista de solo lectura del contenido actual, útil para aserciones en tests.
  Map<String, String> get snapshot => Map.unmodifiable(_data);

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> write(String key, String value) async {
    _data[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _data.remove(key);
  }

  @override
  Future<void> clearAll() async {
    _data.clear();
  }
}
